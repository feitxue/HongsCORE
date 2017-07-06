<%@page import="app.hongs.CoreLocale"%>
<%@page import="app.hongs.action.ActionDriver"%>
<%@page import="app.hongs.action.FormSet"%>
<%@page import="app.hongs.action.NaviMap"%>
<%@page import="app.hongs.util.Dict"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
    String     _module;
    String     _entity;
    String     _title ;
    CoreLocale _locale;

    do {
        // 拆解路径
        int i;
        _module = ActionDriver.getWorkPath(request);
        i = _module.lastIndexOf('/');
        _module = _module.substring( 1, i );
        i = _module.lastIndexOf('/');
        _entity = _module.substring( 1+ i );
        _module = _module.substring( 0, i );

        // 获取语言
        _locale = CoreLocale.getInstance( ).clone();
        _locale.fill(_module);
        _locale.fill(_module +"/"+ _entity);

        // 从菜单中提取标题
        NaviMap site = NaviMap.hasConfFile(_module+"/"+_entity)
                     ? NaviMap.getInstance(_module+"/"+_entity)
                     : NaviMap.getInstance(_module);
        Map menu;
        menu  = site.getMenu(_module +"/" +_entity+"/");
        if (menu != null) {
                _title  = (String) menu.get("text");
            if (_title != null) {
                _title  = _locale.translate(_title);
                break;
            }
        }
        menu  = site.getMenu(_module +"/#"+_entity);
        if (menu != null) {
                _title  = (String) menu.get("text");
            if (_title != null) {
                _title  = _locale.translate(_title);
                break;
            }
        }

        // 没有则从表单提取
        FormSet fset = FormSet.hasConfFile(_module+"/"+_entity)
                     ? FormSet.getInstance(_module+"/"+_entity)
                     : FormSet.getInstance(_module);
        menu  = fset.getForm(_entity);
        if (menu != null) {
                _title  = (String) Dict.get(menu, null, "@", "__text__");
            if (_title != null) {
                _title  = _locale.translate(_title);
                break;
            }
        }
        _title  = "" ;
    }
    while (false);
%>