// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

final dartAotExecutable = Uri.parse(Platform.resolvedExecutable)
    .resolve('dartaotruntime')
    .toFilePath();
final dart2wasmSnapshot = Uri.parse(Platform.resolvedExecutable)
    .resolve('snapshots/dart2wasm_product.snapshot')
    .toFilePath();
final platformDill = Uri.parse(Platform.resolvedExecutable)
    .resolve('../lib/_internal/dart2wasm_platform.dill')
    .toFilePath();

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('dart2wasm_test');
  try {
    final testFile = File('${tempDir.path}/test.dart');
    testFile.writeAsStringSync('''
import 'dart:js_interop';
import 'package:does_not_exist/does_not_exist.dart';

@JS()
extension type WrappedJs(MissingType _) {
  external void member();
}

extension type Wrapped(MissingType _) implements JSObject {}

extension type WrappedPlain(MissingType _) {}

@JS()
external JSPromise<MissingType> fetchSomething(MissingType arg);

@JS()
external MissingType missingField;

@JS()
external void foo<T extends MissingType>(T x);

@JS()
external void nested<T extends JSPromise<MissingType>>(T x);

@JS()
external Wrapped bar();

@JS()
external WrappedPlain barPlain();

class FBounded<T extends FBounded<T>> {}

void checkFBounded<T extends FBounded<T>>(T value) {
  ((JSNumber _) {}).toJS;
}

void main(JSAny? any) {
  ((MissingType x) {}).toJS;
  (() async => null as WrappedPlain).toJS;
  any.isA<MissingType>();
  any.isA<Wrapped>();
}
''');

    final result = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      testFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out.wasm',
    ]);

    Expect.equals(254, result.exitCode);
    Expect.isTrue(
      result.stderr.toString().contains(
        "Error: Couldn't resolve the package 'does_not_exist'",
      ),
      'Expected unresolved package error on stderr, got:\n${result.stderr}',
    );
    Expect.isTrue(
      result.stdout.toString().isEmpty,
      'Expected empty stdout without false-positive dry-run findings, got:\n'
      '${result.stdout}',
    );

    final pureCfeErrorFile = File('${tempDir.path}/pure_cfe_error.dart');
    pureCfeErrorFile.writeAsStringSync('''
void main() {
  final int x = 'not an int';
  print(x);
}
''');

    final pureCfeResult = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      pureCfeErrorFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out_pure_cfe.wasm',
    ]);

    Expect.equals(254, pureCfeResult.exitCode);
    Expect.isTrue(
      pureCfeResult.stderr.toString().contains(
        "A value of type 'String' can't be assigned to a variable of type 'int'",
      ),
      'Expected CFE type error on stderr, got:\n${pureCfeResult.stderr}',
    );
    Expect.isTrue(
      pureCfeResult.stdout.toString().isEmpty,
      'Expected empty stdout for pure CFE error, got:\n${pureCfeResult.stdout}',
    );

    final htmlSymbolFile = File('${tempDir.path}/html_symbol.dart');
    htmlSymbolFile.writeAsStringSync('''
import 'dart:html';
import 'dart:js_interop';

extension type Wrapped(Window _) implements JSObject {}

@JS()
external Window get myWindow;

@JS()
external void foo<T extends Window>(T x);

@JS()
external void nested<T extends JSPromise<Window>>(T x);

@JS()
external Wrapped bar();

void main(JSAny? any) {
  Window? w;
  print(w);
  print(window);
  ((Window x) {}).toJS;
  any.isA<Window>();
  any.isA<Wrapped>();
}
''');

    final htmlResult = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      htmlSymbolFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out_html.wasm',
    ]);

    Expect.equals(254, htmlResult.exitCode);
    Expect.isTrue(
      htmlResult.stderr.toString().isEmpty,
      'Expected empty stderr when dart:html symbols are referenced, got:\n'
      '${htmlResult.stderr}',
    );
    Expect.isTrue(
      htmlResult.stdout.toString().contains('dart:html unsupported (0)'),
      'Expected dart:html finding (0) on stdout, got:\n${htmlResult.stdout}',
    );
    Expect.isFalse(
      htmlResult.stdout.toString().contains('<invalid>') ||
          htmlResult.stdout.toString().contains('invalid-type') ||
          htmlResult.stdout.toString().contains('(2)'),
      'Expected no cascading JS interop error on stdout, got:\n'
      '${htmlResult.stdout}',
    );

    final htmlAndInteropFile = File('${tempDir.path}/html_and_interop.dart');
    htmlAndInteropFile.writeAsStringSync('''
import 'dart:html';
import 'dart:js_interop';

@JS()
external Window get myWindow;

@JS()
external Object get badInteropGetter;

void genericHelper<T>(JSFunction fn) {}

void main() {
  genericHelper<Window>(((Object x) {}).toJS);
}
''');

    final htmlAndInteropResult = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      htmlAndInteropFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out_html_and_interop.wasm',
    ]);

    Expect.equals(254, htmlAndInteropResult.exitCode);
    Expect.isTrue(
      htmlAndInteropResult.stderr.toString().isEmpty,
      'Expected empty stderr when findings are reported, got:\n'
      '${htmlAndInteropResult.stderr}',
    );
    final mixedStdout = htmlAndInteropResult.stdout.toString();
    Expect.isTrue(
      mixedStdout.contains('dart:html unsupported (0)'),
      'Expected dart:html finding (0) on stdout, got:\n$mixedStdout',
    );
    Expect.isTrue(
      mixedStdout.contains(
            "External JS interop member contains an invalid type: 'Object'",
          ) &&
          mixedStdout.contains("Function converted via 'toJS'"),
      'Expected real JS interop findings (2) alongside dart:html, got:\n'
      '$mixedStdout',
    );
    Expect.isFalse(
      mixedStdout.contains('<invalid>') || mixedStdout.contains('invalid-type'),
      'Expected no cascading InvalidType findings on stdout, got:\n$mixedStdout',
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
