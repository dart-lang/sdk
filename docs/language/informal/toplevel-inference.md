# Toplevel inference

Owner: leafp@google.com

Status: Proposal


## Top level inference overview

Top level inference has two phases:

1. **Method override inference**
    * If you omit a return type or parameter type from an overridden or
    implemented method, inference will try to fill in the missing type using the
    signature of the method you are overriding.
2. **Static variable and field inference** 
    * If you omit the type of a field, setter, or getter, which overrides a
   corresponding member of a superclass, then inference will try to fill in the
   missing type using the type of the corresponding member of the superclass.
    * Otherwise, declarations of static variables and fields that omit a type
   will be inferred from their initializer if present.

All results from the first phase are available in the second phase.


As a general principle, when inference fails it is an error.  Tools are free to
behave in implementation specific ways to provide a graceful user experience,
but with respect to the language and its semantics, programs for which inference
fails are unspecified.


The intuitive idea behind this proposal is that top level inference works by
first inferring methods, and then doing inference for "field like things"
(static variables, fields, setters, and getters), where we don't allow inference
for "field like things" to depend on the results of inference for other "field
like things" except in cases where the dependencies are statically predictable.


Some broad principles for type inference that the language team has agreed to,
and which this proposal is designed to satisfy:
* Type inference should be free to fail with an error, rather than being
  required to always produce some answer
* It should not be possible for a programmer to observe a declaration as having
  two different types at difference points in the program (e.g. dynamic for
  recursive uses, but subsequently int).  Some consistent answer (or an error)
  should always be produced.  See the example below for an approach that
  violates this principle.
* The inference for local variables, toplevel variables, and fields, should
  either agree or error out.  The same expression should not be inferred
  differently at different syntactic positions.  It’s ok for an expression to be
  inferrable at one level but not at another.
* Obvious types should be inferred
* Inferred and annotated types should be treated the same
* Simple intuition for users
* Efficient to implement
* Type arguments should be mostly inferred


A motivating example for the current strong mode implementation (that also
serves as a demonstration of its shortcomings) is as follows:


```dart
class A {
  var x = 3;
}
var a = new A();
var b = a.x;
```


To ensure stability with respect to cycles and different orderings, current
strong mode does inference in two passes: firstly on the static and top-level
variables, and secondly on fields (method override based inference is mostly
irrelevant for this discussion). This ensures that inference is stable, but it
has several unfortunate consequences, most notably the following.  Inference may
result in the same variable being implicitly seen at two different types. In the
example above, if all declarations are in the same library, then b will be
inferred before x has been inferred, and so b will be inferred to have type
dynamic.  The same declaration in a separate library will see the type of a.x
after inference, and hence will be inferred to have type `int`.  This violates
one of the principles above, and also means that changes to the library
structure that introduce a cycle may change inference results.


## Method inference


### Method inference


Method inference for a method m behaves as if all method inference for all of
its supertypes has already been performed.


If a method leaves a type off of its signature (parameter type or return type)
and it does not override or implement anything from a super type, then the
omitted types are treated as dynamic.


Otherwise, the missing types are filled in with the type from the overridden or
implemented method.  If there are multiple overridden/implemented methods, and
any two of them have non-equal types (declared or inferred) for a parameter
position which is being inferred for the overriding method, it is an error.  If
there is no corresponding parameter position in the overridden method to infer
from and the signatures are compatible, it is treated as dynamic
(e.g. overriding a one parameter method with a method that takes a second
optional parameter).  Note: if there is no corresponding parameter position in
the overriden method to infer from and the signatures are incompatible
(e.g. overriding a one parameter method with a method that takes a second
non-optional parameter), the inference result is not defined and tools are free
to either emit an error, or to defer the error to override checking.


### Setter return types


If the return type is left off a setter, the return type is inferred to be
`void`.


## Static variable and field inference


A “candidate” for inference is one of any of the following kinds of definitions,
for which the type annotation has been omitted:
* A top level variable definition
* A static class level variable definition
* An instance variable, getter or setter definition.


The *inference dependencies of a candidate* which is inferred via override
inference are the instance fields, setters, and getters that the candidate
overrides.


The *inference dependencies of a candidate* which is inferred via initializer
inference are the *inference dependencies of the initializer expression* used to
infer the type of the candidate.


The *inference dependencies of an expression*  are as defined below
as part of initializer inference.


Informally, the inference dependencies of a candidate are all of the program
elements that contribute to inference for the candidate, and hence which must
have their types inferred before the candidate can have its type inferred.  Note
that by design, a top level variable or static class variable never depends on
an instance field, setter, or getter.  This means that top level variable and
static class variable inference can be done without reference to the results of
field inference.


For each candidate, inference for all of its dependencies must be performed
before inference for the candidate is performed.  If this cannot be done
(because of a cycle) it is a static error.  Note that it is always possible for
the programmer to break a cycle and hence eliminate the error by adding a type
annotation.


### Candidate inference

#### Top level variables

The inferred type of a top level variable is the type inferred from its
initializer.

#### Static class variables

The inferred type of a static class variable is the type inferred from its
initializer.

#### Instance field, getter, and setter inference


The inferred type of a getter, setter, or field is as follows.  Note that we say
that a setter overrides a getter if there is a getter of the same name in some
superclass or interface (explicitly declared or induced by an instance variable
declaration), and similarly for setters overriding getters, fields, etc.


A getter, setter or field which overrides/implements only a getter is inferred
to have the type taken from the overridden getter result type.


A getter, setter or field which overrides/implements only a setter is inferred
to have the type taken from the overridden setter parameter.


A getter which overrides/implements both a setter and a getter is inferred to
have the type taken from the overridden getter result type.


A setter which overrides/implements both a setter and a getter is inferred to
have the type taken from the overridden setter parameter type.


A field which overrides/implements both a setter and a getter is inferred to
have the type taken from the overridden setter parameter type if this type is
the same as the return type of the overridden getter (if the types are not the
same then inference fails with an error).


Note that overriding a field is addressed via the implicit induced getter/setter
pair (or just getter in the case of a final field).


A getter or setter with no annotated type that does not override anything is
treated as if it were annotated with dynamic.


A field with no annotated type that does not override anything has the type
inferred from its initializer.


### Initializer inference


Initializer inference works by defining a subset of the expressions in the
language for which we can predictably do inference in a way that is not
sensitive to ordering outside of the static dependencies that are syntactically
apparent in the expression.  In particular, field inference cannot change the
outcome of initializer inference.


A meta-goal is to keep this inference relatively lightweight and efficient to
implement.


In all cases, if initializer inference fails, it is an error and produces no
result.  Implementations are free to treat this as a result of dynamic after
emitting the error for the purposes of emitting subsequent error messages, but
the behavior of programs for which initializer inference fails is unspecified.

#### Expressions with immediately-evident type

We define a set of expressions with immediately-evident types (called
immediately-evident expressions, abbreviated IE) as follows.  Immediately
evident expressions have an inferred type as specified below.  Any expression
which is not an IE has no inferred type.  For every immediately evident
expression, we also define the set of variable dependencies upon which its
inference relies.

The intention is that toplevel inference should always return the same result as
local inference, or else produce an error.


* null, boolean, numeric, string, type, and symbol literals have their
   corresponding type.
   * No inference dependencies
* An `await` of an expression has type `T` if the expression is an immediately
evident expression with type `T` or `Future<T>`.
   * Inference dependencies are the inference dependencies of the awaited
     expression
* A `throw` expression has type `bottom`.
   * No inference dependencies
* A parenthesized expression has the inferred type of the sub-expression
   * Inference dependencies are the dependencies of the sub-expression
* A conditional expression where both values are immediately evident expressions
  has type `T` where `T` is the least upper bound of the inferred type of the
  two returned sub-expressions.
  * Inference dependencies are the union of the inference dependencies of the
  two returned sub-expressions.
* Logical boolean expressions and equality expressions have inferred type
  `boolean`.
  * No inference dependencies
* Relational expressions, bitwise expressions, and shift expressions are treated
as the appropriate method call as defined in the spec.
  * Inference dependencies are those of the left hand operand.
* A multiplicative binary expression is treated as a method call as defined in
  the spec, with the same exceptions for when the left hand operand is of type `int`.
  * Inference dependencies are those of the left hand operand.
* Applications of the prefix operator `!` have type `boolean`
  * No inference dependencies  
* Applications of the prefix operators `++` and `--` have the type of the operand.
  * Inference dependencies are those of the operand.
* Applications of other prefix operators are treated as method calls.
  * Inference dependencies are those of the operand.
* Application of a postfix operator to an expression `e` has the inferred type of `e`.
  * Inference dependencies are those of the operand.
* A list literal or a map literal with explicit type arguments has the type
   `List<T>` or `Map<K, V>` respectively, where `<T>` or `<K, V>` are the
   provided type arguments.
   * No inference dependencies
* A non-empty list literal with no type arguments, and for which all of the
   elements are IEs, has the type `List<T>` where `T` is the least upper bound
   of the inferred types of the elements.
   * If the elements do not all have an inferred type, it is an error
   * The inference dependencies of the list literal are the collected
      dependencies of the elements.
* An non-const empty list literal with no type arguments has the type
  `List<dynamic>`.
   * No inference dependencies.
* A const empty list literal with no type arguments has the type
  `List<Null>`.
   * No inference dependencies.
* A map literal with no type arguments, and for which all of the keys and
   values are IEs, has the type `Map<K, V>` where `K` is the least upper bound of
   the inferred types of the provided keys, and `V` is the least upper bound of
   the provided values.
   * If the keys and values do not all have an inferred type, it is an error.
   * The inference dependencies of the map literal are the collected
      dependencies of the keys and values.
* An non-const empty map literal with no type arguments has the type
  `Map<dynamic, dynamic>`.
   * No inference dependencies.
* A const empty map literal with no type arguments has the type `Map<Null,
  Null>`.
   * No inference dependencies.
* A function literal with an expression body for which all parameter types are
   type annotated and for which the return expression is an IE and has an
   inferred type, has the corresponding function type.
   * If the return expression has no inferred type it is an error.
   * The inference dependencies are the inference dependencies of the return
   expression.
   * If the function is marked `async`, then the return type of the function is
     inferred as `Future<flatten<T>>` where `T` is the inferred type of the
     return expression and flatten is as described in the spec.
* An instance creation expression with no omitted type arguments has the
   obvious type.
   * No inference dependencies
* An `as` expression has the cast to type
   * No inference dependencies
* An `is` expression has type boolean
   * No inference dependencies
* A simple or qualified identifier referring to a top level function, static
   variable, field, getter; or a static class variable, static getter or method;
   or an instance method; has the inferred type of the identifier.
   * Otherwise, if the identifier has no inferred or annotated type then it is
   an error.
   * Note: specifically, references to instance fields and instance getters are
     disallowed here.
   * The inference dependency of the identifier is itself if the identifier is
      a candidate for inference.  Otherwise there are no inference dependencies.
* A simple identifier denoting a formal parameter which has an annotated type
  and is not a promotion candidate is an immediately evident expression and has
  the type with which it was annotated.
   * Note: the treatment of promotion candidates is still under discussion.
   * No inference dependencies.
* A function (or function expression) invocation with no omitted generic
   arguments where the applicand is an IE that has an inferred type with a
   return type of `T`, has type `T` (with any generic arguments substituted in).
   * If the applicand has no inferred type, it is an error.
   * The inference dependencies are the inference dependencies of the
      applicand.
* A method invocation `o.m(...)` with no omitted type arguments where the
   receiver is an IE with inferred type `T` such that `T` provides a signature
   for `m` with return type `S` has type `S` (with any generic arguments
   substituted in).
   * If the receiver has no inferred type, it is an error.
   * The inference dependencies are the inference dependencies of the receiver.
* A cascade expression `o..e` where `o` is an IE with type `T`, has inferred
   type `T`
   * If the cascade target has no inferred type it is an error.
   * The inference dependencies are the inference dependencies of the cascade
      target.

Note: Assignment expressions are not immediately evident expressions, and
if-null expressions are not immediately evident expressions.
