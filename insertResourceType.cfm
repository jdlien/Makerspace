<!--- YouKnowIAm identifies the currently authenticated user on Staffweb --->
<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset ApplicationID="MakerspaceBooking">
<cfset PermissionsRequired_List="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfif isDefined('SubmitNew')>
	<cfquery name="InsertResource" datasource="ReadWriteSource" dbtype="ODBC">
		INSERT INTO MakerSpaceBookingResourceTypes (TypeName, ShowByDefault, TypeWeekdayMaxBookings, TypeWeekendMaxBookings, ModifiedBy, Modified, OfficeCode)
		VALUES(
			'#form.TypeName#',
			<cfif isDefined('form.ShowByDefault') AND form.ShowByDefault IS 'on'>1<cfelse>0</cfif>,
			<cfif isDefined('form.TypeWeekdayMaxBookings') AND IsNumeric(form.TypeWeekdayMaxBookings)>#form.TypeWeekdayMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.TypeWeekendMaxBookings') AND IsNumeric(form.TypeWeekendMaxBookings)>#form.TypeWeekendMaxBookings#<cfelse>NULL</cfif>,	
			'#YouKnowIAm#',
			GETDATE(),
			'#form.typeBranch#'
			)
	</cfquery>
</cfif>
<cflocation addtoken="no" url="resources.cfm">