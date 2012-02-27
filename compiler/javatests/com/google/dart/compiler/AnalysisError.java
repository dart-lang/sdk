// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

public class AnalysisError extends Exception {
  public AnalysisError(String message) {
    super(message);
  }

  AnalysisError(String message, Throwable cause) {
    super(message, cause);
  }

  AnalysisError(Throwable cause) {
    super(cause);
  }
}
