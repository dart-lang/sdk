// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:dartdev/src/target.dart';
import 'package:test/test.dart';

void main() {
  test('OS naming conventions', () async {
    expect(OS.android.dylibFileName('foo'), 'libfoo.so');
    expect(OS.android.staticlibFileName('foo'), 'libfoo.a');
    expect(OS.windows.dylibFileName('foo'), 'foo.dll');
    expect(
      OS.windows.libraryFileName('foo', DynamicLoadingBundled()),
      'foo.dll',
    );
    expect(OS.windows.staticlibFileName('foo'), 'foo.lib');
    expect(OS.windows.libraryFileName('foo', StaticLinking()), 'foo.lib');
    expect(OS.windows.executableFileName('foo'), 'foo.exe');
  });

  test('Target current', () async {
    final current = Target.current;
    expect(current.toString(), Abi.current().toString());
  });

  test('Target fromDartPlatform', () async {
    final current = Target.fromDartPlatform(Platform.version);
    expect(current.toString(), Abi.current().toString());
    expect(
      () => Target.fromDartPlatform('bogus'),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message.contains('bogus') &&
              e.message.contains('Unknown version'),
        ),
      ),
    );
    expect(
      () => Target.fromDartPlatform(
        '3.0.0 (be) (Wed Apr 5 14:19:42 2023 +0000) on "myfancyos_ia32"',
      ),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message.contains('myfancyos_ia32') &&
              e.message.contains('Unknown ABI'),
        ),
      ),
    );
  });

  test('Target cross compilation', () async {
    // All hosts can cross compile to Android.
    expect(
      Target.current.supportedTargetTargets(),
      contains(Target.androidArm64),
    );
    expect(
      Target.macOSArm64.supportedTargetTargets(),
      contains(Target.iOSArm64),
    );
  });

  test('Target fromArchitectureAndOS', () async {
    final current = Target.fromArchitectureAndOS(
      Architecture.current,
      OS.current,
    );
    expect(current.toString(), Abi.current().toString());

    expect(
      () => Target.fromArchitectureAndOS(Architecture.arm, OS.windows),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              (e.message as String).contains('arm') &&
              (e.message as String).contains('windows'),
        ),
      ),
    );
  });
}
