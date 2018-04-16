<cfset PageTitle="Makerspace Statistics" />

<cfinclude template="/Includes/IntraHeader.cfm" />

<script src="/javascript/jquery.inputmask.bundle.min.js" type="text/javascript"></script>
<script>
$(document).ready(function(){
	$(".datepicker:not([readonly])").datepicker({
	  //yy: four-digit year, M: Three letter month, dd: day number with leading zero
	  dateFormat: "yy-M-dd",
	}).inputmask("9999-aaa-9[9]");
});

</script>



<form class="appForm">
<cfoutput>
<label>From Date: <input class="datepicker" name="from" placeholder="YYYY-Mmm-DD" value="<cfif isDefined('url.from')>#url.from#</cfif>"/></label>
<cfif NOT isDefined('url.from')>
	Please specify from date
</cfif>

<label>To Date: <input class="datepicker" name="to" placeholder="YYYY-Mmm-DD" value="<cfif isDefined('url.to')>#url.to#</cfif>" /></label>
<cfif NOT isDefined('url.to')>
	Please specify to date
</cfif>

<input type="submit" />
</cfoutput>
</form>



<cfif NOT isDefined('url.to') OR NOT isDefined('url.from')>
	<cfinclude template="/Includes/IntraFooter.cfm" />
	<cfabort />
</cfif>




<!--- Loop through all Makerspace Resources --->
<cfquery name="Resources" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerspaceBookingResources r
	JOIN vsd.MakerspaceBookingResourceTypes t ON r.TypeID=t.TypeID
</cfquery>

<cfoutput>

<h1>Makerspace Bookings</h1>

<cfloop query="Resources">

	
<cfquery name="Bookings" dbtype="ODBC" datasource="SecureSource">
	SELECT Count(*) AS Bookings FROM (SELECT *
	FROM vsd.MakerspaceBookingTimes b
	WHERE (RID=#RID#) AND EndTime > '#url.from#' AND startTime < '#url.to#') AS TheBookings
</cfquery>

<cfquery name="Minutes" dbtype="ODBC" datasource="SecureSource">
	SELECT SUM(BookingMinutes) AS Minutes FROM (SELECT *, DATEDIFF(minute, StartTime, EndTime) AS BookingMinutes
	FROM vsd.MakerspaceBookingTimes b
	WHERE (RID=#RID#) AND EndTime > '#url.from#' AND startTime < '#url.to#') AS TheBookings
</cfquery>

<cfquery name="UniqueBarcodes" dbtype="ODBC" datasource="SecureSource">
	SELECT COUNT(DISTINCT UserBarcode) AS UniqueBarcodes
	FROM vsd.MakerspaceBookingTimes b
	WHERE (RID=#RID#) AND EndTime > '#url.from#' AND startTime < '#url.to#'
</cfquery>

<cfif len(Bookings.Bookings) AND Bookings.Bookings GT 0 AND len(Minutes.Minutes) AND Minutes.Minutes GT 0 AND len(UniqueBarcodes.UniqueBarcodes) AND UniqueBarcodes.UniqueBarcodes GT 3>

	<h2>#ResourceName# at #OfficeCode#</h2>
	<table class="altColors padded">
	<tr>
		<th>Bookings</th><td>#Bookings.Bookings#</td>
	</tr>
	<tr>
		<th>Minutes</th><td>#Minutes.Minutes#</td>
	</tr>
	<tr>
		<th>Hours</th><td><cfif IsNumeric(Minutes.Minutes)>#NumberFormat(Minutes.Minutes/60, "9")#</cfif></td>
	</tr>
	<tr>
		<th>Barcodes</th><td>#UniqueBarcodes.UniqueBarcodes#</td>
	</tr>
	</table>

</cfif>

</cfloop>



<h1>Espresso Book Printer Stats</h1>
<cfquery name="EspressoUniqe" dbtype="ODBC" datasource="SecureSource">
	SELECT COUNT(*) AS Books FROM (SELECT * FROM vsd.Espresso
	WHERE CreatedWhen > '#url.from#' AND CreatedWhen < '#url.to#'
	AND TheStatus='Completed'
	) AS TheBooks
</cfquery>

<cfquery name="EspressoPrints" dbtype="ODBC" datasource="SecureSource">
	SELECT SUM(NumberofPrints) AS TotalPrints FROM (SELECT * FROM vsd.Espresso
	WHERE CreatedWhen > '#url.from#' AND CreatedWhen < '#url.to#'
	AND TheStatus='Completed'
	) AS TheBooks
</cfquery>

	<table class="altColors padded">
	<tr>
		<th>Books</th><td>#EspressoUniqe.Books#</td>
	</tr>
	<tr>
		<th>Copies</th><td>#EspressoPrints.TotalPrints#</td>
	</tr>
	</table>


<h1>3D Printer Stats</h1>

<cfquery name="DOrders" dbtype="ODBC" datasource="SecureSource">
	SELECT COUNT(*) AS Orders FROM vsd.ThreeDPrint
	WHERE CreatedWhen > '#url.from#' AND CreatedWhen < '#url.to#' AND TheStatus='Finished'
</cfquery>

<cfquery name="DParts" dbtype="ODBC" datasource="SecureSource">
	SELECT SUM(f.Copies) AS Parts FROM vsd.ThreeDPrintFiles f
	JOIN vsd.ThreeDPrint p ON p.TDID=f.TDID
	WHERE p.CreatedWhen > '#url.from#' AND p.CreatedWhen < '#url.to#' AND TheFileStatus='Completed'
</cfquery>


	<table class="altColors padded">
	<tr>
		<th>Orders</th><td>#DOrders.Orders#</td>
	</tr>
	<tr>
		<th>Parts</th><td>#DParts.Parts#</td>
	</tr>
	</table>


</cfoutput>



<cfinclude template="/Includes/IntraFooter.cfm" />