// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch List makeListFixedLength(List growableList)
    native "Internal_makeListFixedLength";

@patch List makeFixedListUnmodifiable(List fixedLengthList)
    native "Internal_makeFixedListUnmodifiable";

class VMLibraryHooks {
  // Example: "dart:isolate _Timer._factory"
  static var timerFactory;

  // Example: "dart:io _EventHandler._sendData"
  static var eventHandlerSendData;

  // A nullary closure that answers the current clock value in milliseconds.
  // Example: "dart:io _EventHandler._timerMillisecondClock"
  static var timerMillisecondClock;

  // Implementation of Resource.readAsBytes.
  static var resourceReadAsBytes;

  // Implementation of package root/map provision.
  static var packageRootString;
  static var packageConfigString;
  static var packageRootUriFuture;
  static var packageConfigUriFuture;
  static var resolvePackageUriFuture;

  static var platformScript;
}

final bool is64Bit = _inquireIs64Bit();

bool _inquireIs64Bit() native "Internal_inquireIs64Bit";

bool _classRangeCheck(int cid, int lowerLimit, int upperLimit) {
  return cid >= lowerLimit && cid <= upperLimit;
}

bool _classRangeCheckNegative(int cid, int lowerLimit, int upperLimit) {
  return cid < lowerLimit || cid > upperLimit;
}
