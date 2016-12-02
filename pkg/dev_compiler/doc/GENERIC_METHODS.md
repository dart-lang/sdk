# Using Generic Methods

Initially a [proposal][], generic methods are on their way to being fully
supported in Dart. Here is how to use them.

[proposal]: https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md

When they were still being prototyped, and [older comment-based syntax was
designed][old] so that the static analysis could be implemented and tested
before the VM and compilers needed to worry about the syntax. Now that real
syntax is allowed everywhere, this doc has been updated.

[old]: GENERIC_METHOD_COMMENTS.md

## Declaring generic methods

Type parameters for generic methods are listed after the method or function
name, inside angle brackets:

```dart
/// Takes two type parameters, [K] and [V].
Map<K, V> singletonMap<K, V>(K key, V value) {
  return <K, V>{ key, value };
}
```

As with classes, you can put bounds on type parameters:

```dart
/// Takes a list of two numbers of some num-derived type [T].
T sumPair<T extends num>(List<T> items) {
  return items[0] + items[1];
}
```

Class methods (instance and static) can be declared to take generic parameters
in the same way:

```dart
class C {
  static int f<S, T>(int x) => 3;
  int m<S, T>(int x) => 3;
}
```

This even works for function-typed parameters, local functions, and function
expressions:

```dart
/// Takes a generic method as a parameter [callback].
void functionTypedParameter(T callback<T>(T thing)) {}

// Declares a local generic function `itself`.
void localFunction() {
  T itself<T>(T thing) => thing;
}

// Binds a generic function expression to a local variable.
void functionExpression() {
  var lambda = <T>(T thing) => thing;
}
```

We do not currently support a way to declare a function as *returning* a generic
function. This will eventually be supported using a `typedef`.

## Using generic method type parameters

You've seen some examples already, but you can use a generic type parameter
anywhere you would expect in a generic method.

* Inside the method's parameter list:

    ```dart
    takeThing<T>(T thing) { ... }
    //           ^-- here
    ```

* Inside type annotations in the body of the method:

    ```dart
    useThing<T>() {
      T thing = getThing();
    //^-- here
      List<T> pair = [thing, thing];
      //   ^-- and here
    }
    ```

* In the return type of the method:

    ```dart
      T itself<T>(T thing) => thing;
    //^-- here
    ```

* As type arguments in generic classes and method calls:

    ```dart
    useThing<T>(T thing) {
      var pair = <T>[thing, thing];
      //          ^-- here
      var set = new Set<T>()..add(thing);
      //                ^-- here
    }
    ```

    Note that generic methods are not yet supported *at runtime* on the VM and
    dartjs. On those platforms, uses of generic method type arguments are
    treated like `dynamic` today. So in this example, `pair`'s reified type at
    runtime will be `List<dynamic>` and `set` will be `Set<dynamic>`.

* As a type literal:

    ```dart
    printType<T>() {
      Type t = T;
      //       ^-- here
      print(t);
    }
    ```

    Again, note that on the VM and dart2js, this will currently print "dynamic".

## Calling generic methods

Most of the time, when you call a generic method, you can leave off the type
arguments and strong mode's type inference will fill them in for you
automatically. For example:

```dart
var fruits = ["apple", "banana", "cherry"];
var lengths = fruits.map((fruit) => fruit.length);
```

`Iterable.map<S>(S transform(T` is now a generic method that takes a type
parameter for the element type of the returned sequence:

```dart
Iterable.map<S>(S transform(T element))
```

In this example, the type checker:

1. Infers `List<String>` for the type of `fruits` based on the elements in the
   list literal.
2. That lets it infer `String` for the type of the lambda parameter `fruit`
   passed to `map`.
3. Then, from the result of calling `.length`, it infers the return type of the
   lambda to be `int`.
4. That in turn is used to fill in the type argument to the call to `map` as
   `int`, and the resulting sequence is an `Iterable<int>`.

If inference *isn't* able to fill in a type argument for you, it uses `dynamic`
instead. If that isn't what you want, or it infers a type you don't want, you
can always pass them explicitly:

```dart
// Explicitly give a type so that we don't infer "int".
var lengths = fruits.map<num>((fruit) => fruit.length).toList();

// So that we can later add doubles to the result.
lengths.add(1.2);
```
