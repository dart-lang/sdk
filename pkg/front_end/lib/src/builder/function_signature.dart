// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

typedef ParameterInfo = ({DartType type, bool hasDeclaredInitializer});

abstract class FunctionSignature {
  FunctionType get functionType;
  List<ParameterInfo> get positionalParameters;
  Map<String, ParameterInfo> get namedParameters;
  List<TypeParameter> get typeParameters;
}

class FunctionNodeSignature implements FunctionSignature {
  final FunctionNode _function;

  FunctionNodeSignature(this._function);

  @override
  FunctionType get functionType =>
      _function.computeFunctionType(Nullability.nonNullable);

  @override
  List<TypeParameter> get typeParameters => _function.typeParameters;

  @override
  Map<String, ParameterInfo> get namedParameters {
    Map<String, ParameterInfo> map = {};
    for (VariableDeclaration formal in _function.namedParameters) {
      map[formal.name!] = (
        type: formal.type,
        hasDeclaredInitializer: formal.hasDeclaredInitializer,
      );
    }
    return map;
  }

  @override
  List<ParameterInfo> get positionalParameters {
    List<ParameterInfo> list = [];
    for (VariableDeclaration formal in _function.positionalParameters) {
      list.add((
        type: formal.type,
        hasDeclaredInitializer: formal.hasDeclaredInitializer,
      ));
    }
    return list;
  }
}
