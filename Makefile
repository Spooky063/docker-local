DBUSER := root
DBPASS := root

CC := docker-compose
CMYSQL := local_mariadb
CPHP := local_php_apache

HELP_FUN = \
    %help; \
    while(<>) { \
        if(/^([a-z0-9_-]+):.*\#\#(?:@(\w+))?\s(.*)$$/) { \
            push(@{$$help{$$2 // 'options'}}, [$$1, $$3]); \
        } \
    }; \
    print "usage: make [target]\n\n"; \
    for ( sort keys %help ) { \
        print "$$_:\n"; \
        printf("\033[36m  %-20s %s\033[0m\n", $$_->[0], $$_->[1]) for @{$$help{$$_}}; \
        print "\n"; \
    }

.PHONY: db db_create db_import db_drop db_drop_table db_db_exec db_size db_db_size db php cli pma

help:
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

db_create: ##@db Créer une base de donnée du nom passé en paramètre - DBNAME=test
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e 'CREATE DATABASE IF NOT EXISTS `$(DBNAME)`'

db_import: db_create ##@db Créer et importe une base de données *.sql - FILE=dumps/test.sql DBNAME=test
	cat $(FILE) | $(CC) exec -T $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) $(DBNAME)

db_zimport: db_create ##@db Créer et importe une base de données *.sql.gz - FILE=dumps/test.sql.gz DBNAME=test
	zcat $(FILE) | $(CC) exec -T $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) $(DBNAME)

db_drop: ##@db Supprime une base de donnée du nom passé en paramètre - DBNAME=test
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e 'DROP DATABASE `$(DBNAME)`'

db_drop_table: ##@db_tool Supprime toutes les tables d'une base de données passé en paramètre -- DBNAME=test
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -Nse 'SHOW TABLES' $(DBNAME) | while read table; do \
	$(CC) exec -T $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e "DROP TABLE $$table" $(DBNAME); done

db_exec: ##@db Execute une requête global - QUERY="SHOW DATABASES"
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e '$(QUERY)'

db_size: ##@db_tool Affiche la taille des bases de données
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e "SELECT table_schema AS 'Database', SUM(data_length + index_length) / 1024 / 1024 AS 'Size (MB)' FROM information_schema.TABLES GROUP BY table_schema ORDER BY 2;"

db_db_size: ##@db_tool Affiche la taille de toutes les tables d'une base de données passée en paramètre - DBNAME=test
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e "SELECT table_schema as 'Database', table_name AS 'Table', round(((data_length + index_length) / 1024 / 1024), 2) 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = '$(DBNAME)' ORDER BY (data_length + index_length) ASC;"

db_db_cache: ##@db_tool Affiche toutes les requêtes pour effacer les caches d'une base de données passée en paramètre -- BDNAME=test
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS) -e "SELECT CONCAT('TRUNCATE TABLE ', TABLE_NAME, ';') AS 'Mess' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$(DBNAME)' AND (TABLE_NAME LIKE '%_cache_%' OR TABLE_NAME LIKE '%_webprofiler')"

db: ##@container Lance un shell sur le container mysql
	$(CC) exec $(CMYSQL) /usr/bin/mysql -u $(DBUSER) --password=$(DBPASS)

php: ##@container Lance un shell sur le container php
	$(CC) exec $(CPHP) bash

pma: ##@container Ouvre un navigateur avec pma
	python -m webbrowser -t "http://localhost:8080/" >/dev/null 2>&1

