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
<%@ page import="pdisk_org_cowork.*"%>
<%
configUtil.set_websvc_config(CONF_DOMAINID);

String TableRows = request.getParameter("TableRows")!=null?request.getParameter("TableRows"):"";
String Page = request.getParameter("Page")!=null?request.getParameter("Page"):"";

Vector org_cowork_list = null;
OrgCoworkPack org_cowork_pack = null;
OrgCowork org_cowork = new OrgCowork();
org_cowork.init_query(dbUtil.db_conn, configUtil.conf_dbtype);
org_cowork_list = org_cowork.get_list_rootcowork("DomainID", CONF_DOMAINID, "HomeFolder", "no", "CreateDate");

if (org_cowork_list == null)
	pageContext.setAttribute("existOrgcowork", "no");
else
	pageContext.setAttribute("existOrgcowork", "yes");

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
	<link rel="stylesheet" href="/include/css/compose.css">
	<link rel="stylesheet" href="/include/css/custom.css">
	<link rel="stylesheet" href="/include/css/jquery-ui.css"/>
	<script type="text/javascript" src="/include/js/jquery.js"></script>
	<script type="text/javascript" src="/include/js/jquery-ui.js"></script>
	<script type="text/javascript">
	var filesArr = new Array();
	var fileNo = 0;
	var total_size = 0;
	function apply_notice() {
		
		var sub = $("#Subject").val()
		var len = sub.length;
		if( sub[0] == ' ' || sub[len-1] == ' ') {
			alert("<fmt:message key='MSG.check_first_last_space'/>");
			document.noticeAdd.Subject.focus();
			return;
		}
		
		if ( checkNullString(document.noticeAdd.Subject.value) )
		{
			alert("<fmt:message key='MSG.notice_error_msg3' />");
			document.noticeAdd.Subject.focus();
			return;
		}
		
		if ( document.noticeAdd.Subject.value.length > 100 )
		{
			alert("<fmt:message key='MSG.value_length_limit'><fmt:param value='100'/></fmt:message>\n<fmt:message key='MSG.remove_over_limit'><fmt:param value='100'/></fmt:message>");
			var tmp = document.noticeAdd.Subject.value;
			tmp = tmp.substr(0, 100);
			$("#Subject").val(tmp);
			document.noticeAdd.Subject.focus();
			return;
		}
		
		var contents = $('#Contents').html();
		
		if ( checkNullString(contents) )
		{
			alert("<fmt:message key='MSG.qna_write_form_check_content' />");
			document.getElementById('Contents').focus();
			return;
		}
		
		if (confirm('<fmt:message key="MSG.register_progress" />'))
		{
	        var SearchContents = $('#Contents').html();
		    SearchContents = SearchContents.replace(/<[^>]*>?/g, '');
		    SearchContents = SearchContents.replace(/&nbsp;/gi,"");
		    SearchContents = SearchContents.replace(/&amp;/gi,"");
		    SearchContents = SearchContents.replace(/\r\n/gi,"");
		    SearchContents = SearchContents.replace(/\t/gi,"");
		    $("#SearchContents").val(SearchContents);
		    
		    if ( $("#SearchContents").val().length > 100000 )
			{
				alert("<fmt:message key='MSG.value_length_limit'><fmt:param value='100,000'/></fmt:message>");
				document.noticeAdd.Contents.focus();
				return;
			}
		    
		    // Get form
	        var form = $("#noticeAdd")[0];
	        //console.log(form);

		    // Create an FormData object 
	        var data = new FormData(form);
			
		    for (var i=0; i<filesArr.length; i++) {
		    	if(!filesArr[i].is_delete) {
		    		data.append("attach_file", filesArr[i]);
		    	}
		    }
		    
		    var img_num = 0;
		    var image_size = 0;
		    for(var i=0; i<$("#Contents img").length; i++)
		    {
		    	$("#Contents img")[i].id = "img_"+img_num;
		    	img_num++;
		    	
		    	var file = base64toFile($("#Contents img")[i].src, "image_file_"+i+".gif");
		    	image_size += file.size
		    	data.append("image_file", file);
		    	//$("#Contents img")[i].src = "";
		    }
		    var maxsize = 5 * 1024 * 1024;
		    if (image_size > maxsize )
	    	{
	    		alert("<fmt:message key='MSG.capacity_exceed' />");
	    		data.delete("image_file");
	    		return;
	    	}
		    else
		    {
		    	for(var i=0; i<$("#Contents img").length; i++)
		    	{
		    		$("#Contents img")[i].src = "";
		    	}
		    }
		    var paramContents = $('#Contents').html();
		    $("#paramContents").val($('#Contents').html());
		    data.append("paramContents", paramContents);
		    
		    data.delete("file");

	        $.ajax({
	            type : 'post',
	            url : './pds_add.jsp',
	            data : data,
	            enctype: 'multipart/form-data',
	            contentType: false,
	            processData: false,
				beforeSend:function()
				{
					$("#progress").addClass('spinner');
					$("#apply").attr("disabled", "disabled");
					$("#cancel").attr("disabled", "disabled");
				},
	            success : function(result){
	            	if(result == "Parameter Missing")
	            		alert("<fmt:message key='MSG.parameter_error' />");
	            	else if(result == "Exception Error")
	            		alert("<fmt:message key='MSG.error'/>");
	            	else if(result == "Not Exist Orgcowork")
	            		alert("<fmt:message key='MSG.orgcowork_does_not_exist'/>");
	            	else if(result == "success")
						alert("<fmt:message key='MSG.registration_success' />");
	            	else
	            		alert("<fmt:message key='MSG.create_fail'/> ("+result+")");
	            },
	            error: function(xhr, status, error){
	                alert("<fmt:message key='MSG.error' /> - "+error);
	            },
				complete:function()
				{
					$("#progress").removeClass('spinner');
					$("#apply").removeAttr("disabled");
					$("#cancel").removeAttr("disabled");
					document.form_to_save.submit();
				}
	        });
	        
		}
		
	}
	
	function base64toFile(base_data, filename) {

	    var arr = base_data.split(','),
	        mime = arr[0].match(/:(.*?);/)[1],
	        bstr = atob(arr[1]),
	        n = bstr.length,
	        u8arr = new Uint8Array(n);

	    while(n--){
	        u8arr[n] = bstr.charCodeAt(n);
	    }

	    return new File([u8arr], filename, {type:mime});
	}
	
	function go_list() {
		document.form_to_save.submit();
	}
	
	function deleteFile(num, size) {
	    document.querySelector("#file" + num).remove();
	    filesArr[num].is_delete = true;
	    total_size -= parseInt(size);
	}
	
	$(document).on("click",".remove",function(){
		$(this).parent().parent().remove();
	}); 
	
	$(document).on('click', '#normalfiles', function()
	{
		var existOrgcowork = '${existOrgcowork}';
		if (existOrgcowork == 'no')
		{
			alert("<fmt:message key='MSG.no_orgcowork' />");
			return false;
		}
			
	});
	
	function fileUpload(fis) {
		var onload_check = 0;
 		var file_check = 0;
		for (const file of fis.files)
 		{
			if (validation(file))
			{
				file_check += 1;
 				$("#progress").addClass('spinner');
				$("#apply").attr("disabled", "disabled");
				$("#cancel").attr("disabled", "disabled");
				var reader = new FileReader();
	            reader.onload = function () {
	                filesArr.push(file);
	                onload_check += 1;
	                if(onload_check == file_check) {
	                	$("#progress").removeClass('spinner');
						$("#apply").removeAttr("disabled");
						$("#cancel").removeAttr("disabled");
	                }
	 			};
	 			reader.readAsDataURL(file);
	 			
	 			$('#add_file').append('<li id="file'+fileNo+'"><p>'+file.name+' <i class="icon icon-close remove" onclick = "deleteFile('+fileNo+', '+file.size+');"></i></p></li>');
	 			fileNo++;
			}
			else
 				continue;
 		}
 		document.querySelector("input[type=file]").value = "";
	}
	
	function validation(obj) {
 		
 		if (obj.size > (1024 * 1024 * 1024)) 
 		{
 	        alert("<fmt:message key='MSG.board_file_size_limit'/>");
 	        return false;
 		}
 		else {
 			total_size += parseInt(obj.size);
 			if (total_size > (1024 * 1024 * 1024)) 
 			{
 				total_size -= parseInt(obj.size);
 				alert("<fmt:message key='MSG.board_file_size_limit'/>");
 	 	        return false;
 			}
 			return true;
 		}
 	}
	//-->
	</script>
	<style>
	 #Contents ul {
	 	list-style: disc;
	 	padding-left: 40px;
	 }
	 #Contents ul li {
	 	list-style: disc;
	 }
	 
	 #Contents ol {
	 	list-style: decimal;
	 	padding-left: 40px;
	 }
	 #Contents ol li {
	 	list-style: decimal;
	 }
	 
	 blockquote {
	 	font-size: 13px;
	 }
	 
	 .upload-file-list ul li p {
	 	padding-right: 20px;
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
					<form id="noticeAdd" name="noticeAdd" method="post" enctype="multipart/form-data" onsubmit="return false;">
						<input type="hidden" name="PdsName" value="<fmt:message key='CON.pds' />"/>
						<input type="hidden" id="SearchContents" name="SearchContents" value="" />
						<div class="compose">
							<div class="compose-header">
								<div class="compose-field">
									<div class="compose-field-body">
										<input class="compose-input" type="text" id="Subject" name="Subject" placeholder="<fmt:message key='CON.title' />">
									</div>
								</div>
							</div>
							<div class="compose-body">
								<div class="compose-message">
									<div name="Contents" id="Contents" class="compose-editor" style="overflow:auto;height: 500px;"></div>
									<input type="hidden" id="paramContents" name="paramContents">
									<div class="compose-toolbar">
										<div class="btn-toolbar" data-role="editor-toolbar">
											<div class="btn-group">
												<div class="btn-group dropup">
													<button class="btn btn-link link-muted" title="Font Size"
														data-toggle="dropdown" type="button">
														<span class="icon icon-text-height"></span>
													</button>
													<ul class="dropdown-menu">
														<li><a class="fs-Five" data-edit="fontSize 5">Huge</a></li>
														<li><a class="fs-Three" data-edit="fontSize 3">Normal</a></li>
														<li><a class="fs-One" data-edit="fontSize 1">Small</a></li>
													</ul>
												</div>
												<div class="btn-group">
													<button class="btn btn-link link-muted" title="Bold (Ctrl/Cmd+B)"
														data-edit="bold" type="button">
														<span class="icon icon-bold"></span>
													</button>
													<button class="btn btn-link link-muted" title="Italic (Ctrl/Cmd+I)"
														data-edit="italic" type="button">
														<span class="icon icon-italic"></span>
													</button>
													<button class="btn btn-link link-muted" title="Strikethrough"
														data-edit="strikethrough" type="button">
														<span class="icon icon-strikethrough"></span>
													</button>
													<button class="btn btn-link link-muted" title="Underline (Ctrl/Cmd+U)"
														data-edit="underline" type="button">
														<span class="icon icon-underline"></span>
													</button>
												</div>
												<div class="btn-group">
													<button class="btn btn-link link-muted" title="Bullet list"
														data-edit="insertunorderedlist" type="button">
														<span class="icon icon-list-ul"></span>
													</button>
													<button class="btn btn-link link-muted" title="Number list"
														data-edit="insertorderedlist" type="button">
														<span class="icon icon-list-ol"></span>
													</button>
													<button class="btn btn-link link-muted" title="Reduce indent (Shift+Tab)"
														data-edit="outdent" type="button">
														<span class="icon icon-outdent"></span>
													</button>
													<button class="btn btn-link link-muted" title="Indent (Tab)"
														data-edit="indent" type="button">
														<span class="icon icon-indent"></span>
													</button>
												</div>
												<div class="btn-group">
													<button class="btn btn-link link-muted" title="Align Left (Ctrl/Cmd+L)"
														data-edit="justifyleft" type="button">
														<span class="icon icon-align-left"></span>
													</button>
													<button class="btn btn-link link-muted" title="Center (Ctrl/Cmd+E)"
														data-edit="justifycenter" type="button">
														<span class="icon icon-align-center"></span>
													</button>
													<button class="btn btn-link link-muted" title="Align Right (Ctrl/Cmd+R)"
														data-edit="justifyright" type="button">
														<span class="icon icon-align-right"></span>
													</button>
													<button class="btn btn-link link-muted" title="Justify (Ctrl/Cmd+J)"
														data-edit="justifyfull" type="button">
														<span class="icon icon-align-justify"></span>
													</button>
												</div>
												<div class="btn-group">
													<label class="btn btn-link link-muted file-upload-btn" title="Insert picture">
														<span class="icon icon-picture-o"></span>
														<input class="file-upload-input" type="file" name="file" id="imagefiles" data-edit="insertImage">
													</label>
												</div>
												<div class="btn-group">
													<label class="btn btn-link link-muted file-upload-btn" title="Insert file">
														<span class="icon icon-paperclip fa-lg"></span>
														<input class="file-upload-input" type="file" name="file" id="normalfiles" onchange="fileUpload(this)" onclick="this.value=null;" multiple>
													</label>
												</div>
											</div>
											<%
											String site_type = configUtil.read_config("1000000000000", "site.conf", "site_type");
											if (CONF_DOMAINID != null && !"".equals(CONF_DOMAINID) && "1000000000000".equals(CONF_DOMAINID) && (site_type.indexOf("multi") > -1 ) )	{
												%>
												<div class="btn-group p-r" style="float:right;">
													<fmt:message key='CON.show_all' />	
													<label class="switch switch-success">
														<input class="switch-input" name="nRoot" id="nRoot" value="root" type="checkbox">
														<span class="switch-track"></span>
														<span class="switch-thumb"></span>
													</label>	
												</div>
												<div class="p-r" style="float:right; clear:right;">
													* <fmt:message key='CON.show_all_sub_domain'/>
												</div>
												<%
											}
											%>
										</div>
										<div class="upload-file-list">
											<ul id="add_file" style="word-break: break-word;">
												
											</ul>
										</div>
									</div>
								</div>
								<div class="text-center">
									<button class="btn btn-success btn-basic" id="apply" type="button" onclick="apply_notice()"><fmt:message key='BTN.ok' /></button>
									<button class="btn btn-default btn-basic" id="cancel" type="button" onclick="go_list()"><fmt:message key='BTN.cancel' /></button>
								</div>
							</div>
						</div>
					</form>
				</div>
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
		<!-- spinner -->
		<div id="progress" class="spinner-success spinner-lg sq-100"></div>
		<!-- //spinner -->
	</div>
</div>	
<form name="form_to_save" method="post" action="./pds_list.jsp">
	<input type="hidden" name="Page" value="<%=Page%>"/>
	<input type="hidden" name="TableRows" value="<%=TableRows%>"/>
</form>

<script src="/include/js/vendor.js"></script>
<script src="/include/js/elephant.js"></script>
<script src="/include/js/application.js"></script>
<script src="/include/js/demo.js"></script>
<script src="/include/js/compose.min.js"></script>
<script src="/include/js/custom.js"></script>	
<script src="/include/js/jquery-autocomplete.js"></script>
	
</body>
</html>
<%@ include file="/common/database_close.inc" %>