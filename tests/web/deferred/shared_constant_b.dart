// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared_constant_shared.dart' deferred as d;

doB() async {
  await d.loadLibrary();
  return d.constant;
}
