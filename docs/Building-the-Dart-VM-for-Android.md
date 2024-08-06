> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Introduction

It is possible to build and run the standalone Dart VM for Android devices. This setup is not yet thoroughly tested, but is available for experimentation.

## Limitations

* The host (build) machine must be an x86 Linux machine.
* The target (Android) device must be a device or emulator that supports the Android NDK.
* The resulting Android Dart VM can only be run from the Android command line.
* The resulting Android Dart VM only has access to dart:core APIs. It does not have access to the Android C or Java APIs.
* The Android-related tools and emulator image files will take about 2GB of disk space on the host machine.

# One-time Setup

Download and install the Dart source tree using the standard instructions for building Dart.

Use a text editor to add the following line to the very bottom of your Dart .gclient file (which is located in the directory that contains the main 'dart' directory):

`download_android_deps = True`

Run gclient sync to install the Android NDK and SDK. This may take 10 minutes or more depending upon the speed of your Internet connection

`$ gclient sync`

# Building for Android

Once you've set up your build tree, you can build the Dart VM for Android by using the standard Dart build script with the addition of the --os android build flag:

`$ tools/build.py --no-rbe --arch=arm,arm64,ia32,x64 --os=android runtime`

# Testing the result

Adding `adb` to your path

For convenience, add the path to the adb tool to your shell PATH:

`$ export PATH=$PATH:path-to-dart/third_party/android_tools/sdk/platform-tools`

Starting an Android emulator

You can start an emulator running, by using the android_finder.py script:

`$ runtime/tools/android_finder.py -a {armeabi-v7a, x86} -b`

The -a flag says to find an Android device for the specified architecture. The -b flag says to start (or bootstrap) a new emulator if no existing emulator or device with a given ABI can be found. This script could take up to 20 seconds to run if a new emulator needs to be started.

## Running the Dart VM on an Android emulator

Once you have finished building the Android Dart VM and have a running Android emulator, you can run Dart scripts on the emulator as follows:

Create a directory on the Android emulator.

`$ adb shell mkdir /data/local/tmp/dart`

Copy the Dart VM executable to the Android emulator:

`$ adb push out/android/ReleaseAndroid{ARM,ARM64,IA32,X64}/dart /data/local/tmp/dart/dart`

Create a simple Dart test script:

`$ echo "main(){ print(\"Hello, world\!\");}" >hello.dart`

Copy the Dart test script to the Android emulator:

`$ adb push hello.dart /data/local/tmp/dart`

Run the Dart VM with the test script:

`$ adb shell /data/local/tmp/dart/dart /data/local/tmp/dart/hello.dart`

Hello, world!

## Stopping an Android Emulator

You can list all currently attached Android devices, including emulators, using the adb command:

`$ adb devices`

You can stop a running emulator using the adb emu kill command:

`$ adb emu kill           ← if there is just one emulator running`

or

`$ adb -s emulator-name emu kill    ← if there is more than one emulator running`

## Running the Dart VM on an Android device

First, make sure that the "USB Debugging" mode is enabled by navigating to Settings > Developer options > USB debugging. The box should be checked. You may need to have root on the device.

Now, plug in your device. Then, run:

`$ adb devices`

There should be an entry for your device, such as:

```
List of devices attached 
TA23701VKR  device
```

Now, you can copy dart and hello.dart to the device as above. If an emulator is also running, be sure to give adb the -d switch to tell it to use the attached device instead of the emulator. Use the -s switch to give the device ID explicitly.

# Notes

The only effect of the `target_os` line in the Dart `.gclient` configuration file is to install the Android tools. Despite what the name `target_os` implies, the target_os line does not affect which OS is targeted. Therefore, once you've installed the Android tools you can (and should) leave the `target_os = ["android"]` line in place even when switching back and forth between building for Android and building for Linux.
