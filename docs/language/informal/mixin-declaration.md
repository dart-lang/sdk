# Dart 2.0 Mixins

Author: [lrn@google.com](mailto:lrn@google.com)

Version 0.6 (2017-06-14)

Status: Mostly designed, ready for external comments.

## Proposal
This proposal introduces a new syntax for declaring mixins, separate from deriving a mixin from a class declaration. It expects to deprecate and remove the ability to derive a mixin from a class declaration, but doesn't require it.


## Background

Dart 1 mixins have the following features:

*   Derived from a class declaration.
*   Applied to a superclass to create a new class.
*   May be derived from class with super-class, then application must be on class implementing super-class interface.
*   May have super-invocations if the mixin class has a super-class.
*   Cannot have generative constructors.
*   Mixin application forwards non-const constructors.

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
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;('requires' *types*)? ('implements' *types*)? '{' <em>mixinMember</em>* '}'

The `mixinMember` production allows the same instance or static members that a class would allow, but no constructors (for now).

The `mixin` word will have to be at least a **built-in identifier** to avoid parsing ambiguities. It does not need to be a reserved word.

It might be possible to just use `mixin` as a contextual keyword, but it would require some look-ahead to determine whether an occurrence is a type named `mixin` or a mixin declaration, and we would like to discourage the former anyway.

#### Meaning

A mixin declaration introduces a mixin and an *interface*, but *not a class*. The mixin derived from a mixin declaration contains all the non-static members declared by the mixin, just as the mixin derived from a class currently does.

The interface of `mixin A requires B, C implements D, E { body }`, which has the same name as the mixin (`A` here), is equivalent to the interface that would be derived from the class declaration:
```dart
abstract class A implements B, C, D, E { body' }
```
where `body'` contains abstract declarations corresponding to the instance members of `body` of the mixin `A`.

The `requires` keyword on the mixin declaration is open for discussion. It's better than `super`, but fairly long. Another option is `on`.

It's a static warning (strong-mode error) if an instance method in a mixin body has a super-access (`super.foo`, `super.foo()`, `super + bar`, etc.) that is

*   not declared by at least one of the *types* in the mixin's `requires` declaration, or
*   not type-compatible with at least one such declaration from a `requires` type.

The mixin cannot be marked as `abstract`.
All mixins are effectively abstract because they don't need to implement the members of the required superclass types.
We could say that a mixin must implement all other members than the ones declared by the required superclass types, and then allow the declaration to be marked as `abstract` if it doesn't.
It would still require mixin applications to be marked independently, so there is no large advantage to marking the mixin itself as non-abstract.


### Mixin application

Mixin application syntax is unchanged. A mixin application `S with M` introduces a *class* with superclass `S`, implementing `M` and with copies of all the non-static members of `M`. As usual code in the copies of members retain the static scope of their original declaration.

In a mixin application declaration `class C = S with M;`, the class is named `C`, otherwise it has a fresh name (it's effectively anonymous since nobody knows its name, but it needs a name because constructor names include the class name and forwarding constructors need to have names).

Multiple applications introduce a chain of classes, so `S with M1, M2` has an anonymous `S with M1` application class as superclass and applies `M2` to that.

Mixin application semantics is mostly unchanged, except that it's a static warning (strong mode error) to apply a mixin to a class that doesn't implement *all* the `requires` types of the mixin declaration.

All non constructors of the superclass causes a forwarding constructor to be added to the mixin application with the same arguments.


#### Super-calls of mixin applications must be valid

Currently, the specification doesn't warn at compile-time if a `super`-invocation targets an abstract method. This allows declaring a mixin that extends an abstract interface, but it also means that mistakes are only runtime-errors. We want to fix that.

*   One solution is to *require the superclass of a mixin application to be non-abstract*. This would ensure that all `super`-invocations in mixin applications are valid. The mixin declaration only allows `super`-invocations declared by their `requires` constraints and the mixin application requires the superclass to satisfy those constraints, and by also being non-abstract, there must be an actual implementation of the superclass method.
*   Alternatively, we only make it a compile-time error if a mixin application introduces a method on the mixin application class which contains a super-access (<code>super.<em>x</em></code>, <code>super.<em>x</em>(...)</code>, <code>super <em>op</em> arg</code>, etc), and the actual superclass of the mixin application doesn't have a non-abstract implementation of a member with *that* name.
(The compile-time error applies to the mixed-in method with the super-call, so a lazy-compile-time-error implementation can fail to compile that method only.)

Obviously, if the superclass is not abstract, this check won't be necessary.

*   As a third alternative, we can add syntax to explicitly declare and expose the super constraints. Syntax could be like an abstract method that is marked as "super", perhaps one of:

```
int super.foo(int bar);
super int foo(int bar);
super {
  int foo(int bar);  // and perhaps multiple declaration in the block.
}
super foo;  // comma separated list of just the names.
super { foo }; // ditto.
```


The block approach is unlike anything else we do in Dart. The `super.foo` declaration is also different from other syntax and would complicate the grammar more than just a prefixed `super`, but if it's easier to understand for the user, it's probably worth it.

Just mentioning the super-member by name is shorter, and since the required super-types are specified elsewhere, it should be sufficient, but it's not as readable as a full declaration.

With any of these syntaxes, the mixin declaration explicitly declares which super-calls it uses, so the user can be aware of it.

On the other hand, that means duplication (you already make the super-call, now you also repeat it as a declaration) and it still locks you into not being able to do more super-calls in the future without breaking things.

If the constraints are handled entirely structurally, and don't need to be linked to a declared required superclass constraint, it would allow mixins to be used on arbitrary objects that satisfy the constraint, but that would also be the only place in Dart where we have a structural constraint on classes. I would recommend only allowing references to members of the already required superclasses.


The second and third options are the more permissive ones, but that also comes with a cost of maintainability and usability. If a mixin adds a new super-invocation, then it may break existing mixin applications. It's not possible to see the actual requirements of the mixin from its type signature alone - in the third option, a new syntax is introduced to represent the requirement.

If the requirement is just that the superclass is non-abstract (first option), there are no hidden or fragile constraints in the relation between the mixin and the superclass. For that reason, I recommend we pick the that approach (require that the superclass of a mixin application is not abstract) and potentially loosen it later if necessary - adding explicit super-requirements would then allow abstract superclasses that satisfy the requirements, not writing anything still works with a non-abstract superclass.

We should check whether that is a problem for existing code that has an abstract superclass for a mixin application.

In either case, this requirement is new. The current specification doesn't have it, instead it just silently accepts a mixin application on an abstract superclass that doesn't actually implement the super-member, and the call will fail at runtime.


### Potential future changes


#### Deprecating derived mixins

In the future, preferably already in Dart 2.0, we'll remove the ability to derive a mixin from a class declaration.

The requires existing code to be rewritten. The rewrite is simple:


```dart
class FooMixin extends S implements I {
   members;
}
```

becomes

```dart
mixin FooMixin requires S implements I {
  members;
}
```

If a class is *actually* used as both a class and a mixin, the mixin needs to be extracted:

```dart
class Foo extends S implements I {  // Used as mixin *and* class
  members;
}
```

becomes

```dart
class Foo = S with FooMixin {
  public static members
}
mixin FooMixin requires S implements I {
  instance members (references to statics prefixed with "Foo.")
}
// All uses of "with Foo" changed to "with FooMixin".
```

Apart from public static members (which are rare) this is basically a two line rewrite locally, and then finding the uses of the class.

Optionally, we can also allow mixins to be used as classes (instead of the other way around), so `class C extends Mixin { … }` is equivalent to `class C extends Object with Mixin { … }`.


#### Forward const constructors

A mixin application forwards generative constructors as non-const, even if the superclass constructor is a const constructor. That makes some use-cases for mixins impossible.

We could make the forwarding constructors const as well when it is safe. An approximation of that could be when the mixin declares no fields. This is not necessarily a good idea, since it would break getter/field symmetry and prevent a mixin from changing a getter to a final field.


#### Extending mixins

With separate syntax for mixins, we are open to adding more capabilities without needing it to also work for classes.

Options are:

*   Composite mixins (mixin can `extend` another mixin, application applies both).
*   Constructors (mixin constructors don't forward to the superclass, only to a super-mixin). If a mixin has generative constructors (and even const ones), there will be no automatic constructor forwarding because the mixin-application class would need to call the mixin constructor explicitly. It can be omitted if the mixin has a no-arguments constructor, which it will then have by default.


### Revisions

v0.5 (2017-06-12) Initial version

v0.6 (2017-06-14) Say `mixin` must be built-in identifier.
