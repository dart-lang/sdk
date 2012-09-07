// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestProgressEvent extends ProgressEvent default XMLHttpRequestProgressEventWrappingImplementation {

  XMLHttpRequestProgressEvent(String type, int loaded, [bool canBubble,
      bool cancelable, bool lengthComputable, int total]);

  int get position;

  int get totalSize;
}
