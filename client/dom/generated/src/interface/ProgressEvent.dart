// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProgressEvent extends Event {

  bool get lengthComputable();

  int get loaded();

  int get total();

  void initProgressEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, bool lengthComputableArg = null, int loadedArg = null, int totalArg = null);
}
