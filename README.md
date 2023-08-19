## Batch-Pipeline für eine Machine Learning Anwendung

Als Backend für eine datenintensive Machine Learning Applikation zur Betrugserkennung und -prävention soll folgende batch-basierte Datenarchitektur implementiert werden:

![architecture-flowchart drawio (4)](https://github.com/ClaraJozi/data_pipeline/assets/39526169/6e4dedcd-07b5-4f27-903a-ae4bc850743e)

### Gewünschter Output
- eine training_txn Datenbank mit einem public Schema, das vier Tabellen beinhaltet: 
	- _airbyte_raw_credit_card_txns_raw: Rohdaten aus der CSV
	- normalization: normalisierte Daten
   	- stats_total: KPIs nach Datum
   	- stats_geo: KPIs nach Datum und Merchant State
 
  
### Systemvoraussetzungen

- Python 3.9.17
- Ubuntu 20.04.6, 64-bit
- Github Account
- Docker Hub Account

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
- docker-compose.yml Datei

---

### Docker Desktop SetUp
- [Installation von Docker Desktop](https://docs.docker.com/desktop/install/linux-install/) 
- [Credentials Management](https://docs.docker.com/desktop/get-started/#credentials-management-for-linux-users) durch gpg key
<br />

Bei Schwierigkeiten mit dem credential management wurde folgender Fehler angezeigt: 
```
error getting credentials - err: exit status 1, out: `error getting credentials - err: exit status 1, out: `exit status 2: gpg: decryption failed: no secret key
```

Der Fehler konnte mithilfe folgender Schritte behoben werden: 
- Löschung der gespeicherten Docker Credentials
- neue Generierung eines GPG keys
- Speicherung des neuen GPG keys initiiert
- Neustart von Docker Desktop

```
$ rm -rf ~/.password-store/docker-credential-helpers 
$ gpg --generate-key
$ pass init <generated gpg-id public key>
$ systemctl --user start docker-desktop 
```
*Quelle*: *[stack overflow](https://stackoverflow.com/questions/71770693/error-saving-credentials-error-storing-credentials-err-exit-status-1-out)*

<br />

Docker Desktop scheint sich bei Linux auch öfter beim Start aufzuhängen. Wirklich wirkungsvoll war in dem Fall erst einmal nur die De- und Reinstallation von Docker Desktop. 

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

 Während des Airbyte Deployments traten Schwierigkeiten zwischen Airbyte und Docker auf, da ein bestimmter Pfad nicht von Docker erkannt oder nicht für Docker freigegeben worden war. 
 ```
Error response from daemon: Mounts denied: 
The path /tmp is not shared from the host and is not known to Docker.
You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.
See https://docs.docker.com/ for more info.
```
In Docker Desktop kann manuell unter Einstellungen der fehlende path `/tmp` hinzugefügt werden. Nach dem Hinzufügen auf `Apply & Restart` klicken und der Fehler ist behoben.

Wenn `./run-ab-platform.sh` fehlerfrei läuft, kann das Airbyte UI unter http://localhost:8000 geöffnet werden und eine erste Verbindung kann aufgesetzt werden. Der Standard-Benutzername ist `airbyte` und das Standard-Passwort ist `password`. 

<br />

#### 2. [Quelle hinzufügen](https://docs.airbyte.com/quickstart/add-a-source)

In diesem Schritt wird die CSV Datei mit den Kreditkartentransaktionen über Airbyte als Quelle synchronisiert. Die CSV ist lokal gespeichert. Damit Airbyte diese CSV als Quelle synchronisieren kann, muss die Datei in `/tmp/airbyte_local/` verschoben beziehungsweise kopiert werden: 
`cp <lokaler Ordner> /tmp/airbyte_local/`

Im Airbyte UI wird dann Folgendes eingetragen und als Quelle hinzugefügt: 

![Screenshot from 2023-08-11 17-56-50](https://github.com/ClaraJozi/data_pipeline_playground/assets/39526169/4238b402-99ee-44c2-9c04-09e3874680ab)


Der Name des Datasets ist dabei der Name, den wir später für unsere Tabelle benutzen: `credit_card_transactions_raw`

<br />

#### 3. [Ziel hinzufügen](https://docs.airbyte.com/quickstart/add-a-destination)

Nachdem die PostgreSQL-Datenbank wie unter PostgreSQL Setup beschrieben in der `docker-compose.yml` und durch `docker compose up` aufgesetzt wurde, können wir diese als Ziel in Airbyte hinzufügen. In diesem Schritt kann auch definiert werden, ob und welche Verschlüsselungsprotokolle (SSL oder SSH) zur Sicherung der Daten verwendet werden. Das Passwort ist hier das in der `docker-compose.yml` festgelegte Passwort für PostgreSQL: `mysecretpassword`. 

![Screenshot from 2023-08-17 09-42-52](https://github.com/ClaraJozi/data_pipeline/assets/39526169/c7d7bb33-1042-4d5f-ad68-9c7c37873645)


<br />

#### 4. [Verbindung aufsetzen](https://docs.airbyte.com/quickstart/set-up-a-connection)
Abschließend kann unter `Configure connection` festgelegt werden, wie oft zum Beispiel die Verbindung synchronisiert werden soll und ob die Daten in einem JSON blob übertragen werden sollen oder bereits mithilfe von integriertem dbt normalisiert werden sollen. 
![Screenshot from 2023-08-17 10-10-27](https://github.com/ClaraJozi/data_pipeline/assets/39526169/761728fd-bf51-4f6d-bf86-71462ed4cdfa)

![Screenshot from 2023-08-19 18-01-10](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/2938e0bf-bd06-4ef7-827f-367ddedecb1f)

<br />

Zusätzlich zu der Normalisierung der Daten, können in diesem Schritt unter [add transformation](https://docs.airbyte.com/operator-guides/transformation-and-normalization/transformations-with-airbyte/) die eigenen dbt Modelle, die im Rahmen des dbt SetUps kreiert wurden, als Teil eigenes github Repository`s direkt in die Verbindung mitaufgenommen werden. 

![Screenshot from 2023-08-19 17-28-55](https://github.com/ClaraJozi/airbyte-psql-dbt/assets/39526169/a3d35857-8866-4efa-8edd-4ca438deab2e)

Da die integrierte Normalisierung in Airbyte den Daten nicht die gewünschten Datentypen zuweist, ist dem dbt-Setup ein individuell angepasstes SQL-Modell zur Normalisierung beigefügt. 

<br />

---

### PostgreSQL SetUp
PostgreSQL ist auf Ubuntu in der Regel schon vorinstalliert, so dass keine Neuinstallation vorgenommen werden muss. 
PostgreSQL kann deshalb direkt über die Haupt-docker-compose Datei aufgesetzt werden. In der `docker-compose.yml` müssen dafür das offizielle [PostgreSQL-Image](https://hub.docker.com/_/postgres) von Docker sowie die jeweiligen Umgebungsvariablen definiert werden. Der Health Check stellt sicher, dass die PostgreSQL-Datenbank ordnungsgemäß gestartet und einsatzbereit ist, bevor andere Dienste oder Anwendungen, die von dieser Datenbank abhängen, gestartet werden. 
Damit die aufgesetzte Datenbank beim Stoppen von Docker verloren gehen, wird diese auch lokal gespeichert. 

```yml
version: "3.8"

services:
  db:
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
      test: ["CMD-SHELL", "pg_isready -U clara"]
      interval: 60s
      timeout: 30s
      retries: 5

volumes:
  db:
    driver: local
```

<br />

Je nachdem welche Ports in der docker-compose.yml für PostgreSQL festgelegt wurden, kann es zu Konflikten mit dem lokalen PostgreSQL SetUp kommen. Um zu vermeiden, dass beide PostgreSQL Instanzen auf dem selben Port laufen, kann man über `sudo service postgresql stop`  den lokal laufenden PostgreSQL-Datenbankdienst stoppen. 

Nach `docker-compose up` sind in Docker Desktop jetzt sowohl Airbyte als Multi-Container-Anwendung sowie unsere Datenpipeline mit PostgreSQL zu sehen. 

![Screenshot from 2023-08-17 09-11-04](https://github.com/ClaraJozi/data_pipeline/assets/39526169/de81e6c3-d3c5-42e2-8623-561beb16412c)

---

### dbt SetUp
Um dbt lokal aufzusetzen: 
- Installation von [dbt-postgres](https://docs.getdbt.com/docs/core/pip-install)
- `dbt init`, um ein neues dbt-Projekt zu initialisieren
- für unser Projekt werden nur die `.user.yml`, die `profiles.yml`, die `dbt_project.yml` sowie der Ordner `models` mit der `schema.yml` und den SQL Queries für die Modelle benötigt

Am wichtigsten ist dabei die richtige Aufsetzung der `profiles.yml` und der `dbt_project.yml`

1. [profiles.yml](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles)

Die `profiles.yml` ist eine Konfigurationsdatei, in der Informationen über die Verbindungen zu verschiedenen Datenbanken festgehalten werden. Im Wesentlichen werden hier ein Teil der Informationen, die in der `docker-compose.yml` für PostgreSQL festgelegt wurden, wiederholt. 

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

Die dbt_project.yml ist notwendig, damit das Verzeichnis als dbt Projekt erkannt wird und enthält Konfigurationsinformationen, die spezifisch für ein bestimmtes dbt-Projekt gelten. Wichtig ist hierbei, dass der name in der dbt_project.yml `pipeline` mit dem Namen in der `profile.yml` übereinstimmen muss. 

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

Die schema.yml-Datei dazu, Metadaten und Konfigurationen für die Modelle in deinem dbt-Projekt zu definieren. Diese Datei wird in jedem Verzeichnis verwendet, das ein dbt-Modell enthält, und enthält Informationen über die Quellen (Source) und Modelle in diesem Verzeichnis.

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
```
<br />

4. [SQL Modelle](https://docs.getdbt.com/docs/build/sql-models)
   
Die SQL-Modelle in dbt definieren die Transformationslogik für die Daten und können über die bereits definierte Quelldatenbank Daten laden und transformieren. Das SQL Modell selbst ist dabei eine einfache SQL-Query.

Das `stats_total` SQL Modell: 
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

Nachdem das dbt-Projekt so aufgesetzt wurde, kann es in Airbyte jetzt unter `custom transformations` hinzugefügt werden. Die Daten werden dann automatisch bei jeder Synchronisation von der CSV zu PostgreSQL über Airbyte im letzten Schritt transformiert.   


 



