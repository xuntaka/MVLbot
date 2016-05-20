.DEFAULT_GOAL := protos

LOCAL_CONF = ${CURDIR}/conf/local.conf

PROTOS    = protos
CONF      = conf
LOGS      = ${CURDIR}/log
SCRIPT    = ${CURDIR}/script
EXEC      = ${CURDIR}/exec
SERVICES  = ${CURDIR}/etc/init

REVISION = ${shell git rev-list HEAD -1}

install:
	@${CURDIR}/install.newbox.sh
	carton install
	@git pull
	@git submodule update --init

logs:
	@tail -F ${LOGS}/*.log

check:
	find lib -name '*.pm' -exec perl -I${CURDIR}/lib -I${CURDIR}/extlib -Mlocal::lib=${CURDIR}/local -c {} \;

test: check
	@script/app test

start: protos stop
	@./start

stop: dirs
	@./stop

protos: dirs
	@protos/make.pl

dirs:
	@mkdir -p ${CONF}
	@mkdir -p ${LOGS}
	@mkdir -p ${SCRIPT}
	@mkdir -p ${EXEC}
	@mkdir -p ${SERVICES}

info:
	@perl -MData::Dumper -e 'warn Dumper \%ENV'

update:
	@git pull

up: update protos

upgrade:
	@carton install --deployment

crontab: protos
	crontab - < conf/crontab.conf

services: protos
	@sudo ./install_services

export
