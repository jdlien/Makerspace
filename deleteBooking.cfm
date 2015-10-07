<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,delete">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfif isDefined('form.id')>
	<cfquery name="EventDelete" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM Vsd.vsd.MakerspaceBookingTimes WHERE TID='#form.id#'
	</cfquery>
</cfif>