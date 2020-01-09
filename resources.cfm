<cfset pagetitle = "Makerspace Resources Manager">
<cfset ParentPage="Makerspace Resource Booking">
<cfset ParentLink="/DLI/Makerspace/">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">

<cfset adminButtons = ArrayNew(1)>

<cfset adminButton = structNew()>
<cfset adminButton.permType="block">
<cfset adminButton.link="blockedtimes.cfm">
<cfset adminButton.label="Blocked Times">
<cfset adminButton.title="Manage Periods of Unavailability">
<cfset ArrayAppend(adminButtons, adminButton)>	

<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="resourceTypes.cfm">
<cfset adminButton.label="Resource Types">
<cfset adminButton.title="Manage Categories of Resources">
<cfset ArrayAppend(adminButtons, adminButton)>

<cfinclude template="/Includes/IntraHeader.cfm">
<cfset ThisLocation=RealStateBuilding/>
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
</cfif>





<link rel="stylesheet" type="text/css" href="makerspace.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/javascript/colorpicker/css/colorpicker.css" />
<script src="/javascript/colorpicker/js/colorpicker.js"></script>

<cfquery name="ResourceList" datasource="SecureSource" dbtype="ODBC">
	SELECT *, (SELECT COUNT(TID) FROM vsd.MakerspaceBookingTimes WHERE RID=r.RID) AS BookingCount FROM MakerspaceBookingResources r 
	LEFT JOIN MakerspaceBookingResourceTypes t on r.TypeID=t.TypeID
	<cfif len(ThisLocation)>WHERE t.OfficeCode IS NULL OR t.OfficeCode='#ThisLocation#'</cfif>
</cfquery>

<cfquery name="ResourceTypes" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
</cfquery>

<cfquery name="Branches"  dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM Offices
	WHERE (OfficeType IS NOT NULL AND OfficeType != 'GONE' AND OfficeType != 'MACHINE') OR OfficeCode = 'MNP'
	ORDER BY OfficeCode
</cfquery>


<cfoutput>
<form id="branchselect" method="get" onChange="$(this).submit();">
	<label for="branch">Switch Branch <select name="branch" id="branch" class="chzn-select" data-placeholder="Choose Branch" style="width:200px;">
		<option value="">All Branches</option>
		<cfloop query="Branches">
			<option value="#OfficeCode#" <cfif ThisLocation EQ OfficeCode>selected</cfif>>#OfficeCode# - #CommonName#</option>
		</cfloop>
	</select></label>
</form>

<h2>Resources at 
<cfif len(ThisLocation)>
	<cfquery name="OfficeInfo" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.Offices WHERE OfficeCode = '#ThisLocation#'
	</cfquery>

	#OfficeInfo.CommonName#
<cfelse>
	All Branches
</cfif><a class="edit plainLink normal newResource" href="javascript:void(0);">Add New Resource</a>
</h2>
</cfoutput>


<span>Click field to edit and press enter to save.</span>
<table class="padded altColors">
	<thead>
	<tr><th style="text-align:center;">Edit</th>
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
	</thead>
	
	<cfoutput query="ResourceList">
	<tr id="row#RID#">
		<td class="editCell"><a href="javascript:void(0);" class="edit" id="edit#RID#" title="Resource #RID#">Edit</a></td>
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
		<td style="text-align:center;"><cfif BookingCount EQ 0><a class="delete" href="javascript:void(0);" onClick="deleteItem('#RID#', '#ResourceName#');">Delete</a></cfif></td>
	</tr>
	</cfoutput>
	<thead>
	<tr>
		<th></th>
		<th colspan="4"><b>Add New Resource</b></th>
		<th>Blckd</th>
		<th>WkDay</th>
		<th>WkEnd</th>
		<th>Future</th>
		<th>Cncurrnt</th>
		<th></th>
	</tr>
	</thead>
	<tr>
		<form name="newResource" id="newResource" action="insertResource.cfm?branch=<cfoutput>#ThisLocation#</cfoutput>" method="post">
		<td></td>
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
	<tr id="errorRow" style="background-color:transparent;">
		<td><span class="error hidden" id="errorresourceName">You must enter a name</span></td>
		<td><span class="error hidden" id="errordescription">You must enter a description</span></td>
		<td><span class="error hidden" id="errortypeId">Choose a type</span></td>
		<td></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td colspan="10" style="text-align:center;padding-top:50px"><a href="resourceTypes.cfm" class="button">Add/Edit Resource Types</a></td>
	</tr>
</table>





<script language="Javascript">
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


function deleteItem(RID, typeName) {
	if (confirm('Delete '+typeName+'?\nAny bookings for this resource will be deleted.') ){		
			$("#row"+RID).hide(200);
			$.get("deleteResource.cfm?delID="+RID);
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

	$('.editCell .edit').click(function(){
		var id = $(this).attr('id').replace(/\D*(\d+)/, '$1');
		loadPopOverContent('resourceDetails.cfm', '440px', {"id":id});
	});


	$('.newResource').click(function(){
		loadPopOverContent('resourceDetails.cfm', '440px');
	});

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

	
	$(".editableType").editable('editResource.cfm', {
		name : 'NewType',
		indicator : 'Saving...',
		tooltip   : 'Click to change type...',
		placeholder: '<span class="subtleGray">Set a type...</span>',
		data : "{<cfoutput query="ResourceTypes"><cfif CurrentRow GT 1>, </cfif>'#TypeID#':'#TypeName#'</cfoutput>}",
		type : 'select',
		submit: 'OK'
	});
	

	//Originally this was generated by ColdFusion code
	$('.colorselection:not(#newcolorselection)').mouseenter(function(){
		$colorDiv = $(this);
		var rid=$colorDiv.attr('id').replace(/(\d+).*/, "$1");
		$(this).ColorPicker({
			color: rgb2hex($('#'+rid+'color').css('background-color')),
			onShow: function (colpkr) {
				$(colpkr).fadeIn(100);
				return false;
			},
			onHide: function (colpkr) {
				$(colpkr).fadeOut(100);
				//post new color here to editresource.cfm
				$.post('editResource.cfm', {'id':rid,'color':$('#'+rid+'color').css('backgroundColor')});
				
				return false;
			},
			onChange: function (hsb, hex, rgb) {
				$('#'+rid+'color').css('backgroundColor', '#' + hex);
				$('#'+rid+'colorselection').css('backgroundColor', '#' + hex);
				newColorInput
			}
		});


	});
	
	
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

<cfinclude template="/AppsRoot/Includes/IntraFooter.cfm">


