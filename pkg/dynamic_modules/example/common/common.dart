// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines an operation of the calculator.
///
/// Dynamic modules can define their own implementation of an operation to
/// extend the calculator functionality.
abstract interface class Operation {
  String get name;
  num apply(List<num> arguments);
}

/// Defines a centralized registry of calculator operations.
///
/// This is used by the host app to collect all known operations, but also
/// used as an API to allow dynamic modules to register their own operations.
abstract interface class Registry {
  void addOperation(Operation op);
}
