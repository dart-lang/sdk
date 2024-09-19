// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VarianceResolutionTest);
  });
}

@reflectiveTest
class VarianceResolutionTest extends PubPackageResolutionTest {
  @override
  List<String> get experiments {
    return [
      ...super.experiments,
      Feature.variance.enableString,
    ];
  }

  test_inference_in_parameter() async {
    await assertNoErrorsInCode('''
class Contravariant<in T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}

Exactly<T> inferContraContra<T>(Contravariant<T> x, Contravariant<T> y)
    => new Exactly<T>();

main() {
  inferContraContra(Contravariant<Upper>(), Contravariant<Middle>());
}
    ''');

    var node = findNode.methodInvocation('inferContraContra(');
    nodeTextConfiguration.skipArgumentList = true;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: inferContraContra
    staticElement: <testLibraryFragment>::@function::inferContraContra
    element: <testLibraryFragment>::@function::inferContraContra#element
    staticType: Exactly<T> Function<T>(Contravariant<T>, Contravariant<T>)
  staticInvokeType: Exactly<Middle> Function(Contravariant<Middle>, Contravariant<Middle>)
  staticType: Exactly<Middle>
  typeArgumentTypes
    Middle
''');
  }

  test_inference_in_parameter_downwards() async {
    await assertErrorsInCode('''
class B<in T> {
  B(List<T> x);
  void set x(T val) {}
}

main() {
  B<int> b = B(<num>[])..x=2.2;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 76, 1),
    ]);

    var node = findNode.instanceCreation('B(<num>');
    nodeTextConfiguration.skipArgumentList = true;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibraryFragment>::@class::B
      element2: <testLibraryFragment>::@class::B#element
      type: B<num>
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::B::@constructor::new
      substitution: {T: num}
    element: <testLibraryFragment>::@class::B::@constructor::new#element
  staticType: B<num>
''');
  }

  test_inference_inout_parameter() async {
    await assertErrorsInCode('''
class Invariant<inout T> {}

class Exactly<inout T> {}

Exactly<T> inferInvInv<T>(Invariant<T> x, Invariant<T> y) => new Exactly<T>();

main() {
  inferInvInv(Invariant<String>(), Invariant<int>());
}
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 147, 11),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 159, 19),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 180, 16),
    ]);

    var node = findNode.methodInvocation('inferInvInv(');
    nodeTextConfiguration.skipArgumentList = true;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: inferInvInv
    staticElement: <testLibraryFragment>::@function::inferInvInv
    element: <testLibraryFragment>::@function::inferInvInv#element
    staticType: Exactly<T> Function<T>(Invariant<T>, Invariant<T>)
  staticInvokeType: Exactly<Object> Function(Invariant<Object>, Invariant<Object>)
  staticType: Exactly<Object>
  typeArgumentTypes
    Object
''');
  }

  test_inference_out_parameter() async {
    await assertNoErrorsInCode('''
class Covariant<out T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}

Exactly<T> inferCovCov<T>(Covariant<T> x, Covariant<T> y) => new Exactly<T>();

main() {
  inferCovCov(Covariant<Upper>(), Covariant<Middle>());
}
''');

    var node = findNode.methodInvocation('inferCovCov(');
    nodeTextConfiguration.skipArgumentList = true;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: inferCovCov
    staticElement: <testLibraryFragment>::@function::inferCovCov
    element: <testLibraryFragment>::@function::inferCovCov#element
    staticType: Exactly<T> Function<T>(Covariant<T>, Covariant<T>)
  staticInvokeType: Exactly<Upper> Function(Covariant<Upper>, Covariant<Upper>)
  staticType: Exactly<Upper>
  typeArgumentTypes
    Upper
''');
  }
}
