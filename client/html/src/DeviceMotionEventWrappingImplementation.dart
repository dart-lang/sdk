// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DeviceMotionEventWrappingImplementation extends EventWrappingImplementation implements DeviceMotionEvent {
  DeviceMotionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceMotionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceMotionEvent");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapDeviceMotionEvent(e);
  }

  num get interval() => _ptr.interval;
}
