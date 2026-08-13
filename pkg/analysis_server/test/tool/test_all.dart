// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_metrics/test_all.dart' as completion_metrics;
import 'log_player/test_all.dart' as log_player;
import 'lsp_spec/test_all.dart' as lsp_spec;

void main() {
  defineReflectiveSuite(() {
    completion_metrics.main();
    log_player.main();
    lsp_spec.main();
  }, name: 'tool');
}
