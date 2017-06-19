<!--- makerspaceNotify.cfm is a system that will email Makerspace customers about upcoming bookings if they have a booking
that way made days in advance --->


<!--- CHANGE THE 300 to 30 when testing is complete --->
<cfquery name="BookingsNotify" dbtype="ODBC" datasource="SecureSource">
	SELECT ty.TypeID as TID, UserBarCode, t.FirstName, t.LastName, t.Email, t.StartTime, t.EndTime, t.Inserted, t.Notified, t.RID,
	r.ResourceName, r.Description, ty.OfficeCode, o.OfficeName, o.CommonName, o.OfficeAddress, o.Phone1
	FROM vsd.MakerspaceBookingTimes t
	JOIN vsd.MakerspaceBookingResources r ON t.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID
	JOIN vsd.Offices o ON ty.OfficeCode=o.OfficeCode
	WHERE 1=1
	AND DATEDIFF(hour, GETDATE(), StartTime)<=30 --Only Events thirty or fewer hours after now
	AND DATEDIFF(hour, GETDATE(), StartTime)>=0 -- But not events that have already happened
	AND DATEDIFF(hour, Inserted, StartTime) >= 16 --Only events starting more than a day after they were scheduled
	AND (Notified !=1 OR Notified IS NULL) -- Where the email hasn't been sent yet
	AND LEN(t.Email) > 5 --with a non-blank email address
	ORDER BY t.RID, StartTime
</cfquery>
<cfset mailCount=0 />
<cfoutput>
<cfset lastUserBarcode="">
<cfset lastStartTime="2017-01-01 00:00">
<cfset lastRID="">
<cfset skipThis = false />
<cfloop query="BookingsNotify">
<!--- Skip if the last booking is the same card number and the time was one hour before --->
<cfif lastUserBarcode EQ UserBarcode AND lastRID EQ RID
	AND DateDiff("h", lastStartTime, startTime) IS 1>
	<cfset skipThis = true>
<cfelse>
	<cfset skipThis = false>
</cfif>
<cfif isValid("email", email) AND NOT skipThis >
	<cfif OfficeCode IS "ESQ">
		<cfset fromEmail = '"EPL Makerspace" <makerspace@epl.ca>' />
	<cfelse>
		<cfset fromEmail = '"DO NOT REPLY" <noreply@epl.ca>' />
	</cfif>
<!--- <cfmail from='#fromEmail#' to="jlien@epl.ca" subject="Your EPL Makerspace Booking" type="html"> --->
<cfmail from='#fromEmail#' to='"#FirstName# #LastName#"<#Email#>' bcc="jlien@epl.ca" subject="Your EPL Makerspace Booking" type="html">
<p>Dear #FirstName#:</p>

<p>This is a notification of your upcoming booking at the <cfif OfficeCode IS "ESQ">Edmonton Public Library Makerspace<cfelse>#OfficeName# Branch</cfif>,  #OfficeAddress#.<br />
You have a booking for <em>#ResourceName#</em><br />

<cfif DateFormat(Now(), "yyyy-mmm-dd") IS DateFormat(StartTime, "yyyy-mmm-dd")>Today </cfif>at <strong>#TimeFormat(StartTime, "h:mm tt")#</strong>
on #DateFormat(StartTime, "Mmmm d")#.</p>


<cfif OfficeCode IS "ESQ">
<p><strong>If you can not come in for your booking, please reply to this email</strong> (at <a href="mailto:makerspace@epl.ca">makerspace@epl.ca</a>) or call the Makerspace at 780-944-5342</p>
<cfelse>
<p><strong>If you can not come in for your booking, call the #OfficeName# Branch at #phone1#</strong>. Please do not reply to this email.</p>	
</cfif>

<p>Thank you,<br />
Edmonton Public Library</p>
</cfmail>

<cfset mailCount++ />
</cfif><!---isValid email and NOT skipping--->


<cfquery name="UpdateBookingNotified" dbtype="ODBC" datasource="ReadWriteSource">
	UPDATE vsd.MakerspaceBookingTimes SET Notified=1 WHERE TID=#BookingsNotify.TID#
</cfquery>


<cfset lastUserBarcode=UserBarcode>
<cfset lastStartTime=StartTime>
<cfset lastRID=RID>
</cfloop>

#mailCount# Email<cfif mailCount NEQ 1>s have<cfelse> has</cfif> been sent to Makerspace Customers.
</cfoutput>
