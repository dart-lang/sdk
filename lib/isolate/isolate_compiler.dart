// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Dart isolate's API for the dartc compiler (only used for type checking in the
// dart editor, but not for code generation).
#library("dart:isolate");

#source("isolate_api.dart");

class _IsolateFactory {

  factory Isolate2.fromCode(Function topLevelFunction) {
    throw new NotImplementedException();
  }

  factory Isolate2.fromUri(String uri) {
    throw new NotImplementedException();
  }
}

class _IsolateNatives {
  static Future<SendPort> spawn(Isolate isolate, bool isLight) {
    throw new NotImplementedException();
  }
}

class _ReceivePortFactory {

  factory ReceivePort() {
    throw new NotImplementedException();
  }

  factory ReceivePort.singleShot() {
    throw new NotImplementedException();
  }
}
