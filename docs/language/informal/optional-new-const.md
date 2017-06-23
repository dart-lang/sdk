# Optional new/const

Author: Lasse R.H. Nielsen ([lrn@google.com](mailto:lrn@google.com))

Version: 0.8 (2017-06-20)

Status: Under discussion

This informal specification documents a group of four related features.
* Optional `const`
* Optional `new`
* Constructor tear-offs
* Potentially constant auto-`new`/`const`.

These are ordered roughly in order of priority and complexity. The constructor tear-offs feature effectively subsumes and extends the optional `new` feature.

## Optional const (aka. "const insertion")

In current Dart code, every compile-time constant expression (except for annotations) must be prefixed with a `const` keyword. This is the case, even when the context requires the expression to be a compile-time constant expression.

For example, inside a `const` list or map, all elements must be compile-time constants. This leads to repeated `const` keywords in nested expressions:

```dart
const dictionary = const {
  "a": const ["able", "apple", "axis"],
  "b": const ["banana", "bold", "burglary"],
  …
};
```

Here the `const` on the map and all the lists are *required*, which also means that they are *redundant* (and annoying to have to write).

The "optional const" feature allows you to omit the `const` prefix in places where it would otherwise be required. It is effectively optional.

The feature can also be seen as an "automatic const insertion" feature that automatically inserts the missing `const` where it's necessary. The end effect is the same - the user can omit writing the redundant `const`.
This is somewhat precedented in that metadata annotations can be written as `@Foo(constantArg)`.

Making `const` optional intersects perfectly with the "optional new" feature below, which does the same thing for `new`.

Currently, the `const` prefix is used in front of map literals, list literals and *constructor calls*.
Omitting the `const` prefix from list and map literals does not introduce a need for new syntax, since that syntax is already used for plain list and map literals.
That doesn't apply to un-prefixed constructor calls – those do introduce a syntax that isn't currently allowed:
`MyClass<SomeType>.name(arg)`. The language allows generic function invocation, which covers the unnamed constructor call `MyClass<SomeType>(arg)`, but it doesn't allow applying type parameters to an identifier and *not* immediately calling the result.

To allow all const constructor invocations to omit the `const`, the grammar needs to be extended to handle the case of `MyClass<SomeType>.name(arg)`.
This syntax will only apply to unprefixed constructor invocations (at least unless we also introduce type-instantiated generic method tear-offs).

### Prior discussion
See http://dartbug.com/4046 and https://github.com/lrhn/dep-const/blob/master/proposal.md

The syntax for a constructor call is less ambiguous now than when these proposals were drafted, because generic methods have since been added to the language. The language has already decided how to resolve parsing of the otherwise ambiguous `Bar(Foo<int, bar>(42))`.


### Informal specification

*   An expression occurs in a "const context" if it is
    *   a literal const `List`, const `Map` or const constructor invocation (`const {...}`, `const [...]`, `const Symbol(...)`, `@Symbol(...)`),
    *   a parameter default value,
    *   the initializer expression of a const variable,
    *   a case expression in a switch statement, or
    *   is a sub-expression of an expression in a const context.

    That is: `const` introduces a const context for all its sub-expressions, as do the syntactic locations where only const expressions can occur.

*   If a non-const `List` literal, non-const `Map` literal or invocation expression (including the new generic-class-member notation) occurs in a const context, it is equivalent to the same expression with a `const` in front. That is, you don't have to write the `const` if it's required anyway.
That is, an expression on one of the forms:
    *   `Foo(args)`
    *   `Foo<types>(args)`
    *   `Foo.bar(args)`
    *   `Foo<types>.bar(args)`
    *   `prefix.Foo(args)`
    *   `prefix.Foo<types>(args)`
    *   `prefix.Foo.bar(args)`
    *   `prefix.Foo<types>.bar(args)`
    *   `[elements]`
    *   `{mapping}`

    becomes valid in a `const` context.

*   The grammar is extended to allow `Foo<types>.id(args)` and `prefix.Foo<typeArguments>.id(args)` as an expression. They would not otherwise be valid expressions anywhere in the current grammar. They still only work in a const context (it's a compile-time error if they occur elsewhere, just not a grammatical error).

*   Otherwise this is purely syntactic sugar, and existing implementations can handle this at the syntactic level by inserting the appropriate synthetic `const` prefixes.


## Optional new (aka. "new insertion")

Currently, a call to a constructor without a prefixed `new` (or `const`) is invalid. With the optional const feature above, it would become valid in a const context, but not outside of a const context.

So, if the class `Foo` has a constructor `bar` then `Foo.bar()` is currently a static warning/runtime failure (and strong mode compile-time error).

Like for "optional const", we now specify such an expression to be equivalent to `new Foo.bar()` (except in a const context where it's still equivalent to `const Foo.bar()`).

The "empty-named" constructor also works this way: `Foo()` is currently a runtime-error, so we can change its meaning to be equivalent to `new Foo()`.

Like for optional const, we need to extend the grammar to accept `List<int>.filled(4, 42)`.

The `new` is optional, not prohibited. It may still be useful to write `new` as documentation that this actually creates a new object. Also, some constructor names might be less readable without the `new` in front.

In the longer run, we may want to remove `new` so there won't be two ways to do the same thing, but whether that is viable depends on choices about other features that we are considering.

Having optional `new` means that changing a static method to be a constructor is not necessarily a breaking change. Since it's only optional, not disallowed, changing in the other direction is a breaking change.

### Prior discussion

See: http://dartbug.com/5680, http://dartbug.com/18241, http://dartbug.com/20750.

### Informal specification

*   An expression on one of the forms:
    *   `Foo(args)`
    *   `Foo<types>(args)`
    *   `Foo.bar(args)`
    *   `Foo<types>.bar(args)`
    *   `prefix.Foo(args)`
    *   `prefix.Foo<types>(args)`
    *   `prefix.Foo.bar(args)`
    *   `prefix.Foo<types>.bar(args)`

    where `Foo`/`prefix.Foo` denotes a class and `bar` is a named constructor of the class, and that is not in a const context, are no longer errors.

*   Instead they are equivalent to the same expression with a `new` in front. This makes the `new` optional, but still allowed.
*   The grammar allows `prefix.Foo<typeArguments>.bar(args)` and `Foo<typeArguments>.bar(args)` as expressions everywhere, not just inside const contexts. These are not valid syntax in the current grammar.
*   Otherwise this is purely syntactic sugar, and existing implementations can handle this at the syntactic level by inserting a synthetic `new` in front of non-const expressions that would otherwise try to invoke a constructor. This is statically detectable.

## Constructor tear-offs

With constructors being callable like normal static functions, it makes sense to also allow them to be *torn off* in the same way. If `Foo.bar` is a constructor of class `Foo`, then the *expression* `Foo.bar` will be a tear-off of the constructor (it evaluates to a function with the same signature as the constructor, and calling the function will invoke the constructor with the same arguments and an implicit `new`, and return the result).

The tear-off of a constructor from a non-generic class is treated like a tear-off of a static method - it's a compile-time constant expression and it is canonicalized. A generic class constructor tear-off is treated like the tear-off of an instance method. It is not a compile-time constant and it isn't required to be canonicalized, but it must still be *equal* to the same constructor torn off the same class instantiated with the same type parameters.

For a non-named constructor, the expression `Foo` already has a meaning – it evaluates to the `Type` object for the class `Foo` – so we can't use that to refer to the unnamed constructor.

We will introduce the notation `Foo.new`. This is currently a syntax error, so it doesn't conflict with any existing code.

For named constructors, an expression like `Foo<int>.bar` (not followed by arguments like the cases above) is not currently allowed by the syntax, so there is no conflict.

This tear-off syntax is something we want in any case, independently of the optional new/const changes above. However, the syntax completely subsumes the optional `new` feature; with tear-off syntax, `Foo.bar(42)` is just the tear-off `Foo.bar` expression called as a function. You'd have to write `Foo.new(42)` instead of just `Foo(42)` (which is an argument for re-purposing the `Foo` expression to refer to the constructor instead of the type).
That is, if we have constructor tear-offs, the only feature of optional `new` that isn't covered is calling the unnamed constructor.


### Informal specification

*   An expression *x* on one of the forms:
    *   `Foo.new`
    *   `Foo<types>.new`
    *   `Foo.bar`
    *   `Foo<types>.bar`
    *   `prefix.Foo.new`
    *   `prefix.Foo<types>.new`
    *   `prefix.Foo.bar`
    *   `prefix.Foo<types>.bar`

    where `Foo` and `prefix.Foo` denotes a class and `bar` is a constructor of `Foo`, and the expression is not followed by arguments `(args)`, is no longer an error.

    Not included are expressions like `Foo..new(x)` or `Foo..bar(x)`. This is actually an argument against adding static cascades (`C..foo()..bar()` isn't currently a static call, it's a cascade on the `Type` object).

*   Instead of being an error, the expression evaluates to a function value
    *   with the same signature as the constructor (same parameters, default values, and having `Foo` or `Foo<types>` as return type),
    *   which, when called with `args`, returns the same result as `new x'(args)` where `x'` is `x` without any `.new`.
    *   if `Foo` is not generic, the expression is a canonicalized compile-time constant (like a static method).
    *   If `Foo` is generic, the function is `==` to another tear off of the same constructor from "the same instantiation" of the class (like an instance method tear-off). We have to nail down what "the same instantiation" means, especially if `void == Object` in our type system.
*   This feature be *implemented* by adding a static method for each non-generic class constructor:

    ```dart
    class C {
      C(x1, …, xn) : … { body }
      static C C_asFunction(x1, … , xn) => new C(x1, … , xn);
    }
    ```

    The tear-off of `C.new` is just `C_asFunction`.

*   … and adding a new helper class for each generic class with constructors:

    ```dart
    class D<T> {
      D(x1, …, xn) : … { body }
    }
    class D_constructors<T> {
      const D_constructors();
      D_asFunction(x1, …, xn) => new D<T>(x1, …, xn);
    }
    ```

    Then the tear-off of `D<T>.new` is `const D_constructors<T>().D_asFunction`. If the type `T` is a non-const type parameter, the equality is harder to preserve, and the implementation might need to cache and canonicalize the `D_constructors` instances that it does the method tear-offs from, or some other clever hack.

*   In strong mode, method type parameters are not erased, so the implementation might be able to just create a closure containing the type parameter without a helper class (but equality might be harder to get correct that way).
*   In most cases, implementations should be able to be more efficient than this rewriting if they can refer directly to their representation of the constructor.

### Alternatives
Instead of introducing a new syntax, `Foo.new`, we could potentially re-purpose the plain `Foo` to refer to the constructor and introduce a new syntax for the `Type` object for the class, say the Java-esque `Foo.class`. It would be a major breaking change, though, even if it could be mechanized. We should consider whether it's feasible to make this change, because it gives much better uniformity in what `Foo` means.

## Optional new/const in *potentially* const expressions

Together, the "optional const" and "optional new" features describe what happens if you omit the operator on a constructor call in a const or normal expression. However, there is one more kind of expression in Dart - the *potentially constant expression*, which only occurs in the initializer list of a generative const constructor.

Potentially constant expressions have the problem that you can't write `new Foo(x)` in them, because that expression is never constant, and you can't write `const Foo(x)` if `x` is a parameter, because `x` isn't always constant. The same problem applies to list and map literals.

Allowing you to omit the `new`/`const`, and just write nothing, gives us a way to provide a new meaning to a constructor invocation (and list and map literals) in a potentially const expression: Treat it as `const` when invoked as a const constructor, and as `new` when invoking normally.

This also allows you to use the *type parameters* of the constructor to create new objects, like `class Foo<T> { final List<T> list; const Foo(int length) : list = List<T>(length); }`. Basically, it can treat the type parameter as a potentially constant variable as well, and use it.

The sub-expressions must still all be potentially const, but that's not a big problem.

It does introduce another problem that is harder to handle - avoiding infinite recursion at compile-time.

If a constructor can call another constructor as a potentially constant expression, then it's possible to recurse deeply - or infinitely.

Example:


```dart
class C {
  final int value;
  final C left;
  final C right;
  const C(int start, int depth)
    : left = (depth == 0 ? null : C(start, depth - 1)),
      value = start + (1 << depth),
      right = (depth == 0 ? null : C(start + (1 << depth), depth - 1));
}
```

This class would be able to generate a complete binary tree of any depth as a compile-time constant, using only *potentially constant* expressions and `const`/`new`-less constructor calls.

It's very hard to distinguish this case from one that recurses infinitely, and the latter needs to be able to be caught and rejected at compile-time. We need to add some cycle-detection to the semantics to prevent arbitrary recursion. Since no recursion is currently possible, it won't break anything.

Proposed restriction: Don't allow a constant constructor invocation to invoke the same constructor again *directly*, where "directly" means:

*   as a sub-expression of an expression in the initializer list, or
*   *directly* in the initializer list of another const constructor that is invoked by a sub-expression in the initializer list.

This transitively prevents the unfolding of the constructor calls to recurse without any limiting constraint.

It does not prevent the invocation from referring to a const variable whose value was created using the same constructor, so the following is allowed:


```dart
const c0 = const C(0);
const c43 = const C(43);
class C {
  final v;
  const C(x) : v = ((x % 2 == 0) ? x : c0);  // Silly but valid.
}
```


The `const C(0)` invocation does not invoke `C` again, and the `const C(43)` invocation doesn't invoke `C` again, it just refers to another (already created) const value.

As usual, a const *variable* cannot refer to itself when its value is evaluated.

This restriction avoids infinite regress because the number of const variables are at most linear in the source code of the program while still allowing some reference to values of the same type.

Breaking the recursive constraint at variables also has the advantage that a const variable can be represented only by its value. It doesn't need to remember which constructors were used to create that value, just to be able to give an error in cases where that constructor refers back to the variable.

This feature is more invasive and complicated than the previous three. If this feature is omitted, the previous three features still makes sense and should be implemented anyway.

### Prior discussion

See: [issue 18241](http://dartbug.com/18241)

### Informal specification

In short:

*   A const constructor introduces a "potentially const context" for its initializer list.
*   This is treated similarly to a const context when the constructor is invoked in a const expression and as normal expression when the constructor is invoked as a non-const expression.,
*   This means that `const` can be omitted in front of `List` literals, `Map` literals and constructor invocations.
*   All subexpressions of such expressions must still be *potentially const expressions*, otherwise it's still an error.
*   It is a compile-time error if a const constructor invoked in a const expression causes itself to be invoked again *directly* (immediately in the initializer list or recursively while evaluating another const constructor invocation). It's not a problem to refer to a const variable that is created using the same constructor. (This is different from what the VM currently does - the analyzer doesn't detect cycles, and dart2js stack-overflows).
*   The grammar allows `type<typeArguments>(args)` and `type<typeArguments>.foo(args)` as an expression in potentially const contexts, where the latter isn't currently valid syntax, and the former wouldn't be allowed in a const constructor.
*   This is not just syntactic sugar:
    *   It makes const and non-const constructor invocations differ in behavior. This alone can be simulated by treating it as two different constructors (perhaps even rewriting it into two constructors, and change invocations to pick the correct one based on context).
    *   The const version of the constructor now allows parameters, including type parameters, to occur as arguments to constructor calls and as list/map members. This is completely new.
    *   The language still satisfies that there is only one compile-time constant value associated with each `const` expression, but some expression in const constructor initializer lists are no longer const expressions, they are just used as part of creating (potentially nested) const values for the const expressions. Effectively the recursive constructor calls need to be unfolded at each creation point, not just the first level. Each such unfolding is guaranteed to be finite because it can't call the same constructor recursively and it stops at const variable references (or literals). It *can* have size exponential in the code size, though.



## Migration

All the changes in this document are non-breaking - they assign meaning to syntax that was previously an error, either statically or dynamically. As such, code does not *need* to be migrated.

We will want to migrate library, documentation and example code so they can serve as good examples. It's not as important as features that affect the actual API. The most visible change will likely be that some constructors can now be torn off as a const expression and used as a parameter default value.

All other uses will occur inside method bodies or initializer expressions.

Removing `new` is easy, and can be done by a simple RegExp replace.

Removing nested `const` probably needs manual attention ("nested" isn't a regular property).

Using constructor tear-offs will likely be the most visible change, with cases like:


```dart
map.putIfAbsent(42, HashSet<int>.new);  // Rather than map.putIfAbsent(42, () => HashSet<int>()))
bars.map(Foo.fromBar)...  // rather than bars.map((x) => Foo.fromBar(x))
```

Once the features are implemented, this can be either done once and for all, or incrementally since each change is independent, but we should plan for it.

## Related possible features

### Type variables in static methods

When you invoke a static method, you use the class name as a name-space, e.g., `Foo.bar()`.

If `Foo` is a generic class, you are not allowed to write `Foo<int>.bar()`. However, that notation is necessary for optional `new`/`const` anyway, so we might consider allowing it in general. The meaning is simple: the type parameters of a surrounding class will be in scope for static methods, and can be used both in the signature and the body of the static functions.

If the type parameter is omitted, it defaults to dynamic/is inferred to something, and it can be captured by the `Foo<int>.bar` tear-off.

This is in agreement with the language specification that generally treats `List<int>` as a class and the generic `List` class declaration as declaring a mapping from type arguments to classes.

It makes constructors and static methods more symmetric.

It's not entirely without cost - a static method on a class with a bound can only be used if you can properly instantiate the type parameter with something satisfying the bound. A class like


```dart
class C<T extends C<T>> {
   int compare(T other);
   static int compareAny(dynamic o1, dynamic o2) => o1.compare(o2);
}
```


would not be usable as `C.compareAny(v1, v2)` because `C` cannot be automatically instantiated to a valid bound. That is a regression compared to now, where any static method can be called on any class without concern for the type bound. This regression might be reason enough to drop this feature.

Also, if the class type parameters are visible in members, including getters and setters, it should mean that that *static fields* would have to exist for each instantiation, not just once. That's so incompatible with the current behavior, and most likely completely unexpected to users. This idea is unlikely to ever happen.

### Instantiated Type objects

The changes in this document allows `Foo<T>` to occur:

*   Followed by arguments, `Foo<T>(args)`
*   Followed by an identifier, `Foo<T>.bar` (and optionally arguments).
*   Followed by `new`, `Foo<T>.new`.

but doesn't allow `Foo<T>` by itself, not even for the non-named constructor.

The syntax is available, and needs to be recognized in most settings anyway, so we could allow it as a type literal expression. That would allow the expression `List<int>` to evaluate to the *Type* object for the class *List<int>*. It's been a long time (refused) request: [issue 23221](http://dartbug.com/23221).

The syntax will also be useful for instantiated generic method tear-off like `var intContinuation = future.then<int>;`

### Generic constructors

We expect to allow generic constructors.
Currently constructors are not generic the same way other methods are. Instead they have access to the class' type parameters, but they can't have separate type parameters.

We plan to allow this for name constructors, so we can write:
```dart
class Map<K, V> {
  …
  factory Map.fromIterable<S>(
    Iterable<S> values, {K key(S value), K value(S value)}) {
      …
  }
  …
}
```
Having generic constructors shouldn't add more syntax with optional `new` because it uses the same syntax as generic method invocation. If anything, it makes things more consistent.

### Inferred Constant Expression

An expression like `Duration(seconds: 2)` can be prefixed by either `const` or `new`. The optional `new` feature would make this create a new object for each evaluation.
However, since all arguments are constant and the constructor is `const`, it could implicitly become a `const` expression instead.

This has some consequences – if you actually need a new object each time (say a `new Object()` to use as a marker or sentinel), you would now *have to* write `new` to get that behavior. This suggests that if we introduce this feature at all, we should do so at the same time as optional `new`, it would be a breaking change to later change `Object()` from `new` to `const`.

This feature also interacts with optional const. An expression like `Foo(Bar())`, where both `Foo` and `Bar` are `const` constructors, can be either `const` or `new` instantiated. It would probably default to `new`, but writing `const` before either `Foo` or `Bar` would make the other be inferred as constant as well. It's not clear that this is predictable for users (you can omit either, but not both `const` prefix without changing the meaning).

### Revisions

0.5 (2017-02-24) Initial version.

0.6 (2017-06-08) Added "Migration" section, minor tweaks.

0.7 (2017-06-19) Reordered features, added more related features.

0.8 (2017-06-20) Fix-ups and typos.
