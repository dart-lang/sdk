// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TransitionEvent extends Event default TransitionEventWrappingImplementation {

  TransitionEvent(String type, String propertyName, double elapsedTime,
      [bool canBubble, bool cancelable]);

  num get elapsedTime;

  String get propertyName;
}
