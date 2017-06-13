// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'api_signature_test.dart' as api_signature;
import 'file_repository_test.dart' as file_repository;
import 'flat_buffers_test.dart' as flat_buffers;
import 'libraries_reader_test.dart' as libraries_reader;
import 'processed_options_test.dart' as processed_options;
import 'uri_resolver_test.dart' as uri_resolver;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    api_signature.main();
    file_repository.main();
    flat_buffers.main();
    libraries_reader.main();
    processed_options.main();
    uri_resolver.main();
  }, name: 'incremental');
}
