<cfinclude template="/Includes/INTYouKnowVariables.cfm" />

<cfparam name="ThisLocation" default="#RealStateBuilding#" />

<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
</cfif>



<cfset app.title="Makerspace Blocked Times Manager">
<cfset ParentPage="Makerspace Resource Booking">
<cfset ParentLink="portal.cfm?branch=#ThisLocation#">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,block">

<cfset adminButtons = ArrayNew(1)>
<cfset adminButton = structNew()>
<cfset adminButton.permType="reso">
<cfset adminButton.link="resources.cfm">
<cfset adminButton.label="Resources">
<cfset adminButton.title="Manage Consoles, PCs, etc.">
<cfset ArrayAppend(app.adminButtons, adminButton)>	

<cfinclude template="/Includes/IntraHeader.cfm">

<style type="text/css">
	.linkField {
		text-align:center;
	}
	
	.editableUsers {
		width:30px;
	}
	.colorselection {
		width:100%;
		height:22px;
	}
	.ui-datepicker-trigger {
		margin-top:1px;
	}
	
	.datepicker, .hasDatepicker {
		background-image:url('/resources/images/calendar_icon16.png');
		background-position: 100% 50%;
		background-repeat:no-repeat;
		width:100%;
	}
	
	.heading th {
		text-align:center;
	}
	
	.dateField {
		width:110px;
		height:26px;
	}
	
	.timeCell {
		padding-left:0 !important;
		padding-right:0 !important;
		width:92px;
	}

	.timeCell div {
		margin:0 auto;
		display:inline-block;
		text-align: center;
	}

	.timeCell div * {
		overflow:hidden;
		float:left;
		text-align:center;
		margin:0 auto;
	}
	
	.hiddenRow {
		color:#777777;
	}

	.blockError {
		float:left;
	}

	.rowError td {
		background-color:rgba(255,0,0,0.3);
	}
</style>

<cfparam name="url.sort" default="StartTime">
<cfparam name="url.hidden" default="off">

<form id="hiddenToggleForm">
<input type="hidden" name="sort" value="<cfoutput>#url.sort#</cfoutput>" />
<span style="float:right;margin-right:10px;" class="grayButton"><label for="showHidden">Show Hidden <input type="checkbox" name="hidden" id="showHidden" <cfif url.hidden NEQ "off">checked="checked"</cfif> onChange="$('#hiddenToggleForm').submit();"></label></span>
</form>

<cfquery name="Branches"  dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM Offices WHERE OfficeType='BRANCH' ORDER BY OfficeCode
</cfquery>

<cfquery name="BlockList" datasource="SecureSource" dbtype="ODBC">
	SELECT t.BID, t.RID, t.TypeID, StartTime, EndTime, DayofWeek, Continuous,
	t.Description, t.ModifiedBy, t.Modified, r.ResourceName, ty.TypeName, t.Hidden, t.OfficeCode
	FROM MakerspaceBlockedTimes t
	LEFT JOIN MakerspaceBookingResources r on t.RID=r.rid
	LEFT JOIN MakerspaceBookingResourceTypes ty on t.TypeID=ty.TypeID
	WHERE t.OfficeCode='#ThisLocation#'
	<cfif url.hidden eq 'off'>AND (Hidden !=1 OR Hidden IS NULL)</cfif>
	<cfif url.sort eq 'ResourceName'>
	ORDER BY TypeName, ResourceName
	<cfelse>
	ORDER BY #url.sort#
	</cfif>
</cfquery>

<cfquery name="ResourceList" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM MakerspaceBookingResources r 
	LEFT JOIN MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID 
	WHERE t.OfficeCode='#ThisLocation#'
</cfquery>

<cfquery name="ResourceTypes" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM Vsd.Vsd.MakerSpaceBookingResourceTypes
	WHERE OfficeCode='#ThisLocation#'
</cfquery>
<p>During the following blocks of time, the specified resource(s) are unavailable for booking at <b><cfoutput>#ThisLocation#</cfoutput></b>.</p>
<p>Click existing Info to edit and press enter. Changes are saved instantly.</p>
<a name="addBlockedTime"></a>
<table id="existingBlockedTimes" class="padded">
<tr class="heading">
		<th><cfif url.sort eq "DayofWeek">Day of Week &#x25B2;<cfelse><a href="?sort=DayofWeek<cfif url.hidden eq "on">&hidden=on</cfif>">Day of Week</a></cfif></th>
		<th>Start Time</th>
		<th>End Time</th>
		<th><cfif url.sort eq "StartTime">Begin Date &#x25B2;<cfelse><a href="?sort=StartTime<cfif url.hidden eq "on">&hidden=on</cfif>">Begin Date</a></cfif></th>
		<th><cfif url.sort eq "EndTime">End Date &#x25B2;<cfelse><a href="?sort=EndTime<cfif url.hidden eq "on">&hidden=on</cfif>">End Date</a></cfif></th>
		<!--- <th>Branch</th> --->
		<th style=""><cfif url.sort eq "ResourceName">Resource(s) &#x25B2;<cfelse><a href="?sort=ResourceName<cfif url.hidden eq "on">&hidden=on</cfif>">Resource(s)</a></cfif></th>
		<th style="width:400px;">Description (Click to Edit)</th>
		<th style="text-align:center;">Hide</th>
		<th style="text-align:center;">Delete</th>
	</tr>	
	<tr>
		<td colspan="4"><b>Add Blocked Time</b></td>
	</tr>
	<tr class="altRow">
		<form name="newBlockedTime" id="newBlockedTime" action="insertBlockedTime.cfm" method="post">
		<input type="hidden" name="Branch" id="Branch" value="<cfoutput>#ThisLocation#</cfoutput>" />
		<td>
			<select id="dow" name="dow">
				<cfoutput>
				<option value="daily">Every Day</option>
				<option value="continuous">Continuous</option>
				<cfloop from="1" to="7" index="d">
					<!--- SQL uses 0 based days of week (sunday=0), CF uses 1 based (sunday IS 1) --->
					<option value="#d-1#">#DayofWeekAsString(d)#</option>
				</cfloop>
				
				</cfoutput>
			</select>
		</td>
		<!--- I think I can use the same classes for both of the time and dates, respectively --->
		<td class="timeCell">
			<select id="startTimeHour" name="startTimeHour">
				<cfoutput>
				<!--- Hours --->
				<cfloop from="00" to="23" index="h" step="1">
					<option value="#h#">#NumberFormat(h, "09")#</option>
				</cfloop>
			</select
			>:<select id="startTimeMinute" name="startTimeMinute">	
				<!--- Minutes --->
				<cfloop from="00" to="55" index="m" step="5">
					<option value="#m#">#NumberFormat(m, "09")#</option>
				</cfloop>				
				</cfoutput>
			</select>		
		</td>
		<td class="timeCell">
			<select id="endTimeHour" name="endTimeHour">
				<cfoutput>
				<!--- Hours --->
				<cfloop from="00" to="23" index="h" step="1">
					<option value="#h#">#NumberFormat(h, "09")#</option>
				</cfloop>
			</select
			>:<select id="endTimeMinute" name="endTimeMinute">	
				<!--- Minutes --->
				<cfloop from="00" to="55" index="m" step="5">
					<option value="#m#">#NumberFormat(m, "09")#</option>
				</cfloop>				
				</cfoutput>
			</select>		
		</td>
		<td style="width:120px;"><input id="beginDate" name="beginDate" readonly="readonly" type="text" class="datepicker" /></td>
		<td style="width:120px;"><input id="endDate" name="endDate" readonly="readonly" type="text" class="datepicker" /></td>
<!--- 		<td><select name="Branch" id="Branch" class="chzn-select" style="width:80px;" data-placeholder="Branch">
				<option value=""></option>
				<cfoutput query="Branches">
					<option value="#OfficeCode#"<cfif ThisLocation IS OfficeCode> selected</cfif>>#OfficeCode#</option>
				</cfoutput>
			</select>
		</td> --->
		<!--- Display resource name here --->
		<td style="min-width:170px;" >
			<select multiple id="RID" name="RID" class="chzn-select-100" data-placeholder="Choose Resources">
				<option value="ALL">All Resources</option>
				<optgroup label="Types">
				<cfoutput query="ResourceTypes">
					<option value="Type#TypeID#">#TypeName#</option>
				</cfoutput>
				</optgroup>
				<optgroup label="Individual Resources">
				<cfoutput query="ResourceList">
					<option value="#RID#">#ResourceName#</option>
				</cfoutput>
				</optgroup>
			</select>
		</td>
		<td><div id="description"><input type="text" id="descriptionInput" name="description" style="width:100%"/></div></td>
		<td></td>
		<td><input type="Submit" name="SubmitNew" value="Add New" /></td>
		</form>
	</tr>
	<tr id="errorRow">
		<td><span class="error hidden" id="errorDay">Choose a day option.</span></td>
		<td colspan="2"><span class="error hidden" id="errorTime">Enter Start and End Times</span></td>
		<td colspan="2"><span class="error hidden" id="errorDate">Enter Begin and End Dates</span></td>
		<td><span class="error hidden" id="errorBranch">Branch</span></td>
		<td><span class="error hidden" id="errorRID">Choose a resource (or all)</span></td>
		<td></td>
		<td></td>
	</tr>


	<tr class="heading">
		<th><cfif url.sort eq "DayofWeek">Day of Week &#x25B2;<cfelse><a href="?sort=DayofWeek<cfif url.hidden eq "on">&hidden=on</cfif>">Day of Week</a></cfif></th>
		<th>Start Time</th>
		<th>End Time</th>
		<th><cfif url.sort eq "StartTime">Begin Date &#x25B2;<cfelse><a href="?sort=StartTime<cfif url.hidden eq "on">&hidden=on</cfif>">Begin Date</a></cfif></th>
		<th><cfif url.sort eq "EndTime">End Date &#x25B2;<cfelse><a href="?sort=EndTime<cfif url.hidden eq "on">&hidden=on</cfif>">End Date</a></cfif></th>
		<!--- <th>Branch</th> --->
		<th style=""><cfif url.sort eq "ResourceName">Resource(s) &#x25B2;<cfelse><a href="?sort=ResourceName<cfif url.hidden eq "on">&hidden=on</cfif>">Resource(s)</a></cfif></th>
		<th style="width:400px;">Description (Click to Edit)</th>
		<th style="text-align:center;">Hide</th>
		<th style="text-align:center;">Delete</th>
	</tr>
	
	<cfoutput query="BlockList">
	<cfif len(trim(DayOfWeek)) IS 0 AND Continuous NEQ 1>
		<cfset DayOfWeekDesc="Every Day">
	<cfelseif Continuous EQ 1>
		<cfset DayOfWeekDesc="Continuous">
	<cfelse>
		<cfset DayOfWeekDesc=DayOfWeekAsString(DayOfWeek+1)>
	</cfif>
	
	<cfquery name="BlockedResources" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM MakerspaceBlockedTimeResources btr
		LEFT JOIN MakerspaceBookingResources r on btr.RID=r.rid
		LEFT JOIN MakerspaceBookingResourceTypes ty on btr.TypeID=ty.TypeID
		WHERE BID=#BID#
	</cfquery>
	<cfset ResourceDesc="">
	<cfset counter=0>
	<cfloop query="BlockedResources">
		<cfif counter NEQ 0><cfset ResourceDesc&=", "></cfif>
		<cfset ResourceDesc&=BlockedResources.ResourceName>
		<cfset ResourceDesc&=BlockedResources.TypeName>
		<cfset counter++>
	</cfloop>
	<cfif ResourceDesc IS "">
		<cfif len(ResourceName)><cfset ResourceDesc=ResourceName>
		<cfelseif len(TypeName)><cfset ResourceDesc=TypeName>
		<cfelse><cfset ResourceDesc="All Resources">
		</cfif>
	</cfif>
	<!--- Compare start time to end time to determine if end time is after start time --->
	<cfset SaneDate=DateCompare(StartTime, EndTime) />
	<tr id="row#BID#" class="existingBlock<cfif CurrentRow MOD 2> altRow</cfif><cfif Hidden IS 1> hiddenRow</cfif><cfif SaneDate GT 0> rowError</cfif>" style="text-align:center;">
		<td><div class="editableDayOfWeek" id="dow#BID#"><cfif SaneDate GT 0><img class="blockError" src="/Resources/images/notice_icon_24.png" title="Invalid Blocked Time. Check date/time." /></cfif> #DayOfWeekDesc#</div></td>
		<!--- I think I can use the same classes for both of the time and dates, respectively --->
		<td class="timeCell"><div><span class="editableStartHour" id="startTime#BID#">#TimeFormat(StartTime, "HH")#</span><span>:</span><span class="editableStartMinute" id="startTime#BID#">#TimeFormat(StartTime, "mm")#</span></div></td>
		<td class="timeCell"><div><span class="editableEndHour" id="startTime#BID#">#TimeFormat(EndTime, "HH")#</span><span>:</span><span class="editableEndMinute" id="startTime#BID#">#TimeFormat(EndTime, "mm")#</span></div></td>
		<td class="dateField"><div class="editableStartDate" id="startDate#BID#">#DateFormat(StartTime, "YYYY-MMM-DD")#</div></td>
		<td class="dateField"><div class="editableEndDate" id="endDate#BID#">#DateFormat(EndTime, "YYYY-MMM-DD")#</div></td>
		<!--- <td><div class="editableBranch" id="Branch#BID#">#OfficeCode#</div></td> --->
		<!--- Display resource name here --->
		<td><div class="editableResource" id="Resource#BID#">#ResourceDesc#</div></td>
		<td style="text-align:left;"><div class="editableDesc" id="description#BID#">#Description#</div></td>
		<td style="text-align:center;"><a class="grayButton" id="hide#BID#" href="javascript:void(0);" onClick="hideItem('#BID#');"><cfif hidden IS 1>Unhide<cfelse>Hide</cfif></a></td>
		<td style="text-align:center;"><a class="delete" href="javascript:void(0);" onClick="deleteItem('#BID#', '#TimeFormat(StartTime, "HH:mm")#-#TimeFormat(EndTime, "HH:mm")#');">Delete</a></td>
	</tr>
	</cfoutput>

</table>
<a href="#addBlockedTime" class="greenButton">Add New Blocked Time</a>

<div style="height:60px;"></div>

<script language="Javascript">
$('.datepicker').datepicker({
	//yy: four-digit year, M: Three letter month, dd: day number with leading zero
	dateFormat: "yy-M-dd",
});



	function hideItem(BID) {
		//$("#row"+BID).hide(200);
		$.get("hideBlockedTime.cfm?id="+BID)
		.done(function(data) {
			if (data.trim()=="1") {
				$("#row"+BID).addClass('hiddenRow');
				$("#hide"+BID).html('Unhide');
			}
			else {
				$("#row"+BID).removeClass('hiddenRow');
				$("#hide"+BID).html('Hide');
			}
		});
		
	}

	function deleteItem(BID, typeName) {
		if (confirm('Delete Block from '+typeName+'?') ){		
				$("#row"+BID).hide(200);
				/*$("#row"+BID).remove();*/
				$.get("deleteBlockedTime.cfm?delID="+BID);
		}		
	}


/* Add new multiselect type for jEditable */
$.editable.addInputType("multiselect", {
    element: function (settings, original) {
        var select = $('<select multiple="multiple" class="chzn-select" />');

        if (settings.width != 'none') { select.width(settings.width); }
        if (settings.size) { select.attr('size', settings.size); }

        $(this).append(select);
        return (select);
    },
    content: function (data, settings, original) {
        /* If it is string assume it is json. */
        if (String == data.constructor) {
            eval('var json = ' + data);
        } else {
            /* Otherwise assume it is a hash already. */
            var json = data;
        }
        for (var key in json) {
            if (!json.hasOwnProperty(key)) {
                continue;
            }
            if ('selected' == key) {
                continue;
            }
            var option = $('<option />').val(key).append(json[key]);
            $('select', this).append(option);
        }

        if ($(this).val() == json['selected'] ||
                            $(this).html() == $.trim(original.revert)) {
            $(this).attr('selected', 'selected');
        }

        /* Loop option again to set selected. IE needed this... */
        $('select', this).children().each(function () {
            if (json.selected) {
                var option = $(this);
                $.each(json.selected, function (index, value) {
                    if (option.val() == value) {
                        option.attr('selected', 'selected');
                    }
                });
            } else {
                if (original.revert.indexOf($(this).html()) != -1)
                    $(this).attr('selected', 'selected');
            }
        });
    }
});



	
/* Makes Descriptions editable makes Names editable */
	$(document).ready(function() {
		$(".editableDesc").editable('editBlockedTime.cfm', {
			name : 'NewDesc',
			indicator : 'Saving...',
			tooltip   : 'Click to change description...',
			placeholder: '<span class="subtleGray">Click to add a description...</span>'
		});

		<cfoutput>
		$(".editableDayOfWeek").editable('editBlockedTime.cfm', {
			name : 'NewDoW',
			indicator : 'Saving...',
			tooltip   : 'Click to change Day of Week...',
			placeholder: '<span class="subtleGray">Set Weekday...</span>',
			data : "{'daily':'Every Day','continuous':'Continuous'<cfloop from="1" to="7" index="d">,'#d-1#':'#DayofWeekAsString(d)#'</cfloop>}",
			type : 'select'
		});
		
		$(".editableStartHour").editable('editBlockedTime.cfm', {
			name : 'NewStartHour',
			indicator : '...',
			tooltip   : 'Change start hour...',
			data : "{'0':'00'<cfloop from="01" to="23" index="h">,'#h#':'#NumberFormat(h, "09")#'</cfloop>}",
			type : 'select'
		});		
		$(".editableStartMinute").editable('editBlockedTime.cfm', {
			name : 'NewStartMinute',
			indicator : '...',
			tooltip   : 'Change start minute...',
			data : "{'0':'00'<cfloop from="5" to="55" index="m" step="5">,'#m#':'#NumberFormat(m, "09")#'</cfloop>}",
			type : 'select'
		});				

		$(".editableEndHour").editable('editBlockedTime.cfm', {
			name : 'NewEndHour',
			indicator : '...',
			tooltip   : 'Change end hour...',
			data : "{'0':'00'<cfloop from="01" to="23" index="h">,'#h#':'#NumberFormat(h, "09")#'</cfloop>}",
			type : 'select'
		});
		$(".editableEndMinute").editable('editBlockedTime.cfm', {
			name : 'NewEndMinute',
			indicator : '...',
			tooltip   : 'Change end minute...',
			data : "{'0':'00'<cfloop from="5" to="55" index="m" step="5">,'#m#':'#NumberFormat(m, "09")#'</cfloop>}",
			type : 'select'
		});		
		</cfoutput>

		$(".editableStartDate").editable('editBlockedTime.cfm', {
			name : 'NewStartDate',
			indicator : 'Saving...',
			tooltip   : 'Change Begin Date...',
			placeholder : '<span class="subtle">Begin Date</span>',
			type : 'datepicker',
			datepicker:{dateFormat: "yy-M-dd"}
		});	
		
		$(".editableEndDate").editable('editBlockedTime.cfm', {
			name : 'NewEndDate',
			indicator : 'Saving...',
			tooltip   : 'Change End Date...',
			placeholder : '<span class="subtle">End Date</span>',
			type : 'datepicker',
			datepicker:{dateFormat: "yy-M-dd"}
		});

		<cfoutput>
		$(".editableResource").editable('editBlockedTime.cfm', {
			name : 'NewRID',
			indicator : 'Saving...',
			tooltip   : 'Click to change Resource...',
			/*add a 'z' to resources so that it ends up sorted in the correct order */
			data : "{'ALL':'All Resources'<cfloop query='ResourceTypes'>,'Type#TypeID#':'#TypeName#'</cfloop><cfloop query="ResourceList">,'z#RID#':'#ResourceName#'</cfloop>}",
			onblur: 'ignore',
			type : 'multiselect',
			submit : 'OK'
		}).click(function(){
			$(this).find('select').chosen();
		});
		</cfoutput>		



		$('#newBlockedTime').submit( function(e) {
			$('#errorDay').hide();
			$('#errorTime').hide();
			$('#errorDate').hide();
			$('#errorBranch').hide();
			$('#errorRID').hide();
			
			var error=false;
			if ($('#beginDate').val().length == 0) {
				$('#errorDate').fadeIn(200);
				error=true;
			}
			if ($('#endDate').val().length == 0) {
				$('#errorDate').fadeIn(200);
				error=true;
			}

			if ($('#Branch').val().length == 0) {
				$('#errorBranch').fadeIn(200);
				error=true;
			}
			if ($('#RID').val() === null) {
				$('#errorRID').fadeIn(200);
				error=true;
			}

			if (error === false) {
				return true;
			} else {		
				return false;
			}
			
		});

		
	
	});//$(document).ready


	/* Submits on change! */
	$('.existingBlock span, .editableDayOfWeek').on('change','select',function(){
	   $(this).trigger("submit")
	});
	
</script>

<cfinclude template="/AppsRoot/Includes/IntraFooter.cfm">


