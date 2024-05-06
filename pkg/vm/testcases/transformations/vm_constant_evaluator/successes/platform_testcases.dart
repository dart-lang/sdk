// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
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
  throw 'Unexpected platform: ${Platform.operatingSystem}';
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
  }
}

const bool kDebugMode = bool.fromEnvironment('test.define.debug');

TestPlatform? debugDefaultTestPlatform;

@pragma("vm:platform-const-if", !kDebugMode)
TestPlatform get defaultTestPlatformOverridableWhenDebug {
  late TestPlatform result;
  if (Platform.isAndroid) {
    result = TestPlatform.android;
  }
  if (Platform.isFuchsia) {
    result = TestPlatform.fuchsia;
  }
  if (Platform.isIOS) {
    result = TestPlatform.ios;
  }
  if (Platform.isLinux) {
    result = TestPlatform.linux;
  }
  if (Platform.isMacOS) {
    result = TestPlatform.macos;
  }
  if (Platform.isWindows) {
    result = TestPlatform.windows;
  }
  if (kDebugMode && debugDefaultTestPlatform != null) {
    result = debugDefaultTestPlatform!;
  }
  return result;
}

void testConditionalPragma(int i) {
  print(defaultTestPlatformOverridableWhenDebug);
  switch (defaultTestPlatformOverridableWhenDebug) {
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
  }
}

const bool enableAsserts = bool.fromEnvironment('test.define.enableAsserts');

@pragma("vm:platform-const-if", !enableAsserts)
TestPlatform get defaultTestPlatformOverridableWithAsserts {
  late TestPlatform result;
  if (Platform.isAndroid) {
    result = TestPlatform.android;
  }
  if (Platform.isFuchsia) {
    result = TestPlatform.fuchsia;
  }
  if (Platform.isIOS) {
    result = TestPlatform.ios;
  }
  if (Platform.isLinux) {
    result = TestPlatform.linux;
  }
  if (Platform.isMacOS) {
    result = TestPlatform.macos;
  }
  if (Platform.isWindows) {
    result = TestPlatform.windows;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = TestPlatform.android;
    }
    return true;
  }());
  return result;
}

void testConditionalPragmaWithAsserts(int i) {
  print(defaultTestPlatformOverridableWithAsserts);
  switch (defaultTestPlatformOverridableWithAsserts) {
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
  }
}

@pragma("vm:platform-const")
final bool isLinuxOrAndroid = Platform.isLinux || Platform.isAndroid;

@pragma("vm:platform-const")
final bool isIOSOrMacOS = () {
  if (Platform.isMacOS) return true;
  if (Platform.isIOS) return true;
  return false;
}();

void testFields(int i) {
  print(isLinuxOrAndroid);
  print(isIOSOrMacOS);
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
  debugDefaultTestPlatform = TestPlatform.android;
  testConditionalPragma(i);
  testConditionalPragmaWithAsserts(i);
  testFields(i);
}
