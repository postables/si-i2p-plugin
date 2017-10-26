

PREFIX := /
VAR := var/
RUN := run/
LOG := log/
ETC := etc/
USR := usr/
LOCAL := local/
VERSION := 0.15


CC := musl-gcc
COMPILER := "-compiler gccgo"

COMPILER_FLAGS := '-ldflags \'-linkmode external -extldflags "-static"\''
#COMPILER_FLAGS := -gccgoflags '-extldflags "-fPIE" "-static" "-pie"'

build:
	go get github.com/eyedeekay/gosam
	go build -o bin/si-i2p-plugin ./src

build-static:
	go get github.com/eyedeekay/gosam
	go build -ldflags '-linkmode external -extldflags "-static"' \
		-o bin/si-i2p-plugin-static \
		./src

build-gccgo-static:
	go get github.com/eyedeekay/gosam
	go build "$(COMPILER)" \
		-gccgoflags '-extldflags "-fPIE" "-static" "-pie"' \
		-o bin/si-i2p-plugin-static \
		./src

all:
	make clobber; \
	make; \
	make static; \
	make checkinstall; \
	make checkinstall-static; \
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


debug: build
	gdb ./bin/si-i2p-plugin

try: build
	./bin/si-i2p-plugin 2>err | tee -a log &

test-easy:
	echo http://i2p-projekt.i2p > parent/send

test-harder:
	echo i2p-projekt.i2p > parent/send

clean:
	killall si-i2p-plugin; \
	rm -rf parent *.i2p bin/si-i2p-plugin bin/si-i2p-plugin-static *.html *-pak *err *log static-include static-exclude

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

checkinstall: build postinstall-pak postremove-pak description-pak
	checkinstall --default \
		--install=no \
		--fstrans=yes \
		--maintainer=problemsolver@openmailbox.org \
		--pkgname="si-i2p-plugin" \
		--pkgversion="$(VERSION)" \
		--pkglicense=gpl \
		--pkggroup=net \
		--pkgsource=./src/ \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--backup=no \
		--pakdir=../

checkinstall-static: build postinstall-pak postremove-pak description-pak static-include static-exclude
	make static
	checkinstall --default \
		--install=no \
		--fstrans=yes \
		--maintainer=problemsolver@openmailbox.org \
		--pkgname="si-i2p-plugin" \
		--pkgversion="$(VERSION)-static" \
		--pkglicense=gpl \
		--pkggroup=net \
		--pkgsource=./src/ \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--backup=no \
		--exclude=static-exclude \
		--include=static-include \
		--pakdir=../

postinstall-pak:
	@echo "#! /bin/sh" | tee postinstall-pak
	@echo "adduser --system --no-create-home --disabled-password --disabled-login --group sii2pplugin; true" | tee -a postinstall-pak
	@echo "mkdir -p $(PREFIX)$(VAR)$(LOG)si-i2p-plugin/ $(PREFIX)$(VAR)$(RUN)si-i2p-plugin/ || exit 1" | tee -a postinstall-pak
	@echo "chown -R sii2pplugin:adm $(PREFIX)$(VAR)$(LOG)si-i2p-plugin/ $(PREFIX)$(VAR)$(RUN)si-i2p-plugin/ || exit 1" | tee -a postinstall-pak
	@echo "exit 0" | tee -a postinstall-pak
	chmod +x postinstall-pak

postremove-pak:
	@echo "#! /bin/sh" | tee postremove-pak
	@echo "deluser sii2pplugin; true" | tee -a postremove-pak
	@echo "exit 0" | tee -a postremove-pak
	chmod +x postremove-pak

description-pak:
	@echo "si-i2p-plugin" | tee description-pak
	@echo "" | tee -a description-pak
	@echo "Destination-isolating http proxy for i2p. Keeps multiple eepSites" | tee -a description-pak
	@echo "from sharing a single reply destination, to limit the use of i2p" | tee -a description-pak
	@echo "metadata for fingerprinting purposes" | tee -a description-pak

static-include:
	@echo 'bin/si-i2p-plugin-static /usr/local/bin/' | tee static-include

static-exclude:
	@echo 'bin/si-i2p-plugin' | tee static-exclude


static:
	docker rm -f si-i2p-plugin-static; true
	docker build --force-rm -f Dockerfiles/Dockerfile.static -t si-i2p-plugin-static .
	docker run --name si-i2p-plugin-static -t si-i2p-plugin-static
	docker cp si-i2p-plugin-static:/opt/bin/si-i2p-plugin-static ./bin/si-i2p-plugin-static

uuser:
	docker build --force-rm -f Dockerfiles/Dockerfile.uuser -t si-i2p-plugin-uuser .
	docker run -d --rm --name si-i2p-plugin-uuser -t si-i2p-plugin-uuser
	docker exec -t si-i2p-plugin-uuser tail -n 1 /etc/passwd | tee si-i2p-plugin/passwd
	docker cp si-i2p-plugin-uuser:/bin/bash-static si-i2p-plugin/bash
	docker cp si-i2p-plugin-uuser:/bin/busybox si-i2p-plugin/busybox
	docker rm -f si-i2p-plugin-uuser; docker rmi -f si-i2p-plugin-uuser

docker:
	make static
	make uuser
	docker build --force-rm -f Dockerfiles/Dockerfile -t si-i2p-plugin .

docker-run:
	docker run -d \
		--cap-drop all \
		--name si-i2p-plugin \
		--user sii2pplugindocker \
		-t si-i2p-plugin