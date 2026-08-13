// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Complex {
  final double real;
  final double imaginary;

  const Complex(this.real, this.imaginary);

  Complex add(Complex other) {
    return new Complex(real + other.real, imaginary + other.imaginary);
  }

  Complex sub(Complex other) {
    return new Complex(real - other.real, imaginary - other.imaginary);
  }

  Complex negate() {
    return new Complex(-real, -imaginary);
  }

  int get hashCode => real.hashCode * 13 + imaginary.hashCode * 19;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Complex &&
        real == other.real &&
        imaginary == other.imaginary;
  }

  String toString() => 'Complex($real,$imaginary)';
}

extension Operators on Complex {
  Complex operator +(Complex other) => add(other);
  Complex operator -(Complex other) => sub(other);
  Complex operator -() => negate();
}

main() {
  implicit();
  explicit();
}

implicit() {
  Complex c_m2 = new Complex(-2, 2);
  Complex c_m1 = new Complex(-1, 1);
  Complex c0 = new Complex(0, 0);
  Complex c1 = new Complex(1, -1);
  Complex c2 = new Complex(2, -2);

  expect(c_m2, c0 + c_m2);
  expect(c_m2, c_m2 + c0);
  expect(c_m2, c_m1 + c_m1);
  expect(c_m1, c0 + c_m1);
  expect(c_m1, c_m1 + c0);
  expect(c0, c_m2 + c2);
  expect(c0, c2 + c_m2);
  expect(c0, c_m1 + c1);
  expect(c0, c1 + c_m1);
  expect(c0, c0 + c0);
  expect(c1, c0 + c1);
  expect(c1, c1 + c0);
  expect(c2, c0 + c2);
  expect(c2, c2 + c0);
  expect(c2, c1 + c1);

  expect(c_m2, c0 - c2);
  expect(c2, c2 - c0);
  expect(c_m2, -c2);
  expect(c_m1, c1 - c2);
  expect(c1, c2 - c1);
  expect(c_m1, c0 - c1);
  expect(c1, c1 - c0);
  expect(c_m1, -c1);
  expect(c0, c2 - c2);
  expect(c0, c1 - c1);
  expect(c0, c0 - c0);
  expect(c0, c_m1 - c_m1);
  expect(c0, c_m2 - c_m2);
  expect(c0, -c0);
}

explicit() {
  Complex c_m2 = new Complex(-2, 2);
  Complex c_m1 = new Complex(-1, 1);
  Complex c0 = new Complex(0, 0);
  Complex c1 = new Complex(1, -1);
  Complex c2 = new Complex(2, -2);

  expect(c_m2, Operators(c0) + c_m2);
  expect(c_m2, Operators(c_m2) + c0);
  expect(c_m2, Operators(c_m1) + c_m1);
  expect(c_m1, Operators(c0) + c_m1);
  expect(c_m1, Operators(c_m1) + c0);
  expect(c0, Operators(c_m2) + c2);
  expect(c0, Operators(c2) + c_m2);
  expect(c0, Operators(c_m1) + c1);
  expect(c0, Operators(c1) + c_m1);
  expect(c0, Operators(c0) + c0);
  expect(c1, Operators(c0) + c1);
  expect(c1, Operators(c1) + c0);
  expect(c2, Operators(c0) + c2);
  expect(c2, Operators(c2) + c0);
  expect(c2, Operators(c1) + c1);

  expect(c_m2, Operators(c0) - c2);
  expect(c2, Operators(c2) - c0);
  expect(c_m2, -Operators(c2));
  expect(c_m1, Operators(c1) - c2);
  expect(c1, Operators(c2) - c1);
  expect(c_m1, Operators(c0) - c1);
  expect(c1, Operators(c1) - c0);
  expect(c_m1, -Operators(c1));
  expect(c0, Operators(c2) - c2);
  expect(c0, Operators(c1) - c1);
  expect(c0, Operators(c0) - c0);
  expect(c0, Operators(c_m1) - c_m1);
  expect(c0, Operators(c_m2) - c_m2);
  expect(c0, -c0);
}

void errors(Complex c) {
  Operators(c) == c;
  Operators(c) != c;
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
