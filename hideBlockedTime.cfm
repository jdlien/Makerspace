<cfsetting showdebugoutput="no">
<cfsetting enablecfoutputonly="yes">
<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,block">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfquery name="CheckHidden" dbtype="ODBC" datasource="SecureSource">
	SELECT Hidden FROM MakerspaceBlockedTimes WHERE BID='#url.id#'
</cfquery>
<cfquery name="BlockedHide" dbtype="ODBC" datasource="ReadWriteSource">
	UPDATE MakerspaceBlockedTimes SET Hidden=<cfif CheckHidden.Hidden IS 1>0<cfelse>1</cfif> WHERE BID='#url.id#'
</cfquery>
<cfoutput><cfif CheckHidden.Hidden IS 1>0<cfelse>1</cfif></cfoutput>