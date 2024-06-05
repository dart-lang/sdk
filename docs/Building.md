[Dependencies](#dependencies)

[Getting the source](#source)

[Building](#building)

[Testing](#testing)

[Building the standalone VM only](#standalone)

<a id="dependencies"></a>

# Dependencies

## Python 

Dart SDK requires Python 3 to build. 

On Windows you should ensure that `python.bat` wrapper from `depot_tools` comes ahead of any other python binaries in your `PATH` as per [these](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_get_depot_tools) instructions. There are still some steps that require python2 on Windows for now, but Python 3 also has to be available in the path.

## Linux

Install build tools:

```bash
sudo apt-get install git python3 curl xz-utils
```

Install Chromium's [depot tools](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up):

```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$PWD/depot_tools"
```

## Mac OS X

Install XCode.
> If you encounter the error: `xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`, run the command: 
> ```
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```
> See https://stackoverflow.com/questions/17980759.

Install Chromium's [depot tools](http://dev.chromium.org/developers/how-tos/install-depot-tools):
```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$PWD/depot_tools"
```

## Windows

[Install Visual Studio](https://chromium.googlesource.com/chromium/src/+/main/docs/windows_build_instructions.md#visual-studio) (2017 or newer). Make sure to install "Desktop development with C++" component. 

You must have Windows 10 SDK installed. This can be installed separately or by checking the appropriate box in the Visual Studio Installer.

The SDK Debugging Tools must also be installed. If the Windows 10 SDK was installed via the Visual Studio installer, then they can be installed by going to: Control Panel → Programs → Programs and Features → Select the "Windows Software Development Kit" → Change → Change → Check "Debugging Tools For Windows" → Change. Or, you can download the standalone SDK installer and use it to install the Debugging Tools. 

Install Chromium's depot tools following [this](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up) or [this](https://chromium.googlesource.com/chromium/src/+/main/docs/windows_build_instructions.md#install) instructions.

**Important:** If you are not a Googler make sure to set `DEPOT_TOOLS_WIN_TOOLCHAIN` system variable to `0` otherwise depot tools will attempt to pull down a Google-internal toolchain instead of using a local installation of Visual Studio.

<a id="source"></a>

# Getting the source

> [!NOTE] 
> Googlers only: add this to your ~/.gitconfig file _before_ running `fetch dart`:
> ```
> # Googlers need this in ~/.gitconfig or the checkout won't work correctly.
> [url "sso://dart/"]
>     insteadOf = https://dart.googlesource.com/
>     insteadOf = https://dart-review.googlesource.com/
>     insteadOf = http://dart.googlesource.com/
>     insteadOf = http://dart-review.googlesource.com/
> ```

You can choose whatever name you want for the directory to check dart out in, here it is called `dart-sdk`.

```bash
mkdir dart-sdk
cd dart-sdk
# On Windows, this needs to be run in a shell with Administrator rights.
fetch dart
```

Dart SDK uses `gclient` to manage dependencies which are described in the `DEPS` file. If you switch branches or update `sdk` checkout you need to run `gclient sync` to bring dependencies in sync with the SDK version.

Note: If you do not have emscripten, you can update your `.gclient` file to pull emscripten:
```
    "custom_vars": {
      "download_emscripten": True,
    },
```

<a id="building"></a>

# Building

**IMPORTANT: You must follow instructions for [Getting the source](#source) before attempting to build. Just cloning a GitHub repo or downloading and unpacking a ZIP of the SDK repository would not work.**

Build the 64-bit SDK:

```bash
# From within the "dart-sdk" directory.
cd sdk
./tools/build.py --mode release --arch x64 create_sdk
```

The output will be in `out/ReleaseX64/dart-sdk` on Linux and Windows, and `xcodebuild/ReleaseX64/dart-sdk` on macOS.

Build the 32-bit SDK:

```bash
# From within the "dart-sdk" directory.
cd sdk
./tools/build.py --mode release --arch ia32 create_sdk
```
The output will be in `out/ReleaseIA32/dart-sdk` on Linux and Windows, or `xcodebuild/ReleaseIA32/dart-sdk` on macOS.

See also [Building Dart SDK for ARM or RISC-V](Building-Dart-SDK-for-ARM-or-RISC-V.md).

## Tips

By default the build and test scripts select the debug binaries. You can build and test the release version of the VM by specifying `--mode=release` or both debug and release by specifying `--mode=all` on the respective `build.py` and `test.py` command lines.  This can be shortened to `-mrelease` or `-m release`, and the architecture can be specified with `--arch=x64` or `-a x64`, the default.  Other architectures, like `ia32`, `arm`, and `arm64` are also supported.

We recommend that you use a local file system at least for the output of the builds. The output directory is `out` on linux, `xcodebuild` on macOS, and `build` on Windows.  If your code is in some NFS partition, you can link the `out` directory to a local directory:
```bash

$ cd sdk/
$ mkdir -p /usr/local/dart-out/
$ ln -s -f /usr/local/dart-out/ out
```

### Notification when build is done

The environment variable `DART_BUILD_NOTIFICATION_DELAY` controls if `build.py` displays a notification when the build is done. If a build takes longer than `DART_BUILD_NOTIFICATION_DELAY` a notification will be displayed.

A notification is a small transient non-modal window, for now, only supported on Mac and Linux.

## Special note for Windows users using Visual Studio Community Edition:
Your Visual Studio executable command may have a different name from the standard Visual Studio installations. You can specify the name for that executable by passing the additional flag "--executable=$VS\_EXECUTABLE\_NAME" to build.py. The executable name will probably be something like "VSExpress.exe".

## Building on Windows with Visual Studio 2015
Gyp should autodetect the version of Visual Studio you have, and produce solution files in the correct format.
If this is not happening, then set environment variable `gyp_msvs_version` to `2015`.

For example, this will produce Visual Studio 2015-compliant solution files:
```bash
set gyp_msvs_version=2015
gclient runhooks
```

# Testing

All tests are executed using the `test.py` script under `tools/`.  You need to use `build.py` to build the `most` and `run_ffi_unit_tests` targets before testing, e.g.
```bash
$ ./tools/build.py --mode release --arch ia32 most run_ffi_unit_tests
```

Now you can run all tests as follows (Safari, Firefox, Chrome, and IE must be installed, if you want to run the tests on them):
```bash
$ ./tools/test.py -mrelease --arch=ia32 --compiler=dartk,dart2js --runtime=vm,d8,chrome,firefox,[safari,ie10]
```
Specify the compiler used (optional -- only necessary if you are compiling to JavaScript (required for most browsers), the default is "none") and a runtime (where the code will be run).

You can run a specific test by specifying its full name or a prefix. For instance, the following runs only tests from the core libraries:
```bash
$ ./tools/test.py -mrelease --arch=ia32 --runtime=vm corelib
```
The following runs a single test:
```bash
$ ./tools/test.py -mrelease --arch=ia32 --runtime=vm corelib/ListTest
```

Make sure to run tests using the release VM if you have built the release VM, and for the same architecture as you have built.

See also [Testing Dart2js](Testing-Dart2js.md) for dart2js specific examples.

## Complex examples

Adjust the flags to your needs: appropriate values for `--arch` and `--tasks` will depend on your system.  The below examples are taken from a 12 core x86\_64 system.

Dart analyzer tests example:
```bash
./tools/test.py \
  --compiler dart2analyzer \
  --runtime none \
  --progress color \
  --arch x64 \
  --mode release \
  --report \
  --time \
  --tasks 6 \
  language
```

VM tests example:
```bash
./tools/test.py \
  --compiler none \
  --runtime vm \
  --progress color \
  --arch x64 \
  --mode release \
  --checked \
  --report \
  --time \
  --tasks 6 \
  language
```

Dart2JS example:
```bash
./tools/test.py \
  --compiler dart2js \
  --runtime chrome \
  --progress color \
  --arch x64 \
  --mode release \
  --checked \
  --report \
  --time \
  --tasks 6 \
  language
```

## Troubleshooting and tips for browser tests
To debug a browser test failure, you must start a local http server to serve the test.  This is made easy with a helper script in dart/tools/testing.  The error report from test.py gives the command line to start the server in a message that reads:
```bash
To retest, run:  /usr/local/[...]/dart/tools/testing/bin/linux/dart /usr/local/[...]/dart/tools/testing/dart/http_server.dart ...
```
After starting the server, you can run the browser using the command line starting with `Command[[browser name]]`.  The debugging tools in the browser can be used to set Javascript or Dart breakpoints, and the reload button should rerun the test.
    * **Tip:** In the Sources tab of Chrome's developer tools, a "stop sign" button in the upper right tells the browser to break when an exception is thrown.

Some common problems you might get when running tests for the first time:
  * Some fonts are missing. Chromium tests use `DumpRenderTree`, which needs some sets of fonts. See [LayoutTestsLinux](http://code.google.com/p/chromium/wiki/LayoutTestsLinux) for instructions in how to fix it.
  * No display is set (e.g. running tests from an ssh terminal). `DumpRenderTree` is a nearly headless browser. Even though it doesn't open any GUI, it still must have an X session available. There are several ways to work around this:
    * Use `xvfb`:

      ```bash
      xvfb-run ./tools/test.py --arch=ia32 --compiler=dart2js --runtime=drt ...
      ```

    * Other options include using ssh X tunneling (`ssh -Y`), NX, VNC, setting up `xhost` and exporting the DISPLAY environment variable, or simply running tests locally.

<a id="standalone"></a>

# Building the standalone VM only

You can tell the build script to build the runtime targets only with the command:
```bash
$ ./tools/build.py runtime
```
