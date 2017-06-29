<%@page import="app.hongs.CoreLocale"%>
<%@page import="app.hongs.CoreConfig"%>
<%@page import="app.hongs.HongsError"%>
<%@page import="app.hongs.HongsException"%>
<%@page import="app.hongs.db.DB"%>
<%@page import="app.hongs.db.Mview"%>
<%@page import="app.hongs.action.ActionDriver"%>
<%@page import="app.hongs.action.FormSet"%>
<%@page import="app.hongs.action.NaviMap"%>
<%@page import="app.hongs.util.Dict"%>
<%@page import="app.hongs.util.Synt"%>
<%@page import="java.util.Iterator"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.Set"%>
<%@page extends="app.hongs.jsp.Pagelet"%>
<%@page contentType="text/html" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
    // 获取路径动作
    int i;
    String _module, _entity, _action;
    _module = ActionDriver.getWorkPath(request);
    i = _module.lastIndexOf('/');
    _module = _module.substring(1, i);
    i = _module.lastIndexOf('/');
    _entity = _module.substring(i+ 1);
    _module = _module.substring(0, i);
    _action = Synt.declare(request.getAttribute("list.action"), "list");

    // 获取字段集合
    CoreLocale lang;
    Map        flds;
    Set        lsts = null;
    Set        srts = null;
    do {
        try {
            Mview view = new Mview(DB.getInstance(_module).getTable(_entity));
            lang = view.getLang(  );
            flds = view.getFields();
            lsts = Synt.asTerms(view.listable);
            srts = Synt.asTerms(view.sortable);
            break;
        } catch (HongsException ex) {
            if (ex.getErrno() != 0x1039) {
                throw ex;
            }
        } catch (HongsError ex) {
            if (ex.getErrno() != 0x2a  ) {
                throw ex;
            }
        }

        FormSet form = FormSet.hasConfFile(_module +"/"+ _entity)
                     ? FormSet.getInstance(_module +"/"+ _entity)
                     : FormSet.getInstance(_module);
        flds = form.getFormTranslated(_entity );
        lsts = Synt.asTerms(Dict.getDepth(flds, "@", "listable"));
        srts = Synt.asTerms(Dict.getDepth(flds, "@", "sortable"));
        lang = CoreLocale.getInstance().clone();
        lang.loadIgnrFNF(_module);
        lang.loadIgnrFNF(_module +"/"+ _entity);
    } while (false);

    // 获取资源标题
    String id , nm ;
    id = (_module +"-"+ _entity +"-"+ _action).replace('/','-');
    do {
        NaviMap site = NaviMap.hasConfFile(_module+"/"+_entity)
                     ? NaviMap.getInstance(_module+"/"+_entity)
                     : NaviMap.getInstance(_module);
        Map menu  = site.getMenu(_module+"/#"+_entity);
        if (menu != null) {
            nm = (String) menu.get("text");
            if (nm != null) {
                nm  = lang.translate( nm );
                break;
            }
        }

        nm = Dict.getValue( flds, "", "@", "text" );
    } while (false);
%>
<h2><%=lang.translate("fore."+_action+".title", nm)%></h2>
<div id="<%=id%>" class="row">
    <div>
        <div class="toolbox col-md-8 btn-group">
            <%if ( "select".equals(_action)) {%>
            <button type="button" class="ensure btn btn-primary"><%=lang.translate("fore.select", nm)%></button>
            <%} // End If %>
            <button type="button" class="create btn btn-default"><%=lang.translate("fore.create", nm)%></button>
            <%if (!"select".equals(_action)) {%>
            <button type="button" class="update for-choose btn btn-default"><%=lang.translate("fore.update", nm)%></button>
            <button type="button" class="delete for-checks btn btn-warning" title="<%=lang.translate("fore.delete", nm)%>"><span class="glyphicon glyphicon-trash"></span></button>
            <%} // End If %>
        </div>
        <form class="findbox col-md-4 input-group" action="" method="POST">
            <input type="search" name="wd" class="form-control input-search"/>
            <span class="input-group-btn">
                <button type="submit" class="btn btn-default search" title="<%=lang.translate("fore.search", nm)%>"><span class="glyphicon glyphicon-search"></span></button>
                <button type="button" class="btn btn-default filter" title="<%=lang.translate("fore.filter", nm)%>"><span class="glyphicon glyphicon-filter"></span></button>
                <button type="button" class="btn btn-default statis" title="<%=lang.translate("fore.filter", nm)%>"><span class="glyphicon glyphicon-stats" ></span></button>
                <button type="button" class="btn btn-default export" title="<%=lang.translate("fore.filter", nm)%>"><span class="glyphicon glyphicon-save"  ></span></button>
            </span>
        </form>
    </div>
    <!-- 筛选 -->
    <form class="findbox filtbox invisible row" style="background: #ffe;">
        <div class="form-group"></div>
        <%
        Iterator it2 = flds.entrySet().iterator();
        while (it2.hasNext()) {
            Map.Entry et = (Map.Entry)it2.next( );
            Map     info = (Map ) et.getValue( );
            String  name = (String) et.getKey( );
            String  type = (String) info.get("__type__");
            String  text = (String) info.get("__text__");

            if ("@".equals(name)) {
                continue;
            }

            if (!Synt.declare(info.get("filtable"), false)) {
                continue;
            }
            // 
            if ("enum".equals(type) || "select".equals(type) || "check".equals(type) || "radio".equals(type)) {
                continue;
            }
        %>
        <div class="form-group row">
            <label class="col-sm-3 form-control-static control-label text-right"><%=text%></label>
            <div class="col-sm-6">
            <%if ("number".equals(type)) {%>
                <input type="number" class="form-control" name="<%=name%>"/>
            <%} else if ("string".equals(type)) {%>
                <input type="text" class="form-control" name="<%=name%>"/>
            <%} else if (  "date".equals(type)) {%>
                <input type="date" class="form-control" name="<%=name%>"/>
            <%} /*End If */%>
            </div>
        </div>
        <%} /*End For*/%>
        <div class="form-group row">
            <div class="col-sm-6 col-sm-offset-3">
                <button type="submit" class="btn btn-default">确定</button>
                <span style="padding:0.1em;"></span>
                <button type="reset"  class="btn btn-default">重置</button>
            </div>
        </div>
    </form>
    <!-- 报表 -->
    <form class="findbox statbox invisible row" style="backgorund: #ffe;">
        <%
        Iterator it3 = flds.entrySet().iterator();
        while (it3.hasNext()) {
            Map.Entry et = (Map.Entry)it3.next( );
            Map     info = (Map ) et.getValue( );
            String  name = (String) et.getKey( );
            String  type = (String) info.get("__type__");
            String  text = (String) info.get("__text__");

            if ("@".equals(name)) {
                continue;
            }
        %>
        <%if ("enum".equals(type) || "select".equals(type) || "check".equals(type) || "radio".equals(type)) {%>
        <div data-name="<%=name%>" data-text="<%=text%>" data-type="counts" class="col-md-6">
            <div class="row">
                <div class="col-sm-3 checkbox" style="height:300px; overflow: hidden; overflow-y: auto;"></div>
                <div class="col-sm-9 chartbox" style="height:300px; overflow: hidden; overflow-y: auto;"></div>
            </div>
        </div>
        <%} else {%>
        <%} /*End If */%>
        <%} /*End For*/%>
    </form>
    <!-- 列表 -->
    <div class="listbox table-responsive">
        <table class="table table-hover table-striped">
            <thead>
                <tr>
                    <th data-fn="id[]" data-ft="<%if ("select".equals(_action)) {%>_pick<%} else {%>_check<%}%>" class="_check">
                        <input type="checkbox" class="checkall" name="id[]"/>
                    </th>
                <%
                Iterator it = flds.entrySet().iterator();
                while (it.hasNext()) {
                    Map.Entry et = (Map.Entry)it.next( );
                    Map     info = (Map ) et.getValue( );
                    String  name = (String) et.getKey( );
                    String  type = (String) info.get("__type__");
                    String  text = (String) info.get("__text__");

                    if ("@".equals(name) || "hidden".equals(type)) {
                        continue;
                    }

                    if ( (lsts != null
                    && !lsts.contains(name) )
                    || !Synt.declare(info.get("listable"), false)) {
                        continue;
                    }

                    String ob = "";
                    String oc = "";
                    if ( (srts != null
                    &&  srts.contains(name) )
                    ||  Synt.declare(info.get("sortable"), false)) {
                        ob = (String)info.get("data-ob" );
                        if (ob == null) {
                            ob = name;
                        }
                        ob = "data-ob=\""+ob+"\"";
                        oc = "sortable";
                    }
                %>
                <%if ("number".equals(type) || "range".equals(type)) {%>
                    <th data-fn="<%=name%>" <%=ob%> class="<%=oc%> text-right"><%=text%></th>
                <%} else if ("datetime".equals(type)) {%>
                    <th data-fn="<%=name%>" data-ft="_htime" <%=ob%> class="<%=oc%> datetime"><%=text%></th>
                <%} else if ("date".equals(type)) {%>
                    <th data-fn="<%=name%>" data-ft="_date" <%=ob%> class="<%=oc%> date"><%=text%></th>
                <%} else if ("time".equals(type)) {%>
                    <th data-fn="<%=name%>" data-ft="_time" <%=ob%> class="<%=oc%> time"><%=text%></th>
                <%} else if ("file".equals(type)) {%>
                    <th data-fn="<%=name%>" data-ft="_file" <%=ob%> class="<%=oc%>"><%=text%></th>
                <%} else if ("enum".equals(type) || "select".equals(type) || "check".equals(type) || "radio".equals(type)) {%>
                    <th data-fn="<%=name%>_text" <%=ob%> class="<%=oc%>"><%=text%></th>
                <%} else if ("pick".equals(type) || "fork".equals(type)) {%>
                    <th data-fn="<%=info.get("data-ak")%>.<%=info.get("data-tk")%>" data-ft="_fork" <%=ob%> class="<%=oc%>"><%=text%></th>
                <%} else if ("form".equals(type)) {%>
                    <th data-fn="<%=info.get("name")%>.<%=info.get("data-tk")%>" data-ft="_form" <%=ob%> class="<%=oc%>"><%=text%></th>
                <%} else if (!"primary".equals(info.get("primary")) && !"foreign".equals(info.get("foreign"))) {%>
                    <th data-fn="<%=name%>" <%=ob%> class="<%=oc%>"><%=text%></th>
                <%} /*End If */%>
                <%} /*End For*/%>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>
    </div>
    <div class="pagebox"></div>
</div>
<script type="text/javascript" src="static/addons/echarts/echarts.js"></script>
<script type="text/javascript">
(function($) {
    var context = $("#<%=id%>");
    var toolbox = context.find(".toolbox");
    var formbox = context.find(".findbox");
    var findbox = formbox.eq(0);
    var filtbox = context.find(".filtbox");
    var statbox = context.find(".statbox");

    context.hsList({
        loadUrl : "<%=_module%>/<%=_entity%>/search.act?md=2",
        openUrls: [
            ['.create', '<%=_module%>/<%=_entity%>/form.html?md=0', '@'],
            ['.update', '<%=_module%>/<%=_entity%>/form_edit.html?md=1&id={ID}', '@']
        ],
        sendUrls: [
            ['.delete', '<%=_module%>/<%=_entity%>/delete.act', '<%=lang.translate("fore.delete.confirm", nm)%>']
        ],
        _fill__fork: hsListFillFork
    });

    context.find(".export").click(function() {
        var url = "<%=_module%>/<%=_entity%>/export/search.act?";
        var req = formbox.serialize( );
        window.open(url+req, "_blank");
    });

    function statis() {
        var rb = [];
        statbox.find("[data-type=statis]").each(function() {
            rb.push($(this).attr("data-name"));
        });
        if (rb.length == 0) {
            return;
        }

        $.ajax({
            url: "<%=_module%>/<%=_entity%>/statis/search.act?rb="+rb.join(","),
            data: formbox.serialize(),
            dataType: "json",
            context: statbox,
            success: function(rst) {
            }
        });
    }

    function counts() {
        var rb = [];
        statbox.find("[data-type=counts]").each(function() {
            rb.push($(this).attr("data-name"));
        });
        if (rb.length == 0) {
            return;
        }

        $.ajax({
            url: "<%=_module%>/<%=_entity%>/counts/search.act?rb="+rb.join(",")+"&md=3",
            data: formbox.serialize(),
            dataType: "json",
            context: statbox,
            success: function(rst) {
                for (var k in rst.info) {
                     if (k == "__total__") continue;
                     var d  = rst.info[k];
                     var n  = statbox.find("[data-name='"+k+"']");
                     setCheck(n, d);
                     setChart(n, d);
                }
                
                var list = context.data( "HsList" );
                var data = hsSerialDic (list._data);
                for (var k in data) {
                    statbox.find("[name='"+k+"']" ).val(data[k]);
                }
            }
        });
    }

    function setCheck(box, data) {
        var name  = box.data("name");
        var text  = box.data("text");
        var box2  = box.find( ".checkbox").empty();
        
        var label = $('<label></label>');
        var check = $('<input type="checkbox" class="checkall"/>');
        var title = $('<span></span>')
                .text("全部 "+ text);
            label.append(check).append(title).appendTo(box2);

        for(var i = 0; i < data.length; i ++) {
            var v = data[i];
            label = $('<label></label>')
                .attr("title", v.title +" ("+ v.count + ")");
            check = $('<input type="checkbox" class="checkone"/>')
                .attr("name" , name+".")
                .attr("value", v.value );
            title = $('<span></span>')
                .text( v.title);
            label.append(check).append(title).appendTo(box2);
        }
    }

    function setChart(box, data) {
        var legendData = [];
        var seriesData = [];
        for(var i = 0; i < data.length; i ++) {
            var v = data[i];
            legendData.push(v.label);
            seriesData.push({
                value : v.count,
                name  : v.title
            });
        }

        var opts = {
            series : [
                {
                    data: seriesData,
                    type: 'pie',
                    radius: '80%',
                    center: ['50%', '50%']
                }
            ]
        };

        box.data("echart").resize();
        box.data("echart").setOption(opts);
    }

    if (filtbox.find(".form-group").size() == 2) {
        findbox.find(".filter").hide( );
    }
    if (statbox.children().size() == 0) {
        findbox.find(".statis").hide( );
    }

    findbox.find(".filter").click(function() {
        filtbox.toggleClass("invisible");
        if (!filtbox.is("invisible")) {
            filtbox.trigger("opened");
        }
    });
    findbox.find(".statis").click(function() {
        statbox.toggleClass("invisible");
        if (!statbox.is("invisible")) {
            statbox.trigger("opened");
        }
    });
    findbox.find(".search").click(function() {
        filtbox.addClass("invisible");
    });
    filtbox.find(":submit").click(function() {
        filtbox.addClass("invisible");
    });
    filtbox.find(":reset" ).click(function() {
        setTimeout(function() {
            filtbox.find(":submit").click();
        }, 500);
    });

    toolbox.on("saveBack", function() {
        if (statbox.is(".invisible")) {
            statbox.data("changed", true );
        } else {
            statbox.data("changed", false);
            setTimeout(function() {
                statis();
                counts();
            }, 1000);
        }
    });
    formbox.on("submit", function(  ) {
        if (statbox.is(".invisible")) {
            statbox.data("changed", true );
        } else {
            statbox.data("changed", false);
            setTimeout(function() {
                statis();
                counts();
            }, 1000);
        }
    });
    statbox.on("opened", function( ) {
        if (statbox.data("changed")) {
            statis();
            counts();
        }
    });
    statbox.on("change", ":checkbox", function() {
        findbox.find(":submit").click();
    });

    statbox.data("changed", true);
    statbox.find("[data-type=counts]").each(function() {
        var box = $(this).find(".chartbox")[0];
        var obj = echarts.init(box);
        $(this).data("echart", obj);
    });
})(jQuery);
</script>