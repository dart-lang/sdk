// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test file for testing source mappings of operations.

var counter = 0;

void record(result) {
  counter++;
}

main(args) {
  counter++;
  operations(args.length > 0, 0, 1.5, args[0], new Complex(0, 1),
      new Complex(1.5, 2.5));
  specialized(args.length > 0, null, 2, []);
  specialized(args.length > 0, 2, 2, []);
  return counter;
}

void operations(cond, a, b, c, d, e) {
  if (cond) record(a + a);
  if (cond) record(a + b);
  if (cond) record(a + c);
  if (cond) record(a + d);
  if (cond) record(a + e);
  if (cond) record(b + a);
  if (cond) record(b + b);
  if (cond) record(b + c);
  if (cond) record(b + d);
  if (cond) record(b + e);
  if (cond) record(c + a);
  if (cond) record(c + b);
  if (cond) record(c + c);
  if (cond) record(c + d);
  if (cond) record(c + e);
  if (cond) record(d + a);
  if (cond) record(d + b);
  if (cond) record(d + c);
  if (cond) record(d + d);
  if (cond) record(d + e);
  if (cond) record(e + a);
  if (cond) record(e + b);
  if (cond) record(e + c);
  if (cond) record(e + d);
  if (cond) record(e + e);
}

void specialized(cond, a, b, c) {
  if (cond) record(a + b);
  if (cond) record(a & b);
  if (cond) record(~a);
  if (cond) record(a | b);
  if (cond) record(a ^ b);
  if (cond) record(a / b);
  if (cond) record(a == b);
  if (cond) record(a >= b);
  if (cond) record(a > b);
  if (cond) record(a <= b);
  if (cond) record(a < b);
  if (cond) record(a % b);
  if (cond) record(a * b);
  if (cond) record(a << b);
  if (cond) record(a >> b);
  if (cond) record(a - b);
  if (cond) record(a ~/ b);
  if (cond) record(-a);

  if (cond) record(c[a] = b);
  if (cond) record(c[a]);
}

class Complex {
  final num re;
  final num im;

  const Complex(this.re, this.im);

  operator +(Complex other) => new Complex(re + other.re, im + other.im);

  // TODO(johnniwinther): Support implicit null check in '=='.
  //operator ==(Complex other) => re == other.re && im == other.im;

  int get hashCode => 13 * re.hashCode + 17 * im.hashCode;
}
