// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DeviceMotionEvent extends Event default DeviceMotionEventWrappingImplementation {

  // TODO(nweiz): Add more arguments to the constructor when we support
  // DeviceMotionEvent more thoroughly.
  DeviceMotionEvent(String type, [bool canBubble, bool cancelable]);

  num get interval();
}
