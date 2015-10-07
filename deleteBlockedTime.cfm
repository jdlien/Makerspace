<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfquery name="BlockedResourcesDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimeResources WHERE BID='#url.delID#'
</cfquery>
<cfquery name="BlockedDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimes WHERE BID='#url.delID#'
</cfquery>
