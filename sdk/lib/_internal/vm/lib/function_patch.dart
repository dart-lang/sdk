// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class Function {
  // TODO(regis): Pass type arguments to generic functions. Wait for API spec.
  static _apply(List<dynamic>? arguments, List<dynamic>? names)
      native "Function_apply";

  @patch
  static apply(Function function, List<dynamic>? positionalArguments,
      [Map<Symbol, dynamic>? namedArguments]) {
    int numPositionalArguments = 1 + // Function is first implicit argument.
        (positionalArguments != null ? positionalArguments.length : 0);
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List<dynamic>.filled(numArguments, null);
    arguments[0] = function;
    if (positionalArguments != null) {
      arguments.setRange(1, numPositionalArguments, positionalArguments);
    }
    List names = new List<dynamic>.filled(numNamedArguments, null);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments?.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = internal.Symbol.getName(name as internal.Symbol);
      });
    }
    return _apply(arguments, names);
  }
}
