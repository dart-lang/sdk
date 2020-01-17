// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N no_runtimeType_toString`

var o;

class A {
  var field;
  String f() {
    final s1 = '$runtimeType'; // LINT
    final s2 = runtimeType.toString(); // LINT
    final s3 = this.runtimeType.toString(); // LINT
    final s4 = '${runtimeType}'; // LINT
    final s5 = '${o.runtimeType}'; // OK
    final s6 = o.runtimeType.toString(); // OK
    final s7 = runtimeType == runtimeType; // OK
    final s8 = field?.runtimeType?.toString(); // OK
    try {
      final s9 = '${runtimeType}'; // LINT
    } catch (e) {
      final s10 = '${runtimeType}'; // OK
    }
    final s11 = super.runtimeType.toString(); // LINT
    throw '${runtimeType}'; // OK
  }
}

abstract class B {
  void f() {
    final s1 = '$runtimeType'; // OK
  }
}

mixin C {
  void f() {
    final s1 = '$runtimeType'; // OK
  }
}

class D {
  void f() {
    var runtimeType = 'C';
    print('$runtimeType'); // OK
  }
}

extension on A {
  String f() => '$runtimeType'; // LINT
}
extension on B {
  String f() => '$runtimeType'; // OK
}
