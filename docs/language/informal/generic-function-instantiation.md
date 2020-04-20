# Generic Function Instantiation

**Author**: eernst@.

**Version**: 0.3 (2018-04-05)

**Status**: This document is now background material.
For normative text, please consult the language specification.

**This document** is a Dart 2 feature specification of _generic function
instantiation_, which is the feature that implicitly coerces a reference to
a generic function into a non-generic function obtained from said generic
function by passing inferred type arguments.

Intuitively, this is the feature that provides inference for function
values, corresponding to the more well-known inference that we may get for
each invocation of a generic function:

```dart
List<T> f<T>(T t) => [t];

void g(Iterable<int> f(int i)) => print(f(42));

main() {
  // Invocation inference.
  print(f(42)); // Inferred as `f<int>(42)`.

  // Function value inference.
  g(f); // Inferred approximately as `g((int n) => f<int>(n))`.
}
```

This document draws on many of the comments on the SDK issue
[#31665](https://github.com/dart-lang/sdk/issues/31665).


## Motivation

The
[language specification](https://github.com/dart-lang/sdk/blob/master/docs/language/dartLangSpec.tex)
uses the phrase _function object_ to denote the first-class semantic
entity which corresponds to a function declaration. In the following
example, each of the expressions `fg`, `A.fs`, `new A().fi`, and `fl` in
`main` evaluate to a function object, and so does the function literal at
the end of the list:

```dart
int fg(int i) => i;

class A {
  static int fs(int i) => i;
  int fi(int i) => i;
}

main() {
  int fl(int i) => i;
  var functions =
      [fg, A.fs, new A().fi, fl, (int i) => i];
}
```

Once a function object has been obtained, it can be passed around by
assigning it to a variable, passing it as an actual argument, etc. Hence,
it is the notion of a function object that makes functions first-class
entities. The computational step that produces a function object from a
denotation of a function declaration is known as _closurization_.

The situation where closurization occurs is exactly the situation where the
generic function instantiation feature specified in this document may kick
in.

First note that generic function declarations provide support for working
with generic functions as first class values, i.e., generic functions
support regular closurization, just like non-generic functions.

The essence of generic function instantiation is to allow for "curried"
invocations, in the sense that a generic function can receive its actual
type arguments separately during closurization (it must then receive _all_
its type arguments, not just some of them), and that yields a non-generic
function whose type is obtained by substituting type variables in the
generic type for the actual type arguments:

```dart
X fg<X extends num>(X x) => x;

class A {
  static X fs<X extends num>(X x) => x;
  X fi<X extends num>(X x) => x;
}

main() {
  X fl<X extends num>(X x) => x;
  var genericFunctions =
      <Function>[fg, A.fs, new A().fi, fl, <X>(X x) => x];
  var instantiatedFunctions =
      <int Function(int)>[fg, A.fs, new A().fi, fl];
}
```

The functions stored in `instantiatedFunctions` are all of type
`int Function(int)`, and they are obtained by passing the actual
type argument `int` to the denoted generic function, thus obtaining
a non-generic function of the specified type. Hence, the reason why
`instantiatedFunctions` can be created as shown is that it relies on
generic function instantiation, for each element in the list.

Note that generic function instantiation is not supported with all kinds of
generic functions; this is discussed in the discussion section.

It may seem natural to allow explicit instantiations, e.g., `fg<int>` and
`new A().fi<int>` (where type arguments are passed explicitly, but there is
no value argument list). This kind of construct would yield non-generic
functions, just like the cases shown above where the type arguments are
inferred. This is a language extension which is not included in this
document. It may or may not be added to the language separately.


## Syntax

This feature does not affect the grammar.

*If this feature is generalized to include explicit generic
function instantiation, the grammar would need to be extended
to allow a construct like `f<int>` as an expression.*


## Static Analysis and Program Transformation

We say that a reference of the form `identifier`,
`identifier '.' identifier`, or
`identifier '.' identifier '.' identifier`
is a _statically resolved reference to a function_ if it denotes a
declaration of a library function or a static function.

*Such a reference is first-order in the sense that it is bound directly to
the function declaration and there need not be a heap object which
represents said function declaration in order to support invocations of the
function. In that sense we may consider statically resolved references
"extra simple", compared to general references to functions. In particular,
a statically resolved reference to a function will have a static type which
is obtained directly from its declaration, it will never be a supertype
thereof such as `Function` or `dynamic`.*

When an expression _e_ whose static type is a generic function type _G_ is
used in a context where the expected type is a non-generic function type
_F_, it is a compile-time error except in the three situations specified
below.

*The point is that generic function instantiation will only take place in
situations where we would have a compile-time error without that feature,
and in those situations the compile-time error will still exist unless the
situation matches one of those three exceptions.*

**1st exception**: If _e_ is a statically resolved reference to a function,
and type inference yields an actual type argument list
_T<sub>1</sub> .. T<sub>k</sub>_ such that
_G<T<sub>1</sub> .. T<sub>k</sub>>_ is assignable to _F_, then the program
is modified such that _e_ is replaced by a reference to a non-generic
function whose signature is obtained by substituting
_T<sub>1</sub> .. T<sub>k</sub>_ for the formal type parameters in the
function signature of the function denoted by _e_, and whose semantics for
each invocation is the same as invoking _e_ with
_T<sub>1</sub> .. T<sub>k</sub>_ as the actual type argument list.

*Here is an example:*

```dart
List<T> foo<T>(T t) => [t];
List<int> fooOfInt(int i) => [i];

String bar(List<int> f(int)) => "${f(42)}";

main() {
  print(bar(foo));
}
```

*In this example, `foo` as an actual argument to `bar` will be modified as
if the call had been `bar(fooOfInt)`, except for equality&mdash;which is
specified next.*

Consider two distinct evaluations of a statically resolved reference to the
same generic function, which are subject to the above-mentioned
transformation with the same actual type argument list, and let `f1` and
`f2` denote the two functions obtained after the transformation. It is then
guaranteed that `f1 == f2` evaluates to true, but `identical(f1, f2)` can
be false or true, depending on the implementation.

**2nd exception**: Generic function instantiation is supported for instance
methods as well as statically resolved functions: If

- _e_ is a property extraction which denotes a closurization,
- the static type of _e_ is a generic function type _G_,
- _e_ occurs in a context where the expected type is a non-generic
  function type _F_, and
- type inference yields an actual type argument list
  _T<sub>1</sub> .. T<sub>k</sub>_ such that
  _G<T<sub>1</sub> .. T<sub>k</sub>>_ is assignable to _F_

then the program is modified such that _e_ is replaced by a reference to a
non-generic function whose signature is obtained by substituting
_T<sub>1</sub> .. T<sub>k</sub>_ for
the formal type parameters in the signature of the method denoted by
_e_, and whose semantics for each invocation is the same as
invoking that method on that receiver with
_T<sub>1</sub> .. T<sub>k</sub>_ as the actual type argument list.

*Note that the statically known declaration of the method which is
closurized may not be the same one as the declaration of the method which
is actually closurized at run time, but it is guaranteed that the actual
signature will have a formal type parameter list with the same length,
where each formal type parameter will have the same bound as the statically
known one, and the value parameters will have types which are in a correct
override relationship to the statically known ones. In other words, the
function obtained by generic function instantiation on an instance method
may accept a different number of parameters, with type annotations that are
different than the statically known ones, but the corresponding function
type will be a subtype of the statically known one, i.e., it can be called
safely. (It is possible that the method which is actually closurized has
one or more formal parameters which are covariant, and this may cause an
otherwise statically safe invocation to fail at run-time, but this is
exactly the same situation as we would have had with a direct invocation of
the method.)*

Consider two distinct evaluations of a property extraction for the same method
of receivers `o1` and `o2`, which are subject to the above-mentioned
transformation with the same actual type argument list, and let `f1` and
`f2` denote the two functions obtained after the transformation. It is then
guaranteed that `f1 == f2` evaluates to the same value as `identical(o1, o2)`,
but `identical(f1, f2)` can be false or true, depending on the implementation.

*Here is an example:*

```dart
class A {
  List<T> foo<T>(T t) => [t];
}

String bar(List<int> f(int)) => "${f(42)}";

main() {
  print(bar(new A().foo));
}
```

*In this example, `new A().foo` as an actual argument to `bar` will be
modified as if the call had been `bar((int i) => o.foo<int>(i))` where `o`
is a fresh variable bound to the result of evaluating `new A()`, except for
equality.*

**3rd exception**: Generic function instantiation is supported also for
local functions: If

- _e_ is an `identifier` denoting a local function,
- the static type of _e_ is a generic function type _G_,
- _e_ occurs in a context where the expected type is a non-generic
  function type _F_, and
- type inference yields an actual type argument list
  _T<sub>1</sub> .. T<sub>k</sub>_ such that
  _G<T<sub>1</sub> .. T<sub>k</sub>>_ is assignable to _F_

then the program is modified such that _e_ is replaced by a reference to a
non-generic function whose signature is obtained by substituting
_T<sub>1</sub> .. T<sub>k</sub>_ for
the formal type parameters in the signature of the function denoted by _e_,
and whose semantics for each invocation is the same as invoking that
function on that receiver with _T<sub>1</sub> .. T<sub>k</sub>_ as the
actual type argument list.

*No special guarantees are provided regarding the equality and identity
properties of the non-generic functions obtained from a local function.*

If _e_ is an expression which is subject to generic function instantiation
as specified above, and the function denoted by _e_ is a top-level function
or a static method that is not qualified by a deferred prefix, and the
inferred type arguments are all compile-time constant type expressions
(*cf. [this CL](https://dart-review.googlesource.com/c/sdk/+/36220)*), then
_e_ is a constant expression. Other than that, an expression subject to
generic function instantiation is not constant.


## Dynamic Semantics

The dynamic semantics of this feature follows directly from the fact that
the section on static analysis specifies which expressions are subject to
generic function instantiation, and how to obtain the non-generic function
which is the value of such an expression.

There is one exception: It is possible for inference to provide a type
argument which is not statically guaranteed to satisfy the declared upper
bound. In that case, a dynamic error occurs when the generic function
instantiation takes place.

*Here is an example to illustrate how this may occur:*

```dart
class C<X> {
  X x;
  void foo<Y extends X>(Y y) => x = y;
}

C<num> complexComputation() => new C<int>();

main() {
  C<num> c = complexComputation();
  void Function(num) f = c.foo; // Inferred type argument: `num`.
}
```

*In this situation, the inferred type argument `num` is not guaranteed to
satisfy the declared upper bound of `Y`, because the actual type argument
of `c`, let us call it `T`, is only known to be some subtype of `num`.
There is no way to denote the type `T` or any other type (except `Null`)
which is guaranteed to be a subtype of `T`. Hence, the chosen type argument
may turn out to violate the bound at run time, and that violation must be
detected when the tear-off takes place, rather than letting the tear-off
succeed and incurring a dynamic error at each invocation of the resulting
function object.*


## Discussion

There is no support for generic function instantiation with function
literals. That is hardly a serious omission, however, because a function
literal is only referred from one single location (the place where it
occurs), and hence there is never a need to use such a function both as a
generic and as a non-generic function, so it is extremely likely to be
simpler and more convenient to write the function literal as a non-generic
function in the first place, if that is how it will be used.

```dart
class A<X> {
  X x;

  A(this.x);

  void f(List<X> Function(X) g) => print(g(x));

  void bar() {
    // Error: Needs generic function instantiation,
    // which would implicitly pass `<X>`.
    f(<Y>(Y y) => [y]);

    // Work-around: Just use a non-generic function---it can get
    // the required different types for different values of `X` by
    // using `X` directly.
    f((X x) => [x]);
  }
}

main() {
  new A<int>(42).bar();
}
```

Finally, there is no support for generic function instantiation with first
class functions (e.g., the value of a variable or an actual argument). This
choice was made in order to avoid the complexity and performance
implications of having such a feature.  Note that, apart from the `==`
property, it is always possible to write a function literal in order to
pass actual type arguments explicitly, thus getting the same effect:

```dart
List<T> foo<T>(T t) => [t];

void g(List<int> Function(int) h) => print(h(42)[0].isEven);

void bar(List<T> Function<T>(T) f) {
  g(f); // Error: Generic function instantiation not supported here.
  // Work-around.
  g((int i) => f(i));
}

main() {
  bar(foo); // No generic function instantiation needed here.
}
```


## Revisions

- 0.3 (2018-04-05) Clarified constancy of expressions subject to generic
  function instantiation.

- 0.2 (2018-03-21) Adjusted to include support for generic function
  instantiation also for local functions.

- 0.1 (2018-03-19) Initial version.
