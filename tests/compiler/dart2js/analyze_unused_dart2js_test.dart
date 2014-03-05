// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_unused_dart2js;

import 'package:async_helper/async_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';

import 'analyze_helper.dart';

const Map<String, List<String>> WHITE_LIST = const {
  "ir_builder.dart": const ["The method 'getIr' is never called."],
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/use_unused_api.dart');
  asyncTest(() => analyze([uri], WHITE_LIST, analyzeAll: false));
}
