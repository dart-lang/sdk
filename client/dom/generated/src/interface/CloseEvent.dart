// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CloseEvent extends Event {

  int get code();

  String get reason();

  bool get wasClean();

  void initCloseEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, bool wasCleanArg = null, int codeArg = null, String reasonArg = null);
}
