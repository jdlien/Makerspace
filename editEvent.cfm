<cfsetting showdebugoutput="false" />

<cffunction name="timePicker" returnType="void">
	<!--- Prefix gives a prefix to the ID --->
	<cfargument name="prefix" required="yes">
	<!--- Accepts time in 24:00 format --->
	<cfargument name="time" required="no" />
	<cfset thisHour="9" />
	<cfset thisMinute="0" />
	<cfif isDefined('time')>
		<cfset thisHour=TimeFormat(time, "H") />
		<cfset thisMinute=TimeFormat(time, "m") />
	</cfif>
	<cfoutput>
	<select name="#prefix#Hour" id="#prefix#Hour" class="hour" style="width:40px;">
		<cfloop from="9" to="21" index="i">
			<option value="#i#" <cfif i IS thisHour>selected</cfif>><cfif i GT 12>#i-12#<cfelse>#i#</cfif></option>
		</cfloop>
	</select>:<select name="#prefix#Minute" id="#prefix#Minute" class="minute" style="width:50px;">
		<cfloop from="0" to="55" index="i" step="5">
			<option value="#i#" <cfif i IS thisMinute>selected</cfif>>#NumberFormat(i, "09")#</option>
		</cfloop>
	</select> <span id="#prefix#Meridiem" class="meridiem"><cfif thisHour GTE 12>PM<cfelse>AM</cfif></span>

	</cfoutput>
</cffunction>



<cfif isDefined('form.startHour') AND isDefined('form.endHour')>

<!--- <cfdump var="#form#"> --->

	<cfquery name="Event" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingTimes WHERE TID=#form.tid#
	</cfquery>

	<cfset EventDate = DateFormat(Event.StartTime, "YYYY-MM-DD") />

	<cfparam name="form.rid" default="#Event.RID#" />


	<cfset form.newStart=EventDate&" #form.StartHour#:#form.StartMinute#" />
	<cfset form.newEnd=EventDate&" #form.EndHour#:#form.EndMinute#" />


<!--- Only run this query if the booking passes validation. This is just a failsafe --->
	<cfinclude template="addBookingValidityCheck.cfm" />



	<cfquery name="EventUpdate"  dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.MakerspaceBookingTimes
		SET
		StartTime='#EventDate&" "&form.starthour&":"&form.startminute#',
		ENDTime='#EventDate&" "&form.endhour&":"&form.endminute#'
		<cfif isDefined('form.note') AND len(trim(form.note))>,Note='#PreserveSingleQuotes(form.note)#'</cfif>
		WHERE TID='#form.tid#'
	</cfquery>



<cfelseif isDefined('form.tid')>
	<cfquery name="Event"  dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingTimes WHERE TID='#form.tid#'
	</cfquery>
	<cfset EventDate = DateFormat(Event.StartTime, "YYYY-MM-DD") />

	<cfoutput><h3>Booking for #Event.FirstName# #Event.LastName#</h3></cfoutput>
	<form class="appForm" id="eventDetails" method="post">
		<cfoutput>
		
		<div class="formItem">Start Time
		<span class="formGroup">
			#timePicker("start", TimeFormat(Event.StartTime, "HH:mm"))#
		</span>
		</div>

		<div class="formItem">End Time
		<span class="formGroup">
			#timePicker("end", TimeFormat(Event.EndTime, "HH:mm"))#
		</span>
		</div>
	

		<label for="note">Note <input name="note" id="note" value="#Event.Note#" /></label>

		<label class="formSubmit">
			<input type="submit" value="Save Changes" id="submitBtn" disabled>
		</label>


		<label class="formSubmit" style="margin-top:10px;">
			<input class="delete" type="button" value="Delete Booking" id="delBtn" style="font-size:14px;">
		</label>

		<input name="tid" type="hidden" value="#form.tid#" />
		
		</cfoutput>
	</form><!--newNote-->

	<script type="text/javascript">
	var tid = <cfoutput>#form.tid#</cfoutput>;
	var rid = <cfoutput>#event.rid#</cfoutput>;

	$('#eventDetails').submit(function(e){
		e.preventDefault();
		$('#submitBtn').hide();

		//Don't submit the form normally... use Ajax. When done, update the ad's At: section.
		$.post('editEvent.cfm', $(this).serialize() ).done(function(data) {
			//update list of displayboard branches
			$('#calendar').fullCalendar('refetchEvents');
			//close the popover;
			closePopup();
		}); 
	});


	$('.hour').change(function(){
		var prefix = $(this).attr('id').replace('Hour', '');
		if ($(this).val() > 11) {
			$('#'+prefix+"Meridiem").html('PM');
		} else {
			$('#'+prefix+"Meridiem").html('AM');
		}
	});


	$('#delBtn').click(function(){
		// if (confirm('Delete this booking?')) {
			$.post('deleteBooking.cfm', {"id":tid});
			$('#calendar').fullCalendar('removeEvents', getEvents(tid));
			closePopup();
		// }		
	});

	// Ensure times are valid.
	$('.hour, .minute').change(function(){
		//Disable delete event button if the times change
		$('#delBtn').prop('disabled', true);

		var valid=true;
		// I think the easiest solution here is to construct an actual time and then compare them.
		// I'm not going to account for DST changes or other weirdness since that shouldn't affect us
		// Create a date with the event date, accounting for our time zone when it's not DST. The exact time will be adjusted anyways
		var today = new Date('<cfoutput>#EventDate# GMT-0700</cfoutput>');
		var startTime = new Date((today.getYear()+1900)+'-'+(today.getMonth()+1)+'-'+today.getDate()+' '+$('#startHour').val()+':'+$('#startMinute').val()+':00');
		var endTime = new Date((today.getYear()+1900)+'-'+(today.getMonth()+1)+'-'+today.getDate()+' '+$('#endHour').val()+':'+$('#endMinute').val()+':00');

		var tzOffset = startTime.getTimezoneOffset() * 60 * 1000;
		var isoStart = new Date(startTime-tzOffset).toISOString().slice(0, 19).replace('T', ' ');
		var isoEnd = new Date(endTime-tzOffset).toISOString().slice(0, 19).replace('T', ' ');
		//now we can do if (startTime < endTime) {}
		var timeDiff = (endTime - startTime)/1000/60;
		//If the timeDiff is less than 15 minutes, we won't allow that. So that's my first check.
		if (timeDiff < 15) {
			valid = false;
			$('#submitBtn').prop('disabled', true);
			toastr.error('End time must be at least 15 minutes after the start time.<br /><br />Ensure that your end time is not before the start time.');
		}

		//Next we have to check that our new time doesn't conflict with something else. Argh, these are in UTC!
		$.post('addBookingValidityCheck.cfm', {"tid":tid, "rid":rid, "newstart":isoStart, "newEnd":isoEnd}).done(function(data){
			var data = JSON.parse(data);
			console.log(data);
			if (data.ERROR == true) {
				valid=false;
				$('#submitBtn').prop('disabled', true);
				//Display a toast message
				toastr.error(data.ERRORMSG);
			} else {
				$('#submitBtn').prop('disabled', false);
			}
		});

	});

	$('#note').change(function(){
		//Disable delete event button if the note changes
		$('#delBtn').prop('disabled', true);
	});

	</script>

</cfif>