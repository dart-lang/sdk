// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import java.io.PrintStream;

/**
 * @author floitsch@google.com (Florian Loitsch)
 *
 */
interface JavaScriptLauncher {

  void execute(String jsScript, String sourceName, String[] args, RunnerOptions flags,
               PrintStream stdout, PrintStream stderr)
      throws RunnerError;

}
