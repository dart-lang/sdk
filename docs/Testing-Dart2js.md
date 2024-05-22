> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Testing the dart2js Compiler

Testing dart2js is complicated. There are a lot of configurations that are tested on the build bots. In this document we describe the build bots, and what they test. We also recommend a minimum set of tests that will increase your chances of submitting without a hitch.

## Test Configurations

  * **VM Release/Debug:** the release version of the Dart VM is the version you will normally use as a Dart developer. The debug version of the Dart VM is much slower and only intended to be used by VM compiler engineers. It includes debug symbols and a lot of assertions which makes this VM slow.

  * **VM Production/Developer mode:** this is the mode that Dart developers use to enable assertions and type checks while developing a Dart program. Since dart2js is a Dart program, the dart2js compiler engineers want to make sure that their assertions and type annotations are checked.

  * **dart2js Production/Developer mode:** dart2js is an implementation of the Dart programming language. And just like the VM, dart2js should also support developer mode where assertions an type annotations are checked. So both production mode and developer mode of dart2js should be tested. Ideally, both in production mode and developer mode on the VM.

Ideally, we would want to test all the entries in this matrix:

|               | dart2js Production  | dart2js Developer |
| :------------ |:-------------------:|:-----------------:|
| VM Production | X | X |
| VM Developer  | X | X |

## Build Bot Configurations

[dart2js-linux-release-N-4](http://build.chromium.org/p/client.dart/waterfall?builder=dart2js-linux-release-1-4&builder=dart2js-linux-release-2-4&builder=dart2js-linux-release-3-4&builder=dart2js-linux-release-4-4) (where 0 < N < 5), runs:

```
./tools/build.py -mrelease dart2js_bot
./tools/test.py -mrelease -cnone -rvm --use-sdk -v --shards=4 --shard=N dart2js
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N dart2js_extra dart2js_native
./tools/test.py -mrelease -cnone -rvm --use-sdk --shards=4 --shard=N --enable-asserts dart2js
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N --enable-asserts
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N --enable-asserts dart2js_extra dart2js_native
```

Let's break down the name, dart2js-linux-release-N-4:

  * **dart2js** means that we're _testing_ dart2js.

  * **linux** means the tests are _running_ on Linux.

  * **release** means that we use the release version of the Dart VM for _running_ unit tests or dart2js.

  * **N-4** means that we have distributed the test across four build bots. N is a number that identifies one of these four build bots.

[dart2js-linux-release-checked-N-4](http://build.chromium.org/p/client.dart/waterfall?builder=dart2js-linux-release-checked-1-4&builder=dart2js-linux-release-checked-2-4&builder=dart2js-linux-release-checked-3-4&builder=dart2js-linux-release-checked-4-4) (where 0 < N < 5), runs:

```
./tools/build.py -mrelease dart2js_bot
./tools/test.py -mrelease -cnone -rvm --use-sdk --shards=4 --shard=N --host-checked dart2js
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N --host-checked
./tools/test.py -mrelease -cdart2js -rd8 --use-sdk --shards=4 --shard=N --host-checked dart2js_extra dart2js_native
```

[web-chrome-OS](http://build.chromium.org/p/client.dart/waterfall?builder=web-chrome-linux&builder=web-chrome-mac&builder=web-chrome-win7) (where OS is one of linux, mac, or win7).

[web-ff-OS](http://build.chromium.org/p/client.dart/waterfall?builder=web-ff-linux&builder=web-ff-win7) (where OS is one of linux, or win7).

[web-opera-linux](http://build.chromium.org/p/client.dart/waterfall?builder=web-opera-linux)

[web-safari-mac](http://build.chromium.org/p/client.dart/waterfall?builder=web-safari-mac)

## Basic test recommendation

The full test matrix is so huge that we recommend you use minimal local testing and rely on the build bot for full coverage (but keep an eye on the build bot and be ready to revert).

```
./tools/build.py -m release dart2js_bot
./tools/test.py -mrelease --use-sdk --time -pcolor --report --enable-asserts dart2js utils
./tools/test.py -mrelease -cdart2js -rd8 --time -pcolor --report --host-checked dart2js_extra dart2js_native
./tools/test.py -mrelease -cdart2js -rd8,drt --use-sdk --time -pcolor --report
```

(The version above uses --use-sdk which means it starts from the dart2js snapshot.  This means that changes to .dart files in dart2js won't be tested unless you remember to run the build.py command first.)

The bare minimum follows (but you risk breaking the build):

Mac:

```
./tools/build.py -mrelease dart2js
./sdk/bin/dart2js_developer -v --categories=all --package-root=out/ReleaseIA32/packages/ tests/utils/dummy_compiler_test.dart
```

Linux:

```
./tools/build.py -mrelease dart2js
./sdk/bin/dart2js_developer -v --categories=all --package-root=out/ReleaseIA32/packages/ tests/utils/dummy_compiler_test.dart
```

Windows:

```
python ./tools/build.py -mrelease dart2js
sdk\bin\dart2js_developer.bat -v --categories=all --package-root=out/ReleaseIA32/packages/ tests/utils/dummy_compiler_test.dart
