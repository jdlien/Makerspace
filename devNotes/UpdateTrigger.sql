DROP TABLE vsd.MakerspaceUpdates
CREATE TABLE vsd.MakerspaceUpdates (
	OfficeCode varchar(4) NOT NULL,
	--RID INT NOT NULL,
	Seq int DEFAULT 0,
	Updated DATETIME DEFAULT GETDATE()
)

--DROP TRIGGER vsd.MakerspaceUpdatesTrigger
/* Holy crap, this actually works... just not for deletes */
CREATE TRIGGER vsd.MakerspaceUpdatesTrigger ON vsd.MakerspaceBookingTimes
BEFORE INSERT, UPDATE, DELETE AS
BEGIN
IF NOT EXISTS (SELECT ty.OfficeCode FROM vsd.MakerspaceUpdates u
	JOIN inserted i ON i.TID=i.TID
	JOIN vsd.MakerspaceBookingResources r ON i.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID
	AND ty.OfficeCode=u.OfficeCode)
    INSERT INTO vsd.MakerspaceUpdates (OfficeCode) VALUES(
	(SELECT ty.OfficeCOde FROM inserted i
	JOIN vsd.MakerspaceBookingResources r ON i.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID)
	);

	UPDATE vsd.MakerspaceUpdates SET Seq=Seq+1, Updated = GETDATE()
	FROM vsd.MakerspaceUpdates u
	JOIN inserted i ON i.TID=i.TID
	JOIN vsd.MakerspaceBookingResources r ON i.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID
	AND ty.OfficeCode=u.OfficeCode
END

SELECT * FROM vsd.MakerspaceUpdates