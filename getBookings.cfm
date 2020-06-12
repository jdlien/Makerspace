<cfsetting showdebugoutput="no" enableCFOutputOnly="yes">
<cfheader name="Content-Type" value="application/json">
<cfparam name="form.isStaff" default="true">
<cfparam name="form.hideOther" default="false">

<cfscript>
string function escapedq(string s) {
	return replace(s, '"', '\"', "all");
}
</cfscript>

<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
<cfelse>
	<cfinclude template="#appsIncludes#/appsInitIPLocation.cfm">
	<cfset ThisLocation=RealStateBuilding/>
</cfif>

<cfif isDefined('url.rid') and url.rid NEQ ''><cfset form.rid=url.rid></cfif>
<cfif isDefined('form.rid') AND form.rid NEQ "">
	<cfquery name="ResourceInfo" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM MakerSpaceBookingResources
	WHERE RID='#form.rid#'
	</cfquery>
</cfif>
<cfparam name="form.id" default="">
<cfset form.id=REplace(form.id,' ', '', 'ALL')>

<cfquery name="Bookings" datasource="ReadWriteSource" dbtype="ODBC">
	SELECT * from MakerSpaceBookingTimes t
	JOIN MakerSpaceBookingResources r ON t.RID=r.RID
	JOIN MakerspaceBookingResourceTypes ty ON r.TypeID=ty.TypeID
	WHERE ty.OfficeCode='#ThisLocation#'
	<cfif isDefined('form.rid') AND form.rid NEQ "">AND t.RID='#form.rid#'</cfif>
	<cfif isDefined('form.start')>AND StartTime > '#form.start#'</cfif>
	<cfif isDefined('form.end')>AND EndTime < '#form.end#'</cfif>
	<cfif isDefined('form.TypeID') AND len(form.TypeID)>AND (
		<cfset i=0>
		<cfloop list="#form.TypeID#" index="TheType">
			<cfif i GT 0>OR </cfif>r.TypeID=#TheType#
			<cfset i++>
		</cfloop>)
	</cfif>
</cfquery>


<!--- I wanted coldfusion to generate JSON from an structure, but it wasn't working very well 
	[
<cfoutput query="Bookings">
	<cfset noteIcon='' />
	<cfif len(Note)>
		<cfset noteIcon='<div class=\"noteIcon\"></div>' />
	</cfif>
	<cfif form.hideOther IS "true" AND UserBarcode IS NOT form.id>
		<cfset titleDesc="">
	<cfelseif form.isStaff IS 'true'>
		<cfset titleDesc="#FirstName# #LastName#">
	<cfelseif len(form.id) AND form.id IS UserBarcode>
		<cfset titleDesc="Your #ResourceName# Booking">
	<cfelse>
		<cfset titleDesc=#ResourceName#>
	</cfif>
	{
	"title":"#escapedq(titleDesc)#",
	"start":"#StartTime#",
	"end":"#EndTime#",
	<cfif len(form.id) AND form.id IS UserBarcode>
		"borderColor":"black",
	</cfif>
	<cfif form.isStaff IS 'true'>
		"description":"<b>#escapedq(ResourceName)#</b><cfif len(Description)> - #escapedq(Description)#</cfif><br /><b>#escapedq(FirstName)# #escapedq(LastName)#</b><br /> #REReplace(trim(UserBarcode), "(\d{5})(\d{5})(\d{4})", "\1 \2 \3")#<cfif len(Note)><br /><b>Note: </b>#escapedq(Note)#</cfif>",
		"tid":"#TID#",
	</cfif>
	"rid":"#RID#",
	"className":"resourcebooking Res#RID#<cfif len(form.id) AND form.id IS UserBarcode> yourBooking</cfif><cfif form.isStaff> event#TID#</cfif>",
	"color":"<cfif form.hideOther IS "true" AND UserBarcode IS NOT form.id>##DDDDDD<cfelse>#color#</cfif>",
	"noteIcon":"<cfif form.hideOther IS "true" AND UserBarcode IS NOT form.id><cfelse>#noteIcon#</cfif>"
	}<cfif CurrentRow NEQ RecordCount>,</cfif>
</cfoutput>
	]

--->
<cfscript>
bookingsArray=ArrayNew(1);
for (r in Bookings) {
	s=StructNew();
	noteIcon=len(r.Note)?'<div class="noteIcon"></div>':'';
	if (form.hideOther==true && r.UserBarcode!=form.id) titleDesc="";
	else if (form.isStaff==true) titleDesc="#r.FirstName# #r.LastName#";
	else if (form?.id==r.UserBarcode) titleDesc="Your #r.ResourceName# Booking";
	else titleDesc=r.ResourceName;

	s.title=titleDesc;
	s.start=r.StartTime;
	s.end=r.EndTime;
	if (form?.id==r.UserBarcode) borderColor='black';
	if (form?.isStaff==true) {
		s.description='<b>#r.ResourceName#</b>';
		if (len(r.Description)) s.description&=' - #r.Description#';
		s.description&= '<br /><b>#r.FirstName# #r.LastName#</b><br />';
		s.description&=REReplace(trim(r.UserBarcode), "(\d{5})(\d{5})(\d{4})", "\1 \2 \3");
		if (len(r.Note)) s.description&='<br /><b>Note: </b>#r.Note#';
		s.tid=r.TID;
	} else s.description='';
	s.rid=r.RID;
	s.className="resourcebooking Res#r.RID#";
	if (form?.id==r.UserBarcode) s.className&=" yourBooking";
	if (form?.isStaff==true) s.className&=" event#r.TID#";
	s.color=(form?.hideOther==true && r.UserBarcode != form.id)?'##DDDDDD':r.color;
	s.noteIcon=(form?.hideOther==true && r.UserBarcode != form.id)?'':noteIcon;
	ArrayAppend(bookingsArray, s);
}
</cfscript>

<cfoutput>#SerializeJSON(bookingsArray)#</cfoutput>