<cfinclude template="#appsIncludes#/appsInit.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,reso">
<cfinclude template="#appsIncludes#/appsPermissions.cfm">
<!--- It may be prudent to delete blocked times that use this type --->
<cfquery name="ResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
	DELETE FROM MakerspaceBookingResourceTypes WHERE TypeID='#url.delID#'
</cfquery>