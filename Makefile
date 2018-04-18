
PREFIX := /
VAR := var/
RUN := run/
LOG := log/
ETC := etc/
USR := usr/
LOCAL := local/
VERSION := 0.20

rebuild: clean build

build: bin/si-i2p-plugin

nodeps: clean
	GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built'

deps:
	go get -u github.com/eyedeekay/i2pasta/addresshelper
	go get -u github.com/eyedeekay/i2pasta/convert
	go get -u github.com/eyedeekay/gosam

bin/si-i2p-plugin: deps
	GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built'

bin/si-i2p-plugin.bin: deps
	GOOS=darwin GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-o bin/si-i2p-plugin.bin \
		./src
	@echo 'built'

bin/si-i2p-plugin.exe: deps
	GOOS=windows GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-o bin/si-i2p-plugin.exe \
		./src
	@echo 'built'

bin: bin/si-i2p-plugin bin/si-i2p-plugin.bin bin/si-i2p-plugin.exe

build-arm: bin/si-i2p-plugin-arm

bin/si-i2p-plugin-arm: deps
	GOARCH=arm GOARM=7 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-buildmode=pie \
		-o bin/si-i2p-plugin-arm \
		./src
	@echo 'built'

release: deps
	GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-static"' \
		-buildmode=pie \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built release'

native: deps
	go build \
		-a \
		-buildmode=pie \
		-o bin/si-i2p-plugin \
		./src
	@echo 'built release'

android: bin/si-i2p-plugin-arm-droid

bin/si-i2p-plugin-arm-droid: deps
	gomobile build \
		-target=android \
		-a \
		-tags netgo \
		-ldflags '-w -extldflags "-llog -static"' \
		-o bin/si-i2p-plugin-droid \
		./src/android
	@echo 'built'
#

xpi2p:

debug: rebuild
	$(HOME)/.go/bin/dlv exec ./bin/si-i2p-plugin

dlv: rebuild
	$(HOME)/.go/bin/dlv debug ./src/

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

run: rebuild
	./bin/si-i2p-plugin -proxy-port="4443" -addresshelper='http://inr.i2p,http://stats.i2p' | tee run.log 2>run.err

verbose: rebuild
	./bin/si-i2p-plugin -proxy-port="4443" -verbose=true -addresshelper='http://inr.i2p,http://stats.i2p' | tee run.log 2>run.err

try: rebuild
	./bin/si-i2p-plugin -proxy-port="4443" -conn-debug=true -addresshelper='http://inr.i2p,http://stats.i2p' | tee run.log 2>run.err

follow:
	docker logs -f si-proxy

clean:
	killall si-i2p-plugin; \
	rm -rf parent services ./.*.i2p*/ ./*.i2p*/ \
		*.html *-pak *err *log \
		static-include static-exclude \
		bin/si-i2p-plugin bin/si-i2p-plugin-arm

kill:
	killall si-i2p-plugin; \
	rm -rf parent *.i2p parent

tidy:
	rm -rf parent *.i2p *.html *-pak *err *log static-include static-exclude

clobber: clean
	rm -rf ../si-i2p-plugin_$(VERSION)*-1_amd64.deb
	docker rmi -f si-i2p-plugin-static si-i2p-plugin eyedeekay/si-i2p-plugin; true
	docker rm -f si-i2p-plugin-static si-i2p-plugin; true

cat:
	cat parent/recv

exit:
	echo y > parent/del

noexit:
	echo n > parent/del

user:
	adduser --system --no-create-home --disabled-password --disabled-login --group sii2pplugin

docker-setup: docker docker-network
	#make docker-host docker-run

docker:
	docker build --force-rm -f Dockerfiles/Dockerfile -t eyedeekay/si-i2p-plugin .
	docker build --force-rm -f Dockerfiles/Dockerfile.samhost -t eyedeekay/sam-host .

docker-network:
	docker network create si; true

docker-host:
	docker run \
		-d \
		--name sam-host \
		--network si \
		--network-alias sam-host \
		--hostname sam-host \
		--link si-proxy \
		--restart always \
		-p :4567 \
		-p 127.0.0.1:7073:7073 \
		-t eyedeekay/sam-host

docker-run: docker-clean
	docker run \
		-d \
		--name si-proxy \
		--network si \
		--network-alias si-proxy \
		--hostname si-proxy \
		--link sam-host \
		--user sii2pplugin \
		-p 127.0.0.1:44443:44443 \
		--restart always \
		-t eyedeekay/si-i2p-plugin

docker-follow:
	docker logs -f si-proxy

docker-clean:
	docker rm -f si-proxy; true

docker-clobber: docker-clean
	docker rm -f sam-host; true

gofmt:
	gofmt -w src/*.go

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
