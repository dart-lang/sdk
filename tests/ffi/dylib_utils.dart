// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

final _dylibExtension = () {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
    return '.so';
  if (Platform.isMacOS) return '.dylib';
  if (Platform.isWindows) return '.dll';
  throw Exception('Platform not implemented.');
}();

final _dylibPrefix = Platform.isWindows ? '' : 'lib';

String dylibName(String name) => '$_dylibPrefix$name$_dylibExtension';

String _platformPath(String name, {String? path}) {
  path ??= '';
  return path + dylibName(name);
}

ffi.DynamicLibrary dlopenPlatformSpecific(String name, {String? path}) {
  String fullPath = _platformPath(name, path: path);
  return ffi.DynamicLibrary.open(fullPath);
}
