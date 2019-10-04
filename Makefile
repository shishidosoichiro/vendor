export github_api_token=
export owner=shishidosoichiro
export repo=vendor
export tag=$(shell nimble version | grep -v Executing)

os=$(shell if uname -s | grep -qi MINGW64; then echo windows; elif uname -s | grep -qi MSYS; then echo windows; elif uname -s | grep -qi Darwin; then echo darwin; else echo linux; fi)
ext=$(shell if [ $(os) = windows ]; then echo .exe; fi)
time=$(shell if [ $(os) != windows ]; then echo time; fi)

release_script_url=https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447/raw/dbadd7d310ce8446de89c4ffdf1db0b400d0f6c3/upload-github-release-asset.sh
release_script=./dist/upload-github-release-asset.sh

all: clean
	make -e windows
	make -e linux
	make -e darwin
	make -e size

build:
	$(time) nimble build -d:nimOldCaseObjects
	#wc -c ./vendor$(ext)
	ls -lh ./vendor$(ext)

install:
	#$(time) nimble install -y --debug
	mkdir -p ~/bin
	cp -pr dist/vendor-$(tag)-darwin-amd64/vendor ~/bin
	ls -lLh $(shell which vendor)

release:
	mkdir -p dist
	curl -X POST https://api.github.com/repos/$(owner)/$(repo)/releases -d "{\"tag_name\": \"$(tag)\", \"target_commitish\": \"master\", \"name\": \"$(tag)\", \"body\": \"\", \"draft\": false, \"prerelease\": false}" -H 'Content-Type:application/json' -H "Authorization: token $(github_api_token)"

release-files:
	mkdir -p dist
	cd dist && curl --fail --location -O -s $(release_script_url)
	chmod u+x $(release_script)
	$(release_script) github_api_token=$(github_api_token) owner=$(owner) repo=$(repo) tag=$(tag) filename=./dist/vendor-$(tag)-windows-amd64.zip
	$(release_script) github_api_token=$(github_api_token) owner=$(owner) repo=$(repo) tag=$(tag) filename=./dist/vendor-$(tag)-linux-amd64.tar.gz
	$(release_script) github_api_token=$(github_api_token) owner=$(owner) repo=$(repo) tag=$(tag) filename=./dist/vendor-$(tag)-darwin-amd64.tar.gz

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
