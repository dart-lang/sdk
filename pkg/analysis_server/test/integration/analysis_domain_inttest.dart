// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.domain;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';

@ReflectiveTestCase()
class AnalysisDomainIntegrationTest extends
    AbstractAnalysisServerIntegrationTest {
  test_getHover() {
    String filename = 'test.dart';
    String pathname = normalizePath(filename);
    String text =
        r'''
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
  func(35);
}
''';
    writeFile(filename, text);
    setAnalysisRoots(['']);

    testHover(String target, int length, List<String> descriptionRegexps, String
        kind, List<String> staticTypeRegexps, {bool isCore: false, String docRegexp:
        null, bool isLiteral: false, List<String> parameterRegexps:
        null, propagatedType: null}) {
      int offset = text.indexOf(target);
      return server.send(ANALYSIS_GET_HOVER, {
        'file': pathname,
        'offset': offset
      }).then((result) {
        expect(result, isAnalysisGetHoverResult);
        expect(result['hovers'], hasLength(1));
        var info = result['hovers'][0];
        expect(info['offset'], equals(offset));
        expect(info['length'], equals(length));
        if (isCore) {
          expect(basename(info['containingLibraryPath']), equals('core.dart'));
          expect(info['containingLibraryName'], equals('dart.core'));
        } else if (isLiteral) {
          expect(info['containingLibraryPath'], isNull);
          expect(info['containingLibraryName'], isNull);
        } else {
          expect(info['containingLibraryPath'], equals(pathname));
          expect(info['containingLibraryName'], equals('lib.test'));
        }
        if (docRegexp == null) {
          expect(info['dartdoc'], isNull);
        } else {
          expect(info['dartdoc'], matches(docRegexp));
        }
        if (descriptionRegexps == null) {
          expect(info['elementDescription'], isNull);
        } else {
          expect(info['elementDescription'], isString);
          for (String descriptionRegexp in descriptionRegexps) {
            expect(info['elementDescription'], matches(descriptionRegexp));
          }
        }
        expect(info['elementKind'], equals(kind));
        if (parameterRegexps == null) {
          expect(info['parameter'], isNull);
        } else {
          expect(info['parameter'], isString);
          for (String parameterRegexp in parameterRegexps) {
            expect(info['parameter'], matches(parameterRegexp));
          }
        }
        expect(info['propagatedType'], equals(propagatedType));
        if (staticTypeRegexps == null) {
          expect(info['staticType'], isNull);
        } else {
          expect(info['staticType'], isString);
          for (String staticTypeRegexp in staticTypeRegexps) {
            expect(info['staticType'], matches(staticTypeRegexp));
          }
        }
      });
    }

    // Note: analysis.getHover doesn't wait for analysis to complete--it simply
    // returns the latest results that are available at the time that the
    // request is made.  So wait for analysis to finish before testing anything.
    return analysisFinished.then((_) {
      List<Future> tests = [];
      tests.add(testHover('topLevelVar;', 11, ['List', 'topLevelVar'],
          'top level variable', ['List']));
      tests.add(testHover('func(', 4, ['func', 'int', 'param'], 'function',
          ['int', 'void'], docRegexp: 'Documentation for func'));
      tests.add(testHover('int param', 3, ['int'], 'class', ['int'], isCore:
          true, docRegexp: '.*'));
      tests.add(testHover('param)', 5, ['int', 'param'], 'parameter', ['int'],
          docRegexp: 'Documentation for func'));
      tests.add(testHover('num localVar', 3, ['num'], 'class', ['num'], isCore:
          true, docRegexp: '.*'));
      tests.add(testHover('localVar =', 8, ['num', 'localVar'],
          'local variable', ['num'], propagatedType: 'int'));
      tests.add(testHover('topLevelVar.length;', 11, ['List', 'topLevelVar'],
          'top level variable', ['List']));
      tests.add(testHover('length;', 6, ['get', 'length', 'int'], 'getter',
          ['int'], isCore: true, docRegexp: '.*'));
      tests.add(testHover('length =', 6, ['set', 'length', 'int'], 'setter',
          ['int'], isCore: true, docRegexp: '.*'));
      tests.add(testHover('param;', 5, ['int', 'param'], 'parameter', ['int'],
          docRegexp: 'Documentation for func'));
      tests.add(testHover('add(', 3, ['List', 'add'], 'method', null, isCore:
          true, docRegexp: '.*'));
      tests.add(testHover('localVar)', 8, ['num', 'localVar'], 'local variable',
          ['num'], parameterRegexps: ['.*'], propagatedType: 'int'));
      tests.add(testHover('func(35', 4, ['func', 'int', 'param'], 'function',
          null, docRegexp: 'Documentation for func'));
      tests.add(testHover('35', 2, null, null, ['int'], isLiteral: true,
          parameterRegexps: ['int', 'param']));
      return Future.wait(tests);
    });
  }

  test_getHover_noInfo() {
    String filename = 'test.dart';
    String pathname = normalizePath(filename);
    String text =
        r'''
main() {
  // no code
}
''';
    writeFile(filename, text);
    setAnalysisRoots(['']);

    // Note: analysis.getHover doesn't wait for analysis to complete--it simply
    // returns the latest results that are available at the time that the
    // request is made.  So wait for analysis to finish before testing anything.
    return analysisFinished.then((_) {
      return server.send(ANALYSIS_GET_HOVER, {
              'file': pathname,
              'offset': text.indexOf('no code')
            }).then((result) {
              expect(result, isAnalysisGetHoverResult);
              expect(result['hovers'], hasLength(0));
      });
    });
  }
}

main() {
  runReflectiveTests(AnalysisDomainIntegrationTest);
}
