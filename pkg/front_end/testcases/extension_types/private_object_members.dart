// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the we don't complain about extension type members with the same name
// as private backend injected members on Object.

extension type E(int i) {
  int get _identityHashCode => 42;
  bool _instanceOf(instantiatorTypeArguments, functionTypeArguments, type) {
    return false;
  }

  bool _simpleInstanceOf(dynamic type) {
    return false;
  }

  bool _simpleInstanceOfTrue(dynamic type) {
    return false;
  }

  bool _simpleInstanceOfFalse(dynamic type) {
    return false;
  }
}
