// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

import 'package:analysis_server/src/utilities/import_analyzer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAnalyzerDeclarationsInclusionTest);
    defineReflectiveTests(ImportAnalyzerDeclarationsKindTest);
    defineReflectiveTests(ImportAnalyzerReferenceInclusionTest);
    defineReflectiveTests(ImportAnalyzerReferenceKindTest);
    defineReflectiveTests(ImportAnalyzerReferencePrefixTest);
  });
}

/// Tests that show that the correct set of declarations are considered to be
/// moving or staying.
@reflectiveTest
class ImportAnalyzerDeclarationsInclusionTest extends ImportAnalyzerTest {
  Future<void> test_multiple_all() async {
    await analyze('''
[!
class A {}
class B {}
class C {}
class D {}
!]
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'A'),
      element<ClassElement2>(name: 'B'),
      element<ClassElement2>(name: 'C'),
      element<ClassElement2>(name: 'D'),
    ], expectedStayingDeclarations: []);
  }

  Future<void> test_multiple_first() async {
    await analyze('''
[!
class A {}
class B {}
!]
class C {}
class D {}
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'A'),
      element<ClassElement2>(name: 'B'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'C'),
      element<ClassElement2>(name: 'D'),
    ]);
  }

  Future<void> test_multiple_last() async {
    await analyze('''
class A {}
class B {}
[!
class C {}
class D {}
!]
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C'),
      element<ClassElement2>(name: 'D'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'A'),
      element<ClassElement2>(name: 'B'),
    ]);
  }

  Future<void> test_multiple_middle() async {
    await analyze('''
class A {}
[!
class B {}
class C {}
!]
class D {}
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'B'),
      element<ClassElement2>(name: 'C'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'A'),
      element<ClassElement2>(name: 'D'),
    ]);
  }

  Future<void> test_single_first() async {
    await analyze('''
[!
class C {}
!]
class D {}
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'D'),
    ]);
  }

  Future<void> test_single_last() async {
    await analyze('''
class B {}
[!
class C {}
!]
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'B'),
    ]);
  }

  Future<void> test_single_middle() async {
    await analyze('''
class B {}
[!
class C {}
!]
class D {}
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'B'),
      element<ClassElement2>(name: 'D'),
    ]);
  }

  Future<void> test_single_only() async {
    await analyze('''
[!
class C {}
!]
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C'),
    ], expectedStayingDeclarations: []);
  }
}

/// Tests that show that every kind of declaration is correctly recognized.
@reflectiveTest
class ImportAnalyzerDeclarationsKindTest extends ImportAnalyzerTest {
  Future<void> test_all() async {
    await analyze('''
[!
class C1 {}
class D1 = C1 with M1;
enum E1 {}
typedef void F1();
typedef G1 = void Function();
mixin M1 {}
typedef T1 = C1;
extension X1 on int {}
void f1() {}
int get g1 => 0;
int set s1(x) {}
int v1 = 0;
!]
class C2 {}
class D2 = C2 with M2;
enum E2 {}
typedef void F2();
typedef G2 = void Function();
mixin M2 {}
typedef T2 = C2;
extension X2 on int {}
void f2() {}
int get g2 => 0;
int set s2(x) {}
int v2 = 0;
''', expectedMovingDeclarations: [
      element<ClassElement2>(name: 'C1'),
      element<ClassElement2>(name: 'D1'),
      element<EnumElement2>(name: 'E1'),
      element<TypeAliasElement2>(name: 'F1'),
      element<TypeAliasElement2>(name: 'G1'),
      element<MixinElement2>(name: 'M1'),
      element<TypeAliasElement2>(name: 'T1'),
      element<ExtensionElement2>(name: 'X1'),
      element<TopLevelFunctionElement>(name: 'f1'),
      element<GetterElement>(name: 'g1'),
      element<SetterElement>(name: 's1='),
      element<TopLevelVariableElement2>(name: 'v1'),
    ], expectedStayingDeclarations: [
      element<ClassElement2>(name: 'C2'),
      element<ClassElement2>(name: 'D2'),
      element<EnumElement2>(name: 'E2'),
      element<TypeAliasElement2>(name: 'F2'),
      element<TypeAliasElement2>(name: 'G2'),
      element<MixinElement2>(name: 'M2'),
      element<TypeAliasElement2>(name: 'T2'),
      element<ExtensionElement2>(name: 'X2'),
      element<TopLevelFunctionElement>(name: 'f2'),
      element<GetterElement>(name: 'g2'),
      element<SetterElement>(name: 's2='),
      element<TopLevelVariableElement2>(name: 'v2'),
    ]);
  }
}

/// Tests that show that references are correctly recognized as either being in
/// the moving or staying code.
@reflectiveTest
class ImportAnalyzerReferenceInclusionTest extends ImportAnalyzerTest {
  Future<void> test_movingReferencesImported() async {
    await analyze('''
import 'dart:io';

[!
class C {
  File? file;
}
!]
''', expectedStayingReferences: {}, expectedMovingReferences: {
      element<ClassElement2>(name: 'File'): [''],
    });
  }

  Future<void> test_movingReferencesMoving() async {
    await analyze('''
[!
class C {
  C? parent;
}
!]
''', expectedStayingReferences: {}, expectedMovingReferences: {});
  }

  Future<void> test_movingReferencesStaying() async {
    await analyze('''
class A {}
[!
class C extends A {}
!]
''', expectedStayingReferences: {}, expectedMovingReferences: {
      element<ClassElement2>(name: 'A'): [''],
    });
  }

  Future<void> test_stayingReferencesImported() async {
    await analyze('''
import 'dart:io';

class A {
  File? file;
}
[!
class C {}
!]
''', expectedStayingReferences: {
      element<ClassElement2>(name: 'File'): [''],
    }, expectedMovingReferences: {});
  }

  Future<void> test_stayingReferencesMoving() async {
    await analyze('''
class A extends C {}
[!
class C {}
!]
''', expectedStayingReferences: {
      element<ClassElement2>(name: 'C'): [''],
    }, expectedMovingReferences: {});
  }

  Future<void> test_stayingReferencesStaying() async {
    await analyze('''
class A {
  A? parent;
}
[!
class C {}
!]
''', expectedStayingReferences: {}, expectedMovingReferences: {});
  }
}

/// Tests that show that references are correctly recognized for every kind of
/// element.
@reflectiveTest
class ImportAnalyzerReferenceKindTest extends ImportAnalyzerTest {
  Future<void> test_class_movingDeclaration() async {
    await analyze('''
C? c;
[!
class C {}
!]
''', expectedStayingReferences: {
      element<ClassElement2>(name: 'C'): [''],
    });
  }

  Future<void> test_class_movingReference() async {
    await analyze('''
class C {}
[!
C? c;
!]
''', expectedMovingReferences: {
      element<ClassElement2>(name: 'C'): [''],
    });
  }

  Future<void> test_enum_movingDeclaration() async {
    await analyze('''
E? e;
[!
enum E {}
!]
''', expectedStayingReferences: {
      element<EnumElement2>(name: 'E'): [''],
    });
  }

  Future<void> test_enum_movingReference() async {
    await analyze('''
enum E {}
[!
E? e;
!]
''', expectedMovingReferences: {
      element<EnumElement2>(name: 'E'): [''],
    });
  }

  Future<void> test_extension_member_movingDeclaration() async {
    await analyze('''
var x = 2.g;
[!
extension X on int {
  int get g => this;
}
!]
''', expectedStayingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
    });
  }

  Future<void> test_extension_member_movingReference() async {
    await analyze('''
extension X on int {
  int get g => this;
}
[!
var x = 2.g;
!]
''', expectedMovingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
    });
  }

  Future<void> test_extension_operator_movingDeclaration() async {
    await analyze('''
class A {}
var x = A() + A();
[!
extension X on A {
  A operator +(A other) => A();
}
!]
''', expectedStayingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
    });
  }

  Future<void> test_extension_operator_movingReference() async {
    await analyze('''
class A {}
extension X on A {
  A operator +(A other) => A();
}
[!
var x = A() + A();
!]
''', expectedMovingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
      element<ClassElement2>(name: 'A'): [''],
    });
  }

  Future<void> test_extension_override_movingDeclaration() async {
    await analyze('''
var x = X(2).g;
[!
extension X on int {
  int get g => this;
}
!]
''', expectedStayingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
    });
  }

  Future<void> test_extension_override_movingReference() async {
    await analyze('''
extension X on int {
  int get g => this;
}
[!
var x = X(2).g;
!]
''', expectedMovingReferences: {
      element<ExtensionElement2>(name: 'X'): [''],
    });
  }

  Future<void> test_functionTypeAlias_movingDeclaration() async {
    await analyze('''
F? f;
[!
typedef void F();
!]
''', expectedStayingReferences: {
      element<TypeAliasElement2>(name: 'F'): [''],
    });
  }

  Future<void> test_functionTypeAlias_movingReference() async {
    await analyze('''
typedef void F();
[!
F? f;
!]
''', expectedMovingReferences: {
      element<TypeAliasElement2>(name: 'F'): [''],
    });
  }

  Future<void> test_genericFunctionTypeAlias_movingDeclaration() async {
    await analyze('''
G? g;
[!
typedef G = void Function();
!]
''', expectedStayingReferences: {
      element<TypeAliasElement2>(name: 'G'): [''],
    });
  }

  Future<void> test_genericFunctionTypeAlias_movingReference() async {
    await analyze('''
typedef G = void Function();
[!
G? g;
!]
''', expectedMovingReferences: {
      element<TypeAliasElement2>(name: 'G'): [''],
    });
  }

  Future<void> test_mixin_movingDeclaration() async {
    await analyze('''
M? m;
[!
mixin M {}
!]
''', expectedStayingReferences: {
      element<MixinElement2>(name: 'M'): [''],
    });
  }

  Future<void> test_mixin_movingReference() async {
    await analyze('''
mixin M {}
[!
M? m;
!]
''', expectedMovingReferences: {
      element<MixinElement2>(name: 'M'): [''],
    });
  }

  Future<void> test_mixinApplication_movingDeclaration() async {
    await analyze('''
D? d;
[!
class D = C with M;
class C {}
mixin M {}
!]
''', expectedStayingReferences: {
      element<ClassElement2>(name: 'D'): [''],
    });
  }

  Future<void> test_mixinApplication_movingReference() async {
    await analyze('''
class D = C with M;
class C {}
mixin M {}
[!
D? d;
!]
''', expectedMovingReferences: {
      element<ClassElement2>(name: 'D'): [''],
    });
  }

  Future<void> test_topLevelFunction_movingDeclaration() async {
    await analyze('''
var x = f();
[!
void f() {}
!]
''', expectedStayingReferences: {
      element<TopLevelFunctionElement>(name: 'f'): [''],
    });
  }

  Future<void> test_topLevelFunction_movingReference() async {
    await analyze('''
void f() {}
[!
var x = f();
!]
''', expectedMovingReferences: {
      element<TopLevelFunctionElement>(name: 'f'): [''],
    });
  }

  Future<void> test_topLevelGetter_movingDeclaration() async {
    await analyze('''
var x = g;
[!
int get g => 0;
!]
''', expectedStayingReferences: {
      element<GetterElement>(name: 'g'): [''],
    });
  }

  Future<void> test_topLevelGetter_movingReference() async {
    await analyze('''
int get g => 0;
[!
var x = g;
!]
''', expectedMovingReferences: {
      element<GetterElement>(name: 'g'): [''],
    });
  }

  Future<void> test_topLevelSetter_movingDeclaration() async {
    await analyze('''
void f() {
  s = 3;
}
[!
int set s(x) {}
!]
''', expectedStayingReferences: {
      element<SetterElement>(name: 's='): [''],
    });
  }

  Future<void> test_topLevelSetter_movingReference() async {
    await analyze('''
int set s(x) {}
[!
void f() {
  s = 3;
}
!]
''', expectedMovingReferences: {
      element<SetterElement>(name: 's='): [''],
    });
  }

  Future<void>
      test_topLevelVariable_compoundAssignment_separateReadWriteElements_movingDeclaration() async {
    await analyze('''
void f() => v += 1;
[!
int get v => 0;
set v(num _) {}
!]
''', expectedStayingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_compoundAssignment_separateReadWriteElements_movingReference() async {
    await analyze('''
int get v => 0;
set v(num _) {}
[!
void f() => v += 1;
!]
''', expectedMovingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_compoundAssignment_singleReadWriteElement_movingDeclaration() async {
    await analyze('''
void f() => v += 1;
[!
int v = 0;
!]
''', expectedStayingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_compoundAssignment_singleReadWriteElement_movingReference() async {
    await analyze('''
int v = 0;
[!
void f() => v += 1;
!]
''', expectedMovingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void> test_topLevelVariable_movingDeclaration() async {
    await analyze('''
var x = v;
[!
int v = 0;
!]
''', expectedStayingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void> test_topLevelVariable_movingReference() async {
    await analyze('''
int v = 0;
[!
var x = v;
!]
''', expectedMovingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_postfixIncrement_separateReadWriteElements_movingDeclaration() async {
    await analyze('''
void f() => v++;
[!
int get v => 0;
set v(num _) {}
!]
''', expectedStayingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_postfixIncrement_separateReadWriteElements_movingReference() async {
    await analyze('''
int get v => 0;
set v(num _) {}
[!
void f() => v++;
!]
''', expectedMovingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_postfixIncrement_singleReadWriteElement_movingDeclaration() async {
    await analyze('''
void f() => v++;
[!
int v = 0;
!]
''', expectedStayingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_postfixIncrement_singleReadWriteElement_movingReference() async {
    await analyze('''
int v = 0;
[!
void f() => v++;
!]
''', expectedMovingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_prefixIncrement_separateReadWriteElements_movingDeclaration() async {
    await analyze('''
void f() => ++v;
[!
int get v => 0;
set v(num _) {}
!]
''', expectedStayingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_prefixIncrement_separateReadWriteElements_movingReference() async {
    await analyze('''
int get v => 0;
set v(num _) {}
[!
void f() => ++v;
!]
''', expectedMovingReferences: {
      element<SetterElement>(name: 'v='): [''],
      element<GetterElement>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_prefixIncrement_singleReadWriteElement_movingDeclaration() async {
    await analyze('''
void f() => ++v;
[!
int v = 0;
!]
''', expectedStayingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void>
      test_topLevelVariable_prefixIncrement_singleReadWriteElement_movingReference() async {
    await analyze('''
int v = 0;
[!
void f() => ++v;
!]
''', expectedMovingReferences: {
      element<TopLevelVariableElement2>(name: 'v'): [''],
    });
  }

  Future<void> test_typeAlias_movingDeclaration() async {
    await analyze('''
T? t;
[!
typedef T = C;
class C {}
!]
''', expectedStayingReferences: {
      element<TypeAliasElement2>(name: 'T'): [''],
    });
  }

  Future<void> test_typeAlias_movingReference() async {
    await analyze('''
typedef T = C;
class C {}
[!
T? t;
!]
''', expectedMovingReferences: {
      element<TypeAliasElement2>(name: 'T'): [''],
    });
  }
}

/// Tests that show that the prefixes used in references are correctly captured.
@reflectiveTest
class ImportAnalyzerReferencePrefixTest extends ImportAnalyzerTest {
  Future<void> test_class_movingDeclaration() async {
    await analyze('''
import 'dart:io';
import 'dart:io' as a;
import 'dart:io' as b;
import 'dart:io' as c;
import 'dart:io' as d;
[!
File? f1;
a.File? f2;
b.File? f3;
!]
Directory? d1;
c.Directory? d2;
d.Directory? d3;
''', expectedMovingReferences: {
      element<ClassElement2>(name: 'File'): ['', 'a', 'b'],
    }, expectedStayingReferences: {
      element<ClassElement2>(name: 'Directory'): ['', 'c', 'd'],
    });
  }
}

abstract class ImportAnalyzerTest extends PubPackageAnalysisServerTest {
  Future<void> analyze(String code,
      {List<_ExpectedElement>? expectedMovingDeclarations,
      List<_ExpectedElement>? expectedStayingDeclarations,
      Map<_ExpectedElement, List<String>>? expectedMovingReferences,
      Map<_ExpectedElement, List<String>>? expectedStayingReferences}) async {
    createDefaultFiles();
    var testCode = TestCode.parse(code);
    var pathToInclude = newFile(testFilePath, testCode.code).path;
    var context = AnalysisContextCollection(
            includedPaths: [pathToInclude],
            resourceProvider: resourceProvider,
            sdkPath: sdkRoot.path)
        .contexts[0];
    var result = await context.currentSession.getResolvedLibrary(pathToInclude)
        as ResolvedLibraryResult;
    var analyzer =
        ImportAnalyzer(result, pathToInclude, [testCode.range.sourceRange]);

    if (expectedMovingDeclarations != null) {
      var movingDeclarations = analyzer.movingDeclarations.toList();
      var length = expectedMovingDeclarations.length;
      expect(movingDeclarations, hasLength(length));
      for (var i = 0; i < length; i++) {
        expectedMovingDeclarations[i].assertMatches(movingDeclarations[i]);
      }
    }
    if (expectedStayingDeclarations != null) {
      var stayingDeclarations = analyzer.stayingDeclarations.toList();
      var length = expectedStayingDeclarations.length;
      expect(stayingDeclarations, hasLength(length));
      for (var i = 0; i < length; i++) {
        expectedStayingDeclarations[i].assertMatches(stayingDeclarations[i]);
      }
    }
    if (expectedMovingReferences != null) {
      var movingEntries = analyzer.movingReferences.entries.toList();
      var expectedEntries = expectedMovingReferences.entries.toList();
      var length = expectedMovingReferences.length;
      expect(movingEntries, hasLength(length));
      for (var i = 0; i < length; i++) {
        var expectedEntry = expectedEntries[i];
        var movingEntry = movingEntries[i];
        expectedEntry.key.assertMatches(movingEntry.key);
        expect(expectedEntry.value, expectedEntry.value);
      }
    }
    if (expectedStayingReferences != null) {
      var stayingEntries = analyzer.stayingReferences.entries.toList();
      var expectedEntries = expectedStayingReferences.entries.toList();
      var length = expectedStayingReferences.length;
      expect(stayingEntries, hasLength(length));
      for (var i = 0; i < length; i++) {
        var expectedEntry = expectedEntries[i];
        var stayingEntry = stayingEntries[i];
        expectedEntry.key.assertMatches(stayingEntry.key);
      }
    }
  }

  _ExpectedElement<T> element<T extends Element2>({required String name}) =>
      _ExpectedElement<T>(name: name);
}

class _ExpectedElement<T extends Element2> {
  final String name;

  _ExpectedElement({required this.name});

  void assertMatches(Element2 element) {
    expect(element, isA<T>());
    expect(element.name3, name);
  }
}
