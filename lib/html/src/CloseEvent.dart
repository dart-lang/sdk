// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface CloseEvent extends Event default CloseEventWrappingImplementation {

  CloseEvent(String type, int code, String reason,
      [bool canBubble, bool cancelable, bool wasClean]);

  int get code;

  String get reason;

  bool get wasClean;
}
