// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedImportTest);
  });
}

@reflectiveTest
class UnusedImportTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_annotationOnDirective() async {
    Source source = addSource(r'''
library L;
@A()
import 'lib1.dart';
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {
  const A() {}
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source);
    verify([source, source2]);
  }

  test_as() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_as_equalPrefixes_referenced() async {
    // 18818
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
one.B b;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
''');
    Source source3 = addNamedSource("/lib2.dart", r'''
library lib2;
class B {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    await computeAnalysisResult(source3);
    assertErrors(source);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  @failingTest
  test_as_equalPrefixes_unreferenced() async {
    // See todo at ImportsVerifier.prefixElementMap.
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
''');
    Source source3 = addNamedSource("/lib2.dart", r'''
library lib2;
class B {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    await computeAnalysisResult(source3);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  test_core_library() async {
    Source source = addSource(r'''
library L;
import 'dart:core';
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_export() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}
''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class Two {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_export2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Three three;
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}
''');
    addNamedSource("/lib2.dart", r'''
library lib2;
export 'lib3.dart';
class Two {}
''');
    addNamedSource("/lib3.dart", r'''
library lib3;
class Three {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_export_infiniteLoop() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}
''');
    addNamedSource("/lib2.dart", r'''
library lib2;
export 'lib3.dart';
class Two {}
''');
    addNamedSource("/lib3.dart", r'''
library lib3;
export 'lib2.dart';
class Three {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_hide() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_inComment_libraryDirective() async {
    Source source = addSource(r'''
/// Use [Future] class.
library L;
import 'dart:async';
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_metadata() async {
    Source source = addSource(r'''
library L;
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
const x = 0;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_prefix_topLevelFunction() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class One {}
topLevelFunction() {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_prefix_topLevelFunction2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
    two.topLevelFunction();
  }
}
''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class One {}
topLevelFunction() {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_show() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_unusedImport() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
''');
    Source source2 = addNamedSource("/lib1.dart", '''
library lib1;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }
}
