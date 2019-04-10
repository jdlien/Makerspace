<cfsetting showdebugoutput="false" />
<!--- If this is being called independently (for editEvent.cfm), create the data struct --->
<cfif isDefined('form.tid')>
	<cfset data = structNew() />
	<cfset data.ERROR=false />
	<cfset data.ERRORMSG="" />
	<cfset data.MSG="" />

	<cfquery name="ResInfo" dbtype="ODBC" datasource="SecureSource">
		SELECT OfficeCode, r.TypeID FROM vsd.MakerspaceBookingResources r
		JOIN vsd.MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID
		WHERE r.RID=#form.rid#
	</cfquery>

	<cfset thisLocation=ResInfo.OfficeCode />
	<cfset thisTypeID=ResInfo.TypeID />
	<cfset eventBegin=CreateDateTime(Year(newstart),Month(newstart),Day(newstart),Hour(newstart),Minute(newstart),00)>
	<cfset eventEnd=CreateDateTime(Year(newend),Month(newend),Day(newend),Hour(newend),Minute(newend),00)>	

<!--- <cfdump var="#form#"> --->
</cfif>

<!--- Prevent booking this resource if the length is shorter than ten minutes --->
<cfset bookingDurMins = DateDiff("n", eventBegin, eventEnd) />
<cfif bookingDurMins LT 15>
	<cfset data.ERROR=true>
	<cfset data.ERRORMSG&="End time must be at least 15 minutes after the start time.<br /><br />Ensure that your end time is not before the start time.">
	<cfset data.MSG&='<span class="error">'&data.ERRORMSG&'</span>' />
	<cfoutput>#SerializeJSON(data)#</cfoutput>
	<cfabort>
</cfif>

<!--- Prevent booking this system if it's already booked by anyone--->

<!---
	- Are there any bookings with a start time before this start time?
	- Do any of those bookings also have an end time after this end time?

	- Are there any bookings with an end time before this end time?
	- Do any of those bookings also have a start time after this start time?
--->

<cfquery name="DoubleBookings" datasource="ReadWriteSource" dbtype="ODBC">
	SELECT * FROM MakerspaceBookingTimes ti
	WHERE (
		RID='#form.rid#' AND (
			<!--- Existing booking completely overlaps new time --->
			(StartTime <= '#form.newStart#' AND EndTime >= '#form.newEnd#')
			OR
			<!--- Existing booking occurs inside of new time --->
			(StartTime >= '#form.newStart#' AND EndTime <= '#form.newEnd#')
			OR
			<!--- Existing booking overlaps beginning of new time --->
			(StartTime <= '#form.newStart#' AND EndTime > '#form.newStart#')
			OR
			<!--- Existing booking overlaps end of new time --->
			(StartTime < '#form.newEnd#' AND EndTime >= '#form.newEnd#')
			)
		 <!--- exclude the booking that we're checking for --->
		<cfif isDefined('form.tid')> AND TID != #form.tid#</cfif>
	)
</cfquery>

<!--- <cfdump var="#DoubleBookings#"> --->

<cfif DoubleBookings.RecordCount>

	<!--- Now if there was a booking, we check to see if it ended more than fifteen minutes before the end of the hour --->
	<cfset priorBookingEndMinute = TimeFormat(DoubleBookings.EndTime, "mm") />
	<cfset priorBookingStartMinute = TimeFormat(DoubleBookings.StartTime, "mm") />
	<cfif priorBookingEndMinute LTE 45>

		<!--- Adjust the start time to be when the "overlapping" booking ends --->
		<!--- <cfdump var="#newStart#"> --->
		<!--- This may not be the most elegant solution on earth,
			but if I assume a consistent format, a regex should effectively alter the starttime --->
		<cfset form.newStart = REReplace(form.newStart, "(.*)(\d\d):(\d\d):(\d\d)$", "\1\2:#priorBookingEndMinute#:\4") />
		<cfset newstart=Replace(form.newstart, 'T', ' ')>
		<cfset eventBegin=CreateDateTime(Year(newstart),Month(newstart),Day(newstart),Hour(newstart),Minute(newstart),00)>
	<cfelseif priorBookingStartMinute GTE 15>
		<cfset form.newEnd = REReplace(form.newEnd, "(.*)(\d\d):(\d\d):(\d\d)$", "\1\2:#priorBookingStartMinute#:\4") />
		<cfset newend=Replace(form.newstart, 'T', ' ')>
		<cfset eventEnd=CreateDateTime(Year(newend),Month(newend),Day(newend),Hour(newend),Minute(newend),00)>
	<cfelse>
		<cfset data.ERROR=true>
		<cfset data.ERRORMSG&="There is already a booking for this resource at this time">
		<cfset data.MSG&='<span class="error">'&data.ERRORMSG&'</span>' />
		<cfoutput>#SerializeJSON(data)#</cfoutput>
		<cfabort>
	</cfif>
</cfif>


<!--- Check that this event's end time isn't before any blocked times start --->
<cfquery name="BlockedTimes" datasource="SecureSource" dbtype="ODBC">
	SELECT t.BID, ISNULL(t.RID, btr.RID) AS RID, ISNULL(t.TypeID, btr.TypeID) AS TypeID, StartTime, EndTime,
	DayofWeek, Continuous, t.Description, t.ModifiedBy,
	t.Modified, r.ResourceName, ty.TypeName
	FROM MakerspaceBlockedTimes t
	LEFT JOIN MakerspaceBlockedTimeResources btr on btr.BID=t.BID
	LEFT JOIN MakerspaceBookingResources r on t.RID=r.rid OR btr.RID=r.rid
	LEFT JOIN MakerspaceBookingResourceTypes ty on t.TypeID=ty.TypeID OR btr.TypeID=ty.TypeID
	WHERE t.OfficeCode='#ThisLocation#'
	AND (
		(ISNULL(t.RID, btr.RID)='#form.rid#' OR ISNULL(t.TypeID, btr.TypeID)='#ThisTypeID#') 
		OR (ISNULL(t.RID, btr.RID) IS NULL AND ISNULL(t.TypeID, btr.TypeID) IS NULL)
	) AND (
			<!--- Blocked Time completely overlaps new time --->
			(t.StartTime <= '#form.newStart#' AND t.EndTime >= '#form.newEnd#')
			OR
			<!--- Blocked Time occurs inside of new time --->
			(t.StartTime >= '#form.newStart#' AND t.EndTime <= '#form.newEnd#')
			OR
			<!--- Blocked Time overlaps beginning of new time --->
			(t.StartTime <= '#form.newStart#' AND t.EndTime > '#form.newStart#')
			OR
			<!--- Blocked Time overlaps end of new time --->
			(t.StartTime < '#form.newEnd#' AND t.EndTime >= '#form.newEnd#')
		)
</cfquery>

<!--- Now I need to loop through the blocked time events
and check that their applicable times don't collide with the new event --->			
<cfoutput query="BlockedTimes">
	<!--- continuous blocked time (this is the simplest to do) --->
	<cfif Continuous IS 1>
			<cfset data.ERROR=true>
			<cfset data.ERRORMSG&="You may not book this resource at this time.<br />#BlockedTimes.Description#">
			<cfset data.MSG&='<span class="error">'&data.ERRORMSG&'</span>' />
	<cfelse>
		<!--- set up date objects to Compare event times with blocked times --->
		<cfset blockEnd=CreateDateTime(Year(newstart),Month(newstart),Day(newstart),Hour(endTime),Minute(endTime),00)>
		<cfset blockBegin=CreateDateTime(Year(newend),Month(newend),Day(newend),Hour(startTime),Minute(startTime),00)>
		<!--- If blockbegin is before the end of the new event OR the block's end is before the event's beginning
		then the block overlaps with the new event
		OR the day of week is the same as our event --->
		<cfif (DayOfWeek(eventBegin)-1 IS DayofWeek OR DayofWeek IS "")
		AND (
			<!--- note that we're allowing times to match exactly under some circumstances --->
			<!--- Blocked Time completely overlaps new time --->
			(DateCompare(blockBegin,eventBegin) LTE 0 AND DateCompare(blockEnd,eventEnd) GTE 0)
			OR
			<!--- Blocked Time occurs inside of new time --->
			(DateCompare(blockBegin,eventBegin) GTE 0 AND DateCompare(blockEnd,eventEnd) LTE 0)
			OR
			<!--- Blocked Time overlaps beginning of new time --->
			(DateCompare(blockBegin,eventBegin) LTE 0 AND DateCompare(blockEnd,eventBegin) GT 0)
			OR
			<!--- Blocked Time overlaps end of new time --->
			(DateCompare(blockBegin,eventEnd) LT 0 AND DateCompare(blockEnd,eventEnd) GTE 0)

		)>
			<cfset data.ERROR=true>
			<cfset data.ERRORMSG&="You may not book this resource at this time.<br />#BlockedTimes.Description#">
			<cfset data.MSG&='<span class="error">'&data.ERRORMSG&'</span>' />
			<cfoutput>#SerializeJSON(data)#</cfoutput>
			<cfabort>					
		</cfif>
	</cfif><!---if Continuous/else--->
</cfoutput><!---BlockedTimes--->

<!--- If we're using editEvent, at this point we can output the data structure with no error --->
<cfif isDefined('form.tid')>
	<cfoutput>#SerializeJSON(data)#</cfoutput>
</cfif>