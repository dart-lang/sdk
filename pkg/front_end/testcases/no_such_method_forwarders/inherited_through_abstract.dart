// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  noSuchMethod(_) => null;
  method1(); // noSuchMethod forwarder created for this.
  method2(int i); // noSuchMethod forwarder created for this.
  method3(int i); // noSuchMethod forwarder created for this.
  method4(int i) {}
}

abstract class Abstract extends Super {
  method2(num i); // No noSuchMethod forwarder will be inserted here.
}

class Class extends Abstract {
  method1(); // noSuchMethod forwarder from Super is valid.
  /* method2(num i) */ // A new noSuchMethod forwarder is created.
  method3(num i); // A new noSuchMethod forwarder is created.
  // No noSuchMethod forwarder will be inserted and this will be an error.
  method4(num i);
}
