<cfset app.toastr=true />
<cfset app.id="MakerspaceBooking">
<cfset app.title="Makerspace Booking System">
<!--- List structure of permissions, links, and descriptions for which to get admin links --->
<cfscript>
param ThisLocation=session.physicalLocation;
// Can be set to false for a customer-facing version in the future
isStaff=true;

if (isDefined('url.branch')) ThisLocation=url.branch;
if (ThisLocation=="External") ThisLocation='ESQ';
if (ThisLocation!="ESQ") app.addAdminButton('ESQ Branch', 'portal.cfm?branch=ESQ');
app.addAdminButton('Stats', 'stats.cfm');
app.addAdminButton('Resources', 'resources.cfm?branch='&ThisLocation, 'Manage Consoles, PCs, etc.', 'reso');
app.addAdminButton('Blocked Times', 'blockedTimes.cfm?branch='&ThisLocation, 'Manage Periods of Unavailability', 'block');
</cfscript>

<cfinclude template="#app.includes#/appsHeader.cfm">
<!--- Used for the current location of the user in Makerspace Booking System --->
<cfset MBSPath="#REReplace(cgi.script_name, "(.*)/.*", "\1")#" />

<!--- Add fullCalendar plugin for the calendar view. --->
<link rel='stylesheet' href='/Javascript/fullcalendar-3.10.0/fullcalendar.min.css' />
<script src='/Javascript/fullcalendar-3.10.0/fullcalendar.min.js'></script>	

<!--- 2020-Jun-10: Trying to upgrade this to FullCalendar 4.4.2 --->
<!---
<link href='/Javascript/fullcalendar-scheduler-4/packages/core/main.css' rel='stylesheet' />
<link href='/Javascript/fullcalendar-scheduler-4/packages/daygrid/main.css' rel='stylesheet' />
<script src='/Javascript/fullcalendar-scheduler-4/packages/core/main.js'></script>
<script src='/Javascript/fullcalendar-scheduler-4/packages/interaction/main.js'></script>
<script src='/Javascript/fullcalendar-scheduler-4/packages/daygrid/main.js'></script>
<script src='/Javascript/fullcalendar-scheduler-4/packages-premium/resource-common/main.js'></script>
<script src='/Javascript/fullcalendar-scheduler-4/packages-premium/resource-daygrid/main.js'></script>
 --->

<!--- Inputmask is used on card number input --->
<script src='/Javascript/jquery.inputmask.bundle.min.js' type="text/javascript"></script>
<!--- Stylesheet is now external --->
<link rel="stylesheet" type="text/css" href="makerspace.css" />


<cfquery name="ResourceList" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerspaceBookingResources r
	JOIN Vsd.vsd.MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID
	WHERE t.OfficeCode='#ThisLocation#'
	ORDER BY r.TypeID
</cfquery>

<cfquery name="BlockedResources" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM MakerspaceBookingResources r
	JOIN Vsd.vsd.MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID
	WHERE t.OfficeCode='#ThisLocation#'
	AND (r.AllowBlocked !=1 OR r.AllowBlocked IS NULL)
</cfquery>

<cfquery name="ResourceTypeCols" datasource="SecureSource" dbtype="ODBC">
	SELECT COUNT(TypeID) AS Columns, TypeID, 
	(SELECT TOP 1 RID FROM MakerSpaceBookingResources ri
	WHERE ri.TypeID=ro.TypeID) AS FirstRID
	FROM MakerspaceBookingResources ro GROUP BY TypeID
</cfquery>

<cfquery name="TypeList" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
	WHERE OfficeCode='#ThisLocation#'
	ORDER BY TypeID
</cfquery>

<cfquery name="PriorUsers" dbtype="ODBC" datasource="SecureSource">
	SELECT DISTINCT UserBarCode, FirstName, LastName, 1 AS CustSort FROM MakerspaceBookingTimes
	WHERE UserBarCode='21221012345678'
	UNION
	SELECT DISTINCT UserBarCode, FirstName, LastName, 2 AS CustSort FROM MakerspaceBookingTimes b
	JOIN MakerspaceBookingResources r ON r.RID=b.RID
	JOIN MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID	
	WHERE UserBarCode!='21221012345678'
	AND t.OfficeCode='#ThisLocation#'
	AND EndTime > DATEADD(day,-60,GETDATE())
	Order By CustSort, FirstName, LastName
</cfquery>

<div id="userSelection">
	<form name="userSelectionForm" id="userSelectionForm" action="patronlookup.cfm">
	<input type="hidden" name="userkey" id="userkey" value="" />
	<cfif isStaff>
		<div style="float:left;margin-right:20px;">
			<label class="" for="prevUsers">Prior users: </label>
			<select name="prevUsers" id="prevUsers" class="chzn-select-deselect" data-placeholder="Select a customer">
				<option value=""></option>
				<cfoutput query="PriorUsers">
					<option value="#UserBarCode#">#REReplace(UserBarcode, "(\d{5})(\d{5})(\d{4})", "\1 \2 \3")# - #FirstName# #LastName#</option>
				</cfoutput>
			</select>
		</div>
	</cfif><!---isStaff--->
		<div style="float:left;">
			<label class="" for="id">Card #: </label><input type="text" name="id" id="id" style="width:135px;" /><input type="submit" id="userSelectionSubmit" value="Check" style="display:none;">
		</div>
		<input type="submit" value="&#8629;" style="padding-left:0;padding-right:0;" />
		<span id="onlyShow" class="hidden"><label for="hideOtherBookings" style="margin-left:12px;margin-right:2px;">Highlight:</label><input type="checkbox" id="hideOtherBookings" name="hideOtherBookings" style="vertical-align:middle;"/><label id="highlightHelp" for="hideOtherBookings" style="margin-left:2px;" class="helpIcon"></label></span>
		
		<span id="altCard" class=""><label for="alternateCardCheckbox" style="margin-left:12px;margin-right:2px;">Other Card:</label><input type="checkbox" id="alternateCardCheckbox" name="alternateCardCheckbox" style="vertical-align:middle;"/><label id="altCardHelp" for="alternateCardCheckbox" style="margin-left:2px;" class="helpIcon"></label></span>
		

	<span id="errorid" class="error" style="display:none;">&nbsp;Enter a card number</span>
		<!--- I just use this to check that the card is validated. (I check again on the server side when inserting) --->
		<input type="hidden" name="validatedCard" id="validatedCard" value="false" />
	</form>
	<!---user Information or errors will be displayed here --->
	<div id="userStatus"></div>	
</div><!--userSelection-->

<input type="hidden" id="rid" name="rid" />
<!--- Can set default values for displayed type here --->


<cfquery name="DefaultTypes" dbtype="ODBC" datasource="SecureSource">
SELECT * FROM MakerspaceBookingResourceTypes WHERE ShowByDefault=1 AND OfficeCode='#ThisLocation#'
</cfquery>
<input type="hidden" id="typeID" name="typeID"
	value="<cfoutput query="DefaultTypes"><cfif currentRow NEQ 1>,</cfif>#TypeID#</cfoutput>" />
<span id="errorrid" class="error hidden" style="float:right;text-align:right;clear:right;margin-right:40px;">You must select a resource before booking a time.</span>

<div style="clear:both;margin-top:8px;"></div>

<!---fullCalendar displays here--->
<div id="calendar"></div>

<script language="Javascript">
//Makerspace Booking System path (not needed, usually this is the current directory)
<cfoutput>
var thisLocation='#thisLocation#', isStaff=#isStaff#, MBSPath='#REReplace(cgi.script_name, "(.*)/.*", "\1")#/';
</cfoutput>
var userData = new Object();

/* OpenTip Style for Events */
Opentip.styles.eventInfo = {
  background: "rgba(252, 255, 176, 0.9)",
  borderColor: "rgba(247, 235, 150, 0.7)",
  target: true,
  stem: true,
  fixed:true,
  tipJoint: "top"
};

Opentip.styles.clickInfo = {
  background: "rgba(252, 255, 176, 0.9)",
  borderColor: "rgba(247, 235, 150, 0.7)",
  target: true,
  stem: true,
  fixed:true,
  showOn: "click",
  hideOn: "click",
  tipJoint: "top"
};
				
/* attach a submit handler to the login form */
$(document).on('submit', '#userSelectionForm', function(event) {
	/* stop form from submitting normally */
	event.preventDefault();
	$('#errorid').hide();
	var cardNumber = $.trim($('#id').val());
	var cardNumberNoSpaces = cardNumber.replace(/\s/g, '');
	/* This ensures the dropdown gets updated properly when manually entering a number */
	$('#prevUsers').val(cardNumberNoSpaces);
	$('#prevUsers').trigger("chosen:updated");
	
	//If cardnumber isn't blank, submit it to patronlookup.cfm
	if (cardNumber.length) {
		$.post($('#userSelectionForm').attr('action'), $('#userSelectionForm').serialize()).done(function(data){
			userData = data;
			// console.log(data);
			$("#userStatus").html('');
			//Display our errors, if any
			if (typeof data.ERROR === 'object') {
				for(key in data.ERROR) {
				$("#userStatus").append('<span class="error">'+data.ERROR[key]+'</span><br />');
				}
				$('#validatedCard').val('false');
			} else {//else no errors from data
				$('#validatedCard').val('true');
				$('#userkey').val(data.CUSTOMER.USERKEY);
				if (data.CUSTOMER.STATUS == 'BLOCKED') {
					$("#userStatus").append('<span class="blockWarn"><b>'+data.CUSTOMER.FULLNAME+'</b> is BLOCKED.<cfif BlockedResources.RecordCount><br />These may not booked: </cfif><cfoutput query="BlockedResources"><cfif CurrentRow NEQ 1>, </cfif>#ResourceName#</cfoutput></span>');
				}else {
					$("#userStatus").append('<span class="success"><b>'+data.CUSTOMER.FULLNAME+'</b> is valid.</span>&nbsp; Click a time to book it.');
				}
				$('#altCard').hide();
				$('#onlyShow').show();
				
				// Append Certification Information
				var certPopupText = ""
					certPopupText += '<div class="masterCourse">Fab Lab Safety: ';
				if (data.MASTERCOURSE) {
					certPopupText += '<span class="success">Yes</span>';
				} else {
					certPopupText += '<span class="error">No</span>';
				}
				certPopupText +='</div>';
				certPopupText += '<table class="certifications"><caption>Certifications</caption>';
				$.each(data.CERTIFICATIONS, function(key, certInfo) {
					var allowed = '<span class="error">No</span>';
					if (certInfo.CustomerAllowed) allowed = '<span class="success">Yes</span>';
					certPopupText += '<tr><td>'+certInfo.CertiName+'</td><td>'+allowed+'</td></tr>';
				});
				certPopupText += '</table>';

				$("#userStatus").append('&nbsp;<a id="patronCertsPopup" href="javascript:void(0);">Certifications <span class="helpIcon"></span></a>');
				$('#patronCertsPopup').opentip(certPopupText, {style:'clickInfo'});

			}
		});
	}//if cardnumber is 14 characters
	//Else just blank out the userstatus area
	else {$('#userStatus').html('');}
});//on submit userSelectionForm



<!--- Creates variables for the row indicies
(not necessarily the resource ID, as resources can be added/deleted--->
var Resources= new Array();
<!--- formerly an array with RID as index, ResName as the value.
Now if you want the name, you need the object property name
<cfoutput query="resourceList">
	Resources[#RID#]="#ResourceName#";
</cfoutput>
--->

<cfoutput query="resourceList">
	Resources[#RID#]= {
		name:"#ResourceName#",
		offset:#CurrentRow#,
		typeID:#TypeID#,
		color:"#Color#"
	};
</cfoutput>

//I may have to redo this with pure JS as well.
<cfoutput query="ResourceTypeCols">
var type#TypeID#Col = {columns:#Columns#, firstRID:#firstRID#};
//console.log(TypeCol#TypeID#);
</cfoutput>

$('#id').focus(function(){
	$(this).val('');
	// delete data;
	delete userData;
	//This probably needs to be userData
	$('#userStatus').html('');
	$('#prevUsers').val('');
	$('#prevUsers').trigger("chosen:updated");
	$('#onlyShow').hide();
	$('#altCard').show();
	//$('#prevUsers').change();
});

function strTimeToMinutes(str_time) {
  var arr_time = str_time.split(":");
  var hour = parseInt(arr_time[0]);
  var minutes = parseInt(arr_time[1]);
  return((hour * 60) + minutes);
}		

/* Show a line indicating the current time */	
function setTimeline(view, element) {
	var parentDiv = jQuery(".fc-time-grid>.fc-bg");
	var timeline = parentDiv.children(".timeline");
	if (timeline.length == 0) { //if timeline isn't there, add it
		timeline = jQuery('<div class="timeline"><hr /></div>').addClass("timeline");
		parentDiv.prepend(timeline);
		$('.timeline2').remove();
		timeline2 = jQuery('<hr />').addClass("timeline2");
		$('.fc-time-grid-container').prepend(timeline2);
	}

	var curTime = moment();
	curTimeUTC=curTime.clone().add(-6,'h');
	if (view.start <= curTimeUTC && view.end >= curTimeUTC) {
		timeline.show();
		timeline2.show();
	} else {
		timeline.hide();
		timeline2.hide();
		return;
	}

	/*var curSeconds = (curTime.hours() * 60 * 60) + (curTime.minutes() * 60) + curTime.seconds();
	var percentOfDay = curSeconds / 86400; //24 * 60 * 60 = 86400, # of seconds in a day*/
	var minTimeInMinutes = strTimeToMinutes(view.opt("minTime"));
	var maxTimeInMinutes = strTimeToMinutes(view.opt("maxTime"));

	var curSeconds = (( ((curTime.hours() * 60) + curTime.minutes()) - minTimeInMinutes) * 60) + curTime.seconds();             
	var percentOfDay = curSeconds / ((maxTimeInMinutes - minTimeInMinutes) * 60);			
	//console.log(percentOfDay);
	//Invert percentage of day for bottom-up approach
	percentOfDay=1-(percentOfDay);
	//console.log(percentOfDay);
	var topLoc = Math.floor(parentDiv.height() * percentOfDay);

	timeline.css("bottom", topLoc + "px");
	timeline2.css("bottom", topLoc + "px");
	
	if (view.name == "agendaWeek") { //week view, don't want the timeline to go the whole way across
		var dayCol = jQuery(".fc-today:visible");
		var left = dayCol.position().left + 1;
		var width = dayCol.width()-2;
		timeline.css({
			left: left + "px",
			width: width + "px"
		});
		timeline2.css({
			left: left + "px",
			width: width + "px"
		});		
	}

}//end setTimeline()



function addDayResourceColumns() {
	// $('.DayResourceColumn').remove();
	$('.typeCols').remove();
	$('.resCols').remove();
	$('.fc-event-container:not(".fc-helper-container")').append('<div class="typeCols"></div>');
	$('.fc-event-container:not(".fc-helper-container")').append('<div class="resCols"></div>');


	//Redo this as a loop of our Resources[] array. Only include columns for resources in types in the typeid hidden field
	var i, types, count=0;
	//will use the array of types passed to this function as arguments
	//If no arguments were passed, default to the typeID hidden form field
	if (arguments.length == 0) {
		if ($('#typeID').val().length > 0) {
			var arguments=$('#typeID').val().split(',');
		} else {
		//If the field is blank, we want arguments to be all types.
		var arguments=[<cfoutput query="TypeList"><cfif CurrentRow GT 1>,</cfif>#TypeID#</cfoutput>];
		}
	}

	//loop through all types passed as arguments
	for(i=0; i<arguments.length;i++) {
		
		// Create columns for types that are used as blocked times
		//sub loop through all resources to look for matches. Increment counter if found.
		for( var j=0; j < Resources.length; j++) {
			if (typeof Resources[j] === "object") {
				if (Resources[j].typeID == arguments[i]) {
					var typeid = Resources[j].typeID;
					if ($('#DayTypeColumn'+typeid).length > 0) {
						// If the type already exists, increment the flex: value by one
						var theFlex = $('#DayTypeColumn'+typeid).css('flex-grow');
						theFlex=parseInt(theFlex)+1;
						$('#DayTypeColumn'+typeid).css('flex-grow', theFlex);

					} else {
						// else create the new column
						$('.typeCols').append('<div id="DayTypeColumn'+typeid+'" class="DayTypeColumn" style="flex-grow:1;"></div>')
					}
					// Add invisible columns into fc-event-container. Note that there is also a fc-helper-container with this class
					// I only want to to do this if the column needs to be here at all...
					$('.resCols').append('<div id="DayResourceColumn'+j+'" class="DayResourceColumn"></div>');
				}
			}
		}
	}

	
}//end addDayResourceColumns()


function labelColumns() {
	//Clear the header in day view
	$('.fc-day-header.fc-widget-header:first').html('').css('padding-left','2px');
	
	//Redo this as a loop of our Resources[] array. Only include columns for resources in types in the typeid hidden field
	var i, types, count=0;
	//will use the array of types passed to this function as arguments
	//If no arguments were passed, default to the typeID hidden form field
	if (arguments.length == 0) {
		if ($('#typeID').val().length > 0) {
			var arguments=$('#typeID').val().split(',');
		} else {
		//If the field is blank, we want arguments to be all types.
		var arguments=[<cfoutput query="TypeList"><cfif CurrentRow GT 1>,</cfif>#TypeID#</cfoutput>];
		}
	}

	//loop through all types passed as arguments
	for(i=0; i<arguments.length;i++) {
		//sub loop through all resources to look for matches. Increment counter if found.
		for( var j=0; j < Resources.length; j++) {
			if (typeof Resources[j] === "object") {
				if (Resources[j].typeID == arguments[i]) {
					$('.fc-day-header.fc-widget-header').append('<a href="javascript:void(0);" id="DayResourceLabel'+j+'" class="DayResourceLabel" style="background-color:'+Resources[j].color+';border-color:'+Resources[j].color+';">'+Resources[j].name+'</a>');
				}
			}
		}
	}

	$(".DayResourceLabel").on('click', function(){
		var rid=this.id.replace("DayResourceLabel", "");
		//console.log(rid);
		$('#rid').val(rid);
		//$('#rid').trigger("chosen:updated");
		$('#rid').change();
	});	
	
}//end labelColumns

//Use this to look for class names when rendering events. Returns index of array
function searchStringInArray(str, strArray) {
    for (var j=0; j<strArray.length; j++) {
        if (strArray[j].match(str)) return j;
    }
    return -1;
}

var today=new Date();
function maskId() {
   $("#id").inputmask("mask", {
		"mask": "21221 99999 9999",
		"oncomplete": function(){
			$('#errorid').hide();
			$('#userSelectionSubmit').removeAttr('disabled');
			$('#userSelectionForm').submit();
		},			
		"onincomplete": function(){
			var cleanNumber=$('#id').val().replace(/\s/g, '');
			//$('#errorid').show(200);
			$('#userSelectionSubmit').attr('disabled', 'disabled');
		}

	});
}

function unmaskId() {
	$("#id").inputmask('remove');
}

$(document).ready(function(){

	$('#highlightHelp').opentip("Make it easy to see this customer's bookings.", {style:'eventInfo'});
	$('#altCardHelp').opentip("Allow entry of any kind of card number.<br />Press ENTER&#8629; to submit.", {style:'eventInfo'});
	$clearResourceButton='<a href="javascript:void(0);" class="clearResourceButton" title="Show all Resources"><svg width="100%" height="100%"><g id="closeBtn"><circle cx="50%" cy="50%" r="50%" stroke="black" stroke-width="0"></circle><line x1="25%" y1="25%" x2="75%" y2="75%"></line><line x1="25%" y1="75%" x2="75%" y2="25%"></line></g></svg></a>';

	$resourceSel='<div id="resourceSelection"><select name="ridDD" id="ridDD" data-placeholder="Choose a resource"><option value=""></option><cfoutput query="ResourceList"><option value="#RID#">#JSStringFormat(ResourceName)#</option></cfoutput></select>'+$clearResourceButton+'</div>';

	//New checkbox version
	$typeSel='<div id="typeSelection"><label for="checkAll" class="typeCheckLabel bold">All<input type="checkbox" name="all" id="checkAll" /></label>';
	$typeSel+='<cfoutput query="TypeList"><label for="checkType#TypeID#" class="typeCheckLabel">#TypeName#<input type="checkbox" id="checkType#TypeID#" name="checkType#TypeID#" class="checkType" /></label></cfoutput></div>';
	
	
	$('#id').keydown(function(e){
		e = e || window.event;
		if (e.keyCode == 13) {
			$('#userSelectionForm').submit();
			return false;
		}
	});

	//Adds the input mask defined above.
	maskId();
	
	$('#alternateCardCheckbox').on('change', function() {
		if ($('#alternateCardCheckbox').prop('checked')) {unmaskId();}
		else {maskId();}
	});
	
	var first=true;
	$('#calendar').fullCalendar({
		header: {left:'prev,today,next', center:'title', right:'agendaDay,agendaWeek'},
		//titleFormat: {month:'MMMM YYYY', week: "MMMM D YYYY", day: 'dddd MMMM Do YYYY'},
		views: {
			month: {
				titleFormat: 'MMMM YYYY'
			},
			week: {
				titleFormat: 'MMMM D YYYY',
				columnFormat: 'dddd MMM D'
			},
			day: {
				titleFormat: 'dddd MMMM Do YYYY',
				columnFormat: ''
			},
			agenda: {
				timeFormat: 'h:mm t'
			}
		},
		<cfif isDefined('url.date') AND isDate(url.date)>defaultDate:'<cfoutput>#DateFormat(url.date, 'YYYY-MM-DD')#</cfoutput>',</cfif>
		//columnFormat: {week: 'dddd MMM D', day: ''},
		contentHeight:"auto",
		defaultView:'agendaDay',
		//timeFormat: {agenda:'h:mm t'},
		slotDuration:'01:00:00',
		minTime: '09:00:00',
		maxTime: '21:00:00',
		allDaySlot:false,
		firstDay:today.getDay(),
		selectable:true, //I don't want the dragging to work, though
		selectHelper:false,
		eventDurationEditable:false,
		defaultTimedEventDuration: '00:54:00',
		eventAfterRender: function(event, element, view) {
			//console.log('afterRender');
			// Add an id based on the event### class. There might be a much better way to do this.
			var anEvent = $(".event"+event.tid);
			anEvent.attr('id', 'event'+event.tid);

			//Renders HTML in the event title (ie for notes image)
			element.find('.fc-title').prepend(event.noteIcon);
			//Here, if the view is day, I adjust the positioning to make columns
			//There will be a number of columns. Basically I need to figure out which column index each event goes into.
			//I need to fix this to position the bookings/blocked times correctly with the selected types
			if (view.name=="agendaDay" && $('#rid').val()=='') {
				//if this is a resType, we make it wider as per our restype#col object
				//Use the same left offset as the FirstRID RID
				//console.log(event.description);
				//console.log(event.className);
				var typeClassIdx = searchStringInArray('type', event.className);
				//If this event is for a whole type
				if (typeClassIdx >= 0) {
					//console.log(eval(event.className[typeClassIdx]+"Col"));
					numCols=eval(event.className[typeClassIdx]+"Col").columns;
					var thisClass = event.className[typeClassIdx];
					var thisType = thisClass.replace(/type/i, "");
					// console.log(thisClass);
					var anEvent = $(".blockedTime."+thisClass);
					// console.log('relocating .blockedTime.'+thisClass+' to #DayTypeColumn'+thisType);
					anEvent.detach();
					$('#DayTypeColumn'+thisType).append(anEvent);
					//new offset value comes from the Resources[x] object.
					//Use first RID for the type, get offset from Resources array.
					var offset=Resources[eval(event.className[typeClassIdx]+"Col").firstRID].offset;
				} else if (typeof event.className[1] != 'undefined' && event.className[1] != 'All') {
					//Instead of manipulating the width, move this event into the right column.

					//need to calculate an offset value based on the classname of a booking event
					//Figure out the RID for this event. Grep it? Remove the Res?
					var thisRID=event.className[1].replace(/Res/i, "");
					var anEvent = $(".resourcebooking.Res"+thisRID+", .blockedTime.Res"+thisRID);

					anEvent.detach();
					$('#DayResourceColumn'+thisRID).append(anEvent);


					var offset=Resources[thisRID].offset;
				}
				
				labelColumns();
				$('#resourceSelection').remove();
			} else if (view.name=="agendaWeek" && $('#resourceSelection').length==0) {
				$('#typeSelection').remove();
				$('.fc-right:first').prepend($resourceSel);
				$('#ridDD').chosen();
				if($('#ridDD').val()=='') {
					$($('#ridDD')).css('color', '#999999');
					$($('#ridDD option')).css('color', 'black');
					$($('#ridDD option:checked')).css('color', '#999999');
				} else $('#ridDD').css('color', 'black');
				$('#ridDD').on('change', function() {
					if ($('#ridDD').val() != '') {$('#ridDD').css('color', 'black');}
					else $('#ridDD').css('color', '#999999');
					handleRID($('#ridDD').val());
				});
				$('.clearResourceButton').on('click', function(){
					$('#ridDD').val('');
					$('#ridDD').change();
					$('#ridDD').trigger("chosen:updated");
				});
				
				//Bind event handler for dropdown
				
			}
			element.opentip(event.description, {style:'eventInfo'});
		},
		viewRender: function(view, element) {

			<!--- This must not be the only way to disable this functionality. Server-side check required --->
			<cfif permissions.delete eq 1>
			// This is the replacement for eventClick handling build into fullCalendar. I have to create my own event handler
			// because of how I moved the "event" elements into my own structure for formatting.
			$('.fc-event-container').on('click', '.resourcebooking', function(){
				
				//Remove any existing delete buttons from other events
				$('.eventEditButton').remove();
				// $('.eventNoteButton').remove();
				//this would be cleaner if I could use the id
				var tid = $(this).attr('id').replace('event', '');
				var title = $(this).find('.fc-title').html();
				// console.log(title);
				var $editButton='<a class="eventEditButton" href="javascript:void(0)" onclick="editEvent(\''+tid+'\');"><img src="/Resources/Images/gear.svg" /></a>';
				// var $noteButton='<a class="eventNoteButton" href="javascript:void(0)" title="Add/Edit Note" onclick="createNote(\''+tid+'\',\''+title+'\');"><img src="/Resources/Images/editPencilCircle_64.png" /></a>';
				 $(this).append($editButton).children('.eventEditButton').hide().fadeIn(100);
				// $(this).append($noteButton).children('.eventNoteButton').hide().fadeIn(100);


			});
			</cfif>

			var bDate = $('#calendar').fullCalendar('getDate');
			// Now I have the date. Update URL with this date if it's not today
			<cfoutput>
			if (moment(today).format('L') != bDate.format('L')) {
				//Add the date to the URL
				window.history.pushState("", "Apps: Makerspace Booking System", "?<cfif isDefined('url.branch')>branch=#url.branch#&</cfif>date="+bDate.format('L'));
			} else {
				window.history.pushState("", "Apps: Makerspace Booking System", "?<cfif isDefined('url.branch')>branch=#url.branch#</cfif>");
			}
			</cfoutput>
			
			// Show the header row when viewing all resources in day view
			if (view.name=="agendaDay" && $('#rid').val()=='') {
				labelColumns();
				// This isn't enough - it doesn't update when you change the categories.
				addDayResourceColumns();

				//Second attempt to render type labels. (Perhaps this should be a function since I'm now doing this twice... or remove the first instance)

				//Include checkboxes to choose the resource types shown
				if ($('#typeSelection').length==0) {
					$('.fc-right:first').prepend($typeSel);
					var typeArray=$('#typeID').val().split(',');
					//Set checkboxes based on initial value of #typeID
					for( var i=0; i < typeArray.length; i++) {
						//check checkbox with for this resource
						$('#checkType'+typeArray[i]).prop('checked', true);
					}
					//$('#typeDD').val(typeArray);
					//If All is checked, check all the checkboxes.
					$('#checkAll').change(function() {
						if($('#checkAll').prop('checked')) {
							$('.checkType').prop('checked', true);
							$('#typeID').val('');
							handleTypeID();
							addDayResourceColumns();
						} else $('#checkAll').prop('checked', true)
					});
					$('.checkType').change(function() {
						//Returns an array of checkbox type values
						var checkedTypes=$('.checkType').map(function() {
							if ($(this).prop('checked')) {
								var thisID=$(this).attr('id');
								return thisID.replace(/checkType/i, "");
							}
						}).get();
						//If none are checked, check all.
						//Else, uncheck all
						if (checkedTypes.length) $('#checkAll').prop('checked', false);
						else $('#checkAll').prop('checked', true);

						$('#typeID').val(checkedTypes);
						handleTypeID(checkedTypes);
						addDayResourceColumns();
					});

				}//if #typeSelection.length==0

			}
		
			// Draw time line for current time every three minutes.
			if (first) {
				first = false;
			} else {
				window.clearInterval(timelineInterval);
			}
			// Update the time line every 3 minutes
			timelineInterval=setInterval(function(){try{setTimeline(view, element)}catch(err){}}, 180000);
			try {
				setTimeline(view, element);
			} catch(err) {}
		}, //End viewRender
		dayClick: function(date, jsEvent, view){doDayClick(date, jsEvent, view)},
		<!---
		<cfif permissions.delete eq 1><!--- This must not be the only way to disable this functionality. Server-side check required --->
		eventClick: function(calEvent, jsEvent, view) {
			// Add the delete button if it doesn't already exist
			if (typeof calEvent.tid == 'string' && $(this).children('.eventEditButton').length == 0) {
				//Remove any existing delete buttons
				$('.eventEditButton').remove();
				$('.eventNoteButton').remove();
				var $editButton='<a class="eventEditButton" href="javascript:void(0)" onclick="editEvent(\''+calEvent.tid+'\',\''+calEvent.title+'\');"><img src="/Resources/Images/gear.svg" /></a>';
				var $noteButton='<a class="eventNoteButton" href="javascript:void(0)" title="Add/Edit Note" onclick="createNote(\''+calEvent.tid+'\',\''+calEvent.title+'\');"><img src="/Resources/Images/editPencilCircle_64.png" /></a>';
				$(this).append($editButton).children('.eventEditButton').hide().fadeIn(100);
				$(this).append($noteButton).children('.eventNoteButton').hide().fadeIn(100);
			}
		},
		</cfif> --->
		eventSources: [
			{
				url: MBSPath+'getBookings.cfm?branch='+thisLocation,
				type: 'POST',
				data: {
					isStaff: isStaff,
					id:$('#id').val(),
					rid:$('#rid').val(),  //This won't update dynamically. Have to reset event sources onchange.
					typeID:$('#typeID').val(),
					hideOther:$('#hideOtherBookings').prop('checked')
				}
			},
			{
				url: MBSPath+'getBlockedTimes.cfm?branch='+thisLocation,
				type: 'POST',
				data: {	rid:$('#rid').val(),typeID:$('#typeID').val()}					
			}
		]//end of eventSources
		
		
	});//fullCalendar



	/* I can use this for the card number validation as well */
	function handleRID(newRID) {
		$('#errorrid').hide();
		//copy value from the dropdown into the rid hidden field
		if (typeof newRID !='undefined') {
			$('#rid').val(newRID);
			if (newRID == '') $('.clearResourceButton').css('visibility', 'hidden');
			else $('.clearResourceButton').css('visibility', 'visible');
		}
		updateFullCalendar();
	}
	

	//This should be invoked if the value of .rid changes - not sure if this will work yet
	$('#rid').on('change', function(){
		handleRID();
	});

	/* This is to change the types shown on the full day view */
	function handleTypeID(newTypeID) {
		$('#errorrid').hide();
		//copy value from the dropdown into the typeID hidden field
		if (typeof newTypeID !='undefined') {
			$('#typeID').val(newTypeID);
		}
		updateFullCalendar();
	}

	$('#typeID').on('change', function(){
		handleTypeID();
	});	
	
	/* Toggle showing only this user's bookings - note that this will allow them to book other time slots... */
	$('#hideOtherBookings').on('change', function(){
		$('#errorrid').hide();
		updateFullCalendar();

	});
	
});//document.ready


// Check if this data needs to be updated every 5 seconds. If so, update.
var updateSeq = 0;

//Simply updates the 'updateSeq' variable to the current value to prevent a useless update.
function setUpdateSequence() {
	$.get('updateCheck.cfm?branch='+thisLocation).done(function(data){
			updateSeq = data;
	});
}	

//Set the initial update sequence, otherwise a useless update is done shortly after page load.
setUpdateSequence();

setInterval(function() {
	$.get('updateCheck.cfm?branch='+thisLocation).done(function(data){
		// console.log(updateSeq);
		// console.log(data);
		if (parseInt(data) > parseInt(updateSeq)) {
			//We need to update
			updateSeq = data;
			//console.log('Changes detected. Updating...');
			updateFullCalendar();

		}
	});
}, 10000);



function updateFullCalendar() {

	/*Remove events and only show events for the newly selected resource */
	$('#calendar').fullCalendar('removeEvents');
	$('#calendar').fullCalendar('removeEventSource', 'getBookings.cfm?branch='+thisLocation);
	$('#calendar').fullCalendar('removeEventSource', 'getBlockedTimes.cfm?branch='+thisLocation);
	$('#calendar').fullCalendar('addEventSource', {
		url: 'getBookings.cfm?branch='+thisLocation,
		type: 'POST',
		data: {
			id:$('#id').val(),
			rid:$('#rid').val(),
			typeID:$('#typeID').val(),
			hideOther:$('#hideOtherBookings').prop('checked')
		}
	});
	$('#calendar').fullCalendar('addEventSource', {
		url: 'getBlockedTimes.cfm?branch='+thisLocation,
		type: 'POST',
		data: {rid:$('#rid').val(),typeID:$('#typeID').val()}
	});

	/* This should only be required in day view */
	if ($('#calendar').fullCalendar('getView').name=="agendaDay" && $('#rid').val() !='') {
		$('.fc-day-header.fc-widget-header').html(Resources[$('#rid').val()].name+$clearResourceButton);
		$('.clearResourceButton').css('visibility', 'visible');
		$('.clearResourceButton').on('click', function(){
			$('#rid').val('');
			//$('#rid').trigger("chosen:updated");
			$('#rid').change();
		});
	}
	else if ($('#calendar').fullCalendar('getView').name=="agendaDay" && $('#rid').val()=='') {
		labelColumns();
	}

	// Update the sequence number so we don't needlessly do another update
	setUpdateSequence();


}//end updateFullCalendar()


<cfif permissions.delete eq 1>

//This is supposed to return an event object with a particular TID, but it's not working :-/
function getEvents(thisTid){
    var events = new Array();      
    events = $('#calendar').fullCalendar('clientEvents');
    var filterevents = new Array();
    var theEventID;
    for(var j in events){ 
        if(events[j].tid == thisTid)
        {
            theEventID = events[j]._id;
        }
    }           
    return theEventID;
}


//Title doesn't do anything currently. I'm leaving it there for reverse compatibility
function editEvent(tid, title) {
	loadPopOverContent('editEvent.cfm', '425px',{'tid':tid});
	/*
	if (confirm('Delete '+title+'?')) {
		$.post('deleteBooking.cfm', {"id":tid});
		//console.log('RemoveEvents '+tid);
		$('#calendar').fullCalendar('removeEvents', getEvents(tid));
		//$('.event'+tid).fadeOut(200);
		//Can I remove the event from here?
	}
	*/
}
</cfif>

function createNote(tid) {
	//Show popup allowing display selection for this ad.
	loadPopOverContent('editNote.cfm', '300px',{'tid':tid});	

}




function doDayClick(date, jsEvent, view, confirmDelete) {
	/* Okay, I'm thinking that I can get the x offset here, so I need to compare that with
	the current position of the resource columns
	and based on that I can figure out which column was clicked.
	No extra elements required, no screwing with the height.
	*/
	//If in day view and no Resource selected, determine it through position of click
	if (view.name=="agendaDay" && $('#rid').val()=='') {
		// If for some reason jsEvent isn't defined, just return and do nothing.
		if (!jsEvent) {
			//console.log('No jsEvent');
			return;
		}

		//Firefox has a glitch that sometimes results in offsetX being zero, which is impossible.
		//The least it can be should be 1. If we see zero, we will use the values stored in this temp variable
		if (typeof jsEvent.offsetX !== 'undefined' && jsEvent.offsetX != 0) {
			window.tempOffsetX = jsEvent.offsetX;
		}

		//console.log(jsEvent.offsetX);
		if (jsEvent.offsetX == 0 && typeof window.tempOffsetX !== 'undefined') {
			//console.log(window.tempOffsetX);
			jsEvent.offsetX = window.tempOffsetX;
		}
		var rid=resourceColumn(jsEvent.offsetX);
		//console.log(resourceColumn(jsEvent.offsetX));
	}
	else {var rid=$('#rid').val();}
	
	if (confirmDelete != true){
		var confirmDelete=false;
		window.tempDate=date.clone();
	}
	/* If in month view, show the day view for the clicked date */
	if (date.format("HH") == 0) {
		$('#calendar').fullCalendar('gotoDate', date);
		$('#calendar').fullCalendar('changeView', 'agendaDay');
	} else { /* Else check and see if we should add a booking */
		var newEvent={id:'newBooking', title:'Your Booking', start:date.add(5,'minutes').format(), end:date.add(54,'minutes').format()};
		/* Check that everything is cool before booking the time slot. */
		//console.log('rid: '+rid);
		if (allowedToBook(newEvent, rid)) {
			$('#calendar').fullCalendar('removeEvents', 'newBooking');
			$.post('addBooking.cfm?branch='+thisLocation, {
				'userkey':$('#userkey').val(),
				'id':$('#id').val(),
				'rid':rid,
				'newstart':newEvent.start,
				'newend':newEvent.end,
				'status':userData.CUSTOMER.STATUS,
				'firstname':userData.CUSTOMER.FIRST,
				'lastname':userData.CUSTOMER.LAST,
				'email':userData.CUSTOMER.EMAIL,
				'age':userData.CUSTOMER.AGE,
				'confirmDelete':confirmDelete
			})
			.done(function(data){
				window.tempjsEvent=jsEvent;
				window.tempView=view;
				if (typeof data.NEWBOOKING != 'undefined' && data.NEWBOOKING.CARD == '21221012345678') {
					editEvent(data.NEWBOOKING.ID);
				}
				
				if (data.ERROR) {
					toastr.options.timeOut = 6000;
					toastr.error(data.ERRORMSG);
				}else if (data.CONFLICTINGBOOKINGS || data.REQUIRECONFIRM) {
					toastr.options.timeOut = 0;
					toastr.warning(data.MSG);
				}else {
					toastr.options.timeOut = 6000;
					toastr.success(data.MSG);
				}
				$('#calendar').fullCalendar('refetchEvents');
			});//end .done
		}//end if allowedToBook
	}//end if date hour == 0
}//end function doDayClick()


/* Determines which resource column has been clicked based on X position.*/
function resourceColumn(xPos) {
	var thisRid;
	//Loop through resource columns
	$.each($('.DayResourceColumn'), function() {
		var leftPos = $(this).position().left;
		var colWidth = $(this).width();
		if ( xPos >= leftPos && xPos <= leftPos+colWidth) {
			thisRid = $(this).attr('id').replace('DayResourceColumn', '');
		}
	});
	return thisRid;


}


/* Checks for overlapping events. We probably won't use this going forward but it had saved an ajax call. */
function isOverlapping(event, rid){
	var array = $('#calendar').fullCalendar('clientEvents');
	// JDL 2018-02-15
	// console.log(array);
	// console.log(event);
	for(i in array){
		// console.log(array[i].start);
		// console.log(array[i].end);
		// I don't get the point of this... array[i] doesn't have an id
		if(array[i].id != event.id){
			//careful that these are in the same format
			if(!(array[i].start.format() >= event.end || array[i].end.format() <= event.start) && array[i].rid==rid){
				return true;
			}
		}
	}
	return false;
}

/*Checks a bunch of rules to ensure we are allowed to book at this time
	-branch is open
	-not a holiday
	-not blocked off
	-etc?
*/
function allowedToBook(event, rid){
	// console.log('allowedToBook - rid: '+rid);
	if ($('#rid').val() !='') {rid=$('#rid').val()};
	if ( $('#id').val().length < 7 || $('#validatedCard').val() != 'true') {
		$('#errorid').show(200);
		toastr.error('You must enter a card number to book a resource.');
		return false;
	} else if (typeof rid == 'undefined' || rid=='') {
		$('#errorrid').show(200);
		toastr.error($('#errorrid').html());
		return false;
	}
	//Event can't start before now.
	//Okay now it can because Ben says so.
	/*
	else if (event.end < moment().format()) {
		// Show Popup errors when you click on a not allowed time
		toastr.error("You can't book a time that has already elapsed.");
		return false;
	}*/
	else if(event.end > moment().add(30,'day').format()) {
		toastr.error("You can't book a time more than 30 days from now.");
		return false;
	}
	return true;
}

$('#prevUsers').change(function() {
	$('#hideOtherBookings').prop('checked', false);
	$('#onlyShow').hide();
	$('#altCard').show();
	if ($('#prevUsers').val().length == 0) {
		//$('#userSelectionSubmit').prop("disabled", true);
		$('#id').removeAttr("readonly");
	} else $("#userSelectionSubmit").removeAttr( "disabled");
	//if card number does not start with 21221, check 'other card'
	if ( $('#prevUsers').val().length > 0 && $('#prevUsers').val().match(/^21221/g) === null ) {
		$('#alternateCardCheckbox').prop('checked', true);
		$('#alternateCardCheckbox').trigger('change');
	} else {
		$('#alternateCardCheckbox').prop('checked', false);
		$('#alternateCardCheckbox').trigger('change');
	}
	$('#id').val($('#prevUsers').val());
	//Inputmask already submits when the number is filled in.
	//Unfortunately selecting 21221 11111 1111 causes a weird glitch
	$("#userSelectionForm").submit();

	$('#errorrid').hide();

	updateFullCalendar();

});


</script>
<cfinclude template="#app.includes#/appsFooter.cfm">
