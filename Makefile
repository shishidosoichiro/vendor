export github_api_token=
export owner=shishidosoichiro
export repo=vendor
export tag=$(shell nimble version | grep -v Executing)

os=$(shell if uname -s | grep -qi MINGW64; then echo windows; elif uname -s | grep -qi MSYS; then echo windows; elif uname -s | grep -qi Darwin; then echo darwin; else echo linux; fi)
ext=$(shell if [ $(os) = windows ]; then echo .exe; fi)
time=$(shell if [ $(os) != windows ]; then echo time; fi)

all: clean
	make -e windows
	make -e linux
	make -e darwin
	make -e size

build:
	$(time) nimble build
	#wc -c ./vendor$(ext)
	ls -lh ./vendor$(ext)

install:
	#$(time) nimble install -y --debug
	mkdir -p ~/bin
	cp -pr dist/vendor-$(tag)-darwin-amd64/vendor ~/bin
	ls -lLh $(shell which vendor)

release:
	$(time) make release -e -f build/Makefile.$(os)

test:
	$(time) nimble test

size:
	ls -lLh dist/*/*

clean:
	rm -rf ./dist/*

windows:
	$(time) make windows -e -f build/Makefile.$(os)

linux:
	$(time) make linux -e -f build/Makefile.$(os)

darwin:
	$(time) make darwin -e -f build/Makefile.$(os)

.PHONY: build
