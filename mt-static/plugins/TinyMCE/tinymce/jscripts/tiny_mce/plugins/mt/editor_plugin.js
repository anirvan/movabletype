(function(b){function a(d,c){b.fn.mtDialog.open(ScriptURI+"?__mode="+d+"&amp;"+c)}tinymce.Editor.prototype.addMtButton=function(e,f){var d=this;var g={};var c=f.onclickFunctions;if(c){f.onclick=function(){var i=d.mtEditorStatus.mode;var h=c[i];if(typeof(h)=="string"){d.mtProxies[i].execCommand(h)}else{h.apply(d,arguments)}if(i=="source"){d.onMTSourceButtonClick.dispatch(d,d.controlManager)}};for(k in c){g[k]=1}}else{g={wysiwyg:1,source:1}}if(!f.isSupported){f.isSupported=function(j,i){if(!g[j]){return false}if(c&&j=="source"){var h=c[j];if(typeof(h)=="string"){return d.mtProxies.source.isSupported(h,i)}else{return true}}else{return true}}}if(typeof(d.mtButtons)=="undefined"){d.mtButtons={}}d.mtButtons[e]=f;return d.addButton(e,f)};tinymce.ScriptLoader.add(tinymce.PluginManager.urls.mt+"/langs/en.js");tinymce.create("tinymce.plugins.MovableType",{init:function(p,d){tinymce.DOM.loadCSS(d+"/css/mt.css");var e=p.id;var m=b("#blog-id").val()||0;var n={};var q=[];var h={};function s(u,t){var i=u+"-"+t;if(!h[i]){h[i]={};b.each(p.mtButtons,function(v,w){if(w.isSupported(u,t)){h[i][v]=w}})}return h[i]}p.mtProxies=n;p.mtEditorStatus={mode:"wysiwyg",format:"richtext"};p.addCommand("mtGetStatus",function(){return p.mtEditorStatus});function f(){var i=p.mtEditorStatus;b.each(q,function(v,u){b("#"+u).show().removeClass("mce_mt_button_hidden").css({display:"block"});p.controlManager.setDisabled(this,false)});q=[];var t={};b.each(s(i.mode,i.format),function(w,u){t[e+"_"+w]=1});if(i.mode=="source"){n.source.setFormat(i.format);b.each(p.controlManager.controls,function(u,v){if(!v.classPrefix){return}if(!t[u]){b("#"+u).hide().addClass("mce_mt_button_hidden");q.push(u)}})}else{b.each(p.mtButtons,function(v,w){var u=e+"_"+v;if(!t[u]){b("#"+u).hide().addClass("mce_mt_button_hidden");q.push(u)}})}b("table","#"+e+"_toolbargroup").each(function(){var u=b(this);if(u.hasClass("mceSplitButton")){return}u.show();if(u.find("a.mceButton:not(.mce_mt_button_hidden)").length==0){u.hide()}});p.theme.resizeBy(0,0)}p.onInit.add(function(){f()});p.addCommand("mtSetStatus",function(i){b.extend(p.mtEditorStatus,i);f()});p.addCommand("mtGetProxies",function(){return n});p.addCommand("mtSetProxies",function(i){b.extend(n,i)});p.addMtButton("mt_font_size_smaller",{title:"mt.font_size_smaller",onclickFunctions:{wysiwyg:"fontSizeSmaller",source:"fontSizeSmaller"}});p.addMtButton("mt_font_size_larger",{title:"mt.font_size_larger",onclickFunctions:{wysiwyg:"fontSizeLarger",source:"fontSizeLarger"}});p.addMtButton("mt_bold",{title:"mt.bold",onclickFunctions:{wysiwyg:function(){p.execCommand("bold")},source:"bold"}});p.addMtButton("mt_italic",{title:"mt.italic",onclickFunctions:{wysiwyg:function(){p.execCommand("italic")},source:"italic"}});p.addMtButton("mt_underline",{title:"mt.underline",onclickFunctions:{wysiwyg:function(){p.execCommand("underline")},source:"underline"}});p.addMtButton("mt_strikethrough",{title:"mt.strikethrough",onclickFunctions:{wysiwyg:function(){p.execCommand("strikethrough")},source:"strikethrough"}});p.addMtButton("mt_insert_link",{title:"mt.insert_link",onclickFunctions:{wysiwyg:function(){var t=p.dom.getParent(p.selection.getNode(),"A");var i=!p.selection.isCollapsed();n.wysiwyg.execCommand("insertLink",null,{anchor:t,textSelected:i})},source:"insertLink"}});p.addMtButton("mt_insert_email",{title:"mt.insert_email",onclickFunctions:{wysiwyg:function(){var t=p.dom.getParent(p.selection.getNode(),"A");var i=!p.selection.isCollapsed();n.wysiwyg.execCommand("insertEmail",null,{anchor:t,textSelected:i})},source:"insertEmail"}});p.addMtButton("mt_indent",{title:"mt.indent",onclickFunctions:{wysiwyg:function(){p.execCommand("indent")},source:"indent"}});p.addMtButton("mt_outdent",{title:"mt.outdent",onclickFunctions:{wysiwyg:function(){p.execCommand("outdent")}}});p.addMtButton("mt_insert_unordered_list",{title:"mt.insert_unordered_list",onclickFunctions:{wysiwyg:function(){p.execCommand("insertUnorderedList")},source:"insertUnorderedList"}});p.addMtButton("mt_insert_ordered_list",{title:"mt.insert_ordered_list",onclickFunctions:{wysiwyg:function(){p.execCommand("insertOrderedList")},source:"insertOrderedList"}});p.addMtButton("mt_justify_left",{title:"mt.justify_left",onclickFunctions:{wysiwyg:function(){p.execCommand("justifyLeft")},source:"justifyLeft"}});p.addMtButton("mt_justify_center",{title:"mt.justify_center",onclickFunctions:{wysiwyg:function(){p.execCommand("justifyCenter")},source:"justifyCenter"}});p.addMtButton("mt_justify_right",{title:"mt.justify_right",onclickFunctions:{wysiwyg:function(){p.execCommand("justifyRight")},source:"justifyRight"}});p.addMtButton("mt_insert_image",{title:"mt.insert_image",onclick:function(){a("dialog_list_asset","_type=asset&amp;edit_field="+e+"&amp;blog_id="+m+"&amp;dialog_view=1&amp;filter=class&amp;filter_val=image")}});p.addMtButton("mt_insert_file",{title:"mt.insert_file",onclick:function(){a("dialog_list_asset","_type=asset&amp;edit_field="+e+"&amp;blog_id="+m+"&amp;dialog_view=1")}});p.addMtButton("mt_source_bold",{title:"mt.bold",onclickFunctions:{source:"bold"}});p.addMtButton("mt_source_italic",{title:"mt.italic",onclickFunctions:{source:"italic"}});p.addMtButton("mt_source_blockquote",{title:"mt.blockquote",onclickFunctions:{source:"blockquote"}});p.addMtButton("mt_source_unordered_list",{title:"mt.insert_unordered_list",onclickFunctions:{source:"insertUnorderedList"}});p.addMtButton("mt_source_ordered_list",{title:"mt.insert_ordered_list",onclickFunctions:{source:"insertOrderedList"}});p.addMtButton("mt_source_list_item",{title:"mt.list_item",onclickFunctions:{source:"insertListItem"}});function l(i){b.each(p.windowManager.windows,function(u,t){var v=t.iframeElement;b("#"+v.id).load(function(){var x=this.contentWindow;var w={"$contents":b(this).contents(),window:x};i(w,function(){x.tinyMCEPopup.close();if(tinymce.isWebKit){b("#convert_breaks").focus()}n.source.focus()})})})}function r(u,i){function t(){var v=b(this);n.source.execCommand("createLink",null,v.find("#href").val(),{target:v.find("#target_list").val(),title:v.find("#linktitle").val()});i()}u["$contents"].find("form").attr("onsubmit","").submit(t);if(!n.source.isSupported("createLink",p.mtEditorStatus.format,"target")){u["$contents"].find("#targetlistlabel").closest("tr").hide()}}p.addMtButton("mt_source_link",{title:"mt.source_link",onclickFunctions:{source:function(t,i,u){tinymce._setActive(p);this.theme._mceLink.apply(this.theme);l(r)}}});p.addMtButton("mt_source_mode",{title:"mt.source_mode",onclickFunctions:{wysiwyg:function(){p.execCommand("mtSetFormat","none.tinymce_temp")},source:function(){p.execCommand("mtSetFormat","richtext")}}});var c="";for(var o=1;p.settings["theme_advanced_buttons"+o];o++){c+=(c?",":"")+p.settings["theme_advanced_buttons"+o]}var g={mt_bold:"bold",mt_italic:"italic",mt_underline:"underline",mt_strikethrough:"strikethrough",mt_justify_left:"justifyleft",mt_justify_center:"justifycenter",mt_justify_right:"justifyright"};b.each(g,function(t,i){if(c.indexOf(t)==-1){delete g[t]}});p.onNodeChange.add(function(u,i,y,x,t){var v=u.mtEditorStatus;if(v.mode=="wysiwyg"){b.each(g,function(A,z){i.setActive(A,u.queryCommandState(z))});i.setDisabled("mt_outdent",!u.queryCommandState("Outdent"))}if(u.getParam("fullscreen_is_enabled")){i.setDisabled("mt_source_mode",true)}else{if(u.mtEditorStatus.mode=="source"&&u.mtEditorStatus.format!="none.tinymce_temp"){b("#"+e+"_mt_source_mode").hide()}else{b("#"+e+"_mt_source_mode").show()}var w=u.mtEditorStatus.mode=="source"&&u.mtEditorStatus.format=="none.tinymce_temp";i.setActive("mt_source_mode",w)}if(!u.mtProxies.source){return}b.each(j,function(z,A){i.setActive(z,u.mtProxies.source.isStateActive(A))})});if(!p.onMTSourceButtonClick){p.onMTSourceButtonClick=new tinymce.util.Dispatcher(p)}var j={mt_source_bold:"bold",mt_source_italic:"italic",mt_source_blockquote:"blockquote",mt_source_unordered_list:"insertUnorderedList",mt_source_ordered_list:"insertOrderedList",mt_source_list_item:"insertListItem",mt_source_link:"createLink",};b.each(j,function(t,i){if(c.indexOf(t)==-1){delete g[t]}});p.onMTSourceButtonClick.add(function(t,i){b.each(j,function(u,v){i.setActive(u,t.mtProxies.source.isStateActive(v))})})},getInfo:function(){return{longname:"MovableType",author:"Six Apart, Ltd",authorurl:"",infourl:"",version:tinymce.majorVersion+"."+tinymce.minorVersion}}});tinymce.PluginManager.add("mt",tinymce.plugins.MovableType)})(jQuery);