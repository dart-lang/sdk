// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_collection_test.dart' as analysis_context_collection;
import 'context_builder_test.dart' as context_builder;
import 'context_locator_test.dart' as context_locator;
import 'context_root_test.dart' as context_root;
import 'defined_names_test.dart' as defined_names;
import 'driver_kernel_test.dart' as driver_kernel;
import 'driver_resolution_kernel_test.dart' as driver_resolution_kernel;
import 'driver_resolution_test.dart' as driver_resolution;
import 'driver_test.dart' as driver;
import 'file_state_test.dart' as file_state;
import 'index_test.dart' as index;
import 'mutex_test.dart' as mutex;
import 'referenced_names_test.dart' as referenced_names;
import 'search_test.dart' as search;
import 'session_helper_test.dart' as session_helper;
import 'session_test.dart' as session;
import 'uri_converter_test.dart' as uri_converter;

main() {
  defineReflectiveSuite(() {
    analysis_context_collection.main();
    context_builder.main();
    context_locator.main();
    context_root.main();
    defined_names.main();
    driver.main();
    driver_kernel.main();
    driver_resolution.main();
    driver_resolution_kernel.main();
    file_state.main();
    index.main();
    mutex.main();
    referenced_names.main();
    search.main();
    session_helper.main();
    session.main();
    uri_converter.main();
  }, name: 'analysis');
}
