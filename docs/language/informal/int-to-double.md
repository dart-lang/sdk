## Feature: Evaluating integer literals as double values

**Author**: eernst@.

**Version**: 0.5 (2018-09-12).

**Status**: Background material, in language specification as of
[d14b256](https://github.com/dart-lang/sdk/commit/d14b256e351464db352f361f1206e1415db65d9c).

**This document** is a feature specification of the support in Dart 2 for
evaluating integer literals occurring in a context where the expected type
is `double` to a value of type `double`.


## Motivation

In a situation where a value of type `double` is required, e.g., as an
actual argument to a constructor or function invocation, it may be
convenient to write an integer literal because it is more concise, and
the intention is clear. For instance:

```dart
double one = 1; // OK, would have to be `1.0` without this feature.
```

This mechanism only applies to integer literals, and only when the expected
type is a type `T` such that `double` is assignable to `T` and `int` is not
assignable to `T`; in particular, it applies when the expected type is
`double`.

That is, the result of a computation (say, `a + b` or even a lone variable
like `a` of type `int`) will never be converted to a double value
implicitly, and it also doesn't happen when the expected type is a type
variable declared in an enclosing scope, no matter whether that type
variable in a given situation at run time has the value `double`. The one
case where conversion does happen when the expected type is a type variable
is when its upper bound is a subtype of `double` (including `double`
itself). For example:

```dart
class C<N extends num, NN extends double> {
  X foo<X>(X x) => x;
  double d1 = foo<double>(42); // OK.
  double d2 = foo(42); // OK, type argument inferred as `double`.
  num n1 = 42 as double; // OK, `42` evaluates to 42.0.
  N n2 = 42; // Error, neither `int` nor `double` assignable to `N`.
  NN n3 = 42; // OK, `int` not assignable, but `double` is.
  FutureOr<double> n4 = 42; // OK, same reason.
  N n5 = n1; // OK statically, dynamic error if `N` is `int`.
}
```


## Syntax

This feature has no effect on the grammar.


## Static Analysis

Let _i_ be a lexical token which is syntactically an _integer literal_ (as
defined in the language specification section 16.3 Numbers). If _i_ occurs
as an expression in a context where the expected type `T` is such that
`double` is assignable to `T` and `int` is not assignable to `T` then we
will say that _i_ is a _double valued integer literal_.

The static type of a double valued integer literal is `double`.

The _unbounded integer value_ of an integer literal _i_ is the mathematical
integer (that is, unlimited in size and precision) that corresponds to the
numeral consisting of the digits of _i_, using radix 16 when _i_ is prefixed
by `0x` or `0X`, and radix 10 otherwise.

It is a compile-time error if the unbounded integer value of a double
valued integer literal is less than
-(1−2<sup>−53</sup>) * 2<sup>1024</sup>
and if it is greater
than (1−2<sup>−53</sup>) * 2<sup>1024</sup>.

It is a compile-time error if the unbounded integer value of a double
valued integer literal cannot be represented exactly as an IEEE 754
double-precision value, assuming that the mantissa is extended with zeros
until the precision is sufficiently high to unambiguously specify a single
integer value.

*That is, we consider a IEEE 754 double-precision bit pattern to represent
a specific number rather than an interval, namely the number which is
obtained by extending the mantissa with zeros. In this case we are only
interested in such bit patterns where the exponent part is large enough to
make the represented number a whole number, which means that we will need
to add a specific, finite number of zeros.*

*Consequently,
`double d = 18446744073709551616;`
has no error and it will initialize `d` to have the double value
represented as 0x43F0000000000000. But
`int i = 18446744073709551616;`
is a compile-time error because 18446744073709551616 is too large to be
represented as a 64-bit 2's complement number, and
`double d = 18446744073709551615;`
is a compile-time error because it cannot be represented exactly using the
IEEE 754 double-precision format.*


## Dynamic Semantics

At run time, evaluation of a double valued integer literal _i_ yields a
value of type `double` which according to the IEEE 754 standard for
double-precision numbers represents the unbounded integer value of _i_.

Signed zeros in IEEE 754 present an ambiguity. It is resolved by
evaluating an expression which is a unary minus applied to a double valued
integer literal whose unbounded integer value is zero to the IEEE 754
representation of `-0.0`, and other occurrences of a double valued integer
literal whose unbounded integer value is zero to the representation of
`0.0`.

*We need not specify that the representation is extended with zeros as
needed, because there is in any case only one IEEE 754 double-precision bit
pattern that can be said to represent the given unbounded integer value: It
would belong to the interval under any meaningful interpretation of such a
bit pattern as an interval.*


## Discussion

We have chosen to make it an error when a double valued integer literal
cannot be represented exactly by an IEEE 754 double-precision encoding. We
could have chosen to allow for a certain deviation from that, such that it
would be allowed to have a double valued integer literal whose unbounded
integer value would differ "somewhat" from the nearest representable value.

However, we felt that it would be misleading for developers to read a large
double valued integer literal, probably assuming that every digit is
contributing to the resulting double value, if in fact many of the digits
are ignored, in the sense that they must be replaced by different digits in
order to express the nearest representable IEEE double-precision value.

For instance,
11692013098647223344361828061502034755750757138432 is represented as
0x4A20000000000000, but so is
11692013098647223344638182605120307455757075314823, which means that
the 29 least significant digits are replaced by completely different
digits. The former corresponds to an extension of the IEEE representation
with a suitable number of zeros in the mantissa which will translate back
to exactly that number, and the latter is just some other number which is
close enough to have the same IEEE representation as the nearest
representable value.

We expect such large double valued integer literals to occur very rarely,
which means that such a situation will not arise very frequently. However,
when it does arise it may be quite frustrating for developers to find a
representable number, assuming that they start out with something like
11692013098647223344638182605120307455757075314823. It is hence recommended
that tools emit an error message where the nearest representable value is
mentioned, such that a developer may copy it into the code in order to
eliminate the error.

Another alternative would be to accept only those double valued integer
literals whose unbounded integer value can be represented as a 2's
complement bit pattern in 64 bits or in an unsigned 64 bit representation,
that is, only those which are also accepted as integer literals of type
`int`.  This would ensure that developers avoid the situation where a large
number of digits are incorrectly taken to imply a very high precision.
This is especially relevant with decimal double valued integer literals,
because they do not end in a large number of zeros, which make them "look"
like a high-precision number where every digit means something. However, we
felt that this reduction of the expressive power brings so few benefits
that we preferred the approach where also "large numbers" could be
expressed using a double valued integer literal.


## Updates
*   Version 0.5 (2018-09-12), Fix typo

*   Version 0.4 (2018-08-14), adjusted rules to allow more expected types,
    such as `FutureOr<double>`, for double valued integer literals.

*   Version 0.3 (2018-08-09), changed error rules such that it is now an
    error for a double valued integer literal to have an unbounded
    integer value which is not precisely representable.

*   Version 0.2 (2018-08-08), added short discussion section.

*   Version 0.1 (2018-08-07), initial version of this feature specification.
