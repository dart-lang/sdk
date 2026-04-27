// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';

import '../../../generated/type_system_base.dart';

mixin StringTypes on AbstractTypeSystemTest {
  final Map<String, TypeImpl> _types = {};

  void assertExpectedString(TypeImpl type, String? expectedString) {
    if (expectedString != null) {
      var typeStr = typeString(type);

      expect(typeStr, expectedString);
    }
  }

  void defineStringTypes() {
    _types.clear();
  }

  TypeImpl typeOfString(String str) {
    return _types.putIfAbsent(str, () {
      var type = parseType(str);

      var typeStr = typeString(type);
      if (typeStr != str) {
        fail('Expected: $str\nActual: $typeStr');
      }

      return type;
    });
  }

  String typesString(List<TypeImpl> types) {
    var str = types.map(typeString).join('\n');
    return '$str\n';
  }

  String typeString(TypeImpl type) {
    return type.getDisplayString() + _typeParametersStr(type);
  }

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    type.accept(typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      typeStr += ', $typeParameter';
    }
    return typeStr;
  }
}

class _TypeParameterCollector extends TypeVisitor<void> {
  final Set<String> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

  @override
  void visitDynamicType(DynamicType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeParameters);
    for (var typeParameter in type.typeParameters) {
      var bound = typeParameter.bound;
      if (bound != null) {
        bound.accept(this);
      }
    }
    for (var parameter in type.formalParameters) {
      parameter.type.accept(this);
    }
    type.returnType.accept(this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitInvalidType(InvalidType type) {}

  @override
  void visitNeverType(NeverType type) {}

  @override
  void visitRecordType(RecordType type) {
    var fields = [...type.positionalFields, ...type.namedFields];
    for (var field in fields) {
      field.type.accept(this);
    }
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      var bound = type.element.bound;

      if (bound == null) {
        return;
      }

      var str = '';

      var boundStr = bound.getDisplayString();
      str += '${type.element.name} extends $boundStr';

      typeParameters.add(str);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
