// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines basic operations like substraction, multiplication, division.
library;

import '../common/common.dart';

class SubtractionOperation implements Operation {
  @override
  String get name => '-';

  @override
  num apply(List<num> arguments) {
    if (arguments.isEmpty) return 0;
    return arguments.reduce((value, element) => value - element);
  }
}

class MultiplicationOperation implements Operation {
  @override
  String get name => '*';

  @override
  num apply(List<num> arguments) {
    if (arguments.isEmpty) return 1;
    return arguments.reduce((value, element) => value * element);
  }
}

class DivisionOperation implements Operation {
  @override
  String get name => '/';

  @override
  num apply(List<num> arguments) {
    if (arguments.isEmpty) {
      throw ArgumentError('Division requires at least one argument.');
    }
    return arguments.reduce((value, element) => value / element);
  }
}

/// The entrypoint of th edynamic module returns a `void Function(Registry)`
/// that, when invoke, registers all operations defined by this module.
@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return (Registry registry) {
    registry.addOperation(SubtractionOperation());
    registry.addOperation(MultiplicationOperation());
    registry.addOperation(DivisionOperation());
  };
}
