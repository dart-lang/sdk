# Optional new

Author: eernst@.

Version: 0.3 (2017-09-08)

Status: Under implementation.

**This document** is an informal specification of the *optional new* feature.
**The feature** adds support for omitting the reserved word `new` in instance
creation expressions.

This feature extends and includes the
[optional const feature](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-const.md),
and it is assumed that the reader knows about optional const. Beyond
that, this informal specification is derived from a
[combined proposal](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
which presents optional new together with several other features.


## Motivation

In Dart without optional new, the reserved word `new` is present in every
expression whose evaluation invokes a constructor (except constant
expressions). These expressions are known as *instance creation expressions*. If
`new` is removed from such an instance creation expression, the remaining phrase
is still syntactically correct in almost all cases. The required grammar
update that makes them all syntactically correct is a superset of the one that
is specified for
[optional const](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-const.md).

With that grammar update, all instance creation expressions can technically
omit the `new` because tools (compilers, analyzers) are able to parse these
expressions, and they are able to recognize that they denote instance creations
(rather than, say, static function invocations), because the part before the
left parenthesis is statically known to denote a constructor.

For instance, `p.C.foo` may resolve statically to a constructor named `foo` in
a class `C` imported with prefix `p`. Similarly, `D` may resolve to a class, in
which case `D(42)` is statically known to be a constructor invocation because
the other interpretation is statically known to be incorrect (that is, cf.
section '16.14.3 Unqualified Invocation' in the language specification,
evaluating `(D)(42)`: `(D)` is an instance of `Type` which is not a function
type and does not have a method named `call`).

For human readers, it may be helpful to document that a particular expression
is guaranteed to yield a fresh instance, and this is the most common argument
why `new` should *not* be omitted. However, Dart already allows instance
creation expressions to invoke a factory constructor, so Dart developers never
had any firm local guarantees that any particular expression would yield a
fresh object.

Developers may thus prefer to omit `new` in order to obtain more concise code,
and possibly also in order to achieve greater uniformity among invocations of
constructors and other invocations, e.g., of static or global functions.

With that in mind, this proposal allows instance creation expressions to omit
the `new` in all cases, but also preserves the permission to include `new` in
all cases. It is a matter of style to use `new` in a manner that developers
find helpful.


## Syntax

The syntax changes associated with this feature are the following:

```
postfixExpression ::=
    assignableExpression postfixOperator |
    constructorInvocation |  // NEW
    primary selector*
constructorInvocation ::=  // NEW
    typeName typeArguments '.' identifier arguments
assignableExpression ::=
    SUPER unconditionalAssignableSelector |
    constructorInvocation (arguments* assignableSelector)+ |  // NEW
    identifier |
    primary (arguments* assignableSelector)+
```

*As mentioned, this grammar update is a superset of the grammar updates for
[optional const](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-const.md).*


## Static analysis

We specify a type directed source code transformation which eliminates the
feature by expressing the same semantics with different syntax. The static
analysis proceeds to work on the transformed program.

*Similarly to optional const, this means that the feature is "static semantic
sugar". We do not specify the dynamic semantics for this feature, because the
feature is eliminated in this transformation step.*

We need to treat expressions differently in different locations, hence the
following definition, which is identical to the one in
[optional const](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-const.md):

An expression _e_ is said to *occur in a constant context*,

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

We define *new/const insertion* as the following transformation:

- if the expression _e_ occurs in a constant context, replace _e_ by
  `const` _e_,
- otherwise replace _e_ by `new` _e_.

For the purposes of describing the main transformation we need the following
syntactic entity:

```
assignableExpressionTail ::=
    arguments assignableSelector (arguments* assignableSelector)*
```

An expression on one of the following forms must be modified in top-down
order to be or contain a `constantObjectExpression` or `newExpression`
as described:

With a `postfixExpression` _e_,

- if _e_ is on the form `constructorInvocation`, i.e.,
  `typeName typeArguments '.' identifier arguments` then perform
  new/const insertion on _e_.
- if _e_ is on the form
  `typeIdentifier arguments` where `typeIdentifier` denotes a class then
  perform new/const insertion on _e_.
- if _e_ is on the form
  `identifier1 '.' identifier2 arguments` where `identifier1` denotes
  a class and `identifier2` is the name of a named constructor in that class,
  or `identifier1` denotes a prefix for a library _L_ and `identifier2` denotes
  a class exported by _L_, perform new/const insertion on _e_.
- if _e_ is on the form
  `identifier1 '.' typeIdentifier '.' identifier2 arguments` where
  `identifier1` denotes a library prefix for a library _L_, `typeIdentifier`
  denotes a class _C_ exported by _L_, and `identifier2` is the name of a named
  constructor in _C_, perform new/const insertion on _e_.

With an `assignableExpression` _e_,

- if _e_ is on the form
  `constructorInvocation (arguments* assignableSelector)+`
  then replace _e_ by `new` _e_.
- if _e_ is on the form
  `typeIdentifier assignableExpressionTail`
  where `typeIdentifier` denotes a class then replace _e_ by `new` _e_.
- if _e_ is on the form
  `identifier1 '.' identifier2 assignableExpressionTail`
  where `identifier1` denotes a class and `identifier2` is the name of
  a named constructor in that class, or `identifier1` denotes a prefix
  for a library _L_ and `identifier2` denotes a class exported by _L_
  then replace _e_ by `new` _e_.
- if _e_ is on the form
  `identifier1 '.' typeIdentifier '.' identifier2 assignableExpressionTail`
  where `identifier1` denotes a library prefix for a library _L_,
  `typeIdentifier` denotes a class _C_ exported by _L_, and `identifier2`
  is the name of a named constructor in _C_ then replace _e_ by `new` _e_.

For a list literal _e_ occurring in a constant context, replace _e_ by
`const` _e_. For a map literal _e_ occurring in a constant context,
replace _e_ by `const` _e_.

*In short, add `const` in const contexts and otherwise add `new`. With
`assignableExpression` we always add `new`, because such an expression
can never be a subexpression of a correct constant expression. It is easy
to verify that each of the replacements can be derived from
`postfixExpression` via `primary selector*` and similarly for
`assignableExpression`. Hence, the transformation preserves syntactic
correctness.*


## Dynamic Semantics

There is no dynamic semantics to specify for this feature because it is
eliminated by code transformation.


## Interplay with optional const

This informal specification includes optional const as well as optional new,
that is, if this specification is implemented then
[optional const](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-const.md)
may be considered as background material.


## Revisions

- 0.3 (2017-09-08) Included missing rule for transformation of composite
  literals (lists and maps). Eliminated the notion of an immediate
  subexpression, for improved precision.

- 0.2 (2017-07-30) Updated the document to specify the previously missing
  transformations for `assignableExpression`, and to specify a no-magic
  approach (where no `const` is introduced except when forced by the
  syntactic context).

- 0.1 (2017-08-15) Stand-alone informal specification for optional new created,
  using version 0.8 of the combined proposal
  [optional-new-const.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
  as the starting point.
