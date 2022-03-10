// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VarianceTest);
  });
}

@reflectiveTest
class VarianceTest extends PubPackageResolutionTest {
  @override
  List<String> get experiments => [
        ...super.experiments,
        EnableString.variance,
      ];

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
    assertType(
        findNode.methodInvocation('inferContraContra(').typeArgumentTypes![0],
        'Middle');
  }

  test_inference_in_parameter_downwards() async {
    await assertErrorsInCode('''
class B<in T> {
  B(List<T> x);
  void set x(T val) {}
}

main() {
  B<int> b = new B(<num>[])..x=2.2;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 76, 1),
    ]);
    assertType(
        (findNode.instanceCreation('new B').staticType as InterfaceType)
            .typeArguments[0],
        'num');
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
    assertType(findNode.methodInvocation('inferCovCov(').typeArgumentTypes![0],
        'Upper');
  }
}
