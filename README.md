## Batch-Pipeline für eine Machine Learning Anwendung

Als Backend für eine datenintensive Machine Learning Applikation zur Betrugserkennung und -prävention soll folgende batch-basierte Datenarchitektur implementiert werden:

![final_datenarchitektur](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/f2579a66-bc7d-45c8-8d1c-9d2041d053a2)


### Gewünschter Output
Eine erfolgreiche Synchronisation und Transformation via Airbyte und dbt: 
![airbyte_final_sync](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/614f2f06-94bd-4a0e-925b-a7c0ffd0ade3)

Eine `training_txn` Datenbank mit einem public Schema, das fünf Tabellen enthält: 
- `_airbyte_raw_credit_card_txns_raw:` Rohdaten aus der CSV
- `normalization`: normalisierte Daten
- `stats_total`: KPIs nach Datum
- `stats_geo`: KPIs nach Datum und Merchant State & City
- `stats_txn_type`: KPIs nach Datum und Transaktionstyp

![dbeaver_output_final](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/f64fde97-7804-4322-9103-bf0149a7557c)


### Systemvoraussetzungen

- Python 3.9.17
- Ubuntu 20.04.6, 64-bit
- Github Account
- Docker Hub Account
- VS Code

### Tech Stack
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) mit Docker Engine und Docker Compose
- [Airbyte](https://airbyte.com/)
- [PostgreSQL](https://www.postgresql.org/download/linux/ubuntu/)
- [dbt](https://www.getdbt.com/)

### Testdatensatz
- [Kreditkartentransaktionen zur Betrugserkennung](https://www.kaggle.com/datasets/ealtman2019/credit-card-transactions)
---

### Repository SetUp
- geklontes Airbyte Repository
- dbt Ordner
- .gitignore Datei
- README.md
- docker-compose.yml Datei
- test.csv Datei

---
### Datensatz
Der Datensatz ist aufgrund seiner Größe (2.35GB) nicht in dem Repository enthalten. Über Kaggle kann [hier](https://www.kaggle.com/datasets/ealtman2019/credit-card-transactions) aber die csv-Datei `credit_card_transactions-ibm_v2` heruntergeladen werden. Am besten wird die Datei dann direkt in das geklonte Repository abgelegt, so dass sie unter `./airbyte-psql-dbt/credit_card_transactions-ibm_v2.csv` zu finden ist. 

Da die Pipeline für die Verarbeitung des Originaldatensatzes ca 2½ Stunden braucht, ist dem Repository eine kleinere Testdatei beigefügt.

---
### Docker Desktop SetUp in Ubuntu
- [Installation von Docker Desktop](https://docs.docker.com/desktop/install/linux-install/) 
- [Credentials Management](https://docs.docker.com/desktop/get-started/#credentials-management-for-linux-users) durch gpg key
<br />

> 🚧👷‍♀️
>
> Bei Schwierigkeiten mit dem credential management wurde folgender Fehler angezeigt: 
> ```
> error getting credentials - err: exit status 1, out: `error getting credentials - err: exit status 1, out: `exit status 2: gpg: decryption failed: no secret > key
> ```
> 
> Der Fehler konnte mithilfe folgender Schritte behoben werden: 
> - Löschung der gespeicherten Docker Credentials
> - neue Generierung eines GPG keys
> - Speicherung des neuen GPG keys initiiert
> - Neustart von Docker Desktop
> 
> ```
> $ rm -rf ~/.password-store/docker-credential-helpers 
> $ gpg --generate-key
> $ pass init <generated gpg-id public key>
> $ systemctl --user start docker-desktop 
> ```
> *Quelle*: *[stack overflow](https://stackoverflow.com/questions/71770693/error-saving-credentials-error-storing-credentials-err-exit-status-1-out)*

<br />

> ℹ️
> 
> Docker Desktop scheint sich bei Linux auch öfter beim Start aufzuhängen. Wirklich wirkungsvoll waren in dem Fall erst einmal nur die De- und Reinstallation von Docker Desktop. 

<br />

---

### Airbyte SetUp
#### 1. [Airbyte Deployment](https://docs.airbyte.com/quickstart/deploy-airbyte/)
```
$ git clone https://github.com/airbytehq/airbyte.git
$ cd airbyte
$ ./run-ab-platform.sh
```
<br />

> 🚧👷‍♀️
>
> Während des Airbyte Deployments traten Schwierigkeiten zwischen Airbyte und Docker auf, da ein bestimmter Pfad nicht von Docker erkannt oder nicht für Docker freigegeben worden war. 
>  ```
> Error response from daemon: Mounts denied: 
> The path /tmp is not shared from the host and is not known to Docker.
> You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.
> See https://docs.docker.com/ for more info.
> ```
> In Docker Desktop kann manuell unter Einstellungen der fehlende path `/tmp` hinzugefügt werden. Nach dem Hinzufügen auf `Apply & Restart` klicken, und der Fehler ist behoben.

<br />

Wenn `./run-ab-platform.sh` fehlerfrei läuft, kann das Airbyte UI unter http://localhost:8000 geöffnet werden, und eine erste Verbindung kann aufgesetzt werden. Der Standard-Benutzername ist `airbyte`, und das Standard-Passwort ist `password`. 

<br />

#### 2. [Quelle hinzufügen](https://docs.airbyte.com/quickstart/add-a-source)

In diesem Schritt wird die CSV Datei mit den Kreditkartentransaktionen über Airbyte als Quelle synchronisiert. Die CSV ist lokal gespeichert. Damit Airbyte diese CSV als Quelle synchronisieren kann, muss die Datei in `/tmp/airbyte_local/` verschoben beziehungsweise kopiert werden: 
`cp <./airbyte-psql-dbt/credit_card_transactions-ibm_v2.csv> /tmp/airbyte_local/`

Im Airbyte UI wird dann Folgendes eingetragen und als Quelle hinzugefügt: 

![airbyte_source](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/9cbfcf2e-fe59-43bb-abe9-f7b4db1ba21a)

Angaben für Kreditkartentransaktionen-Datei: 
```yml
Dataset Name: credit_card_txns_raw
File Format: CSV
Storage Provider: Local Filesystem
URL: /local/credit_card_transactions-ibm_v2.csv
```

<br />

#### 3. [Ziel hinzufügen](https://docs.airbyte.com/quickstart/add-a-destination)

Nachdem die PostgreSQL-Datenbank, wie unter PostgreSQL Setup beschrieben, in der `docker-compose.yml` und durch `docker compose up` aufgesetzt wurde, können wir sie als Ziel in Airbyte hinzufügen. In diesem Schritt kann auch definiert werden, ob und welche Verschlüsselungsprotokolle (SSL oder SSH) zur Sicherung der Daten verwendet werden. Das Passwort ist hier das in der `docker-compose.yml` festgelegte Passwort für PostgreSQL: `mysecretpassword`. 

![airbyte_destination](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/1e0efdbc-4459-481a-931d-2fad7bd0b380)

Angaben für Kreditkartentransaktionen-Datei: 
```yml
Destination name: Postgres
Host: localhost
Port: 5432
DB Name: training_txn
Default schema: public
User: clara
SSL modes: prefer
SSH tunnel: No Tunnel
Password: mysecretpassword
Activate SSL Connection
```
<br />

#### 4. [Verbindung aufsetzen](https://docs.airbyte.com/quickstart/set-up-a-connection)
Abschließend kann unter `Configure connection` festgelegt werden, wie oft zum Beispiel die Verbindung synchronisiert werden soll und ob die Daten in einem JSON blob übertragen oder bereits mithilfe von integriertem dbt normalisiert werden sollen. 
![airbyte_configuration](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/ed34ffba-5242-4bad-8b30-3cff1f7ab7b5)

![Screenshot from 2023-08-19 18-01-10](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/2938e0bf-bd06-4ef7-827f-367ddedecb1f)

<br />

Zusätzlich zu der Normalisierung der Daten können in diesem Schritt unter `custom transformations` und [add transformation](https://docs.airbyte.com/operator-guides/transformation-and-normalization/transformations-with-airbyte/) die eigenen dbt Modelle, die im Rahmen des dbt SetUps kreiert wurden, als Teil eines Github Repository direkt in die Verbindung mitaufgenommen werden. 



Da die integrierte Normalisierung in Airbyte den Daten nicht die gewünschten Datentypen zuweist, ist dem dbt-Setup ein individuell angepasstes SQL-Modell zur Normalisierung beigefügt. 

![dbt_transformation](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/bcfab96c-456d-463d-8959-8e21537a43cf)

<br />

```yml
Transformation name: dbt_transformation
Transformation type: Custom DBT
Docker image URL with dbt installed: ghcr.io/dbt-labs/dbt-postgres:1.6.0
Entrypoint arguments for dbt cli to run the project: run --project-dir dbt
Git repository URL of the custom transformation project: https://github.com/ClaraJozi/airbyte-psql-dbt.git
```

<br />

---

### PostgreSQL SetUp
PostgreSQL ist auf Ubuntu in der Regel schon vorinstalliert, so dass keine Neuinstallation vorgenommen werden muss. 
PostgreSQL kann deshalb direkt über die Haupt-docker-compose Datei aufgesetzt werden. In der `docker-compose.yml` müssen dafür das offizielle [PostgreSQL-Image](https://hub.docker.com/_/postgres) von Docker sowie die jeweiligen Umgebungsvariablen definiert werden. Der Health Check stellt sicher, dass die PostgreSQL-Datenbank ordnungsgemäß gestartet wird und einsatzbereit ist, bevor andere Dienste oder Anwendungen, die von dieser Datenbank abhängen, gestartet werden. 
Damit die aufgesetzte Datenbank beim Stoppen von Docker nicht verloren geht, wird diese auch lokal gespeichert. 

```yml
version: "3.8"

services:
  db:
    container_name: postgres
    image: postgres:latest
    restart: always
    environment:
      - POSTGRES_USER=clara
      - POSTGRES_PASSWORD=mysecretpassword
      - POSTGRES_DB=training_txn
    ports:
      - '5432:5432'
    volumes:
      - ./postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL"]
      interval: 60s
      timeout: 30s
      retries: 5
```

<br />

> 🚧👷‍♀️
>
> Je nachdem, welche Ports in der `docker-compose.yml` für PostgreSQL festgelegt wurden, kann es zu Konflikten mit dem lokalen PostgreSQL SetUp kommen. Um zu vermeiden, dass beide PostgreSQL Instanzen auf demselben Port laufen, kann man über `sudo service postgresql stop`  den lokal laufenden PostgreSQL-Datenbankdienst stoppen. 

<br />

Nach `docker-compose up` sind in Docker Desktop jetzt sowohl Airbyte als Multi-Container-Anwendung sowie unsere Datenpipeline mit PostgreSQL zu sehen. 

![Screenshot from 2023-08-19 17-45-55](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/328768a9-e647-43e3-8d38-e47e2630e8e7)


---

### [dbt SetUp](https://docs.airbyte.com/operator-guides/transformation-and-normalization/transformations-with-dbt/)
dbt ist bereits in Airbyte integriert. Das heißt, dass Airbyte automatisch nach dem Laden der Daten in PostgreSQL dbt-Transformationen vornehmen kann, indem es selbst eine dbt Docker-Instanz und ein dbt-Projekt generiert. dbt muss deswegen nicht in die `docker-compose.yml`, in der PostgreSQL aufgesetzt wird, integriert werden. 

Airbyte benötigt für individuell angepasste Transformationen nur ein Github-Repository, in dem Dateien wie die `profiles.yml`, `dbt_project.yml` und der Ordner `models` mit der `schema.yml` und den SQL-Modellen enthalten sind. 

1. [profiles.yml](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles)

Die `profiles.yml` ist eine Konfigurationsdatei, in der Informationen über die Verbindungen zu verschiedenen Datenbanken festgehalten werden. Im Wesentlichen wird hier ein Teil der Informationen, die in der `docker-compose.yml` für PostgreSQL festgelegt wurden, wiederholt. 

```yml
pipeline:
  outputs:

    dev:
      type: postgres
      threads: 1
      host: localhost
      port: 5432
      user: clara
      pass: mysecretpassword
      dbname: training_txn
      schema: public

  target: dev
```

<br />
   
2. [dbt_project.yml](https://docs.getdbt.com/reference/dbt_project.yml)

Die dbt_project.yml ist notwendig, damit das Verzeichnis als dbt Projekt erkannt wird, und enthält Konfigurationsinformationen, die spezifisch für ein bestimmtes dbt-Projekt gelten. Wichtig ist hierbei, dass der `name` in der dbt_project.yml `pipeline` mit dem Namen in der `profile.yml` übereinstimmen muss. 

```yml
name: 'data_pipeline'
profile: 'pipeline'

config-version: 2
version: '0.1'

model-paths:
  - "models"

target-path: "target"
log-path: "logs"
packages-install-path: "dbt_modules"

clean-targets:
  - "target"
  - "dbt_modules"

quoting:
  database: false
  schema: false
  identifier: false

models:
  materialized: table
```

<br />

3. schema.yml

Die `schema.yml` Datei dient dazu, Metadaten und Konfigurationen für die Modelle in deinem dbt-Projekt zu definieren. Diese Datei wird in jedem Verzeichnis verwendet, das ein dbt-Modell enthält, und gitbt Auskunft über die Quellen (Source) und Modelle in diesem Verzeichnis.

Zum Beispiel: 

```yml
version: 2

sources:
  - name: training_txn
    description: PostgreSQL database used for training data from credit card transactions CSV for ML model 
    tables:
      - name: _airbyte_raw_credit_card_txns_raw
        identifier: training_txn.public._airbyte_raw_credit_card_txns_raw
        columns:
          - name: _airbyte_ab_id
            description: uuid value assigned by connectors to each row of the data written in the destination
            tests:
              - unique
              - not_null
          - name: _airbyte_data
            description: all the data from the CSV stored as JSON blob
            tests: 
              - not_null
          - name: _airbyte_emitted_at
            description: time at which the record was emitted and recorded by destination connector of Airbyte
            tests:
              - not_null

models:
  - name: normalization
    description: normalization of data from Airbyte
    sql: models/normalization.sql
    columns:
      - name: id
        tests:
          - unique
          - not_null
      - name: cc_owner
        tests: 
          - not_null
      - name: ccard
        tests: 
          - not_null
      - name: year
      - name: month
      - name: day
      - name: full_date
        tests: 
          - not_null
```
<br />

4. [SQL Modelle](https://docs.getdbt.com/docs/build/sql-models)
   
Die SQL-Modelle in dbt definieren die Transformationslogik für die Daten und können über die bereits definierte Quelldatenbank und -tabelle Daten laden und transformieren. Das SQL-Modell selbst ist dabei eine einfache SQL-Query. 
Für dieses Projekt wurden insgesamt vier Modelle generiert, die am Ende als Tabellen zusätzlich zu den Rohdaten in PostgreSQL zu sehen sind: 
- normalisation: individuell angepasste Normalisierung der Rohdaten
- stats_total: Aggregationen nach Datum der Transaktion sortiert
- stats_geo: Aggregationen nach Datum der Transaktion und geographischen Datenpunkten sortiert
- stats_txn_type: Aggregationen nach Datum der Transaktion und Transaktionstyp sortiert 


Das `stats_total` SQL-Modell sieht zum Beispiel so aus: 
```SQL
select 
	full_date, 
	year, 
	month, 
	day, 
	count(distinct cc_owner) as cc_owner_cnt, 
	count(*) as txn_cnt, 
	sum(dollar_amount) as amount_sum, 
	sum(case when is_fraud is true then 1 else 0 end) as fraud_cnt, 
	1.00*sum(case when is_fraud is true then 1 else 0 end)/count(*) as fraud_rate_cnt, 
	sum(case when is_fraud is true then dollar_amount else 0 end) as fraud_vol,
	1.00*sum(case when is_fraud is true then dollar_amount else 0 end)/sum(dollar_amount) as fraud_rate_vol,
	avg(case when is_fraud is false then dollar_amount else 0 end) as avg_amount_non_fraud,
	avg(case when is_fraud is true then dollar_amount else 0 end) as avg_amount_fraud
from {{ ref('normalization') }}
group by 1,2,3,4
order by 1 desc
```

Nachdem das dbt-Projekt so aufgesetzt wurde, kann es in Airbyte jetzt unter `custom transformations` (siehe `Verbindung aufsetzen`) hinzugefügt werden. Die Daten werden dann automatisch bei jeder Synchronisation von CSV zu PostgreSQL über Airbyte im letzten Schritt transformiert.   

<br />

---

### Test der Pipeline mit test.csv

Zum Testen der Pipeline wurde ein kleines Sample der Originaldatei benutzt. 
Damit die Pipeline mit der test.csv laufan kann, müssen ein paar kleine Änderungen vorgenommen werden: 
1. Verschieben der Datei in `/tmp/airbyte_local/`
Die test.csv kann mithilfe von `cp ./airbyte-psql-dbt/test.csv /tmp/airbyte_local` kopiert werden.
<br />

2. Änderung der Quelle im Airbyte UI
![airbyte_test_source](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/b9e2b8b8-02a4-4ca5-b526-d647176d73e4)
```yml
Dataset Name: test
File Format: CSV
Storage Provider: Local Filesystem
URL: /local/test.csv
```
<br />

3. Anpassung des dbt-Modells in `./dbt/models/normalization.sql`

Damit die dbt-Transformationen für die test.csv laufen können, muss die Quelltabelle (source table) im dbt Normalisierung-Modell geändert werden. Dafür muss `FROM _airbyte_raw_credit_card_txns_raw` durch `FROM _airbyte_raw_test` ersetzt werden. 

Erkennen lässt sich das erfolgreiche Laufen der Test-Pipeline wie folgt: 
![airbyte_on_time_result](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/e9ce7cf5-f7a3-4972-a004-7418382e49ee)

Gewünschter Output für den Test: 

![test_output](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/12fc69c7-fa5d-46b3-850b-efa4b2c86764)


 



