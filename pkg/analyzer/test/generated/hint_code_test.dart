// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/util/yaml_test.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HintCodeTest);
  });
}

@reflectiveTest
class HintCodeTest extends ResolverTestCase {
  @override
  void reset() {
    super.resetWith(packages: [
      [
        'js',
        r'''
library js;
class JS {
  const JS([String js]);
}
'''
      ],
    ]);
  }

  test_deprecatedFunction_class() async {
    Source source = addSource(r'''
class Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION]);
    verify([source]);
  }

  test_deprecatedFunction_extends() async {
    Source source = addSource(r'''
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_EXTENDS_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_extends2() async {
    Source source = addSource(r'''
class Function {}
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_EXTENDS_FUNCTION
    ]);
    verify([source]);
  }

  test_deprecatedFunction_mixin() async {
    Source source = addSource(r'''
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_MIXIN_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_mixin2() async {
    Source source = addSource(r'''
class Function {}
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_MIXIN_FUNCTION
    ]);
    verify([source]);
  }

  test_duplicateShownHiddenName_hidden() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' hide A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_HIDDEN_NAME]);
    verify([source]);
  }

  test_duplicateShownHiddenName_shown() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' show A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_SHOWN_NAME]);
    verify([source]);
  }

  test_isDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isInt() async {
    Source source = addSource("var v = 1 is int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_INT]);
    verify([source]);
  }

  test_isNotDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is! double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isNotInt() async {
    Source source = addSource("var v = 1 is! int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_INT]);
    verify([source]);
  }

  test_js_lib_OK() async {
    Source source = addSource(r'''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingJsLibAnnotation_class() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_externalField() async {
    // https://github.com/dart-lang/sdk/issues/26987
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
external dynamic exports;
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [ParserErrorCode.EXTERNAL_FIELD, HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_function() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS('acxZIndex')
set _currentZIndex(int value) { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_method() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

class A {
  @JS()
  void a() { }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_variable() async {
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
dynamic variable;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_strongMode_downCastCompositeHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = true;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }

  test_strongMode_downCastCompositeNoHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_downCastCompositeWarn() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    applyToAnalysisOptions(
        options,
        wrap({
          AnalyzerOptions.analyzer: {
            AnalyzerOptions.errors: {
              StrongModeCode.DOWN_CAST_COMPOSITE.name: 'warning'
            },
          }
        }));
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }
}
