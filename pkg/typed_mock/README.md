A library for mocking classes and verifying expected interaction with mocks.

It is inspired by [Mockito](https://code.google.com/p/mockito/).

Features of this package:
- Code-completion, static validation, search and refactoring all work properly with mocks.
- Much better error messages for unit testing.
- Works with concrete and abstract classes.
- Does not use mirrors.
- No dependent packages.

Other Mock libraries for Dart:
- https://pub.dartlang.org/packages/mockito
- https://pub.dartlang.org/packages/mock (deprecated)

## Tutorial

Let's take the simple case of making sure that a method is called. The first step is to create a mock of the object, as shown below. One nice feature of Dart is that all classes automatically define interfaces, so you don't need to separately define the interface.

```dart
import 'package:typed_mock/typed_mock.dart';

class Dog {
  String speak() => "Woof!";
}

class MockDog extends TypedMock implements Dog {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

All of the magic happens because of the noSuchMethod() function. None of the functions for Animal are actually defined because we used `implements` instead of `extends`. Therefore, all calls to this object will end up in `noSuchMethod()`.

#### Verify a function is called

Here's the code to verify that the function is called:

```dart

void main() {
  final dog = new MockDog();
  verifyZeroInteractions(dog);
  dog.speak();
  verify(dog.speak()).once();
  verifyNoMoreInteractions(dog);
}
```

One of the interesting features of typed_mock is that it internally tracks all calls to each mock object, then tracks which calls have been matched with a verify() call and which not. Therefore, typed_mock is able to detect unexpected calls, even if those calls are made to methods that didn't exist when the test was written. This can be a good incentive to update your tests whenever you change a class.

After creating the `MockAnimal` object, we call `verifyZeroInteractions()` to make sure that the object starts in a clean state. Next we call the `speak()` method, then prove that the speak function was actually called with `verify().once()`.

There are several other functions for verifying calls that can be used instead of `once()`:
- `atLeastOnce()` Ensure the function was called one or more times.
- `times(n)` Ensure the function was called exactly `n` times.
- `atLeast(n)` Ensure the function was called `n` or more times.
- `atMost(n)` Ensure the function was called no more than `n` times.
- `any()` Mark the function call as verified if it was called, but don't fail if it wasn't called.
- `never()` Ensure the function was never called. It's often better to use `verifyNoMoreInteractions()` instead.

#### Configure the mock to return a value

Here's how to return a value from `speak()`:

```dart
void main() {
  final dog = new MockDog();
  when(dog.speak()).thenReturn("woof");
  final s = dog.speak();
  print("$s");
  verify(dog.speak()).once();
  verifyNoMoreInteractions(dog);
}
```

What if `speak()` took the name of an animal as a parameter? When typed_mock tracks a function call, the call tracking is based on the function name and the parameters. For example:


```dart
import 'package:typed_mock/typed_mock.dart';

abstract class Animal {
  String speak();
}

class MockAnimal extends TypedMock implements Animal {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final animal = new MockAnimal();
  when(animal.speak("dog")).thenReturn("woof");
  final s = animal.speak();
  print("$s");
  verify(animal.speak("dog")).once();
}
```

Note that you can reset the call and verify tracking using `resetInteractions()`. However, there is no way to reset the `when()` calls. Create a new mock instead.

You can define different results based on the value of the parameter. Notice that the calls to `verify()` explicitly states the parameter value:

```dart
void main() {
  final animal = new MockAnimal();
  when(animal.speak("cat")).thenReturn("meow");
  when(animal.speak("dog")).thenReturn("woof");
  final s = animal.speak("cat"); // Prints: meow
  verify(animal.speak("cat")).once();
  verify(animal.speak("dog")).never();
}
```

#### Match any value for a parameter

Sometimes you don't care about the exact value of the parameter. That's when `anyString` is used, along with its siblings `anyInt`, `anyBool` and `anyObject`.

The value `anyString` is a matcher that matches any String value. For example, here's how to use `anyString` in a call to `when()`:

```dart
void main() {
  final animal = new MockAnimal();
  when(animal.speak(anyString)).thenReturn("meow");
  final s1 = animal.speak("cat");
  final s2 = animal.speak("dog");
  print("$s1 $s2"); // Prints: meow meow
  verify(animal.speak(anyString)).times(2);
}
```

You can also use `anyString` in `verify()` calls, even if the `when()` calls use exact values. For example:

```dart
void main() {
  final animal = new MockAnimal();
  when(animal.speak("cat")).thenReturn("meow");
  when(animal.speak("dog")).thenReturn("woof");
  var s
  s = animal.speak("cat");
  s = animal.speak("cat");
  s = animal.speak("dog");
  verify(animal.speak(anyString)).times(3);
}
```

You can use `anyString` as the parameter for calculated values:
```dart
  when(animal.speak(anyString)).thenInvoke((String s) => 'The $s speaks!');
```

In addition to `thenReturn()` and `thenInvoke()`, typed_mock supports `thenReturnList()` and `thenThrow()`. See the link at the end of this document for examples.

#### Mocking operator[] and operator[]=

The typed_mock package is able to track set and get access with operators `[]=` and `[]`, respectively. There's nothing special about these operators - they are just functions with non-alphanumeric names that takes two or one parameters. As with other functions, typed_mock tracks both the index and the value as needed. Note the syntax to verify that a particular array element was assigned a particular value. The act of assigning true is tracked separately from the act of assigning false. The syntax is straightforward.

```dart
import 'package:typed_mock/typed_mock.dart';

abstract class Tracker {
  operator [](int index);
  operator []=(int index, bool b);
}

class MockTracker extends TypedMock implements Tracker {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final tracker = new MockTracker();
  tracker[2] = true;
  when(tracker[3]).thenReturn(false);
  when(tracker[4]).thenReturn(true);
  bool x = tracker[3];
  bool y = tracker[4];
  print("$x $y");
  verify(tracker[1] = true).never();
  verify(tracker[2] = false).never();
  verify(tracker[2] = true).once();
  verify(tracker[3]).once();
  verify(tracker[4]).once();
  verify(tracker[5]).never();
}
```

#### Passing mocks as closures

Passing a mock as a function parameter may not behave as you expect because a hidden function is called in the mock to get the closure. The solution is to wrap the call in a separate closure. For example, the call to `verifyNoMoreInteractions()` fails because the reference to `dog.speak` caused a hidden function to be called in `MockDog`.

```dart
void doSomething(String myfunc()) {}

void main() {
  final dog = new MockDog();
  doSomething(dog.speak);
  verifyNoMoreInteractions(dog);
}
```

The solution is as follows:

```dart
void doSomething(String myfunc()) {}

void main() {
  final dog = new MockDog();
  doSomething(() => dog.speak());
  verifyNoMoreInteractions(dog);
}
```

## More Information

For additional examples, see the [unit tests](https://github.com/dart-lang/sdk/blob/master/pkg/typed_mock/test/typed_mock_test.dart).
