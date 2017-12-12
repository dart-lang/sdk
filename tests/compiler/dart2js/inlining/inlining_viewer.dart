// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the inlining data on a dart program.

import 'package:compiler/src/js_backend/backend.dart';
import '../equivalence/show_helper.dart';
import 'inlining_test.dart';

main(List<String> args) async {
  JavaScriptBackend.cacheCodegenImpactForTesting = true;
  await show(args, computeMemberAstInlinings, computeMemberIrInlinings);
}
