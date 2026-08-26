// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The tests in this file verify that the [FunctionBody.lookupPromotedThisType]
/// method can be reliably used to query the type of `this` at any offset within
/// a function body, without requiring an explicit reference to `this` to be
/// present in the AST.
library;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../util/diff.dart';
import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LookupPromotedThisTypeTest);
    defineReflectiveTests(LookupPromotedThisTypeTestWithAnonymousMethods);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test cases that are run with anonymous methods disabled.
@reflectiveTest
class LookupPromotedThisTypeTest extends PubPackageResolutionTest {
  static final _promotedThisTypeExpectation = RegExp(
    r'/\*this:\s*([^*]*?)\s*\*/',
  );

  Future<void> assertPromotedThisTypes(String code) async {
    // These markers identify the ranges to rewrite in the original test code,
    // preserving any diagnostic expectations that it contains.
    var expectedMarkers = _promotedThisTypeExpectation
        .allMatches(code)
        .toList();

    if (expectedMarkers.isEmpty) {
      fail('Expected at least one promoted-this type marker.');
    }

    var result = await resolveTestCodeWithDiagnostics(code);

    // These markers provide query offsets in the code that was actually
    // resolved, after diagnostic expectations have been removed.
    var resolvedMarkers = _promotedThisTypeExpectation
        .allMatches(result.content)
        .toList();
    if (resolvedMarkers.length != expectedMarkers.length) {
      fail(
        'Expected ${expectedMarkers.length} promoted-this type markers in the '
        'resolved code, found ${resolvedMarkers.length}.',
      );
    }

    var actualCode = StringBuffer();
    var previousEnd = 0;
    for (var i = 0; i < expectedMarkers.length; i++) {
      var expectedMarker = expectedMarkers[i];
      var resolvedMarker = resolvedMarkers[i];
      var node = NodeLocator2(resolvedMarker.start).searchWithin(result.unit);
      if (node == null) {
        fail('No AST node at offset ${resolvedMarker.start}.');
      }

      // Local function bodies cannot be queried directly, so use the outermost
      // enclosing body whose flow analysis log covers the marker.
      FunctionBody? outermostBody;
      for (var ancestor in node.withAncestors2.whereType<FunctionBody>()) {
        outermostBody = ancestor;
      }
      if (outermostBody == null) {
        fail('No enclosing function body at offset ${resolvedMarker.start}.');
      }

      var type = outermostBody.lookupPromotedThisType(
        offset: resolvedMarker.start,
      );
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

  test_thisPromotion_inFactoryConstructor() async {
    // Factory constructors don't have access to `this`, but it's still
    // important to make sure that querying the promoted type of `this` doesn't
    // lead to a crash.
    await assertPromotedThisTypes(r'''
class C {
  factory C() {
    /*this: null*/
    throw '';
  }
}
''');
  }

  test_thisPromotion_inForLoop() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a `for` loop, the "updaters" part executes *after*
    // the body.
    await assertPromotedThisTypes(r'''
class C {
  f() {
    for (int i = 0; i < 10 /*this: null*/; /*this: D*/ i++) {
      /*this: null*/
      this as D;
      /*this: D*/
    }
    /*this: null*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inGenerativeConstructor() async {
    await assertPromotedThisTypes(r'''
class C {
  C() {
    /*this: null*/
    if (this is D) {
      /*this: D*/
    }
    /*this: null*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inMethod() async {
    await assertPromotedThisTypes(r'''
class C {
  f() {
    /*this: null*/
    if (this is D) {
      /*this: D*/
    }
    /*this: null*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPatternAssignment() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a pattern assignment, the pattern executes *after*
    // the RHS.
    await assertPromotedThisTypes(r'''
class C {
  f() {
    (/*this: null*/ _ as D /*this: D*/) = /*this: null*/ this;
    /*this: D*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPatternVariableDeclaration() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a pattern variable declaration, the pattern executes
    // *after* the initializer.
    await assertPromotedThisTypes(r'''
class C {
  f() {
    var (/*this: null*/ _ as D /*this: D*/) = /*this: null*/ this;
    /*this: D*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inPrimaryConstructorBody() async {
    await assertPromotedThisTypes(r'''
class C() {
  this {
    /*this: null*/
    if (this is D) {
      /*this: D*/
    }
    /*this: null*/
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_inStaticMethod() async {
    // Static methods don't have access to `this`, but it's still important to
    // make sure that querying the promoted type of `this` doesn't lead to a
    // crash.
    await assertPromotedThisTypes(r'''
class C {
  static f() {
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inTopLevelFunction() async {
    // `this` isn't meaningful in a top level function, but it's still important
    // to make sure that querying the promoted type of `this` doesn't lead to a
    // crash.
    await assertPromotedThisTypes(r'''
f() {
  /*this: null*/
}
''');
  }

  test_thisPromotion_withHorizontalInference_firstArgument() async {
    // Horizontal inference of invocation arguments causes function literals to
    // be visited after all other arguments, so a promotion in a
    // non-function-literal argument can affect the type of `this` in an earlier
    // function literal argument.
    await assertPromotedThisTypes(r'''
class C {
  f() {
    g /*this: null*/ (
      () { /*this: D*/ }, /*this: null*/ this as D /*this: D*/)
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
    await assertPromotedThisTypes(r'''
class C {
  f() {
    g(0 /*this: null*/,
      () { /*this: D*/ }, /*this: null*/ this as D /*this: D*/)
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
/// This class extends [LookupPromotedThisTypeTest] so that the test cases there will get
/// exercised both with and without anonymous methods enabled.
@reflectiveTest
class LookupPromotedThisTypeTestWithAnonymousMethods
    extends LookupPromotedThisTypeTest {
  @override
  List<Feature> get experimentalFeatures => [
    ...super.experimentalFeatures,
    Feature.anonymous_methods,
  ];

  test_thisPromotion_expressionBodiedAnonymousMethod() async {
    await assertPromotedThisTypes(r'''
class C {
  f() {
    /*this: null*/
    (0 as num).=> [
      /*this: null*/
      this as int,
      /*this: int*/
    ];
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inFactoryConstructor_anonymousMethod() async {
    await assertPromotedThisTypes(r'''
class C {
  factory C() {
    /*this: null*/
    (0 as num).{
      /*this: null*/
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
    await assertPromotedThisTypes(r'''
class C {
  C() {
    /*this: null*/
    (0 as num).{
      /*this: null*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inMethod_anonymousMethod() async {
    await assertPromotedThisTypes(r'''
class C {
  f() {
    /*this: null*/
    (0 as num).{
      /*this: null*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inPrimaryConstructorBody_anonymousMethod() async {
    await assertPromotedThisTypes(r'''
class C() {
  this {
    /*this: null*/
    (0 as num).{
      /*this: null*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inStaticMethod_anonymousMethod() async {
    await assertPromotedThisTypes(r'''
class C {
  static f() {
    /*this: null*/
    (0 as num).{
      /*this: null*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
  }
}
''');
  }

  test_thisPromotion_inTopLevelFunction_anonymousMethod() async {
    await assertPromotedThisTypes(r'''
f() {
    /*this: null*/
    (0 as num).{
      /*this: null*/
      this as int;
      /*this: int*/
    };
    /*this: null*/
}
''');
  }

  test_thisPromotion_nonThisBindingAnonymousMethod() async {
    await assertPromotedThisTypes(r'''
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
