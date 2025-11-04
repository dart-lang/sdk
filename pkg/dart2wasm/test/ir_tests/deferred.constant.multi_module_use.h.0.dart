// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred.constant.multi_module_use.h.2.dart';

@pragma('wasm:never-inline')
MyConstClass modH0Use(bool nonShared) {
  return nonShared
      ? const MyConstClass('h0-nonshared-const')
      : const MyConstClass('shared-const');
}
