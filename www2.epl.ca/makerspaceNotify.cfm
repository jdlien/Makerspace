<!--- makerspaceNotify.cfm is a system that will email Makerspace customers about upcoming bookings if they have a booking
that way made days in advance --->

<cfquery name="BookingsNotify" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingTimes
	WHERE 1=1
	AND DATEDIFF(hour, GETDATE(), StartTime)<=3 --Only Events three OR less hours after now
	AND DATEDIFF(hour, GETDATE(), StartTime)>=0 -- But not events that have already happened
	AND DATEDIFF(day, Inserted, StartTime) >= 1 --Only events starting more than a day after they were scheduled
	AND (Notified !=1 OR Notified IS NULL) -- Where the email hasn't been sent yet
	ORDER BY StartTime
</cfquery>

<cfdump var="#BookingsNotify#" />