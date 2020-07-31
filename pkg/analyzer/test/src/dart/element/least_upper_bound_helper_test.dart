// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InterfaceLeastUpperBoundHelperTest);
  });
}

@reflectiveTest
class InterfaceLeastUpperBoundHelperTest with ElementsTypesMixin {
  @override
  final TestTypeProvider typeProvider = TestTypeProvider();

  void test_computeLongestInheritancePathToObject_multipleInterfacePaths() {
    //
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    ClassElementImpl classE = ElementFactory.classElement2("E");
    classB.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classD.interfaces = <InterfaceType>[interfaceTypeStar(classC)];
    classE.interfaces = <InterfaceType>[
      interfaceTypeStar(classB),
      interfaceTypeStar(classD)
    ];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE implements typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classE), 4);
  }

  void test_computeLongestInheritancePathToObject_multipleSuperclassPaths() {
    //
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    ClassElement classC =
        ElementFactory.classElement("C", interfaceTypeStar(classA));
    ClassElement classD =
        ElementFactory.classElement("D", interfaceTypeStar(classC));
    ClassElementImpl classE =
        ElementFactory.classElement("E", interfaceTypeStar(classB));
    classE.interfaces = <InterfaceType>[interfaceTypeStar(classD)];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE extends typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classE), 4);
  }

  void test_computeLongestInheritancePathToObject_object() {
    expect(_longestPathToObject(typeProvider.objectType.element), 0);
  }

  void test_computeLongestInheritancePathToObject_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    expect(_longestPathToObject(classA), 2);
  }

  void test_computeLongestInheritancePathToObject_singleInterfacePath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classB.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeStar(classB)];
    expect(_longestPathToObject(classA), 1);
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classC), 3);
  }

  void test_computeLongestInheritancePathToObject_singleSuperclassPath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    ClassElement classC =
        ElementFactory.classElement("C", interfaceTypeStar(classB));
    expect(_longestPathToObject(classA), 1);
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classC), 3);
  }

  void test_computeSuperinterfaceSet_genericInterfacePath() {
    //
    //  A
    //  | implements
    //  B<T>
    //  | implements
    //  C<T>
    //
    //  D
    //

    var instObject = InstantiatedClass.of(typeProvider.objectType);

    ClassElementImpl classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var BT = typeParameter('T');
    var classB = class_(
      name: 'B',
      typeParameters: [BT],
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var CT = typeParameter('T');
    var classC = class_(
      name: 'C',
      typeParameters: [CT],
      interfaces: [
        InstantiatedClass(
          classB,
          [typeParameterTypeStar(CT)],
        ).withNullabilitySuffixNone,
      ],
    );

    var classD = class_(name: 'D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([instObject, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classC, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([
        instObject,
        instA,
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ]),
    );
  }

  void test_computeSuperinterfaceSet_genericSuperclassPath() {
    //
    //  A
    //  |
    //  B<T>
    //  |
    //  C<T>
    //
    //  D
    //

    var instObject = InstantiatedClass.of(typeProvider.objectType);

    ClassElementImpl classA = ElementFactory.classElement2('A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      typeParameterNames: ['T'],
      supertype: instA.withNullabilitySuffixNone,
    );

    var typeParametersC = ElementFactory.typeParameters(['T']);
    var classC = ElementFactory.classElement3(
      name: 'B',
      typeParameters: typeParametersC,
      supertype: InstantiatedClass(
        classB,
        [typeParameterTypeStar(typeParametersC[0])],
      ).withNullabilitySuffixNone,
    );

    var classD = ElementFactory.classElement2('D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([instObject, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classC, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([
        instObject,
        instA,
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ]),
    );
  }

  void test_computeSuperinterfaceSet_mixin_constraints() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(name: 'C');
    var instC = InstantiatedClass(classC, const []);

    var mixinM = mixin_(
      name: 'M',
      constraints: [
        instB.withNullabilitySuffixNone,
        instC.withNullabilitySuffixNone,
      ],
    );
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject, instA, instB, instC]),
    );
  }

  void test_computeSuperinterfaceSet_mixin_constraints_object() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var mixinM = mixin_(name: 'M');
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject]),
    );
  }

  void test_computeSuperinterfaceSet_mixin_interfaces() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(name: 'C');
    var instC = InstantiatedClass(classC, const []);

    var mixinM = mixin_(
      name: 'M',
      interfaces: [
        instB.withNullabilitySuffixNone,
        instC.withNullabilitySuffixNone,
      ],
    );
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject, instA, instB, instC]),
    );
  }

  void test_computeSuperinterfaceSet_multipleInterfacePaths() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(
      name: 'C',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instC = InstantiatedClass(classC, const []);

    var classD = ElementFactory.classElement3(
      name: 'D',
      interfaces: [instC.withNullabilitySuffixNone],
    );
    var instD = InstantiatedClass(classD, const []);

    var classE = ElementFactory.classElement3(
      name: 'E',
      interfaces: [
        instB.withNullabilitySuffixNone,
        instD.withNullabilitySuffixNone,
      ],
    );
    var instE = InstantiatedClass(classE, const []);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([instObject, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([instObject, instA, instB, instC, instD]),
    );
  }

  void test_computeSuperinterfaceSet_multipleSuperclassPaths() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      supertype: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(
      name: 'C',
      supertype: instA.withNullabilitySuffixNone,
    );
    var instC = InstantiatedClass(classC, const []);

    var classD = ElementFactory.classElement3(
      name: 'D',
      supertype: instC.withNullabilitySuffixNone,
    );
    var instD = InstantiatedClass(classD, const []);

    var classE = ElementFactory.classElement3(
      name: 'E',
      supertype: instB.withNullabilitySuffixNone,
      interfaces: [
        instD.withNullabilitySuffixNone,
      ],
    );
    var instE = InstantiatedClass(classE, const []);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([instObject, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([instObject, instA, instB, instC, instD]),
    );
  }

  void test_computeSuperinterfaceSet_recursion() {
    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      supertype: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    classA.supertype = instB.withNullabilitySuffixNone;

    expect(
      _superInterfaces(instB),
      unorderedEquals([instA, instB]),
    );

    expect(
      _superInterfaces(instA),
      unorderedEquals([instA, instB]),
    );
  }

  void test_computeSuperinterfaceSet_singleInterfacePath() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(
      name: 'C',
      interfaces: [instB.withNullabilitySuffixNone],
    );
    var instC = InstantiatedClass(classC, const []);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([instObject, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([instObject, instA, instB]),
    );
  }

  void test_computeSuperinterfaceSet_singleSuperclassPath() {
    //
    //  A
    //  |
    //  B
    //  |
    //  C
    //
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = ElementFactory.classElement3(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = ElementFactory.classElement3(
      name: 'B',
      supertype: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = ElementFactory.classElement3(
      name: 'C',
      supertype: instB.withNullabilitySuffixNone,
    );
    var instC = InstantiatedClass(classC, const []);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([instObject, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([instObject, instA, instB]),
    );
  }

  int _longestPathToObject(ClassElement element) {
    return InterfaceLeastUpperBoundHelper.computeLongestInheritancePathToObject(
        element);
  }

  Set<InstantiatedClass> _superInterfaces(InstantiatedClass type) {
    return InterfaceLeastUpperBoundHelper.computeSuperinterfaceSet(type);
  }
}
