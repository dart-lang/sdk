// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class FunctionDefinitionMacro1 implements FunctionDefinitionMacro {
  const FunctionDefinitionMacro1();

  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) {
      builder.augment(new FunctionBodyCode.fromString('''{
  return 42;
}'''));
  }
}

macro class FunctionDefinitionMacro2 implements FunctionDefinitionMacro {
  const FunctionDefinitionMacro2();

  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) async {
    if (function.positionalParameters.isEmpty) {
      return;
    }
    StaticType returnType = await builder.resolve(function.returnType);
    StaticType parameterType =
        await builder.resolve(function.positionalParameters.first.type);
    builder.augment(new FunctionBodyCode.fromString('''{
  print('isExactly=${await returnType.isExactly(parameterType)}');
  print('isSubtype=${await returnType.isSubtypeOf(parameterType)}');
}'''));
  }
}
