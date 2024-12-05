// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';

import 'instrumenter.dart';

class SubtypeInstrumenterConfig implements InstrumenterConfig {
  const SubtypeInstrumenterConfig();

  @override
  String get afterName => 'after';

  @override
  String get beforeName => 'before';

  @override
  Arguments createAfterArguments(
      List<Procedure> procedures, List<Constructor> constructors) {
    return new Arguments([]);
  }

  @override
  Arguments createBeforeArguments(
      List<Procedure> procedures, List<Constructor> constructors) {
    return new Arguments([]);
  }

  @override
  Arguments createEnterArguments(int id, Member member) {
    FunctionNode function = member.function!;
    return new Arguments([
      new ThisExpression(),
      ...function.positionalParameters
          .map<Expression>((e) => new VariableGet(e))
    ]);
  }

  @override
  Arguments createExitArguments(int id, Member member) {
    return new Arguments([]);
  }

  @override
  String get enterName => 'enter';

  @override
  String get exitName => 'exit';

  @override
  bool includeConstructor(Constructor constructor) {
    return false;
  }

  @override
  bool includeProcedure(Procedure procedure) {
    if (procedure.name.text == 'performNullabilityAwareSubtypeCheck') {
      Library library = procedure.enclosingLibrary;
      Class? cls = procedure.enclosingClass;
      if (cls?.name == 'Types' &&
          library.importUri.isScheme('package') &&
          library.importUri.path == 'kernel/src/types.dart') {
        return true;
      }
    }
    return false;
  }

  @override
  String get libFilename => 'subtype_lib.dart';
}

Future<void> main(List<String> arguments) async {
  Directory tmpDir = Directory.systemTemp.createTempSync("subtype_measure");
  try {
    Uri output = parseCompilerArguments(arguments);
    await compileInstrumentationLibrary(
        tmpDir, const SubtypeInstrumenterConfig(), arguments, output);
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
