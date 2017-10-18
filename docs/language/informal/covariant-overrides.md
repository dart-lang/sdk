# Covariant Overrides

Owner: rnystrom@, eernstg@.

Status: Implemented.

Version: 1.1 (Oct 10, 2017).

## Summary

Allow an overriding method to tighten a parameter type if it has the
modifier `covariant`, using dynamic checks to ensure soundness. This
provides a better user experience for a programming idiom that appears in
many UI frameworks.

Note that this feature is relevant in strong mode where parameter types
cannot otherwise be tightened, but it affects standard mode Dart in the
sense that the syntax should be accepted and ignored.

## Informal specification

We set out by giving the informal specification for the syntax of this
feature (which is shared among standard mode and strong mode). Following
that, we specify the other aspects of the feature in standard mode,
followed by those other aspects in strong mode.

### Syntax

The set of built-in identifiers is extended with `covariant`. This means
that the identifier `covariant` cannot be the name of a type. The grammar
is updated as follows:

```
normalFormalParameter: // CHANGED
  functionFormalParameter |
  fieldFormalParameter |
  simpleFormalParameter

functionFormalParameter: // NEW
  metadata 'covariant'? returnType? identifier formalParameterList

simpleFormalParameter: // CHANGED
  declaredIdentifier |
  metadata 'covariant'? identifier

declaredIdentifier: // CHANGED
  metadata 'covariant'? finalConstVarOrType identifier

declaration: // CHANGED: last alternative
  constantConstructorSignature (redirection | initializers)? |
  constructorSignature (redirection | initializers)? |
  'external' constantConstructorSignature |
  'external' constructorSignature |
  ('external' 'static'?)? getterSignature |
  ('external' 'static'?)? setterSignature |
  'external'? operatorSignature |
  ('external' 'static'?)? functionSignature |
  'static' ('final' | 'const') type? staticFinalDeclarationList |
  'final' type? initializedIdentifierList |
  ('static' | 'covariant')? ('var' | type) initializedIdentifierList
```

### Standard mode

The static analysis in standard mode ignores `covariant` modifiers, and so
does the dynamic semantics.

*This means that covariant overrides are essentially ignored in standard
mode. The feature is useless because covariant parameter types are always
allowed, but we wish to enable source code to be used in both standard and
strong mode. So standard mode needs to include support for accepting and
ignoring the syntax.*

### Strong mode

In strong mode, the covariant overrides feature affects the static analysis
and dynamic semantics in several ways.

#### Static checking

In this section we discuss a few general issues; several larger subtopics
are discussed in the following subsections.

It is a compile-time error if the `covariant` modifier occurs on a
parameter of a function which is not an instance method (which includes
instance setters and instance operators). It is a compile-time error if the
`covariant` modifier occurs on a variable declaration which is not a
non-final instance variable.

For a given parameter `p` in an instance method (including setter and
operator) `m`, `p` is considered to be a **covariant parameter** if it has
the modifier `covariant` or there is a direct or indirect supertype
containing an overridden declaration of `m` where the parameter
corresponding to `p` has the modifier `covariant`. For a type `T`, if
multiple direct supertypes of `T` has a method `m` which is not overridden
in `T`, each parameter of `m` is covariant iff that parameter is covariant
in `m` in at least one of the supertypes.

*In short, the property of being covariant is inherited, for each
parameter. There is no conflict if only some overridden declarations have
the `covariant` modifier, and others do not. The parameter is covariant iff
at least one of them has it.*

The parameter of an implicit instance setter is covariant if the corresponding
instance variable declaration contains `covariant`.

*A `covariant` modifier on a variable declaration has no other effects, and
in particular it makes no difference for the implicit getter. The other
rules still apply, e.g., the parameter of an implicit instance setter may
be covariant because an explicit setter declaration in a supertype has
`covariant` on its parameter.*

Function typing is unaffected by covariant overriding: When the type of a
function is determined for a property extraction which tears off an
instance method with one or more covariant parameters, the resulting type
has no covariant parameters. Other expressions with a function type do not
admit covariant parameters, and hence function types never include
covariant parameters.

*In particular, subtyping among function types is unaffected by covariant
overriding, and so is type checking for invocations of first-class
functions. Note that it is a non-trivial step to determine the run-time
type of a torn off method, as described below.*

An invocation of an instance method with one or more covariant parameters
is checked as if no `covariant` modifiers had been present on any of the
involved declarations.

*From one point of view, covariant overrides are irrelevant for clients,
it is a feature which is encapsulated in the invoked method. This is
reflected in the typing. From another point of view, clients may need to
provide arguments with a proper subtype of the one required in the static
type, because there may be a dynamic check for that subtype. This is
handled by developers using ad-hoc reasoning and suitable programming
idioms. The whole point of this mechanism is to allow this.*

##### Overriding

The static warnings specified for override relationships among instance
method declarations regarding the number and kind (named, positional) of
parameters remain unchanged, except that any `covariant` modifiers are
ignored.

For a covariant parameter, the override rule is that its type must be
either a supertype or a subtype of the type declared for the corresponding
parameter in each of the directly or indirectly overridden declarations.

*For a parameter which is not covariant, the override rule is is unchanged:
its type must be a supertype of the type declared for the corresponding
parameter in each directly overridden declaration. This includes the
typical case where the type does not change, because any type is a
supertype of itself. Override checking for return types is also unchanged.*

##### Closurization

The static type of a property extraction expression `e.m` which gives rise
to closurization of a method (including an operator or a setter) which has
one or more covariant parameters is the static type of the function `T.m`,
where `T` is the static type of `e`, if `T.m` is defined. Otherwise the
static type of `e.m` is `dynamic`.

The static type of a property extraction expression `super.m` which gives
rise to closurization of a method (including an operator or a setter)
which has one or more covariant parameters is the static type of the
function `T.m`, where `T` is the superclass of the enclosing class.

In both cases, for the static type of the function `T.m`, all occurrences
of the modifier `covariant` are ignored.

*In short, the static type of a tear-off ignores covariant overrides. Note
that this is not true for the dynamic type of the tear-off.*

#### Dynamic semantics

*The run-time semantics of the language with covariant overrides is the
same as the run-time semantics of the language without that feature, except
for the dynamic type of tear-offs, and except that some type checks which
are not guaranteed to succeed based on static checks must be performed at
run time.*

A dynamic error occurs if a method with a covariant parameter `p` is
invoked, and the binding for `p` is a value which is not `null` and whose
run-time type is not a subtype of the type declared for `p`.

##### The dynamic type of a closurized instance method

The dynamic type of a function *f* which is created by closurization
during evaluation of a property extraction expression is determined as
follows:

Let `m` be the name of the method (operator, setter) which is being
closurized, let `T` be the type of the receiver, and let *D* be declaration
of `m` in `T` or inherited by `T`.

The return type of *f* the is the static return type of *D*. For each
parameter `p` declared in *D* which is not covariant, the part in the
dynamic type of *f* which corresponds to `p` is the static type of `p` in
*D*. For each covariant parameter `q`, the part in the dynamic type of *f*
which corresponds to `q` is `Object`.

# Revisions

*   1.1 (2017-10-10) Clarified meaning of `covariant` on fields.

*   1.0 (2017-01-19) Initial specification.

# Background Material

The rest of this document contains motivations for having the covariant
overrides feature, and discussions about it, leading to the design which is
specified in the first part of this document.

## Motivation

In object-oriented class hierarchies, especially in user interface frameworks,
it's fairly common to run into code like this:

```dart
class Widget {
  void addChild(Widget widget) {...}
}

class RadioButton extends Widget {
  void select() {...}
}

class RadioGroup extends Widget {
  void addChild(RadioButton button) {
    button.select();
    super.addChild(button);
  }
}
```

Here, a `RadioGroup` is a kind of widget. It *refines* the base `Widget` interface
by stating that its children must be `RadioButton`s and cannot be any arbitrary
widget. Note that the parameter type in `RadioGroup.addChild()` is
`RadioButton`, which is a subclass of `Widget`.

This might seem innocuous at first, but it's actually statically unsound.
Consider:

```dart
Widget widget = new RadioGroup(); // Upcast to Widget.
widget.addChild(new Widget());    // Add the wrong kind of child.
```

Tightening a parameter type, that is, using a proper subtype of the existing
one in an overriding definition, breaks the [Liskov substitution principle][].
A `RadioGroup` doesn't support everything that its superclass Widget does.
`Widget` claims you can add *any* kind of widget to it as a child, but
`RadioGroup` requires it to be a `RadioButton`.

[liskov substitution principle]: https://en.wikipedia.org/wiki/Liskov_substitution_principle

Breaking substitutability is a little dubious, but in practice it works out
fine. Developers can be careful and ensure that they only add the right kinds
of children to their `RadioGroup`s. However, because this isn't *statically*
safe, many languages disallow it, including Dart strong mode. (Dart 1.0
permits it.)

Instead, users must currently manually tighten the type in the body of the
method:

```dart
class RadioGroup extends Widget {
  void addChild(Widget widget) {
    var button = widget as RadioButton;
    button.select();
    super.addChild(button);
  }
}
```

The declaration is now statically safe, since it takes the same type as the
superclass method. The call to `select()` is safe because it's guarded by an
explicit `as` cast. That cast is checked and will fail at runtime if the passed
widget isn't actually a `RadioButton`.

In most languages, this pattern is what you have to do. It has (at least) two
problems. First, it's verbose. Many users intuitively expect to be able to
define subclasses that refine the contracts of their superclasses, even though
it's not strictly safe to do so. When they instead have to apply the above
pattern, they are surprised, and find the resulting code ugly.

The other problem is that this pattern leads to a worse static typing user
experience. Because the cast is now hidden inside the body of the method, a user
of `RadioGroup` can no longer see the tightened type requirement at the API level.

If they read the generated docs for `addChild()` it appears to accept any old
Widget even though it will blow up on anything other than a RadioGroup. In this
code:

```dart
var group = new RadioGroup();
group.addChild(new Widget());
```

There is no static error even though it's obviously statically incorrect.

Anyone who has designed a widget hierarchy has likely run into this problem a
couple of times. In particular, this showed up in a number of places in Flutter.

In some cases, you can solve this using generics:

```dart
class Widget<T extends Widget> {
  void addChild(T widget) {...}
}

class RadioButton extends Widget<Null> {
  void select() {...}
}

class RadioGroup extends Widget<RadioButton> {
  void addChild(RadioButton button) {
    button.select();
    super.addChild(button);
  }
}
```

In practice, this often doesn't work out. Often you have a family of related
types, and making one generic means they all have to be, each with type
parameters referring to the other. It often requires API consumers to make their
own code generic simply to pass these objects around.

## The covariant override feature

Earlier, we showed the pattern users manually apply when they want to tighten a
parameter type in a method override:

```dart
void addChild(Widget widget) {
  var button = widget as RadioButton;
  ...
}
```

This proposal is roughly akin to syntactic sugar for that pattern. In this
method, `widget` effectively has *two* types:

*   The **original type** is the type that is declared on the method parameter.
    Here, it's `Widget`. This type must follow the type system's rules for a
    valid override in order to preserve the soundness guarantees of the
    language.

    With method parameters, that means the type must be equivalent to or a
    supertype of the parameter type in the superclass and all of its
    superinterfaces. This is the usual
    [sound rule for function subtyping][contra].

[contra]: https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)#Function_types

*   The **desired type** is the type that the user wants to use inside the body
    of the method. This is the real type that the overridden method requires in
    order to function. Here, it's `RadioButton`.

    The desired type is a subtype of the original type. Going from the original
    type to the desired type is a downcast, which means the cast needs to be
    checked and may fail at runtime.

    Even though the desired type is ensconced in the body of the method in the
    manual pattern, it really is part of the method's signature. If you are
    calling `addChild()` *on an object that you statically know is a
    RadioGroup*, you want the errors as if its declared type was the tighter
    desired type, not the original one. This is something the manual pattern
    can't express.

So we need to understand the original type, the desired type, and when
this feature comes into play. To enable it on a method parameter, you
mark it with the contextual keyword `covariant`:

```dart
class Widget {
  void addChild(covariant Widget widget) {...}
}
```

Doing so says "A subclass may override this parameter with a tighter desired
type". A subclass can then override it like so:

```dart
class RadioGroup extends Widget {
  void addChild(RadioButton button) {
    ...
  }
}
```

No special marker is needed in the overriding definition. The presence of
`covariant` in the superclass is enough. The parameter type in the base class
method becomes the *original type* of the overridden parameter. The parameter
type in the derived method is the *desired type*.

This approach fits well when a developer provides a library or framework where
some parameter types were designed for getting tightened. For instance, the
`Widget` hierarchy was designed like that.

In cases where the supertype authors did not foresee this need, it is still
possible to tighten a parameter type by putting the `covariant` modifier on
the *overriding* parameter declaration.

In general, a tightened type for a parameter `p` in a method `m` is allowed
when at least one of the overridden declarations of `m` has a `covariant`
modifier on the declaration corresponding to `p`.

The `covariant` modifier can also be used on mutable fields. Doing so
corresponds to marking the parameter in the implicitly generated setter
for that field as `covariant`:

```dart
class Widget {
  covariant Widget child;
}
```

This is syntactic sugar for:

```dart
class Widget {
  Widget _child;
  Widget get child => _child;
  set child(covariant Widget value) { _child = value; }
}
```

#### Overriding rules

With this feature, type checking of an overriding instance method or operator
declaration depends on the `covariant` modifiers. For a given parameter
`p` in a method or operator `m`, `p` is considered to be a **covariant
parameter** if there is a direct or indirect supertype containing an overridden
declaration of `m` where the parameter corresponding to `p` is marked
`covariant`. In short, `covariant` is inherited, for each parameter. There is
no conflict if only some overridden declarations have the `covariant` modifier
and others do not, the parameter is covariant as soon as any one of them has
it.

We could have chosen to require that every supertype chain must make the
parameter covariant, rather than just requiring that there exists such a
supertype chain. This is a software engineering trade off: both choices
can be implemented, and both choices provide a certain amount of protection
against tightening types by accident. We have chosen the permissive variant,
and it is always possible to make a linter require a stricter one.

For a regular (non-covariant) parameter, the override rule is is unchanged:
its type must be a supertype of the type declared for the same parameter in
each directly overridden declaration. This includes the typical case where the
type does not change, because any type is a supertype of itself.

For a covariant parameter, the override rule is that its type must be either a
supertype or a subtype of the type declared for the same parameter in each
of the directly or indirectly overridden declarations.

It is not enough to require a relationship with the directly overridden
declarations: If we only required a subtype or supertype relation to each
directly overridden declaration, we can easily create an example showing
that there are no guarantees about the relationship between the statically
known (original) parameter type and the actual (desired) parameter type
at run time:

```dart
class A { void foo(int i) {...}}
class B implements A { void foo(Object o) {...}}
class C implements B { void foo(covariant String s) {...}}

main() {
  A a = new C();
  a.foo(42); // Original type: int, desired type: String: Unrelated.
}
```

Checking all overridden declarations may seem expensive, because all
supertypes must be inspected in order to find those declarations. However, we
expect that the cost can be kept at a reasonable level:

First, covariant parameters are expected to be rare, and it is possible for
a compiler to detect them at a reasonable cost: For each parameter, the status
of being covariant or not covariant can be maintained by storing it after
inspecting the stored value for that parameter in each directly overridden
method. With that information available, it is cheap to detect whether a given
method has any covariant parameters. If that is not the case then the override
checks are unchanged, compared to the language without this feature.

Otherwise the parameter is covariant, and in this case it will be necessary to
find all overridden declarations (direct and indirect) for that method, and
gather all types for that parameter. Given that overridden methods would
themselves often have a corresponding covariant parameter, it may be worthwhile
to cache the result. In that case there will be a set of types that occur as
the declared type of the given parameter, and the check will then be to iterate
over these overridden parameter types and verify that the overriding parameter
type is a subtype or a supertype of each of them.

#### Subtyping

`covariant` modifiers are ignored when deciding subtype relationships among
classes. So this:

```dart
var group = new RadioGroup();
Widget widget = group;
```

... is perfectly fine.

#### Method invocations

Method invocations are checked according to the statically known receiver type,
and all `covariant` modifiers are ignored. That is, we check against that which
we called the original parameter types, and we ignore that the desired parameter
type may be different. So this:

```dart
var group = new RadioGroup();
group.addChild(new Widget()); // <--
```

... reports an error on the marked line. But this:

```dart
Widget widget = new RadioGroup();
widget.addChild(new Widget());
```

... does not. Both will fail at run time, but the whole point of allowing
covariant overrides is that developers should be allowed to opt in and take
that risk.

#### Tear-offs

The *static* type of a tear-off is the type declared in the statically known
receiver type:

```dart
var closure = new RadioGroup().addChild;
```

Here, `closure` has static type `(RadioButton) -> void`.

```dart
var closure = (new RadioGroup() as Widget).addChild;
```

Here, it has static type `(Widget) -> void`.

Note that in both cases, we're tearing off the same actual method at runtime. We
discuss below which runtime type such a tear-off should have.

### Runtime semantics

The runtime semantics of the language with covariant overrides is the same
as the runtime semantics of the language without that feature, except that
some type checks are not guaranteed to succeed based on static checks, so
they must be performed at run time.

In particular, when a method with a covariant parameter is invoked, it is not
possible to guarantee based on the static type check at call sites that
the actual argument will have the type which is declared for that parameter
in the method that is actually invoked. A dynamic type check must then be
performed to verify that the actual argument is null or has that type,
and a `CastError` must be thrown if the check fails.

In other words, the static checks enforce the original type, and the dynamic
check enforces the desired type, and both checks are required because the
desired type can be a proper subtype of the original type. Here is an example:

```dart
Widget widget = new RadioGroup();
try {
  widget.addChild(new Widget());
} on CastError {
  print("Caught!"); // Gets printed.
}
```

In practice, a compiler may generate code such that every covariant parameter
in each method implementation gets checked before the body of the method is
executed. This is a correct implementation strategy because the dynamic check
is performed with the desired type and it is performed for all invocations,
no matter which original type the call site had.

As an optimization, the dynamic check could be omitted in some cases, because
it is guaranteed to succeed. For instance, we may know statically that the
original and the desired type are the same, because the receiver's type is
known exactly:

```dart
new RadioGroup().add(myRadioButton())
```

#### The runtime type of a tear-off

For any given declaration *D* of a method `m`, the reified type
obtained by tearing off `m` from a receiver whose dynamic type is a
class `C` wherein *D* is the most specific declaration of `m` (that
is, *D* has not been overridden by any other method declaration in
`C`) can be computed as follows: Collect the set of all declarations
of `m` in direct and indirect supertypes of `C`. For the reified
return type, choose the greatest lower bound of all declared return
types; for the reified parameter type of each covariant parameter,
choose the least upper bound of all declared types for that parameter
(including any declarations of that parameter which are not
covariant).

As a consequence, the reified type of a torn off method is at least as
specific as every possible statically known type for that method, and
that means that it is safe to assign the torn off method to a
variable whose declared type is the statically known type of that
method, no matter which supertype of the dynamic type of the receiver
is the statically known receiver type.

(Note that the computation of a "least upper bound" in Dart does not
in fact yield a *least* upper bound, but it does yield some *upper
bound*, which is sufficient to ensure that this safety property holds.)

This rule is sufficiently complex to justify a rather lengthy
discussion, which follows below.

To give an example of the rule itself, consider `addChild` of
`RadioGroup`. The set of declarations of `addChild` have the following
types:

* `(Widget) -> void` (From `Widget.addChild()`)
* `(RadioButton) -> void` (From `RadioGroup.addChild()`)

So the reified return type is `void`, and the argument type is the least upper
bound of `Widget` and `RadioButton`: `Widget`. Thus the torn off method from
`(new RadioGroup()).addChild` has reified type `(Widget) -> void`.

To motivate this rule, we will consider some design options and their
consequences. Consider the following tear-offs:

```dart
var closureRadio = new RadioGroup().addChild;
var closureWidget = (new RadioGroup() as Widget).addChild;
```

Here, `closureRadio` has static type `(RadioButton) -> void`, and
`closureWidget` has static type `(Widget) -> void`. However, they are both
obtained by tearing off the same method from the exact same type of
receiver at run time, so which of these types (or which type in
general) do we *reify at runtime?*

We could reify the type which is declared in the actual method which is torn
off. (That is a specific method because method lookup is determined by the
dynamic receiver type, and a tear-off embodies one specific receiver). In the
example, the reified type would then be `(RadioButton) -> void`. Intuitively,
this means that we will reify the "true" type of the method, based on its actual
declaration.

Or we could reify the statically known type, except that there are several
possible statically known types when the method is inherited and overridden in
several supertypes. In order to allow the torn off method to be passed around
based on the statically known type, it should have the most specific type which
this tear-off could ever have statically.

To achieve is, we consider all the static types the receiver could
have where the torn off method is statically known (in the example it
would be `RadioGroup` and `Widget`, but not `Object` because
`addChild()` is not inherited from there). In this set of classes,
each declaration for the relevant method specifies a type for each
covariant parameter. We may choose the least upper bound of all these
types, or we may insist that there is a maximal type among them (such
that all the others are subtypes of that type) and otherwise reject
the method declaration as a compile-time error. In the example, this
check succeeds and the resulting reified type is `(Widget) -> void`.

With the first model (where we reify the "true" type `(RadioButton) ->
void`), we get the property that the reified type is the most
informative type there exists, but the tear-off fails to have the
statically known type. This means that we may get a runtime exception
by assigning a tear-off to a variable with the statically known type:

```dart
typedef void WidgetCallback(Widget widget);

Widget widget = new RadioGroup();
WidgetCallback callback = widget.addChild; // Statically OK, fails at run time.
```

This differs from the general situation. For instance, if `addChild` had been
a getter then an initialization like:

```dart
WidgetCallback callback = widget.addChild;
```

would never fail
with a type error, because the value returned by the getter is guaranteed to
have the declared return type or be null. As a consequence, all tear-off
expressions would have to be treated differently by compilers than other
expressions, because they would have to generate the dynamic check.

With the second model (where we aim for covering all statically known
types and reify `(Widget) -> void`), it is possible that an invocation
of the torn off closure fails, because the statically known
requirement on the actual argument is less restrictive that the actual
requirement at runtime. For instance, the actual torn off method would
have a parameter type `RadioButton` even though the statically known
parameter type is `Widget`. Here is an example:

```dart
typedef void WidgetCallback(Widget widget);

Widget widget = new RadioGroup();
WidgetCallback callback = widget.addChild; // Statically and dynamically OK.
callback(new Widget()); // Statically OK, fails at run time.
```

As expected, both models are unsound. However, the second model exhibits a
kind of unsoundness which is in line with the rest of the language, because
it is a parameter passing operation that fails, and not an expression
evaluation that yields a value which does not have the static type. This is
also reflected in the fact that no dynamic checks must be generated at
locations where such checks are otherwise avoided.

So there are pros and cons to both approaches, but we have chosen to
use the second model, yielding reified type `(Widget) -> void`.
Reasons for this include the following:

*   This choice lines up with the reified type you would get if you didn't have
    this language feature and applied the pattern above manually:

    ```dart
    class RadioGroup extends Widget {
      void addChild(Widget widget) {
        var button = widget as RadioButton;
        button.select();
        super.addChild(button);
      }
    }
    ```

    Here, standard override rules are followed, and `RadioGroup.addChild` has
    reified type `(Widget) -> void`.

*   Polymorphic code that does implicit type tests won't spontaneously blow up
    when encountering overridden methods with tighter types. Consider:

    ```dart
    typedef void TakesWidget(Widget widget);

    grabClosures(List<Widget> widgets) {
      var closures = <TakesWidget>[];
      for (var widget in widgets) {
        closures.add(widget.addChild);
      }
    }

    grabClosures([
      new Widget(),
      new RadioGroup()
    ]);
    ```

    The call to `List.add()` has to check the type of the added object at
    runtime thanks to covariant generics. If the reified type of
    `RadioGroup.addChild` had been `(RadioButton) -> void`, that check would fail.

The main downside to reifying with the more special type is that you lose the
ability to use an `is` check to detect which type of argument is *actually*
required, you can just call it and hope that the dynamic check in the body
succeeds. In practice, though, code we see using this pattern doesn't avoid
those cast errors by using `is` checks, it avoids cast errors by managing how
the objects collaborate with each other.

## Questions

### Why not always put `covariant` in the superclass?

We could require each covariant parameter to be covariant everywhere, that is,
we could require that every overridden declaration of that parameter either
has the `covariant` modifier, or that it overrides another declaration which
has it, directly or indirectly.

There are no technical difficulties in implementing this approach, and it has
the nice property that all call sites can be checked for type safety: If a
given actual argument does not correspond to a formal parameter which is
statically known to be covariant then that argument will not be passed to a
covariant parameter at runtime. In other words, the desired type is a supertype
of the original type (typically they are identical), and no runtime check
failure is possible.

The problem with this approach is that it requires the author of all the
involved supertypes to foresee the need for covariance. Moreover, the safety
property is more aggressive than other guarantees provided in Dart (for
instance, an argument like `a` in `List<T>.add(a)` is always subject to a
dynamic check because the list could have a type argument which is a proper
subtype of `T`).

So we made the choice to accept the dynamic checks, and in return allow
developers to use covariant overrides even in cases where some of the supertype
authors did not foresee the need.

It should be noted, however, that it is *possible* to maintain a style where
every covariant parameter is everywhere-covariant (that is, to put `covariant`
in all supertypes), and it is possible to let a linter check that this style
is used consistently. So developers may use this style, the language just
doesn't enforce it.

There are many intermediate forms where a given parameter is covariant
in some supertypes but not all. This could mean that `covariant` is applied
to a parameter in a library, because the design makes it useful to use
covariant overrides for that parameter in subtypes and the library authors
wish to make that known. Subtype authors would then automatically get the
"permission" to tighten the corresponding parameter type, without an
explicit `covariant` modifier. At the same time, it would not violate
any rules if one of these parameters were overriding some additional
declarations of the same method, even if the authors of those declarations
were unaware of the need to use covariant overriding.

### Why not allow all parameters to be tightened?

Dart 1.0 allows any parameter in an overriding method declaration to have a
tighter type than the one in the overridden method. We could certainly
continue to allow this, and retain all the same safety properties in the
semantics by inferring which parameters would be forced to have the
`covariant` modifier, according to this proposal. There are several arguments
in relation to this idea:

*   We expect the situation where an overriding method is intended to have
    a tightened parameter type to be rare, compared to the situation where
    it is intended to have the same type (or even a supertype). This means
    that an actual covariant override may be much more likely to be an
    accident than an intended design choice. In that case it makes sense
    to require the explicit opt-in that a modifier would provide.

*   If a widely used class method is generalized to allow a looser type for
    some parameter, third party implementations of that method in subtypes
    could introduce covariance, silently and without changing the subtype
    at all. This might cause invocations to fail at run time, even in
    situations where the subtype could just as well have been changed to use
    the new, looser parameter type, had the situation been detected.

*   We have widespread feedback from users that they want greater confidence
    in the static safety of their code. Allowing all parameters to silently
    tighten their type shifts the balance in the direction of diminished
    static safety, in return for added dynamic flexibility.

*   Parameter covariance requires a runtime check, which has a run time
    performance cost.

*   Most other statically typed object-oriented languages do not allow this. It
    is an error in Java, C#, C++, and others. Dart's type system strikes a
    balance where certain constructs are allowed, even though they are not
    type safe. But this balance should not be such that guarantees familiar to
    users coming from those languages are violated in ways that are gratuitous
    or error-prone.

*   Finally, we are about to introduce a mechanism whereby the types of an
    instance method declaration are inherited from overridden declarations, if
    those types are omitted. With this mechanism in place, it will be a strong
    signal in itself that a parameter type is present: This means that the
    developer had the intention to specify something _new_, relative to the
    overridden declarations of the same parameter. It is not unambiguous,
    though, because it could be the case that the type is given explicitly
    because there is no overridden method, or it could be that the type is
    specified because it is changed contravariantly, or finally the type could
    be specified explicitly simply because the source code is older than the
    feature which allows it to be omitted, or because the organization
    maintaining the code prefers a coding style where the types are always
    explicit.

Based on arguments like this, we decided that covariant overrides must be
marked explicitly.

### Why not `checked` or `unsafe`?

Instead of "covariant", we could use "checked" to indicate that invocations
passing actual arguments to this parameter will be subject to a runtime
check. We decided not to do this, because it puts the focus on an action
which is required by the type system to enforce a certain discipline on the
program behavior at runtime, but the developers should be allowed to focus
on what the program will do and how they may achieve that, not how it might
fail.

The word "covariant" may be esoteric, but if a developer knows the word or
looks it up the meaning of this word directly addresses the functionality that
this feature provides: It is possible to request a subtype for this parameter
in an overriding version of the method.

Similarly, the word "unsafe" puts the focus on the possible `CastError` at
runtime, which is not the motivation for the developer to use this feature,
it's a cost that they are willing to pay. Moreover, C#, Go, and Rust all use
"unsafe" to refer to code that may violate soundness and memory safety entirely,
e.g., using raw pointers or reinterpreting memory.

What we're doing here isn't that risky. It stays within the soundness
boundaries of the language, that is, it maintains heap soundness. The feature
just requires a runtime check to do that, and this is a well-known situation
in Dart.

## Interactions with other language features

This is yet another use of least upper bounds, which has traditionally been hard
for users to understand in cases where the types are even a little bit complex,
like generics. In practice, we expect most uses of this feature to only override
a single chain of methods, in which case the least upper bound has no effect and
the original type is just the most general parameter type in the chain.

## Comparison to other languages

**TODO**

## Notes

The feature (using a `@checked` metadata annotation rather than the `covariant`
modifier) has already been implemented in strong mode, and is being used by
Flutter. See here:

https://github.com/dart-lang/sdk/commit/a4734d4b33f60776969b72ad475fea267c2091d5
https://github.com/dart-lang/sdk/commit/70f6e16c97dc0f48d29deefdd7960cf3172b31a2
