// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.argument_extraction_for_redirecting;

import '../ast.dart'
    show
        Program,
        Constructor,
        RedirectingInitializer,
        Library,
        LocalInitializer,
        VariableDeclaration,
        VariableGet,
        Expression,
        NamedExpression;
import '../core_types.dart' show CoreTypes;
import '../visitor.dart' show Transformer;

Program transformProgram(CoreTypes coreTypes, Program program) {
  new ArgumentExtractionForRedirecting().visitProgram(program);
  return program;
}

void transformLibraries(CoreTypes coreTypes, List<Library> libraries) {
  var transformer = new ArgumentExtractionForRedirecting();
  for (var library in libraries) {
    transformer.visitLibrary(library);
  }
}

class ArgumentExtractionForRedirecting extends Transformer {
  visitConstructor(Constructor node) {
    if (node.initializers.length == 1 &&
        node.initializers[0] is RedirectingInitializer) {
      int index = 0;
      RedirectingInitializer redirectingInitializer = node.initializers[0];
      List<Expression> positionalArguments =
          redirectingInitializer.arguments.positional;
      List<NamedExpression> namedArguments =
          redirectingInitializer.arguments.named;
      for (int i = 0; i < positionalArguments.length; i++) {
        Expression argument = positionalArguments[i];
        VariableDeclaration extractedArgument =
            new VariableDeclaration("extracted#$index", initializer: argument);
        LocalInitializer initializer = new LocalInitializer(extractedArgument)
          ..parent = node;
        node.initializers.insert(index++, initializer);
        positionalArguments[i] = new VariableGet(extractedArgument)
          ..parent = redirectingInitializer.arguments;
      }
      for (int i = 0; i < namedArguments.length; i++) {
        Expression argument = namedArguments[i].value;
        VariableDeclaration extractedArgument =
            new VariableDeclaration("extracted#$index", initializer: argument);
        LocalInitializer initializer = new LocalInitializer(extractedArgument)
          ..parent = node;
        node.initializers.insert(index++, initializer);
        namedArguments[i].value = new VariableGet(extractedArgument)
          ..parent = redirectingInitializer.arguments;
      }
    }
    return super.visitConstructor(node);
  }
}
