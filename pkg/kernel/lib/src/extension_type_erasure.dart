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

/// Visitor that replaces all extension types with their representation types.
///
/// The visitor returns `null` if the type wasn't changed.
class _ExtensionTypeErasure extends ReplacementVisitor {
  const _ExtensionTypeErasure();

  @override
  DartType? visitExtensionType(ExtensionType node, Variance variance) {
    return node.extensionTypeErasure;
  }
}
