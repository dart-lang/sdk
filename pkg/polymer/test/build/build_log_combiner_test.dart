// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.build_log_combiner_test;

import 'package:code_transformers/messages/build_logger.dart' show
    LOG_EXTENSION;
import 'package:polymer/src/build/build_log_combiner.dart';
import 'package:polymer/src/build/common.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

final options = new TransformOptions(injectBuildLogsInOutput: true);
final phases = [[new BuildLogCombiner(options)]];

void main() {
  useCompactVMConfiguration();

  testPhases('combines multiple logs', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html$LOG_EXTENSION.1':
          '{"foo#0":[${_logString('Info', 0, 'foo')}]}',
      'a|web/test.html$LOG_EXTENSION.2':
          '{"foo#2":[${_logString('Warning', 2, 'bar')}]}',
      'a|web/test.html$LOG_EXTENSION.3':
          '{'
            '"foo#2":[${_logString('Error', 2, 'baz1')}],'
            '"foo#44":[${_logString('Error', 44, 'baz2')}]'
          '}',
  }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html$LOG_EXTENSION': '{'
            '"foo#0":[${_logString('Info', 0, 'foo')}],'
            '"foo#2":[${_logString('Warning', 2, 'bar')},'
                         '${_logString('Error', 2, 'baz1')}],'
            '"foo#44":[${_logString('Error', 44, 'baz2')}]'
          '}',
  });
}

String _logString(String level, int id, String message) =>
  '{"level":"$level","message":{"id":"foo#$id","snippet":"$message"}}';
