// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the rti data on a dart program.

import 'package:args/args.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../equivalence/show_helper.dart';
import 'rti_emission_test_helper.dart';
import 'rti_need_test_helper.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('need', defaultsTo: true);
  argParser.addFlag('emission');
  ArgResults results = argParser.parse(args);

  DataComputer dataComputer;
  if (results['emission']) {
    dataComputer = const RtiEmissionDataComputer();
  } else {
    dataComputer = const RtiNeedDataComputer();
  }

  await show(results, dataComputer);
}
