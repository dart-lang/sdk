// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the inlining data on a dart program.

import '../equivalence/show_helper.dart';
import 'inlining_test.dart';

main(List<String> args) async {
  await show(createArgParser().parse(args), const InliningDataComputer());
}
