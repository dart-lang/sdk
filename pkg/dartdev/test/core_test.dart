// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/analyze.dart';
import 'package:dartdev/src/commands/compile.dart';
import 'package:dartdev/src/commands/create.dart';
import 'package:dartdev/src/commands/fix.dart';
import 'package:dartdev/src/commands/run.dart';
import 'package:dartdev/src/commands/test.dart';
import 'package:dartdev/src/core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('DartdevCommand', _dartdevCommand);
  group('PackageConfig', _packageConfig);
  group('Project', _project);
}

void _dartdevCommand() {
  void _assertDartdevCommandProperties(
      DartdevCommand command, String name, String expectedUsagePath,
      [int subcommandCount = 0]) {
    expect(command, isNotNull);
    expect(command.name, name);
    expect(command.description, isNotEmpty);
    expect(command.project, isNotNull);
    expect(command.argParser, isNotNull);
    expect(command.subcommands.length, subcommandCount);
  }

  test('analyze', () {
    _assertDartdevCommandProperties(AnalyzeCommand(), 'analyze', 'analyze');
  });

  test('compile', () {
    _assertDartdevCommandProperties(CompileCommand(), 'compile', 'compile', 5);
  });

  test('compile/js', () {
    _assertDartdevCommandProperties(
        CompileCommand().subcommands['js'], 'js', 'compile/js');
  });

  test('compile/jit-snapshot', () {
    _assertDartdevCommandProperties(
        CompileCommand().subcommands['jit-snapshot'],
        'jit-snapshot',
        'compile/jit-snapshot');
  });

  test('compile/kernel', () {
    _assertDartdevCommandProperties(
        CompileCommand().subcommands['kernel'], 'kernel', 'compile/kernel');
  });

  test('compile/exe', () {
    _assertDartdevCommandProperties(
        CompileCommand().subcommands['exe'], 'exe', 'compile/exe');
  });

  test('compile/aot-snapshot', () {
    _assertDartdevCommandProperties(
        CompileCommand().subcommands['aot-snapshot'],
        'aot-snapshot',
        'compile/aot-snapshot');
  });

  test('create', () {
    _assertDartdevCommandProperties(CreateCommand(), 'create', 'create');
  });

  test('fix', () {
    _assertDartdevCommandProperties(FixCommand(), 'fix', 'fix');
  });

  test('run', () {
    _assertDartdevCommandProperties(RunCommand(verbose: false), 'run', 'run');
  });

  test('test', () {
    _assertDartdevCommandProperties(TestCommand(), 'test', 'test');
  });
}

void _packageConfig() {
  test('packages', () {
    PackageConfig packageConfig = PackageConfig(jsonDecode(_packageData));
    expect(packageConfig.packages, isNotEmpty);
  });

  test('hasDependency', () {
    PackageConfig packageConfig = PackageConfig(jsonDecode(_packageData));
    expect(packageConfig.hasDependency('test'), isFalse);
    expect(packageConfig.hasDependency('pedantic'), isTrue);
  });
}

void _project() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('hasPubspecFile positive', () {
    p = project();
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPubspecFile, isTrue);
  });

  test('hasPubspecFile negative', () {
    p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPubspecFile, isFalse);
  });

  test('hasPackageConfigFile positive', () {
    p = project();
    p.file('.dart_tool/package_config.json', _packageData);
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPackageConfigFile, isTrue);
    expect(coreProj.packageConfig, isNotNull);
    expect(coreProj.packageConfig.packages, isNotEmpty);
  });

  test('hasPackageConfigFile negative', () {
    p = project();
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPackageConfigFile, isFalse);
  });
}

const String _packageData = '''{
  "configVersion": 2,
  "packages": [
    {
      "name": "pedantic",
      "rootUri": "file:///Users/.../.pub-cache/hosted/pub.dartlang.org/pedantic-1.9.0",
      "packageUri": "lib/",
      "languageVersion": "2.1"
    },
    {
      "name": "args",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ],
  "generated": "2020-03-01T03:38:14.906205Z",
  "generator": "pub",
  "generatorVersion": "2.8.0-dev.10.0"
}
''';
