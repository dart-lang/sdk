# Optional const

Author: eernst@.

Version: 0.1 (2017-08-10)

Status: Under discussion

**This document** is an informal specification of the *optional const* feature.
**The feature** adds support for omitting the reserved word `const` in list and
map literals and constant object expressions, in locations where `const` is
currently required.

This informal specification is built on a
[combined proposal](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
which presents optional const and several other features.

## Motivation

In Dart without optional const, complex constant expressions often contain many
occurrences of `const` on list and map literals, and on constant object
expressions. Subexpressions of constant expressions are themselves required to
be constant expressions, and this means that `const` on a nested list or map
literal provides no extra information: It is a compile-time error if that
`const` is omitted. Similarly, it is a compile-time error if a nested constant
object expression is modified to use `new` rather than `const`. In that
situation it carries no extra information whether `new` or `const` is used, and
it is even possible to omit the reserved word entirely. It is also required for
certain other expressions to be constant, e.g., default values on formal
parameters and initializing expressions for constant variables.

In all these cases the presence of `const` is required, and hence such a
`const` may be inferred by compilers and similar tools if it is omitted.

Developers reading the source code are likely to find it easy to understand
that a required `const` was omitted and is implied, because the reason for
the requirement is visible in the enclosing syntax: The expression where
`const` is inferred is a subexpression of an expression with `const`, it is
used to initialize a constant variable, or it is a default value for a formal
parameter.

In summary, tools do not need the required occurrences of `const`, and they
are also unimportant for developers. Conversely, omitting required occurrences
of `const` will sometimes make large expressions substantially more concise
and readable, and also more convenient to write. Here is an example:

```dart
const myMap = const {
  "a": const [const C("able"), const C("apple"), const C("axis")],
  "b": const [const C("banana"), const C("bold"), const C("burglary")],
};
```

Removing the required occurrences of `const` yields the following:

```dart
const myMap = {
  "a": [C("able"), C("apple"), C("axis")],
  "b": [C("banana"), C("bold"), C("burglary")],
};
```

This proposal specifies that these previously required occurrences of `const`
can be omitted, and will then be inferred.

For a more detailed discussion and motivation, please consult the
[combined proposal](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
which covers optional const as well as several other proposals. That document
was the starting point for this informal specification.

## Syntax

In order to support the optional const feature, the Dart grammar is modified as
follows.

```
postfixExpression ::=
    assignableExpression postfixOperator |
    constructorInvocation |  // NEW
    primary selector*
constructorInvocation ::=  // NEW
    typeName typeArguments '.' identifier arguments
assignableExpression ::=
    SUPER unconditionalAssignableSelector |
    typeName typeArguments '.' identifier arguments
        (arguments* assignableSelector)+ |  // NEW
    identifier |
    primary (arguments* assignableSelector)+
```

*A complete grammar which includes these changes is available
[here](https://gist.github.com/eernstg/024a997f4f8c7ef885d459c3703a35f6).*

*Note that the alternative which is added in the rule for `assignableExpression`
is required in order to allow expressions which are obtained by constructing a
constant object expression in Dart without optional const and removing the
`const`. That particular case will not match any of the cases where the `const`
is required (because `assignableExpression` is only used in contexts which
cannot be constant expressions). However, this approach yields syntactic support
for omitting `const` in every `constantObjectExpression`, and it also allows for
omitting `new` from every `newExpression`, which is useful for the
associated
[optional new feature](https://gist.github.com/eernstg/7e819b44acd8dd9d71f0cc510b618a3d).*

*The grammar only needs to be adjusted for one case, namely invocations of named
constructors for generic classes. In this case we can derive expressions like
`const Foo<int>.bar()`, and the corresponding `Foo<int>.bar()` is not derivable
in the same situations where the variant with `const` can be derived. In other
words, we must add support for constructs like `Foo<int>.bar()` as part of a
`postfixExpression` and as part of an `assignableExpression`. For all other
situations, the variant with `const` becomes a construct which is already
syntactically correct Dart when the `const` is removed. For instance `const
C(42)` becomes `C(42)` which could already be a function invocation and is hence
already allowed syntactically.*

## Static analysis

We specify a type directed source code transformation which eliminates the 
feature. The static analysis proceeds to work on the transformed program.

*This means that the feature is "sugar", but because of the need to refer
to types it could be described as static semantic sugar rather than
syntactic sugar. We do not specify the dynamic semantics for this feature,
because the feature is eliminated in this transformation step.*

An expression on one of the following forms must be modified to be or
contain a `constantObjectExpression` as described:

With a `postfixExpression` _e_,

- if _e_ is on the form `constructorInvocation`, i.e.,
  `typeName typeArguments '.' identifier arguments` then replace _e_ by
  `'const' typeName typeArguments '.' identifier arguments`.
- if _e_ is on the form
  `typeIdentifier arguments` where `typeIdentifier` denotes a class then
  replace _e_ by
  `'const' typeIdentifier arguments`.
- if _e_ is on the form
  `identifier1 '.' identifier2 arguments` where `identifier1` denotes
  a class and `identifier2` is the name of a named constructor in that class,
  or `identifier1` denotes a prefix for a library _L_ and `identifier2` denotes
  a class exported by _L_, replace _e_ by
  `'const' identifier1 '.' identifier2 arguments`.
-  if _e_ is on the form
  `identifier1 '.' typeIdentifier '.' identifier2 arguments` where 
  `identifier1` denotes a library prefix for a library _L_, `typeIdentifier`
  denotes a class _C_ exported by _L_, and `identifier2` is the name of a named
  constructor in _C_, replace _e_ by
  `'const' identifier1 '.' typeIdentifier '.' identifier2 arguments`.

*In short, in these specific situations: "just add `const`". It is easy to
verify that each of the replacements can be derived from
`constObjectExpression`, which can be derived from `postfixExpression` via
`primary selector*`; hence the transformation preserves syntactic correctness.*

The remaining static analysis proceeds to work on the transformed program.

*It is possible that this transformation will create
`constObjectExpressions` which violate the constraints on constant object
expressions. It is recommended that the error messages emitted by tools in
response to such violations include information about the transformative
step that added this `const` to the given construct and informs developers
that they may add `new` explicitly if that matches the intention.*

## Dynamic Semantics

There is no dynamic semantics to specify for this feature because it is
eliminated by code transformation.


## Revisions

- 0.1 (2017-08-10) Stand-alone proposal for optional const created, using
  version 0.8 of the combined proposal
  [optional-new-const.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
  as the starting point.
