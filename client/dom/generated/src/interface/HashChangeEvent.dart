// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HashChangeEvent extends Event {

  String get newURL();

  String get oldURL();

  void initHashChangeEvent(String type = null, bool canBubble = null, bool cancelable = null, String oldURL = null, String newURL = null);
}
