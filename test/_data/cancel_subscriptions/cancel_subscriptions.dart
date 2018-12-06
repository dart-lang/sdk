// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {
  StreamSubscription _subscriptionA; // LINT
  void init(Stream stream) {
    _subscriptionA = stream.listen((_) {});
  }
}

class B {
  StreamSubscription _subscriptionB; // OK
  void init(Stream stream) {
    _subscriptionB = stream.listen((_) {});
  }

  void dispose(filename) {
    _subscriptionB.cancel();
  }
}

void someFunction() {
  StreamSubscription _subscriptionF; // LINT
}

void someFunctionOK() {
  StreamSubscription _subscriptionB; // OK
  _subscriptionB.cancel();
}

class C {
  StreamSubscription _subscriptionC; // OK
  void init(Stream stream) {
    _subscriptionC = stream.listen((_) {});
  }
}

class C_What {
  C c = new C();

  C_What() {
    c._subscriptionC.cancel();
  }
}