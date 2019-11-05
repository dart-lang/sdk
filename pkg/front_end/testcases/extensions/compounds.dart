// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Number {
  final int value;

  Number(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(Object other) => other is Number && value == other.value;

  String toString() => 'Number($value)';
}

extension NumberExtension on Number {
  Number operator +(Object other) {
    if (other is int) {
      return new Number(value + other);
    } else if (other is Number) {
      return new Number(value + other.value);
    } else {
      throw new ArgumentError('$other');
    }
  }

  Number operator -(Object other) {
    if (other is int) {
      return new Number(value - other);
    } else if (other is Number) {
      return new Number(value - other.value);
    } else {
      throw new ArgumentError('$other');
    }
  }
}

class Class {
  Number field;

  Class(this.field);
}

extension ClassExtension on Class {
  Number get property => field;
  void set property(Number value) {
    field = value;
  }

  testImplicitProperties() {
    Number n0 = new Number(0);
    Number n1 = new Number(1);
    Number n2 = new Number(2);

    expect(n0, property);
    expect(n1, property += n1);
    expect(n2, property += n1);
    expect(n0, property -= n2);
    expect(n1, property += n1);
    expect(n0, property -= n1);
    expect(n1, ++property);
    expect(n0, --property);
    expect(n0, property++);
    expect(n1, property--);
    expect(n0, property);

    expect(n0, property);
    property += n1;
    expect(n1, property);
    property += n1;
    expect(n2, property);
    property -= n2;
    expect(n0, property);
    property += n1;
    expect(n1, property);
    property -= n1;
    expect(n0, property);
    ++property;
    expect(n1, property);
    --property;
    expect(n0, property);
    property++;
    expect(n1, property);
    property--;
    expect(n0, property);
  }
}

class IntClass {
  int field;

  IntClass(this.field);
}

extension IntClassExtension on IntClass {
  int get property => field;
  void set property(int value) {
    field = value;
  }

  testImplicitProperties() {
    int n0 = 0;
    int n1 = 1;
    int n2 = 2;

    expect(n0, property);
    expect(n1, property += n1);
    expect(n2, property += n1);
    expect(n0, property -= n2);
    expect(n1, property += n1);
    expect(n0, property -= n1);
    expect(n1, ++property);
    expect(n0, --property);
    expect(n0, property++);
    expect(n1, property--);
    expect(n0, property);

    expect(n0, property);
    property += n1;
    expect(n1, property);
    property += n1;
    expect(n2, property);
    property -= n2;
    expect(n0, property);
    property += n1;
    expect(n1, property);
    property -= n1;
    expect(n0, property);
    ++property;
    expect(n1, property);
    --property;
    expect(n0, property);
    property++;
    expect(n1, property);
    property--;
    expect(n0, property);
  }
}

main() {
  testLocals();
  testProperties();
  testIntProperties();
  testExplicitProperties();
  testExplicitIntProperties();
  testExplicitNullAwareProperties(null);
  testExplicitNullAwareProperties(new Class(new Number(0)));
  testExplicitNullAwareIntProperties(null);
  testExplicitNullAwareIntProperties(new IntClass(0));
  new Class(new Number(0)).testImplicitProperties();
  new IntClass(0).testImplicitProperties();
}

testLocals() {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);
  Number v = n0;
  expect(n0, v);
  expect(n1, v += n1);
  expect(n2, v += n1);
  expect(n0, v -= n2);
  expect(n1, v += n1);
  expect(n0, v -= n1);
  expect(n1, ++v);
  expect(n0, --v);
  expect(n0, v++);
  expect(n1, v--);
  expect(n0, v);

  expect(n0, v);
  v += n1;
  expect(n1, v);
  v += n1;
  expect(n2, v);
  v -= n2;
  expect(n0, v);
  v += n1;
  expect(n1, v);
  v -= n1;
  expect(n0, v);
  ++v;
  expect(n1, v);
  --v;
  expect(n0, v);
  v++;
  expect(n1, v);
  v--;
  expect(n0, v);
}

testProperties() {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);
  Class v = new Class(n0);
  expect(n0, v.field);
  expect(n1, v.field += n1);
  expect(n2, v.field += n1);
  expect(n0, v.field -= n2);
  expect(n1, v.field += n1);
  expect(n0, v.field -= n1);
  expect(n1, ++v.field);
  expect(n0, --v.field);
  expect(n0, v.field++);
  expect(n1, v.field--);
  expect(n0, v.field);

  expect(n0, v.field);
  v.field += n1;
  expect(n1, v.field);
  v.field += n1;
  expect(n2, v.field);
  v.field -= n2;
  expect(n0, v.field);
  v.field += n1;
  expect(n1, v.field);
  v.field -= n1;
  expect(n0, v.field);
  ++v.field;
  expect(n1, v.field);
  --v.field;
  expect(n0, v.field);
  v.field++;
  expect(n1, v.field);
  v.field--;
  expect(n0, v.field);

  expect(n0, v.property);
  expect(n1, v.property += n1);
  expect(n2, v.property += n1);
  expect(n0, v.property -= n2);
  expect(n1, v.property += n1);
  expect(n0, v.property -= n1);
  expect(n1, ++v.property);
  expect(n0, --v.property);
  expect(n0, v.property++);
  expect(n1, v.property--);
  expect(n0, v.property);

  expect(n0, v.property);
  v.property += n1;
  expect(n1, v.property);
  v.property += n1;
  expect(n2, v.property);
  v.property -= n2;
  expect(n0, v.property);
  v.property += n1;
  expect(n1, v.property);
  v.property -= n1;
  expect(n0, v.property);
  ++v.property;
  expect(n1, v.property);
  --v.property;
  expect(n0, v.property);
  v.property++;
  expect(n1, v.property);
  v.property--;
  expect(n0, v.property);
}

testIntProperties() {
  int n0 = 0;
  int n1 = 1;
  int n2 = 2;
  IntClass v = new IntClass(n0);
  expect(n0, v.field);
  expect(n1, v.field += n1);
  expect(n2, v.field += n1);
  expect(n0, v.field -= n2);
  expect(n1, v.field += n1);
  expect(n0, v.field -= n1);
  expect(n1, ++v.field);
  expect(n0, --v.field);
  expect(n0, v.field++);
  expect(n1, v.field--);
  expect(n0, v.field);

  expect(n0, v.field);
  v.field += n1;
  expect(n1, v.field);
  v.field += n1;
  expect(n2, v.field);
  v.field -= n2;
  expect(n0, v.field);
  v.field += n1;
  expect(n1, v.field);
  v.field -= n1;
  expect(n0, v.field);
  ++v.field;
  expect(n1, v.field);
  --v.field;
  expect(n0, v.field);
  v.field++;
  expect(n1, v.field);
  v.field--;
  expect(n0, v.field);

  expect(n0, v.property);
  expect(n1, v.property += n1);
  expect(n2, v.property += n1);
  expect(n0, v.property -= n2);
  expect(n1, v.property += n1);
  expect(n0, v.property -= n1);
  expect(n1, ++v.property);
  expect(n0, --v.property);
  expect(n0, v.property++);
  expect(n1, v.property--);
  expect(n0, v.property);

  expect(n0, v.property);
  v.property += n1;
  expect(n1, v.property);
  v.property += n1;
  expect(n2, v.property);
  v.property -= n2;
  expect(n0, v.property);
  v.property += n1;
  expect(n1, v.property);
  v.property -= n1;
  expect(n0, v.property);
  ++v.property;
  expect(n1, v.property);
  --v.property;
  expect(n0, v.property);
  v.property++;
  expect(n1, v.property);
  v.property--;
  expect(n0, v.property);
}

testExplicitProperties() {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);
  Class v = new Class(n0);

  expect(n0, ClassExtension(v).property);
  expect(n1, ClassExtension(v).property += n1);
  expect(n2, ClassExtension(v).property += n1);
  expect(n0, ClassExtension(v).property -= n2);
  expect(n1, ClassExtension(v).property += n1);
  expect(n0, ClassExtension(v).property -= n1);
  expect(n1, ++ClassExtension(v).property);
  expect(n0, --ClassExtension(v).property);
  expect(n0, ClassExtension(v).property++);
  expect(n1, ClassExtension(v).property--);
  expect(n0, ClassExtension(v).property);

  expect(n0, ClassExtension(v).property);
  ClassExtension(v).property += n1;
  expect(n1, ClassExtension(v).property);
  ClassExtension(v).property += n1;
  expect(n2, ClassExtension(v).property);
  ClassExtension(v).property -= n2;
  expect(n0, ClassExtension(v).property);
  ClassExtension(v).property += n1;
  expect(n1, ClassExtension(v).property);
  ClassExtension(v).property -= n1;
  expect(n0, ClassExtension(v).property);
  ++ClassExtension(v).property;
  expect(n1, ClassExtension(v).property);
  --ClassExtension(v).property;
  expect(n0, ClassExtension(v).property);
  ClassExtension(v).property++;
  expect(n1, ClassExtension(v).property);
  ClassExtension(v).property--;
  expect(n0, ClassExtension(v).property);
}

testExplicitIntProperties() {
  int n0 = 0;
  int n1 = 1;
  int n2 = 2;
  IntClass v = new IntClass(n0);

  expect(n0, IntClassExtension(v).property);
  expect(n1, IntClassExtension(v).property += n1);
  expect(n2, IntClassExtension(v).property += n1);
  expect(n0, IntClassExtension(v).property -= n2);
  expect(n1, IntClassExtension(v).property += n1);
  expect(n0, IntClassExtension(v).property -= n1);
  expect(n1, ++IntClassExtension(v).property);
  expect(n0, --IntClassExtension(v).property);
  expect(n0, IntClassExtension(v).property++);
  expect(n1, IntClassExtension(v).property--);
  expect(n0, IntClassExtension(v).property);

  expect(n0, IntClassExtension(v).property);
  IntClassExtension(v).property += n1;
  expect(n1, IntClassExtension(v).property);
  IntClassExtension(v).property += n1;
  expect(n2, IntClassExtension(v).property);
  IntClassExtension(v).property -= n2;
  expect(n0, IntClassExtension(v).property);
  IntClassExtension(v).property += n1;
  expect(n1, IntClassExtension(v).property);
  IntClassExtension(v).property -= n1;
  expect(n0, IntClassExtension(v).property);
  ++IntClassExtension(v).property;
  expect(n1, IntClassExtension(v).property);
  --IntClassExtension(v).property;
  expect(n0, IntClassExtension(v).property);
  IntClassExtension(v).property++;
  expect(n1, IntClassExtension(v).property);
  IntClassExtension(v).property--;
  expect(n0, IntClassExtension(v).property);
}

testExplicitNullAwareProperties(Class v) {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);

  expect(n0, ClassExtension(v)?.property, v == null);
  expect(n1, ClassExtension(v)?.property += n1, v == null);
  expect(n2, ClassExtension(v)?.property += n1, v == null);
  expect(n0, ClassExtension(v)?.property -= n2, v == null);
  expect(n1, ClassExtension(v)?.property += n1, v == null);
  expect(n0, ClassExtension(v)?.property -= n1, v == null);
  expect(n1, ++ClassExtension(v)?.property, v == null);
  expect(n0, --ClassExtension(v)?.property, v == null);
  expect(n0, ClassExtension(v)?.property++, v == null);
  expect(n1, ClassExtension(v)?.property--, v == null);
  expect(n0, ClassExtension(v)?.property, v == null);

  expect(n0, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property += n1;
  expect(n1, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property += n1;
  expect(n2, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property -= n2;
  expect(n0, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property += n1;
  expect(n1, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property -= n1;
  expect(n0, ClassExtension(v)?.property, v == null);
  ++ClassExtension(v)?.property;
  expect(n1, ClassExtension(v)?.property, v == null);
  --ClassExtension(v)?.property;
  expect(n0, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property++;
  expect(n1, ClassExtension(v)?.property, v == null);
  ClassExtension(v)?.property--;
  expect(n0, ClassExtension(v)?.property, v == null);
}

testExplicitNullAwareIntProperties(IntClass v) {
  int n0 = 0;
  int n1 = 1;
  int n2 = 2;

  expect(n0, IntClassExtension(v)?.property, v == null);
  expect(n1, IntClassExtension(v)?.property += n1, v == null);
  expect(n2, IntClassExtension(v)?.property += n1, v == null);
  expect(n0, IntClassExtension(v)?.property -= n2, v == null);
  expect(n1, IntClassExtension(v)?.property += n1, v == null);
  expect(n0, IntClassExtension(v)?.property -= n1, v == null);
  expect(n1, ++IntClassExtension(v)?.property, v == null);
  expect(n0, --IntClassExtension(v)?.property, v == null);
  expect(n0, IntClassExtension(v)?.property++, v == null);
  expect(n1, IntClassExtension(v)?.property--, v == null);
  expect(n0, IntClassExtension(v)?.property, v == null);

  expect(n0, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property += n1;
  expect(n1, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property += n1;
  expect(n2, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property -= n2;
  expect(n0, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property += n1;
  expect(n1, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property -= n1;
  expect(n0, IntClassExtension(v)?.property, v == null);
  ++IntClassExtension(v)?.property;
  expect(n1, IntClassExtension(v)?.property, v == null);
  --IntClassExtension(v)?.property;
  expect(n0, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property++;
  expect(n1, IntClassExtension(v)?.property, v == null);
  IntClassExtension(v)?.property--;
  expect(n0, IntClassExtension(v)?.property, v == null);
}

expect(expected, actual, [expectNull = false]) {
  if (expectNull) {
    expected = null;
  }
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
