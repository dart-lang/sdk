// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/nullability/constraint_variable_gatherer.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';

/// [TypeOperations] that works with [DecoratedType]s.
class DecoratedTypeOperations implements TypeOperations<DecoratedType> {
  final TypeSystem _typeSystem;
  final VariableRepository _variableRepository;

  DecoratedTypeOperations(this._typeSystem, this._variableRepository);

  @override
  DecoratedType elementType(VariableElement element) {
    return _variableRepository.decoratedElementType(element);
  }

  @override
  bool isSubtypeOf(DecoratedType leftType, DecoratedType rightType) {
    return _typeSystem.isSubtypeOf(leftType.type, rightType.type);
  }
}
