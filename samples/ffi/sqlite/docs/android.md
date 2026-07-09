**This documentation is for demonstration/testing purposes only!**

# Using FFI with Flutter

## Android

Before using the FFI on Android, you need to procure an Android-compatible build of the native library you want to link against.
It's important that the shared object(s) be compatible with ABI version you wish to target (or else, that you have multiple builds for different ABIs).
See [https://developer.android.com/ndk/guides/abis] for more details on Android ABIs.
Within Flutter, the target ABI is controlled by the `--target-platform` parameter to the `flutter` command.

The workflow for packaging a native library will depend significantly on the library itself, but to illustrate the challenges at play, we'll demonstrate how to build the SQLite library from source to use with the FFI on an Android device.

### Building SQLite for Android

Every Android device ships with a copy of the SQLite library (`/system/lib/libsqlite.so`).
Unfortunately, this library cannot be loaded directly by apps (see [https://developer.android.com/about/versions/nougat/android-7.0-changes#ndk]).
It is accessible only through Java.
Instead, we can build SQLite directly with the NDK.

First, download the SQLite "amalgamation" source from [https://www.sqlite.org/download.html].
For the sake of brevity, we'll assume the file has been saved as `sqlite-amalgamation-XXXXXXX.zip`, the Android SDK (with NDK extension) is available in `~/Android`, and we're on a Linux workstation.

```sh
unzip sqlite-amalgamation-XXXXXXX.zip
cd sqlite-amalgamation-XXXXXXX
~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang -c sqlite3.c -o sqlite3.o
~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ld -shared sqlite3.o -o libsqlite3.so
```

Note the use of the `aarch64` prefix to the compiler: this indicates that we're building a shared object for the `arm64-v8a` ABI.
This will be important later.

### Update Gradle script

Next we need to instruct Gradle to package this library with the app, so it will be available to load off the Android device at runtime.
Create a folder `native-libraries` in the root folder of the app, and update the `android/app/build.gradle` file:

```groovy
android {
    // ...
    sourceSets {
        main {
            jniLibs.srcDir "${project.projectDir.path}/../../native-libraries"
        }
    }
}
```

Within the `native-libraries` folder, the libraries are organized by ABI.
Therefore, we must copy the compiled `libsqlite3.so` into `native-libraries/arm64-v8a/libsqlite3.so`.
If multiple sub-directories are present, the libraries from the sub-directory corresponding to the target ABI will be available in the application's linking path, so the library can be loaded with `DynamicLibrary.open("libsqlite3.so")` in Dart.
Finally, pass `--target-platform=android-arm64` to the `flutter` command when running or building the app since `libsqlite3.so` was compiled for the `arm64-v8a` ABI.
