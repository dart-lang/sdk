// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface PopStateEvent extends Event default PopStateEventWrappingImplementation {

  PopStateEvent(String type, Object state, [bool canBubble, bool cancelable]);

  String get state;
}
