// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';

/// Return `true` if the [type] has an [InvalidType].
bool hasInvalidType(DartType type) {
  var visitor = _InvalidTypeVisitor();
  type.accept(visitor);
  return visitor.result;
}

/// A visitor to find if a type contains any [InvalidType]s.
///
/// To find the result, check [result] on this instance after visiting the tree.
///
/// The actual value returned by the visit methods is merely used so that
/// [RecursiveTypeVisitor] stops visiting the type once the first type parameter
/// type is found.
class _InvalidTypeVisitor extends RecursiveTypeVisitor {
  /// The result of whether any [InvalidType]s were found.
  bool result = false;

  @override
  bool visitDartType(DartType dartType) {
    if (dartType is InvalidType) {
      result = true;
      return false;
    }
    return true;
  }
}
