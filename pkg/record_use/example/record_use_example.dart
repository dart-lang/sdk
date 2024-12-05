// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:record_use/record_use.dart';

void doStuff(RecordedUsages usage, Identifier callId, Identifier referenceId) {
  print(usage.metadata);
  print(usage.argumentsTo(callId));
  print(usage.instancesOf(referenceId));
  print(usage.hasNonConstArguments(callId));
}
