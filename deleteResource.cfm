<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">

<cfquery name="check" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingTimes WHERE RID='#url.delID#'
</cfquery>
<cfif check.RecordCount>
	<cfquery name="ResourceBookingDelete" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM vsd.MakerspaceBookingTimes WHERE RID='#url.delID#'
	</cfquery>
</cfif>

<cfquery name="check" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBlockedTimes WHERE RID='#url.delID#'
</cfquery>
<cfif check.RecordCount>
	<cfquery name="ResourceBlockedDelete" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM vsd.MakerspaceBlockedTimes WHERE RID='#url.delID#'
	</cfquery>
</cfif>

<cfquery name="check" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBlockedTimeResources WHERE RID='#url.delID#'
</cfquery>
<cfif check.RecordCount>
	<cfquery name="ResourceBlockedResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM vsd.MakerspaceBlockedTimeResources WHERE RID='#url.delID#'
	</cfquery>
</cfif>

<cfquery name="check" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingResources WHERE RID='#url.delID#'
</cfquery>
<cfif check.RecordCount>
	<cfquery name="ResourceDelete" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM vsd.MakerspaceBookingResources WHERE RID='#url.delID#'
	</cfquery>
</cfif>