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
<%@ page import="java.util.Vector, pdisk_pds.*, pdisk_user.*" %>
<%
configUtil.set_websvc_config(CONF_DOMAINID);

checkFeature = configUtil.read_config(CONF_DOMAINID, "orgcowork.conf", "use_pds");
if ( checkFeature == null || "".equals(checkFeature) )
	checkFeature = "no";
%>
<%
String likeColumn = request.getParameter("likeColumn")!=null?request.getParameter("likeColumn"):"";
String likeValue= request.getParameter("likeValue")!=null?request.getParameter("likeValue"):"";
String equalColumn = request.getParameter("equalColumn")!=null?request.getParameter("equalColumn"):"";
String equalValue = request.getParameter("equalValue")!=null?request.getParameter("equalValue"):"";
String Order = request.getParameter("Order")!=null?request.getParameter("Order"):"CreatedDate";
String OrderType = request.getParameter("OrderType")!=null?request.getParameter("OrderType"):"desc";
String strPage = request.getParameter("Page");

util_string CheckString = new util_string();
if ( equalColumn != null ) equalColumn = CheckString.convert_parameter_for_sql(equalColumn);
if ( equalValue != null ) equalValue = CheckString.convert_parameter_for_sql(equalValue);
if ( Order != null ) Order = CheckString.convert_parameter_for_sql(Order);
if ( OrderType != null ) OrderType = CheckString.convert_parameter_for_sql(OrderType);
if ( strPage != null ) strPage = CheckString.convert_parameter_for_sql(strPage);

int Page = 1;

if (strPage != null && !"".equals(strPage)) Page = Integer.parseInt(strPage);

likeColumn = CheckString.check_parameter(likeColumn);
likeValue = CheckString.check_parameter(likeValue);
equalColumn = CheckString.check_parameter(equalColumn);
equalValue = CheckString.check_parameter(equalValue);
Order = CheckString.check_parameter(Order);
OrderType = CheckString.check_parameter(OrderType);
strPage = CheckString.check_parameter(strPage);

util_string stringUtil = new util_string(CONF_CHARSET);
if ( !"".equals(likeValue) ) {
	likeValue = stringUtil.convert_charset(likeValue);
}

String strTableRows = request.getParameter("TableRows");

int TableRows = 0;

if ( strTableRows != null && !"".equals(strTableRows) ) {
	TableRows = Integer.parseInt(strTableRows);
} else {
	strTableRows = configUtil.read_config(CONF_DOMAINID, "websvc.conf", "board_num_per_page");
	TableRows = Integer.parseInt(strTableRows);
}

util_dateinfo d = new util_dateinfo();
String new_term = d.get_today_ymdhis(0, 0, -3);

PdsPageList pds_list = new PdsPageList(CONF_DOMAINID);
pds_list.init_query(dbUtil.db_conn, configUtil.conf_dbtype);
pds_list.debug = false;
pds_list.num_per_page = TableRows;

Users pdisk_users = new Users();
pdisk_users.init_query(dbUtil.db_conn, configUtil.conf_dbtype);

Vector retVector = null;
PdsPack dataPack = null;
UsersPack userPack = null;

if("".equals(likeValue))
	retVector = pds_list.get_list_notice(CONF_DOMAINID,"-1", "", "", "", "", Order, OrderType, Page);
else
{
	if(likeColumn.indexOf(",") > -1)
	{
		String [] arrColumn = likeColumn.split(",");
		retVector = pds_list.get_list_notice2(CONF_DOMAINID,"-1", arrColumn[0], likeValue, arrColumn[1], likeValue, "", "", Order, OrderType, Page);
	}
	else
		retVector = pds_list.get_list_notice(CONF_DOMAINID,"-1", likeColumn, likeValue, "", "", Order, OrderType, Page);
}
%>
<%@ page import="java.util.Vector, pdisk_user.*" %>
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title><%=configUtil.conf_explorertitlebar%></title>
	<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
		<%@ include file="/include/head.inc" %>
	<link rel="stylesheet" href="/include/css/vendor.min.css">
	<link rel="stylesheet" href="/include/css/elephant.css">
	<link rel="stylesheet" href="/include/css/application.css">
	<link rel="stylesheet" href="/include/css/demo.min.css">
	<link rel="stylesheet" href="/include/css/custom.css">
	<link rel="stylesheet" href="/include/css/jquery-ui.css"/>
	<script src="/include/js/jquery.js"></script>
	<script src="/include/js/jquery-ui.js"></script>
	<script src="/websvc/include/function_get_page_list.js"></script>
	<script type="text/javascript">
	<!--
		<%-- ChangeTableRows --%>
	function paging(page)
	{
		document.search.Page.value = page;
		document.search.submit();
	}

	function view(id, id2, id3, id4)
	{
		console.log(id4);
		document.form_to_save.UserID.value=id;
		document.form_to_save.RegDate.value=id2;
		document.form_to_save.DID.value=id3;
		document.form_to_save.Number.value=id4;

		document.form_to_save.action="./pds_view.jsp";
		document.form_to_save.submit();
	}

	function go_write()
	{
		document.form_to_save.action="./pds_add_form.jsp";
		document.form_to_save.submit();
	}
	function changeTableRows(rows) {
		document.search.TableRows.value = rows;
		document.search.submit();
	}
	
	function go_del()
	{
		var objArray = [];
		$("input[name='selectChk']:checked").each(function () {
			var jsonObject = { 
				"UserID" : $(this).attr("data-userid"), 
				"CreatedDate" : $(this).attr("data-createddate"), 
				"DomainID" : $(this).attr("data-domainid"), 
				"Number" : $(this).attr("data-number")  
			}
		    objArray.push(jsonObject);
		});
		
		if (objArray.length < 1) {
			alert("<fmt:message key='MSG.check_alert'/>");
			return;
		}
		if(confirm("<fmt:message key='MSG.board_cant_restored'/>\n\n<fmt:message key='MSG.post_delete_confirm'/>"))
		{
			$.ajax({
				type : "POST",
				url  : "./pds_del.jsp",
				data : { "array" : JSON.stringify(objArray)},				
				dataType : "text",
				beforeSend:function()
				{
					$("#progress").addClass('spinner');
				},
				success:function(args)
				{
					//alert(args);
					location.reload();
				},
				complete:function()
			    {
					$("#progress").removeClass('spinner');
			    },
			    error : function(error) 
			    {
			    	alert("<fmt:message key='MSG.unkown_error' />");
			    	$("#progress").removeClass('spinner');
			    	location.reload();
			    }
				
			});
		}
	}
	$(document).ready( function() {
		if ( "<%=retVector%>" != "null" )
		{
			$("#<%=Order%>").removeClass("icon-sort");
			$("#<%=Order%>").addClass("icon-sort-<%=OrderType%>");
			$("#<%=Order%>").css("border-bottom-color", "#13b6bc");
			$("#<%=Order%>").css("color", "#13b6bc");
		}
		else
		{
			$("#<%=Order%>").removeClass("icon-sort-desc");
			$("#<%=Order%>").removeClass("icon-sort-asc");
			$("#<%=Order%>").addClass("icon-sort");
			$("#<%=Order%>").css("border-bottom-color", "#e7e7ec");
		}
		$("#AllChk").click(function() {
			var chk;
    		if ( $(this).is(":checked") )
    			chk = true;
    		else
    			chk = false;
    		
			$("input[name=selectChk]").each(function() {
				$(this).prop("checked", chk);
			});
		});
		
		$("input[name=selectChk]").click(function() {
			
    		if ( $(this).is(":checked") )
    		{
    			$(this).prop("checked", true);
    		}
    		else
    		{
    			$(this).prop("checked", false);
    		}
    		
			var all_length = $("input[name=selectChk]").length;
			var chk_length = $("input[name=selectChk]:checked").length;
    		
    		if ( all_length == chk_length )
    			$("#AllChk").prop("checked", true);
    		else
    			$("#AllChk").prop("checked", false);
    		
		});
		
		$("#likeValue").keydown(function(event) {
			switch(event.keyCode) {
				case 13:
					do_check();
			}
		});
	});
	function Ordersearch(order)
  	{
  		document.search.Order.value=order;

  		if (document.search.OrderType.value=="desc")
  		{
  			document.search.OrderType.value = "asc";
  		}
  		else
  		{
  			document.search.OrderType.value = "desc";
  		}

  		document.search.submit();
  	}
	
	var idSpecialCharacterArray = new Array ("<", ">", "\\", "'", "\"", "&");
	function isIdSpecialCharacter (ch)
	{
	    for (j=0; j < idSpecialCharacterArray.length; ++j)
	    {
	         if (ch == idSpecialCharacterArray[j])
	             return true;
	    }
	    return false;
	}
	
	function do_check () {

		if($("#likeValue").val().length == 1)
		{
			alert("<fmt:message key='CON.search_alert1'/>");
			document.search.likeValue.focus();
			return false;
		}
		
	    for(k=0 ; k < document.search.likeValue.value.length ; k++)
		{
			 if ( isIdSpecialCharacter(document.search.likeValue.value.charAt(k)) )
	         {
	                  alert("< > \\ \' \" " + "<fmt:message key='MSG.is_not_a_valid_character' />");
	                  document.search.likeValue.focus();
	                  return;
	         }
	    }

		if (document.search.likeValue.value.length > 255)
		{
			alert("<fmt:message key='MSG.value_length_limit' > <fmt:param value='255'/> </fmt:message>");
			document.search.likeValue.focus();
			return;
		}

		search.submit();
	}
	//-->
	</script>
	<style>
	.line_break {
	   word-break: break-all;
	   white-space: break-spaces;
	}
	</style>
	</head>
	<body class="layout layout-header-fixed layout-sidebar-fixed overflow-h">
	<div class="scroll-wrap">
	
		<!-- header Menu -->
		<%@ include file="/adminsvc/include/html_header_menu.inc" %>
		<!-- //header Menu -->
		
		<div class="layout-main">
			<!-- Side Menu -->
			<%@ include file="/adminsvc/include/html_side_menu.inc" %>
			<!-- //Side Menu -->
			
			<!-- Contents -->
			<div class="layout-content">
				<div class="layout-content-body">
					<div class="row gutter">
						<div class="page-title">
							<h2><%=PageTitle%></h2>
							<p><fmt:message key='DES.pds_info' /></p>
						</div>
					</div>
					<form id="search" name="search" method="post" action="./pds_list.jsp">
						<input type="hidden" name="Page"         value="1" />
						<input type="hidden" name="TableRows"    value="<%= TableRows %>" />
						<input type="hidden" name="Order"        value="<%= Order %>" />
						<input type="hidden" name="OrderType"    value="<%= OrderType %>" />
				
					<div class="row gutter">
						<div class="col-xs-12">
							<div class="card">
								<div class="card-header no-title">
									<div class="left-position">
									
								</div>
								<div class="right-position">
									<select name="likeColumn" id="likeColumn" class="form-control d-ib">
										<option value="Subject,SearchContents" <% if ("Subject,SearchContents".equals(likeColumn)) out.print("selected"); %>><fmt:message key="CON.title" /> + <fmt:message key='CON.contents'/></option>
										<option value="Subject" <% if ("Subject".equals(likeColumn)) out.print("selected"); %>><fmt:message key="CON.title" /></option>
										<option value="SearchContents" <% if ("SearchContents".equals(likeColumn)) out.print("selected"); %>><fmt:message key='CON.contents'/></option>
										<option value="UserID" <% if ("UserID".equals(likeColumn)) out.print("selected"); %>><fmt:message key='CON.writer_id'/></option>
										<option value="Name" <% if ("Name".equals(likeColumn)) out.print("selected"); %>><fmt:message key='CON.writer_name'/></option>
									</select>
									<div class="input-with-icon d-ib">
										<input name="likeValue" id="likeValue" class="form-control" type="text" placeholder=<fmt:message key="CON.please_enter_key_word" /> value="<%=likeValue%>" onkeydown="javascript:if(event.keyCode == 13) return false;">
										<span class="icon icon-search input-icon"></span>
									</div>
									<button class="btn btn-default btn-sm" type="button" onclick="do_check()" ><fmt:message key="BTN.search" /></button>
									<button class="btn btn-sm btn-default btn-bar-border" type="button" onclick="go_write()"><fmt:message key='CON.write_text' /></button>
									<button class="btn btn-sm btn-default " type="button" onclick="go_del()"><fmt:message key='CON.delete' /></button>
								</div>
								</div>
								
								<div class="card-body">
									<div class="table-responsive">
										<table class="table table-striped table-left-td checkbox-board">
										<colgroup>
											<col style="width:30px">
											<col>
											<col style="width:120px">
											<col style="width:120px">
											<col style="width:120px">
										</colgroup>
										<thead>
											<tr>
												<th>
													<label class="custom-control custom-control-success custom-checkbox">
														<input class="custom-control-input" type="checkbox" id="AllChk">
														<span class="custom-control-indicator"></span>
														<span class="custom-control-label"></span>
													</label>
												</th>
												<th><fmt:message key='CON.title' /></th>
												<th><fmt:message key='CON.writer_name' /><br><span>(<fmt:message key='CON.id' />)</span></th>
												<th id="CreatedDate" class="icon-sort"><a href="javascript:Ordersearch('CreatedDate')" ><fmt:message key='CON.write_day' /></a></th>
												<th><fmt:message key='CON.views' /></th>
											</tr>
										</thead>
											<tbody>
												<%
												if (retVector != null)
												{
													for (int i = 0; i < retVector.size(); i++)
													{
														dataPack = (PdsPack)retVector.elementAt(i);
														if(dataPack.DomainID.equals("-1")) {
															userPack = pdisk_users.get_info_by_UserID("1000000000000", dataPack.UserID);
														} else {
															userPack = pdisk_users.get_info_by_UserID(CONF_DOMAINID, dataPack.UserID);
														}
														%>
														<tr>
															<td class="text-center">
																<%
																if(!dataPack.DomainID.equals("-1") || "1000000000000".equals(CONF_DOMAINID)) {
																	%>
																	<label class="custom-control custom-control-success custom-checkbox">
																		<input class="custom-control-input" type="checkbox" name="selectChk" data-userid="<%=dataPack.UserID %>" data-createddate="<%=dataPack.CreatedDate%>" data-domainid = "<%=dataPack.DomainID%>" data-number="<%=dataPack.Number%>" value="" />
																		<span class="custom-control-indicator"></span>
																		<span class="custom-control-label"></span>
																	</label>
																	<%
																}
																%>
															</td>
															<td title="<%=dataPack.Subject%>">
																<% if(dataPack.DomainID.equals("-1")){%>
																<b>[<fmt:message key="CON.all_pds" />]</b>
																<%} %>
																<a class="line_break" href="javascript:view('<%=dataPack.UserID%>','<%=dataPack.CreatedDate%>', '<%=dataPack.DomainID%>', '<%=dataPack.Number%>')" class="linkg"><%=dataPack.Subject%></a>
																<%
																if (Long.parseLong(new_term) < Long.parseLong(dataPack.CreatedDate)) out.print("<span class=\"label arrow-left arrow-danger label-newtag m-x\">NEW</span>");
																%>
															</td>
															<td><%
																if( userPack != null )
																	out.print(userPack.Name);
																if(!dataPack.DomainID.equals("-1"))
																	out.print("<br>("+dataPack.UserID+")");
																%>
															</td>
															<td><%=dataPack.CreatedDate.substring(0, 4)%>-<%=dataPack.CreatedDate.substring(4, 6)%>-<%=dataPack.CreatedDate.substring(6, 8)%><br>
																<%=dataPack.CreatedDate.substring(8, 10)%>:<%=dataPack.CreatedDate.substring(10, 12)%>:<%=dataPack.CreatedDate.substring(12, 14)%></td>
															<td><%=dataPack.Hit%></td>
														</tr>
													<%
														}
													}
													if (retVector == null)
													{
														%>
														<tr>
															<td colspan="5" ><fmt:message key="MSG.no_data" /></td>
														</tr>
														<%
													}
												%>
											</tbody>
										</table>
									</div>
									
									<script type="text/javascript">
								<!--
								get_page_list(<%= pds_list.total_page %>, <%= pds_list.total_block %>, <%= pds_list.block %>, <%= pds_list.first_page %>, <%= pds_list.last_page %>, <%= Page %>, '<%= CONF_LANG %>', '<%= TableRows %>');
								//-->
								</script>
								</div>
							</div>
						</div>
					</div>
				
					</form>
				</div>
			</div>
			<!-- //Contents -->
	
			<!-- Footer -->
			<%@ include file="/adminsvc/include/html_footer.inc" %>
			<!-- //Footer -->
			
			<!-- Modal -->
			<div id="Modal" tabindex="-1" role="dialog" class="modal fade modal-38">
				<div class="modal-dialog">
					<div class="modal-content round-box">
					</div>
				</div>
			</div>
			<!-- //Modal -->
		</div>
		</div>
		<script src="/include/js/vendor.js"></script>
		<script src="/include/js/jquery-autocomplete.js"></script>
		<script src="/include/js/elephant.js"></script>
		<script src="/include/js/application.js"></script>
		<script src="/include/js/demo.js"></script>
		
		<form name="form_to_save" method="post" action="./pds_list.jsp">
			<input type="hidden" name="Page" value="<%=Page%>"/>
			<input type="hidden" name="UserID"/>
			<input type="hidden" name="RegDate"/>
			<input type="hidden" name="DID"/>
			<input type="hidden" name="Number"/>
			<input type="hidden" name="likeColumn" value="<%=likeColumn%>"/>
			<input type="hidden" name="likeValue" value="<%=likeValue%>"/>
		</form>
		
	</body>
</html>
<%@ include file="/common/database_close.inc" %>