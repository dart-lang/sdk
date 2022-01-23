// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

const int compileErrorExitCode = 64;

void main() {
  group('doc', defineDocTests, timeout: longTimeout);
}

void defineDocTests() {
  test('Passing no args fails', () async {
    final p = project();
    final result = await p.run(['doc']);
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
    expect(result.stdout, contains('Documenting dartdev_temp'));
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
    // TODO (mit@): Update this test to actually test for the
    // --validate-links flag.
    expect(result.stdout, contains('Documenting dartdev_temp'));
  });
}
