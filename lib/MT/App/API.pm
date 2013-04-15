# Movable Type (r) Open Source (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

package MT::App::API;

use strict;
use base qw( MT::App );

use MT::API::Resource;
use MT::App::CMS::Common;
use MT::AccessToken;

our ( %endpoints, %formats ) = ();

sub id {'api'}

sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->{template_dir} = 'api';
    $app->{default_mode} = 'api';
    $app;
}

sub core_methods {
    my $app = shift;
    return { 'api' => \&api, };
}

sub core_endpoints {
    my $app = shift;
    my $pkg = '$Core::MT::API::Endpoint::';
    return [
        {   id             => 'authorization',
            route          => '/authorization',
            version        => 1,
            handler        => "${pkg}Auth::authorization",
            format         => 'html',
            requires_login => 0,
        },
        {   id             => 'authentication',
            route          => '/authentication',
            method         => 'POST',
            version        => 1,
            handler        => "${pkg}Auth::authentication",
            requires_login => 0,
        },
        {   id             => 'token',
            route          => '/token',
            version        => 1,
            handler        => "${pkg}Auth::token",
            requires_login => 0,
        },
        {   id          => 'get_user',
            route       => '/users/:user_id',
            version     => 1,
            handler     => "${pkg}User::get",
            error_codes => {
                403 =>
                    'Do not have permission to retrieve the requested user.',
            },
        },
        {   id          => 'update_user',
            route       => '/users/:user_id',
            resources   => ['user'],
            method      => 'PUT',
            version     => 1,
            handler     => "${pkg}User::update",
            error_codes => {
                403 => 'Do not have permission to update the requested user.',
            },
        },
        {   id          => 'list_blogs',
            route       => '/users/:user_id/sites',
            version     => 1,
            handler     => "${pkg}Blog::list",
            error_codes => {
                403 =>
                    'Do not have permission to retrieve the list of blogs.',
            },
        },
        {   id      => 'list_entries',
            route   => '/sites/:site_id/entries',
            method  => 'GET',
            version => 1,
            handler => "${pkg}Entry::list",
            param   => {
                limit      => 10,
                offset     => 0,
                sort_by    => 'authored_on',
                sort_order => 'descend',
                search_fields =>
                    'title,text,text_more,keywords,excerpt,basename',
            },
            error_codes => {
                403 =>
                    'Do not have permission to retrieve the list of entries.',
            },
        },
        {   id        => 'create_entry',
            route     => '/sites/:site_id/entries',
            resources => ['entry'],
            method    => 'POST',
            version   => 1,
            handler   => "${pkg}Entry::create",
            param => { save_revision => 1, },
            error_codes =>
                { 403 => 'Do not have permission to create an entry.', },
        },
        {   id          => 'get_entry',
            route       => '/sites/:site_id/entries/:entry_id',
            version     => 1,
            handler     => "${pkg}Entry::get",
            error_codes => {
                403 =>
                    'Do not have permission to retrieve the requested entry.',
            },
        },
        {   id        => 'update_entry',
            route     => '/sites/:site_id/entries/:entry_id',
            resources => ['entry'],
            method    => 'PUT',
            version   => 1,
            handler   => "${pkg}Entry::update",
            param => { save_revision => 1, },
            error_codes =>
                { 403 => 'Do not have permission to update an entry.', },
        },
        {   id      => 'delete_entry',
            route   => '/sites/:site_id/entries/:entry_id',
            method  => 'DELETE',
            version => 1,
            handler => "${pkg}Entry::delete",
            error_codes =>
                { 403 => 'Do not have permission to delete an entry.', },
        },
        {   id      => 'stats_pageviews_for_path',
            route   => '/sites/:site_id/stats/path/pageviews',
            version => 1,
            handler => "${pkg}Stats::pageviews_for_path",
        },
        {   id      => 'stats_visits_for_path',
            route   => '/sites/:site_id/stats/path/visits',
            version => 1,
            handler => "${pkg}Stats::visits_for_path",
        },
        {   id      => 'stats_pageviews_for_date',
            route   => '/sites/:site_id/stats/date/pageviews',
            version => 1,
            handler => "${pkg}Stats::pageviews_for_date",
        },
        {   id      => 'stats_visits_for_date',
            route   => '/sites/:site_id/stats/date/visits',
            version => 1,
            handler => "${pkg}Stats::visits_for_date",
        },
    ];
}

sub core_formats {
    my $app = shift;
    my $pkg = '$Core::MT::API::Format::';
    return {
        'js'   => 'json',
        'json' => {
            content_type => 'application/json',
            serialize    => "${pkg}JSON::serialize",
            unserialize  => "${pkg}JSON::unserialize",
        },
    };
}

sub init_plugins {
    my $app = shift;

    # This has to be done prior to plugin initialization since we
    # may have plugins that register themselves using some of the
    # older callback names. The callback aliases are declared
    # in init_core_callbacks.
    MT::App::CMS::Common::init_core_callbacks($app);
    $app->SUPER::init_plugins(@_);
}

sub _compile_endpoints {
    my ( $app, $version ) = @_;

    my %hash           = ();
    my %tree           = ();
    my $endpoints_list = $app->registry( 'applications', 'api', 'endpoints' );
    foreach my $endpoints (@$endpoints_list) {
        foreach my $e (@$endpoints) {
            $e->{id}          ||= $e->{route};
            $e->{version}     ||= 1;
            $e->{method}      ||= 'GET';
            $e->{error_codes} ||= {};

            if ( !exists( $e->{requires_login} ) ) {
                $e->{requires_login} = 1;
            }
            $e->{_vars} = [];

            next if $e->{version} > $version;

            my $cur = \%tree;
            ( my $route = $e->{route} ) =~ s#^/+##;
            foreach my $p ( split m#(?=/|\.)|(?<=/|\.)#o, $route ) {
                if ( $p =~ /^:([a-zA-Z_-]+)/ ) {
                    $cur = $cur->{':v'} ||= {};
                    push @{ $e->{_vars} }, $1;
                }
                else {
                    $cur = $cur->{$p} ||= {};
                }
            }

            $cur->{':e'} ||= {};
            if (  !$cur->{':e'}{ lc $e->{method} }
                || $cur->{':e'}{ lc $e->{method} }{version} < $e->{version} )
            {
                $cur->{':e'}{ lc $e->{method} } = $e;
            }

            $hash{ $e->{id} } = $e;
        }
    }

    +{  hash => \%hash,
        tree => \%tree,
    };
}

sub endpoints {
    my ( $app, $version, $path ) = @_;
    $endpoints{$version} ||= $app->_compile_endpoints($version);
}

sub current_endpoint {
    my $app = shift;
    $app->request( 'api_current_endpoint', @_ ? $_[0] : () );
}

sub current_api_version {
    my $app = shift;
    $app->request( 'api_current_version', @_ ? $_[0] : () );
}

sub find_endpoint_by_id {
    my ( $app, $version, $id ) = @_;
    $app->endpoints($version)->{hash}{$id};
}

sub endpoint_url {
    my ( $app, $endpoint, $params ) = @_;
    $endpoint = $app->find_endpoint_by_id($endpoint) unless ref $endpoint;
    return '' unless $endpoint;

    my $replace = sub {
        my ( $whole, $key ) = @_;
        if ( exists $params->{$key} ) {
            my $v = delete $params->{$key};
            UNIVERSAL::isa( $v, 'MT::Object' ) ? $v->id : $v;
        }
        else {
            $whole;
        }
    };

    my $url = $endpoint->{route};
    $url =~ s{(?:(?<=^)|(?<=/|\.))(:([a-zA-Z_-]+))}{$replace->($1, $2)}ge;

    $url . $app->uri_params( args => $params );
}

sub find_endpoint_by_path {
    my ( $app, $method, $version, $path ) = @_;
    $method = lc($method);

    my $endpoints = $app->endpoints($version)->{tree};

    my $handler         = $endpoints;
    my @vars            = ();
    my $implicit_format = '';

    $path =~ s#^/+##;
    my @paths = split m#(?=/|\.)|(?<=/|\.)#o, $path;
    while ( my $p = shift @paths ) {
        if ( $handler->{$p} ) {
            $handler = $handler->{$p};
        }
        elsif ( $handler->{':v'} ) {
            $handler = $handler->{':v'};
            push @vars, $p;
        }
        elsif ( $p eq '.' && scalar(@paths) == 1 ) {
            $implicit_format = shift @paths;
        }
        else {
            return;
        }
    }

    my $e = $handler->{':e'}{$method}
        or return;

    my %params = ();
    for ( my $i = 0; $i < scalar( @{ $e->{_vars} } ); $i++ ) {
        $params{ $e->{_vars}[$i] } = $vars[$i];
    }
    $params{format} = $implicit_format if $implicit_format && !$e->{format};

    $e, \%params;
}

sub find_format {
    my ( $app, $key ) = @_;

    if ( !%formats ) {
        my $reg = $app->registry( 'applications', 'api', 'formats' );
        %formats = map { $_ => 1 } keys %$reg;
    }

    my $format_key
        = $key
        || ( $app->current_endpoint || {} )->{format}
        || $app->param('format')
        || $app->registry( 'applications', 'api' )->{default_format};

    my $format = $formats{$format_key};
    if ( !defined $format ) {
        $format_key = ( keys %formats )[0];
        $format     = $formats{$format_key};
    }

    if ( !ref $format ) {
        $format = $formats{$format_key}
            = $app->registry( 'applications', 'api', 'formats', $format_key );

        if ( ref $format ne 'HASH' ) {
            $format = $formats{$format_key}
                = $app->find_format( $format->[0] );
        }
        else {
            for my $k (qw(serialize unserialize)) {
                $format->{$k} = $app->handler_to_coderef( $format->{$k} );
            }
        }
    }

    $format;
}

sub current_format {
    my ($app) = @_;
    $app->find_format;
}

sub current_error_format {
    my ($app) = @_;
    my $format = $app->current_format;
    if ( my $invoke = $format->{error_format} ) {
        $format = $app->find_format($invoke);
    }
    $format;
}

sub _request_method {
    my ($app) = @_;
    my $method = lc $app->request_method;
    if ( my $m = $app->param('__method') ) {
        if ( $method eq 'post' || $method eq lc $m ) {
            $method = lc $m;
        }
        else {
            return $app->print_error(
                "Request method is not '$m' or 'POST' with '__method=$m'",
                405 );
        }
    }
    $method;
}

sub _path {
    my ($app) = @_;
    my $path = $app->path_info;
    $path =~ s{.+(?=/v\d+/)}{};
    $path;
}

sub resource_object {
    my ( $app, $name, $original ) = @_;

    my $data_text = $app->param($name)
        or return undef;

    my $data = $app->current_format->{unserialize}->($data_text)
        or return undef;

    MT::API::Resource->to_object( $name, $data, $original );
}

sub object_to_resource {
    my ( $app, $res, $fields ) = @_;
    my $ref = ref $res;

    if ( UNIVERSAL::isa( $res, 'MT::Object' ) ) {
        MT::API::Resource->from_object( $res, $fields );
    }
    elsif ( $ref eq 'HASH' ) {
        my %result = ();
        foreach my $k ( keys %$res ) {
            $result{$k} = $app->object_to_resource( $res->{$k}, $fields );
        }
        \%result;
    }
    elsif ( $ref eq 'ARRAY' ) {
        [ map { $app->object_to_resource( $_, $fields ) } @$res ];
    }
    else {
        $res;
    }
}

sub mt_authorization_header {
    my ($app) = @_;

    my $header = $app->get_header('X-MT-Authorization')
        or undef;

    my %values = ();

    $header =~ s/\A\s+|\s+\z//g;

    my ( $type, $rest ) = split /\s+/, $header, 2;
    return undef unless $type;

    $values{$type} = {};

    while ( $rest =~ m/(\w+)=(?:("|')([^\2]*)\2|([^\s,]*))/g ) {
        $values{$type}{$1} = defined($3) ? $3 : $4;
    }

    \%values;
}

sub authenticate {
    my ($app) = @_;

    my $header = $app->mt_authorization_header
        or undef;

    my $session
        = MT::AccessToken->load_session( $header->{MTAuth}{access_token}
            || '' )
        or return undef;
    my $user = $app->model('author')->load( $session->get('author_id') )
        or return undef;

    return undef unless $user->is_active;

    $user;
}

sub user_cookie {
    'mt_api_user';
}

sub session_kind {
    'PS';    # PS == API Session
}

sub make_session {
    my ( $app, $auth, $remember ) = @_;
    require MT::Session;
    my $sess = new MT::Session;
    $sess->id( $app->make_magic_token() );
    $sess->kind( $app->session_kind );
    $sess->start(time);
    $sess->set( 'author_id', $auth->id );
    $sess->set( 'remember', 1 ) if $remember;
    $sess->save;
    $sess;
}

sub session_user {
    my $app = shift;
    my ( $author, $session_id, %opt ) = @_;
    return undef unless $author && $session_id;
    if ( $app->{session} ) {
        if ( $app->{session}->get('author_id') == $author->id ) {
            return $author;
        }
    }

    require MT::Session;
    my $timeout
        = $opt{permanent}
        ? ( 360 * 24 * 365 * 10 )
        : $app->config->UserSessionTimeout;
    my $sess = MT::Session::get_unexpired_value(
        $timeout,
        {   id   => $session_id,
            kind => $app->session_kind,
        }
    );
    $app->{session} = $sess;

    return undef if !$sess;
    if ( $sess && ( $sess->get('author_id') == $author->id ) ) {
        return $author;
    }
    else {
        return undef;
    }
}

sub start_session {
    my $app = shift;
    my ( $user, $remember ) = @_;
    if ( !defined $user ) {
        $user = $app->user;
        my ( $x, $y );
        ( $x, $y, $remember )
            = split( /::/, $app->cookie_val( $app->user_cookie ) );
    }
    my $session = $app->make_session( $user, $remember );
    $app->{session} = $session;
}

sub error {
    my $app  = shift;
    my @args = @_;

    if ( $_[0] && ( $_[0] =~ m/\A\d{3}\z/ || $_[1] ) ) {
        my ( $message, $code ) = do {
            if ( scalar(@_) == 2 ) {
                @_;
            }
            else {
                ( '', $_[0] );
            }
        };
        $app->request(
            'api_error_detail',
            {   code    => $code,
                message => $message,
            }
        );
        @args = join( ' ', reverse(@_) );
    }

    return $app->SUPER::error(@args);
}

sub print_error {
    my ( $app, $message, $status ) = @_;

    if ( !$status && $message =~ m/\A\d{3}\z/ ) {
        $status  = $message;
        $message = '';
    }
    if ( !$message && $status ) {
        require HTTP::Status;
        $message = HTTP::Status::status_message($status);
    }

    my $format = $app->current_error_format;

    $app->response_code($status);
    $app->send_http_header( $format->{content_type} );
    $app->{no_print_body} = 1;
    $app->print_encode(
        $format->{serialize}->(
            {   error => {
                    message => $message,
                    code    => $status,
                }
            }
        )
    );

    return undef;
}

sub show_error {
    my $app      = shift;
    my ($param)  = @_;
    my $endpoint = $app->current_endpoint;
    my $error    = $app->request('api_error_detail');

    return $app->SUPER::show_error(@_)
        if !$endpoint || ( !$error && $endpoint->{format} eq 'html' );

    if ( !$error ) {
        $error = {
            code => $param->{status} || 500,
            message => $param->{error},
        };
    }

    return $app->print_error( $error->{message}
            || $endpoint->{error_codes}{ $error->{code} },
        $error->{code} );
}

sub api {
    my ($app) = @_;
    my $path = $app->_path;

    my ($version) = ( $path =~ s{\A/?v(\d+)}{} );
    return $app->print_error( 'API Version is required', 400 )
        unless defined($version);

    my $request_method = $app->_request_method
        or return;
    my ( $endpoint, $params )
        = $app->find_endpoint_by_path( $request_method, $version, $path )
        or return $app->print_error( 'Unknown endpoint', 404 );
    my $user = $app->authenticate;

    if ( $endpoint->{requires_login} && !$user ) {
        return $app->print_error( 'Unauthorized', 401 );
    }
    $app->user($user);

    if ( my $id = $params->{site_id} ) {
        $app->blog( scalar $app->model('blog')->load($id) )
            or return $app->print_error( 'Site not found', 404 );
        $app->param( 'blog_id', $id );
    }

    foreach my $k (%$params) {
        $app->param( $k, $params->{$k} );
    }
    if ( my $default_param = $endpoint->{param} ) {
        my $request_param = $app->param->Vars;
        foreach my $k (%$default_param) {
            if ( !exists( $request_param->{$k} ) ) {
                $app->param( $k, $default_param->{$k} );
            }
        }
    }

    $endpoint->{handler_ref}
        ||= $app->handler_to_coderef( $endpoint->{handler} )
        or return $app->print_error( 'Unknown endpoint', 404 );

    $app->current_endpoint($endpoint);
    $app->current_api_version($version);

    $app->run_callbacks( 'pre_run_api.' . $endpoint->{id}, $app, $endpoint );
    my $response = $endpoint->{handler_ref}->( $app, $endpoint );
    $app->run_callbacks( 'post_run_api.' . $endpoint->{id},
        $app, $endpoint, $response );

    if ( UNIVERSAL::isa( $response, 'MT::Template' ) ) {
        $response;
    }
    elsif (ref $response eq 'HASH'
        || ref $response eq 'ARRAY'
        || UNIVERSAL::isa( $response, 'MT::Object' ) )
    {
        my $format   = $app->current_format;
        my $resource = $app->object_to_resource( $response,
            $app->param('fields') || '' );
        my $data = $format->{serialize}->($resource);
        $app->send_http_header( $format->{content_type} );
        $app->{no_print_body} = 1;
        $app->print_encode($data);
        undef;
    }
    else {
        $response;
    }
}

1;
__END__

=head1 NAME

MT::App::API

=head1 SYNOPSIS

The I<MT::App::API> module is the application module for providing DATA API.
This module provide the REST interface that is used to
manage blogs, entries, comments, trackbacks, templates, etc.

=cut