# Optional const

Author: eernst@.

Version: 0.3 (2017-09-08)

Status: Under implementation.

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
certain other expressions to be constant, e.g., initializing expressions for
constant variables.

In all these cases the presence of `const` is required, and hence such a
`const` may be inferred by compilers and similar tools if it is omitted.

Developers reading the source code are likely to find it easy to understand
that a required `const` was omitted and is implied, because the reason for
the requirement is visible in the enclosing syntax: The expression where
`const` is inferred is a subexpression of an expression with `const` or it
is used in another situation where a constant value is required, e.g., to
initialize a constant variable.

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
```

*The grammar only needs to be adjusted for one case, namely invocations of named
constructors for generic classes. In this case we can derive expressions like
`const Foo<int>.bar()`, and the corresponding `Foo<int>.bar()` is not derivable
in the same situations where the variant with `const` can be derived. In other
words, we must add support for constructs like `Foo<int>.bar()` as part of a
`postfixExpression`. For all other situations, the variant with `const` becomes
a construct which is already syntactically correct Dart when the `const` is
removed. For instance `const C(42)` becomes `C(42)` which is already allowed
syntactically (it could be a function invocation).*

## Static analysis

We specify a type directed source code transformation which eliminates the
feature. The static analysis proceeds to work on the transformed program.

*This means that the feature is "sugar", but because of the need to refer
to types it could be described as static semantic sugar rather than
syntactic sugar. We do not specify the dynamic semantics for this feature,
because the feature is eliminated in this transformation step.*

We need to treat expressions differently in different locations, hence the
following definition: An expression _e_ is said to *occur in a constant
context*,

- if _e_ is an element of a constant list literal, or a key or value of
  an entry of a constant map literal.
- if _e_ is an actual argument of a constant object expression or of a
  metadata annotation.
- if _e_ is the initializing expression of a constant variable declaration.
- if _e_ is a switch case expression.
- if _e_ is an immediate subexpression of an expression _e1_ which occurs in
  a constant context, unless _e1_ is a `throw` expression or a function
  literal.

*This roughly means that everything which is inside a syntactically
constant expression is in a constant context. A `throw` expression is
currently not allowed in a constant expression, but extensions affecting
that status may be considered. A similar situation arises for function
literals.*

*Note that the default value of an optional formal parameter is not a
constant context. This choice reserves some freedom to modify the
semantics of default values.*

An expression on one of the following forms must be modified in top-down order
to be or contain a `constantObjectExpression` as described:

With a `postfixExpression` _e_ occurring in a constant context,

- if _e_ is on the form `constructorInvocation` then replace _e_ by
  `const` _e_.
- if _e_ is on the form
  `typeIdentifier arguments` where `typeIdentifier` denotes a class then
  replace _e_ by `const` _e_.
- if _e_ is on the form
  `identifier1 '.' identifier2 arguments` where `identifier1` denotes
  a class and `identifier2` is the name of a named constructor in that
  class, or `identifier1` denotes a prefix for a library _L_ and
  `identifier2` denotes a class exported by _L_, replace _e_ by
  `const` _e_.
-  if _e_ is on the form
  `identifier1 '.' typeIdentifier '.' identifier2 arguments` where
  `identifier1` denotes a library prefix for a library _L_,
  `typeIdentifier` denotes a class _C_ exported by _L_, and `identifier2`
  is the name of a named constructor in _C_, replace _e_ by
  `const` _e_.

For a list literal _e_ occurring in a constant context, replace _e_ by 
`const` _e_. For a map literal _e_ occurring in a constant context,
replace _e_ by `const` _e_.

*In short, in these specific situations: "just add `const`". It is easy to
verify that each of the replacements can be derived from
`constObjectExpression`, which can be derived from `postfixExpression` via
`primary selector*`. Hence, the transformation preserves syntactic
correctness.*

The remaining static analysis proceeds to work on the transformed program.

*It is possible that this transformation will create
`constObjectExpressions` which violate the constraints on constant object
expressions, e.g., when `const [[new A()]]` is transformed to
`const [const [new A()]]` where the inner list is an error that was created
by the transformation (so the error was moved from the outer to the inner
list). It is recommended that the error messages emitted by tools in response
to such violations include information about the transformation.*

## Dynamic Semantics

There is no dynamic semantics to specify for this feature because it is
eliminated by code transformation.


## Revisions

- 0.3 (2017-09-08) Eliminated the notion of an immediate subexpression,
  for improved precision.

- 0.2 (2017-08-30) Updated the document to specify the previously missing
  transformations for composite literals (lists and maps), and to specify a
  no-magic approach (where no `const` is introduced except when forced by
  the syntactic context).

- 0.1 (2017-08-10) Stand-alone informal specification for optional const
  created, using version 0.8 of the combined proposal
  [optional-new-const.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
  as the starting point.
