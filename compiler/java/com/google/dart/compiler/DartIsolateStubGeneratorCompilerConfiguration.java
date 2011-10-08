// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;

import java.io.FileNotFoundException;

public class DartIsolateStubGeneratorCompilerConfiguration extends DefaultCompilerConfiguration {

  public DartIsolateStubGeneratorCompilerConfiguration(CompilerOptions compilerOptions)
      throws FileNotFoundException {
    super(compilerOptions);
  }

  @Override
  public boolean shouldWarnOnNoSuchType() {
    return true;
  }
}
