// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() {
  testDartIntegration('stack traces are mapped to Dart source', (ctx) async {
    await ctx.ws.writeFileFromText(
      'pubspec.yaml',
      '{name: _, environment: {sdk: ^3.11.0}}',
    );
    await ctx.ws.pub(command: 'get');

    await ctx.ws.writeFileFromText('main.dart', '''
      void main() {
        try {
          foo();
        } catch (e, st) {
          print('caught: \$e');
          print('stackTrace:\\n\$st');
        }
      }

      void foo() => bar(); // Line 10

      void bar() => baz(); // Line 12

      void baz() => throw StateError('ExampleError'); // Line 14
    ''');

    await ctx.sandbox.run('main.dart', mode: 'console');
    await ctx.checkConsole(.it()..contains('ExampleError'));
    await ctx.checkConsole(
      .it()..like('''stackTrace:%
%main.dart 14:% baz
%main.dart 12:% bar
%main.dart 10:% foo
%main.dart %:% main%''', ignoreWhitespace: true),
    );
  });

  testDartIntegration('stack traces are remapped after hot reload', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText(
      'pubspec.yaml',
      '{name: _, environment: {sdk: ^3.11.0}}',
    );
    await ctx.ws.pub(command: 'get');

    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:async';

      void thrower() => throw StateError('boom'); // Line 3

      void tick() {
        try {
          thrower();
        } catch (e, st) {
          print('catch in generation 1:\\n\$st');
        }
      }

      void main() =>
          Timer.periodic(Duration(milliseconds: 100), (_) => tick());
    ''');
    await ctx.sandbox.run('main.dart', mode: 'console');
    await ctx.checkConsole(
      .it()..like('''
catch in generation 1:%
%main.dart 3:% thrower%''', ignoreWhitespace: true),
    );

    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:async';

      // padding 1
      // padding 2
      // padding 3
      // padding 4
      // padding 5
      void thrower() => throw StateError('boom'); // Line 8

      void tick() {
        try {
          thrower();
        } catch (e, st) {
          print('catch in generation 2:\\n\$st');
        }
      }

      void main() =>
          Timer.periodic(Duration(milliseconds: 100), (_) => tick());
    ''');
    await ctx.sandbox.hotReload();
    await ctx.checkConsole(
      .it()..like('''
catch in generation 2:%
%main.dart 8:% thrower%''', ignoreWhitespace: true),
    );
  });

  testDartIntegration('stack traces are remapped after hot restart', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText(
      'pubspec.yaml',
      '{name: _, environment: {sdk: ^3.11.0}}',
    );
    await ctx.ws.pub(command: 'get');

    await ctx.ws.writeFileFromText('main.dart', '''
      void thrower() => throw StateError('boom'); // Line 1

      void main() {
        try {
          thrower();
        } catch (e, st) {
          print('catch in generation 1:\\n\$st');
        }
      }
    ''');
    await ctx.sandbox.run('main.dart', mode: 'console');
    await ctx.checkConsole(
      .it()..like('''
catch in generation 1:%
%main.dart 1:% thrower%''', ignoreWhitespace: true),
    );

    await ctx.ws.writeFileFromText('main.dart', '''
      // padding 1
      // padding 2
      void thrower() => throw StateError('boom'); // Line 3

      void main() {
        try {
          thrower();
        } catch (e, st) {
          print('catch in generation 2:\\n\$st');
        }
      }
    ''');
    await ctx.sandbox.hotRestart();
    await ctx.checkConsole(
      .it()..like('''
catch in generation 2:%
%main.dart 3:% thrower%''', ignoreWhitespace: true),
    );
  });

  testDartIntegration('uncaught async errors are mapped to Dart source', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText(
      'pubspec.yaml',
      '{name: _, environment: {sdk: ^3.11.0}}',
    );
    await ctx.ws.pub(command: 'get');

    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:async';

      void main() {
        Timer(Duration(milliseconds: 10), boom);
      }

      void boom() => throw StateError('uncaught boom');
    ''');

    final firstError = ctx.sandbox.errors.first;
    await ctx.sandbox.run('main.dart', mode: 'console');

    await check(
      firstError,
    ).completes(.it()..like('%main.dart %:% boom%', ignoreWhitespace: true));
  });

  testDartIntegration('unhandled rejections are mapped to Dart source', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText(
      'pubspec.yaml',
      '{name: _, environment: {sdk: ^3.11.0}}',
    );
    await ctx.ws.pub(command: 'get');

    // The `Error` is constructed in the pad, so it captures Dart frames.
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:js_interop';

      @JS('Promise.reject')
      external void rejectPromise(JSAny? reason);

      @JS('Error')
      extension type JSError._(JSObject _) implements JSObject {
        external factory JSError(JSString message);
      }

      void main() => boom();                        // Line 11

      void boom() => rejectPromise(JSError('rejected boom'.toJS)); // Line 13
    ''');

    final firstRejection = ctx.sandbox.unhandledRejections.first;
    await ctx.sandbox.run('main.dart', mode: 'console');

    await check(firstRejection).completes(
      .it()..like('''
%rejected boom%
%main.dart 13:% boom
%main.dart 11:% main%''', ignoreWhitespace: true),
    );
  });

  testDartIntegration('stack traces reach into package dependencies', (
    ctx,
  ) async {
    await ctx.server.addPackage({
      'pubspec.yaml': '''
        name: thrower
        version: 1.0.0
        environment:
          sdk: ^3.10.0
      ''',
      'lib/thrower.dart': '''
        void throwFromPackage() => _boom();

        void _boom() => throw StateError('from thrower');
      ''',
    });

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: _
      dependencies:
        thrower: ^1.0.0
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');

    await ctx.ws.writeFileFromText('main.dart', '''
      import 'package:thrower/thrower.dart';

      void main() {
        try {
          throwFromPackage();
        } catch (e, st) {
          print('stackTrace:\\n\$st');
        }
      }
    ''');

    await ctx.sandbox.run('main.dart', mode: 'console');
    await ctx.checkConsole(
      .it()..like('''
stackTrace:%
%thrower.dart %:% _boom
%thrower.dart %:% throwFromPackage
%main.dart %:% main%
''', ignoreWhitespace: true),
    );
  });
}
