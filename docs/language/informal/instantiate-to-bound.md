## Feature: Instantiate to Bound

**Author**: eernst@

**Version**: 0.7 (2018-02-26)

**Status**: Under implementation.

Based on [this description](https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397) by leafp@.

**This document** is an informal specification of the the instantiate to
bound mechanism in Dart 2. The feature described here, *instantiate to
bound*, makes it possible to omit some or all actual type arguments in some
types using generic classes. The missing type arguments will be added
implicitly, and the chosen value for a given type argument will be the
bound on the corresponding formal type parameter. In some situations no
such bound can be expressed, in which case a compile-time error occurs. To
resolve that, the type arguments can be given explicitly.

## Background

In Dart 1.x, missing actual type arguments were filled in with the value
`dynamic`, which was always a useful choice because that would yield types
which were at the bottom of the set of similar types, as well as at the
top.

```dart
List xs = <int>[]; // OK, also dynamically: List<int> <: List<dynamic>.
List<int> y = new List(); // OK, also dynamically: List<dynamic> <: List<int>.
```

In Dart 2, type inference is used in many situations to infer missing type
arguments, hence selecting values that will work in the given context.
However, when the context does not provide any information to this
inference process, some default choice must be made.

In Dart 2, `dynamic` is no longer a super- and subtype of all other types,
and hence using `dynamic` as the default value for a missing actual type
argument will create many malformed types:

```dart
class A<X extends num> {}
A a = null; // A is malformed if interpreted as A<dynamic>.
```

Hence, a new rule for finding default actual type arguments must be
specified.

## Motivation

It is convenient for developers to be able to use a more concise notation
for some types, and instantiate to bound will enable this.

We will use a relatively simple mechanism which is allowed to fail. This
means that developers will have to write actual type arguments explicitly
in some ambiguous situations, thus adding visual complexity to the source
code and requiring extra time and effort to choose and write those
arguments. However, we consider the ability to reason straightforwardly
about generic types in general more important than (possibly misleading)
conciseness.

The performance characteristics of the chosen algorithm plays a role as
well, because it is important to be able to find default type arguments in
a short amount of time. Because of that, we have chosen to require explicit
type arguments on bounds except for some "simple" cases. Again, this means
that the source code will be somewhat more verbose, in return for overall
simplicity.

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

// The raw type D is completed to D<Comparable<dynamic>>.
D x;

// Error: T of D does not have a simple bound, so raw D cannot be a bound.
class E<T extends D> {}
```


## Syntax

This mechanism does not require any grammar modifications.


## Static analysis

Let _G_ be a generic class with formal type parameter declarations
_F<sub>1</sub> .. F<sub>k</sub>_ containing formal type parameters
_X<sub>1</sub> .. X<sub>k</sub>_ and bounds
_B<sub>1</sub> .. B<sub>k</sub>_. We say that the formal type parameter
_X<sub>j</sub>_ has a _simple bound_ when one of the following requirements
is satisfied:

1. _B<sub>j</sub>_ is omitted.

2. _B<sub>j</sub>_ is included, but does not contain any of _X<sub>1</sub>
   .. X<sub>k</sub>_. If _B<sub>j</sub>_ contains a type _T_ on the form
   `qualified` (*for instance, `C` or `p.D`*) which denotes a generic class
   _G<sub>1</sub>_ (*that is, _T_ is a raw type*), every type argument of
   _G<sub>1</sub>_ has a simple bound.

The notion of a simple bound must be interpreted inductively rather than
coinductively, i.e., if a bound _B<sub>j</sub>_ of a generic class _G_ is
reached during an investigation of whether _B<sub>j</sub>_ is a simple
bound, the answer is no.

*For example, with `class C<X extends C> {}` the type parameter `X` does
not have a simple bound.*

*We can now specify in which sense instantiate to bound requires the
involved types to be "simple enough". We impose the following constraint on
all bounds because any generic type may be used as a raw type.*

It is a compile-time error if a formal parameter bound _B_ contains a type
_T_ on the form `qualified` and _T_ denotes a generic class _G_ (*that is,
_T_ is a raw type*), unless every formal type parameter of _G_ has a simple
bound.

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

*When type inference is providing actual type arguments for a term _G_ on
the form `qualified` which denotes a generic class, instantiate to bound
may be used to provide the value for type arguments where no information is
available for inferring such an actual type argument. This document does
not specify how inference interacts with instantiate to bound, that will be
specified as part of the specification of inference. We will hence proceed
to specify instantiate to bound as it applies to a type argument list which
is omitted, such that a value for all the actual type arguments must be
computed.*

Let _T_ be a `qualified` term which denotes a generic class _G_ (*so _T_ is
a raw type*), let _F<sub>1</sub> .. F<sub>k</sub>_ be the formal type
parameter declarations in the declaration of _G_, with type parameters
_X<sub>1</sub> .. X<sub>k</sub>_ and bounds _B<sub>1</sub>
.. B<sub>k</sub>_ with types _T<sub>1</sub> .. T<sub>k</sub>_. For _i_ in
_1 .. k_, let _S<sub>i</sub>_ denote the result of performing instantiate
to bound on the type in the bound, _T<sub>i</sub>_; in the case where
_B<sub>i</sub>_ is omitted, let _S<sub>i</sub>_ be `dynamic`.

*Note that if _T<sub>i</sub>_ for some _i_ is raw then we know that all its
omitted type arguments have simple bounds, which limits the complexity of
the instantiate to bound step for _T<sub>i</sub>_.*

Instantiate to bound then computes an actual type argument list for _G_ as
follows:

Let _U<sub>i,1</sub>_ be _S<sub>i</sub>_, for all _i_ in _1 .. k_. (*This
is the "current value" of the bound for type variable _i_, at step 1; in
general we will consider the current step, _m_, and use data for that step,
e.g., the bound _U<sub>i,m</sub>_, to compute the data for step _m + 1_*).

Let _--><sub>m</sub>_ be a relation among the type variables
_X<sub>1</sub> .. X<sub>k</sub>_ such that
_X<sub>p</sub> --><sub>m</sub> X<sub>q</sub>_ iff _X<sub>q</sub>_ occurs in
_U<sub>p,m</sub>_ (*so each type variable is related to, that is, depends
on, every type variable in its bound, possibly including itself*).
Let _==><sub>m</sub>_ be the transitive closure of _--><sub>m</sub>_.
For each _m_, let _U<sub>i,m+1</sub>_, for _i_ in _1 .. k_, be determined
by the following iterative process:

1. If there exists a _j_ in _1 .. k_ such that
   _X<sub>j</sub> ==><sub>m</sub> X<sub>j</sub>_
   (*that is, if the dependency graph has a cycle*)
   let _M<sub>1</sub> .. M<sub>p</sub>_ be the strongly connected components
   (SCCs) with respect to _--><sub>m</sub>_
   (*that is, the maximal subsets of _X<sub>1</sub> .. X<sub>k</sub>_
   where every pair of variables in each subset are related in both directions
   by _==><sub>m</sub>_; note that the SCCs are pairwise disjoint; also, they
   are uniquely defined up to reordering, and the order does not matter*).
   Let _M_ be the union of _M<sub>1</sub> .. M<sub>p</sub>_
   (*that is, all variables that participate in a dependency cycle*).
   Let _i_ be in _1 .. k_.
   If _X<sub>i</sub>_ does not belong to _M_ then
   _U<sub>i,m+1</sub> = U<sub>i,m</sub>_.
   Otherwise there exists a _q_ such that _X<sub>i</sub>_ belongs to
   _M<sub>q</sub>_; _U<sub>i,m+1</sub>_ is then obtained from _U<sub>i,m</sub>_
   by replacing every covariant occurrence of a variable in _M<sub>q</sub>_ by
   `dynamic`, and replacing every contravariant occurence of a variable in
   _M<sub>q</sub>_ by `Null`.

2. Otherwise, (*if no dependency cycle exists*) let _j_ be the lowest number
   such that _X<sub>j</sub>_ occurs in _U<sub>p,m</sub>_ for some _p_ and
   _X<sub>j</sub> -/-><sub>m</sub> X<sub>q</sub>_ for all _q_ in _1..k_
   (*that is, _U<sub>j,m</sub>_ is closed, that is, the current bound of
   _X<sub>j</sub>_ does not contain any type variables; but _X<sub>j</sub>_ is
   being depended on by the bound of some other type variable*).
   Then, for all _i_ in _1 .. k_, _U<sub>i,m+1</sub>_ is obtained from
   _U<sub>i,m</sub>_ by replacing every covariant occurrence of _X<sub>j</sub>_
   by _U<sub>j,m</sub>_, and replacing every contravariant occurrence of
   _X<sub>j</sub>_ by `Null`.

3. Otherwise, (*when no dependencies exist*) terminate with the result
   _&lt;U<sub>1,m</sub> ..., U<sub>k,m</sub>&gt;_.

*This process will always terminate, because the total number of
occurrences of type variables from _{X<sub>1</sub> .. X<sub>k</sub>}_ in
the current bounds is strictly decreasing with each step, and we terminate
when that number reaches zero.*

*Note that this process may produce a
[super-bounded type](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/super-bounded-types.md).*

When instantiate to bound is applied to a type it proceeds recursively: For
a generic instantiation _G<T<sub>1</sub> .. T<sub>k</sub>>_ it is applied
to _T<sub>1</sub> .. T<sub>k</sub>_; for a function type
_T<sub>0</sub> Function(T<sub>1</sub> .. T<sub>j</sub>, {T<sub>j+1</sub> x<sub>1</sub> .. T<sub>k</sub> x<sub>j+k</sub>})_
and a function type
_T<sub>0</sub> Function(T<sub>1</sub> .. T<sub>j</sub>, [T<sub>j+1</sub> .. T<sub>j+k</sub>])_
it is applied to _T<sub>0</sub> .. T<sub>j+k</sub>_.

*This means that instantiate to bound has no effect on a type that does not
contain any raw types; conversely, instantiate to bound will act on types
which are syntactic subterms, no matter where they occur.*


## Dynamic semantics

The instantiate to bound transformation which is specified in the static
analysis section is used to provide type arguments to dynamic invocations
of generic functions, when no actual type arguments are passed. Otherwise,
the semantics of a given program _P_ is the semantics of the program _P'_
which is created from _P_ by applying instantiate to bound where
applicable.


## Updates

*   Feb 26th 2018, version 0.7: Revised cycle breaking algorithm for
    F-bounded type variables to avoid specifying orderings that do not matter.

*   Feb 22nd 2018, version 0.6: Revised cycle breaking algorithm for
    F-bounded type variables to replace all members by an extreme type, not
    just one of them.

*   Jan 11th 2018, version 0.5: Revised treatment of variance based on
    strongly connected components in the dependency graph.

*   Dec 13th 2017: Revised to allow infinite substitution sequences when the
    value of a type argument is computed, specifying how to detect that
    the substitution sequence is infinite, and how to obtain a result from
    there.

*   Sep 15th 2017: Transferred to the SDK repository as
    [instantiate-to-bound.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md).

*   Sep 15th 2017: Adjusted to include the enhanced expressive power
    described in
    [SDK issue #28580](https://github.com/dart-lang/sdk/issues/28580).

*   Sep 14th 2017: Created this informal specification, based on
    [this description](https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397)
    by leafp@.
