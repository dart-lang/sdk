// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the rti data on a dart program.

import 'package:args/args.dart';
import '../equivalence/show_helper.dart';
import 'rti_need_test.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults results = argParser.parse(args);
  await show(results, computeAstRtiMemberNeed, computeKernelRtiMemberNeed,
      computeAstClassData: computeAstRtiClassNeed,
      computeKernelClassData: computeKernelRtiClassNeed);
}
