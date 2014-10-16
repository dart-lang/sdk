// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library codegen.dart;

import 'api.dart';

/**
 * Visitor specialized for generating Dart code.
 */
class DartCodegenVisitor extends HierarchicalApiVisitor {
  /**
   * Type references in the spec that are named something else in Dart.
   */
  static const Map<String, String> _typeRenames = const {
    'long': 'int',
    'object': 'Map',
  };

  DartCodegenVisitor(Api api) : super(api);

  /**
   * Convert the given [TypeDecl] to a Dart type.
   */
  String dartType(TypeDecl type) {
    if (type is TypeReference) {
      String typeName = type.typeName;
      TypeDefinition referencedDefinition = api.types[typeName];
      if (_typeRenames.containsKey(typeName)) {
        return _typeRenames[typeName];
      }
      if (referencedDefinition == null) {
        return typeName;
      }
      TypeDecl referencedType = referencedDefinition.type;
      if (referencedType is TypeObject || referencedType is TypeEnum) {
        return typeName;
      }
      return dartType(referencedType);
    } else if (type is TypeList) {
      return 'List<${dartType(type.itemType)}>';
    } else if (type is TypeMap) {
      return 'Map<${dartType(type.keyType)}, ${dartType(type.valueType)}>';
    } else if (type is TypeUnion) {
      return 'dynamic';
    } else {
      throw new Exception("Can't convert to a dart type");
    }
  }
}