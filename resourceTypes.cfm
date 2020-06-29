<cfset app.title="Makerspace Resource Types">
<cfset app.addParent("Makerspace Resource Booking", "./") />
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,reso">

<cfset adminButtons = ArrayNew(1)>

<cfset adminButton = structNew()>
<cfset adminButton.permType="block">
<cfset adminButton.link="blockedtimes.cfm">
<cfset adminButton.label="Blocked Times">
<cfset adminButton.tooltip="Manage Periods of Unavailability">
<cfset ArrayAppend(app.adminButtons, adminButton)>	

<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="resources.cfm">
<cfset adminButton.label="Resources">
<cfset adminButton.tooltip="Manage Consoles, PCs, etc.">
<cfset ArrayAppend(app.adminButtons, adminButton)>


<cfinclude template="#app.includes#/appsHeader.cfm" />
<cfset ThisLocation=RealStateBuilding/>
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
</cfif>



<link rel="stylesheet" type="text/css" href="makerspace.css" />


<cfquery name="ResourceTypes" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
</cfquery>

<cfquery name="Branches"  dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM Offices <!---WHERE OfficeType='BRANCH'---> ORDER BY OfficeCode
</cfquery>


<h2>Resource Types/Categories</h2>
<span>Click field to edit and press enter to save.</span>
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
		<td style="text-align:center;"><cfif TypeResources.RecordCount EQ 0><a class="delete" href="javascript:void(0);" onClick="deleteType('#TypeID#', '#TypeName#');">Delete</a></cfif></td>
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




<script language="Javascript">
$(".numberControl").mouseover(function() {
	$(this).children().css('visibility', 'visible');
});

$(".numberControl:not(.visibleButtons)").mouseout(function() {
	$(this).children('button').css('visibility', 'hidden');
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


	function deleteType(TypeID, typeName) {
		if (confirm('Delete Type '+typeName+'?\nThis may cause problems if this type is used for future blocked times.') ){		
				$("#rowType"+TypeID).hide(200);
				$.get("deleteResourceType.cfm?delID="+TypeID);
		}		
	}	

	
/* Makes Descriptions editable makes Names editable */
	$(document).ready(function() {
		
		$(".ShowByDefaultCheckbox").change(function(){
			var thisCheckbox=this.id;
			var isChecked=$(this).is(':checked');
			$.post('editResource.cfm', {id:thisCheckbox, ShowByDefault:isChecked});
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
	
	
	});//$(document).ready


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

	
</script>