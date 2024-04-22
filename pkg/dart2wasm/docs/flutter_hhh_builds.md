# Building Flutter apps with newest Engine & newest Dart

## Modify the Flutter tools

Clone https://github.com/flutter/flutter. This repo contains the `flutter`
command line tool used to build Flutter apps. For building web apps it's using
the `dart compile wasm` command from the Dart SDK. We ensure it uses the Dart
SDK we built by patching the usages of the `dart` binary:

```
<flutter> % git diff
diff --git a/packages/flutter_tools/lib/src/artifacts.dart b/packages/flutter_tools/lib/src/artifacts.dart
index ba3703b86e..e0fb968fab 100644
--- a/packages/flutter_tools/lib/src/artifacts.dart
+++ b/packages/flutter_tools/lib/src/artifacts.dart
@@ -1174,6 +1174,7 @@ class CachedLocalEngineArtifacts implements Artifacts {
   }

   String _getDartSdkPath() {
+    return _dartSdkPath();
     final String builtPath = _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk');
     if (_fileSystem.isDirectorySync(_fileSystem.path.join(builtPath, 'bin'))) {
       return builtPath;
@@ -1404,6 +1405,7 @@ class CachedLocalWebSdkArtifacts implements Artifacts {
   }

   String _getDartSdkPath() {
+    return _dartSdkPath();
     // If we couldn't find a built dart sdk, let's look for a prebuilt one.
     final String prebuiltPath = _fileSystem.path.join(_getFlutterPrebuiltsPath(), _getPrebuiltTarget(), 'dart-sdk');
     if (_fileSystem.isDirectorySync(prebuiltPath)) {
@@ -1522,8 +1524,9 @@ class OverrideArtifacts implements Artifacts {
 }

 /// Locate the Dart SDK.
 String _dartSdkPath(Cache cache) {
-  return cache.getRoot().childDirectory('dart-sdk').path;
+  return '<path-to-dart-sdk-checkout>/out/ReleaseX64/dart-sdk';
 }

 class _TestArtifacts implements Artifacts {
```

We then ensure the Flutter tool is re-built via

```
<flutter> % rm bin/cache/flutter_tools.snapshot
```

=> Next time one runs `flutter` it will re-build the Flutter command line tool.

## Modify the Flutter engine

Building Flutter apps requires not only the dart2wasm compiler but also the
platform file. As there may be dependencies (e.g. adding a member in core
libraries that the compiler has an intrinsic for) we also need to ensure the
core libraries are compiled with the same Dart version (resulting in a correct
`dart2wasm_platform.dill` file that also includes the `dart:ui` Flutter
library).

### Build it

Create an engine checkout with:

```
% mkdir engine
% cd engine
<engine> % fetch flutter
```

Edit `.gclient` to add the `download_emsdk` custom variable:

```
solutions = [
  {
    "custom_deps": {},
    "deps_file": "DEPS",
    "managed": False,
    "name": "src/flutter",
    "safesync_url": "",
    "url": "https://github.com/flutter/engine.git",
    "custom_vars" : {
      "download_emsdk": True,
    },
  },
]
```

Sync dependencies and download emsdk:

```
<src> % gclient sync -D
```

Then checkout the Dart version we want. If the commit is available in the Dart
checkout from `<src>/flutter/third_party/dart` then one may

```
<src> % vim flutter/DEPS

<...update Dart revision hash...>

<src> % gclient sync -D
```

but for local development one may just

```
<src> % cd flutter/third_party/dart
<src>/flutter/third_party/dart % git checkout ...
```

Now we have to make some modification to ensure that the build of the platform
file doesn't use the downloaded prebuilt SDK but the one in
`<src>/flutter/third_party/dart`, we do that by applying the following patch:

```
<src>/flutter % git diff
diff --git a/web_sdk/BUILD.gn b/web_sdk/BUILD.gn
index f1383ae321..caa8aac8f1 100644
--- a/web_sdk/BUILD.gn
+++ b/web_sdk/BUILD.gn
@@ -266,17 +266,21 @@ template("_compile_platform") {
       "--source",
       "dart:_web_locale_keymap",
     ]
-    if (flutter_prebuilt_dart_sdk) {
-      args += [
-        "--multi-root",
-        "file:///" + rebase_path("$host_prebuilt_dart_sdk/.."),
-      ]
-    } else {
-      args += [
-        "--multi-root",
-        "file:///" + rebase_path("$root_out_dir"),
-      ]
-    }
+    args += [
+      "--multi-root",
+      "file:///<path-to-your-dart-sdk>/out/ReleaseX64",
+    ]
   }
 }
```

Then build the release web engine via

```
<src> % flutter/lib/web_ui/dev/felt build
```

NOTE: If you modify the Dart sources, the incremental build may not work
correctly. You man want to `rm -rf <src>/out/wasm_release/flutter_web_sdk` or
`rm -rf <src>/out`.

## Build the Dart SDK

Build the normal Dart SDK in the same version as used in Flutter engine via
`tools/build.py -mrelease create_sdk`

NOTE: You can (after syncing dependencies with `gclient sync -D`) make
`<src>/flutter/third_party/dart` a symlink to the normal Dart SDK you work on. That
avoids the need to keep the two in sync.

## Building a Flutter app (e.g. Wonderous)

```
<path-to-flutter-app> % flutter                                  \
        --local-engine-src-path=<path-to-flutter-engine-src>     \
        --local-web-sdk=wasm_release                             \
        build web --wasm
```

=> This will now use the `flutter` tools with our custom `dart compile wasm` with a
custom `dart2wasm_platform.dill` file.
