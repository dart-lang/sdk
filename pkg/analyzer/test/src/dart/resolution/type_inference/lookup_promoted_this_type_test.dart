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
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
  test_thisPromotion_inFactoryConstructor() async {
    // Factory constructors don't have access to `this`, but it's still
    // important to make sure that querying the promoted type of `this` doesn't
    // lead to a crash.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C() {
    /* target */
    throw '';
  }
}
''');
    var body = result.findNode.singleConstructorDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inForLoop() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a `for` loop, the "updaters" part executes *after*
    // the body.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    for (int i = 0; i < 10 /* target 1 */; /* target 2 */ i++) {
      /* target 3 */
      this as D;
      /* target 4 */
    }
    /* target 5 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 5 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inGenerativeConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C() {
    /* target 1 */
    if (this is D) {
      /* target 2 */
    }
    /* target 3 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singleConstructorDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    /* target 1 */
    if (this is D) {
      /* target 2 */
    }
    /* target 3 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inPatternAssignment() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a pattern assignment, the pattern executes *after*
    // the RHS.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    (/* target 1 */ _ as D /* target 2 */) = /* target 3 */ this;
    /* target 4 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )!
          .toString(),
      'D',
    );
  }

  test_thisPromotion_inPatternVariableDeclaration() async {
    // This test verifies that the `lookupPromotedThisType` query properly
    // understands that in a pattern variable declaration, the pattern executes
    // *after* the initializer.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    var (/* target 1 */ _ as D /* target 2 */) = /* target 3 */ this;
    /* target 4 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )!
          .toString(),
      'D',
    );
  }

  test_thisPromotion_inPrimaryConstructorBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C() {
  this {
    /* target 1 */
    if (this is D) {
      /* target 2 */
    }
    /* target 3 */
  }
}
class D extends C {}
''');
    var body = result.findNode.singlePrimaryConstructorBody.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inStaticMethod() async {
    // Static methods don't have access to `this`, but it's still important to
    // make sure that querying the promoted type of `this` doesn't lead to a
    // crash.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static f() {
    /* target */
  }
}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inTopLevelFunction() async {
    // `this` isn't meaningful in a top level function, but it's still important
    // to make sure that querying the promoted type of `this` doesn't lead to a
    // crash.
    var result = await resolveTestCodeWithDiagnostics(r'''
f() {
  /* target */
}
''');
    var body = result.findNode.singleFunctionBody;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_withHorizontalInference_firstArgument() async {
    // Horizontal inference of invocation arguments causes function literals to
    // be visited after all other arguments, so a promotion in a
    // non-function-literal argument can affect the type of `this` in an earlier
    // function literal argument.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    g /* target 1 */ (
      () { /* target 2 */ }, /* target 3 */ this as D /* target 4 */)
      /* target 5 */ ;
  }
}
class D extends C {}
g(Object? x, Object? y) {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 5 */'),
          )!
          .toString(),
      'D',
    );
  }

  test_thisPromotion_withHorizontalInference_notFirstArgument() async {
    // Horizontal inference of invocation arguments causes function literals to
    // be visited after all other arguments, so a promotion in a
    // non-function-literal argument can affect the type of `this` in an earlier
    // function literal argument.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    g(0 /* target 1 */,
      () { /* target 2 */ }, /* target 3 */ this as D /* target 4 */)
      /* target 5 */ ;
  }
}
class D extends C {}
g(Object? x, Object? y, Object? z) {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 3 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )!
          .toString(),
      'D',
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 5 */'),
          )!
          .toString(),
      'D',
    );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    /* target 1 */
    (0 as num).=> [
      /* target 2 */
      this as int,
      /* target 3 */
    ];
    /* target 4 */
  }
}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inFactoryConstructor_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C() {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
    throw '';
  }
}
''');
    var body = result.findNode.singleConstructorDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inGenerativeConstructor_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C() {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
  }
}
''');
    var body = result.findNode.singleConstructorDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inMethod_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
  }
}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inPrimaryConstructorBody_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C() {
  this {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
  }
}
''');
    var body = result.findNode.singlePrimaryConstructorBody.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inStaticMethod_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static f() {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
  }
}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_inTopLevelFunction_anonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f() {
    /* target 1 */
    (0 as num).{
      /* target 2 */
      this as int;
      /* target 3 */
    };
    /* target 4 */
}
''');
    var body = result.findNode.singleFunctionBody;
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 1 */'),
      ),
      isNull,
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 2 */'),
      ),
      isNull,
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'int',
    );
    expect(
      body.lookupPromotedThisType(
        offset: result.content.indexOf('/* target 4 */'),
      ),
      isNull,
    );
  }

  test_thisPromotion_nonThisBindingAnonymousMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    this as D;
    /* target 1 */
    0.(x) {
      /* target 2 */
      this as E;
      /* target 3 */
    };
    /* target 4 */
  }
}
class D extends C {}
class E extends D {}
''');
    var body = result.findNode.singleMethodDeclaration.body;
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 1 */'),
          )
          .toString(),
      'D',
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 2 */'),
          )
          .toString(),
      'D',
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 3 */'),
          )!
          .toString(),
      'E',
    );
    expect(
      body
          .lookupPromotedThisType(
            offset: result.content.indexOf('/* target 4 */'),
          )
          .toString(),
      'E',
    );
  }
}
