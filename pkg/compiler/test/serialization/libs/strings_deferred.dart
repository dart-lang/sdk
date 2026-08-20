// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String s = 'hello';
// Make sure we're using wtf8 encoding for strings in the serialized output.
// This ensures we don't conflate this non-utf8 string with the empty string.
const String t = '\uFEFF';

void useStrings() {
  print(s);
  print(t);
}
