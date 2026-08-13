// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

class MyFinalizable implements Finalizable {
  int internalValue = 4;
}

void main() {
  final finalizable = MyFinalizable();
  {
    final finalizable2 = MyFinalizable();
    // Should generate: _reachabilityFence(finalizable2);
  }
  if (DateTime.now().millisecondsSinceEpoch == 42) {
    // Should generate: _reachabilityFence(finalizable1);
    return;
  } else {
    try {
      final finalizable3 = MyFinalizable();
      {
        // Should not generate anything.
      }
      // Should generate: _reachabilityFence(finalizable3);
    } on Exception {
      final finalizable4 = MyFinalizable();
      // Should generate: _reachabilityFence(finalizable4);
    } finally {
      final finalizable5 = MyFinalizable();
      // Should generate: _reachabilityFence(finalizable5);
    }
    try {
      final finalizable13 = MyFinalizable();
      try {
        final finalizable14 = MyFinalizable();
        if (DateTime.now().millisecondsSinceEpoch == 100) {
          // Caught in try.
          // Should generate: _reachabilityFence(finalizable14);
          throw Exception('foo');
        }
        if (DateTime.now().millisecondsSinceEpoch == 101) {
          // Not caught in try.
          // Should generate: _reachabilityFence(finalizable1);
          // Should generate: _reachabilityFence(finalizable13);
          // Should generate: _reachabilityFence(finalizable14);
          throw Error();
        }
      } on Exception catch (e) {
        print(e);
        // Caught in surrounding try.
        // Should generate: _reachabilityFence(finalizable13);
        rethrow;
      } finally {
        if (DateTime.now().millisecondsSinceEpoch == 1000) {
          // Caught in surrounding try.
          // Should generate: _reachabilityFence(finalizable13);
          throw Exception('bar');
        }
      }
      // Should generate: _reachabilityFence(finalizable13);
    } on Exception catch (e) {
      print(e);
    }
  }
  switch (DateTime.now().millisecondsSinceEpoch) {
    case 1:
    case 2:
      final finalizable6 = MyFinalizable();
      // Should generate: _reachabilityFence(finalizable1);
      // Should generate: _reachabilityFence(finalizable6);
      return;
    Foo:
    case 3:
      final finalizable7 = MyFinalizable();
      // Should generate: _reachabilityFence(finalizable7);
      break;
    Bar:
    case 4:
      final finalizable70 = MyFinalizable();
      switch (DateTime.now().millisecondsSinceEpoch) {
        case 5:
          final finalizable71 = MyFinalizable();
          if (DateTime.now().millisecondsSinceEpoch == 44) {
            // Should generate: _reachabilityFence(finalizable70);
            // Should generate: _reachabilityFence(finalizable71);
            continue Bar;
          }
          // Should generate: _reachabilityFence(finalizable71);
          break;
      }
      // Should generate: _reachabilityFence(finalizable70);
      continue Foo;
    default:
      final finalizable8 = MyFinalizable();
    // Should generate: _reachabilityFence(finalizable8);
  }
  labelI:
  labelI3:
  for (int i = 0; i < 10; i++) {
    final finalizable9 = MyFinalizable();
    labelJ:
    for (int j = 0; j < 10; j++) {
      final finalizable10 = MyFinalizable();
      if (DateTime.now().millisecondsSinceEpoch == 42) {
        // Should generate: _reachabilityFence(finalizable9);
        // Should generate: _reachabilityFence(finalizable10);
        break labelI3;
      }
      if (DateTime.now().millisecondsSinceEpoch == 1337) {
        // Should generate: _reachabilityFence(finalizable9);
        // Should generate: _reachabilityFence(finalizable10);
        break labelI;
      }
      if (DateTime.now().millisecondsSinceEpoch == 1) {
        // Should generate: _reachabilityFence(finalizable9);
        continue labelJ;
      }
      if (DateTime.now().millisecondsSinceEpoch == 3) {
        // Should generate: _reachabilityFence(finalizable9);
        // Should generate: _reachabilityFence(finalizable10);
        continue labelI;
      }
      // Should generate: _reachabilityFence(finalizable10);
    }
    // Should generate: _reachabilityFence(finalizable9);
  }
  label1:
  {
    final finalizable11 = MyFinalizable();
    label2:
    {
      final finalizable12 = MyFinalizable();
      if (DateTime.now().millisecondsSinceEpoch == 1) {
        // Should generate: _reachabilityFence(finalizable11);
        // Should generate: _reachabilityFence(finalizable12);
        break label1;
      }
      if (DateTime.now().millisecondsSinceEpoch == 3) {
        // Should generate: _reachabilityFence(finalizable12);
        break label2;
      }
      // Should generate: _reachabilityFence(finalizable12);
    }
    // Should generate: _reachabilityFence(finalizable11);
  }
  for (int i = 0; i < 10; i++) {
    final finalizable15 = MyFinalizable();
    // Should generate: _reachabilityFence(finalizable15);
  }
  int i = 0;
  while (i < 10) {
    final finalizable16 = MyFinalizable();
    i++;
    // Should generate: _reachabilityFence(finalizable16);
  }
  for (final finalizable17
      in Iterable<Finalizable>.generate(5, (int index) => MyFinalizable())) {
    // Should generate: _reachabilityFence(finalizable17);
  }
  i = 0;
  for (Finalizable finalizable18 = MyFinalizable(); i < 10; i++) {
    // Should generate: _reachabilityFence(finalizable18);
  }
  // Should generate: _reachabilityFence(finalizable1);
}

int doSomething(int a) => a;

void Function() createClosure() {
  final finalizable20 = MyFinalizable();
  return () {
    if (DateTime.now().millisecondsSinceEpoch == 42) {
      return;
      // Should generate: _reachabilityFence(finalizable20);
    }
    doSomething(finalizable20.internalValue);
    // Should generate: _reachabilityFence(finalizable20);
  };
  // Should generate: _reachabilityFence(finalizable20);
}

void Function() Function() Function() createNestedClosure() {
  final finalizable40 = MyFinalizable();
  return () {
    final finalizable41 = MyFinalizable();
    return () {
      final finalizable42 = MyFinalizable();
      return () {
        doSomething(finalizable40.internalValue);
        doSomething(finalizable41.internalValue);
        doSomething(finalizable42.internalValue);
        // Should generate: _reachabilityFence(finalizable40);
        // Should generate: _reachabilityFence(finalizable41);
        // Should generate: _reachabilityFence(finalizable42);
      };
      // Should generate: _reachabilityFence(finalizable40);
      // Should generate: _reachabilityFence(finalizable41);
      // Should generate: _reachabilityFence(finalizable42);
    };
    // Should generate: _reachabilityFence(finalizable40);
    // Should generate: _reachabilityFence(finalizable41);
  };
  // Should generate: _reachabilityFence(finalizable40);
}

void Function() createBadClosure() {
  final finalizable21 = MyFinalizable();
  final internalValue = finalizable21.internalValue;
  return () {
    doSomething(internalValue);
    // Should not generate: _reachabilityFence(finalizable21);
  };
  // Should generate: _reachabilityFence(finalizable21);
}

void reassignment() {
  var finalizable30 = MyFinalizable();
  doSomething(4);
  // Should generate: _reachabilityFence(finalizable30);
  finalizable30 = MyFinalizable();
}
