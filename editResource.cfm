<cfsetting showdebugoutput="no">
<cfinclude template="#appsIncludes#/appsInit.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,reso">
<cfinclude template="#appsIncludes#/appsPermissions.cfm">
<!--- Changes click-to-edit URL --->
<cfif isDefined('form.NewDesc')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateDescription" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET Description='#form.NewDesc#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
	<cfoutput>#form.NewDesc#</cfoutput>
</cfif>

<!--- Changes click-to-edit Name --->
<cfif isDefined('form.NewName')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateName" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET ResourceName='#form.NewName#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
	<cfoutput>#form.NewName#</cfoutput>
</cfif>

<!--- Changes click-to-edit Type Name --->
<cfif isDefined('form.NewTypeName')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateTypeName" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResourceTypes SET TypeName='#form.NewTypeName#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE TypeID=#form.id#
	</cfquery>
	<cfoutput>#form.NewTypeName#</cfoutput>
</cfif>


<!--- Changes click-to-edit Type --->
<cfif isDefined('form.NewType')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateType" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources
		SET TypeID='#form.NewType#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
	<cfquery name="TypeName" datasource="SecureSource" dbtype="ODBC">
		SELECT TypeName FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
		WHERE TypeID='#form.NewType#'
	</cfquery>
	<cfoutput>#TypeName.TypeName#</cfoutput>
</cfif>


<!--- Changes click-to-edit Type Branch --->
<cfif isDefined('form.NewBranch')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateBranch" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResourceTypes SET OfficeCode='#form.NewBranch#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE TypeID=#form.id#
	</cfquery>
	<cfoutput>#form.NewBranch#</cfoutput>
</cfif>


<!--- Changes click-to-edit Numbers, variable parameter --->
<cfif isDefined('url.number') && isDefined('url.param')>
	<cfparam name="form.number" default="#url.number#">
	<cfparam name="form.param" default="#url.param#">
	<cfparam name="form.id" default="#url.id#">
</cfif>
<cfif isDefined('form.number') && isDefined('form.param')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfif FindNoCase('Type', form.param)>
		<cfquery name="UpdateTypeNumber" dbtype="ODBC" datasource="ReadWriteSource">
			UPDATE vsd.vsd.MakerSpaceBookingResourceTypes SET #form.param#=#form.number#, ModifiedBy='#session.identity#', Modified=GETDATE()
			WHERE TypeID=#form.id#
		</cfquery>	
	<cfelse>
		<cfquery name="UpdateNumber" dbtype="ODBC" datasource="ReadWriteSource">
			UPDATE vsd.vsd.MakerSpaceBookingResources SET #form.param#=#form.number#, ModifiedBy='#session.identity#', Modified=GETDATE()
			WHERE RID=#form.id#
		</cfquery>
	</cfif>
	<cfoutput>#form.number#</cfoutput>
</cfif>

<cfif isDefined('url.id') AND isDefined('url.users')>
	<cfquery name="UpdateMaxUsers" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET MaxUsers='#url.users#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#url.id#
	</cfquery>
</cfif>

<!--- Updates color --->
<cfif isDefined('form.color')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateColor" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET Color='#form.color#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
</cfif>

<!--- Updates Allow Blocked --->
<cfif isDefined('form.allowBlocked')>
	<cfif form.allowBlocked IS 'on' OR form.allowBlocked IS 'true' OR form.allowBlocked IS 'yes'>
		<cfset allowBlocked=1>
	<cfelse>
		<cfset allowBlocked=0>
	</cfif>
	<cfset form.id = REReplace(form.id, "(\d+)\D+", "\1")>
	<cfquery name="UpdateBlocked" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET AllowBlocked='#allowBlocked#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
</cfif>


<!--- Updates Concurrent bit --->
<cfif isDefined('form.allowConcurrent')>
	<cfif form.allowConcurrent IS 'on' OR form.allowConcurrent IS 'true' OR form.allowConcurrent IS 'yes'>
		<cfset allowConcurrent=1>
	<cfelse>
		<cfset allowConcurrent=0>
	</cfif>
	<cfset form.id = REReplace(form.id, "(\d+)\D+", "\1")>
	<cfquery name="UpdateBlocked" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResources SET Concurrent='#allowConcurrent#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE RID=#form.id#
	</cfquery>
</cfif>


<!--- Updates Allow Blocked for Types--->
<cfif isDefined('form.ShowByDefault')>
	<cfif form.ShowByDefault IS 'on' OR form.ShowByDefault IS 'true' OR form.ShowByDefault IS 'yes'>
		<cfset ShowByDefault=1>
	<cfelse>
		<cfset ShowByDefault=0>
	</cfif>
	<cfset form.id = REReplace(form.id, "(\d+)\D+", "\1")>
	<cfquery name="UpdateShow" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerSpaceBookingResourceTypes SET ShowByDefault='#ShowByDefault#', ModifiedBy='#session.identity#', Modified=GETDATE()
		WHERE TypeID=#form.id#
	</cfquery>
</cfif>
