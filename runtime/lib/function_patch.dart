// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Function {
  static _apply(List arguments, List names)
      native "Function_apply";

  /* patch */ static apply(Function function,
                           List positionalArguments,
                           [Map<Symbol, dynamic> namedArguments]) {
    int numPositionalArguments = 1 +  // Function is first implicit argument.
        (positionalArguments != null ? positionalArguments.length : 0);
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List(numArguments);
    arguments[0] = function;
    arguments.setRange(1, numPositionalArguments, positionalArguments);
    List names = new List(numNamedArguments);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _symbol_dev.Symbol.getName(name);
      });
    }
    return _apply(arguments, names);
  }
}
