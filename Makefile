export github_api_token=
export owner=shishidosoichiro
export repo=vendor
export tag=$(shell nimble version | grep -v Executing)

strip=true
upx=true
optimize=
#optimize=-d:release --opt:size
cpu=amd64
#cpu=arm64
platform=$(shell if uname -s | grep -qi MINGW64; then echo windows; elif uname -s | grep -qi MSYS; then echo windows; elif uname -s | grep -qi Darwin; then echo macosx; else echo linux; fi)
os=$(platform)

ext=$(shell if [ $(os) = windows ]; then echo .exe; fi)
release_script_url=https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447/raw/dbadd7d310ce8446de89c4ffdf1db0b400d0f6c3/upload-github-release-asset.sh
release_script=./dist/upload-github-release-asset.sh
time=$(shell if [ $(platform) = macosx ]; then echo time; fi)

archive_name=vendor-$(tag)-$(os)-$(cpu)
archive_ext=$(shell if [ $(os) = windows ]; then echo zip; else echo tar.gz; fi)

all: windows linux macosx size

windows:
	$(time) make build package os=windows optimize="-d:release --opt:size"

linux:
	$(time) make build package os=linux optimize="-d:release --opt:size"

macosx:
	$(time) make build package os=macosx optimize="-d:release --opt:size"

build:
	#nim c --out:vendor$(ext) --cpu:$(cpu) --os:$(os) -d:ssl $(optimize) -d:platform_$(platform) -f src/vendor.nim
	nimble build --cpu:$(cpu) --os:$(os) -d:ssl $(optimize) -d:platform_$(platform)
ifeq ($(platform)-$(os)-$(strip),macosx-macosx-true)
	strip ./vendor$(ext)
endif
ifeq ($(upx),true)
	upx --best ./vendor$(ext)
endif

package:
	mkdir -p dist/$(archive_name)
	cp -rp ./vendor$(ext) dist/$(archive_name)/vendor$(ext)
ifeq ($(archive_ext),zip)
	cd dist && zip -r $(archive_name).zip $(archive_name)
endif
ifeq ($(archive_ext),tar.gz)
	cd dist && tar -zcf $(archive_name).tar.gz $(archive_name)
endif

install:
	#$(time) nimble install -y --debug
	mkdir -p ~/bin
	cp -pr ./vendor ~/bin
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
	$(release_script) github_api_token=$(github_api_token) owner=$(owner) repo=$(repo) tag=$(tag) filename=./dist/vendor-$(tag)-macosx-amd64.tar.gz

test:
	$(time) nimble test

size:
	ls -lLh dist/*/*

clean:
	rm -rf ./vendor
	rm -rf ./vendor.exe
	rm -rf ./dist/*

provision:
	$(time) make provision-$(os) -f build/Makefile.$(platform)

.PHONY: build
