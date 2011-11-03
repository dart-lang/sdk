// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;


import com.google.dart.CompileError;
import com.google.dart.CompileResult;
import com.google.dart.CompileService;
import com.google.dart.fling.Environment.Status;

import org.deftserver.io.IOLoop;

import java.io.File;

public class Fling {
  static void emitErrorsAndWarnings(CompileResult result) {
    for (CompileError error : result.getErrors()) {
      System.err.println("ERROR: " + error);
    }
    for (CompileError warning : result.getWarnings()) {
      System.err.println("WARNING: " + warning);
    }
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("You're doing it wrong.");
      System.exit(1);
    }

    // TODO(knorton): For now we only build artifacts for the corelib but
    // it would be faster to do so for DOM and fling as well.
    final CompileService compileService = CompileService.create();

    final File file = new File(args[0]);
    CompileResult result = compileService.build(file);
    emitErrorsAndWarnings(result);
    if (!result.didBuild()) {
      System.exit(1);
    }

    while (true) {
      final Environment env = Environment.create(compileService);
      if (env.execute(result.getJavaScript()) == Status.Exit) {
        return;
      }
      env.destroy();

      // TODO(knorton): I had to make change to deft to forcefully close out all
      // the IOHandlers
      // in an IOLoop. I will attempt to upstream the changes.
      IOLoop.INSTANCE.reset();

      // Try to build the new version of the app. If that fails, recycle the old
      // version.
      final CompileResult newResult = compileService.build(file);
      if (newResult.didBuild()) {
        result = newResult;
        continue;
      }

      emitErrorsAndWarnings(newResult);
    }
  }
}
