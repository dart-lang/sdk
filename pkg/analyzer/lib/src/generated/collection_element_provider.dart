// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Abstraction layer allowing the mechanism for looking up the elements of
/// collections to be customized.
///
/// This is needed for the NNBD migration engine, which needs to be able to
/// re-run resolution on code for which certain collection elements have been
/// removed or changed due to dead code elimination..
///
/// This base class implementation gets elements directly from the collections;
/// for other behaviors, create a class that extends or implements this class.
class CollectionElementProvider {
  const CollectionElementProvider();

  /// Gets the elements contained in a [ListLiteral].
  List<CollectionElement> getListElements(ListLiteral node) => node.elements;

  /// Gets the explicit type arguments of a [ListLiteral], or `null` if there
  /// are no explicit type arguments.
  List<TypeAnnotation> getListTypeArguments(ListLiteral node) =>
      node.typeArguments?.arguments;

  /// Gets the elements contained in a [SetOrMapLiteral].
  List<CollectionElement> getSetOrMapElements(SetOrMapLiteral node) =>
      node.elements;

  /// Gets the explicit type arguments of a [SetOrMapLiteral], or `null` if
  /// there are no explicit type arguments.
  List<TypeAnnotation> getSetOrMapTypeArguments(SetOrMapLiteral node) =>
      node.typeArguments?.arguments;
}
