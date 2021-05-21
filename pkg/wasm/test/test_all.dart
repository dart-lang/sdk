// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'basic_test.dart' as basic;
import 'corrupted_error_test.dart' as corrupted_error;
import 'fn_call_error_test.dart' as fn_call_error;
import 'fn_import_error_test.dart' as fn_import_error;
import 'fn_import_exception_test.dart' as fn_import_exception;
import 'fn_import_test.dart' as fn_import;
import 'hello_wasi_test.dart' as hello_wasi;
import 'hello_world_test.dart' as hello_world;
import 'memory_error_test.dart' as memory_error;
import 'memory_test.dart' as memory;
import 'numerics_test.dart' as numerics;
import 'void_test.dart' as void_;
import 'wasi_error_test.dart' as wasi_error;

void main() {
  group('basic', basic.main);
  group('corrupted_error', corrupted_error.main);
  group('fn_call_error', fn_call_error.main);
  group('fn_import_error', fn_import_error.main);
  group('fn_import_exception', fn_import_exception.main);
  group('fn_import', fn_import.main);
  group('hello_wasi', hello_wasi.main);
  group('hello_world', hello_world.main);
  group('memory_error', memory_error.main);
  group('memory', memory.main);
  group('numerics', numerics.main);
  group('void', void_.main);
  group('wasi_error', wasi_error.main);
}
