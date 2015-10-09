<cfset enableToastr=true>
<cfset RemoveSidebar="yes">
<cfset PermissionsMaxApplication="MakerspaceBooking">
<cfset pagetitle="Makerspace Booking System">
<cfset enableFullCalendar24="yes">


<!--- List structure of permissions, links, and descriptions for which to get admin links --->
<cfset adminButtons = ArrayNew(1)>
<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="resources.cfm">
<cfset adminButton.label="Resources">
<cfset adminButton.title="Manage Consoles, PCs, etc.">
<cfset ArrayAppend(adminButtons, adminButton)>	

<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="blockedtimes.cfm">
<cfset adminButton.label="Blocked Times">
<cfset adminButton.title="Manage Periods of Unavailability">
<cfset ArrayAppend(adminButtons, adminButton)>	

<cfinclude template="/AppsRoot/Includes/IntraHeader.cfm">
<!--- Used for the current location of the user in Makerspace Booking System --->
<cfset MBSPath="/dev/Makerspace" />
<cfset ThisLocation=RealStateBuilding/>
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
</cfif>


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

<!--- This variable determines what information and control is given to the user --->
<cfset isStaff=true>

<script src='/Javascript/jquery.inputmask.bundle.min.js' type="text/javascript"></script>

<style type="text/css">

	.fc-widget-content {
		height:40px !important;
		/*Overrides .fc-time-grid .fc-slats td { height: 1.5em*/
	}


	.fc-time-grid-container {
		/*height:none !important;*/
		overflow:hidden;
	}

	.fc-time-grid-event {
		/*overflow:visible !important;*/
	}

	.notice {
		text-align:center;
	}
	
	.typeCheckLabel {
		margin-left:10px;
		font-weight:normal;
	}

	.typeCheckLabel input {
		padding: 0;
		vertical-align: middle;
		position: relative;
		top: -1px;
		*overflow: hidden;
	}

	#userSelection label {
		font-weight:bold;
	}
	
	.bold {
		font-weight:bold;
	}
	

	label.spaced {
		width:200px;
		float:left;
		
	}
	
	.yourBooking .fc-event-title {
		font-weight:bold;
	}
	
	.resourcebooking {
		/*max-width:200px;*/
	}
	
	.warning {
		color:#990000;
	}
	
	.timeline {
		position: absolute;
		left: 50px;
		border: none;
		border-bottom: 0px solid red;
		background-image:url('/resources/images/alpha-black-20.png');
		height:2000px;
		width: 100%;
		margin: 0;
		padding: 0;
	}
	
	.timeline hr {
		width:100%;
		padding:0;
		margin:0;
		position:absolute;
		bottom:0px;
		border:0;
		border-bottom:1px dashed red;
		height:1px;
		color:red;
		z-index:99;
	}
	
	.timeline2 {
		width:100%;
		padding:0;
		margin:0;
		position:absolute;
		bottom:0px;
		border:0;
		border-bottom:1px dashed red;
		height:1px;
		color:red;
		z-index:99;
	}

	.grayButton {
		margin:3px 3px;
		margin-bottom:15px;
	}
	
	#userStatus {
		float:left;
		clear:left;
		min-height:25px;
	}
	
	.opentip {
		z-index:99;
	}

	.confirmQuestion {
		font-weight:bold;
		text-align:center;
		margin:0 auto;
		margin-top:16px;
	}

	.confirmDeletion a {
		display:block;
		color:black;
		-webkit-border-radius: 5px;
		-moz-border-radius: 5px;
		border-radius: 5px;
		margin:6px auto;
		text-align:center;
		width:90%;
		border-top: solid 1px #EEEEEE;
		border-right: solid 1px #BBBBBB;
		border-bottom: solid 1px #BBBBBB;
		border-left: solid 1px #EEEEEE;
		background-color:#DDDDDD;
	}
	
	.confirmDeletion a:hover {
		color:black;
		background-color:#EEEEEE;
	}

	
/*
	.confirmDeletion {
		color:black;
		-webkit-border-radius: 5px;
		-moz-border-radius: 5px;
		border-radius: 5px;
		margin:6px;
	}
	
	.cancelBooking {
		-webkit-border-radius: 5px;
		-moz-border-radius: 5px;
		border-radius: 5px;
		margin:6px;
	}
	
	.confirmDeletion:hover, .cancelBooking:hover {
		color: #222222;
		text-decoration: none;
		background-position: 0 -15px;
		-webkit-transition: background-position 0.1s linear;
		   -moz-transition: background-position 0.1s linear;
			 -o-transition: background-position 0.1s linear;
				transition: background-position 0.1s linear;
	}
*/	
	.blockWarn {
		color:#D88A00;
	}
	
	.DayResourceLabel {
		position:relative;
		z-index:4;
		float:left;
		margin:0 1px;
		border:1px solid #AAAAAA;
		-webkit-border-radius: 3px;
		-moz-border-radius: 3px;
		border-radius: 3px;
		overflow:hidden;
		white-space:nowrap;
		background-image:url('/resources/images/alpha-80.png');
		color:black;
	}
	
	.DayResourceLabel:hover {
		background-image:url('/resources/images/alpha-60.png');
		text-decoration:none;
	}	
	
	
	.clickableColumn {
		height:100%;
		position:absolute;
		border-left:1px solid #EEEEEE;
		border-right:1px solid #EEEEEE;
		margin:0 2px;
		z-index:3;
		-webkit-border-radius: 3px;
		-moz-border-radius: 3px;
		border-radius: 3px;		
	}
	
	.clearResourceButton {
		color:#999;
		font-weight:bold;
		width:18px;
		height:18px;
		visibility:hidden;
		display:inline-block;;
		text-align:center;
		font-size:17px;
		margin-right:6px;
		margin-left:6px;
		vertical-align: middle;
	}

	.clearResourceButton:visited {
		color:#444444;
	}
	
	.clearResourceButton:hover {
		text-decoration:none;
		color:#D60000;
	}

	.clearResourceButton svg #closeBtn {
		stroke:black;
		stroke-width:2;
		fill:#ddd;
	}

	.clearResourceButton svg #closeBtn:hover {
		stroke:red;
		fill:#eee;
	}

	#resourceSelection {
		padding-top:4px;
		padding-right:10px;
		margin:0 10px 15px 0;
		display:inline;
	}

	#resourceSelection * {
		text-align:left;
	}
	
	#typeSelection {
		padding-top:4px;
		padding-right:10px;
		margin:0 10px 15px 0;
		display:inline;
	}

	#typeSelection * {
		text-align:left;
	}
	
	#ridDD {
		margin-top:3px;
		vertical-align:bottom;
		width:375px;
	}
	
	#typeDD {
		margin-top:3px;
		vertical-align:bottom;
		width:375px;
	}
	
	.fc-right span {
		text-align:right; /* This causes the positions to get switched :( */
	}
	
	.fc-left {
		width: 180px;
		text-align: left;
		}
		
	.fc-center {
		text-align: left;
		}
		
	.fc-right {
		text-align: right;
		}
	
	.noteIcon {
		width:12px;
		height:11px;
		background-image:url('/Resources/images/stickynoteimage-23x22.png');
		background-size:11px 11px;
		background-repeat:no-repeat;
		float:left;
		margin-right:1px;
	}

	.eventDeleteButton img {
		height:20px;
		width:20px;
		position:absolute;
		border:none;
		top:0px;
		right:0px;
		z-index:30;
	}

	.eventNoteButton img {
		height:20px;
		width:20px;
		position:absolute;
		border:none;
		bottom:0px;
		left:0px;
		z-index:30;
	}
</style>


<cfquery name="PriorUsers" dbtype="ODBC" datasource="SecureSource">
	SELECT DISTINCT UserBarCode, FirstName, LastName, 1 AS CustSort FROM MakerspaceBookingTimes
	WHERE UserBarCode='21221012345678'
	UNION
	SELECT DISTINCT UserBarCode, FirstName, LastName, 2 AS CustSort FROM MakerspaceBookingTimes b
	JOIN MakerspaceBookingResources r ON r.RID=b.RID
	JOIN MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID	
	WHERE UserBarCode!='21221012345678'
	AND t.OfficeCode='#ThisLocation#'
	AND EndTime > DATEADD(day,-20,GETDATE())
	Order By CustSort, FirstName, LastName
</cfquery>

<div id="userSelection">
	<form name="userSelectionForm" id="userSelectionForm" action="patronlookup.cfm">
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
		<span id="onlyShow" class="hidden"><label for="hideOtherBookings" style="margin-left:12px;margin-right:2px;">Highlight:</label><input type="checkbox" id="hideOtherBookings" name="hideOtherBookings" style="vertical-align:middle;"/><label id="highlightHelp" for="hideOtherBookings" style="margin-left:2px;"><img src="/Resources/Images/help_icon-32.png" alt="Help" style="vertical-align:middle;width:16px;height:16px;border:none;"></label></span>
		
		<span id="altCard" class=""><label for="alternateCardCheckbox" style="margin-left:12px;margin-right:2px;">Other Card:</label><input type="checkbox" id="alternateCardCheckbox" name="alternateCardCheckbox" style="vertical-align:middle;"/><label id="altCardHelp" for="alternateCardCheckbox" style="margin-left:2px;"><img src="/Resources/Images/help_icon-32.png" alt="Help" style="vertical-align:middle;width:16px;height:16px;border:none;"></label></span>
		

	<span id="errorid" class="error" style="display:none;">&nbsp;Enter a card number</span>
		<!--- I just use this to check that the card is validated. (I check again on the server side when inserting) --->
		<input type="hidden" name="validatedCard" id="validatedCard" value="false" />
	</form>
<!---user Information or errors will be displayed here --->
<div id="userStatus"></div>	
</div><!--userSelection-->

<input type="hidden" id="rid" name="rid" />
<!--- Can set default vaules for displayed type here --->


<cfquery name="DefaultTypes" dbtype="ODBC" datasource="SecureSource">
SELECT * FROM MakerspaceBookingResourceTypes WHERE ShowByDefault=1 AND OfficeCode='#ThisLocation#'
</cfquery>
<input type="hidden" id="typeID" name="typeID" value="<cfoutput query="DefaultTypes"><cfif currentRow NEQ 1>,</cfif>#TypeID#</cfoutput>" />
<span id="errorrid" class="error" style="display:none;float:right;text-align:right;clear:right;margin-right:40px;">You must select a resource before booking a time.</span>	

<div style="clear:both;margin-top:8px;"></div>

<!---fullCalendar displays here--->
<div id="calendar"></div>

<script language="Javascript">
	/* Enable submit only if 14 characters have been entered 
	This is obviated by inputmask
	$('#id').keyup(function() {
		var cleanNumber=$(this).val().replace(/\s/g, '');
		if (cleanNumber.length == 14 && isNaN(cleanNumber)===false) $('#userSelectionSubmit').removeAttr('disabled');
		else $('#userSelectionSubmit').attr('disabled', 'disabled');
	});*/

/* OpenTip Style for Events */
Opentip.styles.eventInfo = {
  background: "rgba(252, 255, 176, 0.9)",
  borderColor: "rgba(247, 235, 150, 0.7)",
  target: true,
  stem: true,
  fixed:true,
  tipJoint: "top"
};
		
/* Get the width of the contents of the Makerspace Booking Calendar where events go */
var calHeader='.fc-day-header.fc-widget-header';
		
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
		var url = $('#userSelectionForm').attr( 'action' );
		var formdata = $('#userSelectionForm').serialize();
		$.post(url, formdata)
		.done(function(data){
			dataObj = JSON.parse(data);
			$("#userStatus").html('');
			//Display our errors, if any
			if (typeof dataObj.ERROR === 'object') {
				for(key in dataObj.ERROR) {
				$("#userStatus").append('<span class="error">'+dataObj.ERROR[key]+'</span><br />');
				}
				$('#validatedCard').val('false');
			} else {//else no errors from dataObj
				$('#validatedCard').val('true');
				if (dataObj.CUSTOMER.STATUS == 'BLOCKED') {
					$("#userStatus").append('<span class="blockWarn"><b>'+dataObj.CUSTOMER.FULLNAME+'</b> is BLOCKED.<cfif BlockedResources.RecordCount><br />These may not booked: </cfif><cfoutput query="BlockedResources"><cfif CurrentRow NEQ 1>, </cfif>#ResourceName#</cfoutput></span>');
				}else {
					$("#userStatus").append('<span class="success"><b>'+dataObj.CUSTOMER.FULLNAME+'</b> is valid.</span>&nbsp; Click a time to book it.');
				}			//This was annoying people
				//$('#id').prop('readonly', true);
				$('#altCard').hide();
				$('#onlyShow').show();
				

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
	//This should die eventually
	<!---var offsetRes#RID#=#CurrentRow#;--->
</cfoutput>
/*Will have to fix all references to 
	DONE -resources array 
	DONE-offsetRes# variables (now a property of Resources[#].offset
	-resCount variable (now a function taking types as parameter)
*/

//Change offset into a function that accepts a resource for parameter then calculates its offset.
//Or... figure it out whenever the typeID field changes and update offset in the Resources Objects.
//Maybe I can do this as part of resCount.

var resCount = function(){
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
	
	//reset all offsets (I may not need this)
	for( var i=0; i < Resources.length; i++) {
		if (typeof Resources[i] === "object") {Resources[i].offset='';}
	}
	
	//loop through all types passed as arguments, set the offset of all resources
	for(i=0; i<arguments.length;i++) {
		//sub loop through all resources to look for matches. Increment counter if found.
		for( var j=0; j < Resources.length; j++) {
			if (typeof Resources[j] === "object") {
				if (Resources[j].typeID == arguments[i]) {
					count++;
					Resources[j].offset = count;
				}
			}
		}
	}
	return count;	
};


/* resCount should probably become a function that uses the typeID field to determine the number of resources. TypeID is a list.
	-Create array of objects for all resources
	-Loop through the array given a list of 
 */
<!---var resCount=<cfoutput>#ResourceList.RecordCount#</cfoutput>;--->

//I may have to redo this with pure JS as well.
<cfoutput query="ResourceTypeCols">
var type#TypeID#Col = {columns:#Columns#, firstRID:#firstRID#};
//console.log(TypeCol#TypeID#);
</cfoutput>

$('#id').focus(function(){
	$(this).val('');
	delete dataObj;
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
		timeline2 = jQuery('<hr />').addClass("timeline2");
		$('.fc-time-grid-container').prepend(timeline2);
	}

	var curTime = moment();
	curTimeUTC=curTime.clone().add('h',-6);
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

function evenWidth() {
	return $(calHeader).width()/resCount()-4;
}


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
					$('.fc-day-header.fc-widget-header').append('<a href="javascript:void(0);" id="DayResourceLabel'+j+'" class="DayResourceLabel" style="width:'+evenWidth()+'px;background-color:'+Resources[j].color+';border-color:'+Resources[j].color+';">'+Resources[j].name+'</a>');	
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
		titleFormat: {month:'MMMM YYYY', week: "MMMM D YYYY", day: 'dddd MMMM Do YYYY'},
		columnFormat: {week: 'dddd MMM D', day: ''},
		contentHeight:"auto",
		defaultView:'agendaDay',
		timeFormat: {agenda:'h:mm t'},
		slotDuration:'01:00:00',
		minTime: '09:00:00',
		maxTime: '21:00:00',
		allDaySlot:false,
		firstDay:today.getDay(),
		selectable:true, //I don't want the dragging to work, though
		selectHelper:false,
		eventDurationEditable:false,
		defaultTimedEventDuration: '00:55:00',
		eventAfterRender: function(event, element, view) {
			//Renders HTML in the event title (ie for notes image)
			element.find('.fc-event-title').prepend(event.noteIcon);
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
					$(".blockedTime."+event.className[typeClassIdx]).css('width',evenWidth()*numCols+((numCols-1)*4));
					//console.log('setting .blockedTime.'+event.className[1]+' to '+evenWidth()+numCols);
					//new offset value comes from the Resources[x] object.
					//Use first RID for the type, get offset from Resoruces array.
					var offset=Resources[eval(event.className[typeClassIdx]+"Col").firstRID].offset; 
				} else if (typeof event.className[1] != 'undefined' && event.className[1] != 'All') {
					$(".resourcebooking, .blockedTime."+event.className[1]).css('width',evenWidth());
					//need to calculate an offset value based on the classname of a booking event
					//Figure out the RID for this event. Grep it? Remove the Res?
					var thisRID=event.className[1].replace(/Res/i, "");
					var offset=Resources[thisRID].offset;
				} else { //If no resource is associated it applies to all columns
					$(".blockedTime.All").css('width',$(calHeader).width());
					$(".blockedTime.All").css('left',0);
				}
				
				//           Left time col    col position for res    'margin'
				position = (evenWidth()*offset) + (offset*4) - evenWidth() -3;
				element.css('left',position);
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
			
			/* Show the header row when viewing all resources in day view */
			if (view.name=="agendaDay" && $('#rid').val()=='') {
				labelColumns();

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
					});

				}//if #typeSelection.length==0

			}
		
			/* Draw time line for current time every three minutes. */
			if (first) {
				first = false;
			} else {
				window.clearInterval(timelineInterval);
			}
			/* Update the time line every 3 minutes */
			timelineInterval=setInterval(function(){try{setTimeline(view, element)}catch(err){}}, 180000);
			try {
				setTimeline(view, element);
			} catch(err) {}
		},
		dayClick: function(date, jsEvent, view){doDayClick(date, jsEvent, view)},
		<cfif permissions.delete eq 1><!--- This must not be the only way to disable this functionality. Server-side check required --->
		eventClick: function(calEvent, jsEvent, view) {
			// Add the delete button if it doesn't already exist
			if (typeof calEvent.tid == 'string' && $(this).children('.eventDeleteButton').length == 0) {
				//Remove any existing delete buttons
				$('.eventDeleteButton').remove();
				$('.eventNoteButton').remove();
				var $deleteButton='<a class="eventDeleteButton" href="javascript:void(0)" onclick="deleteEvent(\''+calEvent.tid+'\',\''+calEvent.title+'\');"><img src="/Resources/Images/x_icon_64.png" /></a>';
				var $noteButton='<a class="eventNoteButton" href="javascript:void(0)" title="Add/Edit Note" onclick="createNote(\''+calEvent.tid+'\',\''+calEvent.title+'\');"><img src="/Resources/Images/editPencilCircle_64.png" /></a>';
				$(this).append($deleteButton).children('.eventDeleteButton').hide().fadeIn(100);
				$(this).append($noteButton).children('.eventNoteButton').hide().fadeIn(100);
			}
		},
		</cfif>
		eventSources: [
			{
				url: '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>',
				type: 'POST',
				data: {
					isStaff:'<cfoutput>#isStaff#</cfoutput>',
					id:$('#id').val(),
					rid:$('#rid').val(),  //This won't update dynamically. Have to reset event sources onchange.
					typeID:$('#typeID').val(),
					hideOther:$('#hideOtherBookings').prop('checked')
				}
			},
			{
				url: '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>',
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
		/*Remove events and only show events for the newly selected resource */
		$('#calendar').fullCalendar('removeEvents');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>');
		$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>',
			type: 'POST',
			data: {
				id:$('#id').val(),
				rid:$('#rid').val(),
				typeID:$('#typeID').val(),
				hideOther:$('#hideOtherBookings').prop('checked')
			}
		});
		$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>',
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
		/*Remove events and only show events for the newly selected resource */
		$('#calendar').fullCalendar('removeEvents');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>');
		$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>',
			type: 'POST',
			data: {
				id:$('#id').val(),
				rid:$('#rid').val(),
				typeID:$('#typeID').val(),
				hideOther:$('#hideOtherBookings').prop('checked')
			}
		});
		$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>',
			type: 'POST',
			data: {
				rid:$('#rid').val(),
				typeID:$('#typeID').val()
			}
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
	}

	$('#typeID').on('change', function(){
		handleTypeID();
	});	
	
	/* Toggle showing only this user's bookings - note that this will allow them to book other time slots... */
	$('#hideOtherBookings').on('change', function(){
		$('#errorrid').hide();
		/*Remove events and only show events for the newly selected resource */
		$('#calendar').fullCalendar('removeEvents');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>');
		$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>')
		$('#calendar').fullCalendar('addEventSource', {
				url: '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>',
				type: 'POST',
				data: {
					id:$('#id').val(),
					rid:$('#rid').val(),
					typeID:$('#typeID').val(),
					hideOther:$('#hideOtherBookings').prop('checked')
				}
			});
		$('#calendar').fullCalendar('addEventSource', {
				url: '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>',
				type: 'POST',
				data: {rid:$('#rid').val(),typeID:$('#typeID').val()}
		});

	});
	
});//document.ready

<cfif permissions.delete eq 1>
function deleteEvent(tid, title) {
	if (confirm('Delete '+title+'?')) {
		$.post('deleteBooking.cfm', {"id":tid});
		$('.event'+tid).fadeOut(200);
	}
}
</cfif>

function createNote(tid) {
	//Show popup allowing display selection for this ad.
	loadPopOverContent('editNote.cfm', '300px',
				{
					'tid':tid
				});	

}


function doDayClick(date, jsEvent, view, confirmDelete) {
	//If in day view and no Resource selected, determine it through position of click
	if (view.name=="agendaDay" && $('#rid').val()=='') {var rid=resourceColumn(jsEvent.offsetX);}
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
		var newEvent={id:'newBooking', title:'Your Booking', start:date.add('minutes',5).format(), end:date.add('minutes',55).format()};
		/* Check that everything is cool before booking the time slot. */
		//console.log('rid: '+rid);
		if (allowedToBook(newEvent, rid) && !isOverlapping(newEvent, rid)) {
			$('#calendar').fullCalendar('removeEvents', 'newBooking');
			$.post('addBooking.cfm?branch=<cfoutput>#ThisLocation#</cfoutput>', {
				'id':$('#id').val(),
				'rid':rid,
				'newstart':newEvent.start,
				'newend':newEvent.end,
				'status':dataObj.CUSTOMER.STATUS,
				'firstname':dataObj.CUSTOMER.FIRST,
				'lastname':dataObj.CUSTOMER.LAST,
				'confirmDelete':confirmDelete
			})
			.done(function(data){
				bookingInfoObj=$.parseJSON(data);
				var noticeMsg="";

				if (typeof bookingInfoObj.NEWBOOKING != 'undefined') {
					noticeMsg="<b>"+Resources[bookingInfoObj.NEWBOOKING.RID].name+"</b> booked<br />for <b>"
						+moment(bookingInfoObj.NEWBOOKING.START).format("h:mm a")
						+"</b>";// to "+moment(bookingInfoObj.NEWBOOKING.END).format("h:mm a");
					if (moment(bookingInfoObj.NEWBOOKING.START).format("dddd, MMMM Do") == moment().format("dddd, MMMM Do")) {
					noticeMsg+=" today"}
					else noticeMsg+=" on "+moment(bookingInfoObj.NEWBOOKING.START).format("dddd, MMMM Do");
					noticeMsg+=".";
				}
				//Handles confirmation dialog for booking past events
				if (typeof bookingInfoObj.PASTDATE != 'undefined' && bookingInfoObj.REQUIRECONFIRM != true) {
					noticeMsg="<b>"+Resources[bookingInfoObj.NEWBOOKING.RID].name+"</b> marked as used<br />on <b>"
						+moment(bookingInfoObj.NEWBOOKING.START).format("h:mm a")+"</b>";
					if (moment(bookingInfoObj.NEWBOOKING.START).format("dddd, MMMM Do") == moment().format("dddd, MMMM Do")) {
					noticeMsg+=" today"}
					else noticeMsg+=" on "+moment(bookingInfoObj.NEWBOOKING.START).format("dddd, MMMM Do");
					noticeMsg+=".";
				} else if (typeof bookingInfoObj.PASTDATE != 'undefined' && bookingInfoObj.REQUIRECONFIRM == true) {
					noticeMsg+='<br /><span class="warning">This time is in the past and cannot be booked.<b><br />';
					window.tempjsEvent=jsEvent;
					window.tempView=view;
					noticeMsg+='</span><div class="confirmQuestion">Record this resource as already used?</div>';
					<!--- On clicking confirmdeletion, I have to resubmit this whole thing again but with confirmdelete set. --->
					noticeMsg+='<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes</a>';
					noticeMsg+='<a href="javascript:void(0);">No</a></div>';
				}//end else if

				if (typeof bookingInfoObj.PRIORBOOKINGS != 'undefined' && bookingInfoObj.REQUIRECONFIRM != true) {
					var arrLen=bookingInfoObj.PRIORBOOKINGS.length;
					for (var i = 0; i < arrLen; i++) {
						noticeMsg+='<br /><span class="warning">Your prior <b>'
							+Resources[bookingInfoObj.PRIORBOOKINGS[i].RID].name
							+'</b> booking for <b>'+moment(bookingInfoObj.PRIORBOOKINGS[i].START).format("dddd [at] h:mm a")
							+'</b> has been cancelled.</span>';
					}//end array loop
				} else if (typeof bookingInfoObj.PRIORBOOKINGS != 'undefined' && bookingInfoObj.REQUIRECONFIRM == true) {
					var arrLen=bookingInfoObj.PRIORBOOKINGS.length;
					noticeMsg+='<br /><span class="warning">To make this booking, these other bookings must be cancelled:<b><br />';
					for (var i = 0; i < arrLen; i++) {
							noticeMsg+=Resources[bookingInfoObj.PRIORBOOKINGS[i].RID].name
							+'</b> booking for <b>'+moment(bookingInfoObj.PRIORBOOKINGS[i].START).format("dddd [at] h:mm a")+'</b>';
					}//end for loop
					window.tempjsEvent=jsEvent;
					window.tempView=view;
					noticeMsg+='</span><div class="confirmQuestion">Schedule the new booking?</div>';
					<!--- On clicking confirmdeletion, I have to resubmit this whole thing again but with confirmdelete set. --->
					noticeMsg+='<div class="confirmDeletion"><a href="javascript:void(0);" onclick="doDayClick(tempDate, tempjsEvent, tempView, true)">Yes - cancel other bookings</a>';
					noticeMsg+='<a href="javascript:void(0);">No - Don&#146;t cancel anything</a></div>';
				}//end else if
				if (typeof bookingInfoObj.ERRORMSG != 'undefined' && bookingInfoObj.ERRORMSG.length > 0) {
					noticeMsg+=bookingInfoObj.ERRORMSG;
				}//end priorbookings if
				
				if (bookingInfoObj.ERROR) {
					toastr.options.timeOut = 6000;
					toastr.error(noticeMsg);
				}else if (bookingInfoObj.PRIORBOOKINGS || bookingInfoObj.PASTDATE) {
					toastr.options.timeOut = 0;
					toastr.warning(noticeMsg);
				}else {
					toastr.options.timeOut = 6000;
					toastr.success(noticeMsg);
				}
				$('#calendar').fullCalendar('refetchEvents');
			});	
		}//end if allowedToBook
	}//end if date hour == 0
}//end function doDayClick()


/* Determines which resource column has been clicked based on X position */
function resourceColumn(xPos) {
	// evenWidth=$(calHeader).width()/resCount()-4;
	
	for (var i=0; i < Resources.length; i++) {
		if (typeof Resources[i] === "object") {
		//Left time col    col position for res    'margin'
			var thisOffset = (evenWidth()*Resources[i].offset) + (Resources[i].offset*4) - (evenWidth());
			if (xPos>=thisOffset && xPos <=thisOffset+evenWidth()) {
				return i;
			}
		}//end if Resources[i] is an object
	}
}


/* Checks for overlapping events. */
function isOverlapping(event, rid){
	var array = $('#calendar').fullCalendar('clientEvents');
	for(i in array){
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
	if ($('#rid').val() !='') {rid=$('#rid').val()};
	if ( $('#id').val().length < 10 || $('#validatedCard').val() != 'true') {
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
	else if(event.end > moment().add('day',15).format()) {
		toastr.error("You can't book a time more than two weeks from now.");
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
	/*Remove events and only show events for the newly selected resource */
	/*$('#calendar').fullCalendar('removeEvents');*/
	$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>');
	$('#calendar').fullCalendar('removeEventSource', '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>');
	$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBookings.cfm?branch=#thisLocation#</cfoutput>',
			type: 'POST',
			data: {
				id:$('#id').val(),
				rid:$('#rid').val(),
				typeID:$('#typeID').val(),
				hideOther:$('#hideOtherBookings').prop('checked')
			}
		});
	$('#calendar').fullCalendar('addEventSource', {
			url: '<cfoutput>#MBSPath#/getBlockedTimes.cfm?branch=#thisLocation#</cfoutput>',
			type: 'POST',
			data: {rid:$('#rid').val(),typeID:$('#typeID').val()}
	});
});




</script>
<cfinclude template="/AppsRoot/Includes/IntraFooter.cfm">
