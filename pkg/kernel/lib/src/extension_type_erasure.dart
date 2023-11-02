// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import 'replacement_visitor.dart';

/// Computes the extension type erasure of [type], that is, the type in which
/// all extension types have been replaced with their representation type.
DartType computeExtensionTypeErasure(DartType type) {
  return rawExtensionTypeErasure(type) ?? type;
}

/// Returns the extension type erasure of [type], that is, the type in which
/// all extension types have been replaced with their representation type.
///
/// Returns `null` if the type wasn't changed.
DartType? rawExtensionTypeErasure(DartType type) {
  return type.accept1(const _ExtensionTypeErasure(), Variance.covariant);
}

/// Returns the extension type erasure of [supertype], that is, the type in
/// which all extension types have been replaced with their representation type.
Supertype extensionSupertypeErasure(Supertype supertype) {
  if (supertype.typeArguments.isEmpty) {
    return supertype;
  }
  List<DartType>? newTypeArguments;
  for (int i = 0; i < supertype.typeArguments.length; i++) {
    DartType typeArgument = supertype.typeArguments[i];
    DartType? newTypeArgument =
        typeArgument.accept1(const _ExtensionTypeErasure(), Variance.covariant);
    if (newTypeArgument != null) {
      newTypeArguments ??= supertype.typeArguments.toList(growable: false);
      newTypeArguments[i] = newTypeArgument;
    }
  }
  if (newTypeArguments != null) {
    return new Supertype(supertype.classNode, newTypeArguments);
  }
  return supertype;
}

/// Visitor that replaces all extension types with their representation types.
///
/// The visitor returns `null` if the type wasn't changed.
class _ExtensionTypeErasure extends ReplacementVisitor {
  const _ExtensionTypeErasure();

  @override
  DartType? visitExtensionType(ExtensionType node, int variance) {
    return node.extensionTypeErasure;
  }
}
