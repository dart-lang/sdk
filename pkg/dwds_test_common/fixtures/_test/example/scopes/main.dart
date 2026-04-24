// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An example with more complicated scope.
library;

import 'dart:async';
import 'dart:collection';

final libraryPublicFinal = MyTestClass();

final _libraryPrivateFinal = 1;
Object? libraryNull;
var libraryPublic = <String>['library', 'public', 'variable'];
var notAList = NotReallyAList();

var _libraryPrivate = ['library', 'private', 'variable'];

var identityMap = <String, int>{};

var map = <Object, Object>{};

final stream = Stream.value(1);

MyTestClass getLibraryPublicFinal() => libraryPublicFinal;

List<String> getLibraryPublic() => libraryPublic;

Map<Object, Object> getMap() => map;

Map<String, int> getIdentityMap() => identityMap;

Stream<int> getStream() => stream;

void staticFunction(int formal) {
  print(formal); // Breakpoint: staticFunction
}

void staticAsyncFunction(String value) async {
  // ignore: unused_local_variable
  final myLocal = await 'a local value';
  print(value); // Breakpoint: staticAsyncFunction
}

void staticAsyncLoopFunction(String value) async {
  Function? f;
  for (var i in [1, 2, 3]) {
    print(i);
    final myLocal = await 'my local value';
    f ??= () {
      print(value);
      print(i);
      return myLocal; // Breakpoint: staticAsyncLoopFunction
    };
  }
  f!();
}

void main() async {
  print('Initial print from scopes app');
  final local = 'local in main';
  final intLocalInMain = 42;
  final testClass = MyTestClass();
  Object? localThatsNull;
  identityMap['a'] = 1;
  identityMap['b'] = 2;
  map['a'] = [1, 2, 3];
  map['b'] = 'something';
  notAList.add(7);

  String nestedFunction<T>(T parameter, Object aClass) {
    final another = int.tryParse('$parameter');
    return '$local: parameter, $another'; // Breakpoint: nestedFunction
  }

  dynamic nestedWithClosure(String banana) {
    return () => '$local + $banana';
  }

  Timer.periodic(const Duration(seconds: 1), (Timer t) {
    final ticks = t.tick;
    // ignore: unused_local_variable, prefer_typing_uninitialized_variables
    var closureLocal;
    libraryPublicFinal.printCount();
    staticFunction(1);
    staticAsyncFunction('arg1');
    staticAsyncLoopFunction('arg2');
    print('ticking... $ticks (the answer is $intLocalInMain)');
    print(nestedFunction('$ticks ${testClass.message}', Timer));
    print(localThatsNull);
    print(libraryNull);
    final localList = libraryPublic;
    print(localList);
    localList.add('abc');
    final f = testClass.methodWithVariables();
    print(f('parameter'));
    final num = '1234'.someExtensionMethod();
    print('$num');
  });

  print(_libraryPrivateFinal);
  print(_libraryPrivate);
  print(nestedFunction(_libraryPrivate.first, Object));
  print(nestedWithClosure(_libraryPrivate.first)());
}

String libraryFunction(String arg) {
  print('calling a library function with $arg');
  final concat = 'some constant plus $arg plus whatever';
  print(concat);
  return concat;
}

abstract class MyAbstractClass {
  String abstractField = 'abstract-field-value';
}

class MyTestClass<T> extends MyAbstractClass {
  final String message;

  String? notFinal;

  MyTestClass({this.message = 'world'}) {
    myselfField = this;
    tornOff = toString;
  }

  String hello() => message;

  String Function(String) methodWithVariables() {
    final local = '$message + something';
    print(local);
    return (String parameter) {
      // Be sure to use a field from this, so it isn't entirely optimized away.
      final closureLocalInsideMethod = '$message/$local/$parameter';
      print(closureLocalInsideMethod);
      return closureLocalInsideMethod; // Breakpoint: nestedClosure
    };
  }

  //ignore: avoid_returning_this
  MyTestClass get myselfGetter => this;

  late final MyTestClass myselfField;

  var count = 0;

  // An easy location to add a breakpoint.
  void printCount() {
    print('The count is ${++count}');
    libraryFunction('abc'); // Breakpoint: printMethod
  }

  final _privateField = 'a private field';

  // ignore: unused_element
  String privateMethod(String s) => '$s : $_privateField';

  @override
  String toString() => 'A test class with message $message';

  bool equals(Object other) {
    if (other is MyTestClass) return message == other.hello();
    return false;
  }

  Function closure = someFunction;

  late final String Function() tornOff;
}

Function? someFunction() => null;

// ignore: unused_element
int _libraryPrivateFunction(int a, int b) => a + b;

class NotReallyAList extends ListBase<Object?> {
  final List<Object?> _internal;

  NotReallyAList() : _internal = [];

  @override
  Object? operator [](x) => _internal[x];

  @override
  operator []=(int x, Object? y) => _internal[x] = y;

  @override
  int get length => _internal.length;

  @override
  set length(x) => _internal.length = x;
}

extension NumberParsing on String {
  int someExtensionMethod() {
    final ret = int.parse(this);
    return ret; // Breakpoint: extension
  }
}
