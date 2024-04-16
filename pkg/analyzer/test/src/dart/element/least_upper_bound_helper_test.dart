// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathToObjectTest);
    defineReflectiveTests(SuperinterfaceSetTest);
  });
}

@reflectiveTest
class PathToObjectTest extends AbstractTypeSystemTest {
  void test_class_mixins1() {
    var M1 = mixin_(name: 'M1');
    expect(_toElement(M1), 2);

    var A = class_(name: 'A');
    expect(_toElement(A), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class X extends _X&A&M1 {}
    //    length: 3
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
      ],
    );

    expect(_toElement(X), 4);
  }

  void test_class_mixins2() {
    var M1 = mixin_(name: 'M1');
    var M2 = mixin_(name: 'M2');
    expect(_toElement(M1), 2);
    expect(_toElement(M2), 2);

    var A = class_(name: 'A');
    expect(_toElement(A), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 3
    // class X extends _X&A&M1&M2 {}
    //    length: 4
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
        interfaceTypeNone(M2),
      ],
    );

    expect(_toElement(X), 5);
  }

  void test_class_mixins_longerViaSecondMixin() {
    var I1 = class_(name: 'I1');
    var I2 = class_(name: 'I2', superType: interfaceTypeNone(I1));
    var I3 = class_(name: 'I3', superType: interfaceTypeNone(I2));

    expect(_toElement(I1), 2);
    expect(_toElement(I2), 3);
    expect(_toElement(I3), 4);

    var M1 = mixin_(name: 'M1');
    var M2 = mixin_(
      name: 'M2',
      interfaces: [interfaceTypeNone(I3)],
    );
    expect(_toElement(M1), 2);
    expect(_toElement(M2), 5);

    var A = class_(name: 'A');
    expect(_toElement(A), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 5 = max(1 + _X&A&M1, 1 + M2)
    // class X extends _X&A&M1&M2 {}
    //    length: 6
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
        interfaceTypeNone(M2),
      ],
    );

    expect(_toElement(X), 7);
  }

  void test_class_multipleInterfacePaths() {
    //
    //   Object?
    //     |
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB = class_(name: "B");
    ClassElementImpl classC = class_(name: "C");
    ClassElementImpl classD = class_(name: "D");
    ClassElementImpl classE = class_(name: "E");
    classB.interfaces = <InterfaceType>[interfaceTypeNone(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeNone(classA)];
    classD.interfaces = <InterfaceType>[interfaceTypeNone(classC)];
    classE.interfaces = <InterfaceType>[
      interfaceTypeNone(classB),
      interfaceTypeNone(classD)
    ];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE implements typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_toElement(classB), 3);
    expect(_toElement(classE), 5);
  }

  void test_class_multipleSuperclassPaths() {
    //
    //   Object?
    //     |
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElement classA = class_(name: "A");
    ClassElement classB =
        class_(name: "B", superType: interfaceTypeNone(classA));
    ClassElement classC =
        class_(name: "C", superType: interfaceTypeNone(classA));
    ClassElement classD =
        class_(name: "D", superType: interfaceTypeNone(classC));
    ClassElementImpl classE =
        class_(name: "E", superType: interfaceTypeNone(classB));
    classE.interfaces = <InterfaceType>[interfaceTypeNone(classD)];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE extends typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_toElement(classB), 3);
    expect(_toElement(classE), 5);
  }

  void test_class_null() {
    expect(_toType(nullNone), 1);
  }

  void test_class_object() {
    expect(_toType(objectQuestion), 0);
    expect(_toType(objectNone), 1);
  }

  void test_class_recursion() {
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB =
        class_(name: "B", superType: interfaceTypeNone(classA));
    classA.supertype = interfaceTypeNone(classB);
    expect(_toElement(classA), 2);
  }

  void test_class_singleInterfacePath() {
    //
    //   Object?
    //     |
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB = class_(name: "B");
    ClassElementImpl classC = class_(name: "C");
    classB.interfaces = <InterfaceType>[interfaceTypeNone(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeNone(classB)];
    expect(_toElement(classA), 2);
    expect(_toElement(classB), 3);
    expect(_toElement(classC), 4);
  }

  void test_class_singleSuperclassPath() {
    //
    //   Object?
    //     |
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElement classA = class_(name: "A");
    ClassElement classB =
        class_(name: "B", superType: interfaceTypeNone(classA));
    ClassElement classC =
        class_(name: "C", superType: interfaceTypeNone(classB));
    expect(_toElement(classA), 2);
    expect(_toElement(classB), 3);
    expect(_toElement(classC), 4);
  }

  void test_mixin_constraints_interfaces_allSame() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 2);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_toElement(M), 3);
  }

  void test_mixin_longerConstraint_1() {
    var A1 = class_(name: 'A1');
    var A = class_(
      name: 'A',
      superType: interfaceTypeNone(A1),
    );
    var B = class_(name: 'B');
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_toElement(A), 3);
    expect(_toElement(B), 2);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_toElement(M), 4);
  }

  void test_mixin_longerConstraint_2() {
    var A = class_(name: 'A');
    var B1 = class_(name: 'B1');
    var B = class_(
      name: 'B',
      interfaces: [
        interfaceTypeNone(B1),
      ],
    );
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 3);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_toElement(M), 4);
  }

  void test_mixin_longerInterface_1() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var I1 = class_(name: 'I1');
    var I = class_(
      name: 'I',
      interfaces: [
        interfaceTypeNone(I1),
      ],
    );
    var J = class_(name: 'J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 2);
    expect(_toElement(I), 3);
    expect(_toElement(J), 2);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_toElement(M), 4);
  }

  int _toElement(InterfaceElement element) {
    var type = interfaceTypeNone(element);
    return _toType(type);
  }

  int _toType(InterfaceType type) {
    return InterfaceLeastUpperBoundHelper.computeLongestInheritancePathToObject(
        type);
  }
}

@reflectiveTest
class SuperinterfaceSetTest extends AbstractTypeSystemTest {
  void test_genericInterfacePath() {
    //
    //  A
    //  | implements
    //  B<T>
    //  | implements
    //  C<T>
    //
    //  D
    //

    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var BT = typeParameter('T');
    var classB = class_(
      name: 'B',
      typeParameters: [BT],
      interfaces: [instA],
    );

    var CT = typeParameter('T');
    var classC = class_(
      name: 'C',
      typeParameters: [CT],
      interfaces: [
        interfaceTypeNone(classB, typeArguments: [
          typeParameterTypeNone(CT),
        ]),
      ],
    );

    var classD = class_(name: 'D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classB, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classC, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ),
      unorderedEquals([
        objectQuestion,
        objectNone,
        instA,
        interfaceTypeNone(classB, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ]),
    );
  }

  void test_genericSuperclassPath() {
    //
    //  A
    //  |
    //  B<T>
    //  |
    //  C<T>
    //
    //  D
    //

    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      typeParameters: [typeParameter('T')],
      superType: instA,
    );

    var typeParametersC = ElementFactory.typeParameters(['T']);
    var classC = class_(
      name: 'B',
      typeParameters: typeParametersC,
      superType: interfaceTypeNone(classB, typeArguments: [
        typeParameterTypeNone(typeParametersC[0]),
      ]),
    );

    var classD = class_(name: 'D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classB, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classC, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ),
      unorderedEquals([
        objectQuestion,
        objectNone,
        instA,
        interfaceTypeNone(classB, typeArguments: [
          interfaceTypeNone(classD),
        ]),
      ]),
    );
  }

  void test_mixin_constraints() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      interfaces: [instA],
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(name: 'C');
    var instC = interfaceTypeNone(classC);

    var mixinM = mixin_(
      name: 'M',
      constraints: [
        instB,
        instC,
      ],
    );
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC]),
    );
  }

  void test_mixin_constraints_object() {
    var mixinM = mixin_(name: 'M');
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone]),
    );
  }

  void test_mixin_interfaces() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      interfaces: [instA],
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(name: 'C');
    var instC = interfaceTypeNone(classC);

    var mixinM = mixin_(
      name: 'M',
      interfaces: [
        instB,
        instC,
      ],
    );
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC]),
    );
  }

  void test_multipleInterfacePaths() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      interfaces: [instA],
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(
      name: 'C',
      interfaces: [instA],
    );
    var instC = interfaceTypeNone(classC);

    var classD = class_(
      name: 'D',
      interfaces: [instC],
    );
    var instD = interfaceTypeNone(classD);

    var classE = class_(
      name: 'E',
      interfaces: [
        instB,
        instD,
      ],
    );
    var instE = interfaceTypeNone(classE);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([objectQuestion, objectNone, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC, instD]),
    );
  }

  void test_multipleSuperclassPaths() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      superType: instA,
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(
      name: 'C',
      superType: instA,
    );
    var instC = interfaceTypeNone(classC);

    var classD = class_(
      name: 'D',
      superType: instC,
    );
    var instD = interfaceTypeNone(classD);

    var classE = class_(
      name: 'E',
      superType: instB,
      interfaces: [
        instD,
      ],
    );
    var instE = interfaceTypeNone(classE);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([objectQuestion, objectNone, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC, instD]),
    );
  }

  void test_recursion() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      superType: instA,
    );
    var instB = interfaceTypeNone(classB);

    classA.supertype = instB;

    expect(
      _superInterfaces(instB),
      unorderedEquals([instA, instB]),
    );

    expect(
      _superInterfaces(instA),
      unorderedEquals([instA, instB]),
    );
  }

  void test_singleInterfacePath() {
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      interfaces: [instA],
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(
      name: 'C',
      interfaces: [instB],
    );
    var instC = interfaceTypeNone(classC);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([objectQuestion, objectNone, instA, instB]),
    );
  }

  void test_singleSuperclassPath() {
    //
    //  A
    //  |
    //  B
    //  |
    //  C
    //
    var classA = class_(name: 'A');
    var instA = interfaceTypeNone(classA);

    var classB = class_(
      name: 'B',
      superType: instA,
    );
    var instB = interfaceTypeNone(classB);

    var classC = class_(
      name: 'C',
      superType: instB,
    );
    var instC = interfaceTypeNone(classC);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([objectQuestion, objectNone, instA, instB]),
    );
  }

  Set<InterfaceType> _superInterfaces(InterfaceType type) {
    var helper = InterfaceLeastUpperBoundHelper(typeSystem);
    return helper.computeSuperinterfaceSet(type);
  }
}
