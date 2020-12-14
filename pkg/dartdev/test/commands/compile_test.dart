// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

const int compileErrorExitCode = 64;

void main() {
  group('compile', defineCompileTests, timeout: longTimeout);
}

void defineCompileTests() {
  // *** NOTE ***: These tests *must* be run with the `--use-sdk` option
  // as they depend on a fully built SDK to resolve various snapshot files
  // used by compilation.
  test('Running from built SDK', () {
    final Directory binDir = File(Platform.resolvedExecutable).parent;
    expect(binDir.path, contains('bin'));
  });

  test('Implicit --help', () {
    final p = project();
    var result = p.runSync(
      [
        'compile',
      ],
    );
    expect(result.stderr, contains('Compile Dart'));
    expect(result.exitCode, compileErrorExitCode);
  });

  test('--help', () {
    final p = project();
    final result = p.runSync(
      ['compile', '--help'],
    );
    expect(result.stdout, contains('Compile Dart'));
    expect(result.exitCode, 0);
  });

  test('Compile and run jit snapshot', () {
    final p = project(mainSrc: 'void main() { print("I love jit"); }');
    final outFile = path.join(p.dirPath, 'main.jit');
    var result = p.runSync(
      [
        'compile',
        'jit-snapshot',
        '-o',
        outFile,
        p.relativeFilePath,
      ],
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = p.runSync(['run', 'main.jit']);
    expect(result.stdout, contains('I love jit'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile and run executable', () {
    final p = project(mainSrc: 'void main() { print("I love executables"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'lib', 'main.exe'));

    var result = p.runSync(
      [
        'compile',
        'exe',
        inFile,
      ],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = Process.runSync(
      outFile,
      [],
    );

    expect(result.stdout, contains('I love executables'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile and run executable with options', () {
    final p = project(
        mainSrc: 'void main() {print(const String.fromEnvironment("life"));}');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = p.runSync(
      [
        'compile',
        'exe',
        '--define',
        'life=42',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = Process.runSync(
      outFile,
      [],
    );

    expect(result.stdout, contains('42'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile and run aot snapshot', () {
    final p = project(mainSrc: 'void main() { print("I love AOT"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.aot'));

    var result = p.runSync(
      [
        'compile',
        'aot-snapshot',
        '-o',
        'main.aot',
        inFile,
      ],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    final Directory binDir = File(Platform.resolvedExecutable).parent;
    result = Process.runSync(
      path.join(binDir.path, 'dartaotruntime'),
      [outFile],
    );

    expect(result.stdout, contains('I love AOT'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile and run kernel snapshot', () {
    final p = project(mainSrc: 'void main() { print("I love kernel"); }');
    final outFile = path.join(p.dirPath, 'main.dill');
    var result = p.runSync(
      [
        'compile',
        'kernel',
        '-o',
        outFile,
        p.relativeFilePath,
      ],
    );
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);

    result = p.runSync(['run', 'main.dill']);
    expect(result.stdout, contains('I love kernel'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile JS', () {
    final p = project(mainSrc: "void main() { print('Hello from JS'); }");
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.js'));

    final result = p.runSync([
      'compile',
      'js',
      '-m',
      '-o',
      outFile,
      '-v',
      inFile,
    ]);
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });
}
