// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
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
class PathToObjectTest extends _Base {
  void test_class_mixins1() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'X', supertype: 'A', mixins: ['M1']),
      ],
      mixins: [MixinSpec(name: 'M1')],
    );
    var M1 = mixinElement('M1');
    expect(_toElement(M1), 2);

    var A = classElement('A');
    expect(_toElement(A), 2);
    var X = classElement('X');

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class X extends _X&A&M1 {}
    //    length: 3
    expect(_toElement(X), 4);
  }

  void test_class_mixins2() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'X', supertype: 'A', mixins: ['M1', 'M2']),
      ],
      mixins: [
        MixinSpec(name: 'M1'),
        MixinSpec(name: 'M2'),
      ],
    );
    var M1 = mixinElement('M1');
    var M2 = mixinElement('M2');
    expect(_toElement(M1), 2);
    expect(_toElement(M2), 2);

    var A = classElement('A');
    expect(_toElement(A), 2);
    var X = classElement('X');

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 3
    // class X extends _X&A&M1&M2 {}
    //    length: 4
    expect(_toElement(X), 5);
  }

  void test_class_mixins_longerViaSecondMixin() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'I1'),
        ClassSpec(name: 'I2', supertype: 'I1'),
        ClassSpec(name: 'I3', supertype: 'I2'),
        ClassSpec(name: 'A'),
        ClassSpec(name: 'X', supertype: 'A', mixins: ['M1', 'M2']),
      ],
      mixins: [
        MixinSpec(name: 'M1'),
        MixinSpec(name: 'M2', interfaces: ['I3']),
      ],
    );
    var I1 = classElement('I1');
    var I2 = classElement('I2');
    var I3 = classElement('I3');

    expect(_toElement(I1), 2);
    expect(_toElement(I2), 3);
    expect(_toElement(I3), 4);

    var M1 = mixinElement('M1');
    var M2 = mixinElement('M2');
    expect(_toElement(M1), 2);
    expect(_toElement(M2), 5);

    var A = classElement('A');
    expect(_toElement(A), 2);
    var X = classElement('X');

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 5 = max(1 + _X&A&M1, 1 + M2)
    // class X extends _X&A&M1&M2 {}
    //    length: 6
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C', interfaces: ['A']),
        ClassSpec(name: 'D', interfaces: ['C']),
        ClassSpec(name: 'E', interfaces: ['B', 'D']),
      ],
    );
    var classB = classElement('B');
    var classE = classElement('E');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
        ClassSpec(name: 'C', supertype: 'A'),
        ClassSpec(name: 'D', supertype: 'C'),
        ClassSpec(name: 'E', supertype: 'B', interfaces: ['D']),
      ],
    );
    var classB = classElement('B');
    var classE = classElement('E');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
      ],
    );
    var classA = classElement('A');
    var classB = classElement('B');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C', interfaces: ['B']),
      ],
    );
    var classA = classElement('A');
    var classB = classElement('B');
    var classC = classElement('C');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
        ClassSpec(name: 'C', supertype: 'B'),
      ],
    );
    var classA = classElement('A');
    var classB = classElement('B');
    var classC = classElement('C');
    expect(_toElement(classA), 2);
    expect(_toElement(classB), 3);
    expect(_toElement(classC), 4);
  }

  void test_mixin_constraints_interfaces_allSame() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B'),
        ClassSpec(name: 'I'),
        ClassSpec(name: 'J'),
      ],
      mixins: [
        MixinSpec(name: 'M', constraints: ['A', 'B'], interfaces: ['I', 'J']),
      ],
    );
    var A = classElement('A');
    var B = classElement('B');
    var I = classElement('I');
    var J = classElement('J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 2);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);
    var M = mixinElement('M');
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toElement(M), 3);
  }

  void test_mixin_longerConstraint_1() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A1'),
        ClassSpec(name: 'A', supertype: 'A1'),
        ClassSpec(name: 'B'),
        ClassSpec(name: 'I'),
        ClassSpec(name: 'J'),
      ],
      mixins: [
        MixinSpec(name: 'M', constraints: ['A', 'B'], interfaces: ['I', 'J']),
      ],
    );
    var A = classElement('A');
    var B = classElement('B');
    var I = classElement('I');
    var J = classElement('J');
    expect(_toElement(A), 3);
    expect(_toElement(B), 2);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);
    var M = mixinElement('M');
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toElement(M), 4);
  }

  void test_mixin_longerConstraint_2() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B1'),
        ClassSpec(name: 'B', interfaces: ['B1']),
        ClassSpec(name: 'I'),
        ClassSpec(name: 'J'),
      ],
      mixins: [
        MixinSpec(name: 'M', constraints: ['A', 'B'], interfaces: ['I', 'J']),
      ],
    );
    var A = classElement('A');
    var B = classElement('B');
    var I = classElement('I');
    var J = classElement('J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 3);
    expect(_toElement(I), 2);
    expect(_toElement(J), 2);
    var M = mixinElement('M');
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toElement(M), 4);
  }

  void test_mixin_longerInterface_1() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B'),
        ClassSpec(name: 'I1'),
        ClassSpec(name: 'I', interfaces: ['I1']),
        ClassSpec(name: 'J'),
      ],
      mixins: [
        MixinSpec(name: 'M', constraints: ['A', 'B'], interfaces: ['I', 'J']),
      ],
    );
    var A = classElement('A');
    var B = classElement('B');
    var I = classElement('I');
    var J = classElement('J');
    expect(_toElement(A), 2);
    expect(_toElement(B), 2);
    expect(_toElement(I), 3);
    expect(_toElement(J), 2);
    var M = mixinElement('M');
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toElement(M), 4);
  }

  int _toElement(InterfaceElementImpl element) {
    var type = interfaceTypeNone(element);
    return _toType(type);
  }

  int _toType(InterfaceType type) {
    return InterfaceLeastUpperBoundHelper.computeLongestInheritancePathToObject(
      type,
    );
  }
}

@reflectiveTest
class SuperinterfaceSetTest extends _Base {
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

    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', typeParameters: ['T'], interfaces: ['A']),
        ClassSpec(name: 'C', typeParameters: ['T'], interfaces: ['B<T>']),
        ClassSpec(name: 'D'),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var classC = classElement('C');
    var classD = classElement('D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classB, typeArguments: [interfaceTypeNone(classD)]),
      ),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classC, typeArguments: [interfaceTypeNone(classD)]),
      ),
      unorderedEquals([
        objectQuestion,
        objectNone,
        instA,
        interfaceTypeNone(classB, typeArguments: [interfaceTypeNone(classD)]),
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

    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', typeParameters: ['T'], supertype: 'A'),
        ClassSpec(name: 'C', typeParameters: ['T'], supertype: 'B<T>'),
        ClassSpec(name: 'D'),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var classC = classElement('C');
    var classD = classElement('D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([objectQuestion, objectNone]),
    );

    // B<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classB, typeArguments: [interfaceTypeNone(classD)]),
      ),
      unorderedEquals([objectQuestion, objectNone, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        interfaceTypeNone(classC, typeArguments: [interfaceTypeNone(classD)]),
      ),
      unorderedEquals([
        objectQuestion,
        objectNone,
        instA,
        interfaceTypeNone(classB, typeArguments: [interfaceTypeNone(classD)]),
      ]),
    );
  }

  void test_mixin_constraints() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C'),
      ],
      mixins: [
        MixinSpec(name: 'M', constraints: ['B', 'C']),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
    var instC = interfaceTypeNone(classC);
    var mixinM = mixinElement('M');
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC]),
    );
  }

  void test_mixin_constraints_object() {
    buildLibrary(mixins: [MixinSpec(name: 'M')]);
    var mixinM = mixinElement('M');
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone]),
    );
  }

  void test_mixin_interfaces() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C'),
      ],
      mixins: [
        MixinSpec(name: 'M', interfaces: ['B', 'C']),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
    var instC = interfaceTypeNone(classC);
    var mixinM = mixinElement('M');
    var instM = interfaceTypeNone(mixinM);

    expect(
      _superInterfaces(instM),
      unorderedEquals([objectQuestion, objectNone, instA, instB, instC]),
    );
  }

  void test_multipleInterfacePaths() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C', interfaces: ['A']),
        ClassSpec(name: 'D', interfaces: ['C']),
        ClassSpec(name: 'E', interfaces: ['B', 'D']),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
    var instC = interfaceTypeNone(classC);
    var classD = classElement('D');
    var instD = interfaceTypeNone(classD);
    var classE = classElement('E');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
        ClassSpec(name: 'C', supertype: 'A'),
        ClassSpec(name: 'D', supertype: 'C'),
        ClassSpec(name: 'E', supertype: 'B', interfaces: ['D']),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
    var instC = interfaceTypeNone(classC);
    var classD = classElement('D');
    var instD = interfaceTypeNone(classD);
    var classE = classElement('E');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);

    classA.supertype = instB;

    expect(_superInterfaces(instB), unorderedEquals([instA, instB]));

    expect(_superInterfaces(instA), unorderedEquals([instA, instB]));
  }

  void test_singleInterfacePath() {
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', interfaces: ['A']),
        ClassSpec(name: 'C', interfaces: ['B']),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
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
    buildLibrary(
      classes: [
        ClassSpec(name: 'A'),
        ClassSpec(name: 'B', supertype: 'A'),
        ClassSpec(name: 'C', supertype: 'B'),
      ],
    );
    var classA = classElement('A');
    var instA = interfaceTypeNone(classA);
    var classB = classElement('B');
    var instB = interfaceTypeNone(classB);
    var classC = classElement('C');
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

abstract class _Base extends AbstractTypeSystemTest {
  void buildLibrary({
    List<ClassSpec> classes = const [],
    List<MixinSpec> mixins = const [],
  }) {
    testLibrary = buildTestLibrary(
      LibrarySpec(
        uri: 'package:test/test.dart',
        imports: const ['dart:core'],
        classes: classes,
        mixins: mixins,
      ),
    );
  }

  ClassElementImpl classElement(String name) {
    return testLibrary.getClass(name)!;
  }

  MixinElementImpl mixinElement(String name) {
    return testLibrary.getMixin(name)!;
  }
}
