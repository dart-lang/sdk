// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

const arm = 'arm';
const arm64 = 'arm64';
const ia32 = 'ia32';
const x64 = 'x64';

// https://stackoverflow.com/questions/45125516/possible-values-for-uname-m
final _unames = {
  'arm': arm,
  'arm64': arm64,
  'aarch64_be': arm64,
  'aarch64': arm64,
  'armv8b': arm64,
  'armv8l': arm64,
  'i386': ia32,
  'i686': ia32,
  'x86_64': x64,
};

String _checkRunningMode(String architecture) {
  // Check if we're running in 32bit mode.
  final int pointerSize = sizeOf<IntPtr>();
  if (pointerSize == 4 && architecture == x64) return ia32;
  if (pointerSize == 4 && architecture == arm64) return arm;

  return architecture;
}

String _architecture() {
  final String uname = Process.runSync('uname', ['-m']).stdout.trim();
  final String? architecture = _unames[uname];
  if (architecture == null) {
    throw Exception('Unrecognized architecture: "$uname"');
  }

  // Check if we're running in 32bit mode.
  return _checkRunningMode(architecture);
}

String _platformPath(String name, String path) {
  if (Platform.isMacOS || Platform.isIOS) {
    return '${path}mac/${_architecture()}/lib$name.dylib';
  }

  if (Platform.isWindows) {
    return '${path}win/${_checkRunningMode(x64)}/$name.dll';
  }

  // Unknown platforms default to Unix implementation.
  return '${path}linux/${_architecture()}/lib$name.so';
}

DynamicLibrary dlopenPlatformSpecific(String name, {String path = ''}) {
  final String fullPath = _platformPath(name, path);
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

Object dlopenGlobalPlatformSpecific(String name, {String path = ''}) {
  if (Platform.isLinux || Platform.isAndroid) {
    // TODO(https://dartbug.com/50105): enable dlopen global via package:ffi.
    return using((arena) {
      final dylibHandle = dlopen(
          _platformPath(name, path).toNativeUtf8(allocator: arena).cast(),
          RTLD_LAZY | RTLD_GLOBAL);
      return dylibHandle;
    });
  }

  return dlopenPlatformSpecific(name, path: path);
}
