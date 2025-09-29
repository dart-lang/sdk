// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:record_use/record_use.dart';

void doStuffInLinkHook(
  RecordedUsages usage,
  Identifier identifier1,
  Identifier identifier2,
  Identifier identifier3,
) {
  print(usage.metadata);
  print(usage.constArgumentsFor(identifier1));
  print(usage.constantsOf(identifier2));
  print(usage.hasNonConstArguments(identifier3));
}
