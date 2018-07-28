package io.github.ihongs.dh.search;

import io.github.ihongs.Cnst;
import io.github.ihongs.Core;
import io.github.ihongs.HongsException;
import io.github.ihongs.HongsExemption;
import io.github.ihongs.action.FormSet;
import io.github.ihongs.dh.lucene.LuceneRecord;
import io.github.ihongs.util.thread.Block;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.apache.lucene.document.Document;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.Term;

/**
 * 搜索记录
 *
 * 增加写锁避免同时写入导致失败
 * 注意: 此类的对象无法使用事务
 *
 * @author Hongs
 */
public class SearchEntity extends LuceneRecord {

    private static final Map<String, IndexWriter> WRITERS = new HashMap();

    public SearchEntity(Map form, String path, String name) {
        super(form, path, name);
    }

    public SearchEntity(Map form) {
        this (form, null, null);
    }

    /**
     * 获取实例
     * 存储为 conf/form 表单为 conf.form
     * 表单缺失则尝试获取 conf/form.form
     * 实例生命周期将交由 Core 维护
     * @param conf
     * @param form
     * @return
     * @throws HongsException
     */
    public static SearchEntity getInstance(String conf, String form) throws HongsException {
        String code = SearchEntity.class.getName() +":"+ conf +"."+ form;
        Core   core = Core.getInstance( );
        if ( ! core.containsKey( code ) ) {
            String path = conf +"/"+ form;
            String name = conf +"."+ form;
            Map    fxrm = FormSet.getInstance(conf).getForm(form);

            // 表单配置中可指定数据路径
            Map c = (Map) fxrm.get("@");
            if (c!= null) {
                String p;
                p = (String) c.get("db-path");
                if (null != p && p.length() != 0) {
                    path  = p;
                }
                p = (String) c.get("db-name");
                if (null != p && p.length() != 0) {
                    name  = p;
                }
            }

            SearchEntity inst = new SearchEntity(fxrm, path,name);
            core.put( code, inst ) ; return inst ;
        } else {
            return  (SearchEntity) core.got(code);
        }
    }

    @Override
    public IndexWriter getWriter() throws HongsException {
        final String kn = SearchEntity.class.getName() + ":" + getDbName();
        IndexWriter  iw = WRITERS.get (kn);
        if (iw == null) {
            iw = super.getWriter();
            WRITERS.put ( kn, iw );
        }
        return iw;
    }

    @Override
    public void addDoc(final Document doc) throws HongsException {
        final String kn = SearchEntity.class.getName() + ":" + getDbName();
        Block.Locker lk = Block.getLocker(kn);
        lk.lock();
        try {
            IndexWriter iw = getWriter ( );
            iw.addDocument (doc);
            iw.commit();
        } catch (IOException ex) {
            throw new HongsExemption.Common(ex);
        } finally {
            lk.unlock();
        }
    }

    @Override
    public void setDoc(final String id, final Document doc) throws HongsException {
        final String kn = SearchEntity.class.getName() + ":" + getDbName();
        Block.Locker lk = Block.getLocker(kn);
        lk.lock();
        try {
            IndexWriter iw = getWriter ( );
            iw.updateDocument (new Term(Cnst.ID_KEY, id), doc);
            iw.commit();
        } catch (IOException ex) {
            throw new HongsExemption.Common(ex);
        } finally {
            lk.unlock();
        }
    }

    @Override
    public void delDoc(final String id) throws HongsException {
        final String kn = SearchEntity.class.getName() + ":" + getDbName();
        Block.Locker lk = Block.getLocker(kn);
        lk.lock();
        try {
            IndexWriter iw = getWriter ( );
            iw.deleteDocuments(new Term(Cnst.ID_KEY, id) /**/);
            iw.commit();
        } catch (IOException ex) {
            throw new HongsExemption.Common(ex);
        } finally {
            lk.unlock();
        }
    }

    @Override
    public void close() {
        final String kn = SearchEntity.class.getName() + ":" + getDbName();
        super . close();
        WRITERS.remove(kn);
    }

}