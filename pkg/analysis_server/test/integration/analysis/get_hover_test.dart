// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.get.hover;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(AnalysisGetHoverIntegrationTest);
}

@ReflectiveTestCase()
class AnalysisGetHoverIntegrationTest extends
    AbstractAnalysisServerIntegrationTest {
  /**
   * Pathname of the file containing Dart code.
   */
  String pathname;

  /**
   * Dart code under test.
   */
  final String text = r'''
library lib.test;

List topLevelVar;

/**
 * Documentation for func
 */
void func(int param) {
  num localVar = topLevelVar.length;
  topLevelVar.length = param;
  topLevelVar.add(localVar);
}

main() {
  // comment
  func(35);
}
''';

  /**
   * Check that a getHover request on the substring [target] produces a result
   * which has length [length], has an elementDescription matching every
   * regexp in [descriptionRegexps], has a kind of [kind], and has a staticType
   * matching [staticTypeRegexps].
   *
   * [isCore] means the hover info should indicate that the element is defined
   * in dart.core.  [docRegexp], if specified, should match the documentation
   * string of the element.  [isLiteral] means the hover should indicate a
   * literal value.  [parameterRegexps] means is a set of regexps which should
   * match the hover parameters.  [propagatedType], if specified, is the
   * expected propagated type of the element.
   */
  checkHover(String target, int length, List<String> descriptionRegexps,
      String kind, List<String> staticTypeRegexps, {bool isCore: false,
      String docRegexp: null, bool isLiteral: false, List<String> parameterRegexps:
      null, propagatedType: null}) {
    int offset = text.indexOf(target);
    return sendAnalysisGetHover(pathname, offset).then((result) {
      expect(result.hovers, hasLength(1));
      HoverInformation info = result.hovers[0];
      expect(info.offset, equals(offset));
      expect(info.length, equals(length));
      if (isCore) {
        expect(basename(info.containingLibraryPath), equals('core.dart'));
        expect(info.containingLibraryName, equals('dart.core'));
      } else if (isLiteral) {
        expect(info.containingLibraryPath, isNull);
        expect(info.containingLibraryName, isNull);
      } else {
        expect(info.containingLibraryPath, equals(pathname));
        expect(info.containingLibraryName, equals('lib.test'));
      }
      if (docRegexp == null) {
        expect(info.dartdoc, isNull);
      } else {
        expect(info.dartdoc, matches(docRegexp));
      }
      if (descriptionRegexps == null) {
        expect(info.elementDescription, isNull);
      } else {
        expect(info.elementDescription, isString);
        for (String descriptionRegexp in descriptionRegexps) {
          expect(info.elementDescription, matches(descriptionRegexp));
        }
      }
      expect(info.elementKind, equals(kind));
      if (parameterRegexps == null) {
        expect(info.parameter, isNull);
      } else {
        expect(info.parameter, isString);
        for (String parameterRegexp in parameterRegexps) {
          expect(info.parameter, matches(parameterRegexp));
        }
      }
      expect(info.propagatedType, equals(propagatedType));
      if (staticTypeRegexps == null) {
        expect(info.staticType, isNull);
      } else {
        expect(info.staticType, isString);
        for (String staticTypeRegexp in staticTypeRegexps) {
          expect(info.staticType, matches(staticTypeRegexp));
        }
      }
    });
  }

  /**
   * Check that a getHover request on the substring [target] produces no
   * results.
   */
  Future checkNoHover(String target) {
    int offset = text.indexOf(target);
    return sendAnalysisGetHover(pathname, offset).then((result) {
      expect(result.hovers, hasLength(0));
    });
  }

  setUp() {
    return super.setUp().then((_) {
      pathname = sourcePath('test.dart');
    });
  }

  test_getHover() {
    writeFile(pathname, text);
    standardAnalysisSetup();

    // Note: analysis.getHover doesn't wait for analysis to complete--it simply
    // returns the latest results that are available at the time that the
    // request is made.  So wait for analysis to finish before testing anything.
    return analysisFinished.then((_) {
      List<Future> tests = [];
      tests.add(
          checkHover(
              'topLevelVar;',
              11,
              ['List', 'topLevelVar'],
              'top level variable',
              ['List']));
      tests.add(
          checkHover(
              'func(',
              4,
              ['func', 'int', 'param'],
              'function',
              ['int', 'void'],
              docRegexp: 'Documentation for func'));
      tests.add(
          checkHover(
              'int param',
              3,
              ['int'],
              'class',
              ['int'],
              isCore: true,
              docRegexp: '.*'));
      tests.add(
          checkHover(
              'param)',
              5,
              ['int', 'param'],
              'parameter',
              ['int'],
              docRegexp: 'Documentation for func'));
      tests.add(
          checkHover(
              'num localVar',
              3,
              ['num'],
              'class',
              ['num'],
              isCore: true,
              docRegexp: '.*'));
      tests.add(
          checkHover(
              'localVar =',
              8,
              ['num', 'localVar'],
              'local variable',
              ['num'],
              propagatedType: 'int'));
      tests.add(
          checkHover(
              'topLevelVar.length;',
              11,
              ['List', 'topLevelVar'],
              'top level variable',
              ['List']));
      tests.add(
          checkHover(
              'length;',
              6,
              ['get', 'length', 'int'],
              'getter',
              ['int'],
              isCore: true,
              docRegexp: '.*'));
      tests.add(
          checkHover(
              'length =',
              6,
              ['set', 'length', 'int'],
              'setter',
              ['int'],
              isCore: true,
              docRegexp: '.*'));
      tests.add(
          checkHover(
              'param;',
              5,
              ['int', 'param'],
              'parameter',
              ['int'],
              docRegexp: 'Documentation for func',
              parameterRegexps: ['.*']));
      tests.add(
          checkHover(
              'add(',
              3,
              ['List', 'add'],
              'method',
              null,
              isCore: true,
              docRegexp: '.*'));
      tests.add(
          checkHover(
              'localVar)',
              8,
              ['num', 'localVar'],
              'local variable',
              ['num'],
              parameterRegexps: ['.*'],
              propagatedType: 'int'));
      tests.add(
          checkHover(
              'func(35',
              4,
              ['func', 'int', 'param'],
              'function',
              null,
              docRegexp: 'Documentation for func'));
      tests.add(
          checkHover(
              '35',
              2,
              null,
              null,
              ['int'],
              isLiteral: true,
              parameterRegexps: ['int', 'param']));
      tests.add(checkNoHover('comment'));
      return Future.wait(tests);
    });
  }
}
