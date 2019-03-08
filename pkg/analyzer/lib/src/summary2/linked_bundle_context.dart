// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// The context of a linked bundle, with shared references.
class LinkedBundleContext {
  final List<Reference> references;

  LinkedBundleContext(this.references);

  InterfaceType getInterfaceType(LinkedNodeType linkedType) {
    if (linkedType.kind == LinkedNodeTypeKind.interface) {
      var element = references[linkedType.interfaceClass].element;
      // TODO(scheglov) type arguments
      assert(linkedType.interfaceTypeArguments.isEmpty);
      return InterfaceTypeImpl.explicit(element, []);
    }
    return null;
  }
}
