// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

String _platformPath(String name, {String path = ""}) {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
    return path + "lib" + name + ".so";
  if (Platform.isMacOS) return path + "lib" + name + ".dylib";
  if (Platform.isWindows) return path + name + ".dll";
  throw Exception("Platform not implemented");
}

ffi.DynamicLibrary dlopenPlatformSpecific(String name, {String path = ""}) {
  String fullPath = _platformPath(name, path: path);
  return ffi.DynamicLibrary.open(fullPath);
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<ffi.Void Function(), void Function()>("TriggerGC");
