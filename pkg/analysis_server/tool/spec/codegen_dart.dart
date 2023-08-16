// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api.dart';

/// Visitor specialized for generating Dart code.
class DartCodegenVisitor extends HierarchicalApiVisitor {
  /// Type references in the spec that are named something else in Dart.
  static const Map<String, String> _typeRenames = {
    'long': 'int',
    'object': 'Object',
  };

  DartCodegenVisitor(super.api);

  /// Convert the given [TypeDecl] to a Dart type.
  String dartType(TypeDecl type) {
    if (type is TypeReference) {
      var typeName = type.typeName;
      var referencedDefinition = api.types[typeName];
      var typeRename = _typeRenames[typeName];
      if (typeRename != null) {
        return typeRename;
      }
      if (referencedDefinition == null) {
        return typeName;
      }
      var referencedType = referencedDefinition.type;
      if (referencedType is TypeObject || referencedType is TypeEnum) {
        return typeName;
      }
      return dartType(referencedType);
    } else if (type is TypeList) {
      return 'List<${dartType(type.itemType)}>';
    } else if (type is TypeMap) {
      return 'Map<${dartType(type.keyType)}, ${dartType(type.valueType)}>';
    } else if (type is TypeUnion) {
      return 'Object';
    } else {
      throw Exception("Can't convert to a dart type");
    }
  }

  /// Return the Dart type for [field], nullable if the field is optional.
  String fieldDartType(TypeObjectField field) {
    var typeStr = dartType(field.type);
    return field.optional ? '$typeStr?' : typeStr;
  }
}
