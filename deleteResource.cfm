<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfquery name="ResourceBookingDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBookingTimes WHERE RID='#url.delID#'
</cfquery>
<cfquery name="ResourceBlockedDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimes WHERE RID='#url.delID#'
</cfquery>
<cfquery name="ResourceBlockedResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBlockedTimeResources WHERE RID='#url.delID#'
</cfquery>
<cfquery name="ResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBookingResources WHERE RID='#url.delID#'
</cfquery>