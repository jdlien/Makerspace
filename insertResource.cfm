<!--- session.identity identifies the currently authenticatd user on Staffweb --->
<cfinclude template="#app.includes#/appsInit.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,reso">
<cfinclude template="#app.includes#/appsPermissions.cfm">
<cfif isDefined('SubmitNew')>
	<cfquery name="InsertResource" datasource="ReadWriteSource" dbtype="ODBC">
		INSERT INTO MakerSpaceBookingResources (
			ResourceName,
			Description,
			TypeID,
			MaxUsers,
			Color,
			AllowBlocked,
			WeekdayMaxBookings,
			WeekendMaxBookings,
			FutureMaxBookings,
			ModifiedBy,
			Modified)
		VALUES(
			'#form.resourceName#',
			'#form.description#',
			'#form.TypeId#',
			<!---<cfif isNumeric(trim(form.UserCount))>'#form.UserCount#'<cfelse>NULL</cfif>,--->1,
			'#form.color#',
			<cfif isDefined('form.AllowBlocked') AND form.AllowBlocked IS 'on'>1<cfelse>0</cfif>,
			<cfif isDefined('form.WeekdayMaxBookings') AND IsNumeric(form.WeekdayMaxBookings)>#form.WeekdayMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.WeekendMaxBookings') AND IsNumeric(form.WeekendMaxBookings)>#form.WeekendMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.FutureMaxBookings') AND IsNumeric(form.FutureMaxBookings)>#form.FutureMaxBookings#<cfelse>NULL</cfif>,
			'#session.identity#',
			GETDATE()
			)
	</cfquery>
</cfif>
<cfif isDefined('url.branch')>
	<cflocation addtoken="no" url="resources.cfm?branch=#url.branch#">
<cfelse>
	<cflocation addtoken="no" url="resources.cfm">
</cfif>