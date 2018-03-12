
PREFIX := /
VAR := var/
RUN := run/
LOG := log/
ETC := etc/
USR := usr/
LOCAL := local/
VERSION := 0.19


build: clean bin/si-i2p-plugin

bin/si-i2p-plugin:
	go get -u github.com/eyedeekay/gosam
	GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built'

build-arm: bin/si-i2p-plugin-arm

bin/si-i2p-plugin-arm:
	go get -u github.com/eyedeekay/gosam
	GOARCH=arm GOARM=7 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-buildmode=pie \
		-o bin/si-i2p-plugin-arm \
		./src
	@echo 'built'

release:
	go get -u github.com/eyedeekay/gosam
	GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-buildmode=pie \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built release'


debug: build
	gdb ./bin/si-i2p-plugin

all:
	make clobber; \
	make release; \
	make build-arm; \
	make checkinstall; \
	make checkinstall-arm; \
	make docker
	make tidy

install:
	mkdir -p $(PREFIX)$(VAR)$(LOG)/si-i2p-plugin/ $(PREFIX)$(VAR)$(RUN)si-i2p-plugin/ $(PREFIX)$(ETC)si-i2p-plugin/
	install -D bin/si-i2p-plugin $(PREFIX)$(USR)$(LOCAL)/bin/
	install -D bin/si-i2p-plugin.sh $(PREFIX)$(USR)$(LOCAL)/bin/
	install -D init.d/si-i2p-plugin $(PREFIX)$(ETC)init.d/
	install -D systemd/sii2pplugin.service $(PREFIX)$(ETC)systemd/system/
	install -D si-i2p-plugin/settings.cfg $(PREFIX)$(ETC)si-i2p-plugin/

remove:
	rm -f $(PREFIX)$(USR)$(LOCAL)/bin/si-i2p-plugin \
		$(PREFIX)$(USR)$(LOCAL)/bin/si-i2p-plugin.sh \
		$(PREFIX)$(ETC)init.d/si-i2p-plugin $(PREFIX)\
		$(ETC)systemd/system/sii2pplugin.service \
		$(PREFIX)$(ETC)si-i2p-plugin/settings.cfg
	rm -rf $(PREFIX)$(VAR)$(LOG)/si-i2p-plugin/ $(PREFIX)$(VAR)$(RUN)si-i2p-plugin/ $(PREFIX)$(ETC)si-i2p-plugin/

run: build
	./bin/si-i2p-plugin >run.log 2>run.err &

follow:
	tail -f run.log run.err | nl

try: build
	./bin/si-i2p-plugin -conn-debug=true >log 2>err &
	sleep 1
	tail -f log | nl

clean:
	killall si-i2p-plugin; \
	rm -rf parent ./.*.i2p/ *.i2p/ *.html *-pak *err *log static-include static-exclude del recv

kill:
	killall si-i2p-plugin; \
	rm -rf parent *.i2p parent

tidy:
	rm -rf parent *.i2p *.html *-pak *err *log static-include static-exclude

clobber:
	rm -rf ../si-i2p-plugin_$(VERSION)*-1_amd64.deb
	docker rmi -f si-i2p-plugin-static si-i2p-plugin; true
	docker rm -f si-i2p-plugin-static si-i2p-plugin; true
	make clean

cat:
	cat parent/recv

exit:
	echo y > parent/del

noexit:
	echo n > parent/del

user:
	adduser --system --no-create-home --disabled-password --disabled-login --group sii2pplugin

docker:
	docker build --force-rm -f Dockerfiles/Dockerfile -t eyedeekay/si-i2p-plugin .

docker-run:
	docker run \
		--cap-drop all \
		--name si-i2p-plugin \
		--user sii2pplugin \
		-p 44443:4443 \
		-t eyedeekay/si-i2p-plugin

docker-run-thirdeye:
	docker run \
		--name thirdeye-proxy \
		--network thirdeye \
		--network-alias thirdeye-proxy \
		--hostname thirdeye-proxy \
		--cap-drop all \
		--user sii2pplugin \
		-p 44443:4443 \
		-t eyedeekay/si-i2p-plugin

mps:
	bash -c "ps aux | grep si-i2p-plugin | grep -v gdb |  grep -v grep | grep -v https" 2> /dev/null

mls:
	@echo pipes
	@echo ==================
	ls *.i2p/* parent 2>/dev/null
	@echo

ls:
	while true; do make -s mls 2>/dev/null; sleep 2; clear; done

ps:
	while true; do make -s mps 2>/dev/null; sleep 2; clear; done

include misc/Makefiles/demo.mk
include misc/Makefiles/test.mk
include misc/Makefiles/checkinstall.mk
