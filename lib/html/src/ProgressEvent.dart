// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ProgressEvent extends Event default ProgressEventWrappingImplementation {

  ProgressEvent(String type, int loaded, [bool canBubble, bool cancelable,
      bool lengthComputable, int total]);

  bool get lengthComputable();

  int get loaded();

  int get total();
}
