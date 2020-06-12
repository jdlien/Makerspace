<cfinclude template="#appsIncludes#/appsInit.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,block">
<cfinclude template="#appsIncludes#/appsPermissions.cfm">
<cfquery name="BlockedResourcesDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimeResources WHERE BID='#url.delID#'
</cfquery>
<cfquery name="BlockedDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimes WHERE BID='#url.delID#'
</cfquery>
