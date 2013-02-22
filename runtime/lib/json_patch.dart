// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// JSON parsing and serialization.

patch parse(String json, [reviver(var key, var value)]) {
  return _parse(json, reviver);
}
