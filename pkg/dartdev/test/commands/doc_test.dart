// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

const int compileErrorExitCode = 64;

void main() {
  group('doc', defineCompileTests, timeout: longTimeout);
}

void defineCompileTests() {
  test('Passing no args fails', () async {
    final p = project();
    var result = await p.run(['doc']);
    expect(result.stderr, contains('Input directory not specified'));
    expect(result.exitCode, compileErrorExitCode);
  });

  test('--help', () async {
    final p = project();
    final result = await p.run(['doc', '--help']);
    expect(
      result.stdout,
      contains('Usage: dart doc [arguments] <input directory>'),
    );

    expect(result.exitCode, 0);
  });

  test('Document a library', () async {
    final source = '''
/// This is Foo. It uses [Bar].
class Foo {
    Bar bar;
}

/// Bar is very nice.
class Bar {
    _i = 42;
}
    ''';

    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', source);
    final result = await p.run(['doc', '--validate-links', p.dirPath]);
    print(
        'exit: ${result.exitCode}, stderr:\n${result.stderr}\nstdout:\n${result.stdout}');
    expect(result.stdout, contains('Documenting dartdev_temp'));
  });

  test('Document a library with broken link is flagged', () async {
    final source = '''
/// This is Foo. It uses [Baz].
class Foo {
  //  Bar bar;
}
    ''';

    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', source);
    final result = await p.run(['doc', '--validate-links', p.dirPath]);
    print(
        'exit: ${result.exitCode}, stderr:\n${result.stderr}\nstdout:\n${result.stdout}');
    expect(result.stdout, contains('Documenting dartdev_temp'));
  });
}
