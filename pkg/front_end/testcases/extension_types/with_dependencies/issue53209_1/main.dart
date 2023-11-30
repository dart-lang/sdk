// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './main_lib.dart';

extension type E1(String foo) {
  factory E1.redirectingFactoryToSubtype() = E2.redirectingFactoryWithMismatchingParameters;
}
