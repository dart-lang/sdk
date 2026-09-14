// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The tests in this file verify that the [CompilationUnit.lookupThisType]
/// method can be reliably used to query the type of `this` at any offset within
/// a compilation unit, without requiring an explicit reference to `this` to be
/// present in the AST.
///
/// @docImport 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_log.dart';
library;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart' show FlowAnalysisRootImpl;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../util/diff.dart';
import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlowAnalysisRootTest);
    defineReflectiveTests(LookupThisTypeTest);
    defineReflectiveTests(LookupThisTypeTestWithAnonymousMethods);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests that verify precisely which AST nodes act as flow analysis roots.
///
/// Each root retains a [FlowAnalysisLog] for as long as the resolved unit is
/// retained (that's what [CompilationUnit.lookupThisType] queries), so a
/// declaration establishing more roots than it needs is a memory cost paid on
/// every declaration in every file. These tests exist to make the set of roots
/// visible in a diff.
@reflectiveTest
class FlowAnalysisRootTest extends PubPackageResolutionTest {
  Future<void> assertRoots(String code, List<String> expected) async {
    var result = await resolveTestCode(code);
    var actual = <String>[];

    void collect(AstNode node) {
      if (node is FlowAnalysisRootImpl && node.flowAnalysisLog != null) {
        actual.add(node.runtimeType.toString());
      }
      for (var child in node.childEntities) {
        if (child is AstNode) collect(child);
      }
    }

    collect(result.unit);
    expect(actual, expected);
  }

  test_constructor() async {
    // The formal parameters are visited inside the constructor's own flow
    // analysis region, so they don't need a region of their own.
    await assertRoots(
      r'''
class C {
  C(int x);
}
''',
      ['ConstructorDeclarationImpl'],
    );
  }

  test_constructor_withDefaultValue() async {
    await assertRoots(
      r'''
class C {
  C([int x = 0]);
}
''',
      ['ConstructorDeclarationImpl'],
    );
  }

  test_method() async {
    // As for constructors, the formal parameters don't need a region of their
    // own.
    await assertRoots(
      r'''
class C {
  void f(int x) {}
}
''',
      ['MethodDeclarationImpl'],
    );
  }

  test_method_withDefaultValue() async {
    await assertRoots(
      r'''
class C {
  void f([int x = 0]) {}
}
''',
      ['MethodDeclarationImpl'],
    );
  }

  test_primaryConstructor() async {
    // A primary constructor's formal parameter list lives in the class header,
    // not inside the primary constructor body, so there is no enclosing region
    // for it to join; it necessarily acts as a root of its own.
    await assertRoots(
      r'''
class C([int x = 0]) {
  this {}
}
''',
      ['FormalParameterListImpl', 'PrimaryConstructorBodyImpl'],
    );
  }

  test_topLevelFunction() async {
    await assertRoots(
      r'''
void f([int x = 0]) {}
''',
      ['FunctionDeclarationImpl'],
    );
  }
}

/// Test cases that are run with anonymous methods disabled.
@reflectiveTest
class LookupThisTypeTest extends PubPackageResolutionTest {
  static final _thisTypeExpectation = RegExp(r'/\*this:\s*([^*]*?)\s*\*/');

  Future<void> assertThisTypes(String code) async {
    // These markers identify the ranges to rewrite in the original test code,
    // preserving any diagnostic expectations that it contains.
    var expectedMarkers = _thisTypeExpectation.allMatches(code).toList();

    if (expectedMarkers.isEmpty) {
      fail('Expected at least one this type marker.');
    }

    var result = await resolveTestCodeWithDiagnostics(code);

    // These markers provide query offsets in the code that was actually
    // resolved, after diagnostic expectations have been removed.
    var resolvedMarkers = _thisTypeExpectation
        .allMatches(result.content)
        .toList();
    if (resolvedMarkers.length != expectedMarkers.length) {
      fail(
        'Expected ${expectedMarkers.length} this type markers in the '
        'resolved code, found ${resolvedMarkers.length}.',
      );
    }

    var actualCode = StringBuffer();
    var previousEnd = 0;
    for (var i = 0; i < expectedMarkers.length; i++) {
      var expectedMarker = expectedMarkers[i];
      var resolvedMarker = resolvedMarkers[i];

      var type = result.unit.lookupThisType(offset: resolvedMarker.start);
      var typeText = type == null ? 'null' : typeString(type);

      actualCode
        ..write(code.substring(previousEnd, expectedMarker.start))
        ..write('/*this: $typeText*/');
      previousEnd = expectedMarker.end;
    }
    actualCode.write(code.substring(previousEnd));

    var actual = actualCode.toString();
    if (actual != code) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(code, actual);
      }
      fail('See the difference above.');
    }
  }

  test_thisPromotion_inAnnotation() async {
    // Annotations are flow analysis roots in their own right, nested inside the
    // flow analysis root for the declaration they annotate. `this` isn't
    // accessible inside an annotation, so the query should return `null` (and,
    // in particular, it should not accidentally consult the log belonging to
    // the enclosing method declaration).
    await assertThisTypes(r'''
class C {
  @Deprecated(/*this: null*/ 'x')
  f() {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inConstructorInitializerList() async {
    // The flow analysis region for a constructor covers the initializer list as
    // well as the body, but `this` isn't bound until the body is reached.
    await assertThisTypes(r'''
class C {
  final Object x;
  C() : x = /*this: null*/ 0 {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inFactoryConstructor() async {
    // Factory constructors don't have access to `this`, but it's still
    // important to make sure that querying the type of `this` doesn't
    // lead to a crash.
    await assertThisTypes(r'''
class C {
  factory C() {
    /*this: null*/
    throw '';
  }
}
''');
  }

  test_thisPromotion_inForLoop() async {
    // This test verifies that the `lookupThisType` query properly
    // understands that in a `for` loop, the "updaters" part executes *after*
    // the body.
    await assertThisTypes(r'''
class C {
  f() {
    for (int i = 0; i < 10 /*this: C*/; /*this: D*/ i++) {
      /*this: C*/
      this as D;
      /*this: D*/
    }
    /*this: C*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inGenerativeConstructor() async {
    await assertThisTypes(r'''
class C {
  C() {
    /*this: C*/
    if (this is D) {
      /*this: D*/
    }
    /*this: C*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inInstanceFieldInitializer() async {
    // `this` isn't accessible in the initializer of a non-late instance field.
    await assertThisTypes(r'''
class C {
  final Object x = /*this: null*/ 0;
}
''');
  }

  test_thisPromotion_inLateInstanceFieldInitializer() async {
    // `this` *is* accessible (and promotable) in the initializer of a `late`
    // instance field.
    await assertThisTypes(r'''
class C {
  late final Object x = this is D ? /*this: D*/ 0 : /*this: C*/ 1;
}
class D extends C {}
''');
  }

  test_thisPromotion_inMethod() async {
    await assertThisTypes(r'''
class C {
  f() {
    /*this: C*/
    if (this is D) {
      /*this: D*/
    }
    /*this: C*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inMethod_ofExtension() async {
    await assertThisTypes(r'''
class C {}
class D extends C {}
extension E on C {
  f() {
    /*this: C*/
    if (this is D) {
      /*this: D*/
    }
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inMethod_ofExtensionType() async {
    await assertThisTypes(r'''
extension type C(num n) {
  f() {
    /*this: C*/
    if (this is D) {
      /*this: D*/
    }
    /*this: C*/
  }
}
extension type D(int i) implements C {}
''');
  }

  test_thisPromotion_inPatternAssignment() async {
    // This test verifies that the `lookupThisType` query properly
    // understands that in a pattern assignment, the pattern executes *after*
    // the RHS.
    await assertThisTypes(r'''
class C {
  f() {
    (/*this: C*/ _ as D /*this: D*/) = /*this: C*/ this;
    /*this: D*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPatternVariableDeclaration() async {
    // This test verifies that the `lookupThisType` query properly
    // understands that in a pattern variable declaration, the pattern executes
    // *after* the initializer.
    await assertThisTypes(r'''
class C {
  f() {
    var (/*this: C*/ _ as D /*this: D*/) = /*this: C*/ this;
    /*this: D*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPrimaryConstructorBody() async {
    await assertThisTypes(r'''
class C() {
  this {
    /*this: C*/
    if (this is D) {
      /*this: D*/
    }
    /*this: C*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPrimaryConstructorInitializerList() async {
    // The flow analysis region for a primary constructor body covers the
    // initializer list as well as the body, but `this` isn't bound until the
    // body is reached.
    await assertThisTypes(r'''
class C(int y) {
  final Object x;
  this : x = /*this: null*/ y {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inStaticFieldInitializer() async {
    // `this` isn't accessible in the initializer of a static field.
    await assertThisTypes(r'''
class C {
  static final Object x = /*this: null*/ 0;
}
''');
  }

  test_thisPromotion_inStaticMethod() async {
    // Static methods don't have access to `this`, but it's still important to
    // make sure that querying the type of `this` doesn't lead to a
    // crash.
    await assertThisTypes(r'''
class C {
  static f() {
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inTopLevelFunction() async {
    // `this` isn't meaningful in a top level function, but it's still important
    // to make sure that querying the type of `this` doesn't lead to a
    // crash.
    await assertThisTypes(r'''
f() {
  /*this: null*/
}
''');
  }

  test_thisPromotion_inTopLevelVariableInitializer() async {
    // `this` isn't accessible in a top level variable initializer, but it's
    // still important to make sure that querying the type of `this` doesn't
    // lead to a crash.
    await assertThisTypes(r'''
final Object x = /*this: null*/ 0;
''');
  }

  test_thisPromotion_outsideAnyFlowAnalysisRoot() async {
    // Some offsets aren't inside any flow analysis root at all; querying them
    // should simply return `null`.
    await assertThisTypes(r'''
/*this: null*/
class C {
  f() {}
  /*this: null*/
  g() {}
}
''');
  }

  test_thisPromotion_withHorizontalInference_firstArgument() async {
    // Horizontal inference of invocation arguments causes function literals to
    // be visited after all other arguments, so a promotion in a
    // non-function-literal argument can affect the type of `this` in an earlier
    // function literal argument.
    await assertThisTypes(r'''
class C {
  f() {
    g /*this: C*/ (
      () { /*this: D*/ }, /*this: C*/ this as D /*this: D*/)
      /*this: D*/ ;
  }
}
class D extends C {}
g(Object? x, Object? y) {}
''');
  }

  test_thisPromotion_withHorizontalInference_notFirstArgument() async {
    // Horizontal inference of invocation arguments causes function literals to
    // be visited after all other arguments, so a promotion in a
    // non-function-literal argument can affect the type of `this` in an earlier
    // function literal argument.
    await assertThisTypes(r'''
class C {
  f() {
    g(0 /*this: C*/,
      () { /*this: D*/ }, /*this: C*/ this as D /*this: D*/)
      /*this: D*/ ;
  }
}
class D extends C {}
g(Object? x, Object? y, Object? z) {}
''');
  }
}

/// Test cases that are run with anonymous methods enabled.
///
/// This class extends [LookupThisTypeTest] so that the test cases there will
/// get exercised both with and without anonymous methods enabled.
@reflectiveTest
class LookupThisTypeTestWithAnonymousMethods extends LookupThisTypeTest {
  @override
  List<Feature> get experimentalFeatures => [
    ...super.experimentalFeatures,
    Feature.anonymous_methods,
  ];

  test_thisPromotion_expressionBodiedAnonymousMethod() async {
    await assertThisTypes(r'''
class C {
  f() {
    /*this: C*/
    (0 as num).=> [
      /*this: num*/
      this as int,
      /*this: int*/
    ];
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inConstructorInitializerList_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  final Object x;
  C() : x = /*this: null*/ (0 as num).=> [
    /*this: num*/
    this as int,
    /*this: int*/
  ] {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inDefaultValueOfConstructor_anonymousMethod() async {
    // Although an anonymous method in a default value is illegal, it should
    // still be analyzed correctly.
    await assertThisTypes(r'''
class C {
  C({Object? p = /*this: null*/ (0 as num).=> /*this: num*/ 1}) {
//                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inDefaultValueOfMethod_anonymousMethod() async {
    // Although an anonymous method in a default value is illegal, it should
    // still be analyzed correctly.
    await assertThisTypes(r'''
class C {
  void f({Object? p = /*this: null*/ (0 as num).=> /*this: num*/ 1}) {
//                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inDefaultValueOfPrimaryConstructor_anonymousMethod() async {
    // Although an anonymous method in a default value is illegal, it should
    // still be analyzed correctly.
    await assertThisTypes(r'''
class C({Object? p = /*this: null*/ (0 as num).=> /*this: num*/ 1}) {
//                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
  this {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inDefaultValueOfStaticMethod_anonymousMethod() async {
    // Although an anonymous method in a default value is illegal, it should
    // still be analyzed correctly.
    await assertThisTypes(r'''
class C {
  static void f({Object? p = /*this: null*/ (0 as num).=> /*this: num*/ 1}) {
//                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inDefaultValueOfTopLevelFunction_anonymousMethod() async {
    // Although an anonymous method in a default value is illegal, it should
    // still be analyzed correctly.
    await assertThisTypes(r'''
void f({Object? p = /*this: null*/ (0 as num).=> /*this: num*/ 1}) {
//                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
  /*this: null*/
}
''');
  }

  test_thisPromotion_inFactoryConstructor_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  factory C() {
    /*this: null*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
    throw '';
  }
}
''');
  }

  test_thisPromotion_inGenerativeConstructor_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  C() {
    /*this: C*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inInstanceFieldInitializer_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  final Object x = /*this: null*/ (0 as num).=> [
    /*this: num*/
    this as int,
    /*this: int*/
  ];
}
''');
  }

  test_thisPromotion_inLateInstanceFieldInitializer_anonymousMethod() async {
    // In a `late` instance field initializer, `this` is bound to the enclosing
    // class outside the anonymous method, and to the anonymous method's
    // receiver inside it.
    await assertThisTypes(r'''
class C {
  late final Object x = (0 as num).=> [
    /*this: num*/
    this as int,
    /*this: int*/
  ];
  late final Object y = this is D ? /*this: D*/ 0 : /*this: C*/ 1;
}
class D extends C {}
''');
  }

  test_thisPromotion_inMethod_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  f() {
    /*this: C*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inPrimaryConstructorBody_anonymousMethod() async {
    await assertThisTypes(r'''
class C() {
  this {
    /*this: C*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inPrimaryConstructorInitializerList_anonymousMethod() async {
    await assertThisTypes(r'''
class C(int y) {
  final Object x;
  this : x = /*this: null*/ (0 as num).=> [
    /*this: num*/
    this as int,
    /*this: int*/
  ] {
    /*this: C*/
  }
}
''');
  }

  test_thisPromotion_inStaticFieldInitializer_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  static final Object x = /*this: null*/ (0 as num).=> [
    /*this: num*/
    this as int,
    /*this: int*/
  ];
}
''');
  }

  test_thisPromotion_inStaticMethod_anonymousMethod() async {
    await assertThisTypes(r'''
class C {
  static f() {
    /*this: null*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inTopLevelFunction_anonymousMethod() async {
    await assertThisTypes(r'''
f() {
    /*this: null*/
    (0 as num).{
      /*this: num*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
}
''');
  }

  test_thisPromotion_inTopLevelVariableInitializer_anonymousMethod() async {
    // An anonymous method binds `this` even though there's no enclosing
    // function body.
    await assertThisTypes(r'''
final Object x = /*this: null*/ (0 as num).=> [
  /*this: num*/
  this as int,
  /*this: int*/
];
''');
  }

  test_thisPromotion_nonThisBindingAnonymousMethod() async {
    await assertThisTypes(r'''
class C {
  f() {
    this as D;
    /*this: D*/
    0.(x) {
      /*this: D*/
      this as E;
      /*this: E*/
    };
    /*this: E*/
  }
}
class D extends C {}
class E extends D {}
''');
  }
}
