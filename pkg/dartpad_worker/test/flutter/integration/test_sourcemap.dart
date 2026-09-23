// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() =>
    testFlutterIntegration('stack traces are mapped (flutter)', (ctx) async {
      await ctx.ws.writeFileFromText('pubspec.yaml', '''
        name: myapp
        environment:
          sdk: ^3.12.0
        dependencies:
          flutter:
            sdk: flutter
      ''');

      await ctx.ws.pub(command: 'get');

      await ctx.ws.writeFileFromText('main.dart', r'''
        import 'package:flutter/material.dart';

        void main() {
          try {
            boom(); // Line  5
          } catch (e, st) {
            print('caught: $e');
            print('stackTrace:\n$st');
          }
          runApp(const MyApp());
        }

        void boom() => throw StateError('from boom'); // Line 13

        class MyApp extends StatelessWidget {
          const MyApp({super.key});

          @override
          Widget build(BuildContext context) {
            throw StateError('from build'); // Line 20
          }
        }
      ''');

      await ctx.sandbox.run('main.dart', mode: 'flutter');

      await ctx.checkConsole(
        .it()..like('''
stackTrace:%
%main.dart 13:% boom
%main.dart 5:% main%''', ignoreWhitespace: true),
      );

      // The framework catches the exception from `build`
      await ctx.checkConsole(
        .it()..like('''
%EXCEPTION CAUGHT BY WIDGETS%
%main.dart 20:% build%''', ignoreWhitespace: true),
      );
    });
