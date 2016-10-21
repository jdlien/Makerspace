<cfset RemoveSidebar=true>
<cfset pagetitle = "Makerspace Resources Manager">
<cfset ParentPage="Makerspace Resource Booking">
<cfset ParentLink="/DLI/Makerspace/">
<cfset PermissionsMaxApplication="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfset enableColorPicker=true>

<cfset adminButtons = ArrayNew(1)>

<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="blockedtimes.cfm">
<cfset adminButton.label="Blocked Times">
<cfset adminButton.title="Manage Periods of Unavailability">
<cfset ArrayAppend(adminButtons, adminButton)>	


<cfinclude template="/Includes/IntraHeader.cfm">
<cfset ThisLocation=RealStateBuilding/>
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
</cfif>


<style type="text/css">
	.linkField {
		text-align:center;
	}
	
	.editableUsers {
		width:30px;
	}
	.colorselection {
		width:100%;
		height:22px;
	}

	.numberControl {
		padding-left:2px !important;
		padding-right:2px !important;
		white-space:nowrap;
	}
	
	.numberControl button {
		margin-right:0px;
		margin-left:0px;
		width:18px;
		padding:0;
		text-align:center;
		visibility:hidden;
	}
	
	.numberControl input {
		max-width:25px;
		margin-bottom:2px;
		margin-left:1px;
		margin-right:1px;
		text-align:center;
		background-color:white;
		color:black;
	}
	
	.visibleButtons button {
		visibility:visible;
	}
	
</style>

<cfquery name="ResourceList" datasource="SecureSource" dbtype="ODBC">
	select * from MakerspaceBookingResources r 
	LEFT JOIN MakerspaceBookingResourceTypes t on r.TypeID=t.TypeID 
</cfquery>

<cfquery name="ResourceTypes" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
</cfquery>

<cfquery name="Branches"  dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM Offices <!---WHERE OfficeType='BRANCH'---> ORDER BY OfficeCode
</cfquery>


<p>Click existing Info to edit and press enter. Changes are saved instantly.</p>
<table class="padded">
	<tr class="heading">
		<th>Name (Click to Edit)</th>
		<th>Description (Click to Edit)</th>
		<th>Type</th>
		<!---<th style="text-align:center;">Max Users</th>--->
		<th style="text-align:center;">Color</th>
		<th style="text-align:center;" title="Customers with blocked library cards may use this resource">Allow<br />Blckd</th>
		<th style="text-align:center;">WkDay<br />Max</th>
		<th style="text-align:center;">WkEnd<br />Max</th>
		<th style="text-align:center;">Future<br />Max</th>
		<th style="text-align:center;" title="Allow this to be booked even if someone already has a simultaneous booking">Allow<br />Cncrrnt</th>
		<th style="text-align:center;">Delete</th>
	</tr>
	
	<cfoutput query="ResourceList">
	<tr id="row#RID#"<cfif CurrentRow MOD 2> class="altRow"</cfif>>
		<td><div class="editableName" id="name#RID#">#ResourceName#</div></td>
		<td><div class="editableDesc" id="description#RID#">#Description#</div></td>
		<td><div class="editableType" id="type#RID#">#TypeName#</div></td>
		<!---<td>
			<button type="button" onClick="decUsers('#RID#');" style="margin-right:5px;width:22px;">-</button
					><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#RID#users" id="#RID#users" size="2" style="max-width:80px;margin-bottom:2px;margin-left:0px;text-align:center;background-color:white;color:black;" value="#MaxUsers#" readonly/>
			<button type="button" onClick="incUsers('#RID#')" style="width:22px;">+</button><span id="error#RID#Users" class="error hidden">&larr;&nbsp;You need at least one user slot.</span>	
		</td>--->
		<td>
		<cfif len(#ResourceList.color#) EQ 0>
			<cfset ResourceList.color='##888888'>
		</cfif>
			<div class="colorselection" id="#RID#colorselection" style="background-color:#color#;">
				<div id="#RID#color" style="background-color:#color#;width:100%;height:100%"></div>
			</div>
		</td>
		<td style="text-align:center;"><input type="checkbox" class="allowBlockedCheckbox" name="#RID#allowBlocked" id="#RID#allowBlocked" <cfif #allowBlocked# EQ 1>checked="checked"</cfif>/></td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#RID#', 'WeekdayMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#RID#WeekdayMaxBookings" id="#RID#WeekdayMaxBookings" size="2" value="#WeekdayMaxBookings#" readonly/><button type="button" onClick="incNum('#RID#', 'WeekdayMaxBookings')">+</button>
		</td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#RID#', 'WeekendMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#RID#WeekendMaxBookings" id="#RID#WeekendMaxBookings" size="2" value="#WeekendMaxBookings#" readonly/><button type="button" onClick="incNum('#RID#', 'WeekendMaxBookings')">+</button>
		</td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#RID#', 'FutureMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#RID#FutureMaxBookings" id="#RID#FutureMaxBookings" size="2" value="#FutureMaxBookings#" readonly/><button type="button" onClick="incNum('#RID#', 'FutureMaxBookings')">+</button>
		</td>		
		<td style="text-align:center;"><input type="checkbox" class="allowConcurrentCheckbox" name="#RID#allowConcurrent" id="#RID#allowConcurrent" <cfif #Concurrent# EQ 1>checked="checked"</cfif>/></td>
		<td style="text-align:center;"><a class="delete" href="javascript:void(0);" onClick="deleteItem('#RID#', '#ResourceName#');">Delete</a></td>
	</tr>
	</cfoutput>
	<tr>
		<td colspan="4"><b>Add New Resource</b></td>
		<th>Blckd</th>
		<th>WkDay</th>
		<th>WkEnd</th>
		<th>Future</th>
		<th>Cncurrnt</th>
	</tr>
	<tr class="altRow">
		<form name="newResource" id="newResource" action="insertResource.cfm" method="post">
		<td><input type="text" name="resourceName" id="resourceName" placeholder="Enter a Name" /></td>
		<td><input type="text" name="description" id="description" style="width:370px;" placeholder="Enter a Description"/></td>
		<td>
			<select name="typeId" id="typeId" class="chzn-select" data-placeholder="Select a Type">
				<option value=""></option>
				<cfoutput query="ResourceTypes">
					<option value="#TypeID#">#TypeName#</option>
				</cfoutput>
			</select>
		</td>
		<td>
			<div class="colorselection" id="newcolorselection">
				<div id="newcolor" style="background-color:#888888;width:100%;height:100%"></div>
				<input type="hidden" name="color" id="newColorInput" value="#888888" />
			</div>		
		</td>
		<td style="text-align:center;"><input type="checkbox" name="allowBlocked" id="allowBlocked" /></td>
		<!---<td style="text-align:center;">
		<input type="text" class="dayMax" name="wkdayMax" id="wkdayMax" style="max-width:40px;margin-bottom:2px;margin-left:0px;text-align:center;" value="" />
		</td>
		<td style="text-align:center;">
		<input type="text" class="dayMax" name="wkendMax" id="wkendMax" style="max-width:40px;margin-bottom:2px;margin-left:0px;text-align:center;" value="" />
		</td>--->
		<td class="numberControl visibleButtons" style="text-align:center;" title="Maximum Weekday Bookings Per Person">
			<button type="button" onClick="decNum('', 'WeekdayMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="WeekdayMaxBookings" id="WeekdayMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'WeekdayMaxBookings')">+</button>
		</td>
		<td class="numberControl visibleButtons" style="text-align:center;" title="Maximum Weekend Bookings Per Person">
			<button type="button" onClick="decNum('', 'WeekendMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="WeekendMaxBookings" id="WeekendMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'WeekendMaxBookings')">+</button>
		</td>
		<td class="numberControl visibleButtons" style="text-align:center;" title="Maximum Future Bookings Allowed">
			<button type="button" onClick="decNum('', 'FutureMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="FutureMaxBookings" id="FutureMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'FutureMaxBookings')">+</button>
		</td>		
		<td style="text-align:center;"><input type="checkbox" name="allowConcurrent" id="allowConcurrent" title="Allow Concurrent Bookings" /></td>
		
		<td><input type="Submit" name="SubmitNew" value="Add New" /></td>
		</form>
	</tr>
	<tr id="errorRow">
		<td><span class="error hidden" id="errorresourceName">You must enter a name</span></td>
		<td><span class="error hidden" id="errordescription">You must enter a description</span></td>
		<td><span class="error hidden" id="errortypeId">Choose a type</span></td>
		<td></td>
		<td></td>
		<td></td>
	</tr>
</table>


<h3 style="margin-top:30px;">Resource Types/Categories</h3>
<table class="padded">
	<tr class="heading">
		<th>Name (Click to Edit)</th>
		<th>Branch</th>
		<th>Resources Assigned to This Type</th>
		<th style="text-align:center;">Display<br />by Default</th>
		<th style="text-align:center;">WkDay<br />Max</th>
		<th style="text-align:center;">WkEnd<br />Max</th>
		<th style="text-align:center;">Future<br />Max</th>
		<th style="text-align:center;">Delete</th>
	</tr>
	
	<cfoutput query="ResourceTypes">
		<cfquery name="TypeResources" dbtype="ODBC" datasource="SecureSource">
			SELECT * FROM MakerspaceBookingResources
			WHERE TypeID=#ResourceTypes.TypeID#
		</cfquery>
	<tr id="rowType#TypeID#"<cfif CurrentRow MOD 2> class="altRow"</cfif>>
		<td><div class="editableTypeName" id="typeName#TypeID#">#TypeName#</div></td>
		<td><div class="editableBranch" id="branch#TypeID#">#OfficeCode#</div></td>
		<td><cfloop query="TypeResources"><cfif CurrentRow NEQ 1>, </cfif>#ResourceName#</cfloop></td>
		<td style="text-align:center;"><input type="checkbox" class="ShowByDefaultCheckbox" name="#TypeID#ShowByDefault" id="#TypeID#ShowByDefault" <cfif #ShowByDefault# EQ 1>checked="checked"</cfif>/></td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#TypeID#', 'TypeWeekdayMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#TypeID#TypeWeekdayMaxBookings" id="#TypeID#TypeWeekdayMaxBookings" size="2" value="#TypeWeekdayMaxBookings#" readonly/><button type="button" onClick="incNum('#TypeID#', 'TypeWeekdayMaxBookings')">+</button>
		</td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#TypeID#', 'TypeWeekendMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#TypeID#TypeWeekendMaxBookings" id="#TypeID#TypeWeekendMaxBookings" size="2" value="#TypeWeekendMaxBookings#" readonly/><button type="button" onClick="incNum('#TypeID#', 'TypeWeekendMaxBookings')">+</button>
		</td>
		<td class="numberControl" style="text-align:center;">
			<button type="button" onClick="decNum('#TypeID#', 'TypeFutureMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="#TypeID#TypeFutureMaxBookings" id="#TypeID#TypeFutureMaxBookings" size="2" value="#TypeFutureMaxBookings#" readonly/><button type="button" onClick="incNum('#TypeID#', 'TypeFutureMaxBookings')">+</button>
		</td>
		<td style="text-align:center;"><a class="delete" href="javascript:void(0);" onClick="deleteType('#TypeID#', '#TypeName#');">Delete</a></td>
	</tr>
	</cfoutput>
	<tr>
		<td colspan="4"><b>Add New Type</b></td>
	</tr>
	<tr class="altRow">
		<form name="newResourceType" id="newResourceType" action="insertResourceType.cfm" method="post">
		<td><input type="text" name="typeName" id="typeName" placeholder="Enter a Type Name" /></td>
		<td><select name="typeBranch" id="typeBranch" class="chzn-select" style="width:80px;" data-placeholder="Branch">
				<option value=""></option>
				<cfoutput query="Branches">
					<option value="#OfficeCode#"<cfif ThisLocation IS OfficeCode> selected</cfif>>#OfficeCode#</option>
				</cfoutput>
			</select>
		</td>
		<td></td>
		<td style="text-align:center;"><input type="checkbox" name="ShowByDefault" id="ShowByDefault" /></td>
		<td class="numberControl visibleButtons" style="text-align:center;">
			<button type="button" onClick="decNum('', 'TypeWeekdayMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="TypeWeekdayMaxBookings" id="TypeWeekdayMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'TypeWeekdayMaxBookings')">+</button>
		</td>
		<td class="numberControl visibleButtons" style="text-align:center;">
			<button type="button" onClick="decNum('', 'TypeWeekendMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="TypeWeekendMaxBookings" id="TypeWeekendMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'TypeWeekendMaxBookings')">+</button>
		</td>		
		<td class="numberControl visibleButtons" style="text-align:center;" title="Maximum Future Bookings For All Resources of Type">
			<button type="button" onClick="decNum('', 'TypeFutureMaxBookings');">-</button
			><input type="text" pattern="[0-9]*" maxlength="2" min="0" name="TypeFutureMaxBookings" id="TypeFutureMaxBookings" size="2" value="" readonly/><button type="button" onClick="incNum('', 'TypeFutureMaxBookings')">+</button>
		</td>
		<td><input type="Submit" name="SubmitNew" value="Add New" /></td>
		</form>
	</tr>
	<tr id="errorRow">
		<td colspan="1"><span class="error hidden" id="errorTypeName">You must enter a name.</span></td>
		<td><span class="error hidden" id="errorBranch">Select a branch.</span></td>
		<td></td>
		<td></td>
		<td></td>
	</tr>	
</table>

<script src='/Javascript/jquery.inputmask.bundle.min.js' type="text/javascript"></script>
<script language="Javascript">
$(".dayMax").inputmask("9");

$(".numberControl").mouseover(function() {
	$(this).children().css('visibility', 'visible');
});

$(".numberControl:not(.visibleButtons)").mouseout(function() {
	$(this).children('button').css('visibility', 'hidden');
});


$('#newResource').submit( function(event) {
	$('#errorresourceName').hide();
	$('#errortypeId').hide();
	
	var error=false;
	if ($('#resourceName').val().length == 0) {
		$('#errorresourceName').fadeIn(200);
		error=true;
	}
	if ($('#typeId').val().length == 0) {
		$('#errortypeId').fadeIn(200);
		error=true;
	}
	
	if (error) {
		event.preventDefault();
	}
	
});

/* Validate new resource type (ensure it has a name) */
$('#newResourceType').submit( function(event) {
	$('#errorTypeName').hide();
	$('#errorBranch').hide();
	var error=false;
	if ($('#typeName').val().length == 0) {
		$('#errorTypeName').fadeIn(200);
		error=true;
	}
	if ($('#typeBranch').val().length == 0) {
		$('#errorBranch').fadeIn(200);
		error=true;
	}	
	if (error) {
		event.preventDefault();
	}
	
});


	function deleteItem(RID, typeName) {
		if (confirm('Delete '+typeName+'?\nAny bookings for this resource will be deleted.') ){		
				$("#row"+RID).hide(200);
				$.get("deleteResource.cfm?delID="+RID);
		}		
	}

	function deleteType(TypeID, typeName) {
		if (confirm('Delete Type '+typeName+'?\nThis may cause problems if this type is used for future blocked times.') ){		
				$("#rowType"+TypeID).hide(200);
				$.get("deleteResourceType.cfm?delID="+TypeID);
		}		
	}	
	
	function rgb2hex(rgb) {
		if (/^#[0-9A-F]{6}$/i.test(rgb)) return rgb;

		rgb = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
		function hex(x) {
			return ("0" + parseInt(x).toString(16)).slice(-2);
		}
		return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
	}
	
/* Makes Descriptions editable makes Names editable */
	$(document).ready(function() {
	
		$(".allowBlockedCheckbox").change(function(){
			var thisCheckbox=this.id;
			var isChecked=$(this).is(':checked');
			$.post('editResource.cfm', {id:thisCheckbox, allowBlocked:isChecked});
		});

		$(".allowConcurrentCheckbox").change(function(){
			var thisCheckbox=this.id;
			var isChecked=$(this).is(':checked');
			$.post('editResource.cfm', {id:thisCheckbox, allowConcurrent:isChecked});
		});
		
		$(".ShowByDefaultCheckbox").change(function(){
			var thisCheckbox=this.id;
			var isChecked=$(this).is(':checked');
			$.post('editResource.cfm', {id:thisCheckbox, ShowByDefault:isChecked});
		});		
	
		$(".editableDesc").editable('editResource.cfm', {
			name : 'NewDesc',
			indicator : 'Saving...',
			tooltip   : 'Click to change description...',
			placeholder: '<span class="subtleGray">Click to add a description...</span>'
		});


		$(".editableName").editable('editResource.cfm', {
			name : 'NewName',
			indicator : 'Saving...',
			tooltip   : 'Click to change name...',
			placeholder: '<span class="subtleGray">Click to add a name...</span>'
		});

		$(".editableTypeName").editable('editResource.cfm', {
			name : 'NewTypeName',
			indicator : 'Saving...',
			tooltip   : 'Click to change type name...',
			placeholder: '<span class="subtleGray">Click to add a name...</span>'
		});
		
		
		$(".editableType").editable('editResource.cfm', {
			name : 'NewType',
			indicator : 'Saving...',
			tooltip   : 'Click to change type...',
			placeholder: '<span class="subtleGray">Set a type...</span>',
			data : "{<cfoutput query="ResourceTypes"><cfif CurrentRow GT 1>, </cfif>'#TypeID#':'#TypeName#'</cfoutput>}",
			type : 'select',
			submit: 'OK'
		});

		$(".editableBranch").editable('editResource.cfm', {
			name : 'NewBranch',
			indicator : 'Saving...',
			tooltip   : 'Click to change branch...',
			placeholder: '<span class="subtleGray">Set a branch...</span>',
			data : "{<cfoutput query="Branches"><cfif CurrentRow GT 1>, </cfif>'#OfficeCode#':'#OfficeCode#'</cfoutput>}",
			type : 'select',
			submit: 'OK'
		});		

		<cfoutput query="ResourceList">
		//console.log('#color#');
		$('###RID#colorselection').ColorPicker({
			color: rgb2hex($('###RID#colorselection').css('background-color')),
			onShow: function (colpkr) {
				$(colpkr).fadeIn(100);
				return false;
			},
			onHide: function (colpkr) {
				$(colpkr).fadeOut(100);
				//post new color here to editresource.cfm
				$.post('editResource.cfm', {'id':'#RID#','color':$('###RID#color').css('backgroundColor')});
				
				return false;
			},
			onChange: function (hsb, hex, rgb) {
				$('###RID#color').css('backgroundColor', '##' + hex);
				$('###RID#colorselection').css('backgroundColor', '##' + hex);
				newColorInput
			}
		});				
		
		</cfoutput>
		
		
		$('#newcolorselection').ColorPicker({
			color: '#888888',
			onShow: function (colpkr) {
				$(colpkr).fadeIn(100);
				return false;
			},
			onHide: function (colpkr) {
				$(colpkr).fadeOut(100);
				//post new color here to editresource.cfm
				//$.post('editResource.cfm', {'color':$('.colorselection div').css('backgroundColor')}
				
				return false;
			},
			onChange: function (hsb, hex, rgb) {
				$('#newcolorselection div').css('backgroundColor', '#' + hex);
				$('#newColorInput').val('#' + hex);
				newColorInput
			}
		});	
	
	
	});//$(document).ready

/* Makes Users editable 
	$(document).ready(function() {
		$(".editableUsers").editable('editResource.cfm', {
			name : 'NewUsers',
			indicator : '...',
			tooltip   : 'Click to change max users...',
			placeholder: '<span class="subtleGray">edit</span>'
		});
	});
*/

//Functions for the number buttons
	function decNum(RID, param) {
		var Number=document.getElementById(RID+param).value;
		if ( Number > 0) {
			document.getElementById(RID+param).value--;
			Number--;
			if (RID.length > 0) {
			$.get("editResource.cfm?id="+RID+"&param="+param+"&number="+Number);	
			}
		} else if (Number <= 0) {
			document.getElementById(RID+param).value=String.fromCharCode(8734);
			Number="NULL";
			if (RID.length > 0) {
				$.get("editResource.cfm?id="+RID+"&param="+param+"&number="+Number);	
			}
		}
	}

	function incNum(RID, param) {
		var Number=document.getElementById(RID+param).value;
		if (isNaN(Number)) {
			Number=0;
			document.getElementById(RID+param).value=0;
		}
		if ( Number >= 0) {
			document.getElementById(RID+param).value++;
			Number++;
			if (RID.length > 0) {
			$.get("editResource.cfm?id="+RID+"&param="+param+"&number="+Number);	
			}
		}
	}
/*
	function decNumType(TypeID, param) {
		var Number=document.getElementById(TypeID+'Type'+param).value;
		if ( Number > 0) {
			document.getElementById(TypeID+'Type'+param).value--;
			Number--;
			if (TypeID.length > 0) {
			$.get("editResource.cfm?id="+TypeID+"&param="+param+"&number="+Number+"&type");	
			}
		} else if (Number <= 0) {
			document.getElementById(TypeID+'Type'+param).value=String.fromCharCode(8734);
			Number="NULL";
			if (TypeID.length > 0) {
				$.get("editResource.cfm?id="+TypeID+"&param="+param+"&number="+Number+"&type");	
			}
		}
	}

	function incNumType(TypeID, param) {
		var Number=document.getElementById(TypeID+'Type'+param).value;
		if (isNaN(Number)) {
			Number=0;
			document.getElementById(TypeID+'Type'+param).value=0;
		}
		if ( Number >= 0) {
			document.getElementById(TypeID+'Type'+param).value++;
			Number++;
			if (TypeID.length > 0) {
			$.get("editResource.cfm?id="+TypeID+"&param="+param+"&number="+Number+"&type");	
			}
		}
	}
*/
	
</script>

<cfinclude template="/AppsRoot/Includes/IntraFooter.cfm">


