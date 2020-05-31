<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<!--- <cfinclude template="/Includes/IntraHeader.cfm"> --->
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,delete">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfif isDefined('form.id')>
	<cfquery name="EventCheck" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM Vsd.vsd.MakerspaceBookingTimes WHERE TID='#form.id#'
	</cfquery>
	<cfif EventCheck.RecordCount GT 0>
		<cfquery name="EventDelete" dbtype="ODBC" datasource="ReadWriteSource">
			DELETE FROM Vsd.vsd.MakerspaceBookingTimes WHERE TID='#form.id#'
		</cfquery>
	</cfif>
</cfif>