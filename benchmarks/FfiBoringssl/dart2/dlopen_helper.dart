// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

const kArm = "arm";
const kArm64 = "arm64";
const kIa32 = "ia32";
const kX64 = "x64";

// https://stackoverflow.com/questions/45125516/possible-values-for-uname-m
final _unames = {
  "arm": kArm,
  "aarch64_be": kArm64,
  "aarch64": kArm64,
  "armv8b": kArm64,
  "armv8l": kArm64,
  "i386": kIa32,
  "i686": kIa32,
  "x86_64": kX64,
};

String _checkRunningMode(String architecture) {
  // Check if we're running in 32bit mode.
  final int pointerSize = sizeOf<IntPtr>();
  if (pointerSize == 4 && architecture == kX64) return kIa32;
  if (pointerSize == 4 && architecture == kArm64) return kArm;

  return architecture;
}

String _architecture() {
  final String uname = Process.runSync("uname", ["-m"]).stdout.trim();
  final String architecture = _unames[uname];
  if (architecture == null)
    throw Exception("Unrecognized architecture: '$uname'");

  // Check if we're running in 32bit mode.
  return _checkRunningMode(architecture);
}

String _platformPath(String name, {String path = ""}) {
  if (Platform.isMacOS || Platform.isIOS)
    return "${path}mac/${_architecture()}/lib$name.dylib";

  if (Platform.isWindows)
    return "${path}win/${_checkRunningMode(kX64)}/$name.dll";

  // Unknown platforms default to Unix implementation.
  return "${path}linux/${_architecture()}/lib$name.so";
}

DynamicLibrary dlopenPlatformSpecific(String name, {String path}) {
  final String fullPath = _platformPath(name, path: path);
  return DynamicLibrary.open(fullPath);
}
