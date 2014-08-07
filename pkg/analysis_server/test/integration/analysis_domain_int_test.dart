// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.domain;

import 'dart:async';

import 'package:analysis_testing/reflective_tests.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';

@ReflectiveTestCase()
class AnalysisDomainIntegrationTest extends
    AbstractAnalysisServerIntegrationTest {
  test_getHover() {
    String pathname = sourcePath('test.dart');
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
    writeFile(pathname, text);
    standardAnalysisRoot();

    testHover(String target, int length, List<String> descriptionRegexps, String
        kind, List<String> staticTypeRegexps, {bool isCore: false, String docRegexp:
        null, bool isLiteral: false, List<String> parameterRegexps:
        null, propagatedType: null}) {
      int offset = text.indexOf(target);
      return sendAnalysisGetHover(pathname, offset).then((result) {
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
    String pathname = sourcePath('test.dart');
    String text = r'''
main() {
  // no code
}
''';
    writeFile(pathname, text);
    standardAnalysisRoot();

    // Note: analysis.getHover doesn't wait for analysis to complete--it simply
    // returns the latest results that are available at the time that the
    // request is made.  So wait for analysis to finish before testing anything.
    return analysisFinished.then((_) {
      return sendAnalysisGetHover(pathname, text.indexOf('no code')).then(
          (result) {
        expect(result['hovers'], hasLength(0));
      });
    });
  }

  test_getErrors_before_analysis() {
    return getErrorsTest(false);
  }

  test_getErrors_after_analysis() {
    return getErrorsTest(true);
  }

  Future getErrorsTest(bool afterAnalysis) {
    String pathname = sourcePath('test.dart');
    String text = r'''
main() {
  var x // parse error: missing ';'
}''';
    writeFile(pathname, text);
    standardAnalysisRoot();
    Future finishTest() {
      return sendAnalysisGetErrors(pathname).then((result) {
        expect(result['errors'], equals(currentAnalysisErrors[pathname]));
      });
    }
    if (afterAnalysis) {
      return analysisFinished.then((_) => finishTest());
    } else {
      return finishTest();
    }
  }

  test_updateContent_content_only() {
    return updateContentTest(false);
  }

  test_updateContent_including_offset_and_lengths() {
    return updateContentTest(true);
  }

  Future updateContentTest(bool includeOffsetAndLengths) {
    String pathname = sourcePath('test.dart');
    String goodText = r'''
main() {
  print("Hello, world!");
}''';
    String badText = goodText.replaceAll(';', '');
    writeFile(pathname, badText);
    standardAnalysisRoot();
    return analysisFinished.then((_) {
      // The contents on disk (badText) are missing a semicolon.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
      var contentChange = {
        'content': goodText
      };
      if (includeOffsetAndLengths) {
        contentChange['offset'] = goodText.indexOf(';');
        contentChange['oldLength'] = 0;
        contentChange['newLength'] = 1;
      }
      return sendAnalysisUpdateContent({
        pathname: contentChange
      });
    }).then((result) => analysisFinished).then((_) {
      // There should be no errors now because the contents on disk have been
      // overriden with goodText.
      expect(currentAnalysisErrors[pathname], isEmpty);
      // TODO(paulberry): passing "checkTypes: false" to work around the fact
      // that isContentChange doesn't permit 'content' to be null.
      return sendAnalysisUpdateContent({
        pathname: {
          'content': null
        }
      }, checkTypes: false);
    }).then((result) => analysisFinished).then((_) {
      // Now there should be errors again, because the contents on disk are no
      // longer overridden.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
    });
  }
}

main() {
  runReflectiveTests(AnalysisDomainIntegrationTest);
}
