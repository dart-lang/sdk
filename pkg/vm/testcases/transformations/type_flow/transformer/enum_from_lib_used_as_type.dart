// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'enum_from_lib_used_as_type.lib.dart';

main() {
  List list = [];
  if (list.isNotEmpty) {
    new Class().method(null as dynamic);
  }
}
