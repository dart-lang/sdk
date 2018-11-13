## Feature: Super-bounded Types

**Author**: eernst@.

**Version**: 0.8 (2018-10-16).

**Status**: Background material.
The language specification has the normative text on this topic.
Note that the rules have changed, which means that
**this document cannot be used as a reference**, it can only be
used to get an overview of the ideas; please refer to the language
specification for all technical details.

**This document** is an informal specification of the support in Dart 2 for
using certain generic types where the declared bounds are violated. The
feature described here, *super-bounded types*, consists in allowing an
actual type argument to be a supertype of the declared bound, as long as a
consistent replacement of `Object`, `dynamic`, and `void` by `Null`
produces a traditional, well-bounded type. For example, if a class `C`
takes a type argument `X` which must extend `C<X>`, `C<Object>`,
`C<dynamic>`, and `C<void>` are correct super-bounded types. This is useful
because there is no other way to specify a type which retains the knowledge
that it is a `C` based type, and at the same time it is a supertype of
`C<T>` for all the `T` that satisfy the specified bound. In other words, it
allows developers to specify that they want to work with a `C<T>`, except
that they don't care which `T`, and _every_ such `T` must be allowed.

This permission to use a super-bounded type is only granted in some
situations. For instance, super-bounded types are allowed as type
annotations, but they are not allowed in instance creation expressions like
`new C<Object>()` (assuming that `Object` violates the bound of
`C`). Similarly, a function declared as
```dart
void foo<X extends List<num>>(X x) {
  ...
}
```
cannot be invoked with `foo<List<dynamic>>([])`, nor can the type
argument be inferred to `List<dynamic>` in an invocation like
`foo([])`. But `C<void> x = new C<int>();` is OK, and so is
`x is C<Object>`.


## Motivation

Many well-known classes have a characteristic typing structure:
```dart
abstract class num implements Comparable<num> {...}
class Duration implements Comparable<Duration> {...}
class DateTime implements Comparable<DateTime> {...}
...
```
The class `Comparable<T>` has a method `int compareTo(T other)`,
which makes it possible to do things like this:
```dart
int comparison = a.compareTo(b);
```
This works fine when `a` and `b` both have type `num`, or both have type
`Duration`, but it is not so easy to describe the situation where the
comparable type can vary. For instance, consider the following:
```dart
class ComparablePair<X extends Comparable<X>> {
  X a, b;
}

main() {
  ComparablePair<MysteryType> myPair = ...
  int comparison = myPair.a.compareTo(myPair.b);
}
```
We could replace `MysteryType` by `num` and then work on pairs
of `num` only. But can we find a type to replace `MysteryType` such
that `myPair` can hold an instance of `ComparablePair<T>`, no matter
which `T` it uses?

We would need a supertype of all those `T` where
`T extends Comparable<T>`; but we cannot use the obvious ones like
`Object` or `dynamic`, because they do not satisfy the declared
bound for the type argument to `ComparablePair`. There is in fact no such
type in the Dart type system!

This is an issue that comes up in various forms whenever a type parameter
bound uses the corresponding type variable itself (or multiple type
parameters mutually depend on each other), that is, whenever we have one
or more _F-bounded_ type parameters. Here is an example which is concise
and contains the core of the issue:
```dart
class C<X extends C<X>> {
  X next;
}
```
For each given type `T` it is possible to determine whether `T` is a
subtype of `C<T>`, in which case that `T` would be an admissible actual
type argument for `C`. This means that the set of possible values for `X`
is a well-defined set.

However, there is no type `S` such that the set of possible values for `X`
is equal to the set of subtypes of `S`; that is, the set of types we seek
to express is not the set of subtypes of anything. Sure, those types are a
subset of all subtypes of `Object`, but we need to express that _exact_ set
of types, not a superset.

Hence, we cannot correctly characterize "all possible values for `X`" as a
single type argument. This means that we cannot find a `U` such that `C<U>`
is the least upper bound of all possible types on the form `C<T>`.

But that's exactly what we _must_ find, if we are to safely express the
greatest possible amount of information about the set of objects whose type
is on the form `C<T>` for some `T`. In particular, we cannot express the
type which "should be" the result of
[instantiate-to-bound](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
on the raw type `C`.

We can make an attempt to approximate the least supertype of all correct
generic instantiations of `C` (that is, a supertype of all types on the
form `C<T>`). Assume that `T` is an admissible actual type argument for
`C` (that is, we can rely on `T extends C<T>`):
```dart
// Because `T extends C<T>`, and due to generic covariance:
C<T>  <:  C<C<T>>

// Same facts used on the nested type argument `T`:
C<C<T>>  <:  C<C<C<T>>> ...

// Same at the next level ...
C<C<C<T>>>  <:  C<C<C<C<T>>>>
...
```
We can continue ad infinitum, and this means that a good candidate for the
"least upper bound of all `C<T>`" would be the infinite type `W` where
`W = C<W>`. Basically, `W = C<C<C<C<C<C<...>>>>>>`, nesting to an
infinite depth.

Note that `T` "disappears" when we extend the nesting ad infinitum, which
means that `W` is the result we find for _every_ `T`. Conversely, we cannot
hope to find a different type `V` (not equal to `C<R>` for any `R`) such
that `V` is both a supertype of all types on the form `C<T>` for some `T`
and `V` is a proper subtype of `W`. In other words, if the "least upper
bound of all `C<T>`" exists, it must be `W`.

However, we do not wish to introduce these infinite types into the Dart
type universe. The ability to express types on this form will
inevitably introduce the ability to express many new kinds of types, and we
do not expect this generalization to improve the expressive power of the
language in a manner that compensates sufficiently for the burden of
managing the added complexity.

Instead, we give developers the responsibility to make the choice
explicitly: They can use super-bounded types to express a range of
supertypes of these infinite types (as well as other types, if they
wish). When they do that with an infinite type, they can make the choice to
unfold it exactly as many times as they want. At the same time, they will
be forced to maintain a greater level of awareness of the nature of these
types than they would, had we chosen to model infinite types, e.g., by
unfolding them to some specific, finite level.

Here are some examples of finite unfoldings, and the effect they have on
types of expressions:
```dart
class C<X extends C<X>> {
  X next;
  C(this.next);
}

class D extends C<D> {
  D(D next): super(next);
}

main() {
  D d = new D(new D(null));
  C<dynamic> c0 = d;
  C<C<dynamic>> c1 = d;
  C<C<C<dynamic>>> c2 = d;

  c0.next.unknown(42); // Statically OK, `c0.next` is `dynamic`.
  c1.next.unknown(43); // Compile-time error.
  c1.next.next.unknown(44); // Statically OK.
  c2.next.next.unknown(45); // Compile-time error.
  c2.next.next.next.unknown(46); // Statically OK.

  // With type `D`, the static analysis is aware of the cyclic
  // structure of the type, and every level of nesting is handled
  // safely. But `D` may be less useful because there may be a
  // similar type `D2`, and this code will only work with `D`.
  d.next.next.next.next.next.next.next.unknown(46); // Compile-time error.
}
```
We can make a choice of how to deal with the missing type information. When
we use `C<dynamic>`, `C<C<dynamic>>` and `C<C<C<dynamic>>>` we will
implicitly switch to dynamic member access after a few steps of
navigation.

If we choose to use `C<Object>`, `C<C<Object>>` and so on then we will have
to use explicit downcasts in order to access all non-`Object` members. We
will still be able to pass `c0.next` as an argument to a function expecting
a `C<S>` (where `S` can be anything), but we could also pass it where a
`String` is expected, etc.

Finally, if we choose to use `C<void>` and so on then we will not even be
able to access the object where the type information ends: we cannot use
the value of an expression like `c0.next` without an explicit
cast (OK, `void v = c0.next;` is accepted, but it is mostly impossible to
use the value of an expression of type `void`). This means that we cannot
pass `c0.next` as an argument to a function that accepts a `C<S>`
(for any `S`) without an explicit cast.

In summary, the choice of `dynamic`, `Object`, and `void` offers a range of
approaches to the lack of typing information, but the amount of information
remains the same.


## Syntax

This feature does not require any modifications to the Dart grammar.


## Static analysis

We say that the parameterized type _G<T<sub>1</sub>..T<sub>k</sub>>_ is
_regular-bounded_ when _T<sub>j</sub> <: [T<sub>1</sub>/X<sub>1</sub> ..
T<sub>k</sub>/X<sub>k</sub>]B<sub>j</sub>_ for all _j_, _1 <= j <= k_,
where _X<sub>1</sub>..X<sub>k</sub>_ are the formal type parameters of _G_
in declaration order, and _B<sub>1</sub>..B<sub>k</sub>_ are the
corresponding upper bounds.

*This means that each actual type argument satisfies the declared upper
bound for the corresponding formal type parameter.*

We extend covariance for generic class types such that it can be used also
in cases where a type argument violates the corresponding bound.

*For instance, assuming the classes `C` and `D` as declared in the
Motivation section, `C<D>` is a subtype of `C<Object>`. This is new because
`C<Object>` used to be a compile-time error, which means that no questions
could be asked about its properties. Note that this is a straightforward
application of the usual covariance rule: `C<D> <: C<Object>` because
`D <: Object`. We need this relaxation of the rules in order to be able to
define which violations of the declared bounds are admissible.*

Let _G_ denote a generic class, _X<sub>1</sub>..X<sub>k</sub>_ the formal
type parameters of _G_ in declaration order, and
_B<sub>1</sub>..B<sub>k</sub>_ the types in the corresponding upper bounds,
using `Object` when the upper bound is omitted. The parameterized type
_G&lt;T<sub>1</sub>..T<sub>k</sub>&gt;_ is then a _super-bounded type_
iff the following two requirements are satisfied:

1.   There is a _j_, _1 <= j <= k_, such that _T<sub>j</sub>_ is not a
     subtype of
     _[T<sub>1</sub>/X<sub>1</sub>..T<sub>k</sub>/X<sub>k</sub>]B<sub>j</sub>_.

2.   Let _S<sub>j</sub>_, _1 <= j <= k_, be the result of replacing every
     covariant occurrence of `Object`, `dynamic`, and `void` in
     _T<sub>j</sub>_ by `Null`, and every contravariant occurrence of `Null`
     by `Object`. It is then required that
     _S<sub>j</sub> &lt;:
     [S<sub>1</sub>/X<sub>1</sub>..S<sub>k</sub>/X<sub>k</sub>]B<sub>j</sub>_
     for all _j_, _1 <= j <= k_.

*In short, at least one type argument violates its bound, and the type is
regular-bounded after replacing all occurrences of an extreme type by the
opposite extreme type, according to their variance.*

*For instance, assuming the declarations of `C` and `D` as in the
Motivation section, `C<Object>` is a super-bounded type, because `Object`
violates the declared bound and `C<Null>` is regular-bounded.*

*Here is an example that involves contravariance:*

```dart
class E<X extends void Function(X)> {}
```

*With this declaration, `E<void Function(Null)>` is a super-bounded type
because `E<void Function(Object)>` is a regular-bounded type. Note that
the contravariance can also be eliminated, yielding a simpler super-bounded
type: `E<dynamic>` is a super-bounded type because `E<Null>` is a
regular-bounded type.*

We say that a parameterized type _T_ is _well-bounded_ if it is
regular-bounded or super-bounded.

*Note that it is possible for a super-bounded type to be nested in another
type which is super-bounded, and it can also be nested in another type
which is not super-bounded. For example, assuming `C` as in the Motivation
section, `C<C<Object>>` is a super-bounded type which contains a
super-bounded type; in contrast, `List<C<Object>>` is a regular type (a
generic instantiation of `List`) which contains a super-bounded type
(`C<Object>`).*

It is a compile-time error if a parameterized type is not well-bounded.

*That is, a parameterized type is regular-bounded, or it is super-bounded,
or it is an error. This rule replaces and relaxes the rule in the language
specification that constrains parameterized types to be regular-bounded.*

It is a compile-time error if a type used as the type in an instance
creation expression (*that is, the `T` in expressions of the form
`new T(...)`, `new T.id(...)`, `const T(...)`, or `const T.id(...)`*)
is super-bounded. It is a compile-time error if the type in a redirection
of a redirecting factory constructor (*that is, the `T` in a phrase of the
form `T` or `T.id` after `=` in the constructor declaration*) is
super-bounded. It is a compile-time error if a super-bounded type is
specified as a superinterface for a class. (*This implies that a
super-bounded type cannot appear in an `extends`, `implements`, or
`with` clause, or in a mixin application; e.g., `T` in
`class C = T with M;` cannot be super-bounded*). Finally, it is a
compile-time error if a bound in a formal type parameter declaration is
super-bounded.

*This means that we allow super-bounded types as function return types, as
type annotations on variables (all of them: library, static, instance, and
local variables, and formal parameters of functions), in type tests
(`e is T`), in type casts (`e as T`), in `on` clauses, and as type
arguments.*

Let _F_ denote a parameterized type alias, _X<sub>1</sub>..X<sub>k</sub>_ the
formal type parameters of _F_ in declaration order, and
_B<sub>1</sub>..B<sub>k</sub>_ the types in the corresponding upper bounds,
using `Object` when the upper bound is omitted. The parameterized type
_F&lt;T<sub>1</sub>..T<sub>k</sub>&gt;_ is then a _super-bounded type_
iff the following three requirements are satisfied:

1.   There is a _j_, _1 <= j <= k_, such that _T<sub>j</sub>_ is not a
     subtype of
     _[T<sub>1</sub>/X<sub>1</sub>..T<sub>k</sub>/X<sub>k</sub>]B<sub>j</sub>_.

2.   Let _S<sub>j</sub>_, _1 <= j <= k_, be the result of replacing every
     covariant occurrence of `Object`, `dynamic`, and `void` in
     _T<sub>j</sub>_ by `Null`, and every contravariant occurrence of `Null`
     by `dynamic`. It is then required that
     _S<sub>j</sub> &lt;:
     [S<sub>1</sub>/X<sub>1</sub>..S<sub>k</sub>/X<sub>k</sub>]B<sub>j</sub>_
     for all _j_, _1 <= j <= k_.

3.   Let _T_ be the right hand side of the declaration of _F_, then
     _[T<sub>1</sub>/X<sub>1</sub>..T<sub>k</sub>/X<sub>k</sub>]T_ is a
     well-bounded type.

*In short, a parameterized type based on a type alias, `F<...>`, must pass the
super-boundedness checks in itself, and so must the body of `F`.*

*For instance, assume that `F` and `G` are declared as follows:*
```dart
class A<X extends C<X>> {
  ...
}

typedef F<X extends C<X>> = A<X> Function();
typedef G<X extends C<X>> = void Function(A<X>);
```
*The type `F<Object>` is then a super-bounded type, because `F<Null>` is
regular-bounded (`Null` is a subtype of `C<Null>`) and because
`A<Object> Function()` is well-bounded, because `A<Object>` is
super-bounded. Similarly, `G<Object>` is a super-bounded type because
`void Function(A<Object>)` is well-bounded because `A<Object>` is
super-bounded.*

*Note that it is necessary to require that the right hand side of a type
alias declaration is taken into account when determining that a given
application of a type alias to an actual type argument list is correctly
super-bounded. That is, we do not think that it is possible for a
(reasonable) constraint specification mechanism on the formal type
parameters of a type alias declaration to ensure that all arguments
satisfying those constraints will also be suitable for the type on the
right hand side. In particular, we may use simple upper bounds and
F-bounded constraints (as we have always done), perform and pass the
'correctly super-bounded' check on a given parameterized type based on a
type alias, and still have a right hand side which is not well-bounded:*
```dart
class B<X extends List<num>> {}
typedef H<Y extends num> = void Function(B<List<Y>>);
typedef K<Y extends num> = B<List<Y>> Function(B<List<Y>>);

H<Object> myH = null; // Error!
```
*`H<Object>` is a compile-time error because it is not regular-bounded
(`Object <: num` does not hold), and it is also not correctly
super-bounded: `Null` does satisfy the constraint in the declaration of
`Y`, but `H<Object>` gives rise to the right hand side
`void Function(B<List<Object>>)`, and that is not a well-bounded type:
It is not regular-bounded (`List<Object> <: List<num>` does not hold),
and it does not become a regular-bounded type by the type replacements
(that yield `void Function(B<List<Object>>)` because that occurrence of
`Object` is contravariant).*

*Semantically, this failure may be motivated by the fact that `H<Object>`,
were it allowed, would not be a supertype of `H<T>` for all the `T` where
`H<T>` is regular-bounded. So it would not be capable of playing the role
as a "default type" that abstracts over all the possible actual types that
are expressible using `H`. For example, a variable declared like
`List<H<Object>> x;` would not be allowed to hold a value of type
`List<H<num>>` because the latter is not a subtype of the former.*

*In the given situation it is possible to express such a default type:
`H<Null>` is actually a common supertype of `H<T>` for all `T` such that
`H<T>` is regular-bounded. However, `K` shows that this is not always the
case: There is no type `S` such that `K<S>` is a common supertype of `K<T>`
for all those `T` where `K<T>` is regular-bounded. Facing this situation,
we prefer to bail out rather than implicitly allow some kind of
super-bounded type (assuming that we amend the rules such that it is not an
error) which would not abstract over all possible instantiations anyway.*

*The subtype relations for super-bounded types follow directly from the
extension of generic covariance to include actual type arguments that
violate the declared bounds. For the example in the Motivation section, `D`
is a subtype of `C<D>` which is a subtype of `C<C<D>>`, which is a subtype
of `C<C<C<D>>>`, continuing with `C<C<C<Object>>>>`, `C<C<Object>>`,
`C<Object>`, and `Object`, respectively, and similarly for `dynamic` and
`void`.*

Types of members from super-bounded class types are computed using the same
rules as types of members from other types. Types of function applications
involving super-bounded types are computed using the same rules as types of
function applications involving other types.

*For instance, using the example class `C` again, if `c1` has static type
`C<C<dynamic>>` then `c1.next` has static type `C<dynamic>` and
`c1.next.next` has static type `dynamic`. Similarly, if `List<X> foo(X)`
were the signature of a method in `C`, `c1.foo` would have static type
`List<C<dynamic>> Function(C<dynamic>)`. Note that the argument type `X`
makes that parameter of `foo` covariant, which implies that the reified
type of the tear-off `c1.foo` would have argument type `Object`, which
ensures that the expression `c1.foo` evaluates to a value whose dynamic
type is a subtype of the static type, as it should.*

*Similarly, if we invoke an instance method with statically known argument
type `C<void>` whose argument is covariant, there will be a dynamic type
check on the actual argument (which might require that it is, say, of type
`D`); that check may fail at run time, but this is no different from the
situation with types that are not super-bounded. In general, the
introduction of super-bounded types does not introduce new soundness
considerations around covariance.*

*Super-bounded function types do not have to be only in the statically
known types of first class functions, they can also be part of the actual
type of a function at run time.  For instance, a function may be declared
as follows:*

```dart
List<C<dynamic>> foo(C<dynamic> x) {
  ...
}
```

*It would then have type exactly `List<C<dynamic>> Function(C<dynamic>)`,
and this means that it will accept an object which is an instance of a
subtype of `C<T>` for any `T`, and it will return a list whose element type
is some subtype of `C<dynamic>`, which could be `D` or `C<C<D>>` at run
time.*


## Dynamic semantics

The reification of a super-bounded type (*e.g., as a parameter type in a
reified function type*) uses the types as specified.

*For instance `void foo(C<Object> x) => print(x);` will have reified type
`void Function(C<Object>)`. It is allowed for a run-time entity to have a
type which contains a super-bounded type, it is only prohibited for
run-time entities to have a super-bounded type themselves. So there can be
an instance whose dynamic type is `List<C<Object>>` but no instance whose
dynamic type is `C<Object>`.*

The subtype rules used for run-time type tests, casts, and generated type
checks are the same as the subtype rules used during static analysis.

*If an implementation applies an optimization that is only valid when
super-bounded types cannot exist, or in other ways relies on the (no longer
valid) assumption that super-bounded types cannot exist, it will need to
stop using that optimization or making that assumption. We do not expect
this to be a common situation, nor do we expect significant losses in
performance due to the introduction of this feature.*


## Discussion

The super-bounded type feature is all about violating bounds, in a
controlled manner. But what is the **motivation for enforcing bounds** in
the first place? The answer to that question serves to justify why it must
be 'controlled'. We have at least two reasons, one internal and one
external.

The **internal reason** is that the bound of each formal type parameter is
relied upon during type checking of the body of the corresponding generic
declaration. For instance:
```dart
class C<X extends num> {
  X x;
  bool get foo => x.isNegative; // Statically safe invocation.
}
```
If we ever allow an instance of `C<Object>` to be created, or even an
instance of a subclass which has `C<Object>` as a (possibly indirect)
superclass, then we could end up executing that implementation of `foo` in
a situation where `x` does not have an `isNegative` getter. In other words,
the internal issue is that super-bounding may induce a plain soundness
violation in the scope of the type parameter.

This motivates the ban on super-bounding in instance creation expressions,
e.g., the ban on `new C<Object>()`.

However, it does not suffice to justify banning super-bounded `implements`
clauses: There will not be any inherited method implementations from a type
that a given class implements, and hence no code will ever be executed in
the above situation (where a formal type parameter is in scope, and its
actual value violates the bound). In fact, code which could be executed in
this context would have static knowledge of the super-bound, and hence
there is no soundness issue in the body of such a class, nor in its
subclasses or subtypes.

```dart
// A thought experiment (explaining why this is a compile-time error).
class D implements C<Object> {
  Object x;
  bool get foo => false;
}
```

It is reasonable to expect a `C<Object>` to have a field `x` of type
`Object` and a `foo` getter of type `bool`, and we can easily implement
that. There is no soundness issue, because no code is inherited from `C`.

But there is also an **external reason**: It is reasonable to expect that
every instance will satisfy declared bounds, e.g., whenever an object is
accessed under the type `C<T>` for any `T`, it should be true that `T` is a
subtype of `num`. This is not a soundness issue per se; the class `D` is
perfectly consistent in its behavior with a typing as `C<Object>`, and its
implementation is type safe.

However, it seems reasonable for developers to reckon as follows: When an
object _o_ has a static type like `C<Object>` it must satisfy the
expectations associated with `C`. So there exists an actual type argument
`T` which satisfies the declared bound, and _o_ must then behave like an
instance of `C<T>`. In the example, with the given bound `num` and using
covariance, _o_ would then be guaranteed to be typable as a `C<num>`. So
the following contains downcasts, but it is "reasonable" to expect them to
be guaranteed to succeed at run time:

```dart
C<Object> cObject = ...; // Complex creation.
C<num> cNum = cObject; // Safe, right?
bool b = (cObject.x as num).isNegative; // Also safe, right?
```

If `D` is allowed to exist then we can have a consistent language, and the
above would be OK, but the "safe" downcasts would in fact fail at run
time. The point is that when we know something is a `C<Object>` then we know
that it satisfies the constraints of `C<Object>`, and we can't assume that
it satisfies any stronger constraints (such as those of `C<num>`).

This is not a soundness issue in the traditional sense, but it is an issue
about how important it is to **allow** developers to make that **extra
assumption** that all implementations of a given generic class _G_ must be
just as picky about their actual type arguments as _G_ itself.

We think that it is indeed justified to make these extra assumptions, and
**hence** we have **banned super-bounded `implements` clauses**.

The extra assumptions which are now supported could be stated as: We can
rely on the declared bounds on type parameters of generic classes and
functions, also for code which is outside the scope of those type
parameters.

In short, the underlying principle is that "there cannot be an instance of
a generic class (including instances of subtypes), nor an invocation of a
generic function, whose actual type arguments violate the declared
bounds".

Super-bounded function types are possible and useful. Consider the
following example:
```dart
// If bound on `X` holds then `C<X>` is regular-bounded.
typedef F<X extends C<X>> = C<X> Function();

main() {
  F<C<dynamic>> f = ...; // OK, checking `F<C<Null>>` and `C<dynamic> Function()`.
  var c0 = f(); // `c0` has type `C<C<dynamic>>`.
  var c1 = c0.next; // `c1` has type `C<dynamic>`
  var c2 = c1.next; // `c2` has type `dynamic`
  ...
}
```
In this example, an unfolding of `C` to a specific level is supported in a
function type, and application of such a function immediately brings out
class types like `C<C<dynamic>>` that we have already argued are useful.


## Updates

*   Version 0.8 (2018-10-16), emphasized that this document is no longer
    specifying the current rules, it is for background info only.

*   Version 0.7 (2018-06-01), marked as background material: The normative
    text on variance and on super-bounded types is now part of the language
    specification.

*   Version 0.6 (2018-05-25), added example showing why we must check the
    right hand side of type aliases.

*   Version 0.5 (2018-01-11), generalized to allow replacement of top types
    covariantly and bottom types contravariantly. Introduced checks on
    parameterized type aliases (such that bounds declared for the type
    alias itself are taken into account).

*   Version 0.4 (2017-12-14), clarified several points and corrected
    locations where super-bounded types were prohibited, but we should just
    say that the bounds must be satisfied.

*   Version 0.3 (2017-11-07), dropping `super`, instead allowing `Object`,
    `dynamic`, or `void` for super-bounded types, with a similar treatment as
    `super` used to get.

*   Version 0.2 (2017-10-31), introduced keyword `super` as a type argument.

*   Version 0.1 (2017-10-20), initial version of this informal specification.
