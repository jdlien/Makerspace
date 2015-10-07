<cfsetting showdebugoutput="false" />
<cfif isDefined('form.note')>
	<cfquery name="Event"  dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.MakerspaceBookingTimes
		SET Note='#PreserveSingleQuotes(form.note)#'
		WHERE TID='#form.tid#'
	</cfquery>
<cfelseif isDefined('form.tid')>
	<cfquery name="Event"  dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingTimes WHERE TID='#form.tid#'
	</cfquery>
	<form id="newNote" method="post" action="#listlast(cgi.script_name,"/")#">
	<div style="text-align:center;">
		<cfoutput>
		<h3>#Event.FirstName# #Event.LastName#</h3>
		<label for="note"><b>Note for #timeformat(Event.StartTime, "h:mm tt")# booking:</b> <input name="note" id="note" value="#Event.Note#" style="width:100%; display:block; margin:10px auto;" /></label>
		<input type="submit" name="save" value="Save" style="width:100px;" id="submitBtn" />
		<input name="tid" type="hidden" value="#form.tid#"
		</cfoutput>
	</div>
	</form><!--newNote-->

	<script type="text/javascript">

	$('#newNote').submit(function(e){
		e.preventDefault();
		$('#submitBtn').hide();

		//Don't submit the form normally... use Ajax. When done, update the ad's At: section.
		$.post('editNote.cfm', $(this).serialize() ).done(function(data) {
			//update list of displayboard branches
			$('#calendar').fullCalendar('refetchEvents');
			//close the popover;
			closePopup();
		}); 
	});



	</script>

</cfif>