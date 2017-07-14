# Feature: Generic Function Type Alias

**Status**: Implemented.

**This document** is an informal specification of a feature supporting the
definition of function type aliases using a more expressive syntax than the
one available today, such that it also covers generic function types. The
feature also introduces syntax for specifying function types directly, such
that they can be used in type annotations etc. without going via a
`typedef`.

In this document, a **generic function type** denotes the type of a function
whose declaration includes a list of formal type parameters. It could also
have been called a *generic-function type*, because it is "the type of a
generic function". Note that this differs from "a type parameterized name
*F* whose instances *F<T>* denote function types", which might perhaps be
called a *generic function-type*. In this document the latter is designated
as a **parameterized typedef**. Examples clarifying this distinction are
given below.

**This feature** introduces a new syntactic form of typedef declaration
which includes an identifier and a type, connecting the two with an equals
sign, `=`. The effect of such a declaration is that the name is declared to
be an alias for the type. Type parameterization may occur in the declared
type (declaring a generic function type) as well as on the declared name
(declaring a parameterized typedef). This feature also introduces syntax for
specifying function types directly, using a syntax which is similar to the
header of a function declaration.

The **motivation** for adding this feature is that it allows developers to
specify generic function types at all, and to specify function types
everywhere a type is expected. That includes type annotations, return types,
actual type arguments, and formal type parameter bounds. Currently there is
no way to specify a function type directly in these situations. Even in the
case where a function type *can* be specified (such as a type annotation for
a formal parameter) it may be useful for readability to declare a name as an
alias of a complex type, and use that name instead of the type.

## Examples

Using the new syntax, a function type alias may be declared as follows:

```dart
typedef F = List<T> Function<T>(T);
```

This declares `F` to be the type of a function that accepts one type
parameter `T` and one value parameter of type `T` whose name is
unspecified, and returns a result of type `List<T>`. It is possible to use
the new syntax to declare function types that we can already declare using
the existing typedef declaration. For instance, `G` and `H` both declare
the same type:

```dart
typedef G = List<int> Function(int); // New form.
typedef List<int> H(int i); // Old form.
```

Note that the name of the parameter is required in the old form, but the
type may be omitted. In contrast, the type is required in the new form, but
the name may be omitted.

The reason for having two ways to express the same thing is that the new
form seamlessly covers non-generic functions as well as generic ones, and
developers might prefer to use the new form everywhere, for improved
readability.

There is a difference between declaring a generic function type and
declaring a typedef which takes a type argument. The former is a
declaration of a single type which describes a certain class of runtime
entities: Functions that are capable of accepting some type arguments as
well as some value arguments, both at runtime. The latter is a compile-time 
mapping from types to types: It accepts a type argument at compile time and
returns a type, which may be used, say, as a type annotation. We use the
phrase *parameterized typedef* to refer to the latter. Dart has had support
for parameterized typedefs for a while, and the new syntax supports
parameterized typedefs as well. Here is an example of a parameterized
typedef, and a usage thereof:

```dart
typedef I<T> = List<T> Function(T); // New form.
typedef List<T> J<T>(T t); // Old form.
I<int> myFunction(J<int> f) => f;
```

In this example,
we have declared two equivalent parameterized typedefs `I` and `J`,
and we have used an instantiation of each of them in the type annotations
on `myFunction`. Note that the type of `myFunction` does not include *any*
generic types, it is just a function that accepts an argument and returns a
result, both of which have a non-generic function type that we have
obtained by instantiating a parameterized typedef. The argument type might
as well have been declared using the traditional function signature syntax,
and the return type (and the argument type, by the way) might as well have
been declared using a regular, non-parameterized typedef:

```dart
typedef List<int> K(int i); // Old form, non-generic.
K myFunction2(List<int> f(int i)) => f; // Same as myFunction.
```

The new syntax allows for using the two kinds of type parameters together:

```dart
typedef L<T> = List<T> Function<S>(S, {T Function(int, S) factory});
```

This declares `L` to be a parameterized typedef; when instantiating `L`
with an actual type argument as in `L<String>`, it becomes the type of a
generic function that accepts a type argument `S` and two value arguments:
one required positional argument of type `S`, and one named optional
argument with name `factory` and type `String Function(int, S)`; finally,
it returns a value of type `List<String>`.

## Syntax

The new form of `typedef` declaration uses the following syntax (there are
no deletions from the grammar; addition of a new rule or a new alternative
in a rule is marked with NEW and modified rules are marked CHANGED):

```
typeAlias:
  metadata 'typedef' typeAliasBody |
  metadata 'typedef' identifier typeParameters? '=' functionType ';' // NEW
functionType: // NEW
  returnType? 'Function' typeParameters? parameterTypeList
parameterTypeList: // NEW
  '(' ')' |
  '(' normalParameterTypes ','? ')' |
  '(' normalParameterTypes ',' optionalParameterTypes ')' |
  '(' optionalParameterTypes ')'
normalParameterTypes: // NEW
  normalParameterType (',' normalParameterType)*
normalParameterType: // NEW
  type | typedIdentifier
optionalParameterTypes: // NEW
  optionalPositionalParameterTypes | namedParameterTypes
optionalPositionalParameterTypes: // NEW
  '[' normalParameterTypes ','? ']'
namedParameterTypes: // NEW
  '{' typedIdentifier (',' typedIdentifier)* ','? '}'
typedIdentifier: // NEW
  type identifier
type: // CHANGED
  typeWithoutFunction |
  functionType
typeWithoutFunction: // NEW
  typeName typeArguments?
typeWithoutFunctionList: // NEW
  typeWithoutFunction (',' typeWithoutFunction)*
mixins: // CHANGED
  'with' typeWithoutFunctionList
interfaces: // CHANGED
  'implements' typeWithoutFunctionList
superclass: // CHANGED
  'extends' typeWithoutFunction
mixinApplication: // CHANGED
  typeWithoutFunction mixins interfaces?
newExpression: // CHANGED
  'new' typeWithoutFunction ('.' identifier)? arguments
constObjectExpression: // CHANGED
  'const' typeWithoutFunction ('.' identifier)? arguments
redirectingFactoryConstructorSignature: // CHANGED
  'const'? 'factory' identifier ('.' identifier)?
  formalParameterList '=' typeWithoutFunction ('.' identifier)?
```

The syntax relies on treating `Function` as a fixed element in a function
type, similar to a keyword or a symbol (many languages use symbols like
`->` to mark function types).

*The rationale for using this form is that it makes a function type very
similar to the header in a declaration of a function with that type: Just
replace `Function` by the name of the function, and add missing parameter
names and default values.*

*The syntax differs from the existing function type syntax
(`functionSignature`) in that the existing syntax allows the type of a
parameter to be omitted, but the new syntax allows names of positional
parameters to be
omitted. The rationale for this change is that a function type where a
parameter has a specified name and no type is very likely to be a
mistake. For instance, `int Function(int)` should not be the type of a
function that accepts an argument named "int" of type `dynamic`, it should
specify `int` as the parameter type and allow the name to be
unspecified. It is still possible to opt in and specify the parameter name,
which may be useful as documentation, e.g., if several arguments have the
same type.*

The modification of the rule for the nonterminal `type` causes parsing
ambiguities. The following disambiguation rule applies:
If the parser is at a location L where the tokens starting
at L may be a `type` or some other construct (e.g., in the body of a
method, when parsing something that may be a statement and may also be a
declaration), the parser must commit to parsing a `type` if it
is looking at the identifier `Function` followed by `<` or `(`, or it
is looking at a `type` followed by the identifier `Function` followed by `<`
or `(`.

*Note that this disambiguation rule does require parsers to have unlimited
lookahead. However, if a parsing strategy is used where the token
stream already contains references from each opening bracket (such as `<`
or `(`) to the corresponding closing bracket then the decision can be
taken in a fixed number of steps: If the current token is `Function` then
check the immediate successor (`<` or `(` means yes, we are looking at
a `type`, everything else means no) and we're done; if the first token is
an `identifier` other than `Function` then we can check whether it is a
`qualified` by looking at no more than the two next tokens, and we may then
check whether the next token again is `<`; if it is not then we look for
`Function` and the token after that, and if it is `<` then look for the
corresponding `>` (we have now skipped a generic class type), and then
the successor to that token again must be `Function`, and we finally check
its successor (looking for `<` or `(` again). This skips over the
presumed type arguments to a generic class type without checking that they
are actually type arguments, but we conjecture that there are no
syntactically correct alternatives (for example, we conjecture that there
is no syntactically correct statement, not a declaration, starting with
`SomeIdentifier<...> Function(...` where the angle brackets are balanced).*

*Note that this disambiguation rule will prevent parsing some otherwise
correct programs. For instance, the declaration of an asynchronous function
named `Function` with an omitted return type (meaning `dynamic`) and an
argument named `int` of type `dynamic` using `Function(int) async {}` will
be a parse error, because the parser will commit to parsing a type after
having seen "`Function(`" as a lookahead. However, we do not expect that it
will be a serious problem for developers to be unable to write such
programs.*

## Scoping

Consider a typedef declaration as introduced by this feature, i.e., a
construct on the form

```
metadata 'typedef' identifier typeParameters? '=' functionType ';'
```

This declaration introduces `identifier` into the enclosing library scope.

Consider a parameterized typedef, i.e., a construct on the form

```
metadata 'typedef' identifier typeParameters '=' functionType ';'
```

Note that in this case the `typeParameters` cannot be omitted. This
construct introduces a scope known as the *typedef scope*. Each typedef
scope is nested inside the library scope of the enclosing library. Every
formal type parameter declared by the `typeParameters` in this construct
introduces a type variable into its enclosing typedef scope. The typedef
scope is the current scope for the `typeParameters` themselves, and for the
`functionType`.

Consider a `functionType` specifying a generic function type, i.e., a
construct on the form

```
returnType? 'Function' typeParameters parameterTypeList
```

Note again that `typeParameters` are present, not optional. This construct
introduces a scope known as a *function type scope*. The function type
scope is nested inside the current scope for the associated `functionType`.
Every formal type parameter declared by the `typeParameters` introduces a
type variable into its enclosing function type scope. The function type
scope is the current scope for the entire `functionType`.

*This implies that parameterized typedefs and function types are capable of
specifying F-bounded type parameters, because the type parameters are in
scope in the type parameter list itself.*

## Static Analysis

Consider a typedef declaration as introduced by this feature, i.e., a
construct on the form

```
metadata 'typedef' identifier typeParameters? '=' functionType ';'
```

It is a compile-time error if a name *N* introduced into a library scope by
a typedef has an associated `functionType` which depends directly or
indirectly on *N*. It is a compile-time error if a bound on a formal type
parameter in `typeParameters` is not a type. It is a compile-time error if
a typedef has an associated `functionType` which is not a well-bounded type
when analyzed under the assumption that every identifier resolving to a
formal type parameter in `typeParameters` is a type satisfying its bound. It
is a compile-time error if an instantiation *F<T1..Tk>* of a parameterized
typedef is mal-bounded.

*This implies that a typedef cannot be recursive. It can only introduce a
name as an alias for a type which is already expressible as a
`functionType`, or a name for a type-level function F where every
well-bounded invocation `F<T1..Tk>` denotes a type which could be expressed
as a `functionType`. In the terminology of
[kind systems](https://en.wikipedia.org/wiki/Kind_(type_theory)), we
could say that a typedef can define entities of kind ` * ` and of kind
` * -> * `, and, when it is assumed that every formal type parameter of the
typedef (if any) has kind ` * `, it is an error if the right hand side of the
declaration denotes an entity of any other kind than ` * `; in particular,
declarations of entities of kind ` * -> * ` cannot be curried.*

*Note that the constraints required to ensure that the body of a `typedef`
is well-bounded may not be expressible in the language with some otherwise
reasonable declarations:
``` dart
typedef F<X> = void Function(X);
class C<Y extends F<num>> {}
typedef G<Z> = C<F<Z>> Function();
```
The formal type parameter `Z` must be a supertype of `num` in order to
ensure that `F<Z>` is a subtype of the bound `F<num>`, but we do not support
lower bounds on type arguments in Dart. Consequently, a declaration like
`G` is a compile-time error no matter which bound we specify for `Z`, because
no bound will ensure that the body is well-bounded for all possible `Z`.
Similarly, the body of a `typedef` may use a given type argument in
two or more different covariant contexts, which may require a bound which
is a subtype of the constraints needed for each of those usages; for
nominal types we would need an intersection type constructor in order to
express a useful constraint in this situation. A richer type algebra
may be added to Dart in the future which could allow more of these
complex `typedef`s, but it is not obvious that it is useful enough to
justify the added complexity.*

It is a compile-time error if a name declared in a typedef, with or without
actual type arguments, is used as a superclass, superinterface, or mixin. It
is a compile-time error if a generic function type is used as a bound for a
formal type parameter of a class or a function. It is a compile-time error if
a generic function type is used as an actual type argument.

*Generic function types can thus only be used in the following situations:*

- *as a type annotation on an local, instance, static, or global variable.*
- *as a function return or parameter type.*
- *in a type test.*
- *in a type cast.*
- *in an on-catch clause.*
- *as a parameter or return type in a function type.*

*The motivation for having this constraint is that it ensures that the Dart type
system admits only predicative types. It does admit non-prenex types, e.g.,
`int Function(T function<T>(T) f)`. From research into functional calculi
it is well-known that impredicative types give rise to undecidable subtyping,
e.g.,
[(Pierce, 1993)](http://www2.tcs.ifi.lmu.de/lehre/SS07/Typen/pierce93bounded.pdf),
and even though the Dart type system is very different from F-sub, we cannot
assume that these difficulties are absent.*

## Dynamic Semantics

The addition of this feature does not change the dynamic semantics of
Dart.

## Changes

2017-May-31: Added constraint on usage of generic function types: They
cannot be used as type parameter bounds nor as type arguments.

2017-Jan-04: Adjusted the grammar to require named parameter types to have
a type (previously, the type was optional).

2016-Dec-21: Changed the grammar to prevent the new function type syntax
in several locations (for instance, as a super class or as a mixin). The
main change in the grammar is the introduction of `typeWithoutFunction`.

2016-Dec-15: Changed the grammar to prevent the old style function types
(derived from `functionSignature` in the grammar) from occurring inside
the new style (`functionType`).
