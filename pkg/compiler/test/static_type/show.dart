// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the static type data on a dart program.

import 'package:args/args.dart';
import '../equivalence/show_helper.dart';
import 'type_promotion_test.dart';
import 'static_type_test.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('type-promotion', defaultsTo: false);
  ArgResults results = argParser.parse(args);

  bool showTypePromotion = results['type-promotion'];

  await show(
      results,
      showTypePromotion
          ? new TypePromotionDataComputer()
          : new StaticTypeDataComputer());
}
