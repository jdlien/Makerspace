<!--- YouKnowIAm identifies the currently authenticated user on Staffweb --->
<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,reso">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfif isDefined('SubmitNew')>
	<cfquery name="InsertResource" datasource="ReadWriteSource" dbtype="ODBC">
		INSERT INTO MakerSpaceBookingResourceTypes (TypeName, ShowByDefault,
			TypeWeekdayMaxBookings,
			TypeWeekendMaxBookings,
			TypeFutureMaxBookings,
			ModifiedBy,
			Modified,
			OfficeCode)
		VALUES(
			'#form.TypeName#',
			<cfif isDefined('form.ShowByDefault') AND form.ShowByDefault IS 'on'>1<cfelse>0</cfif>,
			<cfif isDefined('form.TypeWeekdayMaxBookings') AND IsNumeric(form.TypeWeekdayMaxBookings)>#form.TypeWeekdayMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.TypeWeekendMaxBookings') AND IsNumeric(form.TypeWeekendMaxBookings)>#form.TypeWeekendMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.TypeFutureMaxBookings') AND IsNumeric(form.TypeFutureMaxBookings)>#form.TypeFutureMaxBookings#<cfelse>NULL</cfif>,
			'#YouKnowIAm#',
			GETDATE(),
			'#form.typeBranch#'
			)
	</cfquery>
</cfif>
<cflocation addtoken="no" url="resources.cfm">