// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  Class1? get property => null;

  void set property(Class1? value) {}

  Class1 get property1 => new Class1();

  Class2 get property2 => new Class2();

  Class1? get nullable1 => property1;

  void set nullable1(Class1? value) {
    property = value;
  }

  Class1 nonNullable1Method() => nonNullable1;

  Class1? operator [](Class1? key) => nullable1;

  void operator []=(Class1? key, Class1? value) {
    property = value;
  }

  Class1? operator +(int value) => nullable1;

  Class1? operator -() => nullable1;

  Class1 get nonNullable1 => property1;

  Class2 get nonNullable2 => property2;
}

class Class2 {
  Class2 get property => this;

  void set property(Class2 value) {}

  Class2 nonNullable2Method() => nonNullable2;

  Class2 operator [](Class2? key) => property;

  void operator []=(Class2? key, Class2? value) => property;

  Class2 operator +(int value) => property;

  Class2 operator -() => property;

  Class2 get nonNullable2 => property;

  void set nonNullable2(Class2 value) {
    property = value;
  }
}

class Class3 {
  Class2? get property => null;

  Class2? operator [](Class3? key) => property;
}

main() {
  propertyAccess(null);
  indexAccess(null, null, null);
  operatorAccess(null, null);
  ifNull(null);
}

void propertyAccess(Class1? n1) {
  Class1? nullable1 = n1;

  n1?.nullable1;
  n1?.nullable1 = new Class1();
  nullable1 = n1?.nullable1 = new Class1();
  n1?.nonNullable1Method();

  n1?.nonNullable1.nullable1;
  n1?.nullable1?.nullable1;
  n1?.nonNullable1.nullable1?.nullable1;
  n1?.nonNullable1.nullable1 = new Class1();
  n1?.nullable1?.nullable1 = new Class1();
  n1?.nonNullable1.nullable1?.nullable1 = new Class1();
  (n1?.nullable1)?.nullable1;
  throws(() => (n1?.nullable1 = new Class1()).nullable1);
  throws(() => (n1?.nonNullable1Method()).nullable1);
  nullable1 = n1?.nonNullable1.nullable1 = new Class1();
  nullable1 = n1?.nullable1?.nullable1 = new Class1();
  nullable1 = n1?.nonNullable1.nullable1?.nullable1 = new Class1();
  n1?.nullable1?.nonNullable1Method();
  n1?.nullable1 = new Class1().nullable1;
  nullable1 = n1?.nullable1 = new Class1().nullable1;
  n1?.nullable1 = new Class1().nullable1 = new Class1();
  nullable1 = n1?.nullable1 = new Class1().nullable1 = new Class1();
  n1?.nullable1 = new Class1().nonNullable1Method();
  nullable1 = n1?.nullable1 = new Class1().nonNullable1Method();
  n1?.nonNullable1Method().nullable1;
  n1?.nonNullable1Method().nullable1 = new Class1();
  n1?.nonNullable1Method().nonNullable1Method();

  n1?.nonNullable1.nonNullable1.nullable1;
  n1?.nonNullable1.nonNullable1.nullable1 = new Class1();
  nullable1 = n1?.nonNullable1.nonNullable1.nullable1 = new Class1();
  n1?.nonNullable1.nullable1?.nonNullable1Method();
  n1?.nullable1 = new Class1().nonNullable1.nullable1;
  nullable1 = n1?.nullable1 = new Class1().nonNullable1.nullable1;
  n1?.nullable1 = new Class1().nonNullable1.nullable1 = new Class1();
  nullable1 =
      n1?.nullable1 = new Class1().nonNullable1.nullable1 = new Class1();
  n1?.nullable1 = new Class1().nonNullable1.nonNullable1Method();
  nullable1 = n1?.nullable1 = new Class1().nonNullable1.nonNullable1Method();
  n1?.nonNullable1Method().nonNullable1.nullable1;
  n1?.nonNullable1Method().nonNullable1.nullable1 = new Class1();
  n1?.nonNullable1Method().nonNullable1.nonNullable1Method();

  n1?.nonNullable1.nullable1 = new Class1().nullable1;
  nullable1 = n1?.nonNullable1.nullable1 = new Class1().nullable1;
  n1?.nonNullable1.nullable1 = new Class1().nullable1 = new Class1();
  nullable1 =
      n1?.nonNullable1.nullable1 = new Class1().nullable1 = new Class1();
  n1?.nonNullable1.nullable1 = new Class1().nonNullable1Method();
  nullable1 = n1?.nonNullable1.nullable1 = new Class1().nonNullable1Method();
  n1?.nullable1 = new Class1().nullable1 = new Class1().nullable1;
  nullable1 = n1?.nullable1 = new Class1().nullable1 = new Class1().nullable1;
  n1?.nullable1 =
      new Class1().nullable1 = new Class1().nullable1 = new Class1();
  nullable1 = n1?.nullable1 =
      new Class1().nullable1 = new Class1().nullable1 = new Class1();
  n1?.nullable1 = new Class1().nullable1 = new Class1().nonNullable1Method();
  nullable1 = n1?.nullable1 =
      new Class1().nullable1 = new Class1().nonNullable1Method();
  n1?.nonNullable1Method().nullable1 = new Class1().nullable1;
  nullable1 = n1?.nonNullable1Method().nullable1 = new Class1().nullable1;
  n1?.nonNullable1Method().nullable1 = new Class1().nullable1 = new Class1();
  nullable1 = n1?.nonNullable1Method().nullable1 =
      new Class1().nullable1 = new Class1();
  n1?.nonNullable1Method().nullable1 = new Class1().nonNullable1Method();
  nullable1 =
      n1?.nonNullable1Method().nullable1 = new Class1().nonNullable1Method();

  n1?.nonNullable1.nonNullable1Method().nullable1;
  n1?.nonNullable1.nonNullable1Method().nullable1 = new Class1();
  nullable1 = n1?.nonNullable1.nonNullable1Method().nullable1 = new Class1();
  n1?.nonNullable1.nonNullable1Method().nonNullable1Method();
  n1?.nullable1 = new Class1().nonNullable1Method().nullable1;
  nullable1 = n1?.nullable1 = new Class1().nonNullable1Method().nullable1;
  n1?.nullable1 = new Class1().nonNullable1Method().nullable1 = new Class1();
  nullable1 = n1?.nullable1 =
      new Class1().nonNullable1Method().nullable1 = new Class1();
  n1?.nullable1 = new Class1().nonNullable1Method().nonNullable1Method();
  nullable1 =
      n1?.nullable1 = new Class1().nonNullable1Method().nonNullable1Method();
  n1?.nonNullable1Method().nonNullable1Method().nullable1;
  n1?.nonNullable1Method().nonNullable1Method().nullable1 = new Class1();
  n1?.nonNullable1Method().nonNullable1Method().nonNullable1Method();

  n1?.nonNullable1Method()?.nonNullable1Method();
}

void indexAccess(Class1? n1, Class2? n2, Class3? n3) {
  Class1? nullable1 = n1;
  Class2? nullable2 = n2;
  Class3? nullable3 = n3;

  n1?[nullable1];
  n1?[nullable1] = new Class1();
  n1?[nullable1]?.nonNullable1Method();
  n1?.nonNullable1[nullable1];
  n1?.nonNullable1[nullable1] = new Class1();
  nullable1 = n1?.nonNullable1[nullable1] = new Class1();
  n1?.nonNullable1[nullable1]?.nonNullable1Method();
  n1?.nonNullable2[nullable2] += 0;
  nullable2 = n1?.nonNullable2[nullable2] += 0;
  n1?[nullable1] ??= nullable1;
  nullable1 = n1?[nullable1] ??= nullable1;
  n2?[nullable2] += 0;
  nullable2 = n2?[nullable2] += 0;
  n2?[nullable2] += 0;
  nullable2 = n2?[nullable2] += 0;
  n2?[nullable2]++;
  nullable2 = n2?[nullable2]++;
  ++n2?[nullable2];
  nullable2 = ++n2?[nullable2];
  n1?.nonNullable2[nullable2]++;
  nullable2 = n1?.nonNullable2[nullable2]++;
  ++n1?.nonNullable2[nullable2];
  nullable2 = ++n1?.nonNullable2[nullable2];

  n1?.nonNullable2[nullable2][nullable2];
  n1?.nonNullable2[nullable2][nullable2] = new Class2();
  nullable2 = n1?.nonNullable2[nullable2][nullable2] = new Class2();
  n1?.nonNullable2[nullable2][nullable2]?.nonNullable2Method();
  n1?.nonNullable2[nullable2][nullable2] += 0;
  nullable2 = n1?.nonNullable2[nullable2][nullable2] += 0;
  n1?.nonNullable2[nullable2][nullable2]++;
  nullable2 = n1?.nonNullable2[nullable2][nullable2]++;
  ++n1?.nonNullable2[nullable2][nullable2];
  nullable2 = ++n1?.nonNullable2[nullable2][nullable2];

  n1?[nullable1]?[nullable1];
  n1?[nullable1]?[nullable1] = new Class1();
  nullable1 = n1?[nullable1]?[nullable1] = new Class1();
  n1?[nullable1]?[nullable1]?.nonNullable1Method();
  nullable1 = n1?[nullable1]?[nullable1]?.nonNullable1Method();
  n1?[nullable1]?[nullable1] ??= nullable1;
  nullable1 = n1?[nullable1]?[nullable1] ??= nullable1;
  n3?[nullable3]?[nullable2] += 0;
  nullable2 = n3?[nullable3]?[nullable2] += 0;
  n3?[nullable3]?[nullable2]++;
  nullable2 = n3?[nullable3]?[nullable2]++;
  ++n3?[nullable3]?[nullable2];
  nullable2 = ++n3?[nullable3]?[nullable2];
}

void operatorAccess(Class1? n1, Class2? n2) {
  Class2? nullable2 = n2;

  throws(() => n1?.nonNullable1 + 0);
  throws(() => -n1?.nonNullable1);
  n2?.nonNullable2 += 0;
  nullable2 = n2?.nonNullable2 += 0;
  n2?.nonNullable2.nonNullable2 += 0;
  nullable2 = n2?.nonNullable2.nonNullable2 += 0;
  n2?.nonNullable2++;
  nullable2 = n2?.nonNullable2++;
  ++n2?.nonNullable2;
  nullable2 = ++n2?.nonNullable2;
}

void ifNull(Class1? n1) {
  Class1? nullable1 = n1;

  n1?.nullable1 ??= n1;
  n1 = n1?.nullable1 ??= n1;
  n1?.nonNullable1.nullable1 ??= n1;
  n1 = n1?.nonNullable1.nullable1 ??= n1;
  n1?.nonNullable1[n1] ??= n1;
  n1 = n1?.nonNullable1[n1] ??= n1;
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception.';
}
