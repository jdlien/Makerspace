<!--- Just shows information about a certain type that can be requested via AJAX request --->
<cfsetting showdebugoutput="false" />
<cfif isDefined('url.typeid') AND isNumeric(url.typeid)>

	<cfquery name="TypeInfo" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingResourceTypes t
		JOIN vsd.Offices o ON o.OfficeCode=t.OfficeCode
		WHERE TypeID=#url.typeid#
	</cfquery>

	<cfif TypeInfo.RecordCount EQ 0>
		<span class="error">TypeID <cfoutput>#url.typeid#</cfoutput> does not exist.</span>
		<cfabort />
	</cfif>

	<cfoutput query="TypeInfo">
	<!--- <h3>Type Details</h3> --->

	<div>Type Maximums: <b>Weekday:</b> <cfif IsNumeric(TypeWeekdayMaxBookings)>#TypeWeekdayMaxBookings#<cfelse>_</cfif>&nbsp;&nbsp;
		<b>Weekend:</b> <cfif IsNumeric(TypeWeekendMaxBookings)>#TypeWeekendMaxBookings#<cfelse>_</cfif>&nbsp;&nbsp;
		<b>Future:</b> <cfif IsNumeric(TypeFutureMaxBookings)>#TypeFutureMaxBookings#<cfelse>_</cfif></div>

	<!--- <div><b>Branch:</b> #OfficeName#</div> --->

	<cfif ShowByDefault EQ "1">
		<div>Shown by default.</div>
	<cfelse>
		<div><b>Not</b> shown by default.</div>
	</cfif>

	</cfoutput>

</cfif>