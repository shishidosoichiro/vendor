os=$(shell if uname -s | grep -qi MINGW64; then echo windows; elif uname -s | grep -qi MSYS; then echo windows; elif uname -s | grep -qi Darwin; then echo darwin; else echo linux; fi)
ext=$(shell if [ $(os) = windows ]; then echo .exe; fi)
time=$(shell if [ $(os) != windows ]; then echo time; fi)

all: clean
	make windows
	make linux
	make darwin
	make size

build:
	$(time) nimble build
	#wc -c ./vendor$(ext)
	ls -lh ./vendor$(ext)

install:
	$(time) nimble install -y --debug
	ls -lLh $(shell which vendor)

test:
	$(time) nimble test

size:
	ls -lLh dist/*/*

clean:
	rm -rf ./dist/*

windows:
	$(time) make windows -f build/Makefile.$(os)

linux:
	$(time) make linux -f build/Makefile.$(os)

darwin:
	$(time) make darwin -f build/Makefile.$(os)

.PHONY: build
