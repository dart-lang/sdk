// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * A class that that helps presenting error messages in the command line.
 *
 * @see DefaultErrorFormatter
 * @see PrettyErrorFormatter
 */
public interface ErrorFormatter {

  public void format(DartCompilationError event);
}
