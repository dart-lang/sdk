// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;

public class ASTWriterFactory {
  public static BaseASTWriter create(CompilerConfiguration config) {
    String astFormat = config.getCompilerOptions().dumpAST();
    CompilerOptions compilerOptions = config.getCompilerOptions();
    String outDir = compilerOptions.getWorkDirectory().getAbsolutePath();
    if ("console".equals(astFormat)) {
      return new ConsoleWriter(outDir);
    } else if ("text".equals(astFormat)) {
      return new TextWriter(outDir);
    } else if ("dot".equals(astFormat)) {
      return new DotWriter(outDir);
    }
    return null;
  }
}
