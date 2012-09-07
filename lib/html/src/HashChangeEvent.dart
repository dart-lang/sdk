// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface HashChangeEvent extends Event default HashChangeEventWrappingImplementation {

  HashChangeEvent(String type, String oldURL, String newURL, [bool canBubble,
      bool cancelable]);

  String get newURL;

  String get oldURL;
}
