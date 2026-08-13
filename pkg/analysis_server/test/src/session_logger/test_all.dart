// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'log_normalizer_test.dart' as log_normalizer;
import 'session_logger_sink_test.dart' as session_logger_sink;

void main() {
  defineReflectiveSuite(() {
    log_normalizer.main();
    session_logger_sink.main();
  });
}
