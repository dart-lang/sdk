# Feature Specification: Interface Conflict Management

**Owner**: eernst@

**Status**: Background material, normative text is now in dartLangSpec.tex.
Note that the rules have changed, which means that
**this document cannot be used as a reference**, it can only be
used to get an overview of the ideas; please refer to the language
specification for all technical details.

**Version**: 0.3 (2018-04-24)


This document is a Dart 2 feature specification which specifies how to
handle conflicts among certain program elements associated with the
interface of a class. In particular, it specifies that multiple occurrences
of the same generic class in the superinterface hierarchy must receive the
same type arguments, and that no attempts are made at synthesizing a
suitable method signature if multiple distinct signatures are provided by
the superinterfaces, and none of them resolves the conflict.


## Motivation

In Dart 1, the management of conflicts during the computation of the
interface of a class is rather forgiving. On page 42 of
[ECMA-408](https://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf),
we have the following:

> However, if the above rules would cause multiple members
> _m<sub>1</sub>, ..., m<sub>k</sub>_
> with the same name _n_ to be inherited (because identically named
> members existed in several superinterfaces) then at most one member
> is inherited.
>
> ...
>
> Then _I_ has a method named _n_, with _r_ required parameters of type
> `dynamic`, _h_ positional parameters of type `dynamic`, named parameters
> _s_ of type `dynamic` and return type `dynamic`.

In particular, the resulting class interface may then contain a method
signature which has been synthesized during static analysis, and which
differs from all declarations of the given method in the source code.
In the case where some superintenfaces specify some optional positional
parameters and others specify some named parameters, any attempt to
implement the synthesized method signature other than via a user-defined
`noSuchMethod` would fail (it would be a syntax error to declare both
kinds of parameters in the same method declaration).

For Dart 2 we modify this approach such that more emphasis is given to
predictability, and less emphasis is given to convenience: No class
interface will ever contain a method signature which has been
synthesized during static analysis, it will always be one of the method
interfaces that occur in the source code. In case of a conflict, the
developer must explicitly specify how to resolve the conflict.

To reinforce the same emphasis on predictability, we also specify that
it is a compile-time error for a class to have two superinterfaces which
are instantiations of the same generic class with different type arguments.


## Syntax

The grammar remains unchanged.


## Static Analysis

We introduce a new relation among types, _more interface-specific than_,
which is similar to the subtype relation, but which treats top types
differently.

- The built-in class `Object` is more interface-specific than `void`.
- The built-in type `dynamic` is more interface-specific than `void`.
- None of `Object` and `dynamic` is more interface-specific than the other.
- All other subtype rules are also valid rules about being more
  interface-specific.

This means that we will express the complete rules for being 'more
interface-specific than' as a slight modification of
[subtyping.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/subtyping.md)
and in particular, the rule 'Right Top' will need to be split in cases
such that `Object` and `dynamic` are more interface-specific than `void` and
mutually unrelated, and all other types are more interface-specific than
both `Object` and `dynamic`.

*For example, `List<Object>` is more interface-specific than `List<void>`
and incomparable to `List<dynamic>`; similarly, `int Function(void)` is
more interface-specific than `void Function(Object)`, but the latter is
incomparable to `void Function(dynamic)`.*

It is a compile-time error if a class _C_ has two superinterfaces of the
form _D<T<sub>1</sub> .. T<sub>k</sub>>_ respectively
_D<S<sub>1</sub> .. S<sub>k</sub>>_ such that there is a _j_ in _1 .. k_
where _T<sub>j</sub>_ and _S<sub>j</sub>_ denote types that are not
mutually more interface-specific than each other.

*This means that the (direct and indirect) superinterfaces must agree on
the type arguments passed to any given generic class. Note that the case
where the number of type arguments differ is unimportant because at least
one of them is already a compile-time error for other reasons. Also note
that it is not sufficient that the type arguments to a given superinterface
are mutual subtypes (say, if `C` implements both `I<dynamic>` and
`I<Object>`), because that gives rise to ambiguities which are considered
to be compile-time errors if they had been created in a different way.*

This compile-time error also arises if the type arguments are not given
explicitly.

*They might be obtained via
[instantiate-to-bound](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
or, in case such a mechanism is introduced, they might be inferred.*

*The language specification already contains verbiage to this effect, but we
mention it here for two reasons: First, it is a recent change which has been
discussed in the language team together with the rest of the topics in this
document because of their similar nature and motivation. Second, we note
that this restriction may be lifted in the future. It was a change in the
specification which did not break many existing programs because `dart2js`
always enforced that restriction (even though it was not specified in the
language specification), so in that sense it just made the actual situation
explicit. However, it may be possible to lift the restriction: Given that an
instance of a class that has `List<int>` among its superinterfaces can be
accessed via a variable of type `List<num>`, it seems unlikely that it would
violate any language invariants to allow the class of that instance to have
both `List<int>` and `List<num>` among its superinterfaces. We may then
relax the rule to specify that for each generic class _G_ which occurs among
superinterfaces, there must be a unique superinterface which is the most
specific instantiation of _G_.*

During computation of the interface of a class _C_, it may be the case that
multiple direct superinterfaces have a declaration of a member of the same
name _n_, and class _C_ does not declare member named _n_.
Let _D<sub>1</sub> .. D<sub>n</sub>_ denote this set of declarations.

It is a compile-time error if some declarations among
_D<sub>1</sub> .. D<sub>n</sub>_ are getters and others are non-getters.

Otherwise, if all of _D<sub>1</sub> .. D<sub>n</sub>_ are getter
declarations, the interface of _C_ inherits one, _D<sub>j</sub>_, whose
return type is more interface-specific than that of every declaration in
_D<sub>1</sub> .. D<sub>n</sub>_. It is a compile-time error if no such
_D<sub>j</sub>_ exists.

*For example, it is an error to have two declarations with the signatures
`Object get foo` and `dynamic get foo`, and no others, because none of
these is more interface-specific than the other. This example illustrates
why it is unsatisfactory to rely on subtyping alone: If we had accepted
this kind of ambiguity then it would be difficult to justify the treatment
of `o.foo.bar` during static analysis where `o` has type _C_: If it is
considered to be a compile-time error then `dynamic get foo` is being
ignored, and if it is not an error then `Object get foo` is being ignored,
and each of these behaviors may be surprising and/or error-prone. Hence, we
require such a conflict to be resolved explicitly, which may be done by
writing a signature in the class which overrides both method signatures
from the superinterfaces and explicitly chooses `Object` or `dynamic`.*

Otherwise, (*when all declarations are non-getter declarations*), the
interface of _C_ inherits one, _D<sub>j</sub>_, where its function type is
more interface-specific than that of all declarations in
_D<sub>1</sub> .. D<sub>n</sub>_. It is a compile-time error if no such
declaration _D<sub>j</sub>_ exists.

*In the case where more than one such declaration exists, it is known that
their parameter list shapes are identical, and their return types and
parameter types are pairwise mutually more interface-specific than each
other (i.e., for any two such declarations _D<sub>i</sub>_ and _D<sub>j</sub>_,
if _U<sub>i</sub>_ is the return type from _D<sub>i</sub>_ and
_U<sub>j</sub>_ is the return type from _D<sub>j</sub>_ then
_U<sub>i</sub>_ is more interface-specific than _U<sub>j</sub>_ and
vice versa, and similarly for each parameter type). This still allows for
some differences. We ignore differences in metadata on formal parameters
(we do not consider method signatures in interfaces to have metadata). But
we need to consider one more thing:*

In this decision about which declaration among
_D<sub>1</sub> .. D<sub>n</sub>_
the interface of the class _C_ will inherit, if we have multiple possible
choices, let _D<sub>i</sub>_ and _D<sub>j</sub>_ be such a pair of possible
choices. It is a compile-time error if _D<sub>i</sub>_ and _D<sub>j</sub>_
declare two optional formal parameters _p<sub>1</sub>_ and _p<sub>2</sub>_
such that they correspond to each other (*same name if named, or else same
position*) and they specify different default values.


## Discussion

Conflicts among distinct top types may be considered to be spurious in the
case where said type occurs in a contravariant position in the method
signature. Consider the following example:

```dart
abstract class I1 {
  void foo(dynamic d);
}

abstract class I2 {
  void foo(Object o);
}

abstract class C implements I1, I2 {}
```

In both situations&mdash;when `foo` accepts an argument of type `dynamic`
and when it accepts an `Object`&mdash;the acceptable actual arguments are
exactly the same: _Every_ object can be passed. Moreover, the formal
parameters `d` and `o` are not in scope anywhere, so there will never be
an expression like `d.bar` or `o.bar` which is allowed respectively
rejected because the receiver is or is not `dynamic`. In other words,
_it does not matter_ for clients of `C` whether that argument type is
`dynamic` or `Object`.

During inference, the type-from-context for an actual argument to `foo`
will depend on the choice: It will be `dynamic` respectively `Object`.
However, this choice will not affect the treatment of the actual
argument.

One case worth considering is the following:

```dart
abstract class I1 {
  void foo(dynamic f());
}

abstract class I2 {
  void foo(Object f());
}
```

If a function literal is passed in at a call site, it may have its return
type inferred to `dynamic` respectively `Object`. This will change the
type-from-context for any returned expressions, but just like the case
for the actual parameter, that will not change the treatment of such
expressions. Again, it does not matter for clients calling `foo` whether
that type is `dynamic` or `Object`.

Conversely, the choice of top type matters when it is placed in a
contravariant location in the parameter type:

```dart
abstract class I1 {
  void foo(int f(dynamic d));
}

abstract class I2 {
  void foo(int f(Object o));
}
```

In this situation, a function literal used as an actual argument at a call
site for `foo` would receive an inferred type annotation for its formal
parameter of `dynamic` respectively `Object`, and the usage of that parameter
in the body of the function literal would then differ. In other words, the
developer who declares `foo` may decide whether the code in the body of the
function literal at the call sites should use strict or relaxed type
checking&mdash;and it would be highly error-prone if this decision were
to be made in a way which is unspecified.

All in all, it may be useful to "erase" all top types to `Object` when they
occur in contravariant positions in method signatures, such that the
differences that may exist do not create conflicts; in contrast, the top
types that occur in covariant positions are significant, and hence the fact
that we require such conflicts to be resolved explicitly is unlikely to be
relaxed.

## Updates

*   Apr 24th 2018, version 0.3: Renamed 'override-specific' to
    'interface-specific', to avoid giving the impression that it can be
    used to determine whether a given signature can override another one
    (the override check must use different rules, e.g., it must allow
    `dynamic foo();` to override `Object foo();` _and_ vice versa).

*   Apr 16th 2018, version 0.2: Introduced the relation 'more
    override-specific than' in order to handle top types more consistently
    and concisely.

*   Feb 8th 2018, version 0.1: Initial version.
