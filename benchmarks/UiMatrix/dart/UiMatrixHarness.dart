// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Various math benchmarks from https://github.com/yjbanov/uimatrix

import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_math/vector_math_64.dart';

import 'uimatrix.dart';

const int N = 5000;
Object? sink;

void main() {
  InstantiateIdentityMatrix4().report();
  InstantiateIdentityUiMatrix().report();
  Instantiate2DTranslationMatrix4().report();
  Instantiate2DTranslationUiMatrix().report();
  InstantiateSimple2DMatrix4().report();
  InstantiateSimple2DUiMatrix().report();
  InstantiateComplexMatrix4().report();
  InstantiateComplexUiMatrix().report();

  MultiplyIdentityByIdentityMatrix4().report();
  MultiplyIdentityByIdentityUiMatrix().report();
  MultiplySimply2DByIdentityMatrix4().report();
  MultiplySimply2DByIdentityUiMatrix().report();
  MultiplySimple2DBySimple2DMatrix4().report();
  MultiplySimple2DBySimple2DUiMatrix().report();
  MultiplyComplexByComplexMatrix4().report();
  MultiplyComplexByComplexUiMatrix().report();

  AddIdentityPlusIdentityMatrix4().report();
  AddIdentityPlusIdentityUiMatrix().report();
  AddSimple2DPlusIdentityMatrix4().report();
  AddSimple2DPlusIdentityUiMatrix().report();
  AddSimple2DPlusSimple2DMatrix4().report();
  AddSimple2DPlusSimple2DUiMatrix().report();
  AddComplexPlusComplexMatrix4().report();
  AddComplexPlusComplexUiMatrix().report();

  InversionIdentityMatrix4().report();
  InversionIdentityUiMatrix().report();
  InversionSimple2DMatrix4().report();
  InversionSimple2DUiMatrix().report();
  InversionComplexMatrix4().report();
  InversionComplexUiMatrix().report();

  DeterminantIdentityMatrix4().report();
  DeterminantIdentityUiMatrix().report();
  DeterminantSimple2DMatrix4().report();
  DeterminantSimple2DUiMatrix().report();
  DeterminantComplexMatrix4().report();
  DeterminantComplexUiMatrix().report();
}

class InstantiateIdentityMatrix4 extends BenchmarkBase {
  InstantiateIdentityMatrix4() : super('Instantiate_Identity_Matrix4');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += Matrix4.identity().storage[0];
    }
    sink = total;
  }
}

class InstantiateIdentityUiMatrix extends BenchmarkBase {
  InstantiateIdentityUiMatrix() : super('Instantiate_Identity_UiMatrix');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += UiMatrix.identity.scaleX;
    }
    sink = total;
  }
}

class Instantiate2DTranslationMatrix4 extends BenchmarkBase {
  Instantiate2DTranslationMatrix4()
      : super('Instantiate_2DTranslation_Matrix4');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += Matrix4.translationValues(0.4, 3.45, 0).storage[0];
    }
    sink = total;
  }
}

class Instantiate2DTranslationUiMatrix extends BenchmarkBase {
  Instantiate2DTranslationUiMatrix()
      : super('Instantiate_2DTranslation_UiMatrix');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += UiMatrix.translation2d(dx: 0.4, dy: 3.45).scaleX;
    }
    sink = total;
  }
}

class InstantiateSimple2DMatrix4 extends BenchmarkBase {
  InstantiateSimple2DMatrix4() : super('Instantiate_Simple2D_Matrix4');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (Matrix4.identity()
            ..translate(0.4, 3.45)
            ..scale(1.2, 2.3))
          .storage[0];
    }
    sink = total;
  }
}

class InstantiateSimple2DUiMatrix extends BenchmarkBase {
  InstantiateSimple2DUiMatrix() : super('Instantiate_Simple2D_UiMatrix');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total +=
          UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45).scaleX;
    }
    sink = total;
  }
}

class InstantiateComplexMatrix4 extends BenchmarkBase {
  InstantiateComplexMatrix4() : super('Instantiate_Complex_Matrix4');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (Matrix4.identity()
            ..rotateZ(0.1)
            ..translate(0.4, 3.45))
          .storage[0];
    }
    sink = total;
  }
}

class InstantiateComplexUiMatrix extends BenchmarkBase {
  InstantiateComplexUiMatrix() : super('Instantiate_Complex_UiMatrix');

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      final cosAngle = math.cos(0.1);
      final sinAngle = math.sin(0.1);
      total += UiMatrix.transform2d(
        scaleX: cosAngle,
        scaleY: cosAngle,
        k1: -sinAngle,
        k2: sinAngle,
        dx: 0.4,
        dy: 3.45,
      ).scaleX;
    }
    sink = total;
  }
}

late UiMatrix a;
late UiMatrix b;
late Matrix4 a4;
late Matrix4 b4;

class MultiplyIdentityByIdentityMatrix4 extends BenchmarkBase {
  MultiplyIdentityByIdentityMatrix4()
      : super('Multiply_IdentityByIdentity_Matrix4') {
    a4 = Matrix4.identity();
    b4 = Matrix4.identity();
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 * b4 as Matrix4).storage[0];
    }
    sink = total;
  }
}

class MultiplyIdentityByIdentityUiMatrix extends BenchmarkBase {
  MultiplyIdentityByIdentityUiMatrix()
      : super('Multiply_IdentityByIdentity_UiMatrix') {
    a = UiMatrix.identity;
    b = UiMatrix.identity;
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a * b).scaleX;
    }
    sink = total;
  }
}

class MultiplySimply2DByIdentityMatrix4 extends BenchmarkBase {
  MultiplySimply2DByIdentityMatrix4()
      : super('Multiply_Simple2DByIdentity_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
    b4 = Matrix4.identity();
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 * b4 as Matrix4).storage[0];
    }
    sink = total;
  }
}

class MultiplySimply2DByIdentityUiMatrix extends BenchmarkBase {
  MultiplySimply2DByIdentityUiMatrix()
      : super('Multiply_Simple2DByIdentity_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
    b = UiMatrix.identity;
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a * b).scaleX;
    }
    sink = total;
  }
}

class MultiplySimple2DBySimple2DMatrix4 extends BenchmarkBase {
  MultiplySimple2DBySimple2DMatrix4()
      : super('Multiply_Simple2DBySimple2D_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
    b4 = Matrix4.identity()
      ..translate(0.5, 3.46)
      ..scale(1.7, 2.8);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 * b4 as Matrix4).storage[0];
    }
    sink = total;
  }
}

class MultiplySimple2DBySimple2DUiMatrix extends BenchmarkBase {
  MultiplySimple2DBySimple2DUiMatrix()
      : super('Multiply_Simple2DBySimple2D_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
    b = UiMatrix.simple2d(scaleX: 1.3, scaleY: 2.4, dx: 0.5, dy: 3.46);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a * b).scaleX;
    }
    sink = total;
  }
}

class MultiplyComplexByComplexMatrix4 extends BenchmarkBase {
  MultiplyComplexByComplexMatrix4()
      : super('Multiply_ComplexByComplex_Matrix4') {
    a4 = Matrix4.identity()
      ..rotateZ(0.1)
      ..translate(0.4, 3.45);
    b4 = Matrix4.identity()
      ..rotateZ(0.2)
      ..translate(0.3, 3.44);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 * b4 as Matrix4).storage[0];
    }
    sink = total;
  }
}

class MultiplyComplexByComplexUiMatrix extends BenchmarkBase {
  MultiplyComplexByComplexUiMatrix()
      : super('Multiply_ComplexByComplex_UiMatrix') {
    a = UiMatrix.transform2d(
      scaleX: math.cos(0.1),
      scaleY: math.cos(0.1),
      k1: -math.sin(0.1),
      k2: math.sin(0.1),
      dx: 0.4,
      dy: 3.45,
    );
    b = UiMatrix.transform2d(
      scaleX: math.cos(0.2),
      scaleY: math.cos(0.2),
      k1: -math.sin(0.2),
      k2: math.sin(0.2),
      dx: 0.4,
      dy: 3.45,
    );
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a * b).scaleX;
    }
    sink = total;
  }
}

class AddIdentityPlusIdentityMatrix4 extends BenchmarkBase {
  AddIdentityPlusIdentityMatrix4() : super('Add_IdentityPlusIdentity_Matrix4') {
    a4 = Matrix4.identity();
    b4 = Matrix4.identity();
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 + b4).storage[0];
    }
    sink = total;
  }
}

class AddIdentityPlusIdentityUiMatrix extends BenchmarkBase {
  AddIdentityPlusIdentityUiMatrix()
      : super('Add_IdentityPlusIdentity_UiMatrix') {
    a = UiMatrix.identity;
    b = UiMatrix.identity;
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a + b).scaleX;
    }
    sink = total;
  }
}

class AddSimple2DPlusIdentityMatrix4 extends BenchmarkBase {
  AddSimple2DPlusIdentityMatrix4() : super('Add_Simple2DPlusIdentity_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
    b4 = Matrix4.identity();
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 + b4).storage[0];
    }
    sink = total;
  }
}

class AddSimple2DPlusIdentityUiMatrix extends BenchmarkBase {
  AddSimple2DPlusIdentityUiMatrix()
      : super('Add_Simple2DPlusIdentity_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
    b = UiMatrix.identity;
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a + b).scaleX;
    }
    sink = total;
  }
}

class AddSimple2DPlusSimple2DMatrix4 extends BenchmarkBase {
  AddSimple2DPlusSimple2DMatrix4() : super('Add_Simple2DPlusSimple2D_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
    b4 = Matrix4.identity()
      ..translate(0.5, 3.46)
      ..scale(1.7, 2.8);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 + b4).storage[0];
    }
    sink = total;
  }
}

class AddSimple2DPlusSimple2DUiMatrix extends BenchmarkBase {
  AddSimple2DPlusSimple2DUiMatrix()
      : super('Add_Simple2DPlusSimple2D_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
    b = UiMatrix.simple2d(scaleX: 1.3, scaleY: 2.4, dx: 0.5, dy: 3.46);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a + b).scaleX;
    }
    sink = total;
  }
}

class AddComplexPlusComplexMatrix4 extends BenchmarkBase {
  AddComplexPlusComplexMatrix4() : super('Add_ComplexPlusComplex_Matrix4') {
    a4 = Matrix4.identity()
      ..rotateZ(0.1)
      ..translate(0.4, 3.45);
    b4 = Matrix4.identity()
      ..rotateZ(0.2)
      ..translate(0.3, 3.44);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a4 + b4).storage[0];
    }
    sink = total;
  }
}

class AddComplexPlusComplexUiMatrix extends BenchmarkBase {
  AddComplexPlusComplexUiMatrix() : super('Add_ComplexPlusComplex_UiMatrix') {
    a = UiMatrix.transform2d(
      scaleX: math.cos(0.1),
      scaleY: math.cos(0.1),
      k1: -math.sin(0.1),
      k2: math.sin(0.1),
      dx: 0.4,
      dy: 3.45,
    );
    b = UiMatrix.transform2d(
      scaleX: math.cos(0.2),
      scaleY: math.cos(0.2),
      k1: -math.sin(0.2),
      k2: math.sin(0.2),
      dx: 0.4,
      dy: 3.45,
    );
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += (a + b).scaleX;
    }
    sink = total;
  }
}

class InversionIdentityMatrix4 extends BenchmarkBase {
  InversionIdentityMatrix4() : super('Inversion_Identity_Matrix4') {
    a4 = Matrix4.identity();
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      final Matrix4 m = Matrix4.zero()..copyInverse(a4);
      total += m.storage[0];
    }
    sink = total;
  }
}

class InversionIdentityUiMatrix extends BenchmarkBase {
  InversionIdentityUiMatrix() : super('Inversion_Identity_UiMatrix') {
    a = UiMatrix.identity;
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.invert()!.scaleX;
    }
    sink = total;
  }
}

class InversionSimple2DMatrix4 extends BenchmarkBase {
  InversionSimple2DMatrix4() : super('Inversion_Simple2D_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      final Matrix4 m = Matrix4.zero()..copyInverse(a4);
      total += m.storage[0];
    }
    sink = total;
  }
}

class InversionSimple2DUiMatrix extends BenchmarkBase {
  InversionSimple2DUiMatrix() : super('Inversion_Simple2D_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.invert()!.scaleX;
    }
    sink = total;
  }
}

class InversionComplexMatrix4 extends BenchmarkBase {
  InversionComplexMatrix4() : super('Inversion_Complex_Matrix4') {
    a4 = Matrix4.identity()
      ..rotateZ(0.1)
      ..translate(0.4, 3.45);
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      final Matrix4 m = Matrix4.zero()..copyInverse(a4);
      total += m.storage[0];
    }
    sink = total;
  }
}

class InversionComplexUiMatrix extends BenchmarkBase {
  InversionComplexUiMatrix() : super('Inversion_Complex_UiMatrix') {
    a = UiMatrix.transform2d(
      scaleX: math.cos(0.1),
      scaleY: math.cos(0.1),
      k1: -math.sin(0.1),
      k2: math.sin(0.1),
      dx: 0.4,
      dy: 3.45,
    );
  }

  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.invert()!.scaleX;
    }
    sink = total;
  }
}

class DeterminantIdentityMatrix4 extends BenchmarkBase {
  DeterminantIdentityMatrix4() : super('Determinant_Identity_Matrix4') {
    a4 = Matrix4.identity();
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a4.determinant();
    }
    sink = total;
  }
}

class DeterminantIdentityUiMatrix extends BenchmarkBase {
  DeterminantIdentityUiMatrix() : super('Determinant_Identity_UiMatrix') {
    a = UiMatrix.identity;
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.determinant();
    }
    sink = total;
  }
}

class DeterminantSimple2DMatrix4 extends BenchmarkBase {
  DeterminantSimple2DMatrix4() : super('Determinant_Simple2D_Matrix4') {
    a4 = Matrix4.identity()
      ..translate(0.4, 3.45)
      ..scale(1.2, 2.3);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a4.determinant();
    }
    sink = total;
  }
}

class DeterminantSimple2DUiMatrix extends BenchmarkBase {
  DeterminantSimple2DUiMatrix() : super('Determinant_Simple2D_UiMatrix') {
    a = UiMatrix.simple2d(scaleX: 1.2, scaleY: 2.3, dx: 0.4, dy: 3.45);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.determinant();
    }
    sink = total;
  }
}

class DeterminantComplexMatrix4 extends BenchmarkBase {
  DeterminantComplexMatrix4() : super('Determinant_Complex_Matrix4') {
    a4 = Matrix4.identity()
      ..rotateZ(0.1)
      ..translate(0.4, 3.45);
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a4.determinant();
    }
    sink = total;
  }
}

class DeterminantComplexUiMatrix extends BenchmarkBase {
  DeterminantComplexUiMatrix() : super('Determinant_Complex_UiMatrix') {
    a = UiMatrix.transform2d(
      scaleX: math.cos(0.1),
      scaleY: math.cos(0.1),
      k1: -math.sin(0.1),
      k2: math.sin(0.1),
      dx: 0.4,
      dy: 3.45,
    );
  }
  @override
  void run() {
    double total = 0;
    for (int i = 0; i < N; i++) {
      total += a.determinant();
    }
    sink = total;
  }
}
