// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for dart2js that used to miscompile boolean and operations
/// if one of the operands was an int and the other was not (issue 22427).
///
/// Extended to all operations as there is a risk of similar bugs with other
/// operators, e.g. `a % 2` _looks_ like it might be 0 or 1.

import "package:expect/expect.dart";

@AssumeDynamic()
@NoInline()
confuse(x) => x;

class Thing1 {
  operator &(b) => this;
  operator |(b) => this;
  operator ^(b) => this;
  operator <<(b) => this;
  operator >>(b) => this;

  operator +(b) => this;
  operator -(b) => this;
  operator *(b) => this;
  operator /(b) => this;
  operator ~/(b) => this;
  operator %(b) => this;
  remainder(b) => this;

  operator <(b) => this;
  operator <=(b) => this;
  operator >(b) => this;
  operator >=(b) => this;
}

class Thing2 {
  @NoInline()
  operator &(b) => this;
  @NoInline()
  operator |(b) => this;
  @NoInline()
  operator ^(b) => this;
  @NoInline()
  operator <<(b) => this;
  @NoInline()
  operator >>(b) => this;

  @NoInline()
  operator +(b) => this;
  @NoInline()
  operator -(b) => this;
  @NoInline()
  operator *(b) => this;
  @NoInline()
  operator /(b) => this;
  @NoInline()
  operator ~/(b) => this;
  @NoInline()
  operator %(b) => this;
  @NoInline()
  remainder(b) => this;

  @NoInline()
  operator <(b) => this;
  @NoInline()
  operator <=(b) => this;
  @NoInline()
  operator >(b) => this;
  @NoInline()
  operator >=(b) => this;
}

confused() {
  var a = new Thing1();
  Expect.equals(a, confuse(a) & 5 & 2);
  Expect.equals(a, confuse(a) | 5 | 2);
  Expect.equals(a, confuse(a) ^ 5 ^ 2);
  Expect.equals(a, confuse(a) << 5 << 2);
  Expect.equals(a, confuse(a) >> 5 >> 2);

  Expect.equals(a, confuse(a) + 5 + 2);
  Expect.equals(a, confuse(a) - 5 - 2);
  Expect.equals(a, confuse(a) * 5 * 2);
  Expect.equals(a, confuse(a) / 5 / 2);
  Expect.equals(a, confuse(a) % 5 % 2);
  Expect.equals(a, confuse(a) ~/ 5 ~/ 2);
  Expect.equals(a, confuse(a).remainder(5).remainder(2));

  Expect.equals(a, (confuse(a) < 5) < 2);
  Expect.equals(a, (confuse(a) <= 5) <= 2);
  Expect.equals(a, (confuse(a) > 5) > 2);
  Expect.equals(a, (confuse(a) >= 5) >= 2);
}

direct1() {
  var a = new Thing1();
  Expect.equals(a, a & 5 & 2);
  Expect.equals(a, a | 5 | 2);
  Expect.equals(a, a ^ 5 ^ 2);
  Expect.equals(a, a << 5 << 2);
  Expect.equals(a, a >> 5 >> 2);

  Expect.equals(a, a + 5 + 2);
  Expect.equals(a, a - 5 - 2);
  Expect.equals(a, a * 5 * 2);
  Expect.equals(a, a / 5 / 2);
  Expect.equals(a, a % 5 % 2);
  Expect.equals(a, a ~/ 5 ~/ 2);
  Expect.equals(a, a.remainder(5).remainder(2));

  Expect.equals(a, (a < 5) < 2);
  Expect.equals(a, (a <= 5) <= 2);
  Expect.equals(a, (a > 5) > 2);
  Expect.equals(a, (a >= 5) >= 2);
}

direct2() {
  var a = new Thing2();
  Expect.equals(a, a & 5 & 2);
  Expect.equals(a, a | 5 | 2);
  Expect.equals(a, a ^ 5 ^ 2);
  Expect.equals(a, a << 5 << 2);
  Expect.equals(a, a >> 5 >> 2);

  Expect.equals(a, a + 5 + 2);
  Expect.equals(a, a - 5 - 2);
  Expect.equals(a, a * 5 * 2);
  Expect.equals(a, a / 5 / 2);
  Expect.equals(a, a % 5 % 2);
  Expect.equals(a, a ~/ 5 ~/ 2);
  Expect.equals(a, a.remainder(5).remainder(2));

  Expect.equals(a, (a < 5) < 2);
  Expect.equals(a, (a <= 5) <= 2);
  Expect.equals(a, (a > 5) > 2);
  Expect.equals(a, (a >= 5) >= 2);
}

main() {
  confused();
  direct1();
  direct2();
}
