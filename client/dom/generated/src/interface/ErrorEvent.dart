// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ErrorEvent extends Event {

  String get filename();

  int get lineno();

  String get message();

  void initErrorEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String messageArg = null, String filenameArg = null, int linenoArg = null);
}
