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
AFTER INSERT, UPDATE AS
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

--DROP TRIGGER vsd.MakerspaceDeleteTrigger 
CREATE TRIGGER vsd.MakerspaceDeleteTrigger ON vsd.MakerspaceBookingTimes
AFTER DELETE AS
BEGIN
IF NOT EXISTS (SELECT ty.OfficeCode FROM vsd.MakerspaceUpdates u
	JOIN deleted d ON d.TID=d.TID
	JOIN vsd.MakerspaceBookingResources r ON d.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID
	AND ty.OfficeCode=u.OfficeCode)
    INSERT INTO vsd.MakerspaceUpdates (OfficeCode) VALUES(
	(SELECT ty.OfficeCOde FROM deleted d
	JOIN vsd.MakerspaceBookingResources r ON d.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID)
	);

	UPDATE vsd.MakerspaceUpdates SET Seq=Seq+1, Updated = GETDATE()
	FROM vsd.MakerspaceUpdates u
	JOIN deleted d ON d.TID=d.TID
	JOIN vsd.MakerspaceBookingResources r ON d.RID=r.RID
	JOIN vsd.MakerspaceBookingResourceTypes ty ON ty.TypeID=r.TypeID
	AND ty.OfficeCode=u.OfficeCode

/*	DELETE t FROM vsd.MakerspaceBookingTimes t 
	JOIN deleted d ON d.TID=t.TID
	WHERE t.TID=d.TID
*/
END


SELECT * FROM vsd.MakerspaceUpdates WHERE OfficeCode='MNP'

SELECT * FROM vsd.MakerspaceBlockedTimes


CREATE TRIGGER vsd.MakerspaceBlockedUpdatesTrigger ON vsd.MakerspaceBlockedTimes
AFTER INSERT, UPDATE AS
BEGIN
IF NOT EXISTS (SELECT i.OfficeCode FROM vsd.MakerspaceUpdates u
	JOIN inserted i ON i.OfficeCode=u.OfficeCode
	AND i.OfficeCode=u.OfficeCode)
    INSERT INTO vsd.MakerspaceUpdates (OfficeCode) VALUES((SELECT OfficeCode FROM inserted));

	UPDATE vsd.MakerspaceUpdates SET Seq=Seq+1, Updated = GETDATE()
	FROM vsd.MakerspaceUpdates u
	JOIN inserted i ON i.OfficeCode=u.OfficeCode
	AND i.OfficeCode=u.OfficeCode
END


CREATE TRIGGER vsd.MakerspaceBlockedDeleteTrigger ON vsd.MakerspaceBlockedTimes
AFTER DELETE AS
BEGIN
IF NOT EXISTS (SELECT d.OfficeCode FROM vsd.MakerspaceUpdates u
	JOIN deleted d ON d.OfficeCode=u.OfficeCode
	AND d.OfficeCode=u.OfficeCode)
    INSERT INTO vsd.MakerspaceUpdates (OfficeCode) VALUES((SELECT OfficeCode FROM inserted));

	UPDATE vsd.MakerspaceUpdates SET Seq=Seq+1, Updated = GETDATE()
	FROM vsd.MakerspaceUpdates u
	JOIN deleted d ON d.OfficeCode=u.OfficeCode
	AND d.OfficeCode=u.OfficeCode
END



--JDL: 2019-12-06 added suppport for multiple certs in makerspace booking resources
CREATE TABLE vsd.MakerspaceBookingResourcesCerts (
	RID INT FOREIGN KEY REFERENCES vsd.MakerspaceBookingResources(RID),
	MCID INT FOREIGN KEY REFERENCES vsd.MakerCerts(MCID),
	ModifiedBy varchar(30) NOT NULL,
	Modified DATETIME NOT NULL
)


ALTER TABLE vsd.MakerspaceBookingResources ADD RequireCerts bit NULL