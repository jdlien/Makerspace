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
	<cfinclude template="#app.includes#/appsInitIPLocation.cfm">
	<cfset ThisLocation=session.physicalLocation/>
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
	SELECT *, ISNULL((SELECT TOP 1 1 FROM vsd.MakerspaceBookingResourcesCerts WHERE RID=t.RID), 0) AS hasCert
	FROM MakerSpaceBookingTimes t
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
	// If this resource has certs and they aren't required, show icon if the patron doesn't have the cert
	s.certInfo = "";
	if (r.hasCert==1 && r.RequireCerts!=1) {
		// Look up the patron's certificates
		userResourceCerts = queryExecute("SELECT cc.UserKey, cc.LibraryCard, r.RID, rc.MCID, c.CertiName FROM vsd.MakerspaceBookingResources r
			JOIN vsd.MakerspaceBookingResourcesCerts rc ON rc.RID=r.RID
			JOIN vsd.MakerCerts c ON rc.MCID=c.MCID
			LEFT OUTER JOIN vsd.MakerCertsCustomers cc ON cc.MCID=rc.MCID AND cc.UserKey=#r.UserKey#
			WHERE r.RID=#r.RID#");

			// If any records have a blank userkey (or library card) the user is missing a required cert

		for (c in userResourceCerts) {
			if (c.UserKey == "") {
				if (len(s.certInfo) == 0) s.certInfo = "<b>Missing certs: </b>";
				else s.certInfo &= ", ";
				s.certInfo &= c.CertiName;
			}
		}

	} // end if hasCert and doesn't require it
	if (len(s.certInfo)) s.description &= '<br />#s.certInfo#';
}
</cfscript>

<cfoutput>#SerializeJSON(bookingsArray)#</cfoutput>