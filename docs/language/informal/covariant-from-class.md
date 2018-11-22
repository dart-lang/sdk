# Informal Specification: Parameters that are Covariant due to Class Type Parameters

**Owner**: eernst@

**Status**: This document is now background material.
For normative text, please consult the language specification.

**Version**: 0.6 (2018-06-01)


## Summary

This document is an informal specification which specifies how to determine
the reified type of a tear-off where one or more parameters has a type
annotation in which a formal type parameter of the enclosing class occurs
in a covariant position. This feature has no effect in Dart 1, it is only
concerned with Dart 2.


## Motivation

The main topic here is variance, so we will briefly introduce that concept.

Consider the situation where a type is specified as an expression that
contains another type as a subexpression. For instance, `List<int>`
contains `int` as a subexpression. We may then consider `List<...>` as a
function, and `int` as an argument which is passed to that function. With
that, covariance is the property that this function is increasing, and
contravariance is the property that it is decreasing, using the subtype
relation for comparisons.

Generic classes in Dart are covariant in all their arguments. For example
`List<E>` is covariant in `E`. This then means that `List<...>` is an
increasing function, i.e., whenever `S` is a subtype of `T`, `List<S>`
is a subtype of `List<T>`.

The subtype rule for function types in Dart 1 is different from the one in
strong mode and in the upcoming Dart 2. This difference is the main fact
that motivates the feature described in this document.

Concretely, the subtype rule for function types allows for covariant return
types in all cases. For instance, assuming that two functions `f` and `g`
have identical parameter types, the type of `f` will always be a subtype of
the type of `g` if `f` returns `int` and `g` returns `num`.

This is not true for parameter types. In Dart 1, the function type subtype
rule allows for covariant parameter types as well as contravariant ones,
but strong mode and the upcoming Dart 2 require contravariance for
parameter types. For instance, we have the following cases (using `void`
for the return type, because the return type is uninteresting, it should
just be the same everywhere):

```dart
typedef void F(num n);

void f1(Object o) {}
void f2(num n) {}
void f3(int i) {}

main() {
  F myF;
  myF = f1;  // Contravariance: Succeeds in Dart 1, and in strong mode.
  myF = f2;  // Same type: Always succeeds.
  myF = f3;  // Covariance: Succeeds in Dart 1, but fails in strong mode.
}
```

In all cases, the variance is concerned with the relationship between the
type of the parameter for `myF` and the type of the parameter for the
function which is assigned to `myF`. Since Dart 1 subtyping makes both `f1`
and `f3` subtypes of the type of `myF`, all assignments succeed at run time
(and static analysis proceeds without warnings). In strong mode and Dart 2,
`f3` does not have a subtype of the type of `myF`, so this is considered as
a downcast at compile time, and it fails at runtime.

Contravariance is the sound rule that most languages use, so this means
that function calls in strong mode and in Dart 2 are subject to more tight
type checking, and some run-time errors cannot occur.

However, covariant parameter types can be quite natural and convenient,
they just impose an obligation on developers to use ad-hoc reasoning in
order to avoid the potential type errors at run time. The
[covariant overrides](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/covariant-overrides.md)
feature was added exactly for this purpose: When developers want to use
unsound covariance, they can get it by requesting it explicitly. In the
(vast majority of) cases where the sound and more strict contravariant rule
fits the intended design, there will be no such request, and parameter type
covariance (which would then presumably only arise by mistake) will be
flagged as a type error.

In order to preserve a fundamental soundness property of Dart, the reified
type of tear-offs of methods has parameter type `Object` for every
parameter whose type is covariant. The desired property is that every
expression with static type `T` must evaluate to a value whose dynamic type
`S` which is a subtype of `T`. Here is an example why it would not work to
reify the declared parameter type directly:

```dart
// Going by the OLD RULES, showing why we need to introduce new ones.

typedef void F(num n);

class A {
  // The reified parameter type is `num`, directly as declared.
  void f(covariant num n) {}
}

class B extends A {
  // The reified parameter type is `int`, directly as declared.
  void f(int i) {}
}

main() {
  A a = new B();
  F myF = a.f; // Statically safe, yet fails at run time!
}
```

The problem is that `a.f` has static type `void Function(num)`, and if the
reified type at run time is `void Function(int)` then `a.f` is an expression
whose value at run time does _not_ conform to the statically known type.

Even worse, there is no statically known type annotation that we can use in
the declaration of `myF` which will make it safe&mdash;the value of `a`
could be an instance of some other class `C` where the parameter type is
`double`, and in general we cannot statically specify a function type where
the parameter type is a subtype of the actual parameter type at runtime (as
required for the initialization to succeed).

*We could use the bottom type as the argument type, `void Function(Null)`, but
that makes all invocations unsafe (except `myF(null)`). We believe that it is
more useful to preserve the information that "it must be some kind of number",
even though not all kinds of numbers will work. With `Null`, we just communicate
that all invocations are unsafe, with no hints at all about which ones would be
less unsafe than others.*

We do not want any such expressions where the value is not a subtype of the
statically known type, and hence the reified type of `a.f` is `void
Function(Object)`. In general, the type of each covariant parameter is reified
as `Object`. In the example, this is how it works:

```dart
typedef void F(num n);

class A {
  // The reified parameter type is `Object` because `n` is covariant.
  void f(covariant num n) {}
}

class B extends A {
  // The reified parameter type is `Object` because `i` is covariant.
  void f(int i) {}
}

main() {
  A a = new B();
  F myF = a.f; // Statically safe, and succeeds at runtime.
}
```

*Note that an invocation of `myF` can be statically safe and yet fail at
runtime, e.g., `myF(3.1)`, but this is exactly the same situation as with
the torn-off method: `a.f(3.1)` is also considered statically safe, and yet
it will fail at runtime.*

The purpose of this document is to cover one extra type of situation where
the same typing situation arises.

Parameters can have a covariant type because they are or contain a formal
type parameter of an enclosing generic class. Here is an example using the
core class `List` (which underscores that it is a common phenomenon, but
any generic class would do). It illustrates why we need to change the
reified type of tear-offs also with parameters that are covariant due to
class covariance:

```dart
// Going by the OLD RULES, showing why we need to introduce new ones.

// Here is the small part of the core List class that we need here.
abstract class List<E> ... {
  // The reified type is `void Function(E)` in all modes, as declared.
  void add(E value);
  // The reified type is `void Function(Iterable<E>)` in all modes, as declared.
  void addAll(Iterable<E> iterable);
  ...
}

typedef void F(num n);
typedef void G(Iterable<num> n);

main() {
  List<num> xs = <int>[1, 2];
  F myF = xs.add;    // Statically safe, yet fails at run time
                     // in strong mode and Dart 2.
  G myG = xs.addAll; // Same situation as with myF.
}
```

The example illustrates that the exact same typing situation arises in the
following two cases:

- A covariant parameter type is induced by an overriding method declaration
  (example: `int i` in `B.f`).
- A covariant parameter type is induced by the use of a formal type
  parameter of the enclosing generic class in a covariant position in the
  parameter type declaration (example: `E value` and `Iterable<E> iterable`
  in `List.add` resp. `List.addAll`).

This document specifies how to preserve the above mentioned expression
soundness property of Dart, based on a modified rule for how to reify
parameter types of tear-offs. Here is how it works with the new rules
specified in this document:

```dart
abstract class List<E> ... {
  // The reified type is `void Function(Object)` in all modes.
  void add(E value);
  // The reified type is `void Function(Object)` in all modes.
  void addAll(Iterable<E> iterable);
  ...
}

typedef void F(num n);
typedef void G(Iterable<num> n);

main() {
  List<num> xs = <int>[1, 2];
  F myF = xs.add;    // Statically safe, and succeeds at run time.
  G myG = xs.addAll; // Same situation as with myF.
}
```


## Feature specification


### Syntax

The grammar remains unchanged.


#### Static analysis

The static type of a property extraction remains unchanged.

*The static type of a torn-off method is taken directly from the statically
known declaration of that method, substituting actual type arguments for
formal type parameters as usual. For instance, the static type of
`xs.addAll` is `void Function (Iterable<num>)` when the static type of `xs` is
`List<num>`. Note that this is significant because the reified types of some
torn-off methods will indeed change with the introduction of this feature.*

When we say that a parameter is **covariant by modifier**, we are referring
to the definition of being a covariant parameter which is given in
[covariant overrides](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/covariant-overrides.md).

*When a parameter _p_ is covariant by modifier, there will necessarily be a
declaration of a formal parameter _p1_ (which may be the same as _p_, or it
may be different) which contains the built-in identifier `covariant`.*

*We need to introduce a new kind of covariant parameters, in addition to the
ones that are covariant by modifier. To do that, we also need to refer to
the variance of each occurrence of a type variable in a type, which is
specified in the language specification.*

Consider a class _T_ which is generic or has a generic supertype (directly
or indirectly). Let _S_ be said generic class. Assume that there is a
declaration of a method, setter, or operator `m` in _S_, that `X` is a
formal type parameter declared by _S_, and that said declaration of `m` has
a formal parameter `x` wherein `X` occurs covariantly or invariantly. In
this situation we say that the parameter `x` is **covariant by class
covariance**.

*This means that the type annotation of the given parameter may actually be
covariant in the relevant type parameter, or it may vary among types that
have no subtype relationship to each other. The parameter will be called
'covariant' in both cases, because the situation where it is actually
covariant is expected to be much more common than the situation where it
varies among unrelated types.*

When checking whether a given instance method declaration _D1_ is a correct
override of another instance method declaration _D2_, it is ignored whether or
not a formal parameter in _D1_ or _D2_ is covariant by class covariance.

*This differs from the treatment of parameters which are covariant by modifier,
where an overriding parameter type must be a subtype or a supertype of each
overridden parameter type. In practice this means a parameter which is
covariant by modifier may be specialized covariantly without limit, but a
parameter which is covariant by class covariance must be overridden by a
parameter with the same type or a supertype thereof, and it is only that type
itself which "is covariant" (in the sense that clients know an upper bound
_T_ statically, and for the actual type _S_ at run time it is only known that
_S <: T_). Here is an example:*

```dart
abstract class C<X> {
  void f1(X x);
  void f2(X x);
  void f3(covariant num x);
  void f4(X x);
  void f5(covariant X x);
}

abstract class D extends C<num> {
  void f1(num n); // OK
  void f2(int i); // Error: `num <: int` required, but not true.
  void f3(int i); // OK: covariant by modifier (only).
  void f4(covariant int i); // OK: covariant by modifier (and class).
  void f5(int i); // OK: covariant by modifier (and class).
}
```


#### Dynamic semantics

In the following, the phrase _covariant parameter_ denotes either a parameter
which is covariant by modifier, or a parameter which is covariant by class
covariance.

*We could have used 'covariant by class covariance' throughout, but for overall
simplicity we make it explicit that the treatment of both kinds of covariant
parameters is identical in the dynamic semantics.*

The reified type for a function _f_ obtained by a closurizing property
extraction on an instance method, setter, or operator is determined as
follows:

Let `m` be the name of the method, operator, or setter which is being
closurized, let _T_ be the dynamic type of the receiver, and let _D_ be the
declaration of `m` in _T_ or inherited by _T_ which is being extracted.

The reified return type of _f_ the is the static return type of _D_. For
each parameter `p` declared in _D_ which is not covariant, the part in the
dynamic type of _f_ which corresponds to `p` is the static type of `p` in
_D_. For each covariant parameter `q`, the part in the dynamic type of _f_
which corresponds to `q` is `Object`.

*The occurrences of type parameters in the types of non-covariant
parameters (note that those occurrences must be in a non-covariant position
in the parameter type) are used as-is. For instance, `<String>[].asMap()`
will have the reified type `Map<int, String> Function()`.*

The dynamic checks associated with invocation of such a function are still
needed, and they are unchanged.

*That is, a dynamic error occurs if a method with a covariant parameter p
is invoked, and the actual argument value bound to p has a run-time type
which is not a subtype of the type declared for p.*


## Alternatives

The "erasure" of the reified parameter type for each covariant parameter to
`Object` may seem aggressive.

In particular, it ignores upper bounds on the formal type parameter which gives
rise to the covariance by class covariance, and it ignores the structure of
the type where that formal type parameter is used. Here are two examples:

```dart
class C<X extends num> {
  void foo(X x) {}
  void bar(List<X> xs) {}
}
```

With this declaration, the reified type of `new C<int>().foo` will be `void
Function(Object)`, even though it would have been possible to use the type `void
Function(num)` based on the upper bound of `X`, and still preserve the earlier
mentioned expression soundness. This is because all supertypes of the dynamic
type of the receiver that declare `foo` have an argument type for it which is a
subtype of `num`.

Similarly, the reified type of `new C<int>().bar` will be `void
Function(Object)`, even though it would have been possible to use the type `void
Function(List<num>)`.

Note that the reified type is independent of the static type of the receiver, so
it does not matter that we consider `new C<int>()` directly, rather than using
an intermediate variable whose type annotation is some supertype, e.g.,
`C<num>`.

In the first example, `foo`, there is a loss of information because we are
(dynamically) allowed to assign the function to a variable of type `void
Function(Object)`. Even worse, we may assign it to a variable of type `void
Function(String)`, because `void Function(Object)` (that is, the actual type
that the function reports to have) is a subtype of `void Function(String)`. In
that situation, every statically safe invocation will fail, because there are no
values of type `String` which will satisfy the dynamic check in the function
itself, which requires an argument of type `int` (except `null`, of course, but
this is rarely sufficient to make the function useful).

In the second example, `bar`, the same phenomenon is extended a little, because
we may assign the given torn-off function to a variable of type `void
Function(String)`, in addition to more reasonable ones like `void
Function(Object) `, `void Function(Iterable<Object>)`, and `void
Function(Iterable<int>)`.

It is certainly possible to specify a more "tight" reified type like the ones
mentioned above. In order to do this, we would need the least upper bound of all
the statically known types in all supertypes of the dynamic type of the
receiver. This would involve a least upper bound operation on a set of types,
and it would involve an instantiate-to-bounds operation on the type parameters.

The main problem with this approach is that some declarations do not allow for
computation of a finite type which is the least upper bound of all possible
instantiations, so we cannot instantiate-to-bound:

```dart
// There is no finite type `T` such that all possible values for `X`
// and no other types are subtypes of `T`.
class D<X extends D<X>> {}
```

Similarly, some finite sets of types do not have a denotable least upper bound:

```dart
class I {}
class J {}

class A implements I, J {}
class B implements I, J {}
```

In this case both of `A` and `B` have the two immediate superinterfaces `I` and
`J`, and there is no single type (that we can express in Dart) which is the
least of all the supertypes of `A` and `B`.

So in some cases we will have to error out when we compute the reified type of a
tear-off of a given method, unless we introduce intersection types and infinite
types, or unless we find some other way around this difficulty.

On the other hand, it should be noted that the common usage of these torn-off
functions would be guided by the statically known types, which do have the
potential to keep them "within a safe domain".

Here is an example:

```dart
main() {
  List<int> xs = <int>[];
  void Function(int) f1 = xs.add; // Same type statically, OK at runtime.
  void Function(num) f2 = xs.add; // Statically a downcast, can warn, OK at runtime.
  void Function(Object) f3 = xs.add; // A downcast, can warn, OK at runtime.
  void Function(String) f4 = xs.add; // An unrelated type, error in strong mode.

  List<num> ys = xs; // "Forget part of the type".
  void Function(int) f5 = ys.add; // Statically an upcast, OK at runtime.
  void Function(num) f6 = ys.add; // Statically same type, OK at runtime.
  void Function(Object) f7 = ys.add; // Statically a downcast, OK at runtime.
  void Function(String) f8 = ys.add; // An unrelated type, error in strong mode.

  List<Object> zs = ys;
  void Function(int) f9 = zs.add; // Statically an upcast, OK at runtime.
  void Function(num) fa = zs.add; // Statically an upcast, OK at runtime.
  void Function(Object) fb = zs.add; // Statically same type, OK at runtime.
  void Function(String) fc = zs.add; // Finally we can go wrong silently!
}
```

In other words, the static typing helps programmers to maintain the same level
of knowledge (say, "this is a list of `num`") consistently, even though it is
consistently incomplete ("it's actually a list of `int`"), and this helps a lot
in avoiding those crazy assignments (to `List<String>`) where almost all method
invocations will go wrong.


## Updates

*   Jun 1st 2018, version 0.6: Removed specification of variance, for which
    the normative text is now part of the language specification. Adjusted
    the wording to fit the slightly different definitions of variance given
    there. The meaning of this feature specification has not changed.

*   Feb 1st 2018, version 0.5: Added specification of override checks for
    parameters which are covariant from class.

*   Nov 24th 2017, version 0.4: Modified the definition of what it takes to be
    a covariant parameter: Some cases were previously incorrectly omitted.

*   Nov 11th 2017, no version number specified: Clarified examples.

*   Apr 21st 2017, no version number specified: Some typos corrected.

*   Feb 16th 2017, no version number specified: Initial version.
