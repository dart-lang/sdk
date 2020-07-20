// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:meta/meta.dart';

/// The data related to a function for which one of the `Type` valued arguments
/// has been converted into a type argument.
class ConvertArgumentToTypeArgumentChange extends Change {
  /// The index of the argument that was transformed.
  final int argumentIndex;

  /// The index of the type argument into which the argument was transformed.
  final int typeArgumentIndex;

  /// Initialize a newly created transform to describe a conversion of the
  /// argument at the [argumentIndex] to the type parameter at the
  /// [typeArgumentIndex] for the function [element].
  ConvertArgumentToTypeArgumentChange(
      {@required this.argumentIndex, @required this.typeArgumentIndex})
      : assert(argumentIndex >= 0),
        assert(typeArgumentIndex >= 0);
}
