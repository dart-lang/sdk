// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Alternative compile method for dart2js commandline that stores the compiler
/// for later inspection.
///
/// Use this in testing to inspect the compiler after compilation by setting
/// the `compileFunc` variable in `package:compiler/implementation/dart2js.dart`
/// to [compiler] before calling the `internalMain` function.

library dart2js.alt;

import 'dart:async';
import 'package:compiler/compiler.dart';
import 'package:compiler/implementation/apiimpl.dart';

Compiler compiler;

Future<String> compile(Uri script,
                       Uri libraryRoot,
                       Uri packageRoot,
                       CompilerInputProvider inputProvider,
                       DiagnosticHandler handler,
                       [List<String> options = const [],
                        CompilerOutputProvider outputProvider,
                        Map<String, dynamic> environment = const {}]) {
  if (!libraryRoot.path.endsWith("/")) {
    throw new ArgumentError("libraryRoot must end with a /");
  }
  if (packageRoot != null && !packageRoot.path.endsWith("/")) {
    throw new ArgumentError("packageRoot must end with a /");
  }
  compiler = new Compiler(inputProvider,
                          outputProvider,
                          handler,
                          libraryRoot,
                          packageRoot,
                          options,
                          environment);
  return compiler.run(script).then((_) {
    String code = compiler.assembledCode;
    if (code != null && outputProvider != null) {
      code = ''; // Non-null signals success.
    }
    return code;
  });
}