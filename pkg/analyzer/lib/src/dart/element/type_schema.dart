// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// A type that is being inferred but is not currently known.
///
/// This type will only appear in a downward inference context for type
/// parameters that we do not know yet. Notationally it is written `?`, for
/// example `List<?>`. This is distinct from `List<dynamic>`. These types will
/// never appear in the final resolved AST.
class UnknownInferredType extends TypeImpl {
  static final UnknownInferredType instance = UnknownInferredType._();

  UnknownInferredType._() : super(UnknownInferredTypeElement.instance);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.star;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeUnknownInferredType();
  }

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    // In theory this should never happen, since we only need to do this
    // replacement when checking super-boundedness of explicitly-specified
    // types, or types produced by mixin inference or instantiate-to-bounds, and
    // the unknown type can't occur in any of those cases.
    assert(
        false, 'Attempted to check super-boundedness of a type including "?"');
    // But just in case it does, behave similar to `dynamic`.
    if (isCovariant) {
      return typeProvider.nullType;
    } else {
      return this;
    }
  }

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;

  /// Given a [type] T, return true if it does not have an unknown type `?`.
  static bool isKnown(DartType type) => !isUnknown(type);

  /// Given a [type] T, return true if it has an unknown type `?`.
  static bool isUnknown(DartType type) {
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }
    if (type is InterfaceTypeImpl) {
      return type.typeArguments.any(isUnknown);
    }
    if (type is FunctionType) {
      return isUnknown(type.returnType) ||
          type.parameters.any((p) => isUnknown(p.type));
    }
    return false;
  }
}

/// The synthetic element for [UnknownInferredType].
class UnknownInferredTypeElement extends ElementImpl
    implements TypeDefiningElement {
  static final UnknownInferredTypeElement instance =
      UnknownInferredTypeElement._();

  UnknownInferredTypeElement._() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  UnknownInferredType get type => UnknownInferredType.instance;

  @override
  T accept<T>(ElementVisitor visitor) => null;
}
