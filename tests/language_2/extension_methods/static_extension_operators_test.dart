// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that static extensions can be used for all operators.

void main() {
  Object a = "a";
  Object b = "b";
  Object c = "c";

  expect("(-a)", -a);
  expect("(~a)", ~a);
  expect("(a+b)", a + b);
  expect("(a-b)", a - b);
  expect("(a*b)", a * b);
  expect("(a/b)", a / b);
  expect("(a%b)", a % b);
  expect("(a~/b)", a ~/ b);
  expect("(a|b)", a | b);
  expect("(a&b)", a & b);
  expect("(a^b)", a ^ b);
  expect("(a<b)", a < b);
  expect("(a>b)", a > b);
  expect("(a<=b)", a <= b);
  expect("(a>=b)", a >= b);
  expect("(a<<b)", a << b);
  expect("(a>>b)", a >> b);
  // expect("(a>>>b)", a >>> b);
  expect("a(b)", a(b));
  expect("a(b,c)", a(b, c));
  expect("a[b]", a[b]);
  expect("c", a[b] = c, "a[b]=c");

  // Operator-assignment works and evaluates to its RHS value.
  expect("(a.field+b)", a.field += b, "a.field=(a.field+b)");
  expect("(a.field-b)", a.field -= b, "a.field=(a.field-b)");
  expect("(a.field*b)", a.field *= b, "a.field=(a.field*b)");
  expect("(a.field/b)", a.field /= b, "a.field=(a.field/b)");
  expect("(a.field%b)", a.field %= b, "a.field=(a.field%b)");
  expect("(a.field~/b)", a.field ~/= b, "a.field=(a.field~/b)");
  expect("(a.field|b)", a.field |= b, "a.field=(a.field|b)");
  expect("(a.field&b)", a.field &= b, "a.field=(a.field&b)");
  expect("(a.field^b)", a.field ^= b, "a.field=(a.field^b)");
  expect("(a.field<<b)", a.field <<= b, "a.field=(a.field<<b)");
  expect("(a.field>>b)", a.field >>= b, "a.field=(a.field>>b)");
  // expect("(a.field>>>b)", a.field >>>= b, "a.field=(a.field>>>b)");

  // Even on index operations.
  expect("(a[c]+b)", a[c] += b, "a[c]=(a[c]+b)");
  expect("(a[c]-b)", a[c] -= b, "a[c]=(a[c]-b)");
  expect("(a[c]*b)", a[c] *= b, "a[c]=(a[c]*b)");
  expect("(a[c]/b)", a[c] /= b, "a[c]=(a[c]/b)");
  expect("(a[c]%b)", a[c] %= b, "a[c]=(a[c]%b)");
  expect("(a[c]~/b)", a[c] ~/= b, "a[c]=(a[c]~/b)");
  expect("(a[c]|b)", a[c] |= b, "a[c]=(a[c]|b)");
  expect("(a[c]&b)", a[c] &= b, "a[c]=(a[c]&b)");
  expect("(a[c]^b)", a[c] ^= b, "a[c]=(a[c]^b)");
  expect("(a[c]<<b)", a[c] <<= b, "a[c]=(a[c]<<b)");
  expect("(a[c]>>b)", a[c] >>= b, "a[c]=(a[c]>>b)");
  // expect("(a[c]>>>b)", a[c] >>>= b, "a[c]=(a[c]>>>b)");

  // And ++/-- expands to their assignments.
  expect("(a.field+1)", ++a.field, "a.field=(a.field+1)");
  expect("(a.field-1)", --a.field, "a.field=(a.field-1)");
  expect("a.field", a.field++, "a.field=(a.field+1)");
  expect("a.field", a.field--, "a.field=(a.field-1)");
  expect("(a[b]+1)", ++a[b], "a[b]=(a[b]+1)");
  expect("(a[b]-1)", --a[b], "a[b]=(a[b]-1)");
  expect("a[b]", a[b]++, "a[b]=(a[b]+1)");
  expect("a[b]", a[b]--, "a[b]=(a[b]-1)");

  // Combinations.
  expect("(a+b[b(c)]((a*b)))", a + b[c[a] = b(c)](a * b), "c[a]=b(c)");

  // Operator precedence is unaffected by being extensions.
  expect("(c<((-a)|(b^((~c)&((a<<b)>>((c-a)+((((b*c)~/a)%b)/c)))))))",
      c < -a | b ^ ~c & a << b >> c - a + b * c ~/ a % b / c);
  expect("((((((((((((c/b)%a)~/c)*b)+a)-c)<<b)>>a)&(~c))^b)|(-a))>b)",
      c / b % a ~/ c * b + a - c << b >> a & ~c ^ b | -a > b);
}

// Last value set by []= or setter.
String setValue = "";

void expect(String expect, Object value, [String expectSet]) {
  Expect.equals(expect, value, "value");
  if (expectSet != null) Expect.equals(expectSet, setValue, "assignment");
}

extension Ops on Object {
  Object operator -() => "(-${this})";
  Object operator ~() => "(~${this})";
  Object operator +(Object other) => "(${this}+$other)";
  Object operator -(Object other) => "(${this}-$other)";
  Object operator *(Object other) => "(${this}*$other)";
  Object operator /(Object other) => "(${this}/$other)";
  Object operator %(Object other) => "(${this}%$other)";
  Object operator ~/(Object other) => "(${this}~/$other)";
  Object operator |(Object other) => "(${this}|$other)";
  Object operator &(Object other) => "(${this}&$other)";
  Object operator ^(Object other) => "(${this}^$other)";
  Object operator <(Object other) => "(${this}<$other)";
  Object operator >(Object other) => "(${this}>$other)";
  Object operator <=(Object other) => "(${this}<=$other)";
  Object operator >=(Object other) => "(${this}>=$other)";
  Object operator <<(Object other) => "(${this}<<$other)";
  Object operator >>(Object other) => "(${this}>>$other)";
  // TODO: enable `>>>` when it has been implemented.
  // String operator >>>(Object other) => "(${this}>>>$other)";

  // Cannot make an extension method for `==` because it's declared by Object.

  Object operator [](Object other) => "${this}[$other]";
  void operator []=(Object other, Object value) {
    setValue = "${this}[$other]=$value";
  }

  Object call([arg1, arg2]) =>
      "${this}(${[arg1, arg2].where((x) => x != null).join(",")})";

  Object get field => "${this}.field";
  void set field(Object other) {
    setValue = "${this}.field=$other";
  }
}
