// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines ^, log, ln, e, sqrt, exp operations.
library;

import 'dart:math' as math;
import '../common/common.dart';

class ExponentOperation implements Operation {
  @override
  String get name => '^';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 2) {
      throw ArgumentError(
        'Exponentiation requires exactly 2 arguments (base, exponent).',
      );
    }
    final base = arguments[0];
    final exponent = arguments[1];
    return math.pow(base, exponent);
  }
}

class SqrtOperation implements Operation {
  @override
  String get name => 'sqrt';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 1) {
      throw ArgumentError('Square root requires exactly 1 argument.');
    }
    return math.sqrt(arguments[0]);
  }
}

class LogOperation implements Operation {
  @override
  String get name => 'log';

  @override
  num apply(List<num> arguments) {
    if (arguments.length == 1) {
      return math.log(arguments[0]);
    } else if (arguments.length == 2) {
      return math.log(arguments[0]) / math.log(arguments[1]);
    } else {
      throw ArgumentError('Logarithm requires 1 or 2 arguments.');
    }
  }
}

class LnOperation implements Operation {
  @override
  String get name => 'ln';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 1) {
      throw ArgumentError('Natural logarithm requires exactly 1 argument.');
    }
    return math.log(arguments[0]);
  }
}

class ExpNotationOperation implements Operation {
  @override
  String get name => 'EXP';

  @override
  num apply(List<num> arguments) {
    if (arguments.length != 2) {
      throw ArgumentError(
        'EXP requires exactly 2 arguments (mantissa, exponent).',
      );
    }
    return arguments[0] * math.pow(10, arguments[1]);
  }
}

class EOperation implements Operation {
  @override
  String get name => 'e';

  @override
  num apply(List<num> arguments) {
    if (arguments.isNotEmpty) {
      throw ArgumentError('Constant "e" does not accept arguments.');
    }
    return math.e;
  }
}

/// The entrypoint of th edynamic module returns a `void Function(Registry)`
/// that, when invoke, registers all operations defined by this module.
@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return (Registry registry) {
    registry.addOperation(ExponentOperation());
    registry.addOperation(SqrtOperation());
    registry.addOperation(LogOperation());
    registry.addOperation(LnOperation());
    registry.addOperation(ExpNotationOperation());
    registry.addOperation(EOperation());
  };
}
