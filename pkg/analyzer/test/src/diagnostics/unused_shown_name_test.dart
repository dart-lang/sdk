// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedShownNameTest);
    defineReflectiveTests(UnusedShownNameTest_Driver);
  });
}

@reflectiveTest
class UnusedShownNameTest extends ResolverTestCase {
  test_unreferenced() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A, B;
A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_unusedShownName_as() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as p show A, B;
p.A a;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_unusedShownName_duplicates() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A, B;
import 'lib1.dart' show C, D;
A a;
C c;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}
class C {}
class D {}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source, [HintCode.UNUSED_SHOWN_NAME, HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_unusedShownName_topLevelVariable() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
int a = var1;
int b = var2;
int c = var3;
''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }
}

@reflectiveTest
class UnusedShownNameTest_Driver extends UnusedShownNameTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
