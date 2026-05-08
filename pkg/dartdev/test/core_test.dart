// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  initGlobalState();
  group('DartdevCommand', _dartdevCommand);
  group('Project', _project);
}

void _dartdevCommand() {
  void assertDartdevCommandProperties(
    DartdevCommand command,
    String name,
    String expectedUsagePath, [
    int subcommandCount = 0,
  ]) {
    expect(command, isNotNull);
    expect(command.name, name);
    expect(command.description, isNotEmpty);
    expect(command.project, isNotNull);
    expect(command.argParser, isNotNull);
    expect(command.subcommands.length, subcommandCount);
  }

  test('analyze', () {
    assertDartdevCommandProperties(AnalyzeCommand(), 'analyze', 'analyze');
  });

  test('compile', () {
    assertDartdevCommandProperties(CompileCommand(), 'compile', 'compile', 7);
  });

  test('compile/js', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['js'] as DartdevCommand,
      'js',
      'compile/js',
    );
  });

  test('compile/js-dev', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['js-dev'] as DartdevCommand,
      'js-dev',
      'compile/js-dev',
    );
  });

  test('compile/jit-snapshot', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['jit-snapshot'] as DartdevCommand,
      'jit-snapshot',
      'compile/jit-snapshot',
    );
  });

  test('compile/kernel', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['kernel'] as DartdevCommand,
      'kernel',
      'compile/kernel',
    );
  });

  test('compile/exe', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['exe'] as DartdevCommand,
      'exe',
      'compile/exe',
    );
  });

  test('compile/aot-snapshot', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['aot-snapshot'] as DartdevCommand,
      'aot-snapshot',
      'compile/aot-snapshot',
    );
  });

  test('compile/wasm', () {
    assertDartdevCommandProperties(
      CompileCommand().subcommands['wasm'] as DartdevCommand,
      'wasm',
      'compile/wasm',
    );
  });

  test('create', () {
    assertDartdevCommandProperties(CreateCommand(), 'create', 'create');
  });

  test('fix', () {
    assertDartdevCommandProperties(FixCommand(), 'fix', 'fix');
  });

  test('run', () {
    assertDartdevCommandProperties(RunCommand(verbose: false), 'run', 'run');
  });

  test('test', () {
    assertDartdevCommandProperties(TestCommand(), 'test', 'test');
  });
}

void _project() {
  test('hasPubspecFile positive', () {
    final p = project();
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPubspecFile, isTrue);
  });

  test('hasPubspecFile negative', () {
    final p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPubspecFile, isFalse);
  });
}
