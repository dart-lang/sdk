// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compile_time_constant_evaluator;

import 'common/tasks.dart' show CompilerTask, Measurer;
import 'elements/entities.dart';

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Register that [element] needs lazy initialization.
  void registerLazyStatic(FieldEntity element);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantEnvironment {
  ConstantCompilerTask(Measurer measurer) : super(measurer);
}
