<% //-------------------------------------------- All Page Common Include Start %>
<%@ include file="/common/charset/current.inc" %>
<%@ page import="common_utils.*" %>
<%@ include file="/common/set_base_utils.inc" %>
<%@ include file="/include/language_set.inc" %>
<%@ include file="/include/check_domain.inc" %>
<% //-------------------------------------------- All Page Common Include End %>
<% //-------------------------------------------- Authorize Page Common Include Start %>
<%@ include file="/adminsvc/include/auth_set.inc" %>
<%@ include file="/adminsvc/include/auth_check.inc" %>
<% //-------------------------------------------- Authorize Page Common Include End %>
<%@ include file="/common/database_connection.inc" %>
<%
configUtil.set_websvc_config(CONF_DOMAINID);
%>
<%@ page import="java.util.Vector, pdisk_pds.*, pdisk_user.*,  mgmt_explorer.*, pdisk_org_cowork.*" %>
<%
String UserID = request.getParameter("UserID")!=null?request.getParameter("UserID"):"";
String RegDate = request.getParameter("RegDate")!=null?request.getParameter("RegDate"):"";
String DomainID = request.getParameter("DID")!=null?request.getParameter("DID"):"";
String Number = request.getParameter("Number")!=null?request.getParameter("Number"):"";
String TableRows = request.getParameter("TableRows")!=null?request.getParameter("Number"):"";;
String likeColumn = request.getParameter("likeColumn") != null ? request.getParameter("likeColumn") : ""; // "UserID" Column
String likeValue = request.getParameter("likeValue") != null ? request.getParameter("likeValue") : ""; // Inputbox Value

util_string CheckString = new util_string();

UserID = CheckString.check_parameter(UserID);
RegDate = CheckString.check_parameter(RegDate);
DomainID = CheckString.check_parameter(DomainID);
Number = CheckString.check_parameter(Number);
likeColumn = CheckString.check_parameter(likeColumn);
likeValue = CheckString.check_parameter(likeValue);
if ( UserID != null ) UserID = CheckString.convert_parameter_for_sql(UserID);
if ( RegDate != null ) RegDate = CheckString.convert_parameter_for_sql(RegDate);
if ( DomainID != null ) DomainID = CheckString.convert_parameter_for_sql(DomainID);
if ( Number != null ) Number = CheckString.convert_parameter_for_sql(Number);
util_string stringUtil = new util_string(CONF_CHARSET);
if ( !"".equals(likeValue) ) {
	likeValue = stringUtil.convert_charset(likeValue);
}
//-------------------------

%>
<% //-------------------------------------------- Post Parameter variable END%>
<%
if ( UserID.equals("") || RegDate.equals(""))
{
	%>
	<script language="javascript">
	
	alert("<fmt:message key='MSG.push_missing_info' />");
	document.location.href="./pds_list.jsp";
	//-->
	</script>
	<%
	dbUtil.close_connection();
	return;
}

String strPage = request.getParameter("Page");

int Page = 1;

if (strPage != null) Page = Integer.parseInt(strPage);


Pds pds_info = new Pds();
pds_info.init_query(dbUtil.db_conn, configUtil.conf_dbtype);
pds_info.update_hit(Number, DomainID, UserID, RegDate);

Vector retVector = pds_info.get_list("DomainID", DomainID, "UserID", UserID, "CreatedDate", RegDate);

if (retVector == null)
{
	%>
	<script language="javascript">
	<!--
	alert("<fmt:message key='MSG.no_data' />");
	document.location.href="./pds_list.jsp";
	//-->
	</script>
	<%
	dbUtil.close_connection();
	return;
}

PdsPack dataPack = null;
UsersPack userPack = null;

Users pdisk_users = new Users();
pdisk_users.init_query(dbUtil.db_conn, configUtil.conf_dbtype);

dataPack = (PdsPack)retVector.elementAt(0);

if ("-1".equals(DomainID)) userPack = pdisk_users.get_info_by_UserID("1000000000000", dataPack.UserID);
else userPack = pdisk_users.get_info_by_UserID(CONF_DOMAINID, dataPack.UserID);

String web_http_port = configUtil.read_config(CONF_DOMAINID, "pdrive.conf", "web_http_port");
if (web_http_port.equals("")) web_http_port = "80";

Vector org_cowork_list = null;
OrgCoworkPack org_cowork_pack = null;
OrgCowork org_cowork = new OrgCowork();
org_cowork.init_query(dbUtil.db_conn, configUtil.conf_dbtype);
if ("-1".equals(DomainID)) {
	org_cowork_list = org_cowork.get_list_rootcowork("DomainID", "1000000000000", "HomeFolder", "no", "CreateDate");
} else {
	org_cowork_list = org_cowork.get_list_rootcowork("DomainID", CONF_DOMAINID, "HomeFolder", "no", "CreateDate");
}

String file_http_port = configUtil.read_config(CONF_DOMAINID, "pdrive.conf", "file_http_port");
if (file_http_port.equals("")) file_http_port = "80";

String Server = request.getServerName();
String DiskOwner = "";
String DiskType = "";
String Partition = "";
String FolderPath = "";
String FileServer = "";

String FolderName = dataPack.Subject;
FolderName = FolderName.replaceAll("[\\\\/:*?\"<>|.]", "");
FolderName = FolderName.replaceAll("&quot;", "");
FolderName = FolderName.replaceAll("&lt;", "");
FolderName = FolderName.replaceAll("&gt;", "");
FolderName = FolderName.replaceAll("%", "%25");
FolderName = FolderName.trim();

if ( org_cowork_list != null ) {
	org_cowork_pack = (OrgCoworkPack)org_cowork_list.elementAt(0);
	
	DiskOwner = org_cowork_pack.CoworkID;
	DiskType = "orgcowork";
	Partition = org_cowork_pack.Partition;
	FolderPath = "/"+"REFERENCE"+"/"+dataPack.CreatedDate.substring(0, 6)+"/"+dataPack.Number+"."+FolderName;
	FileServer = org_cowork_pack.Server;
}


String Ssl_protocol = "http";
boolean isSescure = request.isSecure();
if (isSescure == true)
{
	Ssl_protocol = "https";
	file_http_port = configUtil.read_config(CONF_DOMAINID, "pdrive.conf", "file_ssl_port");
	if (file_http_port.equals("")) file_http_port = "443";
}

util_crypt utilCrypt = new util_crypt();
String DomainID_des = utilCrypt.crypt_des(DomainID, configUtil.conf_deskey);
DiskOwner = utilCrypt.crypt_des(DiskOwner, configUtil.conf_deskey);
DiskType = utilCrypt.crypt_des(DiskType, configUtil.conf_deskey);
Partition = utilCrypt.crypt_des(Partition, configUtil.conf_deskey);
FolderPath = utilCrypt.crypt_des(FolderPath, configUtil.conf_deskey);

String CON_pds_all_domain = util_msg.getMessage("CON.pds_root");

PdsImg pds_img = new PdsImg();
pds_img.init_query(dbUtil.db_conn, configUtil.conf_dbtype);
Vector retImg = pds_img.get_list(DomainID, Number);
int img_num = 0;
String [] img_file = null;
if(retImg != null)
{
	img_num = retImg.size();
	img_file = new String[img_num+1];
	for(int i=0; i<img_num; i++)
	{
		img_file[i] = pds_img.get_img_string(DomainID, Number, Integer.toString(i));
	}
}
%>
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title><%= configUtil.conf_explorertitlebar %></title>
	<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
		<%@ include file="/include/head.inc" %>
	<link rel="stylesheet" href="/include/css/vendor.min.css">
	<link rel="stylesheet" href="/include/css/elephant.css">
	<link rel="stylesheet" href="/include/css/application.css">
	<link rel="stylesheet" href="/include/css/demo.min.css">
	<link rel="stylesheet" href="/include/css/custom.css">	
	<link rel="stylesheet" href="/include/css/jquery-ui.css"/>
	<script type="text/javascript" src="/include/js/jquery.js"></script>
	<script type="text/javascript" src="/include/js/jquery-ui.js"></script>
	<script type="text/javascript" src="/websvc/include/function_get_page_list.js"></script>
	<script type="text/javascript">
	
	function go_list() {
		$("#progress").addClass('spinner');
		document.form_to_save.submit();
	}
	
	function goto_modify(CreatedDate)
	{
		$("#progress").addClass('spinner');
		document.form_to_save.CreatedDate.value = CreatedDate;
		document.form_to_save.action = "./pds_mod_form.jsp";
		document.form_to_save.submit();
	}
	function init() {
		makeContents();
		$.post('<%=Ssl_protocol%>://<%=Server%>:<%=file_http_port%>/fsvrsvc/get_list_doc_export.jsp', { 
			FileServer : "<%=FileServer%>",
			DomainID : "<%=DomainID_des%>",
			DiskOwner : "<%=DiskOwner%>",
			DiskType : "<%=DiskType%>",
			Partition : "<%=Partition%>",
			FolderPath : "<%=FolderPath%>"
		},
		reciveInitGetList);
	}

	function makeContents() {
		var str = "<%=dataPack.Contents %>" ;
	 	//console.log("str = "+str);
	    str = str.replace(/&lt;/gi, "<");
	    str = str.replace(/&gt;/gi, ">");
	    str = str.replace(/&quot;/gi, "\"");
	    str = str.replace(/&amp;/gi, "&");
	    
	    var change = document.getElementById('changeHtml');
	    change.innerHTML = str;
	    <%
		for(int i=0; i<img_num; i++)
		{
			%>
			$("#img_<%=i%>").attr("src", "<%=img_file[i]%>");
			<%
		}
		%>
	}
	
	function reciveInitGetList(data) {
		
		result = data.substring((data.indexOf("\r\n")) + 2);

		if ( "Success" != result.substring(0, 7) ) return;

		contents = result.substring( (result.indexOf("\r\n")) + 2 );
	    list = contents.split("\r\n");

	    Folder = 0x20;
	    File   = 0x40;

	    var View = "";
	 	var str = "<%=dataPack.Contents %>" ;
	 	
	    for( i=0; i< list.length ; i++ ) {
	    	list_info = list[i].split("\t");

	    	if ( (parseInt(list_info[1]) & File) != 0 ) {
	    		DomainID = encodeURIComponent("<%=DomainID_des%>");
	    		DiskOwner = encodeURIComponent("<%=DiskOwner%>");
				DiskType = encodeURIComponent("<%=DiskType%>");
				Partition = encodeURIComponent("<%=Partition%>");
				FolderPath = encodeURIComponent(list_info[3]);
	    		downURL = "<%=Ssl_protocol%>://<%=FileServer%>:<%=file_http_port%>/fsvrsvc/get_file_doc_export.jsp?DomainID="+DomainID+"&DiskOwner="+DiskOwner+"&DiskType="+DiskType+"&Partition="+Partition+"&FolderPath="+FolderPath+"&SystemLang="+navigator.systemLanguage; 
	    		View = View+ "<span>&nbsp;<a  href=\""+downURL+"\" target=\"FileDownTmp\">"+list_info[0]+"</a></span><br/>";
	    		
	    	}
	    }

	    var FileViewObj = document.getElementById('DownLoadFileList');
	    FileViewObj.innerHTML = View;
	}
	</script>
	<style>
	#changeHtml ul {
		list-style: disc;
		padding-left: 40px;
	}
	#changeHtml ul li {
		list-style: disc;
	}
	
	#changeHtml ol {
		list-style: decimal;
		padding-left: 40px;
	}
	#changeHtml ol li {
		list-style: decimal;
	}
	.line_break {
	   word-break: break-all;
	   /* white-space: break-spaces; */
	   white-space:initial;
	}
	
	blockquote {
	 	font-size: 13px;
	}
	</style>
</head>
<body class="layout layout-header-fixed overflow-h layout-sidebar-fixed"  onload="init();">
<div class="scroll-wrap" >
	<!-- header Menu -->
	<%@ include file="/adminsvc/include/html_header_menu.inc" %>
	<!-- //header Menu -->
	
	<div class="layout-main">
		<!-- Side Menu -->
		<%@ include file="/adminsvc/include/html_side_menu.inc" %>
		<!-- //Side Menu -->
		<!-- Contents -->
		<div id="BodyArea" class="layout-content" >
			<div class="layout-content-body">
				
					<div class="row gutter">
					<div class="col-xs-12">
						<div class="card">
							<div class="card-header">
								<h3 class="big"><fmt:message key="CON.view_details" /></h3>
							
							</div>
							<div class="card-body table-responsive">
								<table class="table type-18">
								<tr>
								<th><fmt:message key="CON.title" /></th>
								<td class="line_break">
							<%
									if ("-1".equals(DomainID)) 
										out.print("["+CON_pds_all_domain+"] ");
								
								out.print(dataPack.Subject);
								%>
								</td>
								</tr>
								<tr>
									<th><fmt:message key="CON.writer_name" /><span>(<fmt:message key="CON.id" />)</span></th>
									<td>
										<% 
										if( userPack != null )
											out.print(userPack.Name);
										if(!dataPack.DomainID.equals("-1"))
											out.print(" ("+dataPack.UserID+")");
										%>
									</td>
								</tr>
								<tr>
									<th><fmt:message key="CON.write_day" /></th>
									<td>
		<%
									if (dataPack.CreatedDate != null && !"".equals(dataPack.CreatedDate)) {
										out.print( dataPack.CreatedDate.substring(0,   4) + "-" +
									               dataPack.CreatedDate.substring(4,   6) + "-" +
												   dataPack.CreatedDate.substring(6,   8) + " " +
									               dataPack.CreatedDate.substring(8,  10) + ":" +
												   dataPack.CreatedDate.substring(10, 12) + ":" +
									               dataPack.CreatedDate.substring(12, 14) );
									} else {
										out.print("-");
									}
		%>
									</td>
								</tr>
								<tr>
									<th><fmt:message key="CON.views"/></th>
									<td><%=dataPack.Hit%></td>
								</tr>
								<tr>
									<th><fmt:message key="CON.contents" /></th>
									<td id="changeHtml" class="line_break" >
									
									</td>	
								</tr>
								<tr>
									<th>
										<fmt:message key="CON.attachments" />
									</th>
									<td>
										<div id="DownLoadFileList"  class="download_file_list" style="width:98%;display:block;"></div>
									
									</td>
								</tr>
							</table>
							</div>
						</div>
						<div class="text-right">
							<%
							if ( ("-1".equals(DomainID) && !"1000000000000".equals(CONF_DOMAINID)) || !dataPack.UserID.equals(adminAuth.UserID)) {
								
							} else {
								%>
								<button class="btn btn-default btn-basic" type="button" onclick="goto_modify('<%=dataPack.CreatedDate%>')"> <fmt:message key="CON.modify" /></button>
								<%
							}
							%>
							<button class="btn btn-default btn-basic" type="button" onclick="go_list()"> <fmt:message key="CON.list" /></button>
						</div>
					</div>
				</div>
			</div>
		</div>
	
	<%@ include file="/adminsvc/include/html_footer.inc" %>
	<!-- //Footer -->
	</div>
	</div>

	<!-- spinner -->
	<div id="progress" class="spinner-success spinner-lg sq-100"></div>
	<!-- //spinner -->
	
	<form name="form_to_save" method="post" action="./pds_list.jsp">
		<input type="hidden" name="DID" value="<%=dataPack.DomainID%>"/>
		<input type="hidden" name="CreatedDate" value=""/>
		<input type="hidden" name="UserID" value="<%=dataPack.UserID%>"/>
		<input type="hidden" name="Number" value="<%=dataPack.Number%>"/>
		<input type="hidden" name="Page" value="<%=Page%>"/>
		<input type="hidden" name="TableRows" value="<%=TableRows%>"/>
		<input type="hidden" name="likeColumn" value="<%=likeColumn%>"/>
		<input type="hidden" name="likeValue" value="<%=likeValue%>"/>
	</form>
	
	<script src="/include/js/vendor.js"></script>
	<script src="/include/js/elephant.js"></script>
	<script src="/include/js/application.js"></script>
	<script src="/include/js/demo.js"></script>
	<script src="/include/js/jquery-autocomplete.js"></script>
</body>
</html>
<%@ include file="/common/database_close.inc" %>