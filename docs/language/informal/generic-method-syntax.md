# Feature: Generic Method Syntax

**This document** is an informal specification of the support in Dart 1.x
for generic methods and functions which includes syntax and name
resolution, but not reification of type arguments.

The **motivation for** having this **feature** is that it enables partial
support for generic methods and functions, thus providing a bridge between
not having generic methods and having full support for generic methods. In
particular, code declaring and using generic methods may be type checked and
compiled in strong mode, and the same code will now be acceptable in
standard (non-strong) mode as well. The semantics is different in certain
cases, but standard mode analysis will emit diagnostic messages (e.g.,
errors) for that.

In this document, the word **routine** will be used when referring to
an entity which can be a non-operator method declaration, a top level
function declaration, a local function declaration, or a function literal
expression. Depending on the context, the word routine may also denote the
semantic entity associated with such a declaration, e.g., a closure
corresponding to a function literal.

With **this feature** it is possible to compile code where generic methods
and functions are declared, implemented, and invoked. The runtime semantics
does not include reification of type arguments. Usages of the runtime
value of a routine type parameter is a runtime error or yields `dynamic`,
depending on the context. No type checking takes place at usages of a method
or function type parameter in the body, and no type checking regarding
explicitly specified or omitted type arguments takes place at call sites.

In short, generic methods and functions are supported syntactically, and the
runtime semantics prevents dynamic usages of the type argument values, but
it allows all usages where that dynamic value is not required. For instance,
a generic routine type parameter, `T`, cannot be used in an expression like
`x is T`, but it can be used as a type annotation. In a context where other
tools may perform type checking, this allows for a similar level of
expressive power as do language designs where type arguments are erased at
compile time.

The **motivation for** this **document** is that it serves as an informal
specification for the implementation of support for the generic method
syntax feature in all Dart tools.

## Syntax

The syntactic elements which are added or modified in order to support this
feature are as follows, based on grammar rules given in the Dart Language
Specification (Aug 19, 2015).

```
formalParameterPart:
  typeParameters? formalParameterList
functionSignature:
  metadata returnType? identifier formalParameterPart
typeParameter:
  metadata identifier ('extends' type)?
functionExpression:
  formalParameterPart functionBody
fieldFormalParameter:
  metadata finalConstVarOrType? 'this' '.' identifier
  formalParameterPart?
argumentPart:
  typeArguments? arguments
selector:
  assignableSelector | argumentPart
assignableExpression:
  primary (argumentPart* assignableSelector)+ |
  'super' unconditionalAssignableSelector |
  identifier
cascadeSection:
  '..' (cascadeSelector argumentPart*)
  (assignableSelector argumentPart*)*
  (assignmentOperator expressionWithoutCascade)?
```

In a [draft specification](https://codereview.chromium.org/1177073002) of
generic methods from June 2015, the number of grammar changes is
significantly higher, but that form can be obtained via renaming.

This extension to the grammar gives rise to an **ambiguity** where the
same tokens may be angle brackets of a type argument list as well as
relational operators. For instance, `foo(a<b,c>(d))`[^1] may be parsed as  
a `postfixExpression` on the form `primary arguments` where the arguments
are two relational expressions (`a<b` and `c>(d)`), and it may also be
parsed such that there is a single argument which is an invocation of a
generic function (`a<b,c>(d)`).  The ambiguity is resolved in **favor** of
the latter.

*This is a breaking change, because existing code could include
expressions like `foo(a < b, c > (d))` where `foo` receives two
arguments. That expression will now be parsed as an invocation of `foo`
with one argument. It is unlikely that this will introduce bugs silently,
because the new parsing is likely to incur diagnostic messages at
compile-time.*

We chose to favor the generic function invocation over the
relational expression because it is considered to be a rare exception that
this ambiguity arises: It requires a balanced set of angle brackets followed
by a left parenthesis, which is already an unusual form. On top of that, the
style guide recommendation to use named parameters for boolean arguments
helps making this situation even less common.

If it does occur then there is an easy **workaround**: an extra set of
parentheses (as in `foo(a<b,(2>(d)))`) will resolve the ambiguity in the
direction of relational expressions; or we might simply be able to remove
the parentheses around the last expression (as in `foo(a<b,2>d)`), which
will also eliminate the ambiguity.

_It should be noted that parsing techniques like recursive descent seem to
conflict with this approach to disambiguation: Determining whether the
remaining input starts with a balanced expression on the form `<` .. `>`
seems to imply a need for unbounded lookahead. However, if some type of
parsing is used where bracket tokens are matched up during lexical
analysis then it takes only a simple O(1) operation in the parser to
perform a check which will very frequently resolve the ambiguity._

## Scope of the Mechanism

With the syntax in place, it is obvious that certain potential extensions
have **not** been **included**.

For instance, constructors, setters, getters, and operators cannot be
declared as generic: The syntax for passing actual type arguments at
invocation sites for setters, getters, and operators is likely to be
unwieldy and confusing, and for constructors there is a need to find
a way to distinguish between type arguments for the new instance and
type arguments for the constructor itself. However, there are plans
to add support for generic constructors.

This informal specification specifies a dynamic semantics where the values
of **actual type arguments are not reified** at run time. A future
extension of this mechanism may add this reification, such that dynamic
type tests and type casts involving routine type variables will be
supported.

## Resolution and Type Checking

In order to be useful, the support for generic methods and functions must be
sufficiently complete and consistent to **avoid spurious** diagnostic
**messages**. In particular, even though no regular type checks take place
at usages of routine type parameters in the body where they are in scope,
those type parameters should be resolved. If they had been ignored then any
usage of a routine type parameter `X` would give rise to a `Cannot resolve
type X` error message, or the usage might resolve to other declarations of
`X` in enclosing scopes such as a class type parameter, both of which is
unacceptable.

In `dart2js` resolution, the desired behavior has been achieved by adding a
new type parameter **scope** and putting the type parameters into that
scope, giving each of them the bound `dynamic`. The type parameter scope is
the current scope during resolution of the routine signature and the type
parameter bounds, it encloses the formal parameter scope of the routine, and
the formal parameter scope in turn encloses the body scope.

This implies that every usage of a routine type parameter is treated during
**type checking** as if it had been an alias for the type dynamic.

Static checks for **invocations** of methods or functions where type
arguments are passed are omitted entirely: The type arguments are parsed,
but no checks are applied to certify that the given routine accepts type
arguments, and no checks are applied for bound violations. Similarly, no
checks are performed for invocations where no type arguments are passed,
whether or not the given routine is statically known to accept type
arguments.

Certain usages of a routine type parameter `X` give rise to **errors**: It
is a compile-time error if `X` is used as a type literal expression (e.g.,
`foo(X)`), or in an expression on the form `e is X` or `e is! X`, or in a
try/catch statement like `.. on T catch ..`.

It could be argued that it should be a warning or an error if a routine type
parameter `X` is used in an expression on the form `e as X`. The blind
success of this test at runtime may introduce bugs into correct programs in
situations where the type constraint is violated; in particular, this could
cause "wrong" objects to propagate through local variables and parameters
and even into data structures (say, when a `List<T>` is actually a
`List<dynamic>`, because `T` is not present at runtime when the list is
created). However, considering that these type constraint violations are
expected to be rare, and considering that it is common to require that
programs compile without warnings, we have chosen to omit this warning. A
tool is still free to emit a hint, or in some other way indicate that there
is an issue.

## Dynamic semantics

If a routine invocation specifies actual type arguments, e.g., `int` in the
**invocation** `f<int>(42)`, those type arguments will not be evaluated at
runtime, and they will not be passed to the routine in the
invocation. Similarly, no type arguments are ever passed to a generic
routine due to call-site inference. This corresponds to the fact that the
type arguments have no runtime representation.

When the body of a generic **routine** is **executed**, usages of the formal
type parameters will either result in a run-time error, or they will yield
the type dynamic, following the treatment of malformed types in
Dart. There are the following cases:

When `X` is a routine type parameter, the evaluation of `e is X`, `e is! X`,
and `X` used as an expression proceeds as if `X` had been a malformed type,
producing a dynamic error; the evaluation of `e as X` has the same outcome
as the evaluation of `e`.

Note that the forms containing `is` are compile-time errors, which means
that compilers may reject the program or offer ways to compile the program
with a different runtime semantics for these expressions. The rationale for
`dart2js` allowing the construct and compiling it to a run time error is
that (1) this allows more programs using generic methods to be compiled,
and (2) an `is` expression that blindly returns `true` every time (or
`false` every time) may silently introduce a bug into an otherwise correct
program, so the expression must fail if it is ever evaluated.

When `X` is a routine type parameter which is passed as a type argument to a
generic class instantiation `G`, it is again treated like a malformed type,
i.e., it is considered to denote the type dynamic.

This may be surprising, so let us consider a couple of examples: When `X` is
a routine type parameter, `42 is X` raises a dynamic error, `<int>[42] is
List<X>` yields the value `true`, and `42 as X` yields `42`, no matter
whether the syntax for the invocation of the routine included an actual type
argument, and, if so, no matter which value the actual type argument would
have had at the invocation.

Object construction is similar: When `X` is a routine type parameter which
is a passed as a type argument in a constructor invocation, the actual
value of the type type argument will be the type dynamic, as it would have
been with a malformed type.

In **checked mode**, when `X` is a routine type parameter, no checked mode
checks will ever fail for initialization or assignment to a local variable
or parameter whose type annotation is `X`, and if the type annotation is a
generic type `G` that contains `X`, checked mode checks will succeed or
fail as if `X` had been the type dynamic. Note that this differs from the
treatment of malformed types.

## Changes

2017-Jan-04: Changed 'static error' to 'compile-time error', which is the
phrase that the language specification uses.

## Notes

[^1]: These expressions violate the common style in Dart with respect to
spacing and capitalization. That is because the ambiguity implies
conflicting requirements, and we do not want to bias the appearance in
one of the two directions.
