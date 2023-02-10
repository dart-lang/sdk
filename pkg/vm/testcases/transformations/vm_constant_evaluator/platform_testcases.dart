// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void testAndroid(int i) {
  final b = Platform.isAndroid;
  print(b);
  if (Platform.isAndroid) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

void testFuchsia(int i) {
  final b = Platform.isFuchsia;
  print(b);
  if (Platform.isFuchsia) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

void testIOS(int i) {
  final b = Platform.isIOS;
  print(b);
  if (Platform.isIOS) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

void testLinux(int i) {
  final b = Platform.isLinux;
  print(b);
  if (Platform.isLinux) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

void testMacOS(int i) {
  final b = Platform.isMacOS;
  print(b);
  if (Platform.isMacOS) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

void testWindows(int i) {
  final b = Platform.isWindows;
  print(b);
  if (Platform.isWindows) {
    final os = Platform.operatingSystem;
    print(os);
    final sep = Platform.pathSeparator;
    print(sep);
  }
}

main(List<String> args) {
  if (args.isEmpty) return;
  final i = int.parse(args[0]);
  testAndroid(i);
  testFuchsia(i);
  testIOS(i);
  testLinux(i);
  testMacOS(i);
  testWindows(i);
}
