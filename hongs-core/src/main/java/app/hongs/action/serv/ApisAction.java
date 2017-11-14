package app.hongs.action.serv;

import app.hongs.Cnst;
import app.hongs.Core;
import app.hongs.CoreConfig;
import app.hongs.action.ActionDriver;
import app.hongs.action.ActionHelper;
import app.hongs.util.Data;
import app.hongs.util.Synt;
import app.hongs.util.Tool;
import java.io.IOException;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 应用接口类
 *
 * <p>
 * 可将输入和输出数据按既定规则进行转换,
 * 内部采用 INCLUDE 将数据转 ActsAction.
 * </p>
 *
 * <h3>web.xml配置:</h3>
 * <pre>
 * &lt;servlet&gt;
 *   &lt;servlet-name&gt;ApisAction&lt;/servlet-name&gt;
 *   &lt;servlet-class&gt;app.hongs.action.ApisAction&lt;/servlet-class&gt;
 * &lt;/servlet&gt;
 * &lt;servlet-mapping&gt;
 *   &lt;servlet-name&gt;ApisAction&lt;/servlet-name&gt;
 *   &lt;url-pattern&gt;*.api&lt;/url-pattern&gt;
 * &lt;/servlet-mapping&gt;
 * </pre>
 *
 * @author Hongs
 */
public class ApisAction
  extends  ActionDriver
{
    private String dataKey;
    private String convKey;
    private String wrapKey;
    private String scokKey;

    @Override
    public void init(ServletConfig conf) throws ServletException {
        super.init(conf);

        CoreConfig cc = CoreConfig.getInstance( );
        dataKey  = cc.getProperty("core.api.data", ".data"); // 请求数据
        convKey  = cc.getProperty("core.api.conv", ".conv"); // 转换策略
        wrapKey  = cc.getProperty("core.api.wrap", ".wrap"); // 包裹数据
        scokKey  = cc.getProperty("core.api.scok", ".scok"); // 无错误码
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse rsp)
            throws ServletException, IOException {
        String act = ActionDriver.getCurrPath(req);
        if (act == null || act.length() == 0) {
            rsp.sendError(HttpServletResponse.SC_NOT_FOUND, "API URI can not be empty.");
            return;
        }

        ActionHelper hlpr = ActionDriver.getWorkCore(req).get(ActionHelper.class);

        // 提取 API 特有的参数
        String _dat  = req.getParameter(dataKey);
        String _cnv  = req.getParameter(convKey);
        String _wap  = req.getParameter(wrapKey);
        String _sok  = req.getParameter(scokKey);

        // 将请求数据处理之后传递
        if (_dat != null && _dat.length( ) != 0) {
            Map data;
            try {
                data = Synt.asMap(Data.toObject(_dat));
            } catch (ClassCastException e) {
                hlpr.error400("Can not parse value for '!data'");
                return;
            }
            hlpr.getRequestData( )
                .putAll (  data  );
        }

        // 指定转换则启用对象模式
        if (_cnv != null && _cnv.length( ) != 0) {
            Core.getInstance().put(Cnst.OBJECT_MODE, true);
        }

        // 将请求转发到动作处理器
        req.getRequestDispatcher(act).include( req , rsp );

        // 获取响应数据逐步格式化
        Map resp  = hlpr.getResponseData();
        if (resp == null) {
            return;
        }

        //** 数据转换策略 **/

        Set conv  = null;
        if (_cnv != null && _cnv.length( ) != 0) {
            try {
                conv = Synt.toTerms(_cnv );
            } catch (ClassCastException e) {
                hlpr.error400 ( "Can not parse value for '!conv'" );
                return;
            }
        }

        if (conv != null) {
            convData(resp, conv);
        }

        //** 包裹返回数据 **/

        boolean wrap;
        try {
            wrap = Synt.declare(_wap, false);
        } catch (ClassCastException e) {
            hlpr.error400("Value for '.wrap' can not be case to boolean");
            return;
        }

        if (wrap) {
            wrapData(resp);
        }

        //** 状态总是 200 **/

        boolean scok;
        try {
            scok = Synt.declare(_sok, false);
        } catch (ClassCastException e) {
            hlpr.error400("Value for '.scok' can not be case to boolean");
            return;
        }

        if (scok) {
            rsp.setStatus( javax.servlet.http.HttpServletResponse.SC_OK );
        }
    }

    public static void wrapData(Map resp) throws ServletException {
        Map    data;
        Object doto = resp.get("data");
        if (doto == null) {
            data =  new HashMap( );
            resp.put("data", data);
        }  else {
            try {
                data = (Map) doto ;
            }   catch  (ClassCastException e) {
                throw new ServletException(e);
            }
        }
        Iterator it = resp.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry et = (Map.Entry) it.next();
            Object k = et.getKey();
            if ( ! _API_RSP.contains( k )) {
                data.put(k, et.getValue());
                it.remove();
            }
        }
    }

    public static void convData(Map resp, Set<String> conv) {
        Conv cnvr = new Conv();
        boolean     all =  conv.contains( "all2str");
        cnvr.all  = all ?  new  Conv2Str( ) : new Conv2Obj( ) ;
        cnvr.num  = all || conv.contains( "num2str") ? new Conv2Str(/**/) : cnvr.all;
        cnvr.nul  = all || conv.contains("null2str") ? new ConvNull2Str() : cnvr.all;
        cnvr.bool = conv.contains("bool2num") ? new ConvBool2Num()
                  :(conv.contains("bool2str") ? new ConvBool2Str() : new Conv2Obj());
        cnvr.date = conv.contains("date2num") ? new ConvDate2Num()
                  :(conv.contains("date2sec") ? new ConvDate2Sec() : new Conv2Obj());
        cnvr.flat = conv.contains("flat.map") ? new Flat4Map(cnvr, ".")
                  :(conv.contains("flat_map") ? new Flat4Map(cnvr, "_")
                  : null);
        resp.putAll(Synt.filter(resp , cnvr));
    }

    private static final Set _API_RSP = new HashSet();
    static {
        _API_RSP.add("ok");
        _API_RSP.add("ern");
        _API_RSP.add("err");
        _API_RSP.add("msg");
        _API_RSP.add("data");
    }

    private static class Conv implements Synt.Each {
        private Conv2Obj all;
        private Conv2Obj nul;
        private Conv2Obj num;
        private Conv2Obj bool;
        private Conv2Obj date;
        private Flat4Map flat = null;

        @Override
        public Object run(Object o, Object k, int i) {
            if (o == null) {
                return nul.conv(o);
            } else
            if (o instanceof Number ) {
                return num.conv(o);
            } else
            if (o instanceof Boolean) {
                o  =  bool.conv(o);
            } else
            if (o instanceof Date) {
                o  =  date.conv(o);
            } else

            // 向下递归, 拉平层级
            if (o instanceof Map ) {
                if (flat != null ) {
                  return flat.run ((Map ) o,  "" );
                }
                return Synt.filter((Map ) o, this);
            } else
            if (o instanceof Set ) {
                return Synt.filter((Set ) o, this);
            } else
            if (o instanceof List) {
                return Synt.filter((List) o, this);
            } else
            if (o instanceof Object[]) {
                return Synt.filter((Object[]) o, this);
            }

            return all.conv(o);
        }
    }

    private static class Flat4Map {
        private final Conv  conv;
        private final String dot;

        public Flat4Map(Conv conv, String dot) {
            this.conv = conv;
            this.dot  = dot ;
        }

        public Object run(Map o, String p) {
            Map x = new LinkedHashMap( );
            for(Object ot : o.entrySet() ) {
                Map.Entry et = (Map.Entry) ot;
                String k = et.getKey().toString();
                Object v = et.getValue();
                if (v instanceof Map) {
                    Map m = (Map) v;
                    m = ( Map ) this.run(m, p + k + dot);
                    x.putAll(m);
                } else {
                    x.put(p+ k, this.conv.run(v, k, -1));
                }
            }
            return x;
        }
    }

    private static class Conv2Obj {
        public Object conv(Object o) {
            return o;
        }
    }

    private static class Conv2Str extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            if (o instanceof Number) {
                return Tool.toNumStr((Number) o);
            }
            return o.toString();
        }
    }

    private static class ConvNull2Str extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            return "";
        }
    }

    private static class ConvBool2Str extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            return ((Boolean) o) ? "1" : "";
        }
    }

    private static class ConvBool2Num extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            return ((Boolean) o) ?  1  :  0;
        }
    }

    private static class ConvDate2Num extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            return ((Date) o).getTime();
        }
    }

    private static class ConvDate2Sec extends Conv2Obj {
        @Override
        public Object conv(Object o) {
            return ((Date) o).getTime() / 1000;
        }
    }

}
