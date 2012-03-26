// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DOMType {
  // TODO(vsm): Remove if/when Dart supports OLS for all objects.
  var dartObjectLocalStorage;

  String get typeName();
}
