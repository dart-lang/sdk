// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
// TODO: https://github.com/dart-lang/webdev/issues/2508
// ignore: deprecated_member_use
import 'dart:html';

import 'package:_test_package/test_library.dart';
import 'package:_test/deferred_library.dart' deferred as d;
import 'package:_test/library.dart';

extension NumberParsing on String {
  int parseInt() {
    final ret = int.parse(this);
    return ret; // Breakpoint: extension
  }
}

void main() async {
  var count = 0;
  // For setting breakpoints.
  Timer.periodic(const Duration(seconds: 1), (_) {
    print('Count is: ${++count}');
    print(testLibraryValue);
    print(testPartLibraryValue);
  });

  // for evaluation
  var extensionId = 0;
  Timer.periodic(const Duration(seconds: 1), (_) async {
    await asyncMethod();
    printLocal();
    printFieldFromLibraryClass(); // Breakpoint: callPrintFieldFromLibraryClass
    printFieldFromLibraryPartClass();
    printFieldMain();
    printGlobal();
    printFromTestLibrary();
    printFromTestLibraryPart();
    printFromTestPackage();
    printCallExtension();
    printLoopVariable();
    printGeneric<int>(0);
    printObjectMultiLine(); // Breakpoint: callPrintObjectMultiLine
    printNestedObjectsMultiLine(); // Breakpoint: callPrintEnclosingFunctionMultiLine
    printStream(); // Breakpoint: callPrintStream
    printList();
    printMap();
    printSet();
    printFrame2();
    printLargeScope();
    // For testing evaluation in async JS frames.
    registerUserExtension(extensionId++);
  });

  document.body?.appendText(concatenate('Program', ' is running!'));
}

void registerUserExtension(int id) async {
  registerExtension('ext.extension$id', (_, __) async {
    print('Hello World from extension$id');
    return ServiceExtensionResponse.result(json.encode({'success': true}));
  });
}

Future<int> asyncMethod() async {
  printLocal();
  return 0;
}

void printGeneric<T>(T formal) {
  print(formal);
}

void printLocal() {
  final local = 42;
  print('Local is: $local'); // Breakpoint: printLocal
}

void printFieldFromLibraryClass() {
  final instance = TestLibraryClass(1, 2); // Breakpoint: createLibraryObject
  print('$instance'); // Breakpoint: printFieldFromLibraryClass
}

void printFieldFromLibraryPartClass() {
  final instance = TestLibraryPartClass(1, 2);
  print('$instance'); // Breakpoint: printFieldFromLibraryPartClass
}

void printFieldMain() {
  final instance = MainClass(2, 1);
  print('$instance'); // Breakpoint: printFieldMain
}

void printGlobal() {
  print(testLibraryValue); // Breakpoint: printGlobal
}

void printFromTestPackage() {
  print(concatenate('Hello', ' World'));
}

void printFromTestLibrary() {
  final local = 23;
  print(testLibraryFunction(local));
}

void printFromTestLibraryPart() {
  final local = 23;
  print(testLibraryPartFunction(local));
}

void printCallExtension() {
  final local = '23';
  print(local.parseInt());
}

void printLoopVariable() {
  final list = <String>['1'];
  for (var item in list) {
    print(item); // Breakpoint: printLoopVariable
  }
}

Future<void> printDeferred() async {
  d.deferredPrintLocal();
}

void printNestedObjectsMultiLine() {
  // dart format off
  printEnclosingObject( // Breakpoint: printEnclosingFunctionMultiLine
    EnclosingClass( // Breakpoint: printEnclosingObjectMultiLine
      EnclosedClass(0), // Breakpoint: printNestedObjectMultiLine
    ),
  );
  // dart format on
}

void printObjectMultiLine() {
  // dart format off
  print( // Breakpoint: printMultiLine
    // Breakpoint: Do not remove, will break callstack tests!
    createObject() // Breakpoint: printObjectMultiLine
      ..initialize(),
  );
  // dart format on
}

void printEnclosingObject(EnclosingClass o) {
  print(o); // Breakpoint: printEnclosingObject
}

void printStream() {
  final controller = StreamController<int>();
  final stream = controller.stream.asBroadcastStream();
  final subscription = stream.listen(print);
  controller.sink.add(0);
  subscription.cancel(); // Breakpoint: printStream
}

void printList() {
  final list = [0, 1, 2];
  print(list); // Breakpoint: printList
}

void printMap() {
  final map = {'a': 1, 'b': 2, 'c': 3};
  print(map); // Breakpoint: printMap
}

void printSet() {
  final mySet = {1, 4, 5, 7};
  print(mySet); // Breakpoint: printSet
}

ClassWithMethod createObject() {
  return ClassWithMethod(0); // Breakpoint: createObjectWithMethod
}

void printFrame2() {
  final local2 = 2;
  print(local2);
  printFrame1();
}

void printFrame1() {
  final local1 = 1;
  print(local1); // Breakpoint: printFrame1
}

void printLargeScope() {
  final t0 = 0;
  final t1 = 1;
  final t2 = 2;
  final t3 = 3;
  final t4 = 4;
  final t5 = 5;
  final t6 = 6;
  final t7 = 7;
  final t8 = 8;
  final t9 = 9;
  final t10 = 10;
  final t11 = 11;
  final t12 = 12;
  final t13 = 13;
  final t14 = 14;
  final t15 = 15;
  final t16 = 16;
  final t17 = 17;
  final t18 = 18;
  final t19 = 19;

  // dart format off
  print('$t0 $t1, $t2, $t3, $t4, $t5, $t6, $t7, $t8, $t9, $t10, '
    '$t11, $t12, $t13, $t14, $t15, $t16, $t17, $t18, $t19'); // Breakpoint: printLargeScope
  // dart format on
}

class MainClass {
  final int field;
  final int _field;
  MainClass(this.field, this._field); // Breakpoint: newMainClass

  @override
  String toString() => '$field, $_field'; // Breakpoint: toStringMainClass
}

class EnclosedClass {
  final int _field;
  EnclosedClass(this._field); // Breakpoint: newEnclosedClass

  @override
  String toString() => '$_field';
}

class ClassWithMethod {
  final int _field;
  ClassWithMethod(this._field);

  void initialize() {}

  @override
  String toString() => '$_field';
}

class EnclosingClass {
  final EnclosedClass _field;
  EnclosingClass(this._field); // Breakpoint: newEnclosingClass

  @override
  String toString() => '$_field';
}
