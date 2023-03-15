# ISEC - AABD

A simple xe oracle database instance to study PL/SQL.

## how to start the oracledb

```
    docker-compose up

    docker exec <container name> ./setPassword.sh <your password>
```


## connecting to the oracledb

```
    SID: XE
    username: system
    password: <your password>
    host: localhost
    port: 1521
```

## database scripts

```
    every script inside the sql folder are pl/sql scripts for oracle db.
    feel free to check them out since they are divided by topics.
```

## Oracle Manager Database Express

> you can access via: localhost:5500/em/
```
    if you acess via website use the following container name:
    CDB$ROOT
```