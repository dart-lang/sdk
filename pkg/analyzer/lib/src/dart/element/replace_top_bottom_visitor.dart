// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:meta/meta.dart';

/// Replace every "top" type in a covariant position with [_bottomType].
/// Replace every "bottom" type in a contravariant position with [_topType].
class ReplaceTopBottomVisitor extends ReplacementVisitor {
  final DartType _topType;
  final DartType _bottomType;
  final TypeSystemImpl _typeSystem;

  bool _isCovariant;

  ReplaceTopBottomVisitor._(
    this._typeSystem,
    this._topType,
    this._bottomType,
    this._isCovariant,
  );

  @override
  void changeVariance() {
    _isCovariant = !_isCovariant;
  }

  @override
  DartType visitDynamicType(DynamicType type) {
    return _isCovariant ? _bottomType : null;
  }

  @override
  DartType visitInterfaceType(InterfaceType type) {
    if (_isCovariant) {
      if (_typeSystem.isTop(type)) {
        return _bottomType;
      }
    } else {
      if (!_typeSystem.isNonNullableByDefault && type.isDartCoreNull) {
        return _topType;
      }
    }

    return super.visitInterfaceType(type);
  }

  @override
  DartType visitNeverType(NeverType type) {
    return _isCovariant ? null : _topType;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType type) {
    if (!_isCovariant && _typeSystem.isNonNullableByDefault) {
      if (_typeSystem.isSubtypeOf2(type, NeverTypeImpl.instance)) {
        return _typeSystem.objectQuestion;
      }
    }
    return null;
  }

  @override
  DartType visitVoidType(VoidType type) {
    return _isCovariant ? _bottomType : null;
  }

  /// Runs an instance of the visitor on the given [type] and returns the
  /// resulting type.  If the type contains no instances of Top or Bottom, the
  /// original type object is returned to avoid unnecessary allocation.
  static DartType run({
    @required DartType topType,
    @required DartType bottomType,
    @required TypeSystemImpl typeSystem,
    @required DartType type,
  }) {
    var visitor = ReplaceTopBottomVisitor._(
      typeSystem,
      topType,
      bottomType,
      true,
    );
    var result = type.accept(visitor);
    assert(visitor._isCovariant == true);
    return result ?? type;
  }
}
