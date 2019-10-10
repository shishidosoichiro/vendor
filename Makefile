export github_api_token=
export owner=shishidosoichiro
export repo=vendor
export tag=$(shell nimble version | grep -v Executing)

strip=true
upx=true
optimize=-d:release -d:ssl --opt:size
cpu=amd64
#cpu=arm64
platform=$(shell if uname -s | grep -qi MINGW64; then echo windows; elif uname -s | grep -qi MSYS; then echo windows; elif uname -s | grep -qi Darwin; then echo macosx; else echo linux; fi)
os=$(platform)

ext=$(shell if [ $(os) = windows ]; then echo .exe; fi)
archive=$(shell if [ $(os) = windows ]; then echo zip; else echo tar.gz; fi)
release_script_url=https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447/raw/dbadd7d310ce8446de89c4ffdf1db0b400d0f6c3/upload-github-release-asset.sh
release_script=./dist/upload-github-release-asset.sh
time=$(shell if [ $(platform) = macosx ]; then echo time; fi)

all: windows linux macosx size

windows:
	$(time) make build os=windows

linux:
	$(time) make build os=linux

macosx:
	$(time) make build os=macosx

build:
	nim c --out:dist/vendor-$(tag)-$(os)-$(cpu)/vendor$(ext) $(optimize) --cpu:$(cpu) --os:$(os) -d:platform_$(platform) -f src/vendor.nim
ifeq ($(os)$(strip),macosxtrue)
	strip dist/vendor-$(tag)-$(os)-$(cpu)/vendor$(ext)
endif
ifeq ($(upx),true)
	upx --best dist/vendor-$(tag)-$(os)-$(cpu)/vendor$(ext)
endif
ifeq ($(archive),zip)
	cd dist && zip -r vendor-$(tag)-$(os)-$(cpu).zip vendor-$(tag)-$(os)-$(cpu)
endif
ifeq ($(archive),tar.gz)
	cd dist && tar -zcf vendor-$(tag)-$(os)-$(cpu).tar.gz vendor-$(tag)-$(os)-$(cpu)
endif

nimble:
	$(time) nimble build
	#wc -c ./vendor$(ext)
	ls -lh ./vendor$(ext)

install:
	#$(time) nimble install -y --debug
	mkdir -p ~/bin
	cp -pr dist/vendor-$(tag)-macosx-amd64/vendor ~/bin
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
	rm -rf ./dist/*

provision:
	$(time) make provision-$(os) -f build/Makefile.$(platform)

.PHONY: build
