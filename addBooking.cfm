<cfset YouKnowIAm = REReplace(getauthuser(), '(?:.*[\\\/])?(.*)', '\1')>
<cfsetting showdebugoutput="no">
<cfsetting enablecfoutputonly="no">
<cfheader name="Content-Type" value="application/json">

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
	<cfinclude template="/AppsRoot/Includes/IPOffices.cfm">
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
		<cfset form.id=Replace(trim(form.id),' ', '', 'ALL')>
		<cfif len(form.id GTE 6)>
			<!--- Get information about the current booking's resource --->
			<cfquery name="ResourceInfo" datasource="SecureSource" dbtype="ODBC">
				SELECT * FROM MakerspaceBookingResources r 
				LEFT JOIN MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID 
				WHERE r.RID='#form.rid#'
			</cfquery>
			<cfset ThisTypeID=ResourceInfo.TypeID>


			<cfif ListFind(exemptCards, form.id) EQ 0>
				<cfset notExempt=true />
			<cfelse>
				<cfset notExempt=false />
			</cfif>

			<!--- Initialize our error handling variables --->
			<cfset data = StructNew()>
			<cfset data.ERROR=false>
			<cfset data.ERRORMSG="">
			<cfset data.MSG="" />
			<cfset data.REQUIRECONFIRM=false />

			<!--- Prevent booking if it is in the past --->
			<cfif DateCompare(newend, now()) LT 0>
				<cfset data.PASTDATE=true>
				<cfset data.FORM=form>
				<cfif form.CONFIRMDELETE IS NOT 'true'>
					<cfset data.REQUIRECONFIRM=true>
					<cfset data.MSG = '<br /><span class="warning">This time is in the past.</span><br />' />
					<cfset data.MSG&='<div class="confirmQuestion">Record this resource as used at this time?<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes</a><a href="javascript:void(0);">No</a></div></div>' />					
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort>
				</cfif>
			</cfif>
			
			<!--- Prevent booking if this user is blocked and this resource doesn't allow blocked users to book it --->
			<cfif ResourceInfo.AllowBlocked NEQ 1 AND form.status IS 'BLOCKED'>
				<cfset data.ERROR=true>
				<cfset data.ERRORMSG&="This resource may not be booked with a blocked card.">
				<cfset data.MSG&='<span class="error">'&data.ERRORMSG&'</span>' />
				<cfoutput>#SerializeJSON(data)#</cfoutput>
				<cfabort>			
			</cfif>

			<!--- This include checks that there are no booking or blocked time conflicts.
			It has been broken into an include so that editEvent.cfm can also use it to check times --->
			<cfinclude template="addBookingValidityCheck.cfm" />

			<!--- If we are not booking a concurrently bookable resource, we do some checks
					Here we need a list of other non-concurrent bookings for this user *at this time*
			--->
			<cfif ResourceInfo.Concurrent NEQ 1 AND notExempt>
				<!--- Check for other bookings at this time slot on a non-concurrent resource --->
				<cfquery name="NonConcurrentBookings" datasource="ReadWriteSource" dbtype="ODBC">
					SELECT * FROM MakerspaceBookingTimes ti
					JOIN MakerspaceBookingResources r on r.RID=ti.RID
					WHERE (r.Concurrent = 0 OR r.Concurrent IS NULL)
						AND UserBarcode='#form.id#'
						AND (  '#form.newstart#' <=  StartTime 	AND '#form.newend#' >  StartTime
							OR '#form.newstart#' >= StartTime 	AND '#form.newend#' <= EndTime
							OR '#form.newstart#' <  EndTime 		AND '#form.newend#' >  EndTime )

				</cfquery>
				<cfif notExempt AND NonConcurrentBookings.RecordCount AND NOT (isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true')>
					<cfset data.MSG&='<span class="warning">To make this booking, a conflicting booking must be cancelled.</span><br />' />
					<cfloop query="NonConcurrentBookings">
						<cfset data.CONFLICTINGBOOKINGS[currentRow]=StructNew()>
						<cfset data.CONFLICTINGBOOKINGS[currentRow].UserBarcode=UserBarcode>
						<cfset data.CONFLICTINGBOOKINGS[currentRow].RID=RID>
						<cfset data.CONFLICTINGBOOKINGS[currentRow].START=StartTime>
						<cfset data.MSG&='<br />#ResourceName# at #TimeFormat(StartTime, "h:nn tt")#' />
					</cfloop>
					<cfset data.MSG&='<div class="confirmQuestion">Schedule the new booking?<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes - cancel other booking</a><a href="javascript:void(0);">No - Don&##146;t cancel anything</a></div></div>' />
					<cfset mustDelete=true />
				</cfif><!---NonConcurrentBookings.RecordCount--->
				<!--- We can't book because we have other nonconcurrent bookings.  --->
			</cfif>



			<!--- Check that the user hasn't already booked the max slots for this resource or type for this day --->
			<!--- Count number of bookings for this resource already on this day --->
			<cfif notExempt AND NOT (isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true')>
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
					<cfif IsNumeric(ResourceInfo.TypeWeekendMaxBookings) AND BookingCount.TypeSlotsBooked GTE ResourceInfo.TypeWeekendMaxBookings>
						<cfset data.REQUIRECONFIRM=true>
						<cfset data.MSG&="User has already booked the weekend maximum #ResourceInfo.TypeWeekendMaxBookings# time slots for the #ResourceInfo.TypeName# resource type.">
					<cfelseif IsNumeric(ResourceInfo.WeekendMaxBookings) AND BookingCount.ResSlotsBooked GTE ResourceInfo.WeekendMaxBookings>
						<cfset data.REQUIRECONFIRM=true>
						<cfset data.MSG&="User has already booked the weekend maximum #ResourceInfo.WeekendMaxBookings# time slots for the #ResourceInfo.ResourceName# resource.">					
					</cfif>
				<cfelse><!--- is a weekday --->
					<cfif IsNumeric(ResourceInfo.TypeWeekdayMaxBookings) AND BookingCount.TypeSlotsBooked GTE ResourceInfo.TypeWeekdayMaxBookings>
						<cfset data.REQUIRECONFIRM=true>
						<cfset data.MSG&="User has already booked the weekday maximum #ResourceInfo.TypeWeekdayMaxBookings# time slots for the #ResourceInfo.TypeName# resource type.">
					<cfelseif IsNumeric(ResourceInfo.WeekdayMaxBookings) AND BookingCount.ResSlotsBooked GTE ResourceInfo.WeekdayMaxBookings>
						<cfset data.REQUIRECONFIRM=true>
						<cfset data.MSG&="User has already booked the weekday maximum #ResourceInfo.WeekdayMaxBookings# time slots for the #ResourceInfo.ResourceName# resource.">					
					</cfif>
				</cfif>
			</cfif><!--- check if exemptCard --->
			
			
			<cfif data.ERROR IS true OR data.REQUIRECONFIRM IS true>
				<!--- Add the buttons to confirm to data.MSG --->
				<cfif NOT isDefined('mustDelete')>
					<cfset data.MSG&='<div class="confirmQuestion">Would you like to book this resource anyway?</div><div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes</a><a href="javascript:void(0);">No</a></div>' />
				</cfif>
				<cfoutput>#SerializeJSON(data)#</cfoutput>
				<cfabort>
			</cfif>


			<!--- This feature will only apply to non-concurrent conflicting bookings --->
			<!--- If we found a concurrent booking that needs to be deleted, we require permission from the user --->
			<cfif notExempt>
			<cfif ResourceInfo.Concurrent NEQ 1 AND NonConcurrentBookings.Recordcount AND isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true'>
				<cfquery name="CleanUpNonConcurrentBookings" datasource="ReadWriteSource" dbtype="ODBC">
					DELETE MakerspaceBookingTimes 
					FROM MakerspaceBookingTimes ti
					JOIN MakerspaceBookingResources r on r.RID=ti.RID
					WHERE (UserBarcode='#form.id#'
						AND (  '#form.newstart#' <=  StartTime 	AND '#form.newend#' >  StartTime
							OR '#form.newstart#' >= StartTime 	AND '#form.newend#' <= EndTime
							OR '#form.newstart#' <  EndTime 		AND '#form.newend#' >  EndTime )
						AND (Concurrent = 0 OR Concurrent IS NULL))
				</cfquery>	
				
				<!--- List items that were deleted --->
				<cfloop query="NonConcurrentBookings">
					<cfset data.MSG&='<span class="warning">The #ResourceName# booking at #TimeFormat(StartTime, "h:nn tt")# was cancelled.</span><br /><br />' />
				</cfloop>

			<cfelseif ResourceInfo.Concurrent NEQ 1 AND NonConcurrentBookings.Recordcount>
				<cfset data.REQUIRECONFIRM=true>
				<!--- this might be handy for resubmission --->
				<cfset data.FORM=form>
			</cfif><!--- if extra bookings and confirmed to delete --->
			</cfif><!---notExempt--->

			<!--- Count the number of future bookings for this resource and user --->
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
			<cfif IsNumeric(ResourceInfo.FutureMaxBookings) 
				AND FutureBookings.RecordCount GTE ResourceInfo.FutureMaxBookings
				AND NOT (isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true')
				AND notExempt>
				<!--- Return an error along with our list of conflicting bookings. --->
					<cfset data.ERRORMSG&="#ResourceInfo.ResourceName# only allows for #ResourceInfo.FutureMaxBookings# future bookings."/>
					<!--- I may be checking errormsg has length to throw exceptions. --->
					<cfset data.MSG&='<span class="warning">'&data.ERRORMSG&'</span>' />
					<cfset data.REQUIRECONFIRM=true />					
					<!--- Return a nice structure of the conflicting bookings --->
					<cfset data.MSG&='<br /><br />The following are already booked:<br />' />
					<cfif FutureBookings.RecordCount>
						<cfset data.FUTUREBOOKINGS=ArrayNew(1)>
						<cfloop query="FutureBookings">
							<cfset data.MSG&='#ResourceName# at #TimeFormat(StartTime, "h:nn tt")#' />
							<cfif DateCompare(StartTime, now(), 'd') EQ 0>
								<cfset data.MSG&=' today' />
							<cfelse>
								<cfset data.MSG&=DateFormat(StartTime, " EEE, mmm d") />
							</cfif>
							<cfset data.MSG&="<br />" />					
							<cfset data.FUTUREBOOKINGS[currentRow]=StructNew()>
							<cfset data.FUTUREBOOKINGS[currentRow].UserBarcode=UserBarcode>
							<cfset data.FUTUREBOOKINGS[currentRow].RID=RID>
							<cfset data.FUTUREBOOKINGS[currentRow].START=StartTime>
						</cfloop>
					</cfif>
					<cfif NOT isDefined('mustDelete')>
						<cfset data.MSG&='<div class="confirmQuestion">Would you like to book this resource anyway?<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes</a><a href="javascript:void(0);">No</a></div></div>' />
					</cfif>	
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort />
			</cfif>
			<cfif IsNumeric(ResourceInfo.TypeFutureMaxBookings)
				AND FutureBookingsType.RecordCount GTE ResourceInfo.TypeFutureMaxBookings
				AND NOT (isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true')
				AND notExempt
				AND NOT (isDefined('data.REQUIRECONFIRM') AND data.REQUIRECONFIRM IS true AND FutureBookings.RecordCount NEQ 1)><!--- Why NEQ 1?? --->
				<!--- Return an error along with our list of conflicting bookings. --->
				<!--- Give the user a chance to resolve a single non-concurrency conflict --->
					<cfset data.ERRORMSG&="The #ResourceInfo.TypeName# type only allows for #ResourceInfo.TypeFutureMaxBookings# future bookings."/>
					<!--- I may be checking errormsg has length to throw exceptions. --->
					<cfset data.MSG&='<span class="warning">'&data.ERRORMSG&'</span>' />
					<cfset data.REQUIRECONFIRM=true />
					<cfif FutureBookingsType.RecordCount AND notExempt>
						<cfset data.FUTUREBOOKINGS=ArrayNew(1)>
						<cfloop query="FutureBookingsType">
							<cfset data.FUTUREBOOKINGS[currentRow]=StructNew()>
							<cfset data.FUTUREBOOKINGS[currentRow].UserBarcode=UserBarcode>
							<cfset data.FUTUREBOOKINGS[currentRow].RID=RID>
							<cfset data.FUTUREBOOKINGS[currentRow].START=StartTime>
						</cfloop>
					</cfif>
					<cfset data.MSG&='<div class="confirmQuestion">Would you like to book this resource anyway?<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes</a><a href="javascript:void(0);">No</a></div></div>' />
					<cfoutput>#SerializeJSON(data)#</cfoutput>
					<cfabort />
			</cfif>


			<!--- Check that the user has any required certs --->
			<cfquery name="resourceCerts" dbtype="ODBC" datasource="SecureSource">
				SELECT * FROM vsd.MakerspaceBookingResourcesCerts rc
				JOIN vsd.MakerCerts c ON rc.MCID=c.MCID
				WHERE RID=#form.rid#
			</cfquery>

			<cfif resourceCerts.recordCount GT 0>
				<cfloop query="resourceCerts">
					<cfquery name="certCheck" dbtype="ODBC" datasource="SecureSource">
						SELECT * FROM vsd.MakerCertsCustomers WHERE UserKey = #form.userKey# AND MCID=#resourceCerts.MCID#
					</cfquery>

					<cfif certCheck.recordCount EQ 0>
						<cfset data.ERROR = true />
						<cfset data.ERRORMSG&="Patron does not have the <b>#resourceCerts.CertiName#</b> certificate.<br />" />
					</cfif>

				</cfloop>
					<cfif isDefined('data.ERROR') AND data.ERROR EQ true>
						<cfset data.MSG&='<span class="warning">'&data.ERRORMSG&'</span>' />
						<cfoutput>#SerializeJSON(data)#</cfoutput>
						<cfabort />						
					</cfif>
			</cfif>


			<!--- If we have gotten this far, things look good. Ensure we don't have bookings that conflict with concurrency --->
			<cfif notExempt IS false 
					OR ResourceInfo.Concurrent EQ 1 
					OR NonConcurrentBookings.Recordcount EQ 0
					OR isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true'>
				<!--- if I want to be thorough, I could set an end time that's 55 minutes after the start --->
				<cfquery name="InsertNewBooking" datasource="ReadWriteSource" dbtype="ODBC">
					INSERT INTO MakerspaceBookingTimes (RID, <cfif isDefined('form.userkey')>UserKey, </cfif><cfif isDefined('form.id')>UserBarcode, </cfif>
					StartTime, EndTime, Inserted, InsertedBy
					<cfif isDefined('form.firstname')>, FirstName</cfif>
					<cfif isDefined('form.lastname')>, LastName</cfif>
					<cfif isDefined('form.email') AND isValid("email", form.email)>, Email</cfif>
					<cfif isDefined('form.age') AND isNumeric(form.age)>, Age</cfif>)
					VALUES (
						'#form.rid#',
						<cfif isDefined('form.userkey')>#form.userkey#, </cfif>
						<cfif isDefined('form.id')>'#form.id#',</cfif>
						'#form.newstart#',
						'#form.newend#',
						GETDATE(),
						'#YouKnowIAm#'
						<cfif isDefined('form.firstname')>, '#form.firstname#'</cfif>
						<cfif isDefined('form.lastname')>, '#form.lastname#'</cfif>
						<cfif isDefined('form.email') AND isValid("email", form.email)>, '#form.email#'</cfif>
						<cfif isDefined('form.age') AND isNumeric(form.age)>, '#form.age#'</cfif>
					)
					SELECT SCOPE_IDENTITY() AS NewBookingID
				</cfquery>
				
				<cfset data.NEWBOOKING=StructNew()>
				<cfset data.NEWBOOKING.ID=InsertNewBooking.NewBookingID>
				<cfset data.NEWBOOKING.RID=form.rid>
				<cfset data.NEWBOOKING.START=form.newstart>
				<cfset data.NEWBOOKING.END=form.newend>
				<cfset data.NEWBOOKING.CARD=form.id>
				<!--- Turn off REQUIRECONFIRM to make the success message green, even after deleting a conflict --->
				<cfif isDefined('form.CONFIRMDELETE') AND form.CONFIRMDELETE IS 'true'><cfset data.REQUIRECONFIRM=false /></cfif>
				<cfset data.MSG&='<b>'&ResourceInfo.ResourceName&"</b> booked<br />for <b> "&TimeFormat(newstart, "h:nn tt") />
				<cfif DateCompare(newStart, now(), 'd') EQ 0>
					<cfset data.MSG&=' today' />
				<cfelse>
					<cfset data.MSG&=DateFormat(newstart, " EEE, mmmm d") />
				</cfif>
				<cfset data.MSG&='.' />
				<cfif form.id EQ '21221012345678'>
					<cfset data.MSG&="<br /><br /><b>This booking requires a note.</b>" />
				</cfif>

			</cfif><!---Either no extra bookings or confirmation--->
		<cfelse>
			<cfset data.ERROR=true>
			<cfset data.ERRORMSG="Invalid library card number.">
		</cfif><!--- if ID is 14 digits --->
	</cfif><!--- if form.id is defined --->	
	<cfoutput>#SerializeJSON(data)#</cfoutput>
</cfif><!---if form start defined--->
