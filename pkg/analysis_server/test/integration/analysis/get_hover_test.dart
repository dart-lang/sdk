// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisGetHoverIntegrationTest);
  });
}

@reflectiveTest
class AnalysisGetHoverIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  /// Pathname of the file containing Dart code.
  String pathname;

  /// Dart code under test.
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

  /// Check that a getHover request on the substring [target] produces a result
  /// which has length [length], has an elementDescription matching every
  /// regexp in [descriptionRegexps], has a kind of [kind], and has a staticType
  /// matching [staticTypeRegexps].
  ///
  /// [isCore] means the hover info should indicate that the element is defined
  /// in dart.core.  [docRegexp], if specified, should match the documentation
  /// string of the element.  [isLiteral] means the hover should indicate a
  /// literal value.  [parameterRegexps] means is a set of regexps which should
  /// match the hover parameters.  [propagatedType], if specified, is the
  /// expected propagated type of the element.
  Future<AnalysisGetHoverResult> checkHover(
    String target,
    int length,
    List<String> descriptionRegexps,
    String kind,
    List<String> staticTypeRegexps, {
    bool isLocal = false,
    bool isCore = false,
    String docRegexp,
    bool isLiteral = false,
    List<String> parameterRegexps,
  }) {
    var offset = text.indexOf(target);
    return sendAnalysisGetHover(pathname, offset).then((result) async {
      expect(result.hovers, hasLength(1));
      var info = result.hovers[0];
      expect(info.offset, equals(offset));
      expect(info.length, equals(length));
      if (isCore) {
        expect(path.basename(info.containingLibraryPath), equals('core.dart'));
        expect(info.containingLibraryName, equals('dart:core'));
      } else if (isLocal || isLiteral) {
        expect(info.containingLibraryPath, isNull);
        expect(info.containingLibraryName, isNull);
      } else {
        expect(info.containingLibraryPath, equals(pathname));
        expect(info.containingLibraryName, isNotNull);
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
        for (var descriptionRegexp in descriptionRegexps) {
          expect(info.elementDescription, matches(descriptionRegexp));
        }
      }
      expect(info.elementKind, equals(kind));
      if (parameterRegexps == null) {
        expect(info.parameter, isNull);
      } else {
        expect(info.parameter, isString);
        for (var parameterRegexp in parameterRegexps) {
          expect(info.parameter, matches(parameterRegexp));
        }
      }
      if (staticTypeRegexps == null) {
        expect(info.staticType, isNull);
      } else {
        expect(info.staticType, isString);
        for (var staticTypeRegexp in staticTypeRegexps) {
          expect(info.staticType, matches(staticTypeRegexp));
        }
      }
      return null;
    });
  }

  /// Check that a getHover request on the substring [target] produces no
  /// results.
  Future checkNoHover(String target) {
    var offset = text.indexOf(target);
    return sendAnalysisGetHover(pathname, offset).then((result) {
      expect(result.hovers, hasLength(0));
    });
  }

  @override
  Future<void> setUp() {
    return super.setUp().then((_) {
      pathname = sourcePath('test.dart');
    });
  }

  Future<void> test_getHover() async {
    writeFile(pathname, text);
    standardAnalysisSetup();

    // Note: analysis.getHover doesn't wait for analysis to complete--it simply
    // returns the latest results that are available at the time that the
    // request is made.  So wait for analysis to finish before testing anything.
    await analysisFinished;

    await checkHover('topLevelVar;', 11, ['List', 'topLevelVar'],
        'top level variable', ['List']);

    await checkHover('func(', 4, ['func', 'int', 'param'], 'function', null,
        docRegexp: 'Documentation for func');

    await checkHover('int param', 3, ['int'], 'class', null,
        isCore: true, docRegexp: '.*');

    await checkHover('param)', 5, ['int', 'param'], 'parameter', ['int'],
        isLocal: true, docRegexp: 'Documentation for func');

    await checkHover('num localVar', 3, ['num'], 'class', null,
        isCore: true, docRegexp: '.*');

    await checkHover(
        'localVar =', 8, ['num', 'localVar'], 'local variable', ['num'],
        isLocal: true);

    await checkHover('topLevelVar.length;', 11, ['List', 'topLevelVar'],
        'top level variable', ['List']);

    await checkHover('length;', 6, ['get', 'length', 'int'], 'getter', null,
        isCore: true, docRegexp: '.*');

    await checkHover('length =', 6, ['set', 'length', 'int'], 'setter', null,
        isCore: true, docRegexp: '.*');

    await checkHover('param;', 5, ['int', 'param'], 'parameter', ['int'],
        isLocal: true,
        docRegexp: 'Documentation for func',
        parameterRegexps: ['.*']);

    await checkHover('add(', 3, ['add'], 'method', ['dynamic', 'void'],
        isCore: true, docRegexp: '.*');

    await checkHover(
        'localVar)', 8, ['num', 'localVar'], 'local variable', ['num'],
        isLocal: true, parameterRegexps: ['.*']);

    await checkHover(
        'func(35', 4, ['func', 'int', 'param'], 'function', ['int', 'void'],
        docRegexp: 'Documentation for func');

    await checkHover('35', 2, null, null, ['int'],
        isLiteral: true, parameterRegexps: ['int', 'param']);

    await checkNoHover('comment');
  }
}
