// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface JavaScriptCallFrame {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrame get caller();

  int get column();

  String get functionName();

  int get line();

  int get sourceID();

  String get type();

  void evaluate(String script);

  int scopeType(int scopeIndex);
}
