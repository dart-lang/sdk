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

void testSwitchStatements(int i) {
  switch (Platform.operatingSystem) {
    case "android":
      print("is android");
      break;
    case "fuchsia":
      print("is fuchsia");
      break;
    case "ios":
      print("is ios");
      break;
    case "linux":
      print("is linux");
      break;
    case "macos":
      print("is macos");
      break;
    case "windows":
      print("is windows");
      break;
    default:
      throw "Unexpected platform";
  }
}

enum TestPlatform {
  android,
  fuchsia,
  ios,
  linux,
  macos,
  windows,
}

@pragma("vm:platform-const")
TestPlatform get defaultTestPlatform {
  if (Platform.isAndroid) return TestPlatform.android;
  if (Platform.isFuchsia) return TestPlatform.fuchsia;
  if (Platform.isIOS) return TestPlatform.ios;
  if (Platform.isLinux) return TestPlatform.linux;
  if (Platform.isMacOS) return TestPlatform.macos;
  if (Platform.isWindows) return TestPlatform.windows;
  throw 'Unexpected platform';
}

void testPragma(int i) {
  print(defaultTestPlatform);
  switch (defaultTestPlatform) {
    case TestPlatform.android:
      print("is android");
      break;
    case TestPlatform.fuchsia:
      print("is fuchsia");
      break;
    case TestPlatform.ios:
      print("is ios");
      break;
    case TestPlatform.linux:
      print("is linux");
      break;
    case TestPlatform.macos:
      print("is macos");
      break;
    case TestPlatform.windows:
      print("is windows");
      break;
    default:
      throw "Unexpected platform";
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
  testSwitchStatements(i);
  testPragma(i);
}
