// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ngeoffray): define native top-level methods once top-level
// methods work with the resolver.
typedef void _PrintType(arg);

_PrintType get print() {
  return _Logger.print;
}

class _Logger {
  static print(arg) {
    _printString((arg === null) ? "null" : arg.toString());
  }

  static void _printString(String str) native;
}
