// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' show File, Platform;

Uri dylibPath(String name, Uri path) {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia) {
    return path.resolve("lib$name.so");
  }
  if (Platform.isMacOS) return path.resolve("lib$name.dylib");
  if (Platform.isWindows) return path.resolve("$name.dll");
  throw Exception("Platform not implemented");
}

DynamicLibrary dlopenPlatformSpecific(String name, {List<Uri>? paths}) =>
    DynamicLibrary.open((paths ?? [Uri()])
        .map((path) => dylibPath(name, path).toFilePath())
        .firstWhere((lib) => File(lib).existsSync()));
