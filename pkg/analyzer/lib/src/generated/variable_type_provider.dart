// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Provider of types for local variables and formal parameters.
abstract class LocalVariableTypeProvider {
  /// Returns the type accepted by a write to [element], accounting for its
  /// current promotion state.
  TypeImpl getWriteType(InternalVariableElement element);
}
