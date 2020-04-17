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
  final bool field;

  const Class(dynamic value) : field = value is T;
}

class ClassWithBound<T extends num> {
  final bool field;

  const ClassWithBound() : field = three is T;

  const ClassWithBound.withValue(dynamic value) : field = value is T;
}

class ClassWithList<T> {
  final bool field;

  const ClassWithList(dynamic value) : field = value is List<T>;
}

class ClassWithFunction<T> {
  final bool field;

  const ClassWithFunction(dynamic value) : field = value is T Function(T);
}

void main() {
  const Class(0);
  const Class<num>(0);
  const Class<int>(0);
  const Class<String>('');
  const ClassWithBound<int>();
  const ClassWithBound<int>.withValue(0);
  const ClassWithBound<int>.withValue(three);
  const ClassWithBound<double>.withValue(0.5);
  const ClassWithList([]);
  const ClassWithList<num>(<int>[0]);
  const ClassWithList<int>(<int>[0]);
  const ClassWithList<String>(<String>['']);
  const ClassWithFunction(dynamicFunction);
  const ClassWithFunction<Object?>(dynamicFunction);
  const ClassWithFunction(objectFunction);
  const ClassWithFunction<void>(objectFunction);
  const ClassWithFunction<int>(intFunction);
  const ClassWithFunction<int>(idAsIntFunction);
  const ClassWithFunction<Object>(objectFunction);
  const Class<num>('');
  const Class<int>(0.5);
  const Class<String>(0);
  const ClassWithBound<double>();
  const ClassWithBound<double>.withValue(0);
  const ClassWithBound<double>.withValue(three);
  const ClassWithBound<num>.withValue('');
  const ClassWithList(0);
  const ClassWithList<num>(<String>['']);
  const ClassWithList<int>(<num>[0]);
  const ClassWithList<String>(<int>[0]);
  const ClassWithFunction(0);
  const ClassWithFunction(intFunction);
  const ClassWithFunction<Object>(intFunction);
  const ClassWithFunction<void>(intFunction);
  const ClassWithFunction<num>(intFunction);
  const ClassWithFunction<int>(idFunction);
}
