<cfset YouKnowIAm = REReplace(getauthuser(), '(?:.*[\\\/])?(.*)', '\1')>
<cfsetting showdebugoutput="no">
<cfsetting enablecfoutputonly="no">
<!--- AddBooking.cfm
	Inserts a new booking for a makerspace resource into the DB.
	Returns JSON of events for this resource.
	
	Extend this to validate to ensure valid barcode, allowed booking times
	-check that the entry doesn't overlap any existing entries
	-time must be in the future and less than a week from now
	-delete any entries where the end time is before now and the user is the same
	-Insert the new entry
	-reload the calendar JSON data
	
	I could do a default for end time.
	
	-Don't allow bookings during blocked times.
	
	-Require special parameter to be passed in order to delete events and book a new one.
	-Return something that triggers a confirmation dialogue so that parameter can be passed.
	
	2014-07-23
	-Add check against Weekday/Weekend Limits for Type and Resource for the current user except exempt cards.
		-Chosen date is weekday/is weekend
		-What are the limits for this type of day for this resource and type. Take the smallest.
		-How many are currently booked for this user for this day?
--->
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
<cfelse>
	<cfinclude template="/AppsRoot/Includes/INTRealState.cfm">
	<cfset ThisLocation=RealStateBuilding/>
</cfif>

<cfif isDefined('form.newstart')>
	<cfset exemptCards="21221012345678,2122111111111">

	<cfset newstart=Replace(form.newstart, 'T', ' ')>
	<cfset newend=Replace(form.newend, 'T', ' ')>
	<cfset eventBegin=CreateDateTime(Year(newstart),Month(newstart),Day(newstart),Hour(newstart),Minute(newstart),00)>
	<cfset eventEnd=CreateDateTime(Year(newend),Month(newend),Day(newend),Hour(newend),Minute(newend),00)>	
	<!--- Determine if this booking is for a weekend --->
	
	<cfif DayOfWeek(eventBegin) IS 7 OR DayOfWeek(eventBegin) IS 1>
		<cfset isWeekend=true>
	<cfelse>
		<cfset isWeekend=false>
	</cfif>
	
	<cfif isDefined('form.id')>
		<!--- Clean out any spaces from the user input --->
		<cfset form.id=Replace(form.id,' ', '', 'ALL')>
		<cfif len(form.id IS 14)>
			<!--- Get information about the current booking's resource --->
			<cfquery name="ResourceList" datasource="SecureSource" dbtype="ODBC">
				SELECT * FROM MakerspaceBookingResources r 
				LEFT JOIN MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID 
				WHERE r.RID='#form.rid#'
			</cfquery>
			<cfset ThisTypeID=ResourceList.TypeID>


			<cfif ListFind(exemptCards, form.id) EQ 0>
				<cfset notExempt=true />
			<cfelse>
				<cfset notExempt=false />
			</cfif>

			<!--- Initialize our error handling variables --->
			<cfset data = StructNew()>
			<cfset data.error=false>
			<cfset data.errorMsg="">

			<!--- Prevent booking if it is in the past --->
			<cfif DateCompare(newend, now()) LT 0>
				<cfset data.pastDate=true>
				<cfset data.form=form>
				<cfif form.confirmDelete IS NOT 'true'>
					<cfset data.requireConfirm=true>
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort>			
				</cfif>
			</cfif>
			
			<!--- Prevent booking this system if it's already booked by anyone--->
			<cfquery name="DoubleBookings" datasource="ReadWriteSource" dbtype="ODBC">
				SELECT * FROM MakerspaceBookingTimes ti
				WHERE (RID='#form.rid#'
					AND StartTime >='#form.newstart#' AND EndTime <= '#form.newend#')
			</cfquery>
			<cfif DoubleBookings.RecordCount>
				<cfset data.error=true>
				<cfset data.errorMsg&="There is already a booking for this resource at this time">
				<cfoutput>#SerializeJSON(data)#</cfoutput>
				<cfabort>			
			</cfif>

			<cfif ResourceList.AllowBlocked NEQ 1 AND form.status IS 'BLOCKED'>
				<cfset data.error=true>
				<cfset data.errorMsg&="This resource may not be booked with a blocked card.">
				<cfoutput>#SerializeJSON(data)#</cfoutput>
				<cfabort>			
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
				)
				AND t.startTime < '#form.newend#' AND t.EndTime > '#form.newstart#'
			</cfquery>
			<!--- Now I need to loop through the blocked time events
			and check that their applicable times don't collide with the new event --->			
			<cfoutput query="BlockedTimes">
				<!--- continuous blocked time (this is the simplest to do) --->
				<cfif Continuous IS 1>
						<cfset data.error=true>
						<cfset data.errorMsg&="You may not book this resource at this time.<br />#BlockedTimes.Description#">
				<cfelse>
					<!--- set up date objects to Compare event times with blocked times --->
					<cfset blockEnd=CreateDateTime(Year(newstart),Month(newstart),Day(newstart),Hour(endTime),Minute(endTime),00)>
					<cfset blockBegin=CreateDateTime(Year(newend),Month(newend),Day(newend),Hour(startTime),Minute(startTime),00)>
					<!--- If blockbegin is before the end of the new event OR the block's end is before the event's beginning
					then the block overlaps with the new event
					OR the day of week is the same as our event --->
					<cfif (DayOfWeek(eventBegin)-1 IS DayofWeek OR DayofWeek IS "")
					AND (DateCompare(blockBegin,eventEnd) LT 0 AND DateCompare(blockEnd,eventBegin) GT 0)>
						<cfset data.error=true>
						<cfset data.errorMsg&="You may not book this resource at this time.<br />#BlockedTimes.Description#">						
					</cfif>
				</cfif><!---if Continuous--->
			</cfoutput><!---BlockedTimes--->

			<!--- Check that the user hasn't already booked the max slots for this resource or type for this day --->
			<!--- Count number of bookings for this resource already on this day --->
			<cfif notExempt>
				<cfquery name="BookingCount"  dbtype="ODBC" datasource="SecureSource">
					SELECT COUNT(1) AS TypeSlotsBooked, 
						(SELECT COUNT(1) FROM MakerspaceBookingTimes
						WHERE CAST(FLOOR(CAST(StartTime AS FLOAT)) AS DATETIME) = CAST(FLOOR(CAST(CAST('#form.newstart#' AS DATETIME) AS FLOAT)) AS DATETIME)
						AND UserBarCode='#form.id#'
						AND RID=#form.rid#) AS ResSlotsBooked
					FROM MakerspaceBookingTimes bt
					JOIN MakerspaceBookingResources r on r.RID=bt.RID
					JOIN MakerspaceBookingResourceTypes t ON t.TypeID=r.TypeID
					WHERE CAST(FLOOR(CAST(StartTime AS FLOAT)) AS DATETIME) = CAST(FLOOR(CAST(CAST('#form.newstart#' AS DATETIME) AS FLOAT)) AS DATETIME)
					AND UserBarCode='#form.id#'
					AND r.TypeID=#ThisTypeID#		
				</cfquery>
				<cfif isWeekend>
					<cfif IsNumeric(ResourceList.TypeWeekendMaxBookings) AND BookingCount.TypeSlotsBooked GTE ResourceList.TypeWeekendMaxBookings>
						<cfset data.error=true>
						<cfset data.errorMsg&="You have already booked the weekend maximum #ResourceList.TypeWeekendMaxBookings# time slots for the #ResourceList.TypeName# resource type.">
					<cfelseif IsNumeric(ResourceList.WeekendMaxBookings) AND BookingCount.ResSlotsBooked GTE ResourceList.WeekendMaxBookings>
						<cfset data.error=true>
						<cfset data.errorMsg&="You have already booked the weekend maximum #ResourceList.WeekendMaxBookings# time slots for the #ResourceList.ResourceName# resource.">					
					</cfif>
				<cfelse><!--- is a weekday --->
					<cfif IsNumeric(ResourceList.TypeWeekdayMaxBookings) AND BookingCount.TypeSlotsBooked GTE ResourceList.TypeWeekdayMaxBookings>
						<cfset data.error=true>
						<cfset data.errorMsg&="You have already booked the weekday maximum #ResourceList.TypeWeekdayMaxBookings# time slots for the #ResourceList.TypeName# resource type.">					
					<cfelseif IsNumeric(ResourceList.WeekdayMaxBookings) AND BookingCount.ResSlotsBooked GTE ResourceList.WeekdayMaxBookings>
						<cfset data.error=true>
						<cfset data.errorMsg&="You have already booked the weekday maximum #ResourceList.WeekdayMaxBookings# time slots for the #ResourceList.ResourceName# resource.">					
					</cfif>
				</cfif>
			</cfif><!--- check if exemptCard --->
			
			
			<cfif data.error IS true>
				<cfoutput>#SerializeJSON(data)#</cfoutput>
				<cfabort>
			</cfif>




			<!--- If we are not booking a concurrently bookable resource, we do some checks
					Here we need a list of other non-concurrent bookings for this user *at this time*
			--->
			<cfif ResourceList.Concurrent NEQ 1 AND notExempt>
				<!--- Check for other bookings at this time slot on a non-concurrent resource --->
				<cfquery name="NonConcurrentBookings" datasource="ReadWriteSource" dbtype="ODBC">
					SELECT * FROM MakerspaceBookingTimes ti
					JOIN MakerspaceBookingResources r on r.RID=ti.RID
					WHERE (r.Concurrent = 0 OR r.Concurrent IS NULL)
						AND UserBarcode='#form.id#'
						AND StartTime='#form.newstart#'
				</cfquery>
				<cfif notExempt AND NonConcurrentBookings.RecordCount>
					<cfloop query="NonConcurrentBookings">
						<cfset data.ConflictingBookings[currentRow]=StructNew()>
						<cfset data.ConflictingBookings[currentRow].UserBarcode=UserBarcode>
						<cfset data.ConflictingBookings[currentRow].RID=RID>
						<cfset data.ConflictingBookings[currentRow].START=StartTime>
					</cfloop>

				</cfif><!---NonConcurrentBookings.RecordCount--->
				<!--- We can't book because we have other nonconcurrent bookings.  --->
			</cfif>


			<!--- This feature will only apply to non-concurrent conflicting bookings --->
			<!--- If we found a concurrent booking that needs to be deleted, we require permission from the user --->
			<cfif notExempt>
			<cfif ResourceList.Concurrent NEQ 1 AND NonConcurrentBookings.Recordcount AND isDefined('form.confirmDelete') AND form.confirmDelete IS 'true'>
				<cfquery name="CleanUpNonConcurrentBookings" datasource="ReadWriteSource" dbtype="ODBC">
					DELETE MakerspaceBookingTimes 
					FROM MakerspaceBookingTimes ti
					JOIN MakerspaceBookingResources r on r.RID=ti.RID
					WHERE (UserBarcode='#form.id#'
						AND StartTime='#form.newstart#'
						AND (Concurrent = 0 OR Concurrent IS NULL))
				</cfquery>			

			<cfelseif ResourceList.Concurrent NEQ 1 AND NonConcurrentBookings.Recordcount>
				<cfset data.requireConfirm=true>
				<!--- this might be handy for resubmission --->
				<cfset data.form=form>
			</cfif><!--- if extra bookings and confirmed to delete --->
			</cfif><!---notExempt--->

			<!--- Count the number of future bookings for this resource --->
			<cfquery name="FutureBookings" datasource="ReadWriteSource" dbtype="ODBC">
				SELECT * FROM vsd.MakerspaceBookingTimes ti
				JOIN vsd.MakerspaceBookingResources r on r.RID=ti.RID
				WHERE ti.RID='#form.rid#'
					AND UserBarcode='#form.id#'
					AND StartTime > GETDATE()
			</cfquery>

			<!--- Count the number of future bookings for this resource type --->
			<cfquery name="FutureBookingsType" datasource="ReadWriteSource" dbtype="ODBC">
				SELECT * FROM vsd.MakerspaceBookingTimes ti
				JOIN vsd.MakerspaceBookingResources r on r.RID=ti.RID
				WHERE TypeID='#ThisTypeID#'
					AND UserBarcode='#form.id#'
					AND StartTime > GETDATE()
			</cfquery>



			<!--- Now we are comparing the quantity of extra bookings --->
			
			<!--- Return one of the following errors, starting with the error for the specific resource --->
			<!--- Compare Each of FutureBookings and FutureBookingsType against the FutureMax and TypeFutureMax --->
			<cfif IsNumeric(ResourceList.FutureMaxBookings) 
				AND FutureBookings.RecordCount GTE ResourceList.FutureMaxBookings
				AND notExempt>
				<!--- Return an error along with our list of conflicting bookings. --->
					<cfset data.error=true>
					<cfset data.errorMsg&="#ResourceList.ResourceName# only allows for #ResourceList.FutureMaxBookings# future bookings."/>
					<!--- Return a nice structure of the conflicting bookings --->
					<cfif FutureBookings.RecordCount>
						<cfset data.FutureBookings=ArrayNew(1)>
						<cfloop query="FutureBookings">
							<cfset data.FutureBookings[currentRow]=StructNew()>
							<cfset data.FutureBookings[currentRow].UserBarcode=UserBarcode>
							<cfset data.FutureBookings[currentRow].RID=RID>
							<cfset data.FutureBookings[currentRow].START=StartTime>
						</cfloop>
					</cfif>
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort />
			</cfif>
			<cfif IsNumeric(ResourceList.TypeFutureMaxBookings)
				AND FutureBookingsType.RecordCount GTE ResourceList.TypeFutureMaxBookings
				AND notExempt
				AND NOT (isDefined('data.RequireConfirm') AND data.RequireConfirm IS true AND FutureBookings.RecordCount NEQ 1)>
				<!--- Return an error along with our list of conflicting bookings. --->
				<!--- Give the user a chance to resolve a single non-concurrency confclit --->
					<cfset data.error=true>
					<cfset data.errorMsg&="The #ResourceList.TypeName# type only allows for #ResourceList.TypeFutureMaxBookings# future bookings."/>
					<cfif FutureBookingsType.RecordCount AND notExempt>
						<cfset data.FutureBookings=ArrayNew(1)>
						<cfloop query="FutureBookingsType">
							<cfset data.FutureBookings[currentRow]=StructNew()>
							<cfset data.FutureBookings[currentRow].UserBarcode=UserBarcode>
							<cfset data.FutureBookings[currentRow].RID=RID>
							<cfset data.FutureBookings[currentRow].START=StartTime>
						</cfloop>
					</cfif>
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort />
			</cfif>





			<cfif notExempt IS false 
					OR ResourceList.Concurrent EQ 1 
					OR NonConcurrentBookings.Recordcount EQ 0
					OR isDefined('form.confirmDelete') AND form.confirmDelete IS 'true'>
				<!--- if I want to be thorough, I could set an end time that's 55 minutes after the start --->
				<cfquery name="InsertNewBooking" datasource="ReadWriteSource" dbtype="ODBC">
					INSERT INTO MakerspaceBookingTimes (RID, <cfif isDefined('form.id')>UserBarcode, </cfif>
					StartTime, EndTime, Inserted, InsertedBy
					<cfif isDefined('form.firstname')>, FirstName</cfif>
					<cfif isDefined('form.lastname')>, LastName</cfif>)
					VALUES (
						'#form.rid#',
						<cfif isDefined('form.id')>'#form.id#',</cfif>
						'#form.newstart#',
						'#form.newend#',
						GETDATE(),
						'#YouKnowIAm#'
						<cfif isDefined('form.firstname')>, '#form.firstname#'</cfif>
						<cfif isDefined('form.lastname')>, '#form.lastname#'</cfif>
					)
					SELECT SCOPE_IDENTITY() AS NewBookingID
				</cfquery>
				
				<cfset data.NewBooking=StructNew()>
				<cfset data.NewBooking.id=InsertNewBooking.NewBookingID>
				<cfset data.NewBooking.rid=form.rid>
				<cfset data.NewBooking.start=form.newstart>
				<cfset data.NewBooking.end=form.newend>

			</cfif><!---Either no extra bookings or confirmation--->
		<cfelse>
			<cfset data.error=true>
			<cfset data.errorMsg="Invalid library card number.">
		</cfif><!--- if ID is 14 digits --->
	</cfif><!--- if form.id is defined --->	
	<cfoutput>#SerializeJSON(data)#</cfoutput>
</cfif><!---if form start defined--->
