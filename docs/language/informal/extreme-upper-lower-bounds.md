# Feature Specification: Upper and Lower Bounds for Extreme Types

**Owner**: eernst@

**Status**: Background material, normative language now in dartLangSpec.tex.

**Version**: 0.2 (2018-05-22)


This document is a Dart 2 feature specification which specifies how to
compute the standard upper bound and standard lower bound (`SUB` and `SLB`)
of a pair of types when at least one of the operands is an extreme type:
`Object`, `dynamic`, `void`, or `bottom`.


## Motivation

In order to motivate the rules for upper and lower bounds of a pair of
types, we will focus on concrete examples that embody upper bounds very
directly, namely conditional expressions, and extend that to lower bounds
using functions.

For example, can we use the result from the evaluation of `b ?
print('Hello!') : 42`?  In Dart 2, an expression with static type `void` is
considered to have a value which is not valid, and it is a compile-time
error to use it in most situations. When it is one of two possible branches
in a conditional expression (here: `print('Hello!')`) we would expect to
consider the whole value to be not valid, because otherwise we could
receive the value of "the void branch" and thus inadvertently use a value
which is not valid. Based on this kind of reasoning we have chosen to give
expressions like `b ? print('Hello!') : 42` the type `void`.

Similarly, can we do `(b ? 42 : f()).isEven` if `f` has return type
`dynamic`? In this case the result from evaluating the conditional
expression (`?:`) may have any type whatsoever, so `isEven` cannot be
assumed to exist in the interface of that object. On the other hand,
`isEven` could be safely invoked on the result from the branch `42`, and
the other branch would admit arbitrary member access operations (such as
`f().isEven`), even though there is no static evidence for the existence of
any particular members (except for a few members which are declared in
`Object` and hence inherited or overridden for every object). So you could
say "it is OK for both branches, so it must be OK for the expression as a
whole."

Then how about `(b ? 42 : f()).fooBar()` where `f` is again assumed to have
the return type `dynamic`? In this situation we would accept `f().fooBar()`
because `dynamic` receivers admit all member accesses, but `42.fooBar()`
would be rejected. Hence, we might say that "it is not OK for both
branches, hence it is not OK for the conditional expression".

We could give `b ? 42 : f()` the type `int`, which would allow us to accept
`(b ? 42 : f()).isEven` and reject `(b ? 42 : f()).fooBar()`. This would
effectively mean that `dynamic` would be considered to be a subtype of all
other types during computations of upper and lower bounds.

However, we consider that to be such a serious anomaly relative to the rest
of the Dart 2 type system that we have not taken that approach.

Instead, we have chosen to accept that a `dynamic` branch in a conditional
expression will make the whole conditional expression dynamic.

A set of situations with the opposite polarity arise when we consider types
in a contravariant position, e.g., `b ? (T1 t1) => e1 : (T2 t2) => e2`,
where we need to consider various combinations of types as the values of
`T1` and `T2` in order to compute the type of the whole expression.

Ignoring "voidness" and "dynamicness" for a moment and focusing on the pure
subtyping relationships, we apply the _standard upper bound_ function to
the types of the two branches in the former situation (like `b ? e1 : e2`),
and for the latter situation (where an intervening function literal
reverses the polarity, that is, the types in question occur in
contravariant locations) we use the _standard lower bound_ function.

These bound functions take exactly two arguments, so we may also call them
'operators' and the arguments 'operands'.  We call these functions
'standard' rather than 'least' and 'greatest' because the Dart 2 type
language cannot express a true least upper bound and greatest lower bound
of all pairs of types, but it is still useful to choose an approximation
thereof in many cases. We abbreviate the function names to `SUB` and `SLB`.

As long as we are concerned with non-extreme types (everything except the
top and bottom types), these bound functions deliver an approximation of
the least upper bound and the greatest lower bound of its operands. For
instance, `SUB(int, num)` is `num`, and `SLB(int, num)` is `int`, so we get
the type `Object` for `b ? new Object() : 42`, and the type `num
Function(int)` for `b ? (num n) => 41 : (int o) => 4.1`.

This specification is concerned with combining the treatment of the pure
subtyping related properties and the other properties like "dynamicness"
and "voidness". We achieve that by means of a specification of the values
of `SUB` and `SLB` when at least one of their operands is an extreme type.


## Syntax

The grammar is unaffected by this feature.


## Static Analysis

An _extreme type_ is one of the types `Object`, `dynamic`, `void`, and
`bottom`.

Consider a pair of types such that at least one of them is an extreme
type. The value of the functions `SUB` and `SLB` on that pair of types is
then determined by the following rules:

```dart
SUB(T, T) == T, for all T.
SUB(S, T) == SUB(T, S), for all S, T.
SUB(void, T) == void, for all T.
SUB(dynamic, T) == dynamic, for all T != void.
SUB(Object, T) == Object, for all T != void, dynamic.
SUB(bottom, T) == T, for all T.

SLB(T, T) == T, for all T.
SLB(S, T) == SLB(T, S), for all S, T.
SLB(void, T) == T, for all T.
SLB(dynamic, T) == T, for all T != void.
SLB(Object, T) == T, for all T != void, dynamic.
SLB(bottom, T) == bottom, for all T.
```

*Note that this is the same outcome as we would have had if `Object` were a
proper subtype of `dynamic` and `dynamic` were a proper subtype of
`void`. Hence, an easy way to recall these rules would be to think `Object
< dynamic < void`. Here, `<` is a "micro subtype" relationship which is
able to distinguish between the top types, as opposed to the subtype
relationship `<:` which considers the top types to be the same type. For
any relationship involving a non-top type, `<` is the same thing as `<:`.*


## Discussion

We considered a different set of rules as well:

```dart
SUB(T, T) == T, for all T.
SUB(S, T) == SUB(T, S), for all S, T.
SUB(void, T) == void, for all T.
SUB(dynamic, T) == Object, for all T != void, dynamic.
SUB(Object, T) == Object, for all T != void.
SUB(bottom, T) == T, for all T != dynamic.

SLB(T, T) == T, for all T.
SLB(S, T) == SLB(T, S), for all S, T.
SLB(void, dynamic) == Object.
SLB(void, T) == T, for all T != dynamic.
SLB(dynamic, T) == T, for all T != void.
SLB(Object, T) == T, for all T != void, dynamic.
SLB(bottom, T) == bottom, for all T.
```

This set of rules cannot be reduced to any "micro subtype" relationship
where we simply make a choice of how to order the top types and then get
all other results as a consequence of that choice. These alternative rules
are more strict on the propagation of "dynamicness" in a way which may be
helpful for developers. Here is how it works:

The 'Motivation' section mentioned a number of pragmatic reasons why it may
be meaningful to let `SUB(dynamic, int)` be some other type than `dynamic`.

If we take the stance that the relaxed type checks on member accesses that
we apply to `dynamic` receivers are error-prone and hence shouldn't
propagate very far implicitly, we may chose to eliminate the special
treatment of `dynamic`, unless that type is present in all branches.

This means that we would make the invocation `(b ? 42 : f()).isEven` a
compile-time error: We could say that "it is not a dynamic invocation
because some branches do not deliver a dynamic receiver, and there is no
static guarantee that the `isEven` method exists, so the expression is a
compile-time error". This is achieved by means of one of the rules shown
above: `SUB(dynamic, T) == Object, for all T != void, dynamic`.

In order to show that the alternative set of rules has an internal
structure (as opposed to being a random mixture of decisions), we can
describe them in the following manner. First we translate all types into a
tuple-representation:

```dart
void      (1, 1, 0)
dynamic   (1, 0, 1)
Object    (1, 0, 0)
T         (T, 0, 0), for all non-extreme types T
bottom    (0, 0, 0)
```

In this tuple, the first component is the core type (where "voidness" and
"dynamicness" have been erased), where `0` is bottom, `1` is top (that is,
the types `Object`, `dynamic`, and `void`), and every other (non-extreme)
type is itself, e.g., `int` is `int`.

The second component is the "voidness": `1` means that the type is a void
type (there is only `void`), and `0` means non-void.

The third component is the "dynamicness": `1` means that the type is
dynamic (there is only `dynamic`, at least for now), and `0` means
non-dynamic.

This means that the tuple contains one "core type" and two "bits" (boolean
components). With that, we can compute the functions using simple
operations:

```dart
SUB((t1, v1, d1), (t2, v2, d2)) = (lub(t1,t2), v1 || v2, d1 && d2)
SLB((t1, v1, d1), (t2, v2, d2)) = (glb(t1,t2), v1 && v2, d1 && d2)

```

We may also specify the same thing more concisely in a curried form:

```dart
SUB = (lub, lub, glb)
SLB = (glb, glb, glb)
```

where `lub` and `glb` are specialized for the domain of types and booleans,
respectively, but are basically "least upper bound" and "greatest lower 
bound": For types we rely on an underlying notion of upper and lower bounds
for all non-extreme types, and for booleans it is simply the indicated 
operators above (`||` and `&&`, respectively).

It may seem tempting, for symmetry, to change the definitions such that we
get `SLB = (glb, glb, lub)`, but this would introduce types of the form
`(T, 0, 1)`, that is, types like `dynamic(int)` and 
`dynamic(int Function(String))` that we have considered but not yet decided
to introduce. Given that the only effect this change would have is to
change some types in a contravariant location from `Object` to `dynamic`,
and given that this is generally not detectable for clients (e.g., we don't
care about, and actually can't even detect, the difference between calling
a function of type `int Function(Object)` and a function of type `int
Function(dynamic)`), so this choice is not likely to matter much. Also the
fact that the use of `min` yields fewer occurrences of the type `dynamic`
seems to be consistent with the nature of Dart 2 typing.

Note that the operations are reflexive and symmetric by construction, and
they are also likely to be associative, because both `lub` and `glb` are
associative for booleans, and for types we will need to consider the actual
underlying mechanism, but it ought to be associative if at all possible:

```dart
lub(lub(a,b),c) = lub(a,lub(b,c))
glb(glb(a,b),c) = glb(a,glb(b,c))
```

## Updates

*   May 22nd 2018, version 0.2: Adjusted to use `Object < dynamic < void`
    as a "subtyping micro-structure" (which produces a simpler set of
    rules) and mention the rules from version 0.1 merely as a possible
    alternative ruleset.

*   May 1st 2018, version 0.1: Initial version of this feature 
    specification created, based on discussions in SDK issue 28513.
