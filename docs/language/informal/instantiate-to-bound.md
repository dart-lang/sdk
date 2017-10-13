## Feature: Instantiate to Bound

Author: eernst@

Based on [this description](https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397) by leafp@.

**Status**: Under implementation. Remaining issue: Can a super-bounded
type be created by instantiate to bound?

**This document** is an informal specification of the the instantiate to bound
mechanism in Dart 2. The feature described here, *instantiate to bound*, makes
it possible to omit some or all actual type arguments in some types using
generic classes. The missing type arguments will be added implicitly, and the
chosen value for a given type argument will be the bound on the corresponding
formal type parameter. In some situations no such bound can be expressed, in
which case a compile-time error occurs. To resolve that, the type arguments
can be given explicitly.

## Background

In Dart 1.x, missing actual type arguments were filled in with the value
`dynamic`, which was always a useful choice because that would yield types
which were at the bottom of the set of similar types, as well as at the top.
```dart
List xs = <int>[]; // OK, also dynamically: List<int> <: List<dynamic>.
List<int> y = new List(); // OK, also dynamically: List<dynamic> <: List<int>.
```
In Dart 2, type inference is used in many situations to infer missing type
arguments, hence selecting values that will work in the given context.
However, when the context does not provide any information to this inference
process, some default choice must be made.

In Dart 2, `dynamic` is no longer a super- and subtype of all other types,
and hence using `dynamic` as the default value for a missing actual
type argument will create many malformed types:
```dart
class A<X extends num> {}
A a = null; // A is malformed if interpreted as A<dynamic>.
```
Hence, a new rule for finding default actual type arguments must be specified.

## Motivation

It is convenient for developers to be able to use a more concise notation for
some types, and instantiate to bound will enable this.

We will use a relatively simple mechanism which is allowed to fail. This means
that developers will have to write actual type arguments explicitly in some
ambiguous situations, thus adding visual complexity to the source code and
requiring extra time and effort to choose and write those arguments. However,
we consider the ability to reason straightforwardly about generic types in
general more important than (possibly misleading) conciseness.

The performance characteristics of the chosen algorithm plays a role as well,
because it is important to be able to find default type arguments in a short
amount of time. Because of that, we have chosen to require explicit type
arguments on bounds except for some "simple" cases. Again, this means that the
source code will be somewhat more verbose, in return for overall simplicity.

Here are some examples:

```dart
class A<T extends int> {}

// The raw type A is completed to A<int>.
A x;

// T of A has a simple bound, so A can be a bound and is completed to A<int>.
class B<T extends A> {}

class C<T extends int, S extends A<T>> {}

// The raw type C is completed to C<int, A<int>>.
C x;

class D<T extends Comparable<T>> {}

// Error: no default type arguments can be computed for D.
D x;

// Error: T of D does not have a simple bound, so raw D cannot be a bound.
class E<T extends D> {}
```


## Syntax

This mechanism does not require any grammar modifications.


## Static analysis

Let _G_ be a generic class with formal type parameter declarations
_F1 .. Fk_ containing formal type parameters _X1 .. Xk_ and bounds _B1
.. Bk_. We say that the formal type parameter _Xj_ has a _simple bound_
when one of the following requirements is satisfied:

1. _Bj_ is omitted.

2. _Bj_ is included, but does not contain any of _X1 .. Xk_. If _Bj_
   contains a type _T_ on the form `qualified` (*for instance, `C` or
   `p.D`*) which denotes a generic class _G1_ (*that is, _T_ is a raw
   type*), every type argument of _G1_ has a simple bound.

The notion of a simple bound must be interpreted inductively rather
than coinductively, i.e., if a bound _Bj_ of a generic class _G_ is
reached during an investigation of whether _Bj_ is a simple bound,
the answer is no.

*For example, with `class C<X extends C> {}` the type parameter `X` does
not have a simple bound.*

*We can now specify in which sense instantiate to bound requires the
involved types to be "simple enough". We impose the following constraint on
all bounds because any generic type may be used as a raw type.*

It is a compile-time error if a formal parameter bound _B_ contains
a type _T_ on the form `qualified` and _T_ denotes a generic class
_G_ (*that is, _T_ is a raw type*), unless every formal type parameter of
_G_ has a simple bound.

*In short, type arguments on bounds can only be omitted if they themselves
have simple bounds. In particular, `class C<X extends C> {}` is a
compile-time error because the bound `C` is raw, and the formal type
parameter `X` that corresponds to the omitted type argument does not have a
simple bound.*

When a type annotation _T_ on the form `qualified` denotes a generic class
(*so _T_ is raw*), instantiate to bound is used to provide the missing type
argument list. It is a compile-time error if the instantiate to bound
process fails.

*Other mechanisms may be considered for this situation, e.g., inference
could be used to select a possible type annotation, and type arguments
could then be transferred from the inferred type annotation to the given
incomplete type annotation. For instance, `Iterable` could be specified
explicitly for a variable, `List<int>` could be inferred from its
initializing expression, and the partially inferred type annotation would
then be `Iterable<int>`. However, even if such a mechanism is introduced,
it will not make the instantiate to bound feature obsolete: instatiate to
bound would still be used in cases where no information is available to
infer the omitted type arguments, e.g., for `List xs = [];`.*

When type inference is providing actual type arguments for a term _G_ on
the form `qualified` which denotes a generic class, instantiate to bound
will provide the value for a single type argument in cases where no
information is available for inferring such an actual type argument. In
this situation, it is a compile-time error if instantiate to bound fails.

In all these cases, instantiate to bound selects the value for an omitted
actual type argument as follows:

Let _T_ be a `qualified` term which denotes a generic class _G_ (*so _T_ is
a raw type*), let _F1 .. Fk_ be the formal type parameter declarations in the
declaration of _G_, with type parameters _X1 .. Xk_ and bounds _B1 .. Bk_
with types _T1 .. Tk_, and let _j_ be the position of the actual type
argument for which the selection will be made.

If _Bj_ is omitted, the selected value for _Xj_ is `dynamic`.

Otherwise, if _Bj_ does not contain any of the formal type parameters
_X1 .. Xk_, the selected value for _Xj_ is the result of performing
instantiate to bound on the type in the bound, _Tj_.

*Note that if _Tj_ is raw then we know that all its omitted type arguments
have simple bounds, which limits the complexity of the instantiate to bound
step for _Tj_.*

Otherwise, define the substitution _s_ as follows: for all _j_ in _1 .. k_,
replace _Xj_ by the result of applying instantiate to bound on _Tj_. Now,
repeatedly apply _s_ on the types in the bounds _T1 .. Tk_ until _Tj_ does
not contain any of the formal type parameters _X1 .. Xk_.

If this process terminates then the selected value is the final
value of the bound in _Fj_. If it does not terminate, the instantiate
to bounds process has failed.

*It can always be determined whether the process will terminate, because
it always replaces each formal type parameter by a specific term, thus
incrementally building a regular tree: If the bound in _Fj_ at some step
_s_ contains some type parameter _Xm_, and it contains _Xm_ again at a
later step _s+n_, then the process will not terminate. If no such
repeated occurrence of a type parameter occurs then the process will
terminate, because the set of formal type parameters is finite.*

*Note that instantiate to bound will always fail if the bound
on _Fj_ is an F-bound, e.g., `class A<T extends B<T>>`.*

When instantiate to bound is applied to a type it proceeds recursively: For
a generic instantiation `G<T1..Tk>` it is applied to `T1..Tk`; for
a function type `T0 Function(T1..Tj, {Tj+1 xj+1 .. Tk xk})` and
a function type `T0 Function(T1..Tj, [Tj+1 .. Tk])` it is applied
to `T0..Tk`.

*This means that instantiate to bound has no effect on a type that does not
contain any raw types; conversely, instantiate to bound will act on types
which are syntactic subterms, no matter where they occur.*


## Dynamic semantics

There is no separate dynamic semantics for this mechanism. The semantics
of a given program _P_ is the semantics of the program _P'_ which is
created from _P_ by applying instantiate to bound where applicable.


## Discussion

A more complex algorithm was considered, possibly involving support for
recursive (infinite) types. For example:

```dart
// A global dependency: F and G could be in different libraries.
class F<T extends G> {}
class G<T extends F> {}
```

In this case, instantiating the bounds to the infinite terms
`G<F<G<F<G<F<...>>>>>>` and `F<G<F<G<F<G<...>>>>>>` would be a consistent
solution, which could be justified by means of a coinductive
interpretation of what it means to be a 'simple bound'. However, we do not
expect solutions to this kind of challenge to be sufficiently useful
(if even possible) to justify the added complexity, both with respect to
comprehensibility for human readers, and with respect to the performance
of tools.


## Updates

*   Sep 15th 2017: Transferred to the SDK repository as
    [instantiate-to-bound.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md).

*   Sep 15th 2017: Adjusted to include the enhanced expressive power
    described in
    [SDK issue #28580](https://github.com/dart-lang/sdk/issues/28580).

*   Sep 14th 2017: Created this informal specification, based on
    [this description](https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397)
    by leafp@.
