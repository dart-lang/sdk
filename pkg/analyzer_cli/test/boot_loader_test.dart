// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.boot_loader_test;

import 'dart:io';

import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:analyzer_cli/src/boot_loader.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

main() {
  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  /// Base setup.
  _setUp() {
    savedOutSink = outSink;
    savedErrorSink = errorSink;
    savedExitHandler = exitHandler;
    savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = new StringBuffer();
    errorSink = new StringBuffer();
  }

  /// Base teardown.
  _tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }

  setUp(() => _setUp());

  tearDown(() => _tearDown());

  group('Bootloader', () {
    group('plugin processing', () {
      test('bad format', () {
        BootLoader loader = new BootLoader();
        loader.createImage([
          '--options',
          path.join(testDirectory, 'data/bad_plugin_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        expect(
            errorSink.toString(),
            'Plugin configuration skipped: Unrecognized plugin config '
            'format, expected `YamlMap`, got `YamlList` '
            '(line 2, column 4)\n');
      });
      test('plugin config', () {
        BootLoader loader = new BootLoader();
        Image image = loader.createImage([
          '--options',
          path.join(testDirectory, 'data/plugin_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        var plugins = image.config.plugins;
        expect(plugins, hasLength(1));
        expect(plugins.first.name, 'my_plugin1');
      });
      group('plugin validation', () {
        test('requires class name', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin', libraryUri: 'my_package/foo.dart')),
              isNotNull);
        });
        test('requires library URI', () {
          expect(
              validate(
                  new PluginInfo(name: 'test_plugin', className: 'MyPlugin')),
              isNotNull);
        });
        test('check', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin',
                  className: 'MyPlugin',
                  libraryUri: 'my_package/foo.dart')),
              isNull);
        });
      });
    });
  });
}
