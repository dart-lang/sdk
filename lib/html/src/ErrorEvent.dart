// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ErrorEvent extends Event default ErrorEventWrappingImplementation {

  ErrorEvent(String type, String message, String filename, int lineNo,
      [bool canBubble, bool cancelable]);

  String get filename;

  int get lineno;

  String get message;
}
