// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const num three = 3;
dynamic dynamicFunction(dynamic d) => d;
Object? objectFunction(Object? o) => o;
int intFunction(int i) => i;
T idFunction<T>(T t) => t;

const int Function(int) idAsIntFunction = idFunction;

class Class<T> {
  final T field;

  const Class(dynamic value) : field = value as T;
}

class ClassWithBound<T extends num> {
  final T field;

  const ClassWithBound() : field = three as T;

  const ClassWithBound.withValue(dynamic value) : field = value as T;
}

class ClassWithList<T> {
  final List<T> field;

  const ClassWithList(dynamic value) : field = value as List<T>;
}

class ClassWithFunction<T> {
  final T Function(T) field;

  const ClassWithFunction(dynamic value) : field = value as T Function(T);
}

void main() {
  const Class(0); // ok
  const Class<num>(0); // ok
  const Class<int>(0); // ok
  const Class<String>(''); // ok
  const ClassWithBound<int>(); // ok
  const ClassWithBound<int>.withValue(0); // ok
  const ClassWithBound<int>.withValue(three); // ok
  const ClassWithBound<double>.withValue(0.5); // ok
  const ClassWithList([]); // ok
  const ClassWithList<num>(<int>[0]); // ok
  const ClassWithList<int>(<int>[0]); // ok
  const ClassWithList<String>(<String>['']); // ok
  const ClassWithFunction(dynamicFunction); // ok
  const ClassWithFunction<Object?>(dynamicFunction); // ok
  const ClassWithFunction(objectFunction); // ok
  const ClassWithFunction<void>(objectFunction); // ok
  const ClassWithFunction<int>(intFunction); // ok
  const ClassWithFunction<int>(idAsIntFunction); // ok
}

weakMode() {
  const ClassWithFunction<Object>(objectFunction); // ok in weak mode
}

errors() {
  const Class<num>(''); // error
  const Class<int>(0.5); // error
  const Class<String>(0); // error
  const ClassWithBound<double>(); // error
  const ClassWithBound<double>.withValue(0); // error
  const ClassWithBound<double>.withValue(three); // error
  const ClassWithBound<num>.withValue(''); // error
  const ClassWithList(0); // error
  const ClassWithList<num>(<String>['']); // error
  const ClassWithList<int>(<num>[0]); // error
  const ClassWithList<String>(<int>[0]); // error
  const ClassWithFunction(0); // error
  const ClassWithFunction(intFunction); // error
  const ClassWithFunction<Object>(intFunction); // error
  const ClassWithFunction<void>(intFunction); // error
  const ClassWithFunction<num>(intFunction); // error
  const ClassWithFunction<int>(idFunction); // error
}
