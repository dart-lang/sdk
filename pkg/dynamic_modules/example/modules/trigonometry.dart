// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines sin, cos, tan, and pi.
library;

import 'dart:math' as math;
import '../common/common.dart';

class SinOperation implements Operation {
  @override
  String get name => 'sin';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 1) {
      throw ArgumentError('Sin requires exactly 1 argument (in radians).');
    }
    return math.sin(arguments[0]);
  }
}

class CosOperation implements Operation {
  @override
  String get name => 'cos';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 1) {
      throw ArgumentError('Cos requires exactly 1 argument (in radians).');
    }
    return math.cos(arguments[0]);
  }
}

class TanOperation implements Operation {
  @override
  String get name => 'tan';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 1) {
      throw ArgumentError('Tan requires exactly 1 argument (in radians).');
    }
    return math.tan(arguments[0]);
  }
}

class PiOperation implements Operation {
  @override
  String get name => 'pi';

  @override
  num apply(List<num> arguments) {
    if (arguments.isNotEmpty) {
      throw ArgumentError('Constant "pi" does not accept arguments.');
    }
    return math.pi;
  }
}

/// The entrypoint of th edynamic module returns a `void Function(Registry)`
/// that, when invoke, registers all operations defined by this module.
@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return (Registry registry) {
    registry.addOperation(SinOperation());
    registry.addOperation(CosOperation());
    registry.addOperation(TanOperation());
    registry.addOperation(PiOperation());
  };
}
