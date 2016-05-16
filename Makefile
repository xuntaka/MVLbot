.DEFAULT_GOAL := protos

LOCAL_CONF = ${CURDIR}/conf/local.conf

PROTOS = protos
CONF   = conf
LOGS   = ${CURDIR}/log
SCRIPT = ${CURDIR}/script

REVISION = ${shell git rev-list HEAD -1}

logs:
	@tail -F ${LOGS}/*.log

check:
	find lib -name '*.pm' -exec perl -I${CURDIR}/lib -I${CURDIR}/extlib -Mlocal::lib=${CURDIR}/local -c {} \;

test:
	@script/app test -v $(filter-out $@,$(MAKECMDGOALS))

start: protos stop
	@./start

stop: dirs
	@./stop

protos: dirs
	@protos/make.pl

dirs:
	@mkdir -p ${LOGS}
	@mkdir -p ${SCRIPT}

info:
	@perl -MData::Dumper -e 'warn Dumper \%ENV'

update:
	@git pull

upgrade:
	carton install --deployment

up: update upgrade protos

crontab: protos
	crontab - < conf/crontab.conf

export
