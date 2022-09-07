# proxysql_experimentation: containers for examining how ProxySQL works

## Summary:
This sets up containers runnning the following:
* Lucee
* ProxySQL
* two MariaDB instances

See `docker/docker-compose.yml` (and linked `Dockerfile`s).

It has some ProxySQL config to test routing SQL statements to either MariaDB as appropriate, via ProxySQL.

See the last section of this document for links to relevant data / config / code that demonstrates how ProxySQL is being used.

Lucee connects to ProxySQL for its datasource, and ProxySQL does the rest.

There are integration tests to prove the rules are working.


## Installation:

### Clone the repo

```
$ pwd
/mnt/c/src/containers
$ git clone git@github.com:adamcameron/proxysql_experimentation.git
```

### Build the containers

```
$ cd proxysql_experimentation/docker
$ pwd
/mnt/c/src/containers/proxysql_experimentation/docker

$ # ./rebuildContainers.sh [lucee admin password] [DB root password] [DB user password]
$ # EG:

$ ./rebuildContainers.sh 12345 123 1234

# [let it run to completion]
# Creating network "proxysql_experimentation_backend" with driver "bridge"
# Creating volume "proxysql_experimentation_mariaDb1Data" with default driver
# Creating volume "proxysql_experimentation_mariaDb2Data" with default driver
# Creating volume "proxysql_experimentation_proxySqlData" with default driver
# Creating proxysql_experimentation_lucee_1    ... done
# Creating proxysql_experimentation_mariadb1_1 ... done
# Creating proxysql_experimentation_proxysql_1 ... done
# Creating proxysql_experimentation_mariadb2_1 ... done

$  docker exec --interactive --tty proxysql_experimentation_lucee_1 /bin/bash
```

### Install TestBox

```
/var/www# box install

# [let it run to completion]
# root@dff6a6b6c395:/var/www# box install
#  √ | Installing ALL dependencies
#    | √ | Installing package [forgebox:testbox@^4.2.1+400]
```

### Run the tests

```
/var/www# box testbox run

# [let it run to completion]
# =================================================================================
# Final Stats
# =================================================================================
#  
# [Passed: 5] [Failed: 0] [Errors: 0] [Skipped: 0] [Bundles/Suites/Specs: 3/3/5]
#  
# TestBox:        v4.5.0+5
# Duration:       207 ms
# CFML Engine:    Lucee 5.3.9.160
# Labels:         None
```

## Test data / config / code

### Data

Each MariaDB server has the same DB (`proxysql_db`), but with slightly different data, just for the purposes of testing. Summarised here:

```
adam@DESKTOP-QV1A45U:/mnt/c/src/containers/proxysql_experimentation/docker$ docker exec --interactive --tty proxysql_experimentation_mariadb1_1 /bin/bash


root@d75c989a7dc7:/# mysql -uproxysql_db_user -p1234

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 97
Server version: 10.9.2-MariaDB-1:10.9.2+maria~ubu2204 mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.



MariaDB [(none)]> use proxysql_db;

Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed


MariaDB [proxysql_db]> show tables;
+-----------------------+
| Tables_in_proxysql_db |
+-----------------------+
| test_both             |
| test_db1_only         |
+-----------------------+
2 rows in set (0.000 sec)


MariaDB [proxysql_db]> select * FROM test_both;
+-----+---------------------------+
| id  | value                     |
+-----+---------------------------+
| 101 | Test row 1 (DB1 instance) |
| 102 | Test row 2 (DB1 instance) |
+-----+---------------------------+
2 rows in set (0.001 sec)


MariaDB [proxysql_db]> select * FROM test_db1_only;
+-----+-----------------------+
| id  | value                 |
+-----+-----------------------+
| 101 | Test row 1 (DB1 only) |
| 102 | Test row 2 (DB1 only) |
+-----+-----------------------+
2 rows in set (0.000 sec)

MariaDB [proxysql_db]>
```

That's from `mariadb1`. `mariadb2` is basically the same, but references to `DB1` are `DB2`.

See `docker/mariadb1/docker-entrypoint-initdb.d/1.createAndPopulateTestTable.sql` and `docker/mariadb2/docker-entrypoint-initdb.d/1.createAndPopulateTestTable.sql` for the initialisation of this data in the DBs.


### ProxySQL config

`/etc/proxysql.cnf` (`docker/proxysql/conf/proxysql.cnf` in this project) has the following rules:

```
mysql_servers=({
    hostname="database1.backend"
    port=33061
    hostgroup=1
},{
    hostname="database2.backend"
    port=33062
    hostgroup=2
})

# ...

mysql_query_rules=({
    rule_id=1
    active=1
    match_pattern="test_db1_only"
    destination_hostgroup=1
    apply=1
},{
    rule_id=2
    active=1
    match_pattern="test_db2_only"
    destination_hostgroup=2
    apply=1
})
```

So queries referencing table `test_db1_only` will be sent to `mariadb1` (as per above, this table only exists on `mariadb1`); likewise queries to `test_db2_only` will be sent to `mariadb2`.

Anything else will by default go to `mariadb1`.


### Tests

There are tests proving this:

```
// test/integration/db/ProxySqlTest.cfc
import testbox.system.BaseSpec

component extends=BaseSpec {

    function run() {
        describe("Tests ProxySQL", () => {
            it("hits DB1 for queries of test_db1_only", () => {
                result = queryExecute("SELECT * FROM test_db1_only ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB1 only")).toHaveLength(2)
            })
            it("hits DB2 for queries of test_db2_only", () => {
                result = queryExecute("SELECT * FROM test_db2_only ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB2 only")).toHaveLength(2)
            })
            it("hits DB1 for other queries", () => {
                result = queryExecute("SELECT * FROM test_both ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB1 instance")).toHaveLength(2)
            })
        })
    }
}
```

These tests query relevant tables, and check that the data has come back from the expected DB server.

### Application config

From `Application.cfc` :

```
private void function loadDataSources() {
    this.datasources[this.name] = {
        type = "mysql",
        host = "proxysql.backend",
        port = 6033,
        database = "proxysql_db",
        username = "proxysql_db_user",
        password = server.system.environment.MARIADB_PASSWORD,
        custom = {
            useUnicode = true,
            characterEncoding = "UTF-8",
            noAccessToProcedureBodies = true
        }
    }

    this.datasource = this.name
}
```

Note that this is connecting to `proxysql.backend` and on `6033`. It is not directly connecting to the MariaDB databases. Lucee is unaware there is a proxy.
