// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_snippet_producers_test.dart' as dart_snippet_producers;
import 'flutter_snippet_producers_test.dart' as flutter_snippet_producers;
import 'snippet_manager_test.dart' as snippet_manager;
import 'snippet_request_test.dart' as snippet_request;

void main() {
  defineReflectiveSuite(() {
    dart_snippet_producers.main();
    flutter_snippet_producers.main();
    snippet_manager.main();
    snippet_request.main();
  }, name: 'dart');
}
