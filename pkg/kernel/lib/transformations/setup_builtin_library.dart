// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.setup_builtin_library;

import '../ast.dart';

// The DartVM has a special `dart:_builtin` library which exposes a
// `_getMainClosure()` method.  We need to change this method to return a
// closure of `main()`.
Program transformProgram(Program program,
    {String libraryUri: 'dart:_builtin'}) {
  Procedure mainMethod = program.mainMethod;

  Library builtinLibrary;
  for (Library library in program.libraries) {
    if (library.importUri.toString() == libraryUri) {
      builtinLibrary = library;
      break;
    }
  }

  if (builtinLibrary == null) {
    throw new Exception('Could not find "dart:_builtin" library');
  }

  FunctionNode getMainClosure;
  for (Procedure procedure in builtinLibrary.procedures) {
    if (procedure.name.name == '_getMainClosure') {
      getMainClosure = procedure.function;
      break;
    }
  }

  if (getMainClosure == null) {
    throw new Exception('Could not find "_getMainClosure" in "$libraryUri"');
  }

  if (mainMethod != null) {
    var returnMainStatement = new ReturnStatement(new StaticGet(mainMethod));
    getMainClosure.body = returnMainStatement;
    returnMainStatement.parent = getMainClosure;
  } else {
    // TODO(ahe): This should throw no such method error.
    getMainClosure.body = null;
  }

  return program;
}
