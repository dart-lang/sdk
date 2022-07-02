// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/replacement_visitor.dart';

/// Normalizes all `FutureOr` types found in [type].
DartType normalizeFutureOr(DartType type, CoreTypes coreTypes) =>
    type.accept1(_FutureOrNormalizer.instance(coreTypes), Variance.unrelated) ??
    type;

/// Visit methods returns a normalized version of `FutureOr` types or `null` if
/// no normalization was applied.
///
/// The `variance` parameters in the visit methods are unused in this type
/// replacement.
///
/// `FutureOr` types are normalized per the spec:
/// https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md
///
/// Any changes to the normalization logic here should be mirrored in the
/// classes.dart runtime library method named `normalizeFutureOr`.
class _FutureOrNormalizer extends ReplacementVisitor {
  final CoreTypes _coreTypes;

  static _FutureOrNormalizer? _instance;

  _FutureOrNormalizer._(this._coreTypes);

  factory _FutureOrNormalizer.instance(CoreTypes coreTypes) =>
      _instance ?? (_instance = _FutureOrNormalizer._(coreTypes));

  @override
  DartType? visitFutureOrType(FutureOrType futureOr, int variance) {
    var normalizedTypeArg = futureOr.typeArgument.accept1(this, variance);
    var typeArgument = normalizedTypeArg ?? futureOr.typeArgument;
    if (typeArgument is DynamicType) {
      // FutureOr<dynamic> --> dynamic
      return typeArgument;
    }
    if (typeArgument is VoidType) {
      // FutureOr<void> --> void
      return typeArgument;
    }

    if (typeArgument is InterfaceType &&
        typeArgument.classNode == _coreTypes.objectClass) {
      // Normalize FutureOr of Object, Object?, Object*.
      var nullable = futureOr.nullability == Nullability.nullable ||
          typeArgument.nullability == Nullability.nullable;
      var legacy = futureOr.nullability == Nullability.legacy ||
          typeArgument.nullability == Nullability.legacy;
      var nullability = nullable
          ? Nullability.nullable
          : legacy
              ? Nullability.legacy
              : Nullability.nonNullable;
      return typeArgument.withDeclaredNullability(nullability);
    } else if (typeArgument is NeverType) {
      // FutureOr<Never> --> Future<Never>
      return InterfaceType(
          _coreTypes.futureClass, futureOr.nullability, [typeArgument]);
    } else if (typeArgument is NullType) {
      // FutureOr<Null> --> Future<Null>?
      return InterfaceType(
          _coreTypes.futureClass, Nullability.nullable, [typeArgument]);
    } else if (futureOr.declaredNullability == Nullability.nullable &&
        typeArgument.nullability == Nullability.nullable) {
      // FutureOr<T?>? --> FutureOr<T?>
      return futureOr.withDeclaredNullability(Nullability.nonNullable);
    }
    // The following is not part of the normalization spec but this is a
    // convenient place to perform this change of nullability consistently. This
    // only applies at compile-time and is not needed in the runtime version of
    // the FutureOr normalization.
    // FutureOr<T%>% --> FutureOr<T%>
    //
    // If the type argument has undetermined nullability the CFE propagates
    // it to the FutureOr type as well. In this case we can represent the
    // FutureOr type without any nullability wrappers and rely on the runtime to
    // handle the nullability of the instantiated type appropriately.
    if (futureOr.declaredNullability == Nullability.undetermined &&
        typeArgument.declaredNullability == Nullability.undetermined) {
      return futureOr.withDeclaredNullability(Nullability.nonNullable);
    }
    return null;
  }
}
