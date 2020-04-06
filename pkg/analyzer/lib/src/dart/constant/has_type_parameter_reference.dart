// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

/// Return `true` if the [type] has a type parameter reference.
bool hasTypeParameterReference(DartType type) {
  // TODO(scheglov) The implementation is incomplete, use visitor.
  if (type is TypeParameterType) {
    return true;
  }
  if (type is ParameterizedType) {
    return type.typeArguments.any(hasTypeParameterReference);
  }
  return false;
}
