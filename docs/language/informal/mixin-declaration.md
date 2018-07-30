# Dart 2.0 Mixins

**Author**: [lrn@google.com](mailto:lrn@google.com)

**Version**: 0.7 (2018-06-21)

**Status**: Mostly designed, ready for external comments.

## Proposal
This proposal introduces a new syntax for declaring mixins, separate from deriving a mixin from a class declaration. It expects to deprecate and remove the ability to derive a mixin from a class declaration, but doesn't require it.


## Background

Dart 1 mixins have the following features:

*   Derived from a class declaration.
*   Applied to a superclass to create a new class.
*   May be derived from class with super-class, then application must be on class implementing super-class interface.
*   May have super-invocations if the mixin class has a super-class.
*   Cannot have generative constructors.
*   Mixin application forwards some constructors.

There are a number of problems with this approach, especially the super-class constraints.

*   The super-calls (`super.foo()`) are not statically guaranteed to hit a matching method. There is no specified static check of a mixin application that ensures that any mixed-in methods containing a super-call will actually hit an existing method. If the superclass is abstract, the super-call may fail dynamically.
*   Deriving a mixin from a class means that moving a method from the class to its superclass is a breaking change, not just a refactoring. Many class changes that are generally considered safe in OO languages are breaking if the class is used as a mixin. For that reason, we have guidelines saying not to use a class as a mixin unless it's documented as being intended as such (the creator has opted in to the extra constraints).
*   The super-class constraint on a "mixin" is derived from the `extends` clause which only allows a single type. There is no way to specify two requirements, and users trying to do so ends up with code that doesn't work like they expect.
*   A mixin derived from a mixin-application might have a different super-class than expected.
*   Nobody understands how the super-feature actually works (http://dartbug.com/29758, http://dartbug.com/25765)
*   When any class can be used as a mixin, there are local optimizations that cannot be performed (like DDC not being able to detect that a private field isn't overridden). Also, if a class that is not intended as a mixin is used as a mixin, many otherwise safe refactorings (e.g., moving a method to a superclass) will be breaking.


### Mixin Declaration

To avoid some of the problems mentioned above, we introduce a *mixin declaration syntax* separate from class declarations:

*mixinDeclaration* : *metadata*? 'mixin' *identifier* *typeParameters*?  <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;('on' *types*)? ('implements' *types*)? '{' <em>mixinMember</em>* '}'

The `mixinMember` production allows the same instance or static members that a class would allow, but no constructors (for now).

The `mixin` word will have to be at least a **built-in identifier** to avoid parsing ambiguities. It does not need to be a reserved word.

It might be possible to just use `mixin` as a contextual keyword, but it would require some look-ahead to determine whether an occurrence is a type named `mixin` or a mixin declaration, and we would like to discourage the former anyway.


#### Meaning

A mixin declaration introduces a mixin and an *interface*, but *not a class*. The mixin introduced by a mixin declaration contains all the non-static members declared by the mixin, just as the mixin derived from a class declaration currently does.

In a mixin declaration like `mixin A on B, C implements D, E { body }`
the `on` clause declares the interfaces `B` and `C` as *super-class constraints* of the mixin. Having a super-class constaint allows the mixin declaration instance members to perform super-invocations (like `super.foo()`) if they are allowed by
a class implementing both `B` and `C`.
The mixin introduced by `A` can then only be applied to classes that implement both `B` and `C`.

Further, the interfaces `B` and `C` must be *compatible*. The `on` clause introduces a synthetic interface combining `B` and `C`, call it `A$super`, which is equivalent
to the interface of a class declaration of the form:
```dart
abstract class A$super implements B, C {}
```
It is a compile-time error for the mixin declaration if the class declaration above would not be valid. This ensures that if more than one super-constraint interface declares a member with the same name, at least one of those members is more specific than the rest, and this is the unique signature that super-invocations are allowed to invoke.

A mixin declaration defines an interface. The interface for this mixin declaration is equivalent to the interface of the class declared as:
```dart
abstract class A implements A$super implements D, E { body' }
```
where `body'` contains abstract declarations corresponding to the instance members of `body` of the mixin `A`.

It is a compile time error for the mixin declaration if this class declarations would not be valid.

An omitted `on` clause is equivalent to `on Object`.

It's a static warning (strong-mode error) if an instance method in a mixin body has a super-access (`super.foo`, `super.foo()`, `super + bar`, etc.) which would not be a valid invocation if `super` was replaced with an expression with static type `A$super`.

A mixin cannot be marked as `abstract`.
All mixins are effectively abstract because they don't need to implement the members of the required superclass types.
We could say that a mixin must implement all other members than the ones declared by the required superclass types, and then allow the declaration to be marked as `abstract` if it doesn't.
It would still require mixin applications to be marked independently, so there is no large advantage to marking the mixin itself as non-abstract.

### Mixin application

Mixin application syntax is unchanged.

Mixin application semantics is mostly unchanged, except that it's a compile-time error to apply a mixin to a class that doesn't implement *all* the `on` type requirements of the mixin declaration, or apply a mixin containing super-invocations to a class that doesn't have a concrete implementation of the super-invoked members compatible with the super-constraint interfaces.

Forwarding constructors are introduced in the same way as they currently are.

#### Super-calls of mixin applications must be valid

The Dart 1 specification doesn't warn at compile-time if a `super`-invocation targets an abstract method. This allows declaring a mixin that extends an abstract interface, but it also means that mistakes are only runtime-errors. We want to fix that.

*   One solution is to *require the superclass of a mixin application to be non-abstract*. This would ensure that all `super`-invocations in mixin applications are valid. The mixin declaration only allows `super`-invocations declared by their `on` constraints and the mixin application requires the superclass to satisfy those constraints, and by also being non-abstract, there must be an actual implementation of the superclass method. That's probably too restrictive in practice, though (e.g., `class UnmodifiableListBase<T> = ListBase<T> with UnmodifiableListMixin<T>;` is reasonable even if `ListBase` is abstract).
*   Alternatively, we only make it a compile-time error if a mixin  method on the mixin contains a super-access (<code>super.<em>x</em></code>, <code>super.<em>x</em>(...)</code>, <code>super <em>op</em> arg</code>, etc), and the actual superclass of the mixin application doesn't have an implementation of *x*/*op* compatible with the one in interface `A$super`.
This requires a mixin application to check whether the superclass has a
concrete implementation of any member of `A$super` which is used by a super-invocation.
Obviously, if the superclass is not abstract, this check won't be necessary.

The latter option is the more permissive one, but that also comes with a cost of maintainability and usability. If a mixin adds a new super-invocation, then it may break existing mixin applications. It's not possible to see the actual requirements of the mixin from its type signature alone.

If the requirement is just that the superclass is non-abstract (first option), there are no hidden or fragile constraints in the relation between the mixin and the superclass. However it's likely too restrictive in practice, and there is no work-around if you do want to apply a mixin to an abstract class (short of adding throwing implementations of the missing methods, which is not something to encourage).

In either case, this requirement is new. The Dart 1 specification doesn't have it, instead it just silently accepts a mixin application on an abstract superclass that doesn't actually implement the super-member, and the call will fail at runtime.


#### Extending a Mixin
Current Dart classes can be used as superclasses, mixins and interfaces.
A mixin declaration does not introduce a class, but we can, and probably should,
allow *extending* the mixin as a shorthand for extending `Object` with the mixin applied.

That is:

```dart
mixin M {
  String toString() => "Magnificent!";
}
class C extends M {
  ...
}
```

would be equivalent to:

```dart
mixin M {
  String toString() => "Magnificent!";
}
class C extends Object with M {
  ...
}
```

as long as `M` has no `on` clause requiring a class different from `Object`.

This allows easier migration from existing classes that are used as both
superclass and mixin.


### Potential future changes

#### Deprecating derived mixins

In a future version of Dart, we'll remove the ability to derive a mixin from a class declaration.

This requires existing code to be rewritten. The rewrite is simple:

If the class is only used as a mixin,

```dart
class FooMixin extends S implements I {
  members;
}
```

becomes

```dart
mixin FooMixin on S implements I {
  members;
}
```

If the class is *actually* used as both a class and a mixin, and `S` is not `Object`,
the mixin needs to be extracted:

```dart
class Foo extends S implements I {  // Used as mixin *and* class
  members;
}
```

becomes

```dart
class Foo extends S with FooMixin {
  static members
}
mixin FooMixin on S implements I {
  instance members (references to statics prefixed with "Foo.")
}
// All uses of "with Foo" changed to "with FooMixin".
```

Apart from static members (which are rare) this is basically a two line rewrite locally, and then finding the uses of the class as a mixin. Any missed use of `Foo` as a mixin will be a compile-time error, so the uses are easy to find.

Private static members can be placed in either class, and mayb fit better in the mixin class if they are only used by instance members. Putting them in `Foo` ensures that uses outside of the class, but still in the same library, do not need to be changed.

#### Possible related features ####

We may want to allow omitting `extends Object` from 
`class C extends Object with Mixin {}`, 
writing it simply as `class C with Mixin {}`.
The `extends Object` is not necessary when declaring a class with no mixin,
and the syntax is still easy to parse since `with` cannot occur in that
position with any other meaning.

This is not a necessary change, but it make some existing code 
which `extends` a mixin-class slightly easier to port.

#### Further extensions of the feature

With separate syntax for mixins, we are open to adding more capabilities without needing it to also work for classes.

Options are:

*   Composite mixins (mixin can `extend` another mixin, application applies both).
*   Constructors (mixin constructors don't forward to the superclass, only to a super-mixin). If a mixin has generative constructors (and even const ones), there will be no automatic constructor forwarding because the mixin-application class would need to call the mixin constructor explicitly. It can be omitted if the mixin has a no-arguments constructor, which it will then have by default.


### Revisions

v0.5 (2017-06-12) Initial version

v0.6 (2017-06-14) Say `mixin` must be built-in identifier.

v0.7 (2018-06-21) Change `required` to `on` and remove Dart 1 specific things.
