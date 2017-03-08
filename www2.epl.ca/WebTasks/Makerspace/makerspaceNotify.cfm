<!--- makerspaceNotify.cfm is a system that will email Makerspace customers about upcoming bookings if they have a booking
that way made days in advance --->


<!--- CHANGE THE 300 to 30 when testing is complete --->
<cfquery name="BookingsNotify" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingTimes t
	JOIN vsd.MakerspaceBookingResources r ON t.RID=r.RID
	WHERE 1=1
	AND DATEDIFF(hour, GETDATE(), StartTime)<=30 --Only Events thirty or fewer hours after now
	AND DATEDIFF(hour, GETDATE(), StartTime)>=0 -- But not events that have already happened
	AND DATEDIFF(hour, Inserted, StartTime) >= 16 --Only events starting more than a day after they were scheduled
	AND (Notified !=1 OR Notified IS NULL) -- Where the email hasn't been sent yet
	AND LEN(Email) > 5 --with a non-blank email address
	ORDER BY StartTime
</cfquery>

<cfoutput>
<cfloop query="BookingsNotify">
<cfmail from='"EPL Makerspace" <makerspace@epl.ca>' to='"#FirstName# #LastName#"<#Email#>' bcc="jlien@epl.ca" subject="Your EPL Makerspace Booking" type="html">
<p>Dear #FirstName#:</p>

<p>This is a notification of your upcoming booking at the Edmonton Public Library Makerspace.<br />
You have a booking for <em>#ResourceName# - #Description#</em><br />
<cfif DateFormat(Now(), "yyyy-mmm-dd") IS DateFormat(StartTime, "yyyy-mmm-dd")>Today </cfif>at <strong>#TimeFormat(StartTime, "h:mm tt")#</strong>
on #DateFormat(StartTime, "Mmmm d")#.</p>

<p><strong>If you can not come in for your booking, please reply to this email</strong> (at <a href="mailto:makerspace@epl.ca">makerspace@epl.ca</a>) or call the Makerspace at 780-944-5342</p>

<p>Thank you,<br />
Edmonton Public Library</p>
</cfmail>

<cfquery name="UpdateBookingNotified" dbtype="ODBC" datasource="ReadWriteSource">
	UPDATE vsd.MakerspaceBookingTimes SET Notified=1 WHERE TID=#BookingsNotify.TID#
</cfquery>


</cfloop>

#BookingsNotify.RecordCount# Email<cfif BookingsNotify.RecordCount NEQ 1>s have<cfelse> has</cfif> been sent to Makerspace Customers.
</cfoutput>
