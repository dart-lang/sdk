// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/node_builder.dart';

/// [TypeOperations] that works with [DecoratedType]s.
class DecoratedTypeOperations
    implements TypeOperations<VariableElement, DecoratedType> {
  final TypeSystem _typeSystem;
  final VariableRepository _variableRepository;

  DecoratedTypeOperations(this._typeSystem, this._variableRepository);

  @override
  bool isLocalVariable(VariableElement element) {
    return element is LocalVariableElement;
  }

  @override
  bool isSubtypeOf(DecoratedType leftType, DecoratedType rightType) {
    return _typeSystem.isSubtypeOf(leftType.type, rightType.type);
  }

  @override
  DecoratedType tryPromoteToNonNull(DecoratedType type) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  DecoratedType variableType(VariableElement variable) {
    return _variableRepository.decoratedElementType(variable);
  }
}
