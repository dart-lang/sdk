# Typing of members of dynamic

**Author**: eernst@.

**Version**: 0.2 (2018-09-04)

**Status**: Background material. Normative text is now in dartLangSpec.tex.

**This document** is a Dart 2 feature specification of the static typing
of instance members of a receiver whose static type is `dynamic`.

This document uses discussions in 
[this github issue](https://github.com/dart-lang/sdk/issues/32414)
as a starting point.


## Motivation

For Dart programs using a statically typed style, it is often helpful to
use the most precise static type for an expression which is still sound.
In contrast, if such an expression gets type `dynamic` it often causes
subsequent type computations such as inference to make less useful
decisions, or it may mask errors which are likely or guaranteed to occur at
run time. Here is an example:

```dart
class A {
  String toString([bool b = true]) =>
      b ? 'This is an A!' : 'Whatever';
}

foo(List<String> xs) {
  for (String s in xs) print(s);
}

main() {
  dynamic d = new A();
  var xs = [d.toString()];
  foo(xs);
}
```

In this example, the actual type argument passed to the list literal
`[d.toString()]` by inference depends on the static type of the expression
`d.toString()`. If that expression is given the type `dynamic` (as it would
be in Dart 1) then the resulting list will be a `List<dynamic>`, and hence
the invocation of `foo` would fail because it requires an argument of type
`List<String>`.

In general, a receiver with static type `dynamic` is assumed to have all
members, i.e., we can make the attempt to invoke a getter, setter, method,
or operator with any name, and we can pass any list of actual arguments and
possibly some type arguments, and that will not cause any compile-time
errors. Various checks may be performed at run time when such an invocation
takes place, and that is the whole point: Usage of expressions of type
`dynamic` allows developers to skip the static checks and instead have
dynamic checks.

However, every object in a Dart program execution has a type which is a
subtype of `Object`. Hence, for each member declared by `Object`, it will
either inherit an implementation declared by `Object`, or it will have some
implementation specified as an override for the declaration in
`Object`. Given that overriding declarations must satisfy certain
constraints, we do know something about the properties of a member declared
in `Object`. This allows static analysis to give static types to some
expressions which are more precise than `dynamic`, even for a member access
where the receiver has type `dynamic`, and that is the topic of this
document.

We will obey the general principle that an instance method invocation
(including getters, setters, and operators) which would be compiled without
errors under some typing of the receiver must also be without compile-time
errors when the receiver has type `dynamic`. It should be noted that there
is no requirement that the typing relies only on declarations which are in
scope at the point where the invocation occurs, it must instead be possible
to _declare_ such a class that the invocation can be statically typed. The
point in obeying this principle is that dynamic invocation should be
capable of performing _every_ invocation which is possible using types.

For instance, `d.toString(42)` cannot have a compile-time error when `d`
has static type `dynamic`, because we could have the following declaration,
and `d` could have had type `D`:

```dart
class D {
  noSuchMethod(Object o) => o;
  Null toString([int i]) => null;
}
```

Similarly, `d.noSuchMethod('Oh!')` would not be a compile-time error,
because a contravariant type annotation on the parameter as shown above
would allow actual arguments of other types than `Invocation`.

On the other hand, it is safe to assign the static type `String` to
`d.toString()`, because that invocation will definitely invoke the
implementation of `toString` in `Object` or an override thereof, and that
override must have a return type which is `String` or a subtype (for
`String` that can only be `Null`, but in general it can be any subtype).

It may look like a highly marginal corner of the language to give special
treatment to the few methods declared in `Object`, but it does matter in
practice that a number of invocations of `toString` are given the type
`String`. Other members like `hashCode` get the same treatment in order to
have a certain amount of consistency.

Moreover, we have considered generalizing the notion of "the type dynamic"
such that it becomes "the type dynamic based on `T`" for any given type
`T`, using some syntax, e.g., `dynamic(T)`. The idea would be that
statically known methods invoked on a receiver of type `dynamic(T)` would
receive static checking, but invocations of other methods get dynamic
checking. With that, the treatment specified in this document (which was
originally motivated by the typing of `toString`) will suddenly apply to
any member declared by `T`, where `T` can be any type (that is, any
declarable member). It is then important to have a systematic approach and
a simple conceptual "story" about how it works, and why it works like
that. This document should be a usable starting point for such an approach
and story.


## Static Analysis

In this section, `Object` denotes the built-in class `Object`, and
`dynamic` denotes the built-in type `dynamic`.

Let `e` be an expression of the form `d.m`, which is not followed by an
argument part, where the static type of `d` is `dynamic`, and `m` is a
getter declared in `Object`; if the return type of `Object.m` is `T` then
the static type of `e` is `T`.

*For instance, `d.hashCode` has type `int` and `d.runtimeType` has type
`Type`.*

Let `e` be an expression of the form `d.m`, which is not followed by an
argument part, where the static type of `d` is `dynamic`, and `m` is a
method declared in `Object` whose method signature has type `F` (*which is
a function type*). The static type of `e` is then `F`.

*For instance, `d.toString` has type `String Function()`.*

Let `e` be an expression of the form `d.m(arguments)` or
`d.m<typeArguments>(arguments)` where the static type of `d` is `dynamic`,
`m` is a getter declared in `Object` with return type `F`, `arguments` is
an actual argument list, and `typeArguments` is a list of actual type
arguments, if present. Static analysis will then process `e` as a function
expression invocation where a function of static type `F` is applied to the
given argument part.

*So `d.runtimeType(42)` is a compile-time error, because it is checked as a
function expression invocation where an entity of static type `Type` is
invoked. Note that it could actually succeed: An overriding implementation
of `runtimeType` could return an instance whose dynamic type is a subtype
of `Type` that has a `call` method. We decided to make it an error because
it is likely to be a mistake, especially in cases like `d.hashCode()` where
a developer might have forgotten that `hashCode` is a getter.*

Let `e` be an expression of the form `d.m(arguments)` where the static type
of `d` is `dynamic`, `arguments` is an actual argument list, and `m` is a
method declared in `Object` whose method signature has type `F`. If the
number of positional actual arguments in `arguments` is less than the
number of required positional arguments of `F` or greater than the number
of positional arguments in `F`, or if `arguments` includes any named
arguments with a name that is not declared in `F`, the type of `e` is
`dynamic`. Otherwise, the type of `e` is the return type in `F`.

*So `d.toString(bazzle: 42)` has type `dynamic` whereas `d.toString()` has
type `String`. Note that invocations which "do not fit" the statically
known declaration are not errors, they just get return type `dynamic`.*

Let `e` be an expression of the form `d.m<typeArguments>(arguments)` where
the static type of `d` is `dynamic`, `typeArguments` is a list of actual
type arguments, `arguments` is an actual argument list. It is a
compile-time error if `m` is a non-generic method declared in `Object`.

*No generic methods are declared in `Object`. Hence, we do not specify that
there must be the statically required number of actual type arguments, and
they must satisfy the bounds. That would otherwise be the consistent
approach, because the invocation is guaranteed to fail when any of those
requirements are violated, but generalizations of this mechanism would need
to include such rules.*

For an instance method invocation `e` (including invocations of getters,
setters, and operators) where the receiver has static type `dynamic` and
`e` does not match any of the above cases, the static type of `e` is
`dynamic`.

When a `cascadeSection` performs a getter or method invocation that
corresponds to one of the cases above, the corresponding static analysis
and compile-time errors apply.

*For instance, `d..foobar(16)..hashCode()` is an error.*

*Note that only very few forms of instance method invocation with a
receiver of type `dynamic` can be a compile-time error. Of course,
some expressions like `x[1, 2]` are syntax errors even though they
could also be considered "invocations", and subexpressions are checked
separately so any given actual argument could be a compile-time 
error. But almost any given argument list shape could be handled via
`noSuchMethod`, and an argument of any type could be accepted because any
formal parameter in an overriding declaration could have its type
annotation contravariantly changed to `Object`. So it is a natural
consequence of the principle mentioned in 'Motivation' that a `dynamic`
receiver admits almost all instance method invocations. The few cases where
an instance method invocation with a receiver of type `dynamic` is an error
are either guaranteed to fail at run time, or they are very likely to be
developer mistakes.*


## Dynamic Semantics

This feature has no implications for the dynamic semantics, beyond the ones
which are derived directly from the static typing.

*For instance, a list literal may have a run-time type which is determined
via inference by the static type of its elements, as in the example in the
'Motivation' section, or the actual type argument may be influenced by the
typing context, which may again depend on the rules specified in this
document.*


## Revisions

- 0.2 (2018-09-04) Adjustment to make `d.hashCode()` and similar
  expressions an error, cf.
  [this github issue](https://github.com/dart-lang/sdk/issues/34320).

- 0.1 (2018-03-13) Initial version, based on discussions in
  [this github issue](https://github.com/dart-lang/sdk/issues/32414).
