// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.argument_extraction;

import '../ast.dart'
    show
        Constructor,
        FieldInitializer,
        Initializer,
        Library,
        LocalInitializer,
        Program,
        VariableDeclaration,
        VariableGet;
import '../core_types.dart' show CoreTypes;
import '../visitor.dart' show Transformer;

Program transformProgram(CoreTypes coreTypes, Program program) {
  new ArgumentExtractionForTesting().visitProgram(program);
  return program;
}

void transformLibraries(CoreTypes coreTypes, List<Library> libraries) {
  var transformer = new ArgumentExtractionForTesting();
  for (var library in libraries) {
    transformer.visitLibrary(library);
  }
}

class ArgumentExtractionForTesting extends Transformer {
  visitConstructor(Constructor node) {
    var newInits = <Initializer>[];

    int nameCounter = 0;
    for (var fieldInit in node.initializers) {
      if (fieldInit is FieldInitializer &&
          !fieldInit.field.name.name.endsWith("_li")) {
        // Move the body of the initializer to a new local initializer, and
        // eta-expand the reference to the local initializer in the body of the
        // field initializer.
        var value = fieldInit.value;

        var decl = new VariableDeclaration('#li_$nameCounter');
        decl.initializer = value;
        var localInit = new LocalInitializer(decl);
        localInit.parent = node;
        newInits.add(localInit);

        fieldInit.value = new VariableGet(decl);
        fieldInit.value.parent = fieldInit;

        ++nameCounter;
        newInits.add(fieldInit);
      } else {
        newInits.add(fieldInit);
      }
    }

    node.initializers = newInits;
    return super.visitConstructor(node);
  }
}
