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

Note that using the value of an expression of type `void` is not
technically dangerous, doing so does not violate any constraints at the
level of the language semantics.  By using the type `void`, developers
indicate that the value of the corresponding expression evaluation is
meaningless. Hence, there is **no requirement** for the generalized void
mechanism to be strict and **sound**. However, it is the intention that the
mechanism should be sufficiently sound to make the mechanism helpful and
non-frustrating in practice.

No constraints are imposed on which values may be given type `void`, so in
that sense `void` can be considered to be just another name for the type
`Object`, flagged as useless. Note that this is an approximate rule in
Dart 1.x, it fails to hold for function types; it does hold in Dart 2.

The mechanisms helping developers to avoid using the value of an expression
of type `void` are divided into **two phases**. This document specifies the
first phase.

The **first phase** uses restrictions which are based on syntactic criteria
in order to ensure that direct usage of the value of an expression of type
`void` is a static warning (in Dart 2: an error). A few exceptions are
allowed, e.g., type casts, such that developers can explicitly make the
choice to use such a value. The general rule is that for every expression
of type `void`, its value must be ignored.

The **second phase** will deal with casts and preservation of
voidness. Some casts will cause derived expressions to switch from having
type `void` to having some other type, and hence those casts introduce the
possibility that "a void value" will get passed and used. Here is an
example:

```dart
class A<T> { T foo(); }
A<Object> a = new A<void>(); // Violates voidness preservation.
var x = a.foo(); // Use a "void value", now with static type Object.
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

*There is no way for a Dart program at run time to obtain a reified
representation of a return type or parameter type of a function type, even
when the function type as a whole may be obtained (e.g., the function type
could be passed as a type argument and the corresponding formal type
parameter could be evaluated as an expression). A reified representation of
such a return type is therefore not necessary.*

For a composite type (a generic class instantiation or a function type),
the reified representation at run time must be such that the type void and
the built-in class `Object` are treated as equal according to `==`, but
they need not be `identical`.

*For example, with `typedef F<S, T> = S Function(T)`, the `Type` instance
for `F<Object, void>` at run time is `==` to the one for `F<void, void>`
and for `F<void, Object>`.*

*In case of a dynamic error, implementations are encouraged to emit an
error message that includes information about such parts of types being
`void` rather than `Object`. Developers will then see types which are
similar to the source code declarations. This may be achieved using
distinct `Type` objects to represent types such as `F<void, void>` and
`F<Object, void>`, comparing equal using `==` but not `identical`.*

*This treatment of the reified representation of the type void reinforces
the understanding that "voidness" is merely a statically known flag on the
built-in class `Object`. However, for backward compatibility we need to
treat return types differently in Dart 1.x.*

*It may be possible to use a reflective subsystem (mirrors) to deconstruct
a function type whose return type is the type void, but the existing design
of the system library `dart:mirrors` already handles this case by allowing
for a type mirror that does not have a reflected type. All in all, the type
void does not need to be reified at run time, and it is not reified.*

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

Consider a function type _T_ where the return type is the type void. In
Dart 1.x, the dynamic more-specific-than relation, `<<`, and the dynamic
subtype relation, `<:`, are determined by the existing rules in the
language specification, supplemented by the above rule for handling
occurrences of the type void other than as a return type. In Dart 2 there
is no exception for return types: the type void is treated as being the
built-in class `Object`.

*This ensures backward compatibility for the cases where the type void can
be used already today. It follows that it will be a breaking change to
switch to a ruleset where the type void even as a return type is treated
like the built-in class Object, i.e. when switching to Dart 2. However,
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
for the dynamic semantics, for both Dart 1.x and Dart 2.

*That is, the type void is considered to be equivalent to the built-in
class `Object` in Dart 1.x, except when used as a return type, in which
case it is effectively considered to be a proper supertype of `Object`. In
Dart 2 subtyping, the type void is consistently considered to be equivalent
to the built-in class `Object`. As mentioned, this document does not
specify voidness preservation; however, when voidness preservation checks
are added we get an effect in Dart 2 which is similar to the special
treatment of void as a return type in Dart 1.x: The function type downcast
which will be rejected in Dart 1.x (at run time, with a static warning at
compile time) will become a voidness preservation violation, i.e., a
compile-time error.*

It is a static warning for an expression to have type void (in Dart 2: a
compile-time error), except for the following situations:

*   In an expressionStatement `e;`, e may have type void.
*   In the initialization and increment expressions of a for-loop,
    `for (e1; e2; e3) {..}`, `e1` and `e3` may have type void.
*   In a typeCast `e as T`, `e` may have type void.
*   In a parenthesized expression `(e)`, `e` may have type void.
*   In a return statement `return e;`, when the return type of the innermost
    enclosing function is the type void, `e` may have type void.

*Note that the parenthesized expression itself has type void, so it is
again subject to the same constraints. Also note that we may not allow
return statements returning an expression of type void in Dart 2, but
it is allowed here for backward compatibility.*

*The value yielded by an expression of type void must be discarded (and
hence ignored), except when explicitly subjected to a type cast. This
"makes it hard to use a meaningless value", but leaves a small escape hatch
open for the cases where the developer knows that the typing misrepresents
the actual situation.*

During bounds checking, it is possible that a bound of a formal type
parameter of a generic class or function is statically known to be the type
void. In this case, the bound is considered to be the built-in class
`Object`.

In Dart 2, it is a compile-time error when a method declaration _D2_ with
return type void overrides a method declaration _D1_ whose return type is
not void.

*This rule is a special case of voidness preservation, which is needed in
order to maintain the discipline which arises naturally from the function
type subtype rules in Dart 1.x concerning void as a return type.*

## Discussion

Expressions derived from typeCast and typeTest do not support `void` as the
target type. We have omitted support for this situation because we consider
it to be useless. If void is passed indirectly via a type variable `T` then
`e as T`, `e is T`, and `e is! T` will treat `T` like `Object`. In general,
the rationale is that the type void admits all values (because it is just
`Object` plus a "static voidness flag"), but the value of expressions of
type void should be discarded. So there is no point in *obtaining* the type
void for a given expression which already has a different type.

The treatment of bounds is delicate. We syntactically prohibit `void` as a
bound of a formal type parameter of a generic class or function. It is
possible to pass the type void as an actual type argument to a generic
class, and that type argument might in turn be used as the bound of another
formal type parameter of the class, or of a generic function in the
class. It would be possible to make it a compile-time error to pass `void`
as a type argument to a generic class where it will be used as a bound, but
this would require a transitive traversal of all generic classes and
functions where the corresponding formal type parameter is passed on to
other generic classes or functions, which would be highly brittle: A tiny
change to a generic class or function could break code far away. So we do
not wish to prevent formal type parameter bounds from indirectly becoming
the type void. This motivated the decision to treat such a void-valued
bound as `Object`.

## Updates

*   August 22nd 2017: Reworded specification of reified types to deal with
    only such values which may be obtained at run time (previously mentioned
    some entities which may not exist). Added one override rule.

*   August 17th 2017: Several parts clarified.

*   August 16th 2017: Removed exceptions allowing `e is T` and `e is! T`.

*   August 9th 2017: Transferred to SDK repo, docs/language/informal.

*   July 16th 2017: Reformatted as a gist.

*   June 13th 2017: Compile-time error for using a void value was changed to
    static warning.

*   June 12th 2017: Grammar changed extensively, to use `typeNotVoid`
    rather than `voidOrType`.

*   June 5th 2017: Added `typeCast` and `typeTest` to the locations where
    void expressions may occur.
