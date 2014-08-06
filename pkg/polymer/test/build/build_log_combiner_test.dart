// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.build_log_combiner_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/build_log_combiner.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

final options = new TransformOptions(injectBuildLogsInOutput: true);
final phases = [[new BuildLogCombiner(options)]];

void main() {
  useCompactVMConfiguration();

  testPhases('combines multiple logs', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html$LOG_EXTENSION.1': '[${_logString('Info', 'foo')}]',
      'a|web/test.html$LOG_EXTENSION.2': '[${_logString('Warning', 'bar')}]',
      'a|web/test.html$LOG_EXTENSION.3': '[${_logString('Error', 'baz')}]',
  }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html$LOG_EXTENSION':
      '[${_logString('Info', 'foo')},'
       '${_logString('Warning', 'bar')},'
       '${_logString('Error', 'baz')}]',
  });
}

String _logString(String level, String message) =>
  '{"level":"$level","message":"$message"}';