// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for doc.
library dartdocTests;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../lib/dartdoc.dart' as dd;
import '../lib/markdown.dart';
import 'markdown_test.dart';

main() {
  // Some tests take more than the default 20 second unittest timeout.
  unittestConfiguration.timeout = null;
  group('isAbsolute', () {
    final doc = new dd.Dartdoc();

    test('returns false if there is no scheme', () {
      expect(doc.isAbsolute('index.html'), isFalse);
      expect(doc.isAbsolute('foo/index.html'), isFalse);
      expect(doc.isAbsolute('foo/bar/index.html'), isFalse);
    });

    test('returns true if there is a scheme', () {
      expect(doc.isAbsolute('http://google.com'), isTrue);
      expect(doc.isAbsolute('hTtPs://google.com'), isTrue);
      expect(doc.isAbsolute('mailto:fake@email.com'), isTrue);
    });
  });

  group('relativePath', () {
    final doc = new dd.Dartdoc();

    test('absolute path is unchanged', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('http://foo.com'), equals('http://foo.com'));
    });

    test('from root to root', () {
      doc.startFile('root.html');
      expect(doc.relativePath('other.html'), equals('other.html'));
    });

    test('from root to directory', () {
      doc.startFile('root.html');
      expect(doc.relativePath('dir/file.html'), equals('dir/file.html'));
    });

    test('from root to nested', () {
      doc.startFile('root.html');
      expect(doc.relativePath('dir/sub/file.html'), equals(
          'dir/sub/file.html'));
    });

    test('from directory to root', () {
      doc.startFile('dir/file.html');
      expect(doc.relativePath('root.html'), equals('../root.html'));
    });

    test('from nested to root', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('root.html'), equals('../../root.html'));
    });

    test('from dir to dir with different path', () {
      doc.startFile('dir/file.html');
      expect(doc.relativePath('other/file.html'), equals('../other/file.html'));
    });

    test('from nested to nested with different path', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('other/sub/file.html'), equals(
          '../../other/sub/file.html'));
    });

    test('from nested to directory with different path', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('other/file.html'), equals(
          '../../other/file.html'));
    });
  });

  group('dartdoc markdown', () {
    group('[::] blocks', () {

      validateDartdocMarkdown('simple case', '''
        before [:source:] after
        ''', '''
        <p>before <code>source</code> after</p>
        ''');

      validateDartdocMarkdown('unmatched [:', '''
        before [: after
        ''', '''
        <p>before [: after</p>
        ''');
      validateDartdocMarkdown('multiple spans in one text', '''
        a [:one:] b [:two:] c
        ''', '''
        <p>a <code>one</code> b <code>two</code> c</p>
        ''');

      validateDartdocMarkdown('multi-line', '''
        before [:first
        second:] after
        ''', '''
        <p>before <code>first
        second</code> after</p>
        ''');

      validateDartdocMarkdown('contain backticks', '''
        before [:can `contain` backticks:] after
        ''', '''
        <p>before <code>can `contain` backticks</code> after</p>
        ''');

      validateDartdocMarkdown('contain double backticks', '''
        before [:can ``contain`` backticks:] after
        ''', '''
        <p>before <code>can ``contain`` backticks</code> after</p>
        ''');

      validateDartdocMarkdown('contain backticks with spaces', '''
        before [: `tick` :] after
        ''', '''
        <p>before <code>`tick`</code> after</p>
        ''');

      validateDartdocMarkdown('multiline with spaces', '''
        before [:in `tick`
        another:] after
        ''', '''
        <p>before <code>in `tick`
        another</code> after</p>
        ''');

      validateDartdocMarkdown('ignore markup inside code', '''
        before [:*b* _c_:] after
        ''', '''
        <p>before <code>*b* _c_</code> after</p>
        ''');

      validateDartdocMarkdown('escape HTML characters', '''
        [:<&>:]
        ''', '''
        <p><code>&lt;&amp;&gt;</code></p>
        ''');

      validateDartdocMarkdown('escape HTML tags', '''
        '*' [:<em>:]
        ''', '''
        <p>'*' <code>&lt;em&gt;</code></p>
        ''');
    });
  });

  group('integration tests', () {
    test('no entrypoints', () {
      _testRunDartDoc([], (result) {
            expect(result.exitCode, 1);
          });
    });

    test('entrypoint in lib', () {
      _testRunDartDoc(['test_files/lib/no_package_test_file.dart'], (result) {
        expect(result.exitCode, 0);
        _expectDocumented(result.stdout, libCount: 1, typeCount: 1, memberCount: 0);
      });
    });

    test('entrypoint somewhere with packages locally', () {
      _testRunDartDoc(['test_files/package_test_file.dart'], (result) {
        expect(result.exitCode, 0);
        _expectDocumented(result.stdout, libCount: 1, typeCount: 1, memberCount: 0);
      });
    });

    test('file does not exist', () {
      _testRunDartDoc(['test_files/this_file_does_not_exist.dart'], (result) {
        expect(result.exitCode, 1);
      });
    });
  });
}

void _testRunDartDoc(List<String> libraryPaths, void eval(ProcessResult)) {
  expect(_runDartdoc(libraryPaths).then(eval), completes);
}

/// The path to the root directory of the dartdoc entrypoint.
String get _dartdocDir {
  var dir = path.absolute(Platform.script.toFilePath());
  while (path.basename(dir) != 'dartdoc') {
    if (!path.absolute(dir).contains('dartdoc') || dir == path.dirname(dir)) {
      fail('Unable to find root dartdoc directory.');
    }
    dir = path.dirname(dir);
  }
  return path.absolute(dir);
}

/// The path to use for the package root for subprocesses.
String get _packageRoot {
  var sdkVersionPath = path.join(_dartdocDir, '..', '..', '..', 'version');
  if (new File(sdkVersionPath).existsSync()) {
    // It looks like dartdoc is being run from the SDK, so we should set the
    // package root to the SDK's packages directory.
    return path.absolute(path.join(_dartdocDir, '..', '..', '..', 'packages'));
  }

  // It looks like Dartdoc is being run from the Dart repo, so the package root
  // is in the build output directory. We can find that directory relative to
  // the Dart executable, but that could be in one of two places: in
  // "$BUILD/dart" or "$BUILD/dart-sdk/bin/dart".
  var executableDir = path.dirname(Platform.executable);
  if (new Directory(path.join(executableDir, 'dart-sdk')).existsSync()) {
    // The executable is in "$BUILD/dart".
    return path.absolute(path.join(executableDir, 'packages'));
  } else {
    // The executable is in "$BUILD/dart-sdk/bin/dart".
    return path.absolute(path.join(executableDir, '..', '..', 'packages'));
  }
}

/// Runs dartdoc with the libraryPaths provided, and completes to dartdoc's
/// ProcessResult.
Future<ProcessResult> _runDartdoc(List<String> libraryPaths) {
  var dartBin = Platform.executable;

  var dartdoc = path.join(_dartdocDir, 'bin/dartdoc.dart');

  final runArgs = ['--package-root=$_packageRoot/', dartdoc];

  // Turn relative libraryPaths to absolute ones.
  runArgs.addAll(libraryPaths
      .map((e) => path.join(path.absolute(dd.scriptDir), e)));

  return Process.run(dartBin, runArgs);
}

final _dartdocCompletionRegExp =
  new RegExp(r'Documentation complete -- documented (\d+) libraries, (\d+) types, and (\d+) members\.');

void _expectDocumented(String output, { int libCount, int typeCount,
  int memberCount}) {

  final completionMatches = _dartdocCompletionRegExp.allMatches(output)
      .toList();

  expect(completionMatches, hasLength(1),
      reason: 'dartdoc output should contain one summary');

  final completionMatch = completionMatches.single;

  if(libCount != null) {
    expect(int.parse(completionMatch[1]), libCount,
        reason: 'expected library count');
  }

  if(typeCount != null) {
    expect(int.parse(completionMatch[2]), typeCount,
        reason: 'expected type count');
  }

  if(memberCount != null) {
    expect(int.parse(completionMatch[3]), memberCount,
        reason: 'expected member count');
  }
}


validateDartdocMarkdown(String description, String markdown,
    String html) {
  var dartdoc = new dd.Dartdoc();
  validate(description, markdown, html, linkResolver: dartdoc.dartdocResolver,
      inlineSyntaxes: dartdoc.dartdocSyntaxes);
}
