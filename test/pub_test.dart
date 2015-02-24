// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.pub;

import 'package:linter/src/pub.dart';
import 'package:mock/mock.dart';
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

defineTests() {
  const src = """
name: linter
version: 0.0.1
author: Dart Team <misc@dartlang.org>
authors:
  - Bill
  - Ted
description: Style linter for Dart.
documentation:
homepage: https://github.com/dart-lang/linter
dependencies:
  transmogrify:
    hosted:
      name: transmogrify
      url: http://your-package-server.com
    version: '>=0.4.0 <1.0.0'
  analyzer: '0.24.0-dev.1'
  cli_util: '>=0.0.1 <0.1.0'
  semver: '>=0.2.0 <0.3.0'
  yaml: '>=2.1.2 <3.0.0'
  kittens:
    git:
      url: git://github.com/munificent/kittens.git
      ref: some-branch
  foo: any
dev_dependencies:
  markdown: '>=0.7.1+2 <0.8.0'
  unittest: '>=0.11.0 <0.12.0'
""";

  PubSpec ps = new PubSpec.parse(src);

  group('pubspec', () {
    group('basic', () {
      test('toString()', () {
        // For now just confirm it doesn't blow up
        expect(ps.toString(), isNotNull);
      });
    });
    group('entries', () {
      testValue('name', ps.name, equals('linter'));
      testKeySpan('name', ps.name, startOffset: 0, endOffset: 4);
      testValueSpan('name', ps.name, startOffset: 6, endOffset: 12);
      group('documentation', () {
        test('no value', () {
          expect(ps.documentation.value.text, isNull);
        });
      });
      testValue('homepage', ps.homepage,
          equals('https://github.com/dart-lang/linter'));
      testValue(
          'description', ps.description, equals('Style linter for Dart.'));
      testValue('version', ps.version, equals('0.0.1'));
      testValue('author', ps.author, equals('Dart Team <misc@dartlang.org>'));

      group('authors', () {
        PSNodeList authors = ps.authors;
        test('contents', () {
          expect(authors, isNotNull);
          expect(authors.any((PSNode n) => n.text == 'Bill'), isTrue);
          expect(authors.any((PSNode n) => n.text == 'Ted'), isTrue);
        });
      });

      testDepListContains(
          'dependencies', ps.dependencies, [{'analyzer': '0.24.0-dev.1'}]);

      testDepListContains('dev_dependencies', ps.devDependencies, [
        {'markdown': '>=0.7.1+2 <0.8.0'}
      ]);

      group('hosted', () {
        PSDependency dep =
            findDependency(ps.dependencies, name: 'transmogrify');
        PSHost host = dep.host;
        testValue('name', host.name, equals('transmogrify'));
        testValue('url', host.url, equals('http://your-package-server.com'));
        testKeySpan('name', host.name, startOffset: 237, endOffset: 241);
        testValueSpan('name', host.name, startOffset: 243, endOffset: 255);
      });

      group('git', () {
        PSDependency dep = findDependency(ps.dependencies, name: 'kittens');
        PSGitRepo git = dep.git;
        testValue('ref', git.ref, equals('some-branch'));
        testValue(
            'url', git.url, equals('git://github.com/munificent/kittens.git'));
      });
    });
    group('visiting', () {
      test('smoke', () {
        var spy = new MockVisitor();
        ps.accept(spy);
        spy
          ..getLogs(callsTo('visitPackageAuthor')).verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageAuthors')).verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageDependencies'))
              .verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageDependency'))
              .verify(happenedExactly(7))
          ..getLogs(callsTo('visitPackageDescription'))
              .verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageDevDependencies'))
              .verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageDevDependency'))
              .verify(happenedExactly(2))
          ..getLogs(callsTo('visitPackageDocumentation'))
              .verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageHomepage')).verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageName')).verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageAuthors')).verify(happenedExactly(1))
          ..getLogs(callsTo('visitPackageVersion')).verify(happenedExactly(1));
      });
    });
  });
}

PSDependency findDependency(PSDependencyList deps, {String name}) =>
    deps.firstWhere((dep) => dep.name.text == name, orElse: () => null);

main() {
  groupSep = ' | ';

  defineTests();
}

testDepListContains(
    String label, PSDependencyList list, List<Map<String, String>> exp) {
  test(label, () {
    exp.forEach((Map<String, String> entry) {
      entry.forEach((k, v) {
        PSDependency dep = findDependency(list, name: k);
        expect(dep, isNotNull);
        expect(dep.version.value.text, equals(v));
      });
    });
  });
}

testEntry(String label, PSEntry node, Matcher m) {
  group(label, () {
    test('entry', () {
      expect(node, m);
    });
  });
}

testKeySpan(String label, PSEntry node, {int startOffset, int endOffset}) {
  group(label, () {
    group('key', () {
      testSpan(node.key.span, startOffset: startOffset, endOffset: endOffset);
    });
  });
}

testSpan(SourceSpan span, {int startOffset, int endOffset}) {
  test('span', () {
    var start = span.start;
    expect(start, isNotNull);
    expect(start.offset, equals(startOffset));
    var end = span.end;
    expect(end, isNotNull);
    expect(end.offset, equals(endOffset));
  });
}

testValue(String label, PSEntry node, Matcher m) {
  group(label, () {
    test('value', () {
      expect(node.value.text, m);
    });
  });
}

testValueSpan(String label, PSEntry node, {int startOffset, int endOffset}) {
  group(label, () {
    group('value', () {
      testSpan(node.value.span, startOffset: startOffset, endOffset: endOffset);
    });
  });
}

class MockVisitor extends Mock implements PubSpecVisitor {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
