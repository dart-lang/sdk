# Interceptors

## Interceptors

The usual way to add methods to a JavaScript 'class' is to add properties to the
prototype of the constructor function.  This works well for user defined
constructor functions.  It does not work well for the types provided by the
JavaScript implementation since the prototypes of the builtin types are a shared
resource between all the scripts running in the same page.

**dart2js** maps Dart types to JavaScript builtin types for reasons of
efficiency and compatibility with the browser environment, e.g. a Dart String is
a JavaScript string.  In order to avoid unwanted interactions between scripts,
dart2js avoids putting properties on the builtin constructor prototypes.

An interceptor is an object containing the methods and raw type properties of an
instance.  An interceptor is a prototype chain without the instance that can be
used in place of the object's actual prototype chain.  Having a replacement
prototype chain allows us to make any object, like the builtin numbers and
strings and browser DOM objects, behave like user defined objects.  The compiler
can generate interceptor class hierarchies the same as regular class
hierarchies. The difference is that the classes (i.e. JavaScript constructor
functions) are used for their prototypes and never invoked with new.

When the operation `y = x.add(a)` goes via an interceptor the generated
JavaScript code looks like this:

```js
interceptor = getInterceptor(x);
y = interceptor.add$1(x, a);
```

The receiver is passed to the method as an explicit receiver, followed by the
original arguments.  The implicit receiver or 'this' argument tracks the type of
the receiver in interceptor space.  The call to getInterceptor is a dynamic
dispatch, which in the general case is expensive since it requires a case
analysis of the argument.  The code is large too, since every call becomes two
calls in the generated code.  Thus is it critical to avoid the full cost
wherever possible.

Interceptors have some properties useful for optimization.  The interceptor is a
function of the value, so two calls to getInterceptor with the same argument
will return the same interceptor object.  getInterceptor is effect-free.


## Constant interceptors

If the receiver is known to be a leaf class in the inheritance hierarchy, it can
have only one type.  In this case, the interceptor is a constant.  In this
example, constant FooClass_methods is the same as FooClass.prototype:

```js
interceptor = getInterceptor(x);
y = interceptor.add$1(x, a);
-->
interceptor = FooClass_methods;    // constant interceptor
y = interceptor.add$1(x, a);
-->
y = FooClass_methods.add$1(x, a);

```

In addition to replacing the expensive call with a constant, the code now
contains one fewer reference to x.  This means that chained code can be
generated with fewer temporaries and tends to be more readable:

```dart
r.x.add(a)   // Dart source

```
-->
```js
temp_x = r.get$x();
interceptor = getInterceptor(temp_x);
y = interceptor.add$1(temp_x, a);
-->
temp_x = r.get$x();
interceptor = FooClass_methods;
y = interceptor.add$1(temp_x, a);
-->
y = FooClass_methods.add$1(r.get$x(), a);
```

## Almost-constant interceptors

If the receiver is FooClass or null and all uses of the interceptor for null
should throw noSuchMethod on null, then we can select between the interceptor or
null:

```js
(x && FooClass_methods).add$(r.get$x(), a);
```
Note that we can't do this for num, bool or String since they have falsy values.

(Implemented in SSA).


## Specializations of getInterceptor

getInterceptor is a big if-then-else chain. This can be specialized to the types
possible at the call sites, and specialized to prioritize the types where the
uses of the interceptor succeed.  Consider:

```dart
dynamic x = ...
[x.codeUnitAt(0), x.length]
```

The getInterceptor specialization for `x` can be tuned for the use pattern.
It should check for `String` first.
The getInterceptor may omit tests for types that are dominated by a failure (we
don't need to check for `Array` since `x.length` will only be reached for a `String`).

(Part 2 is implemented in SSA).

## Specializations of call sites
### Dummy receiver

If the receiver cannot be an intercepted class and the selector is not used in a
mixin into an interceptor class, then the method does not use the explicit
receiver (the receiver is available as the 'this' parameter).  In this case the ignored
explicit receiver can be replaced by any expression.

```dart
findList().add(1)

```
```js
-->
temp = findList$0();
interceptor = getInterceptor(temp);
interceptor.add$1(temp, 1);
-->
temp = findList$0();
temp.add$1(temp, 1);
-->
temp = findList$0();
temp.add$1(0, 1); // dummy receiver
-->
findList$0().add$1(0, 1)
```

It is unlikely that passing 0 as a dummy value is faster, but the code is smaller.
(Implemented in SSA)

## GVN optimizations

`getInterceptor` always returns the same value for the same input and has not
side effects and cannot throw, i.e. the operation is pure.

### CSE

Re-using the result of a dominating call to `getInterceptor` is always beneficial.

### LICM

Hoisting `getInterceptor` calls out of a loop is benefical.

Improvement: `getInterceptor` is expensive, so we generally don't want to hoist
calls out of zero trip loops unless the interceptor is always eventually used,
either in the zero-trip case or somewhere else.

### PRE

Classic partial redundancy elimination (PRE) eliminates computations that are
redundant on some paths.

```dart
a = getList(...);
if (prefix != null) a.add(prefix);
a.add(data);
```
```js
-->
var a, prefix, interceptor, data;
a = getList(...);
if (prefix != null) {
  interceptor = getInterceptor(a);
  interceptor.add$1(a, prefix);
}
interceptor = getInterceptor(a);
interceptor.add$1(a, data);
-->
var a, prefix, interceptor, data;
a = getList(...);
if (prefix != null) {
  interceptor = getInterceptor(a);
  interceptor.add$1(a, prefix);
} else {
  interceptor = getInterceptor(a);
}
interceptor.add$1(a, data);
```

This is not currently implemented. It would be especially advantageous if the
interceptor is constant on one path.

### Dynamic PRE

```js
var a, interceptor;
while (...) {
  a = ...;
  if (x != null) {
    interceptor = getInterceptor(a);
    interceptor.add$1(a, x);
  }
  if (y != null) {
    interceptor = getInterceptor(a);
    interceptor.add$1(a, y);
  }
}
-->
while (...) {
  var a = ...;
  if (x != null) {
    interceptor = getInterceptor(a);
    interceptor.add$1(a, x);
  }
  if (y != null) {
    if (!interceptor) interceptor = getInterceptor(a);
    interceptor.add$1(a, y);
  }
}
```

## One-shot interceptors

One-shot interceptors are code size optimization that removes the need for a
temporary to hold the receiver.

```js
// r = a.foo() + b;
var t = a.foo$0();
var r = getInterceptor(t).$add(t, b);
-->
$add = function(x, y) {
  return getInterceptor(x).$add(x, y);
}
...
r = $add(a.foo(), b);
```

One-shot interceptors are a special case of outlining.

Single-use interceptors used in type tests (`is` expressions) can sometimes be
replaced with `instanceof`-based type tests
https://github.com/dart-lang/sdk/issues/22016 .

### Customized one-shot interceptors

One-shot interceptors for common operations like `+` are customized with a quick
dispatch for common input types.

```js
$add = function(x, y) {
  if (typeof x == "number" && typeof y == "number") return x + y;
  return getInterceptor(x).$add(x, y);
}
...
// r = a.foo() + b;
r = $add(a.foo(), b);

```

## Sufficing

(Not implemented)

Sufficing is an extension of constant interceptors.  If the receiver is known to
be of a non-leaf class in the hierarchy, it might be possible to use the
constant interceptor for the non-leaf class. Explained further:
https://github.com/dart-lang/sdk/issues/22199

## Interprocedural GVN
Shadow field or closed variable
https://github.com/dart-lang/sdk/issues/23686





