// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TransitionEvent extends Event {

  num get elapsedTime();

  String get propertyName();

  void initWebKitTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String propertyNameArg, num elapsedTimeArg);
}
