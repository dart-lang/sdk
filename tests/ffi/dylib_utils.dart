// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

final _dylibExtension = () {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
    return '.so';
  if (Platform.isMacOS) return '.dylib';
  if (Platform.isWindows) return '.dll';
  throw Exception('Platform not implemented.');
}();

final _dylibPrefix = Platform.isWindows ? '' : 'lib';

String dylibName(String name) => '$_dylibPrefix$name$_dylibExtension';

String platformPath(String name, {String? path}) {
  path ??= '';
  return path + dylibName(name);
}

DynamicLibrary dlopenPlatformSpecific(String name, {String? path}) {
  String fullPath = platformPath(name, path: path);
  return DynamicLibrary.open(fullPath);
}

/// On Linux and Android.
const RTLD_LAZY = 0x00001;

/// On Android Arm.
const RTLD_GLOBAL_android_arm32 = 0x00002;

/// On Linux and Android Arm64.
const RTLD_GLOBAL_rest = 0x00100;

final RTLD_GLOBAL = Abi.current() == Abi.androidArm
    ? RTLD_GLOBAL_android_arm32
    : RTLD_GLOBAL_rest;

@Native<Pointer<Void> Function(Pointer<Char>, Int)>()
external Pointer<Void> dlopen(Pointer<Char> file, int mode);

/// Returns dylib
Object dlopenGlobalPlatformSpecific(String name, {String? path}) {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia) {
    // TODO(https://dartbug.com/50105): enable dlopen global via package:ffi.
    return using((arena) {
      final dylibHandle = dlopen(
          platformPath(name).toNativeUtf8(allocator: arena).cast(),
          RTLD_LAZY | RTLD_GLOBAL);
      return dylibHandle;
    });
  } else {
    // The default behavior on these platforms is RLTD_GLOBAL already.
    return dlopenPlatformSpecific(name, path: path);
  }
}
