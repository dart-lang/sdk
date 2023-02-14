// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

const int errorExitCode = 64;

void main() {
  group('doc', defineDocTests, timeout: longTimeout);
}

void defineDocTests() {
  ensureRunFromSdkBinDart();

  test('--help', () async {
    final p = project();
    final result = await p.run(['doc', '--help']);
    expect(
      result.stdout,
      contains('Usage: dart doc [arguments] [<directory>]'),
    );
    expect(result.exitCode, 0);
  });

  test('Passing conflicting options fails', () async {
    final p = project();
    final result =
        await p.run(['doc', '--validate-links', '--dry-run', p.dirPath]);
    expect(
      result.stderr,
      contains("'dart doc' can not validate links when dry-running."),
    );
    expect(result.exitCode, errorExitCode);
  });

  test('Passing multiple directories fails', () async {
    final p = project();
    final result = await p.run(['doc', 'foo', 'bar']);
    expect(result.stderr,
        contains("'dart doc' only supports one input directory.'"));
    expect(result.exitCode, errorExitCode);
  });

  test('defaults to documenting cwd', () async {
    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', '''
/// This is Foo. It uses [Bar].
class Foo {
  Bar bar;
}

/// Bar is very nice.
class Bar {
  _i = 42;
}
''');
    final result = await p.run(['doc'], workingDir: p.dirPath);
    expect(result.stdout, contains('Documenting dartdev_temp'));
    expect(result.exitCode, 0);
  });

  test('Document a library', () async {
    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', '''
/// This is Foo. It uses [Bar].
class Foo {
  Bar bar;
}

/// Bar is very nice.
class Bar {
  _i = 42;
}
''');
    final result = await p.run(['doc', '--validate-links', p.dirPath]);
    expect(result.stdout, contains('Documenting dartdev_temp'));
    expect(result.exitCode, 0);
  });

  test('Document a library dry-run', () async {
    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', '''
/// This is Foo.
class Foo {
  int i = 42;
}
''');
    final result = await p.run(['doc', '--dry-run', '--verbose', p.dirPath]);
    expect(result.stdout, contains('Using the following options: [--input='));
    // TODO(devoncarew): We should update package:dartdoc to emit some
    // "Documenting ..." text here.
    expect(result.stdout, isNot(contains('Documenting dartdev_temp')));
    expect(result.exitCode, 0);
  });

  test('Errors cause error code', () async {
    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', '''
/// This is Foo. It uses [TypeThatIsntDeclared].
class Foo {
  int i = 42;
}
''');
    p.file('dartdoc_options.yaml', '''
dartdoc:
  errors:
    - unresolved-doc-reference
''');
    final result = await p.run(['doc', p.dirPath]);
    expect(result.exitCode, 1);
  });

  test('Document a library with broken link is flagged', () async {
    final source = '''
/// This is Foo. It uses [Baz].
class Foo {
  int i = 42;
}
''';

    final p = project(mainSrc: 'void main() { print("Hello, World"); }');
    p.file('lib/foo.dart', source);
    final result = await p.run(['doc', '--validate-links', p.dirPath]);
    // TODO (mit): Update this test to actually test for the
    // --validate-links flag.
    expect(result.stdout, contains('Documenting dartdev_temp'));
  });
}
