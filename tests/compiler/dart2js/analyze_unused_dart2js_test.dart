// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_unused_dart2js;

import 'package:async_helper/async_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';

import 'analyze_helper.dart';

const String SIMPLIFY_NEVER_CALLED = "The method 'simplify' is never called";

// The simplify method isn't used in dart2js anymore but is used by many tests.
const Map<String, List<String>> WHITE_LIST = const {
  "type_mask.dart": const [SIMPLIFY_NEVER_CALLED],
  "concrete_types_inferrer.dart": const [SIMPLIFY_NEVER_CALLED],
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/use_unused_api.dart');
  asyncTest(
      () => analyze([uri], WHITE_LIST, analyzeAll: false));
}
