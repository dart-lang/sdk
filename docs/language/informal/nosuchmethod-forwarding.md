## Feature: No Such Method Forwarding

Author: eernst@

**Status**: Under discussion.

**Version**: 0.3 (2017-10-05)

**This document** is an informal specification of the support in Dart 2 for
invoking `noSuchMethod` in situations where an attempt is made to invoke a
method that does not exist.

**The feature** described here, *no such method forwarding*, is a particular
approach whereby an implementation of `noSuchMethod` in a class _C_ causes
_C_ to be extended with a set of compiler generated forwarding methods, such
that an invocation of any method in the static interface of _C_ will become
a regular method invocation, which in turn invokes `noSuchMethod`.


## Motivation

In Dart 1.x, `noSuchMethod` will be invoked whenever an attempt is made to
call a method that does not exist.

In other words, consider an instance method invocation of a member named
_m_ on a receiver _o_ whose class _C_ does not have a member named _m_ (or
it has a member named _m_, but it does not admit the given invocation,
e.g., because the number of arguments is wrong). If _C_ declares or inherits
an implementation of the method `noSuchMethod` which is distinct from the
one in the built-in class `Object`, the properties of the invocation are
specified using an instance _i_ of `Invocation`, and `noSuchMethod` is then
invoked with _i_ as the actual argument. Among other things, _i_ specifies
whether the invocation was a method call or an invocation of a getter or a
setter, and it specifies which actual arguments were passed.

One difficulty with this design is that it requires developers to take
both method invocations and getter invocations into account, in order to
support a given method using `noSuchMethod`:
```dart
class Foo {
  foo(x) {}
}

class MockFoo implements Foo {
  // PS: Make sure that a tear-off of `_mockFoo` has the same type
  // as a tear-off of `Foo.foo`.
  _mockFoo(x) {
    // ... implement mock behavior for `foo` here.
  }

  noSuchMethod(Invocation i) {
    if (i.memberName == #foo) {
      if (i.isMethod &&
          i.positionalArguments.length == 1 &&
          i.namedArguments.isEmpty) {
        return _mockFoo(i.positionalArguments[0]);
      } else if (i.isGetter) {
        return _mockFoo;
      }
    }
    return super.noSuchMethod(i);
  }
}
```
The reason why the type of a tear-off of `_mockFoo` should be the same
as the type of a tear-off of `foo` is that the former should be able to
emulate the properties of the latter faithfully, including the response
it gives rise to when subjected to type tests, either explicitly or
implicitly.

Obviously, this is verbose, tedious, and difficult to maintain if the
claimed superinterfaces (`implements ...`) in the mock class introduce
a large number of methods with complex signatures. It is particularly
inconvenient if the mock behavior is simple and largely independent of
all those types.

The no such method forwarding approach eliminates much of this tedium
by means of compiler-generated forwarding methods corresponding to all
the unimplemented methods. The example could then be expressed as
follows:
```dart
class Foo {
  foo(x) {}
}

class MockFoo implements Foo {
  noSuchMethod(Invocation i) {
    if (i.memberName == #foo) {
      if (i.isMethod &&
          i.positionalArguments.length == 1 &&
          i.namedArguments.isEmpty) {
        // ... implement mock behavior for `foo` here.
      }
    }
    return super.noSuchMethod(i);
  }
}
```
With no such method forwarding, this causes a `foo` forwarding
method to be generated, with the signature declared in `Foo`
and with the necessary code to create and initialize a suitable
`Invocation` which will be passed to `noSuchMethod`.


## Syntax

This feature does not include any grammar modifications.


## Static Analysis

We say that a class _C_ _has a non-trivial_ `noSuchMethod` if _C_ declares
or inherits a non-abstract method named `noSuchMethod` which is distinct
from the declaration in the built-in class `Object`.

*Note that such a declaration cannot be a getter or setter, and it must
accept one positional argument of type `Invocation`, due to the
requirement that it must correctly override the declaration of
`noSuchMethod` in `Object`.*

*We introduce the notion of methods which are 'considered to be
implemented'. These methods are exactly the ones that we will generate
forwarders for, except that we keep the language slightly more abstract,
such that the ability to use a different implementation technique remains
open. During static analysis, "considering" these methods to be implemented
allows the enclosing class to be non-abstract, with no errors.*

If a non-abstract class _C_ has a non-trivial `noSuchMethod`, _C_ is
_considered to declare an implementation_ for each method, getter, and
setter which is a member of _C_'s interface, unless _C_ declares or
inherits an implementation of it.

*Note that it is a compile-time error if a class _C_ has multiple
superinterfaces with a member named _m_, declared by declarations _D1
.. Dk_, and there is no declaration of _m_ in _C_, and there is no
declaration among _D1 .. Dk_ which is a correct override of every
declaration in _D1 .. Dk_. In other words, we ignore the situation where a
class is considered to implement a member _m_, but the signature of _m_ is
ambiguous, because it is based on a set of declarations that does not
contain a "most specific" element: That situation is an error, so we do not
need to handle it.*

It is a compile-time error if _C_ is considered to declare an
implementation of a method declaration _D_, and such an implementation
would override an inherited non-abstract declaration.

*This can only happen if the given implementation satisfies some, but not
all requirements. In the example below, a `foo(int i)` implementation is
inherited and a superinterface declares `foo([int i])`. This is a
compile-time error because it would be error prone to generate a forwarder
in `C` which will silently override an implementation which "almost"
satisfies the requirement in the superinterface.*

```dart
class A {
  foo(int i) => null;
}

abstract class B {
  foo([int i]);
}

class C extends A implements B {
  noSuchMethod(Invocation i) => ...;
  // Error on `foo`: Forwarder would override `A.foo`.
}
```

*This error can be eliminated by adding a disambiguating abstract method
declaration to `C` for `foo`.*

```dart
// class A and B are unchanged from the previous example.

class C extends A implements B {
  noSuchMethod(Invocation i) => ...;
  foo([int i]); // No ambiguity; will forward to `noSuchMethod`.
}
```

*Note that it is _not_ a compile-time error if _C_ is considered to declare an
implementation of a method declaration _D_, and such an implementation
would override an inherited declaration with the same name that some
superclass is considered to have. In other words, it is OK for a generated
forwarder to override another generated forwarder.*

*Note that when a class _C_ is considered to declare an implementation of a
given member, it allows superinvocations in subclasses.*

```dart
abstract class D { baz(); }
class E implements D {}
class F extends E { baz() { super.baz(); }} // OK
```


## Dynamic Semantics

Consider a program _P_ that contains a non-abstract class _C_ which has a
non-trivial `noSuchMethod`, and for which some methods, getters, or setters
_m1 .. mk_ are considered to be implemented, as defined in the previous
section.

*This means that _m1 .. mk_ are present in the interface of _C_, but they
do not have an implementation, except for special cases like when the
implementation is a generated forwarder in a superclass of _C_ which
is not a correct override of the method in the interface of _C_.*

The semantics of _P_ is then such that it behaves as if _C_ had been
modified by adding declarations of _m1 .. mk_ with the signatures
declared in the interface of _C_, and with an implementation of each
member _mj_. That implementation will invoke `noSuchMethod` on `this`
with an `Invocation` as argument which specifies the bindings of the
formal parameters to the actual arguments, and indicates whether _mj_ is a
method, getter, or setter.

*This ensures, relying on the heap soundness and expression soundness of
Dart (which ensures that every expression of type _T_ will evaluate to an
entity of type _T_), that all statically type safe invocations will invoke
regular method implementations, user-written or generated. In other words,
with statically checked calls there is no need for dynamic support for
`noSuchMethod` at all.*

*The generated forwarding methods behave in the same way as user-written
method declarations. For instance, dynamic type checks are performed on the
actual arguments when the corresponding formal parameter is covariant. A
generated forwarding method may have optional arguments with default
values. Given that there is always exactly one user-written signature which
is selected to be the signature of the forwarding method, these default
values are uniquely determined, and they work the same way as default
values do in a user-written method.*

For a dynamic invocation of a member _m_ on a receiver _o_ that has a
non-trivial `noSuchMethod`, the semantics is such that an attempt to invoke
_m_ with the given actual arguments (including possibly some type
arguments) is made at first; if that fails (*because _o_ has no
implementation of _m_ which can be invoked with the given argument list
shape, be it a regular method or a generated forwarder*) `noSuchMethod` is
invoked with an actual argument which is an `Invocation` describing the
actual arguments and invocation.

*This implies that dynamic invocations on receivers having a non-trivial
`noSuchMethod` will simply invoke the forwarders whenever possible.
Similarly, the "automatic" support for tearing off a method in the static
interface of the receiver which is not implemented, but supported via
`noSuchMethod` and a generated forwarder will still work for dynamic
invocations, as well as static ones.*

*The only remaining situation is when a dynamic invocation invokes a method
which is not present in the static interface of the receiver, or when a
method with that name is present, but its signature does not allow for the
given invocation (e.g., because there are too few positional arguments).
In this situation, the regular instance method invocation has failed (there
is no such regular method, and no such generated forwarder). Such a dynamic
invocation must then dynamically determine whether the given receiver has a
non-trivial `noSuchMethod` and invoke it, rather than just invoking the
behavior of `noSuchMethod` in `Object` immediately (that is, throwing a
`NoSuchMethodError`). In this situation, `noSuchMethod` must also support
both method invocations and tear-offs, because there is no generated
forwarder to do that.*

*This approach may incur a certain performance penalty, but only for these
invocations (which are dynamic, and have already failed to invoke an
existing method, regular or generated).*

*In return, this approach enforces the following simple invariant, for both
statically checked and dynamic invocations: Whenever an instance method is
invoked, and no such method exists, `noSuchMethod` will be invoked.*

*Note that this allows dynamic code to support types that have conflicting
signatures. For instance, it would be possible to create a class having a
non-trivial `noSuchMethod` that accepts dynamic invocations corresponding
to having both a getter `int get foo` and a method `int foo()`, even though
that could never be achieved for the actual interface of the class of an
instance. This will allow dynamic code to be more generic than typed code
could be, of course, at the expense of being forced to remain dynamically
typed as long as these conflicting interfaces are used together.*


## Updates

*   Oct 5th 2017, version 0.3: Clarified that generated forwarders must
    pass an `Invocation` to `noSuchMethod` which specifies the bindings
    of formal arguments to actual arguments. Clarified the treatment of
    default values for optional arguments.

*   Sep 20th 2017, version 0.2: Many smaller adjustments, based on review
    feedback.

*   Sep 18th 2017, version 0.1: Created the first version of this document.
