// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch List makeListFixedLength(List growableList)
    native "Internal_makeListFixedLength";

class VMLibraryHooks {
  // Example: "dart:isolate _Timer._factory"
  static var timerFactory;
  // Example: "dart:io _EventHandler._sendData"
  static var eventHandlerSendData;
}

patch class CodeUnits {
  static final int cid = ClassID.getID(new CodeUnits(""));
}
