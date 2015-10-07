<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<!--- It may be prudent to delete blocked times that use this type --->
<cfquery name="ResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBookingResourceTypes WHERE TypeID='#url.delID#'
</cfquery>