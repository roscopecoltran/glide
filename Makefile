GLIDE_GO_EXECUTABLE ?= go
DIST_DIRS := find * -type d -exec
VERSION ?= $(shell git describe --tags)
VERSION_INCODE = $(shell perl -ne '/^var version.*"([^"]+)".*$$/ && print "v$$1\n"' glide.go)
VERSION_INCHANGELOG = $(shell perl -ne '/^\# Release (\d+(\.\d+)+) / && print "$$1\n"' CHANGELOG.md | head -n1)

PACKAGES = $(shell go list ./... | grep -v /vendor/)

# determine platform
ifeq (Darwin, $(findstring Darwin, $(shell uname -a)))
  PLATFORM 			:= macosx
  GO_BUILD_OS 		:= darwin
else
  PLATFORM 			:= Linux
  GO_BUILD_OS 		:= linux
endif

GREEN 				:= "\\033[1;32m"
NORMAL				:= "\\033[0;39m"
RED					:= "\\033[1;31m"
PINK				:= "\\033[1;35m"
BLUE				:= "\\033[1;34m"
WHITE				:= "\\033[0;02m"
YELLOW				:= "\\033[1;33m"
CYAN				:= "\\033[1;36m"

# git
GIT_BRANCH			:= $(shell git rev-parse --abbrev-ref HEAD)
GIT_VERSION			:= $(shell git describe --always --long --dirty --tags)
GIT_REMOTE_URL		:= $(shell git config --get remote.origin.url)
GIT_TOP_LEVEL		:= $(shell git rev-parse --show-toplevel)

# app
APP_NAME 			:= gox
APP_NAME_UCFIRST 	:= Gox
APP_BRANCH 			:= sniperkit
APP_DIST_DIR 		:= "$(CURDIR)/dist"

APP_PKG 			:= $(APP_NAME)
APP_PKGS 			:= $(shell go list ./... | grep -v /vendor/)
APP_VER				:= $(APP_VER)
APP_VER_FILE 		:= $(shell git describe --always --long --dirty --tags)

# golang
GO_BUILD_LDFLAGS 	:= -X github.com/roscopecoltran/$(APP_NAME)/core.version=$(APP_VER_FILE)
GO_BUILD_PREFIX		:= $(APP_DIST_DIR)/all/$(APP_NAME)
GO_BUILD_URI		:= github.com/roscopecoltran/$(APP_NAME)
GO_BUILD_VARS 		:= GOARCH=amd64 CGO_ENABLED=0

# https://github.com/derekparker/delve/blob/master/Makefile
GO_VERSION			:= $(shell go version)
GO_BUILD_SHA		:= $(shell git rev-parse HEAD)
LLDB_SERVER			:= $(shell which lldb-server)

# golang - app
GO_BINDATA			:= $(shell which go-bindata)
GO_BINDATA_ASSETFS	:= $(shell which go-bindata-assetfs)
GO_GOX				:= $(shell which gox)
GO_GLIDE			:= $(shell which glide)
GO_VENDORCHECK		:= $(shell which vendorcheck)
GO_LINT				:= $(shell which golint)
GO_DEP				:= $(shell which dep)
GO_ERRCHECK			:= $(shell which errcheck)
GO_UNCONVERT		:= $(shell which unconvert)
GO_INTERFACER		:= $(shell which interfacer)

# general - helper
TR_EXEC				:= $(shell which tr)
AG_EXEC				:= $(shell which ag)

# package managers
BREW_EXEC			:= $(shell which brew)
MACPORTS_EXEC		:= $(shell which ports)
APT_EXEC			:= $(shell which apt-get)
APK_EXEC			:= $(shell which apk)
YUM_EXEC			:= $(shell which yum)
DNF_EXEC			:= $(shell which dnf)

EMERGE_EXEC			:= $(shell which emerge)
PACMAN_EXEC			:= $(shell which pacmane)
SLACKWARE_EXEC		:= $(shell which sbopkg)
ZYPPER_EXEC			:= $(shell which zypper)
PKG_EXEC			:= $(shell which pkg)
PKG_ADD_EXEC		:= $(shell which pkg_add)

default: build

build: 
	@go build -o glide -ldflags "-X main.version=${APP_VER_FILE}" cmd/glide/main.go
	@glide --version

dist: macos linux windows

install:
	@go build -o glide -ldflags "-X main.version=${APP_VER_FILE}" cmd/glide/main.go
	@glide --version

darwin: gox
	clear
	echo ""
	rm -f $(APP_NAME)
	gox -verbose -ldflags="$(GO_BUILD_LDFLAGS)" -os="darwin" -arch="amd64" -output="{{.Dir}}" $(glide novendor)
	echo ""

darwin-tests: gox
	clear
	echo ""
	rm -f $(APP_NAME)
	gox -verbose -ldflags="$(GO_BUILD_LDFLAGS)" -os="darwin" -arch="amd64" -output="{{.Dir}}" $(glide novendor)
	echo ""

gox: 
	@if [ ! -f $(GO_GOX) ]; then go get -v github.com/mitchellh/gox ; fi

test:
	${GLIDE_GO_EXECUTABLE} test . ./gb ./path ./action ./tree ./util ./godep ./godep/strip ./gpm ./cfg ./dependency ./importer ./msg ./repo ./mirrors

integration-test:
	${GLIDE_GO_EXECUTABLE} build
	./glide up
	./glide install

clean:
	rm -f ./glide.test
	rm -f ./glide
	rm -rf ./dist

bootstrap-dist:
	${GLIDE_GO_EXECUTABLE} get -u github.com/franciscocpg/gox
	cd ${GOPATH}/src/github.com/franciscocpg/gox && git checkout dc50315fc7992f4fa34a4ee4bb3d60052eeb038e
	cd ${GOPATH}/src/github.com/franciscocpg/gox && ${GLIDE_GO_EXECUTABLE} install

build-all:
	gox -verbose \
	-ldflags "-X main.version=${VERSION}" \
	-os="linux darwin windows freebsd openbsd netbsd" \
	-arch="amd64 386 armv5 armv6 armv7 arm64" \
	-osarch="!darwin/arm64" \
	-output="dist/{{.OS}}-{{.Arch}}/{{.Dir}}" .

dist: build-all
	cd dist && \
	$(DIST_DIRS) cp ../LICENSE {} \; && \
	$(DIST_DIRS) cp ../README.md {} \; && \
	$(DIST_DIRS) tar -zcf glide-${VERSION}-{}.tar.gz {} \; && \
	$(DIST_DIRS) zip -r glide-${VERSION}-{}.zip {} \; && \
	cd ..

verify-version:
	@if [ "$(VERSION_INCODE)" = "v$(VERSION_INCHANGELOG)" ]; then \
		echo "glide: $(VERSION_INCHANGELOG)"; \
	elif [ "$(VERSION_INCODE)" = "v$(VERSION_INCHANGELOG)-dev" ]; then \
		echo "glide (development): $(VERSION_INCHANGELOG)"; \
	else \
		echo "Version number in glide.go does not match CHANGELOG.md"; \
		echo "glide.go: $(VERSION_INCODE)"; \
		echo "CHANGELOG : $(VERSION_INCHANGELOG)"; \
		exit 1; \
	fi

.PHONY: build test install clean bootstrap-dist build-all dist integration-test verify-version
