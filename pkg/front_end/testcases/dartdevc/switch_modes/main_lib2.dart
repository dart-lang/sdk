// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'main_lib1.dart';

method(EnumLike e) {
  switch (e) {
    case EnumLike.a:
      print(EnumLike.a);
  }
}
