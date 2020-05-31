<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,block">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfquery name="BlockedResourcesDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimeResources WHERE BID='#url.delID#'
</cfquery>
<cfquery name="BlockedDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimes WHERE BID='#url.delID#'
</cfquery>
