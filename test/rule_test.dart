// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.rule;

import 'dart:io';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/io.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/camel_case_types.dart';
import 'package:linter/src/rules/implementation_imports.dart';
import 'package:linter/src/rules/package_prefixed_library_names.dart';
import 'package:linter/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  defineSanityTests();
  defineRuleTests();
  defineRuleUnitTests();
}

final String ruleDir = p.join('test', 'rules');

/// Rule tests
defineRuleTests() {
  //TODO: if ruleDir cannot be found print message to set CWD to project root
  group('rule', () {
    group('dart', () {
      for (var entry in new Directory(ruleDir).listSync()) {
        if (entry is! File || !isDartFile(entry)) continue;
        var ruleName = p.basenameWithoutExtension(entry.path);
        testRule(ruleName, entry);
      }
    });
    group('pub', () {
      for (var entry in new Directory(p.join(ruleDir, 'pub')).listSync()) {
        if (entry is! Directory) continue;
        Directory pubTestDir = entry;
        for (var file in pubTestDir.listSync()) {
          if (file is! File || !isPubspecFile(file)) continue;
          var ruleName = p.basename(pubTestDir.path);
          testRule(ruleName, file);
        }
      }
    });
  });
}

defineRuleUnitTests() {
  group('uris', () {
    group('isPackage', () {
      var uris = [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ];
      uris.forEach((uri) {
        test(uri.toString(), () {
          expect(isPackage(uri), isTrue);
        });
      });
      var uris2 = [
        Uri.parse('foo/bar.dart'),
        Uri.parse('src/bar.dart'),
        Uri.parse('dart:async')
      ];
      uris2.forEach((uri) {
        test(uri.toString(), () {
          expect(isPackage(uri), isFalse);
        });
      });
    });

    group('samePackage', () {
      test('identity', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/src/bar.dart')),
            isTrue);
      });
      test('foo/bar.dart', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/bar.dart')),
            isTrue);
      });
    });

    group('implementation', () {
      var uris = [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ];
      uris.forEach((uri) {
        test(uri.toString(), () {
          expect(isImplementation(uri), isTrue);
        });
      });
      var uris2 = [
        Uri.parse('package:foo/bar.dart'),
        Uri.parse('src/bar.dart')
      ];
      uris2.forEach((uri) {
        test(uri.toString(), () {
          expect(isImplementation(uri), isFalse);
        });
      });
    });
  });

  group('names', () {
    group('keywords', () {
      var good = ['class', 'if', 'assert', 'catch', 'import'];
      testEach(good, isKeyWord, isTrue);
      var bad = ['_class', 'iff', 'assert_', 'Catch'];
      testEach(bad, isKeyWord, isFalse);
    });
    group('identifiers', () {
      var good = ['foo', '_if', '_', 'f2', 'fooBar', 'foo_bar'];
      testEach(good, isValidDartIdentifier, isTrue);
      var bad = ['if', '42', '3', '2f'];
      testEach(bad, isValidDartIdentifier, isFalse);
    });
    group('pubspec', () {
      testEach(['pubspec.yaml', '_pubspec.yaml'], isPubspecFileName, isTrue);
      testEach(['__pubspec.yaml', 'foo.yaml'], isPubspecFileName, isFalse);
    });

    group('camel case', () {
      group('upper', () {
        var good = [
          '_FooBar',
          'FooBar',
          '_Foo',
          'Foo',
          'F',
          'FB',
          'F1',
          'FooBar1'
        ];
        testEach(good, isUpperCamelCase, isTrue);
        var bad = ['fooBar', 'foo', 'f', '_f', 'F_B'];
        testEach(bad, isUpperCamelCase, isFalse);
      });
    });
    group('lower_case_underscores', () {
      var good = ['foo_bar', 'foo', 'foo_bar_baz', 'p', 'p1', 'p21', 'p1ll0'];
      testEach(good, isLowerCaseUnderScore, isTrue);

      var bad = [
        'Foo',
        'fooBar',
        'foo_Bar',
        'foo_',
        '_f',
        'F_B',
        'JS',
        'JSON',
        '1',
        '1b'
      ];
      testEach(bad, isLowerCaseUnderScore, isFalse);
    });
    group('qualified lower_case_underscores', () {
      var good = [
        'bwu_server.shared.datastore.some_file',
        'foo_bar.baz',
        'foo_bar',
        'foo.bar',
        'foo_bar_baz',
        'foo',
        'foo_',
        'foo.bar_baz.bang',
        //See: https://github.com/flutter/flutter/pull/1996
        'pointycastle.impl.ec_domain_parameters.gostr3410_2001_cryptopro_a',
        'a.b',
        'a.b.c',
        'p2.src.acme'
      ];
      testEach(good, isLowerCaseUnderScoreWithDots, isTrue);

      var bad = ['Foo', 'fooBar.', '.foo_Bar', '_f', 'F_B', 'JS', 'JSON'];
      testEach(bad, isLowerCaseUnderScoreWithDots, isFalse);
    });
    group('lowerCamelCase', () {
      var good = ['fooBar', 'foo', 'f', 'f1', '_f', '_foo', '_'];
      testEach(good, isLowerCamelCase, isTrue);

      var bad = ['Foo', 'foo_', 'foo_bar'];
      testEach(bad, isLowerCamelCase, isFalse);
    });
    group('libary_name_prefixes', () {
      testEach(
          Iterable<List<String>> values, dynamic f(List<String> s), Matcher m) {
        values.forEach((s) => test('${s[3]}', () => expect(f(s), m)));
      }

      bool isGoodPrefx(List<String> v) => matchesOrIsPrefixedBy(
          v[3],
          createLibraryNamePrefix(
              libraryPath: v[0], projectRoot: v[1], packageName: v[2]));

      var good = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.src.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.test.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.data.a'],
        ['/u/b/c/lib/acme.dart', '/u/b/c', 'acme', 'acme']
      ];
      testEach(good, isGoodPrefx, isTrue);

      var bad = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'wrk.acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.a']
      ];
      testEach(bad, isGoodPrefx, isFalse);
    });
  });
}

/// Test framework sanity
defineSanityTests() {
  group('test framework', () {
    group('annotation', () {
      test('extraction', () {
        expect(extractAnnotation('int x; // LINT [1:3]'), isNotNull);
        expect(extractAnnotation('int x; //LINT'), isNotNull);
        expect(extractAnnotation('int x; // OK'), isNull);
        expect(extractAnnotation('int x;'), isNull);
        expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
            equals('dynamic is bad'));
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad')
                .message,
            equals('dynamic is bad'));
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').column,
            equals(1));
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').length,
            equals(3));
        expect(extractAnnotation('dynamic x; //LINT').message, isNull);
        expect(extractAnnotation('dynamic x; //LINT ').message, isNull);
        // Commented out lines shouldn't get linted.
        expect(extractAnnotation('// dynamic x; //LINT '), isNull);
      });
    });
    test('equality', () {
      expect(
          new Annotation('Actual message (to be ignored)', ErrorType.LINT, 1),
          matchesAnnotation(null, ErrorType.LINT, 1));
      expect(new Annotation('Message', ErrorType.LINT, 1),
          matchesAnnotation('Message', ErrorType.LINT, 1));
    });
    test('inequality', () {
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.HINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message2', ErrorType.LINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.LINT, 2)),
          throwsA(new isInstanceOf<TestFailure>()));
    });
  });

  group('reporting', () {
    //https://github.com/dart-lang/linter/issues/193
    group('ignore synthetic nodes', () {
      String path = p.join('test', '_data', 'synthetic', 'synthetic.dart');
      File file = new File(path);
      testRule('non_constant_identifier_names', file);
    });
  });
}

/// Handy for debugging.
defineSoloRuleTest(String ruleToTest) {
  for (var entry in new Directory(ruleDir).listSync()) {
    if (entry is! File || !isDartFile(entry)) continue;
    var ruleName = p.basenameWithoutExtension(entry.path);
    if (ruleName == ruleToTest) {
      testRule(ruleName, entry);
    }
  }
}

Annotation extractAnnotation(String line) {
  int index = line.indexOf(new RegExp(r'(//|#)[ ]?LINT'));
  //Grab the first comment to see if there's one preceding the annotation.
  int comment = line.indexOf(new RegExp(r'(//|#)'));
  if (index > -1 && comment == index) {
    int column;
    int length;
    var annotation = line.substring(index);
    var leftBrace = annotation.indexOf('[');
    if (leftBrace != -1) {
      var sep = annotation.indexOf(':');
      column = int.parse(annotation.substring(leftBrace + 1, sep));
      var rightBrace = annotation.indexOf(']');
      length = int.parse(annotation.substring(sep + 1, rightBrace));
    }

    int msgIndex = annotation.indexOf(']') + 1;
    if (msgIndex < 1) {
      msgIndex = annotation.indexOf('T') + 1;
    }
    String msg = null;
    if (msgIndex < line.length) {
      msg = line.substring(index + msgIndex).trim();
      if (msg.length == 0) {
        msg = null;
      }
    }
    return new Annotation.forLint(msg, column, length);
  }
  return null;
}

AnnotationMatcher matchesAnnotation(
        String message, ErrorType type, int lineNumber) =>
    new AnnotationMatcher(new Annotation(message, type, lineNumber));

testEach(Iterable<String> values, dynamic f(String s), Matcher m) {
  values.forEach((s) => test('"$s"', () => expect(f(s), m)));
}

testRule(String ruleName, File file, {bool debug: false}) {
  test('$ruleName', () {
    if (!file.existsSync()) {
      throw new Exception('No rule found defined at: ${file.path}');
    }

    var expected = <AnnotationMatcher>[];

    int lineNumber = 1;
    for (var line in file.readAsLinesSync()) {
      var annotation = extractAnnotation(line);
      if (annotation != null) {
        annotation.lineNumber = lineNumber;
        expected.add(new AnnotationMatcher(annotation));
      }
      ++lineNumber;
    }

    LintRule rule = ruleRegistry[ruleName];
    if (rule == null) {
      print('WARNING: Test skipped -- rule `$ruleName` is not registered.');
      return;
    }

    LinterOptions options = new LinterOptions([rule])
      ..useMockSdk = true
      ..packageRootPath = '.';

    DartLinter driver = new DartLinter(options);

    Iterable<AnalysisErrorInfo> lints = driver.lintFiles([file]);

    List<Annotation> actual = [];
    lints.forEach((AnalysisErrorInfo info) {
      info.errors.forEach((AnalysisError error) {
        if (error.errorCode.type == ErrorType.LINT) {
          actual.add(new Annotation.forError(error, info.lineInfo));
        }
      });
    });
    try {
      expect(actual, unorderedMatches(expected));
    } on Error catch (e) {
      if (debug) {
        // Dump results for debugging purposes.

        //AST.
        new Spelunker(file.absolute.path).spelunk();
        print('');
        // Lints.
        var reporter = new ResultReporter(lints);
        reporter.write();
      }

      // Rethrow and fail.
      throw e;
    }
  });
}

class Annotation {
  final int column;
  final int length;
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type, this.lineNumber,
      {this.column, this.length});

  Annotation.forError(AnalysisError error, LineInfo lineInfo)
      : this(error.message, error.errorCode.type,
            lineInfo.getLocation(error.offset).lineNumber,
            column: lineInfo.getLocation(error.offset).columnNumber,
            length: error.length);

  Annotation.forLint([String message, int column, int length])
      : this(message, ErrorType.LINT, null, column: column, length: length);

  String toString() =>
      '[$type]: "$message" (line: $lineNumber) - [$column:$length]';

  static Iterable<Annotation> fromErrors(AnalysisErrorInfo error) {
    List<Annotation> annotations = [];
    error.errors.forEach(
        (e) => annotations.add(new Annotation.forError(e, error.lineInfo)));
    return annotations;
  }
}

class AnnotationMatcher extends Matcher {
  final Annotation _expected;
  AnnotationMatcher(this._expected);

  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  bool matches(item, Map matchState) =>
      item is Annotation && _matches(item as Annotation);

  bool _matches(Annotation other) {
    // Only test messages if they're specified in the expectation
    if (_expected.message != null) {
      if (_expected.message != other.message) {
        return false;
      }
    }
    // Similarly for highlighting
    if (_expected.column != null) {
      if (_expected.column != other.column ||
          _expected.length != other.length) {
        return false;
      }
    }
    return _expected.type == other.type &&
        _expected.lineNumber == other.lineNumber;
  }
}

class NoFilter implements LintFilter {
  @override
  bool filter(AnalysisError lint) => false;
}

class ResultReporter extends DetailedReporter {
  ResultReporter(Iterable<AnalysisErrorInfo> errors)
      : super(errors, new NoFilter(), stdout);
}
