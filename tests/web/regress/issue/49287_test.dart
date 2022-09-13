// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--utf8

import 'package:expect/expect.dart';

import '49287_data.dart';

// This test contains a huge number of large strings that are predominantly code
// points that require surrogate pairs. The hope is that if there is an encoding
// issue like #49287 where a split surrogate pair is converted to U+FFFD
// REPLACEMENT CHARACTER, this will appear in the constructed string that
// otherwise does not contain U+FFFD.

void main() {
  Expect.isFalse(bigString.contains('\uFFFD'));
}
