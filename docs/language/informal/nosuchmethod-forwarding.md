## NoSuchMethod Forwarding

Author: eernst@

**Status**: Background material, normative language now in dartLangSpec.tex.

**Version**: 0.7 (2018-07-10)

**This document** is an informal specification of the support in Dart 2 for
invoking `noSuchMethod` in situations where an attempt is made to invoke a
method that does not exist.

**The feature** described here, *noSuchMethod forwarding*, is a particular
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
e.g., because the number of arguments is wrong). The properties of the
invocation are then specified using an instance _i_ of `Invocation`, and
`noSuchMethod` is then invoked with _i_ as the actual argument. Among other
things, _i_ specifies whether the invocation was a method call or an
invocation of a getter or a setter, and it specifies which actual arguments
were passed.

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

The noSuchMethod forwarding approach eliminates much of this tedium
by means of compiler generated forwarding methods corresponding to all
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
With noSuchMethod forwarding, this causes a `foo` forwarding
method to be generated, with the signature declared in `Foo`
and with the necessary code to create and initialize a suitable
`Invocation` which will be passed to `noSuchMethod`.


## Syntax

The grammar remains unchanged.


## Static Analysis

We say that a class _C_ _has a non-trivial_ `noSuchMethod` if _C_ declares
or inherits a concrete method named `noSuchMethod` which is distinct
from the declaration in the built-in class `Object`.

*Note that such a declaration cannot be a getter or setter, and it must
accept one positional argument of type `Invocation`, due to the
requirement that it must correctly override the declaration of
`noSuchMethod` in the class `Object`. For instance, in addition to the
obvious choice `noSuchMethod(Invocation i)` it can be
`noSuchMethod(Object i, [String s])`, but not
`noSuchMethod(Invocation i, String s)`.*

If a concrete class _C_ has a non-trivial `noSuchMethod` then each
method signature (including getters and setters) which is a member of _C_'s
interface and for which _C_ does not have a concrete declaration is
_noSuchMethod forwarded_.

A concrete class _C_ that does _not_ have a non-trivial `noSuchMethod`
implements its interface (*it is a compile-time error not to do so*), but
there may exist superclasses of _C_ declared in other libraries whose
interfaces include some private methods for which _C_ has no concrete
declaration (*such members are by definition omitted from the interface of
_C_, because their names are inaccessible*). Similarly, even if a class _D_
does have a non-trivial `noSuchMethod`, there may exist abstract
declarations of private methods with inaccessible names in superclasses of
_D_ for which _D_ has no concrete declaration. In both of these situations,
such inaccessible private method signatures are _noSuchMethod forwarded_.

No other situations give rise to a noSuchMethod forwarded method
signature.

*This means that whenever it is stated that a class _C_ has a noSuchMethod
forwarded method signature, it is guaranteed to be a concrete class with a
non-trivial `noSuchMethod`, or the signature is guaranteed to be
inaccessible. In the former case, the developer expressed the intent to
obtain implementations of "missing methods" by having a non-trivial
`noSuchMethod` declaration, and in the latter case it is impossible to
write declarations in _C_ that implement the missing private methods, but
they will then be provided as generated forwarders.*

If a class _C_ has a noSuchMethod forwarded signature then an implicit
method implementation implementing that method signature is induced in _C_.
In the case where _C_ already contains an abstract declaration with the
same name, the induced method implementation replaces the abstract
declaration.

It is a compile-time error if a concrete class _C_ has a non-trivial
`noSuchMethod`, and a name `m` has a set of method signatures in the
superinterfaces of _C_ where none is most specific, and there is no
declaration in _C_ which provides such a most specific method signature.

*This means that even in the situation where everything else implies that a
noSuchMethod forwarder should be induced, signature ambiguities must still
be resolved by a developer-written declaration, it cannot be a consequence
of implicitly inducing a noSuchMethod forwarder. However, that
developer-written declaration could be an abstract method in the
concrete class itself.*

*Note that there is no most specific method signature if there are several
method signatures which are equally specific with respect to the argument
types and return type, but an optional formal parameter in these signatures
has different default values in different signatures.*

It is a compile-time error if a class _C_ has a noSuchMethod forwarded
method signature _S_ for a method named _m_, as well as an implementation
of _m_.

*This can only happen if that implementation is inherited and satisfies
some, but not all requirements of the noSuchMethod forwarded method
signature. In the example below, a `foo(int i)` implementation is inherited
and a superinterface declares `foo([int i])`. This is a compile-time error
because `C` does not have a method implementation with signature
`foo([int])`, but if one were to be implicitly induced it would override
`A.foo` (which is capable of accepting some but not all of the argument
lists that an implementation of `foo([int])` would allow). We have made
this an error because it would be error prone to induce a forwarder in `C`
which will silently override an `A.foo` which "almost" satisfies the
requirement in the superinterface. In particular, developers are likely to
be surprised if `A.foo` is not called even when it is passed a single
`int` argument, which precisely matches the declaration of `A.foo`.*

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

*Note that this makes it a breaking change, in situations where such a
signature conflict exists in some subtype like `C`, to change an abstract
method declaration to a method implementation: If `A` had been an abstract
class and `A.foo` an abstract method which was replaced by an `A.foo`
declaration which implements the method, the error on `foo` in class `C`
would be introduced because `A.foo` was implemented. There is a reasonably
practical workaround, though: implement `C.foo` with a signature that
resolves the conflict. That implementation might invoke `A.foo` in a
superinvocation, or it might forward to `noSuchMethod`, or some times one
and some times the other, that is up to the developer who writes `C.foo`.*

*Note that it is _not_ a compile-time error if the interface of _C_ has a
noSuchMethod forwarded method signature _S_ with name _m_, and a superclass
of _C_ also has a noSuchMethod forwarded method signature named _m_, such
that the implicitly induced implementation of the former overrides the
implicitly induced implementation of the  latter. In other words, it is OK
for a generated forwarder to override another generated forwarder.*

*Note that when a class _C_ has an implicitly induced implementation of a
method, superinvocations in subclasses are allowed, just like they would
have been for a developer-written implementation.*

```dart
abstract class D { baz(); }
class E implements D {
  noSuchMethod(Invocation i) => null;
}
class F extends E { baz() { super.baz(); }} // OK
```


## Dynamic Semantics

Assume that a class _C_ has an implicitly induced implementation of a
method _m_ with positional formal parameters
_T<sub>1</sub> a<sub>1</sub>..., T<sub>k</sub> a<sub>k</sub>_
and named formal parameters
_T<sub>k+1</sub> n<sub>1</sub>..., T<sub>k+m</sub> n<sub>m</sub>_.
Said implementation will then create an instance _i_ of the predefined
class `Invocation` such that its

-   `isGetter` evaluates to true iff _m_ is a getter,
    `isSetter` evaluates to true iff _m_ is a setter,
    `isMethod` evaluates to true iff _m_ is a method.
-   `memberName` evaluates to the symbol for the name _m_.
-   `positionalArguments` evaluates to an immutable list whose
    values are _a<sub>1</sub>..., a<sub>k</sub>_.
-   `namedArguments` evaluates to an immutable map with the same keys
    and values as
    _{n<sub>1</sub>: n<sub>1</sub>..., n<sub>m</sub>: n<sub>m</sub>}_

*Note that the number of named arguments can be zero, in which case some of
the positional parameters can be optional. We do not need to mention
optional positional arguments separately, because they receive the same
treatment as required parameters (which are of course always positional).*

Finally the induced method implementation will invoke `noSuchMethod` with
_i_ as the actual argument, and return the result obtained from there.

*This determines the dynamic semantics of implicitly induced methods: The
declared return type and the formal parameters, with type annotations and
default values, are uniquely determined by the noSuchMethod forwarded
method signatures, and invocation of an implicitly induced method has the
same semantics of invocation of other methods. In particular, dynamic type
checks are performed on the actual arguments upon invocation when the
corresponding formal parameter is covariant.*

*This ensures, relying on the heap soundness and expression soundness of
Dart (which ensures that every expression of type _T_ will evaluate to an
entity of type _T_), that all statically type safe invocations will invoke
a method implementation, user-written or implicitly induced. In other
words, with statically checked calls there is no need for dynamic support
for `noSuchMethod` at all.*

For a dynamic invocation of a member _m_ on a receiver _o_ that has a
non-trivial `noSuchMethod`, the semantics is such that an attempt to invoke
_m_ with the given actual arguments (including possibly some type
arguments) is made at first. If that fails (*because _o_ has no
implementation of _m_ which can be invoked with the given argument list
shape, be it a developer-written method or an implicitly induced
implementation*) `noSuchMethod` is invoked with an actual argument which is
an `Invocation` describing the actual arguments and invocation.

*This implies that dynamic invocations on receivers having a non-trivial
`noSuchMethod` will simply invoke the forwarders whenever possible.
Similarly, it will work for dynamic invocations as well as statically
checked ones to tear off a method which is in the interface of the receiver
and implemented as a generated forwarder.*

*The only remaining situation is when a dynamic invocation invokes a method
which is not present in the static interface of the receiver, or when a
method with that name is present, but its signature does not allow for the
given invocation (e.g., because some required arguments are omitted). In
this situation, the regular instance method invocation has failed (there is
no such regular method, and no such generated forwarder). Such a dynamic
invocation will then invoke `noSuchMethod`. In this situation, a
developer-written implementation of `noSuchMethod` should also support both
method invocations and tear-offs explicitly (as it should before this
feature was added), because there is no generated forwarder to do that.*

*This approach may incur a certain performance penalty, but only for these
invocations (which are dynamic, and have already failed to invoke an
existing method, regular or generated).*

*In return, this approach enforces the following simple invariant, for both
statically checked and dynamic invocations: Whenever an instance method is
invoked, and no such method exists, `noSuchMethod` will be invoked.*

*One special case to be aware of is where a forwarder is torn off and then
invoked with an actual argument list which does not match the formal
parameter list. In that situation we will get an invocation of
`Object.noSuchMethod` rather than the `noSuchMethod` in the original
receiver, because this is an invocation of a function object (and they do
not override `noSuchMethod`):*

```dart
class A {
  dynamic noSuchMethod(Invocation i) => null;
  void foo();
}

main() {
  A a = new A();
  dynamic f = a.foo;
  // Invokes `Object.noSuchMethod`, not `A.noSuchMethod`, so it throws.
  f(42);
}
```


## Updates

*   Jul 10th 2018, version 0.7: Added requirement to generate forwarders
    for inaccessible private methods even in the case where there is no
    non-trivial `noSuchMethod`.

*   Mar 22nd 2018, version 0.6: Added example to illustrate the case where a
    torn-off method invokes `Object.noSuchMethod`, not the one in the
    receiver, because of a non-matching actual argument list.

*   Nov 27th 2017, version 0.5: Changed terminology to use 'implicitly
    induced method implementations'. Helped achieving a major simplifaction
    of the dynamic semantics.

*   Nov 22nd 2017, version 0.4: Removed support for explicitly requesting
    generated forwarder in conflict case. Improved the clarity of many
    parts.

*   Oct 5th 2017, version 0.3: Clarified that generated forwarders must
    pass an `Invocation` to `noSuchMethod` which specifies the bindings
    of formal arguments to actual arguments. Clarified the treatment of
    default values for optional arguments.

*   Sep 20th 2017, version 0.2: Many smaller adjustments, based on review
    feedback.

*   Sep 18th 2017, version 0.1: Created the first version of this document.
