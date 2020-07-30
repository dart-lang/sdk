// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:meta/meta.dart';

/// Visitor that computes replaces covariant uses of Top with Bottom, and
/// contravariant uses of Bottom with Top.
///
/// Each visitor method returns `null` if there are no `_`s contained in the
/// type, otherwise it returns the result of substituting `_` with [_bottomType]
/// or [_topType], as appropriate.
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
  DartType visitDynamicType(DynamicType type) =>
      _isCovariant ? _bottomType : type;

  @override
  DartType visitInterfaceType(InterfaceType type) {
    if (_typeSystem.isTop(type)) {
      return _isCovariant ? _bottomType : type;
    }
    if (_typeSystem.isBottom(type) ||
        (!_typeSystem.isNonNullableByDefault && type.isDartCoreNull)) {
      return _isCovariant ? type : _topType;
    }

    return super.visitInterfaceType(type);
  }

  @override
  DartType visitNeverType(NeverType type) =>
      _isCovariant && type.nullabilitySuffix != NullabilitySuffix.question
          ? type
          : _topType;

  @override
  DartType visitVoidType(VoidType type) => _isCovariant ? _bottomType : type;

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
