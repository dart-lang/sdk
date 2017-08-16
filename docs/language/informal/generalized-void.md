## Feature: Generalized Void

Author: eernst@

**Status**: Under implementation.

**This document** is an informal specification of the generalized support
in Dart 1.x for the type `void`. Dart 2 will have a very similar kind of
generalized support for `void`, without the function type subtype exception
that this feature includes for backward compatibility in Dart 1.x. This
document specifies the feature for Dart 1.x and indicates how Dart 2
differs at relevant points.

**The feature** described here, *generalized void*, allows for using the
type `void` as a type annotation and as a type argument.

The **motivation** for allowing the extended usage is that it helps
developers state the intent that a particular **value should be
ignored**. For example, a `Future<void>` may be awaited in order to satisfy
ordering dependencies in the execution, but no useful value will be
available at completion. Similarly, a `Visitor<void>` (where we assume the
type argument is used to describe a value returned by the visitor) may be
used to indicate that the visit is performed for its side-effects
alone. The generalized void feature includes mechanisms to help developers
avoid using such a value.

In general, situations where it may be desirable to use `void` as
a type argument arise when the corresponding formal type variable is used
covariantly. For instance, the class `Future<T>` uses return types
like `Future<T>` and `Stream<T>`, and it uses `T` as a parameter type of a
callback in the method `then`.

Note that is not technically dangerous to use a value of type `void`, it
does not violate any constraints at the level of the language semantics.
Developers just made the decision to declare that the value is useless,
based on the program logic. Hence, there is **no requirement** for the
generalized void mechanism to be strict and **sound**. However, it is the
intention that the mechanism should be sufficiently strict to make the
mechanism helpful and non-frustrating in practice.

No constraints are imposed on which values may be given type `void`, so in
that sense `void` can be considered to be just another name for the type
`Object`, flagged as useless. Note that this is an approximate rule (in
Dart 1.x), it fails to hold for function types.

The mechanisms helping developers to avoid using values of type `void` are
divided into **two phases**. This document specifies the first phase.

The **first phase** uses restrictions which are based on syntactic criteria
in order to ensure that direct usage of a value of type `void` is a static
warning (in Dart 2: an error). A few exceptions are allowed, e.g., type
casts, such that developers can explicitly make the choice to use such a
value. The general rule is that all values of type `void` must be
discarded.

The **second phase** will deal with casts and preservation of
voidness. Some casts will cause derived expressions to switch from having
type `void` to having some other type, and hence those casts introduce the
possibility that "a void value" will get passed and used. Here is an
example:

```dart
class A<T> { T foo(); }
A<Object> a = new A<void>(); // Violates voidness preservation.
var x = a.foo(); // Use a "void value", with static type Object.
```

We intend to introduce a **voidness preservation analysis** (which is
similar to a small type system) to keep track of such situations. As
mentioned, the second phase is **not specified in this document**. Voidness
preservation is a purely static analysis, and there are no plans to
introduce dynamic checking for it.

## Syntax

The reserved word `void` remains a reserved word, but it will now be usable
in additional contexts. Below are the grammar rules affected by this
change. New grammar rules are marked NEW, other grammar rules are
modified. Unchanged alternatives in a rule are shown as `...`. The grammar
rules used as a starting point for this syntax are taken from the language
specification as of June 2nd, 2017 (git commit 0603b18).

```
typeNotVoid ::= // NEW
    typeName typeArguments?
type ::= // ENTIRE RULE MODIFIED
    typeNotVoid | 'void'
redirectingFactoryConstructorSignature ::=
    'const'? 'factory' identifier ('.' identifier)? 
    formalParameterList `=' typeNotVoid ('.' identifier)?
superclass ::=
    'extends' typeNotVoid
mixinApplication ::=
    typeNotVoid mixins interfaces?
typeParameter ::=
    metadata identifier ('extends' typeNotVoid)?
newExpression ::=
    'new' typeNotVoid ('.' identifier)? arguments
constObjectExpression ::=
    'const' typeNotVoid ('.' identifier)? arguments
typeTest ::=
    isOperator typeNotVoid
typeCast ::=
    asOperator typeNotVoid
onPart ::=
    catchPart block |
    'on' typeNotVoid catchPart? block
typeNotVoidList ::=
    typeNotVoid (',' typeNotVoid)*
mixins ::=
    'with' typeNotVoidList
interfaces ::=
    'implements' typeNotVoidList
functionSignature ::=
    metadata type? identifier formalParameterList
functionFormalParameter ::=
    metadata 'covariant'? type? identifier formalParameterList
operatorSignature ::=
    type? 'operator' operator formalParameterList
getterSignature ::=
    type? 'get' identifier
setterSignature ::=
    type? 'set' identifier formalParameterList
topLevelDefinition ::=
    ...
    type? 'get' identifier functionBody |
    type? 'set' identifier formalParameterList functionBody |
    ...
functionPrefix ::=
    type? identifier
```

The rule for `returnType` in the grammar is deleted.

*This is because we can now use `type`, which derives the same expressions
as `returnType` used to derive. In that sense, some of these grammar
modifications are renames. Note that the grammar contains known mistakes,
especially concerned with the placement of `metadata`. This document makes
no attempt to correct those mistakes, that is a separate issue.*

*A complete grammar which includes support for generalized void is
available in the file Dart.g
from
[https://codereview.chromium.org/2688903004/](https://codereview.chromium.org/2688903004/).*

## Dynamic semantics

There are no values at run time whose dynamic type is the type void.

*This implies that it is never required for the getter `runtimeType` in the
built-in class `Object` to return a reified representation of the type
void. Note, however, that apart from the fact that usage is restricted for
values with the type void, it is possible for an expression of type void to
evaluate to any value. In that sense, every value has the type void, it is
just not the only type that it has, and loosely speaking it is not the most
specific type.*

There is no value which is the reified representation of the type void at
run time.

*Syntactically, `void` cannot occur as an expression, and hence expression
evaluation cannot directly yield such a value. However, a formal type
parameter can be used in expressions, and the actual type argument bound to
that formal type parameter can be the type void. That case is specified
explicitly below. Apart from the reserved word `void` and a formal type
parameter, no other term can denote the type void.*

*Conversely, `void` cannot denote any other entity than the type void:
`void` cannot occur as the declared name of any declaration (including
library prefixes, types, variables, parameters, etc.). This implies that
`void` is not subject to scoped lookup, and the name is not exported by any
system library. Similarly, it can never be accessed using a prefixed
expression (`p.void`). Hence, `void` has a fixed meaning everywhere in all
Dart programs, and it can only occur as a stand-alone word.*

When `void` is passed as an actual type argument to a generic class or a
generic function, and when the type void occurs as a parameter type in a
function type, the reified representation is equal (according to `==`) to
the reified representation of the built-in class `Object`.

*It is encouraged for an implementation to use a reified representation for
`void` as a type argument and as a parameter type in a function type which
is not `identical` to the reified representation of the built-in class
`Object`, but they must be equal. This allows implementations to produce
better diagnostic messages, e.g., in case of a runtime error.*

*This treatment of the reified representation of the type void reinforces
the understanding that "voidness" is merely a statically known flag on the
built-in class `Object`, it is not a separate type. However, for backward
compatibility we need to treat return types differently.*

When `void` is specified as the return type of a function, the reified
representation of the return type is left unspecified.

*There is no way for a Dart program at run time to obtain a reified
representation of that return type alone, even when the function type as a
whole may be obtained (e.g., the function type could be evaluated as an
expression). It is therefore not necessary to reified representation of
such a return type.*

*It may be possible to use a reflective subsystem (mirrors) to deconstruct
a function type whose return type is the type void, but the existing design
of the system library `dart:mirrors` already handles this case by allowing
for a type mirror that does not have a reflected type.*

Consider a type _T_ where the type void occurs as an actual type argument
to a generic class, or as a parameter type in a function type. Dynamically,
the more-specific-than relation (`<<`) and the dynamic subtype relation
(`<:`) between _T_ and other types are determined by the following rule:
the type void is treated as being the built-in class `Object`.

*Dart 1.x does not support generic function types dynamically, because they
are erased to regular function types during compilation. Hence there is no
need to specify the the typing relations for generic function types. In
Dart 2, the subtype relationship for generic function types follows from
the rule that `void` is treated as `Object`.*

Consider a function type _T_ where the return type is the type void. The
dynamic more-specific-than relation, `<<`, and the dynamic subtype
relation, `<:`, are determined by the existing rules in the language
specification, supplemented by the above rule for handling occurrences of
the type void other than as a return type.

*This ensures backward compatibility for the cases where the type void can
be used already today. It follows that it will be a breaking change to
switch to a ruleset where the type void even as a return type is treated
like the built-in class Object, i.e. when switching to Dart 2.0. However,
the only situation where the semantics differs is as follows: Consider a
situation where a value of type `void Function(...)` is assigned to a
variable or parameter `x` whose type annotation is `Object Function(...)`,
where the argument types are arbitrary, but such that the assignment is
permitted. In that situation, in checked mode, the assignment will fail
with the current semantics, because the type of that value is not a subtype
of the type of `x`. The rules in this document preserve that behavior. If
we were to consistently treat the type void as `Object` at run time (as in
Dart 2) then this assignment would be permitted (but we would then use
voidness preservation to detect and avoid this situation at compile time).*

*The semantics of checked mode checks involving types where the type void
occurs is determined by the semantics of subtype tests, so we do not
specify that separately.*

An instantiation of a generic class `G` is malbounded if it contains `void`
as an actual type argument for a formal type parameter, unless that type
parameter does not have a bound, or it has a bound which is the built-in
class `Object`, or `dynamic`.

*The treatment of malbounded types follows the current specification.*

## Static Analysis

For the static analysis, the more-specific-than relation, `<<`, and the
subtype relation, `<:`, are determined by the same rules as described above
for the dynamic semantics.

*That is, the type void is considered to be equivalent to the built-in
class `Object`, except when used as a return type, in which case it is
effectively considered to be a proper supertype of `Object`. As mentioned,
voidness preservation is a separate analysis which is not specified by this
document, but it is intended to be used in the future to track "voidness"
in types and flag implicit casts wherein information about voidness may
indirectly be lost. With voidness preservation in place, we expect to be
able to treat the type void as `Object` in all cases during subtype
checks.*

It is a static warning for an expression to have type void, except for the
following situations:

*   In an expressionStatement `e;`, e may have type void.
*   In the initialization and increment expressions of a for-loop,
    `for (e1; e2; e3) {..}`, `e1` and `e3` may have type void.
*   In a typeCast `e as T`, `e` may have type void.
*   In a typeTest `e is T` or `e is! T`, `e` may have type void.
*   In a parenthesized expression `(e)`, `e` may have type void.
*   In a return statement `return e;`, when the return type of the innermost
    enclosing function is the type void, `e` may have type void.

*Note that the parenthesized expression itself has type void, so it is
again subject to the same constraints. Also note that we may not allow
return statements returning an expression of type void in the future, but
it is allowed here for backward compatibility.*

During bounds checking, it is possible that a bound of a formal type
parameter of a generic class or function is statically known to be the type
void. In this case, the bound is considered to be the built-in class
`Object`.

## Discussion

Expressions derived from typeCast and typeTest do not support `void` as the
target type. We have omitted support for this situation because we consider
it to be useless. If void is passed indirectly via a type variable `T` then
`e as T`, `e is T`, and `e is! T` will treat `T` like `Object`. In general,
the rationale is that the type void admits all values (because it is just
`Object` plus a "static voidness flag"), but values of type void should be
discarded.

The treatment of bounds is delicate. We syntactically prohibit `void` as a
bound of a formal type parameter of a generic class or function. It is
possible to pass the type void as an actual type argument to a generic
class, and that type argument might in turn be used as the bound of another
formal type parameter of the class, or of a generic function in the
class. It would be possible to make it a compile-time error to pass `void`
as a type argument to a generic class where it will be used as a bound, but
this would presumably require a transitive traversal of all generic classes
and functions where the corresponding formal type parameter is passed on to
other generic classes or functions, which would be highly brittle: A tiny
change to a generic class or function could break code far away. So we do
not wish to prevent formal type parameter bounds from indirectly becoming
the type void. This motivated the decision to treat such a void-valued
bound as `Object`.

## Updates

*   August 9th 2017: Transferred to SDK repo, docs/language/informal.

*   July 16th 2017: Reformatted as a gist.

*   June 13th 2017: Compile-time error for using a void value was changed to
    static warning.
*   June 12th 2017: Grammar changed extensively, to use
    `typeNotVoid` rather than
    `voidOrType`.
*   June 5th 2017: Added `typeCast` and
    `typeTest` to the locations where void
    expressions may occur.
