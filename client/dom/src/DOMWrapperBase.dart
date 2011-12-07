// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class DOMWrapperBase implements DOMType {
  // DOMWrapperBase has a hidden field on the native side which points to the
  // wrapped DOM object.  The wrapped DOM object is not directly accessible from
  // Dart code.

  var dartObjectLocalStorage;

  DOMWrapperBase() {}
}
