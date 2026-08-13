// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
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
class PathToObjectTest extends AbstractTypeSystemTest {
  void test_class_mixins1() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class X extends A with M1')],
      mixins: [MixinSpec('mixin M1')],
    );
    expect(_toType(parseInterfaceType('M1')), 2);
    expect(_toType(parseInterfaceType('A')), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class X extends _X&A&M1 {}
    //    length: 3
    expect(_toType(parseInterfaceType('X')), 4);
  }

  void test_class_mixins2() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class X extends A with M1, M2'),
      ],
      mixins: [MixinSpec('mixin M1'), MixinSpec('mixin M2')],
    );
    expect(_toType(parseInterfaceType('M1')), 2);
    expect(_toType(parseInterfaceType('M2')), 2);
    expect(_toType(parseInterfaceType('A')), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 3
    // class X extends _X&A&M1&M2 {}
    //    length: 4
    expect(_toType(parseInterfaceType('X')), 5);
  }

  void test_class_mixins_longerViaSecondMixin() {
    buildTestLibrary(
      classes: [
        ClassSpec('class I1'),
        ClassSpec('class I2 extends I1'),
        ClassSpec('class I3 extends I2'),
        ClassSpec('class A'),
        ClassSpec('class X extends A with M1, M2'),
      ],
      mixins: [MixinSpec('mixin M1'), MixinSpec('mixin M2 implements I3')],
    );
    expect(_toType(parseInterfaceType('I1')), 2);
    expect(_toType(parseInterfaceType('I2')), 3);
    expect(_toType(parseInterfaceType('I3')), 4);
    expect(_toType(parseInterfaceType('M1')), 2);
    expect(_toType(parseInterfaceType('M2')), 5);
    expect(_toType(parseInterfaceType('A')), 2);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 5 = max(1 + _X&A&M1, 1 + M2)
    // class X extends _X&A&M1&M2 {}
    //    length: 6
    expect(_toType(parseInterfaceType('X')), 7);
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
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements A'),
        ClassSpec('class D implements C'),
        ClassSpec('class E implements B, D'),
      ],
    );
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE implements typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_toType(parseInterfaceType('B')), 3);
    expect(_toType(parseInterfaceType('E')), 5);
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
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
        ClassSpec('class D extends C'),
        ClassSpec('class E extends B implements D'),
      ],
    );
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE extends typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_toType(parseInterfaceType('B')), 3);
    expect(_toType(parseInterfaceType('E')), 5);
  }

  void test_class_null() {
    expect(_toType(parseInterfaceType('Null')), 1);
  }

  void test_class_object() {
    expect(_toType(parseInterfaceType('Object?')), 0);
    expect(_toType(parseInterfaceType('Object')), 1);
  }

  void test_class_recursion() {
    buildTestLibrary(
      classes: [ClassSpec('class A extends B'), ClassSpec('class B extends A')],
    );
    expect(_toType(parseInterfaceType('A')), 2);
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
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements B'),
      ],
    );
    expect(_toType(parseInterfaceType('A')), 2);
    expect(_toType(parseInterfaceType('B')), 3);
    expect(_toType(parseInterfaceType('C')), 4);
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
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends B'),
      ],
    );
    expect(_toType(parseInterfaceType('A')), 2);
    expect(_toType(parseInterfaceType('B')), 3);
    expect(_toType(parseInterfaceType('C')), 4);
  }

  void test_mixin_constraints_interfaces_allSame() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B'),
        ClassSpec('class I'),
        ClassSpec('class J'),
      ],
      mixins: [MixinSpec('mixin M on A, B implements I, J')],
    );
    expect(_toType(parseInterfaceType('A')), 2);
    expect(_toType(parseInterfaceType('B')), 2);
    expect(_toType(parseInterfaceType('I')), 2);
    expect(_toType(parseInterfaceType('J')), 2);
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toType(parseInterfaceType('M')), 3);
  }

  void test_mixin_longerConstraint_1() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A1'),
        ClassSpec('class A extends A1'),
        ClassSpec('class B'),
        ClassSpec('class I'),
        ClassSpec('class J'),
      ],
      mixins: [MixinSpec('mixin M on A, B implements I, J')],
    );
    expect(_toType(parseInterfaceType('A')), 3);
    expect(_toType(parseInterfaceType('B')), 2);
    expect(_toType(parseInterfaceType('I')), 2);
    expect(_toType(parseInterfaceType('J')), 2);
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toType(parseInterfaceType('M')), 4);
  }

  void test_mixin_longerConstraint_2() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B1'),
        ClassSpec('class B implements B1'),
        ClassSpec('class I'),
        ClassSpec('class J'),
      ],
      mixins: [MixinSpec('mixin M on A, B implements I, J')],
    );
    expect(_toType(parseInterfaceType('A')), 2);
    expect(_toType(parseInterfaceType('B')), 3);
    expect(_toType(parseInterfaceType('I')), 2);
    expect(_toType(parseInterfaceType('J')), 2);
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toType(parseInterfaceType('M')), 4);
  }

  void test_mixin_longerInterface_1() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B'),
        ClassSpec('class I1'),
        ClassSpec('class I implements I1'),
        ClassSpec('class J'),
      ],
      mixins: [MixinSpec('mixin M on A, B implements I, J')],
    );
    expect(_toType(parseInterfaceType('A')), 2);
    expect(_toType(parseInterfaceType('B')), 2);
    expect(_toType(parseInterfaceType('I')), 3);
    expect(_toType(parseInterfaceType('J')), 2);
    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    expect(_toType(parseInterfaceType('M')), 4);
  }

  int _toType(InterfaceType type) {
    return InterfaceLeastUpperBoundHelper.computeLongestInheritancePathToObject(
      type,
    );
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

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B<T> implements A'),
        ClassSpec('class C<T> implements B<T>'),
        ClassSpec('class D'),
      ],
    );
    var instA = parseInterfaceType('A');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([parseType('Object?'), parseType('Object')]),
    );

    // B<D>
    expect(
      _superInterfaces(parseInterfaceType('B<D>')),
      unorderedEquals([parseType('Object?'), parseType('Object'), instA]),
    );

    // C<D>
    expect(
      _superInterfaces(parseInterfaceType('C<D>')),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        parseInterfaceType('B<D>'),
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

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B<T> extends A'),
        ClassSpec('class C<T> extends B<T>'),
        ClassSpec('class D'),
      ],
    );
    var instA = parseInterfaceType('A');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([parseType('Object?'), parseType('Object')]),
    );

    // B<D>
    expect(
      _superInterfaces(parseInterfaceType('B<D>')),
      unorderedEquals([parseType('Object?'), parseType('Object'), instA]),
    );

    // C<D>
    expect(
      _superInterfaces(parseInterfaceType('C<D>')),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        parseInterfaceType('B<D>'),
      ]),
    );
  }

  void test_mixin_constraints() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C'),
      ],
      mixins: [MixinSpec('mixin M on B, C')],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');
    var instM = parseInterfaceType('M');

    expect(
      _superInterfaces(instM),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
        instC,
      ]),
    );
  }

  void test_mixin_constraints_object() {
    buildTestLibrary(mixins: [MixinSpec('mixin M')]);
    var instM = parseInterfaceType('M');

    expect(
      _superInterfaces(instM),
      unorderedEquals([parseType('Object?'), parseType('Object')]),
    );
  }

  void test_mixin_interfaces() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C'),
      ],
      mixins: [MixinSpec('mixin M implements B, C')],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');
    var instM = parseInterfaceType('M');

    expect(
      _superInterfaces(instM),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
        instC,
      ]),
    );
  }

  void test_multipleInterfacePaths() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements A'),
        ClassSpec('class D implements C'),
        ClassSpec('class E implements B, D'),
      ],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');
    var instD = parseInterfaceType('D');
    var instE = parseInterfaceType('E');

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instC,
      ]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
        instC,
        instD,
      ]),
    );
  }

  void test_multipleSuperclassPaths() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
        ClassSpec('class D extends C'),
        ClassSpec('class E extends B implements D'),
      ],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');
    var instD = parseInterfaceType('D');
    var instE = parseInterfaceType('E');

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instC,
      ]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
        instC,
        instD,
      ]),
    );
  }

  void test_recursion() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class B extends A')],
    );
    var classA = classElement('A');
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');

    classA.supertype = instB;

    expect(_superInterfaces(instB), unorderedEquals([instA, instB]));

    expect(_superInterfaces(instA), unorderedEquals([instA, instB]));
  }

  void test_singleInterfacePath() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements B'),
      ],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([parseType('Object?'), parseType('Object')]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([parseType('Object?'), parseType('Object'), instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
      ]),
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
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends B'),
      ],
    );
    var instA = parseInterfaceType('A');
    var instB = parseInterfaceType('B');
    var instC = parseInterfaceType('C');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([parseType('Object?'), parseType('Object')]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([parseType('Object?'), parseType('Object'), instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([
        parseType('Object?'),
        parseType('Object'),
        instA,
        instB,
      ]),
    );
  }

  Set<InterfaceType> _superInterfaces(InterfaceType type) {
    var helper = InterfaceLeastUpperBoundHelper(typeSystem);
    return helper.computeSuperinterfaceSet(type);
  }
}
