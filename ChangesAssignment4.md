1. Seite 7, Listing 5: 
   "withdrawel" spelling correction (Kommentar Index 8.1)
   -> "withdrawal_sum"
   -> "withdrawal_count"

2. Seite 4, 2.3 Vererbung
   Transaction logic correction (Kommentar Index 5.2)
   
   Im PAYMENT_TRANSACTION Subtyp wurde `external_iban` und `external_bic` in `target_iban` und `target_bic` umbenannt, damit auch 
   interne Transaktionen abgebildet werden können, ohne das Design der `TRANSACTION` vollständig zu ändern.
   
   Außerdem wurde eine 1:N Beziehung von ```ACCOUNT```zu ```PAYMENT_TRANSACTION``` namens ```TARGET_ACCOUNT_IBAN_FK``` hinzugefügt, bei der Ziel und Quelle optional sind. Bei internen Transaktionen kann somit das Empfänger-Konto aus der eigenen Account Liste per Fremdschlüssel direkt verknüpft werden, während bei external Transactions target_iban und target_bic notwendig sind um auf andere Konten zu überweisen. Die Beziehung wird also letztendlich nur genutzt, wenn ein IBAN einem IBAN entspricht, den wir selbst verwalten.

3. Seite 4, 2.3 Vererbung
   "Referenzkonto ist nicht modelliert" (Kommentar Index 5.1)
   
   Wenn ein Customer unserer Bank mehrere Sparkonten hat und von Sparkonto A sich etwas aufs Sparkonto B überweisen möchte, geht das nicht direkt sondern muss über das Girokonto gebucht werden. Dementsprechend brauchen wir einen REFERENZ_IBAN und eine Beziehung für einen REFERENZKONTO_FK, um bei mehreren Konten des Kunden die "Drehscheibe" für Auszahlungen oder ähnliches festzulegen.
   
   So bin ich vorgegangen:
   - 1:N Beziehung von ACCOUNT zu ACCOUNT namens REFERENZKONTO_FK
   - Quelle optional (ein Girokonto muss nicht selbst ein Referenzkonto für ein anderes sein) Ziel optional (ein Main-Girokonto hat selbst kein Referenzkonto, nur Spar/Depot)
   - Name in Quelle: `referenziert
   - Name in Ziel: `referenz_konto`. Wird in der Tabelle durch den PK von `ACCOUNT` zu `REFERENZ_KONTO_IBAN`

4. Seite 3, 2. ER-Modell und Datenbankstruktur (Kommentar Index 4.1) 
	
	Das Problem: Ein _Unique Constraint_ (Eindeutigkeits-Regel) sorgt dafür, dass eine Kombination von Werten nur ein einziges Mal in der Tabelle vorkommen darf. In deinem aktuellen Modell steht im Bericht (Seite 12), dass die Kombination aus `depot_iban`, `STOCK_isin` und `purchase_date` eindeutig sein muss.

	- **Beispiel für den Fehler:** Du kaufst am 10. April morgens 5 Apple-Aktien (ISIN: US0378331005). Am Nachmittag fällt der Kurs und du kaufst nochmal 10 Stück.
    
	- **Die Folge:** Die Datenbank vergleicht: `AT..123` (Depot) + `US..1005` (Aktie) + `2026-04-10` (Datum). Da diese Kombination vom Morgen schon existiert, blockiert die Datenbank den zweiten Kauf mit einem Fehler.
	  

5. Zu Kommentar 4.2: Die fehlende Verbindung (Depot-Transaktion)
	
	**Das Problem:** Du hast zwar eine Tabelle `STOCK_TRANSACTION`, aber diese weiß momentan nur, _welche_ Aktie gekauft wurde. Der Korrektor bemängelt, dass nicht direkt ersichtlich ist, für welches **Depot** diese Transaktion war.
	
	Zwar hängen `DEPOT` und `TRANSACTION` beide am `ACCOUNT`, aber der Weg über das Konto ist zu ungenau, besonders wenn ein Kunde mehrere Depots hätte. Eine Transaktion muss "wissen", in welchen "Behälter" (Depot) sie die Aktien legt.
	
	**Die Änderung im Data Modeler:**
	
	1. Wähle eine **1:N Beziehung** (Nicht-identifizierend).
	    
	2. **Quelle:** Die Entität `AKTIENDEPOT` (oder der Subtyp von Account).
	    
	3. **Ziel:** Die Entität `STOCK_TRANSACTION`.
	    
	4. **Name der Beziehung:** `DEPOT_STOCK_TR_FK`.
	    
	5. **Optionalität:** * Quelle optional: Ja (Ein Depot kann existieren, ohne dass bisher eine Aktientransaktion stattfand).
	    
	    - Ziel optional: Nein (Mandatory) – Jede Aktientransaktion **muss** zwingend einem Depot zugeordnet sein.
	        
	
	**Der Effekt:** In deiner Tabelle `STOCK_TRANSACTION` entsteht dadurch eine neue Spalte (z. B. `DEPOT_IBAN_FK`).
	
	- Wenn du jetzt eine Aktie kaufst, steht in der Transaktion: "Ich habe 10x Apple gekauft für das Depot AT..888".
	    
	- Damit ist die Kette geschlossen: `TRANSACTION` -> `DEPOT` -> `STOCK`.
	    
	
	Warum ist das für deinen SQL-Code (DML) wichtig?
	
	Wenn du später einen Kauf tätigst (wie in deinem Listing 12 im PDF), musst du sicherstellen, dass die `transaction_id`und die `depot_iban` zusammenpassen. Der Korrektor möchte sehen, dass du vom Depot aus alle zugehörigen Käufe und Verkäufe direkt über eine einfache Abfrage finden kannst, ohne über drei Ecken (den Kunden) suchen zu müssen.
	
	**Zusammenfassend:** 1. Locker den Constraint bei den Depot-Positionen (Zeitstempel statt nur Datum). 2. Zieh die Linie vom Aktiendepot zur Aktientransaktion, damit die Zuordnung "Was wurde für wen gekauft?" bombenfest ist.
	
