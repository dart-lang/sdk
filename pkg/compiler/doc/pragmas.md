# Pragma Annotations understood by dart2js

## Pragmas for general use

| Pragma | Meaning |
| --- | --- |
| `dart2js:noInline` | [Never inline a function or method](#requesting-a-function-never-be-inlined) |
| `dart2js:never-inline` | Alias for `dart2js:noInline` |
| `dart2js:tryInline` | [Inline a function or method when possible](#requesting-a-function-be-inlined) |
| `dart2js:prefer-inline` | Alias for `dart2js:tryInline` |
| `dart2js:disable-inlining` | [Disable inlining within a method](#disabling-inlining) |
| `dart2js:noElision` | Disables an optimization whereby unused fields or unused parameters are removed |
| `dart2js:load-priority:normal` | [Affects deferred library loading](#load-priority) |
| `dart2js:load-priority:high` | [Affects deferred library loading](#load-priority) |
| `dart2js:resource-identifier` | [Collects data references to resources](resource_identifiers.md) |
| `weak-tearoff-reference` | [Declaring a static weak reference intrinsic method.](#declaring-a-static-weak-reference-intrinsic-method) |

## Unsafe pragmas for general use

These pragmas are available for use in third-party code but are potentially
unsafe. The use of these pragmas is discouraged unless the developer fully
understands potential repercussions.

| Pragma | Meaning |
| --- | --- |
| `dart2js:as:check` | [Check `as` casts](#casts) |
| `dart2js:as:trust` | [Trust `as` casts](#casts) |
| `dart2js:downcast:check` | [Check downcasts](#downcasts) |
| `dart2js:downcast:trust` | [Trust downcasts](#downcasts) |
| `dart2js:index-bounds:check` | TBD |
| `dart2js:index-bounds:trust` | TBD |
| `dart2js:late:check` | [Check late fields are used correctly](#late-checks) |
| `dart2js:late:trust` | [Trust late fields are used correctly](#late-checks) |
| `dart2js:parameter:check` | TBD |
| `dart2js:parameter:trust` | TBD |
| `dart2js:types:check` | TBD |
| `dart2js:types:trust` | TBD |

## Pragmas for internal use

These pragmas can cause unsound behavior if used incorrectly and therefore are
only allowed within the core SDK libraries.

| Pragma | Meaning |
| --- | --- |
| `dart2js:assumeDynamic` | TBD |
| `dart2js:disableFinal` | TBD |
| `dart2js:noSideEffects` | Requires `dart2js:noInline` to work properly |
| `dart2js:noThrows` | Requires `dart2js:noInline` to work properly |

## Detailed descriptions

### Annotations related to function inlining

Function (method) inlining is a compiler optimization where a call to a function
is replaced with the body of the function.  To perform function inlining, the
compiler needs to determine that the call site calls exactly one function, the
target.  This is trivial for top-level methods, static methods and
constructors. For calls to instance methods, the compiler does an analysis of
the possible types of the receiver and uses that to reduce the set of potential
targets. If there is a single target, it can potentially be inlined.

Not all functions can be inlined. For example, a recursive function cannot be
expanded by inlining indefinitely. `dart2js` will not inline functions complex
control flow, such as methods with exception handling (`try`-`catch`-`finally`)
or many return or throw exit points.

We say a function is a _viable inlining candidate_ when it is the single target
and it is possible to perform the inlining.

One benefit of inlining is that the execution cost of performing the call is
avoided, which can be a substantial part of the total cost of the call when the
body of the callee is simple.  Copying instructions from the callee into the
caller can create more opportunities for optimization, for example, it becomes
possible to recognize and remove repeated operations.

The compiler automatically makes a decision whether or not to inline a function
or method based on heuristics. One heuristic is to inline if the inlined
code is likely to be smaller that the call, as this results in a smaller _and_
faster program. Another heuristic is to inline even if the code is likely to be
slightly larger when the call is in a loop, as loops here is a chance that some
of the code can be hoisted out of the loop.

The annotations described below allow the developer to override the default
decisions. They should be used sparingly since it is likely that over time
manual overrides will become increasingly out of date and mismatched with the
evolving capabilities of the compiler.

#### Requesting a function be inlined

```dart
@pragma('dart2js:tryInline')
```

```dart
@pragma('dart2js:prefer-inline') // Alias for the above annotation.
```

This annotation may be placed on a function or method.

The compiler will inline the annotated function wherever it is a viable inlining
candidate.


#### Requesting a function never be inlined

```dart
@pragma('dart2js:noInline')
```

```dart
@pragma('dart2js:never-inline') // Alias for the above annotation.
```

This annotation may be placed on a function or method to prevent the function
from being inlined.

#### Disabling inlining

```dart
@pragma('dart2js:disable-inlining')
```

This annotation may be placed on a function or method.

Function inlining is disabled at call sites within the annotated function.
Inlining is disabled even when the call site has a viable inlining candidate
that is annotated with `@pragma('dart2js:tryInline')`.


### Annotations related to run-time checks

The Dart language and runtime libraries mandate checks in various places. Checks
result in some kind of `Error` exception being thrown.  If a program has a high
degree of test coverage, the developer might have some confidence that the
checks will never fail. If this is the case, the checks can be disabled via
command line options or annotations. Annotations override the command line
settings.

Trusting (i.e. disabling) checks can lead to a smaller and faster program.  The
cost is highly confusing unspecified behavior in place of the `Error`s that
would otherwise have been thrown. The unspecified behavior is not necessarily
consistent between runs and includes the program execution reaching statements
that are 'impossible' to reach and variables being assigned values of an
'impossible' type.

#### Casts

```dart
@pragma('dart2js:as:check')
@pragma('dart2js:as:trust')
```

These annotations may be placed on a function or method to control whether `as`
casts in the body of the function are checked.

One use of `dart2js:as:trust` is to construct an `unsafeCast` method.

```dart
@pragma('dart2js:tryInline')
@pragma('dart2js:as:trust')
T unsafeCast<T>(Object? o) => o as T;
```

The `tryInline` pragma ensures that the function is inlined, removing the cost
of the call and passing the type parameter `T`, and the `as:trust` pragma
removes the code that does the check.

#### Downcasts

```dart
@pragma('dart2js:downcast:check')
@pragma('dart2js:downcast:trust')
```

These annotations may be placed on a function or method to control whether
implicit downcasts in the body of the function are checked.

This is similar to the `dart2js:as:check` and `dart2js:as:trust` pragmas except
it applies to implicit downcasts. Implicit downcasts are `as` checks that are
inserted to cast from `dynamic`.

The `unsafeCast` method described above could also be written by trusting
implicit downcasts.

```dart
@pragma('dart2js:tryInline')
@pragma('dart2js:downcast:trust')
T unsafeCast<T>(dynamic o) => o; // implicit downcast `as T`.
```

Trusting implicit downcasts is part of the `-O3` and `-O4` optimization level
command line options. `dart2js:downcast:check` can be used to enable checking of
implicit downcasts in a method when it would otherwise be trusted due to the
command line options.

#### Late checks

Late checks - checking whether a late variable has been initialized - occur on
all late variables.  The checks on late instance variables (i.e. late fields)
can be controlled via the following annotations.

```dart
@pragma('dart2js:late:check')
@pragma('dart2js:late:trust')
```

These annotations may be placed on the declaration of a late field, class, or
library. When placed on a class, the annotation applies to all late fields of
the class. When placed on a library, the annotation applies to all late fields
of all classes in the library. `dart2js:late` annotations are _scoped_: when
there are multiple annotations, the one nearest the late field wins.

In the future this annotation might be extended to apply to `late` local
variables, static variables, and top-level variables.


### Annotations related to deferred library loading

#### Load priority

**This is not fully implemented.** The annotation exists but **has no effect**.


```dart
@pragma('dart2js:load-priority:normal')
@pragma('dart2js:load-priority:high')
```

By default, a call to `prefix.loadLibrary()` loads the library with 'normal'
priority.  These annotations may be placed on the import specification to change
the priority for all calls to `prefix.loadLibrary()`.

The annotation my also be placed closer to the `loadLibrary()` call.  When
placed on a method, the annotation affects all calls to
`prefix.loadLibrary()` inside the method.

When placed on a local variable, the annotation affects all calls to
`prefix.loadLibrary()` in the initializer of the local variable. In the
following example, only `prefix2` is loaded with high priority because of the
annotation on the variable called "`_`":

```dart
    await prefix1.loadLibrary();
    @pragma('dart2js:load-priority:high')
    final _ = await prefix2.loadLibrary();
    await prefix3.loadLibrary();
```

`dart2js:load-priority` annotations are _scoped_: when there are multiple
annotations, the one on the nearest element enclosing the call to
`loadLibrary()` is in effect.

### Declaring a static weak reference intrinsic method

```dart
@pragma('weak-tearoff-reference')
T Function()? weakRef<T>(T Function()? x) => x;
```

Declares a special static method `weakRef` which can be used to create weak references
to tearoffs of static methods. Weak reference declaration should be a static method taking
one positional required argument. Its return type should be nullable and should match
argument type. It should be either `external` or return its argument (for backwards compatibility).

Compiler replaces `weakRef(foo)` expression with either `foo` if method `foo()` is used and retained during
tree shaking, or `null` if `foo()` is only used through weak references.
Target `foo` should be a constant tearoff of a static method without arguments.
