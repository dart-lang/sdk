# Implicit Creation

Author: eernst@.

Version: 0.5 (2018-01-04)

Status: Under implementation.

**This document** is an informal specification of the *implicit creation* feature.
**The feature** adds support for omitting some occurrences of the reserved words
`new` and `const` in instance creation expressions.

This feature specification was written with a
[combined proposal](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/optional-new-const.md)
as the starting point. That proposal presents optional new and optional const
together with several other features.


## Motivation

In Dart without implicit creation, the reserved word `new` is present in
almost all expressions whose evaluation invokes a constructor at run time,
and `const` is present in the corresponding constant expressions. These
expressions are known as *instance creation expressions*. If `new` or
`const` is removed from such an instance creation expression, the remaining
phrase is still syntactically correct in most cases. This feature
specification updates the grammar to make them all syntactically correct.

With that grammar update, all instance creation expressions can technically
omit `new` or `const` because tools (compilers, analyzers) are able to
parse these expressions.  The tools are able to recognize that these
expressions denote instance creations (rather than, say, static function
invocations), because the part before the arguments is statically known to
denote a constructor.

For instance, `p.C.foo` may resolve statically to a constructor named `foo` in
a class `C` imported with prefix `p`. Similarly, `D` may resolve to a class, in
which case `D(42)` is statically known to be a constructor invocation because
the other interpretation is statically known to be incorrect (that is, cf.
section '16.14.3 Unqualified Invocation' in the language specification,
evaluating `(D)(42)`: `(D)` is an instance of `Type` which is not a function
type and does not have a method named `call`, so we cannot call `(D)`).

In short, even without the keyword, we can still unambiguously recognize the
expressions that create objects. In that sense, the keywords are superfluous.

For human readers, however, it may be helpful to document that a particular
expression will yield a fresh instance, and this is the most common argument why
`new` should *not* be omitted: It can be good documentation. But Dart already
allows instance creation expressions to invoke a factory constructor, which is
not guaranteed to return a newly created object, so Dart developers never had
any firm local guarantees that any particular expression would yield a fresh
object. This means that it may very well be justified to have an explicit `new`,
but it will never be a rigorous guarantee of freshness.

Similarly, it may be important for developers to ensure that certain expressions
are constant, because of the improved performance and the guaranteed
canonicalization. This is a compelling argument in favor of making certain
instance creation expressions constant: It is simply a bug for that same
expression to have `new` because object identity is an observable
characteristic, and it may be crucial for performance that the expression is
constant.

In summary, both `new` and `const` may always be omitted from an instance
creation expression, but it is useful and reasonable to allow an explicit `new`,
and it is necessary to allow an explicit `const`. Based on that line of
reasoning, we've decided to make them optional. It will then be possible for
developers to make many expressions considerably more concise, and they can
still enforce the desired semantics as needed.

Obviously, this underscores the importance of the default: When a given instance
creation expression omits the keyword, should it be `const` or `new`?

**For instance creation expressions we have chosen** to use `const` whenever
possible, and otherwise `new`.

This implies that `const` is the preferred choice for instance creation. There
is a danger that `const` is chosen by default in some cases where this is not
intended by the developer, and the affected software will have bugs which are
hard to spot. In particular, `e1 == e2` may evaluate to true in cases where it
would have yielded false with `new` objects.

We consider that danger to be rather small, because `const` can only be chosen
in cases where the denoted constructor is constant, and with a class with a
constant constructor it is necessary for developers to treat all accesses to its
instances in such a way that the software will still work correctly even when
any given instance was obtained by evaluation of a constant expression. The
point is that, for such a class, we can never know for sure that any given
instance is _not_ a constant object.

With composite literals such as lists and maps, a `const` modifier may be
included in order to make it a constant expression (which will of course fail if
it contains something which is not a constant expression). In this case the
presence of `const` may again be crucial, for the same reasons as with an
instance creation expression, but it may also be crucial that `const` is _not_
present, because the list or map will be mutated.

**For composite literals we have chosen** to implicitly introduce `const`
whenever it is required by the context.

The choice to include `const` only when required by context (rather than
whenever possible) is strictly less aggressive than the approach with instance
creations. This choice is necessary because there is no way for developers to
ensure that a literal like `[1, 2]` is mutable, if permitted by the context,
other than omitting `const`.  Furthermore, we expect this choice to be
convenient in practice, because mutable data structures are used frequently. So
developers must expect to write an explicit `const` on composite literals now
and then.

In summary, the implicit creation feature allows for concise construction of
objects, with a slight preference for constant expressions, and it still allows
developers to explicitly specify `new` or `const`, whenever needed and whenever
it is considered to be good documentation.


## Syntax

The syntax changes associated with this feature are the following:

```
postfixExpression ::=
    assignableExpression postfixOperator |
    constructorInvocation selector* |  // NEW
    primary selector*
constructorInvocation ::=  // NEW
    typeName typeArguments '.' identifier arguments
assignableExpression ::=
    SUPER unconditionalAssignableSelector |
    constructorInvocation assignableSelectorPart+ |  // NEW
    identifier |
    primary assignableSelectorPart+
assignableSelectorPart ::=
    argumentPart* assignableSelector
```


## Static analysis

We specify a type directed source code transformation which eliminates the
feature by expressing the same semantics with different syntax. The static
analysis proceeds to work on the transformed program.

*This means that the feature is "static semantic sugar". We do not specify the
dynamic semantics for this feature, because the feature is eliminated in this
transformation step.*

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
constant expression is in a constant context. Note that a `const` modifier
which is introduced by the source code transformation does not create a
constant context, it is only the explicit occurrences of `const` in the
program that create a constant context. Also note that a `throw` expression
is currently not allowed in a constant expression, but extensions affecting
that status may be considered. A similar situation arises for function
literals.*

The transformation consists of two steps. In the first step, every literal
list and literal map _e_ which occurs in a constant context and does not
have the modifier `const` is replaced by `const` _e_.

We define *new/const insertion* as the following transformation, which will
be applied to specific parts of the program as specified below:

- if the expression _e_ occurs in a constant context, replace _e_ by
  `const` _e_,
- if the expression _e_ does not occur in a constant context, but `const`
  _e_ is a correct constant expression, replace _e_ by `const` _e_,
- otherwise replace _e_ by `new` _e_.

*Note that this transformation is applied in a bottom-up order which implies
that all relevant transformations have already been applied on subexpressions
of _e_. Also note that this transformation is only applied to syntactic
constructs where the outcome is a syntactically correct instance creation
expression. On the other hand, the outcome may have static semantic errors,
e.g., actual arguments to a constructor invocation may have wrong types
because that's how the program was written.*

We define *new insertion* as the following transformation, which will be
applied as specified below:

- replace _e_ by `new` _e_.

*We specify the second step of the transformation as based on a depth-first
traversal of an abstract syntax tree (AST). This means that the program is
assumed to be free of syntax errors, and when the current AST is, e.g., a
`postfixExpression`, the program as a whole has such a structure that the
current location was parsed as a `postfixExpression`. This is different
from the situation where we just require that a given subsequence of the
tokens of the program allows for such a parsing in isolation. For instance,
an identifier like `x` parses as an `assignableExpression` in isolation,
but if it occurs in the context `var x = 42;` or `var y = x;` then it will
not be parsed as an `assignableExpression`, it will be parsed as a plain
`identifier` which is part of a `declaredIdentifier` in the first case, and
as a `primary` which is a `postfixExpression`, which is a
`unaryExpression`, etc., in the second case. In short, we are transforming
the AST of the program as a whole, not isolated snippets of code.*

*In scientific literature, this kind of transformation is commonly
specified as an inductive transformation where `[[e1 e2]] = [[e1]] [[e2]]`
when the language supports a construct of the form `e1 e2`, etc. The reader
may prefer to view the transformation in that light, and we would then say
that we have omitted all the congruence rules.*

An expression of one of the following forms must be modified in bottom-up
order to be or contain a `constantObjectExpression` or `newExpression`
as described:

With a `postfixExpression` _e_,

- if _e_ is of the form `constructorInvocation selector*`, i.e.,
  `typeName typeArguments '.' identifier arguments selector*` then perform
  new/const insertion on the initial `constructorInvocation`.
- if _e_ is of the form
  `typeIdentifier arguments` where `typeIdentifier` denotes a class then
  perform new/const insertion on _e_.
- if _e_ is of the form
  `identifier1 '.' identifier2 arguments` where `identifier1` denotes
  a class and `identifier2` is the name of a named constructor in that class,
  or `identifier1` denotes a prefix for a library _L_ and `identifier2` denotes
  a class exported by _L_, perform new/const insertion on _e_.
- if _e_ is of the form
  `identifier1 '.' typeIdentifier '.' identifier2 arguments` where
  `identifier1` denotes a library prefix for a library _L_, `typeIdentifier`
  denotes a class _C_ exported by _L_, and `identifier2` is the name of a named
  constructor in _C_, perform new/const insertion on _e_.

For the purposes of describing the transformation on assignable expressions
we need the following syntactic entity:

```
assignableExpressionTail ::=
    arguments assignableSelector assignableSelectorPart*
```

With an `assignableExpression` _e_,

- if _e_ is of the form
  `constructorInvocation assignableSelectorPart+`
  then perform new/const insertion on the initial
  `constructorInvocation`.
- if _e_ is of the form
  `typeIdentifier assignableExpressionTail`
  where `typeIdentifier` denotes a class then perform new/const insertion on
  the initial `typeIdentifier arguments`.
- if _e_ is of the form
  `typeIdentifier '.' identifier assignableExpressionTail`
  where `typeIdentifier` denotes a class and `identifier` is the name of
  a named constructor in that class, or `typeIdentifier` denotes a prefix
  for a library _L_ and `identifier` denotes a class exported by _L_
  then perform new/const insertion on the initial
  `typeIdentifier '.' identifier arguments`.
- if _e_ is of the form
  `typeIdentifier1 '.' typeIdentifier2 '.' identifier assignableExpressionTail`
  Where `typeIdentifier1` denotes a library prefix for a library _L_,
  `typeIdentifier2` denotes a class _C_ exported by _L_, and `identifier`
  is the name of a named constructor in _C_ then perform new/const insertion
  on the initial
  `typeIdentifier1 '.' typeIdentifier2 '.' identifier arguments`.

*In short, add `const` wherever possible on terms that invoke a
constructor, and otherwise add `new`. It is easy to verify that each of the
replacements can be derived from `postfixExpression` via `primary
selector*` and similarly for `assignableExpression`. Hence, the
transformation preserves syntactic correctness.*


## Dynamic Semantics

There is no dynamic semantics to specify for this feature because it is
eliminated by code transformation.


## Revisions

- 0.5 (2018-01-04) Rewritten to use `const` whenever possible (aka "magic
  const") and adjusted to specify optional const as well as optional new
  together, because they are now very closely connected. This document was
  renamed to 'implicit-creation.md', and the document 'optional-const.md'
  was deleted.

- 0.4 (2017-10-17) Reverted to use 'immediate subexpression' again, for
  correctness. Adjusted terminology for consistency. Clarified the semantics
  of the transformation.

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
