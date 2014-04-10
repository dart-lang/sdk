// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library verify_and_run;

import 'sample_with_messages.dart' as sample;
import 'verify_messages.dart';

main() {
  sample.main().then(verifyResult);
}