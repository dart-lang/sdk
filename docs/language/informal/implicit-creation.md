# Implicit Creation

Author: eernst@.

Version: 0.7 (2018-04-10)

Status: Background material, normative language now in dartLangSpec.tex.

**This document** is an informal specification of the *implicit creation*
feature. **The feature** adds support for omitting some occurrences of the
reserved words `new` and `const` in instance creation expressions.

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

Obviously, this underscores the importance of the default: When a given
instance creation expression omits the keyword, should it be `const` or
`new`?

**As a general rule** `const` is used whenever it is required, and
otherwise `new` is used. This requirement arises from the syntactic
context, based on the fact that a non-constant expression would be a
compile-time error.

In summary, the implicit creation feature allows for concise construction
of objects, and it still allows developers to explicitly specify `new` or
`const`, whenever needed and whenever it is considered to be good
documentation.


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
constant expression or declaration is in a constant context. Note that a
`const` modifier which is introduced by the source code transformation does
not create a constant context, it is only the explicit occurrences of
`const` in the program that create a constant context. Also note that a
`throw` expression is currently not allowed in a constant expression, but
extensions affecting that status may be considered. A similar situation
arises for function literals.*

*A formal parameter may have a default value, which must be a constant
expression. We have chosen to not put such default values into a constant
context. They must be constant, and it may be necessary to add the keyword
`const` in order to make them so. This may seem inconvenient at times, but
the rationale is that it allows for future generalizations of default value
expressions allowing them to be non-constant. Still, there is no guarantee
that such features will be added to Dart.*

*For a class which contains a constant constructor and an instance variable
which is initialized by an expression _e_, it is a compile-time error if
_e_ is not constant. We have chosen to not put such initializers into a
constant context, and hence an explicit `const` may be required. This may
again seem inconvenient at times, but the rationale is that the reason for
the constancy requirement is non-local (the constant constructor
declaration may be many lines away from the instance variable declaration);
it may break programs in surprising and confusing ways if a constructor is
changed to be constant; and it may cause subtle bugs at run time due to the
change in identity, if such a change is made and it does not cause any
compile-time errors.*

We define *new/const insertion* as the following transformation, which will
be applied to specific parts of the program as specified below:

- if the expression _e_ occurs in a constant context, replace _e_ by
  `const` _e_,
- otherwise replace _e_ by `new` _e_.

*Note that new/const insertion is just a syntactic transformation, it is
specified below where to apply it, including which syntactic constructs may
play the role of _e_.*

*Also note that the outcome of new/const insertion may have static semantic
errors, e.g., actual arguments to a constructor invocation may have wrong
types because that's how the program was written, or a `const` list may
have elements which are not constant expressions. In such cases, tools like
analyzers and compilers should emit diagnostic messages that are meaningful
in relation to the original source of the program, which might mean that
the blame is assigned to a larger syntactic construct than the one that
directly has a compile-time error after the transformation.*

*We specify the transformation as based on a depth-first traversal of an
abstract syntax tree (AST). This means that the program is assumed to be
free of syntax errors, and when the current AST is, e.g., a
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

For the purposes of describing the transformation on assignable expressions
we need the following syntactic entity:

```
assignableExpressionTail ::=
    arguments assignableSelector assignableSelectorPart*
```

The transformation proceeds as follows, with three groups of situations
where a transformation is applied:

1.  With a `postfixExpression` _e_,

    - if _e_ is of the form `constructorInvocation selector*`, i.e.,
      `typeName typeArguments '.' identifier arguments selector*` then
      perform new/const insertion on the initial `constructorInvocation`.
    - if _e_ is of the form `typeIdentifier arguments` where
      `typeIdentifier` denotes a class then perform new/const insertion on
      _e_.
    - if _e_ is of the form `identifier1 '.' identifier2 arguments` where
      `identifier1` denotes a class and `identifier2` is the name of a
      named constructor in that class, or `identifier1` denotes a prefix
      for a library _L_ and `identifier2` denotes a class exported by _L_,
      perform new/const insertion on _e_.
    - if _e_ is of the form 
      `identifier1 '.' typeIdentifier '.' identifier2 arguments`
      where `identifier1` denotes a library prefix for a library _L_,
      `typeIdentifier` denotes a class _C_ exported by _L_, and
      `identifier2` is the name of a named constructor in _C_, perform
      new/const insertion on _e_.

2.  With an `assignableExpression` _e_,

    - if _e_ is of the form
      `constructorInvocation assignableSelectorPart+`
      then perform new/const insertion on the initial
      `constructorInvocation`.
    - if _e_ is of the form `typeIdentifier assignableExpressionTail` where
      `typeIdentifier` denotes a class then perform new/const insertion on
      the initial `typeIdentifier arguments`.
    - if _e_ is of the form
      `typeIdentifier '.' identifier assignableExpressionTail`
      where `typeIdentifier` denotes a class and `identifier` is the name
      of a named constructor in that class, or `typeIdentifier` denotes a
      prefix for a library _L_ and `identifier` denotes a class exported by
      _L_ then perform new/const insertion on the initial
      `typeIdentifier '.' identifier arguments`.
    - if _e_ is of the form
      `typeIdentifier1 '.' typeIdentifier2 '.' identifier
      assignableExpressionTail`
      where `typeIdentifier1` denotes a library prefix for a library _L_,
      `typeIdentifier2` denotes a class _C_ exported by _L_, and
      `identifier` is the name of a named constructor in _C_ then perform
      new/const insertion on the initial 
      `typeIdentifier1 '.' typeIdentifier2 '.' identifier arguments`.

3.  If _e_ is a literal list or a literal map which occurs in a constant
    context and does not have the modifier `const`, it is replaced by
    `const` _e_.

*In short, `const` is added implicitly in almost all situations where it is
required by the context, and in other situations `new` is added on instance
creations. It is easy to verify that each of the replacements can be
derived from `postfixExpression` via `primary selector*` and similarly for
`assignableExpression`. Hence, the transformation preserves syntactic
correctness.*


## Dynamic Semantics

There is no dynamic semantics to specify for this feature, because it is
eliminated by the code transformation.


## Revisions

- 0.7 (2018-04-10) Clarified the structure of the algorithm. Added
  commentary about cases where there is no constant context even though a
  constant expression is required, with a motivation for why it is so.

- 0.6 (2018-04-06) Removed "magic const" again, due to the risks
  associated with this feature (getting it specified and implemented
  robustly, in time).

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
