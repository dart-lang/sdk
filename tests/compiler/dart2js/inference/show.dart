// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the inferrer data on a dart program.

import '../equivalence/show_helper.dart';
import 'inference_test_helper.dart';

main(List<String> args) async {
  await show(args, computeMemberAstTypeMasks, computeMemberIrTypeMasks);
}
