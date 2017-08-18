# Optional new

Author: eernst@.

Version: 0.1 (2017-08-15)

Status: Under discussion

**This document** is an informal specification of the *optional new* feature.
**The feature** adds support for omitting the reserved word `new` in instance
creation expressions.

This feature relies on
[optional const](https://gist.github.com/eernstg/4f498836e73d5f003928e8bbe1683d68),
and it is assumed that the reader knows the optional const feature. Otherwise,
this informal specification is derived from a
[combined proposal](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
which presents optional new and several other features.

## Motivation

In Dart without optional new, the reserved word `new` is present in every
expression whose evaluation invokes a constructor (except constant
expressions). These expressions are known as *instance creation expressions*. If
`new` is removed from such an instance creation expression, the remaining phrase
is still syntactically correct in almost all cases, and the required grammar
update that makes them all syntactically correct is exactly the one that is
specified for
[optional const](https://gist.github.com/eernstg/4f498836e73d5f003928e8bbe1683d68).

Assuming the grammar update in
[optional const](https://gist.github.com/eernstg/4f498836e73d5f003928e8bbe1683d68),
all instance creation expressions can technically omit the `new` because tools
(compilers, analyzers) are able to parse these expressions, and they are able
to recognize that they denote instance creations (rather than, say, static
function invocations), because the part before the left parenthesis is
statically known to denote a constructor.

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
had any local guarantees that any particular expression would yield a fresh
object.

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
    typeName typeArguments '.' identifier arguments
        (arguments* assignableSelector)+ |  // NEW
    identifier |
    primary (arguments* assignableSelector)+
```

This grammar update is identical to the grammar update for optional const.
For more information including a complete grammar, please consult 
[that specification](https://gist.github.com/eernstg/4f498836e73d5f003928e8bbe1683d68).

## Static analysis

We specify a type directed source code transformation which eliminates the 
feature. The static analysis proceeds to work on the transformed program.

*Similarly to optional const, this means that the feature is "static semantic
sugar". We do not specify the dynamic semantics for this feature, because the
feature is eliminated in this transformation step.*

We need to treat expressions differently in different locations, hence the
following definition: An expression _e_ is said to *occur in a constant
context*,

- if _e_ is an immediate subexpression of a constant list literal or a constant
  map literal.
- if _e_ is an immediate subexpression of a constant object expression.
- if _e_ is the initializing expression of a constant variable declaration.
- if _e_ is the default value of a formal parameter. **[This case is under discussion and may be removed]**
- if _e_ is an immediate subexpression of an expression which occurs in a
  constant context.

We define *new/const insertion* as the following transformation:

- if _e_ occurs in a constant context, replace `e` by `const e`.
- otherwise, replace `e` by `new e`

An expression on one of the following forms must be modified to be or
contain a `constantObjectExpression` or `newExpression` as described:

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
-  if _e_ is on the form
  `identifier1 '.' typeIdentifier '.' identifier2 arguments` where 
  `identifier1` denotes a library prefix for a library _L_, `typeIdentifier`
  denotes a class _C_ exported by _L_, and `identifier2` is the name of a named
  constructor in _C_, perform new/const insertion on _e_.

## Dynamic Semantics

There is no dynamic semantics to specify for this feature because it is
eliminated by code transformation.

## Interplay with optional const

The optional new and optional const feature can easily be introduced at the same
time: Just update the grammar as specified for optional const (and mentioned
again here) and use the program transformation specified in this document. The
program transformation in this document subsumes the program transformation
specified for optional const, and hence this will provide support for both
features.

## Revisions

- 0.1 (2017-08-15) Stand-alone proposal for optional new created, using version
  0.8 of the combined proposal
  [optional-new-const.md](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
  as the starting point.
