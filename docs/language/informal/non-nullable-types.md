# Non-nullable types

Owner: **Bob Nystrom** (rnystrom@google.com)

This is a proposal to extend Dart's type system to express types that can or
cannot allow `null`.

We know it is *technically feasible* to implement non-nullable types—other
languages have. The hard questions are around *usability*—can we design
something that isn't too painful to use and helps users write correct code? Will
it still feel like Dart? Usability can't survive in a vacuum, so we will start
with this informal proposal and progressively refine it as we prototype and
experiment.

Before I go any farther, a shout out to Patrice's amazing [non-nullable by
default DEP][dep]. Almost all of the ideas here can be found there, and we
wouldn't even be considering non-nullability in Dart if he hadn't written that
up. You can look at this document as a distillation of his DEP with some of the
open questions answered.

[dep]: https://github.com/dart-lang/dart_enhancement_proposals/issues/30

## Motivation

Normally, there'd be a bunch of verbiage motivating this. But, now that Flow,
Hack, Swift, Kotlin, Ceylon, and TypeScript have non-nullable types, most people
are pretty familiar with the pros and cons.

**TODO: Fill in more if readers want.**

## Summary for executives who like bullet points

*   By default, types are *non*-nullable.

*   To make a type nullable, append `?`.

*   A nullable type behaves like a [union type][] of the base type and the
    `Null` class.

[union type]: https://en.wikipedia.org/wiki/Union_type

*   You must explicitly cast a nullable type to its non-nullable base type.
    Since it is explicit **you can see in your code every place a `null` can go
    where it is not expected.**

*   A nullable type does not support the methods of the base type. No
    `string.length` if `string` is a nullable String. This means **you will
    never get a NoSuchMethodError from inadvertantly calling a method on
    `null`.**

## Nullable types as union types

We'll start from the underlying semantic model and work our way up to the user
visible surface features. Nullable types are built on two concepts, the *Null
class*, and *union types*.

### Null class

Dart already has a [class named Null][null class]. Like all classes, it is a
subclass of Object. It has a single value, `null`.

[null class]: https://api.dartlang.org/be/136810/dart-core/Null-class.html

It works *mostly* like any regular user-defined class that happens to only have
a single instance. In particular, other classes are not a subclass of it—it
can't be extended.

However, the type system has some special rules around the null class. It acts
like the [bottom type][]. Since bottom is a subtype of all types, it allows
`null` to be assigned to any type. This is why every type is nullable in Dart
today.

[bottom type]: https://en.wikipedia.org/wiki/Bottom_type

Our first step then is to eliminate that special rule. The static type of `null`
is its class, Null and that class is treated like any other regular class. This
means that a variable of type String can no longer be initialized with `null`,
since String is not a subclass of Null any more than it is a subclass of int.
`null` is no longer related to any other type (except Object).

### Union types

If we just did that, we'd have *non*-nullable types, but we lost *nullable*
types (well, except for Null and Object). That's a little too restrictive for a
general-purpose object-oriented language. Now we want to add nullable types back
in.

Consider a nullable boolean type. It contains three values: `true`, `false`, and
`null`. The boolean type has two values, `true` and `false`. The Null type just
has one, `null`. So the set of values of a nullable boolean type is the union of
those two types'. Tada: union types.

Union types have been around in academia for a while and are in a few industry
languages as well, most recently [TypeScript][] and [Flow][]. I won't get into
the differences here but note that union types are *not* like algebraic
datatypes (AKA "discriminated unions" or "sum types").

[typescript]: https://www.typescriptlang.org/docs/handbook/advanced-types.html
[flow]: https://flowtype.org/docs/union-intersection-types.html

Union types have been a perennial feature request for Dart, and we may add them,
but they're a big feature. We aren't planning to add full support for them now,
but we can use them under the hood for nullable types.

With those, a nullable type is just the union type of the base type and Null. So
`String?` effectively means `String|Null`. Most of the rest of the semantics
in this proposal fall out from that:

*   **A nullable type is a supertype of its base type.** This means you can
    assign from a non-nullable type to its nullable dual—that's an upcast. If a
    function expects a `String?`, you can pass it a `String`.

    Likewise, the non-nullable type is a subtype of its nullable dual. So to
    "get rid of" nullability, like going from `String?` to `String`, you do a
    *down*cast.

*   **A nullable type is a supertype of Null.** Same as above but now for the
    other, Null, arm of the union. This means you can pass `null` to something
    expecting a nullable type. It also means a nullable variable or field can be
    default initialized to `null`.

*   **A nullable nullable type flattens.** The union `String | Null | Null` is
    the same thing as `String | Null`, so `String??` is the same as `String?`.
    (We don't intent to literally support repeated `?` in type annotations, but
    it comes into play with generics.)

*   **Object is always nullable.** This is an interesting consequence. A union
    of a type and its supertype is always just the supertype, since it already
    contains all instances of the subtype. `int | num` is the same as `num`.
    Since Null is a subclass of Object, that means `Object | Null` is the same
    as just `Object`.

    This sort of makes sense. Object only supports a couple of methods:
    `toString()`, `hashCode`, and `==()`. Null does implement those too. So if
    you call a method on a variable of type Object, you'll never get a
    NoSuchMethodError on it, even if the value is `null`. So there's an argument
    that there's no need to be able to express "any Object at all, but not
    `null`".

    However, you can imagine some API contracts that might want to express that,
    even though it's not strictly necessary to avoid NoSuchMethodError. To that
    end, like Patrice's proposal does, we're considering an extension to support
    this. More below.

*   **The methods allowed on a nullable type are only the methods on `Object`.**
    We don't want to produce some sort of weird structural interface for a union
    type where if each branch of the union defines a method `bark()`, then the
    union allows it too, even though one may be about trees and the other dogs.

    Instead, a method is only allowed on a union type if both branches of the
    union have the same method—i.e. the method comes from the exact same
    declaration.

    With a union of some type and Null, the only methods they will have in
    common are the ones on Object, so the only methods you can call on a
    nullable type are the ones declared on Object. To call anything else, you
    need to cast away the Null first. This is how we statically ensure you don't
    call methods that may throw a NoSuchMethod error when the receiver is
    `null`.

## Syntax

Now that we have some semantics, we need a user interface for them. We tweak the
type annotation syntax slightly. A type annotation that just references a type
name is interpreted to mean just the type itself, and not the nullable union of
it and Null. If the type annotation says `String`, it can only be a `String`.

Then, we allow a postfix `?` in a type annotation to produce the nullable union
of the underlying base type.

Right now, the grammar uses `type` for both type annotations and places that
need to refer to an explicit (possibly generic) class. The former is things like
variable declarations, and the latter is things like `extends` clauses. With
nullable types, those are now different. You can't extend a nullable type, for
example.

So we split out **type** into:

```
type:
  classType "?"?
  ;

classType:
  className typeArguments?
  ;

className:
  qualified
  ;

classTypeList:
  classType ("," classType)*
  ;
```

Now, we restrict all of the places that used to use **type** but where we don't
want to allow "?":

```
redirectingFactoryConstructorSignature:
  "const"? "factory" identifier ("." identifier)? formalParameterList
  "=" classType ("." identifier)?
  ;

superclass:
  "extends" classType
  ;

interfaces:
  "implements" classTypeList
  ;

mixinApplication:
  classType mixins interfaces?
  ;

primary:
  thisExpression |
  "super" unconditionalAssignableSelector |
  functionExpression |
  literal |
  identifier |
  newExpression |
  "new" classType "#" ("." identifier)? |
  constObjectExpression |
  "(" expression ")"
  ;

newExpression:
  "new" classType ("." identifier)? arguments
  ;

constObjectExpression:
  "const" classType ("." identifier)? arguments
  ;
```

Finally, there are two special corners of the grammar that define types but
don't use **type**—function typed parameters, and initializing formals:

```
functionSignature:
  metadata returnType? identifier formalParameterList "?"?
  ;

fieldFormalParameter:
  metadata finalConstVarOrType? this "." identifier formalParameterList? "?"?
  ;
```

### Grammar edge cases

Because of `is`, `?:`, and `.?`, it's a little tricky inserting this into the
grammar. But, as far as I can tell so far, there's no real ambiguity. Some cases
we've discussed:

``` dart
String?.runtimeType
```

This is a null-aware call on the String class. We are not extending class
literals to support the nullable postfix `?`. You can't do just `MyClass?` as an
expression.

``` dart
a is String?.runtimeType
```

This is an error today and will be with the new syntax. A type test isn't a
valid LHS for null-aware operator call or a regular method call. You would have
to explicitly do `(a is String)?.runtimeType` or `(a is String?).runtimeType`.

``` dart
"str" is String ? (some + arbitrarily + long + expression ...) : "not string";
```

This may require arbitrary lookahead to disambiguate the `?` but speculatively
assuming it is for `?:` will almost always be right since you can't call a
boolean anyway.

That being said, we are in slightly dangerous waters here, which is why we'd
like to start experimentally parsing the syntax to see if we run into real
trouble. If we do, one simple option is to disallow `?` in the RHS of an `is`
operator. But for, now we would like to try allowing it.

## Working with nullable types

Once you can define some nullable types, here's how they work.

### Variables and fields

Dart specifies that variables and fields that are not initialized get implicitly
initialized with `null`. That's obviously not good if the variable's type is
non-nullable.

In practice, most variables *are* initialized, so it's not a huge issue. For
variables that are not, it is an error to declare a variable of a non-nullable
type without an initializer.

A non-nullable field can be declared without an initializer as long as it is
initialized in the class's constructor initialization lists. This is similar to
how `final` fields must be initialized, so it shouldn't be too big of a change.

### Optional parameters

The other place where a variable can be default initialized to `null` is an
optional parameter:

```dart
method([int param]) {
  print(param);
}

method(); // Prints 'null'
```

There are two sides of this:

1. What types do we allow to pass as an explicit *argument* to the function?
2. What type does the *parameter* have inside the body of the function?

There are a few choices we can make here, and I don't think we have enough
usability data to have a strong opinion, so as a starting point, I propose we
start with the most literal interpretation of what the user wrote.

*   **If the declared type of an optional parameter is non-nullable, then only a
    non-nullable argument may be passed.** It would be an error to call the
    above code like either of:

    ```dart
    method(null);
    int? maybeInt = ...;
    method(maybeInt);
    ```

*   **The type of the parameter in the body of the method is the same as the
    annotated type.** In the above example, `param` has type `int`. That's what
    the user wrote after all.

*   **It is a static error to declare a non-nullable parameter without a default
    value.** This follows from the above two rules. If the parameter's type is
    non-nullable, we have to ensure it's never `null`, even if the user didn't
    pass an argument. The way to do that is by giving it a default value. So the
    above example is erroneous, but this is OK:

    ```dart
    method([int param = 1]) {
      print(param);
    }
    ```

*   **If you want to allow passing `null` to an optional parameter, declare it
    nullable.** In practice, I think most optional parameters will end up
    declared nullable, so that it's possible to forward optional parameters from
    another function to this one by passing an explicit `null`:

    ```dart
    method([int? param]) { ... }

    forward([int? param]) {
      method(param); // Must allow passing null here.
    }
    ```

    Likewise, if you don't want to provide a default value, make the parameter
    type nullable.

I think these rules are the most obvious ones. By treating non-nullable
annotations as actually being non-nullable, we let users express all possible
kinds of optional parameters. They can always opt *in* to nullability using `?`.

I worry that in practice almost all of them will end up needing to be made
nullable. If that turns out to be the case, we can tweak the rules.

### Escaping nullability

Since nullable types don't have many methods on them, the first thing you end up
doing with one is casting it to the non-nullable base type. That's a downcast.
Dart allows downcasts implicitly, but we do not want to do that for nullable
types. You won't get much confidence in the safety of your code if Dart let you
silently pass a `String?` to a method expecting `String`.

Instead, there are a couple of ways to explicitly cast to a non-nullable type:

*   **Use type propagation from a type test.** The right-hand side of `is`
    supports `?`. If omitted, then you're doing a type test against a
    non-nullable type. If that passes, you know it isn't null.

    Dart already has type propagation so that doing `if (object is String) { ...
    }` tightens the type of `object` to `String` inside the then branch of the
    `if`. It naturally supports non-nullable types too:

    ```dart
    printIfGiven(String? string) {
      if (string is String) {
        // Now string has type String.
        print(string);
      }
    }
    ```

*   **Use type propagation from a `null` check.** Since Null only has a single
    value, `null`, we extend type propagation to support checks against that
    too:

    ```dart
    printIfGiven(String? string) {
      if (string != null) {
        // Now string has type String.
        print(string);
      }
    }
    ```

    Type propagation comes into play with some other control flow constructs
    too, but I won't list them out here. The basic idea is that if you've
    definitely checked that some local variable is not `null`, then its type
    should automatically get tightened to the non-nullable type.

*   **Use `as` to explicitly cast to a non-nullable type.** In cases where you
    *know* the type should not be null (but for whatever reason you can't
    declare it as a non-nullable type), you can cast:

    ```dart
    int getLength(String? string) {
      return (string as String).length;
    }
    ```

    This will throw a CastError if `string` happens to be `null`.

*   **Use null-aware operators.** Since a null-aware operator, by definition,
    skips the method call if the receiver is `null`, we can safely allow method
    calls of the base type using `?.` even when the receiver is a nullable type:

    ```dart
    bool isNullOrEmpty(String? string) {
      return string?.isNotEmpty == true;
    }
    ```

    Here, the `isNotEmpty` call is fine even though `string` is a nullable type.

*   **Use a non-null assertion.** This isn't part of the core proposal, but it's
    a possible extension described below.

### `is` and `as`

There are a few other places outside of type annotations where types appear,
mainly `is` and `as` expressions. Those also allow `?` after the type on the
right-hand side.

This does not change the meaning of `is`. It already treats the right-hand side
as referring to a non-nullable type:

```dart
print(null is int); // "false"
```

Allowing `?` gives you the ability to express nullable type tests:

```dart
print(null is int?); // "true"
```

For `as`, the story is different. It treats the type as nullable today:

```dart
print(null as int); // OK in Dart 1.0. Prints "null".
```

This proposal makes **a breaking change to `as`** such that the above code
throws a CastError. If you want to cast to a type and allow `null`, you have to
explicitly cast to a nullable type:

```dart
print(null as int?); // OK now. Prints "null".
```

### `on`

The `on` clause when catching a thrown exception is the other place where a type
can appear. The language does not allow throwing `null`, so there is no reason
to allow the `?` syntax in an `on` clause.

We could allow it for consistency with other places and have the `?` simply not
do anything since `null` will never get thrown, but I think that would confuse
users. Allowing `?` would let them think they are expressing *something*, but
they really aren't.

### `extends`, `implements`, and `with`

The "types" you reference when declaring a superclass, superinterface or mixin
are not *types* they are *classes*. We do not allow `?` here.

## Generics

Here's where it gets fun. As always, most of complexity with types are around
generics. From what I can tell, nullable types aren't *too* bad. Most of the
behavior falls out from union types.

We'll start with a simple approach that is pretty limited. We may end up needing
to extend it some to support more interesting constraints.

### Nullable type arguments

A type argument to a generic class or method can be a nullable type:

```dart
// A list of ints that may contain null.
new List<int?>();

// A list of ints that will not contain null.
new List<int>();
```

### Nullable variables of type parameter type

When declaring a variable whose type is a type parameter of the enclosing class
or method, you can use `?` just like with any other type. It forms the nullable
type of the type argument:

```dart
class MaybeBox<T> {
  T? value;
}

var box = new MaybeBox<int>;
// box.value has type "int?".
```

Because repeated nullable types flatten, this also works:

```dart
var box = new MaybeBox<int?>; // Note "?" here.
// box.value still has type "int?".
```

### Default constraints

When not specified, the default constraint for a type parameter is Object. Since
Object is itself nullable, that permits type arguments that are both nullable
and non-nullable.

This is maximally permissive to a *user* of the class. But it's maximally
*restrictive* inside the body of the class. Since a type argument may be
non-nullable, uses of the type parameter must be treated like a non-nullable
type. This class has a static error:

```dart
class Foo<T> {
  T notInitialized;
}
```

Because it would let a user do:

```dart
int n = new Foo<int>.notInitialized;
```

If you want to treat a type parameter as nullable, you can make it explicitly
nullable in the body of the class:

```
class Foo<T> {
  T? notInitialized; // <-- "?".
}

// Error, can't implicitly cast away null:
int n = new Foo<int>.notInitialized;

// OK:
int n = new Foo<int>.notInitialized as int
```

### Non-nullable constraints

If you use another type as a constraint, that defaults to constrain type
arguments to *non-nullable* types:

```dart
class Point<T extends num> {
  T x, y;
  Point(this.x, this.y);
}

new Point<int>(); // OK.
new Point<double?>(); // Error!
```

If you want to constrain type arguments to some type, but also allow nullable
versions of it, make the constraint itself nullable:

```dart
class Point<T extends num?> {
  T x, y;
  Point(this.x, this.y);
}

new Point<int>(); // Still OK.
new Point<double?>(); // OK now.
```

Note that using a nullable constraint does *not* mean all type arguments *must*
be nullable, just that they *can*. Since a type argument may still be
non-nullable, inside the body of the class, the type parameter is still treated
like a non-nullable type. That's why `x` and `y` are initialized by the
constructor in the Point examples.

In the minimal proposal, we do not support type constraints that say "the type
argument *must* be a nullable type". Instead, classes that want to treat type
parameters as nullable just use `T?` or whatever inside the body. If that turns
out too limiting, there is an extension below to handle it.

### Covariant generics

**TODO: Are there any interesting implications around covariance?**

## Core library changes

Aside from implementing the static checking, the lion's share of the work of
this proposal will be converting the Dart core libraries to be properly
annotated to track their usage of `null`.

We can't get a sense of how well non-nullable types will work in user code until
they have access to core libraries that are themselves tracking null. We'll go
through and see which type annotations should be nullable and which should not.

In practice, we've found that around 90% of type annotations appear to refer to
objects that are presumed to not be null, so we don't expect to have to add a
*ton* of `?` to the code. It would be much worse if *nullable* was the default.

Return types from methods in the core libraries are easy: if it returns a
non-nullable type, that sends a more useful signal to the caller, but is still
callable from code that wants a nullable type.

Parameters are harder. Changing a parameter from nullable to non-nullable is a
breaking change to the API if a user is passing in `null`. In practice, most
core library methods throw a runtime error if you pass in `null` for any of
their parameters, so little existing correct code should be impacted by this.

Converting that runtime error to a static error does put the error in your face
where you have to deal with it, but that's a good thing for the long term
maintainability of your code.

Some APIs will be need close attention:

### Map subscript

The index operator on Map returns `null` if the key is not found. That means
its correct type should be:

```dart
class Map<K, V> {
  V? operator[](K key) { ... }
}
```

Returning a nullable V means every caller of this will have to cast away the
null after they look up a key. That's really annoying in the common case where
you know the key is present. We may want to change `[]` to throw on an absent
key, or add a second method that does that.

### new List(int size)

The constructor for List that takes a size creates an empty list whose elements
are initialized with `null`. That's obviously wrong if the list has a
non-nullable type.

We may want to remove that constructor, have it throw a runtime error if the
type argument is `null`, require a fill value, or otherwise tweak it. In
practice, this constructor isn't used that often, so we don't expect this to be
too bad.

### Other changes

There are probably some other tricky cases we'll run into as we turn on the new
type rules. We will also likely want to add some new convenience methods to make
it easier to work with nullable and non-nullable types.

If we can get through these changes and are happy with the resuting API, it's a
very strong signal that this proposal is going to work out.

## Possible extensions

The above list of features is the set of things I am confident we will need.
Beyond that, there are some extensions we may want to make non-nullable types
more expressive, or more convenient to work with.

There's a very good chance we'll need one or more of these, but I don't want to
*presume* we do until we know. There's no sense adding unneeded complexity to
the language.

### Not-null assertion operator

There's no easy syntax to escape a nullable type in the middle of a method
chain. Type propagation, at best, uses `&&` which has low precedence, as do `is`
and `as`. That leads to code like:

```dart
(someNullableString as String).length;
```

With required parentheses and all. Kotlin has a `!!` postfix operator that
throws if the operand is `null` and returns it otherwise, with a non-nullable
type. That lets you do:

```dart
someNullableString!!.length;
```

I'm not sure if `!!` is the syntax we want, but we could do something similar.

### Non-null Object type

Since Null is a subclass of Object, there's no way to declare a parameter that
allows any object, but disallows `null`. That might be annoying. We can fix that
by rearranging the top of the class hierarchy a bit. Instead of:

```
  .--------.
  | Object |
  '--------'
    /     \
.------.
| Null |  Other classes...
'------'
```

We would do something like:

```
  .-----------.
  | _Anything |
  '-----------'
     /     \
.------. .--------.
| Null | | Object |
'------' '--------'
              |
        Other classes...
```

The default constraint for generics would be `Object?` to allow nullable type
arguments. If you declare a constraint `extends Object`, that allows any class
but disallows null.

Likewise, a variable whose type is `Object` is non-nullable. You have to use
`Object?` to allow `null`. This probably *would* be a painful breaking change,
but possibly worth it.

(The name `_Anything` is up for debate.)

### Definite assignment analysis

Forcing a non-nullable variable always be initialized can be annoying,
especially in code where there is no easy object you can initialize it with.

```dart
Monster monster; // Error.
if (isBossFight) {
  monster = new GiantDragon();
  monster.breathesFire = true;
} else {
  monster = new PiddlyOrc();
}

monster.attack(hero);
```

There are patterns to work around it.

*   You can make it nullable and then cast when you use it:

    ```dart
    Monster? monster;
    if (isBossFight) {
      monster = new GiantDragon();
      (monster as Monster).breathesFire = true;
    } else {
      monster = new PiddlyOrc();
    }

    (monster as Monster).attack(hero);
    ```

*   You can make it nullable and then make a second non-nullable variable:

    ```dart
    Monster? monster_;
    if (isBossFight) {
      monster_ = new GiantDragon();
      (monster_ as Monster).breathesFire = true;
    } else {
      monster_ = new PiddlyOrc();
    }
    Monster monster = monster_ as Monster;

    monster.attack(hero);
    ```

*   You can hoist the code into a separate function:

    ```dart
    Monster monster = () {
      if (isBossFight) {
        var monster = new GiantDragon();
        monster.breathesFire = true;
        return monster;
      }

      return new PiddlyOrc();
    }();

    monster.attack(hero);
    ```

But those can all be a chore. We could take a page from Java, C#, and others and
do *definite assignment analysis*. If we can ensure that a local variable is
assigned by all possible control flow paths at least once before it gets used,
it is OK to allow it to not be initialized.

That would make the above original code fine. This is how Java and C# ensure
final/readonly fields are initialized by the end of the constructor body.

### Non-null modifier

Inside a generic class or method, there's no way to declare a variable of the
type parameter type that "strips off" the nullability. For example, we will
likely want a method on `Iterable` that returns a new collection with all null
elements removed:

```dart
var maybeNumbers = <int?>[1, 2, null, 3];
var definitelyNumbers = maybeNumbers.whereNotNull();
// definitelyNumbers has type Iterable<int>.
```

As far as I can tell, the minimal proposal doesn't make it possible to define
`whereNotNull()` such that the *static type* of the returned iterable is
non-nullable. Inside List, you just have `T` and can't "unpack" it. We could
support this by allowing a postfix `!` after a type. If the base type is
nullable, it produces the base type, otherwise, it has no effect. (If `?` is set
union with `|Null`, `!` is set difference `-Null`.)

Then we could define:
```dart
class Iterable<T> {
  Iterable<T!> whereNotNull() sync* {
    for (var element in this) {
      if (element != null) yield element;
    }
  }
}
```

Note the `T!` in the return type.

This isn't strictly needed, though. If we have a method on Iterable to let you
filter by any type, then you could also use that with a non-nullable type to
remove the null elements:

```dart
// Given:
class Iterable<T> {
  Iterable<S> of<S extends T>() sync* {
    for (var element in this) {
      if (element is S) yield element;
    }
  }
}

// Then:
var maybeNumbers = <int?>[1, 2, null, 3];
var definitelyNumbers = maybeNumbers.of<int>();
// definitelyNumbers has type Iterable<int>.
```

### Explicit nullable type constraint

With the above rules for type parameter constraints, you can express:

*   **The type argument can be nullable or non-nullable.** Use no constraint or
    a nullable constraing like `extends num?`.

*   **The type argument must be non-nullable.** Use a non-nullable constraint
    like `extends num`.

The missing option is:

*   **The type argument must be nullable.**

There's no way to define a generic that only accepts explicitly nullable type
arguments. This might be useful because it would mean inside the body of that
generic method or class, you could reliably treat `T` as if it were nullable:

```dart
class AlwaysNullable<T ...> {
  T notInitialized; // OK.
}
```

I'm not sure, but one way to express this might be a *supertype* constraint on
type parameters. Java has those for wildcards. It would be:

```dart
class AlwaysNullable<T super Null> {
  T notInitialized; // OK.
}
```

This says you can use any type argument that has a supertype of Null, which is
another way of saying it must be a nullable type.

## Questions

#### Why not use Option types instead of union types?

SML, Haskell, Swift and some other languages use Option types to represent
potentially absent values. Here's why I think union types are a better fit for
Dart (and other object-oriented languages with a top type in general). Let's say
you want to write a function in SML (which I know very poorly so bear with me
when I get stuff wrong) that accepts an int. You do:

```sml
fun takeInt n : Int = ...
```

When you call this:

```sml
takeInt 123
```

The compiler directly passes the bits for that number to the function. There's
no boxing or wrapping or anything. Just the number, probably in a register. That
works fine. Let's say you wanted to be able to pass it either a number or a
boolean:

```sml
takeInt 123
takeInt true
```

Obviously you can't compile those calls to just pass the raw bits. You also need
some tag so that the function can tell if it received an int or a bool. SML
doesn't give you this tag for free, so you must explicitly define an algebraic
datatype to wrap those values and keep the tag bits to distinguish at runtime
for which type was chosen:

```sml
datatype IntOrBool = Int of int | Bool of bool

fun takeEither value : IntOrBool =
  case value
     of Int n => "got int"
      | Bool b => "got bool"
```

But Dart is object-oriented. Every object in Dart is an instance of Object or
some subclass of it. It supports dynamically checked casts and "is" tests. You
can write:

```dart
takeEither(Object o) {
  if (o is int) return "got int";
  if (o is bool) return "got bool";
  if (o is Null) return "got null!";
}

main() {
  takeEither(123);
  takeEither(true);
  takeEither(null);
}
```

This prints "int", "bool", and "null", in that order.

In order for this code to work, the runtime *already* has to pass around enough
information with each value to be able to distinguish its type at runtime. We
don't need an algebraic type to hold the type information, because we have to
track it already.

(Of course, this story gets more complex if we add unboxed value types to Dart à
la structs in C# or Swift.)

It is the case that option types nest, which lets you express some things unions
cannot. My hunch is that flattening is actually more intuitive with the mental
model most Dart users have.

## Are nullable types covariant?

If the base type of one nullable type is a subtype of another's base type, does
that mean the nullable types are subtypes of each other too? Is `int?` a subtype
of `num?`?

**TODO: Figure out the answer. Intuitively, the answer should be "yes". If you
look at the sets of values each type contains, they are natural subtypes. I
don't know if we can generalize that to all union types without adding a lot of
complexity to the subtyping rules. (See the papers mentioned below.)**

**TODO: What other questions do *you* have?**

## See also

* My [old blog post](http://journal.stuffwithstuff.com/2011/10/29/a-proposal-for-null-safety-in-dart/) about non-nullable types.

* Kotlin's [article on null safety](https://kotlinlang.org/docs/reference/null-safety.html).

* [Union, Intersection, and Negation types in Whiley](http://whiley.org/2012/10/31/formalising-flow-typing-with-union-intersection-and-negation-types/).

* David J. Pearce. "Sound and Complete Flow Typing with Unions, Intersections and Negations"

* Alain Frisch et al. "Semantic subtyping: Dealing set-theoretically with function, union, intersection, and negation types"
