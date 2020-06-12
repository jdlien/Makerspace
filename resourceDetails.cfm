<cfsetting showdebugoutput="false" />
<cfset app.id="MakerspaceBooking" />
<cfset app.permissionsRequired="view,reso" />
<cfinclude template="#appsIncludes#/appsPermissions.cfm" />
<!--- Include Form validation JS --->
<script src="/Javascript/appFormTools/formTools.js"></script>

<style>
	.colorSelect {
		width:100%;
		height:100%;
	}

	#showColor {
		width:100%;
		height:100%;
		text-align: center;
		color:white;
		text-shadow:0 0 3px black;
		cursor:pointer;
		border:1px solid #eeeeee;
	}

	.appsThemeDark #showColor {
		border-color:rgb(90,90,90);
	}

	.colorpicker {
		z-index:210;
		position:fixed;
	}

	#typeInfo {
		margin-bottom:25px;
		margin-top:10px;
	}

	#typeInfo h3 {
		margin-bottom:5px;
	}

	#typeInfo div {
		margin-bottom:5px;
	}
</style>

<cfset hasID = false />
<cfif isDefined('form.id') AND isNumeric(form.id)>
	<cfquery name="ResInfo" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM MakerspaceBookingResources r 
		JOIN MakerspaceBookingResourceTypes t on r.TypeID=t.TypeID
		WHERE r.rid = #form.id#
	</cfquery>

	<cfquery name="ResCerts" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingResourcesCerts WHERE RID=#form.id#
	</cfquery>

	<cfset certList = ValueList(ResCerts.MCID) />

	<cfset hasID = form.id />
</cfif>


<cfquery name="ResourceTypes" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingResourceTypes
</cfquery>

<cfquery name="MakerCerts" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.Makercerts ORDER BY MCID
</cfquery>

<cfif hasID AND ResInfo.RecordCount EQ 0>
	<div class="error">Resource #<cfoutput>#form.id#</cfoutput> does not exist.</div>
	<cfabort />
</cfif>

<cfoutput>
<h3><cfif hasID>Edit Info for #ResInfo.ResourceName#<cfelse>Create New Resource</cfif></h3>

<form class="appForm" id="detailForm" method="post" action="resourceDetailsAction.cfm">
<cfif hasID>
	<input type="hidden" name="rid" id="rid" value="#hasID#" />
</cfif>
<label for="resourceName">Resource Name
	<input type="text" name="resourceName" id="resourceName" class="required" <cfif hasID>value="#ResInfo.resourceName#"</cfif> />
	<div class="error hidden" id="resourceNameError">A name is required.</div>
</label>

<label for="description">Description
	<input type="text" name="description" id="description" class="" <cfif hasID>value="#ResInfo.Description#"</cfif> />
	<div class="error hidden" id="descriptionError">A description is required.</div>
</label>

<label for="typeID">Resource Type
	<select name="typeID" id="typeID" class="chzn-select required">
		<option></option>
		<cfloop query="ResourceTypes">
			<option value="#TypeID#" <cfif hasID AND ResInfo.TypeID EQ ResourceTypes.TypeID>selected="selected"</cfif>>#TypeName# (#OfficeCode#)</option>
		</cfloop>
	</select>
	<div class="error hidden" id="typeIDError">A type is required.</div>
</label>

<div id="typeInfo">
<cfif hasID AND isNumeric(resInfo.TypeID)>
	<cfset url.typeid = resinfo.TypeID />
	<cfinclude template="typeInfo.cfm" />
</cfif>
</div>

<label for="certs">Required Certs <div class="helpIcon" data-tooltip="Patrons require all of the selected certifications to use this resource."></div>
	<select multiple id="certs" name="certs" class="chzn-select">
		<option></option>
		<cfloop query="MakerCerts">
			<option value="#MCID#" <cfif hasID AND ListFind(certList, MCID)>selected="selected"</cfif>>#CertiName#</option>
		</cfloop>
	</select>
</label>

<div class="formItem">Colour
	<input type="hidden" name="color" id="color" <cfif hasID>value="#ResInfo.Color#"</cfif> />
	<span class="formGroup">
		<div class="colorselection" id="colorSelect" style="background-color:<cfif hasID>#ResInfo.Color#<cfelse>##888888</cfif>;">
			<div id="showColor" style="background-color:<cfif hasID>#ResInfo.Color#<cfelse>##888888</cfif>;"><cfif hasID>#ResInfo.Color#</cfif></div>
		</div>
	</span>
</div>

<label for="allowBlocked">Allow Blocked <div class="helpIcon" data-tooltip="Patrons with blocked status can use this resource"></div>
	<span class="checkboxLeft"><input type="checkbox" id="allowBlocked" name="allowBlocked" <cfif hasID AND resInfo.AllowBlocked EQ 1>checked="checked"</cfif> /></span>
</label>

<label for="weekdayMaxBookings">Weekday Max Bkgs
	<input type="text" name="weekdayMaxBookings" id="weekdayMaxBookings" class="integer" <cfif hasID>value="#ResInfo.weekdayMaxBookings#"</cfif> />
	<div class="error hidden" id="weekdayMaxBookingsError">A weekdayMaxBookings is required.</div>
</label>

<label for="weekendMaxBookings">Weekend Max Bkgs
	<input type="text" name="weekendMaxBookings" id="weekendMaxBookings" class="integer" <cfif hasID>value="#ResInfo.weekendMaxBookings#"</cfif> />
	<div class="error hidden" id="weekendMaxBookingsError">A weekendMaxBookings is required.</div>
</label>

<label for="futureMaxBookings">Future Max Bkgs
	<input type="text" name="futureMaxBookings" id="futureMaxBookings" class="integer" <cfif hasID>value="#ResInfo.futureMaxBookings#"</cfif> />
	<div class="error hidden" id="futureMaxBookingsError">A futureMaxBookings is required.</div>
</label>


<label for="concurrent">Allow Concurrent<div class="helpIcon" data-tooltip="Resources that are concurrently bookable, such as headphones or bike locks can be used at the same time as other resources. Computers, rooms, and game consoles can only be booked one at a time, so this will be unchecked for those."></div>
	<span class="checkboxLeft"><input type="checkbox" id="concurrent" name="concurrent" <cfif hasID AND resInfo.Concurrent EQ 1>checked="checked"</cfif> /></span>
</label>


<label class="formSubmit">
	<input class="button" type="submit" value="Save Resource" />
</label>
</form>

</cfoutput>


<script>
	$('.chzn-select').chosen();


	$('#colorSelect').ColorPicker({
		color: rgb2hex($('#showColor').css('background-color')),
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
			$('#colorSelect div').css('backgroundColor', '#' + hex);
			$('#color').val('#' + hex);
			$('#showColor').html('#'+hex);
		}
	});	

	// Refresh type details
	$('#typeID').change(function(){
		var typeID = $(this).val();

		$.get('typeInfo.cfm', {"typeid":typeID}).done(function(data){
			$('#typeInfo').html(data);
		});
	});

</script>

