// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/error/codes.dart';

VerifySuperFormalParametersResult verifySuperFormalParameters({
  required ConstructorDeclaration constructor,
  DiagnosticReporter? diagnosticReporter,
  bool hasExplicitPositionalArguments = false,
}) {
  var result = VerifySuperFormalParametersResult();
  for (var parameter in constructor.parameters.parameters) {
    parameter = parameter.notDefault;
    if (parameter is SuperFormalParameterImpl) {
      var declaredFragment = parameter.declaredFragment!;
      if (parameter.isNamed) {
        var name = declaredFragment.name;
        if (name != null) {
          result.namedArgumentNames.add(name);
        }
      } else {
        result.positionalArgumentCount++;
        if (hasExplicitPositionalArguments) {
          diagnosticReporter?.atToken(
            parameter.name,
            CompileTimeErrorCode
                .positionalSuperFormalParameterWithPositionalArgument,
          );
        }
      }
    }
  }
  return result;
}

class VerifySuperFormalParametersResult {
  /// The count of positional arguments provided by the super-parameters.
  int positionalArgumentCount = 0;

  /// The names of named arguments provided by the super-parameters.
  List<String> namedArgumentNames = [];
}
