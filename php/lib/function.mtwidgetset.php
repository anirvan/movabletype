<?php
# Movable Type (r) Open Source (C) 2001-2012 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

require_once("function.mtwidgetmanager.php");
function smarty_function_mtwidgetset($args, &$ctx) {
    return smarty_function_mtwidgetmanager($args, $ctx);
}
?>
