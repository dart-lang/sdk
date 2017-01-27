// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_manager_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractContextManagerTest_Driver);
    defineReflectiveTests(ContextManagerWithNewOptionsTest_Driver);
    defineReflectiveTests(ContextManagerWithOldOptionsTest_Driver);
  });
}

@reflectiveTest
class AbstractContextManagerTest_Driver extends AbstractContextManagerTest {
  bool get enableAnalysisDriver => true;

  @failingTest
  test_embedder_added() {
    // NoSuchMethodError: The getter 'apiSignature' was called on null.
    // Receiver: null
    // Tried calling: apiSignature
    // dart:core                                                          Object.noSuchMethod
    // package:analyzer/src/dart/analysis/driver.dart 460:20              AnalysisDriver.configure
    // package:analysis_server/src/context_manager.dart 1043:16           ContextManagerImpl._checkForPackagespecUpdate
    // package:analysis_server/src/context_manager.dart 1553:5            ContextManagerImpl._handleWatchEvent
    //return super.test_embedder_added();
    fail('NoSuchMethodError');
  }
}

@reflectiveTest
class ContextManagerWithNewOptionsTest_Driver
    extends ContextManagerWithNewOptionsTest {
  bool get enableAnalysisDriver => true;

  @failingTest
  test_analysis_options_file_delete_with_embedder() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    return super.test_analysis_options_file_delete_with_embedder();
  }

  @failingTest
  test_embedder_options() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    return super.test_embedder_options();
  }

  @failingTest
  test_optionsFile_update_strongMode() async {
    // It appears that this fails because we are not correctly updating the
    // analysis options in the driver when the file is modified.
    //return super.test_optionsFile_update_strongMode();
    // After a few other changes, the test now times out on my machine, so I'm
    // disabling it in order to prevent it from being flaky.
    fail('Test times out');
  }

  @failingTest
  test_path_filter_analysis_option() async {
    // This fails because we're not analyzing the analyis options file.
    return super.test_path_filter_analysis_option();
  }
}

@reflectiveTest
class ContextManagerWithOldOptionsTest_Driver
    extends ContextManagerWithOldOptionsTest {
  bool get enableAnalysisDriver => true;

  @failingTest
  test_analysis_options_file_delete_with_embedder() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    return super.test_analysis_options_file_delete_with_embedder();
  }

  @failingTest
  test_embedder_options() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    return super.test_embedder_options();
  }

  @failingTest
  test_optionsFile_update_strongMode() async {
    // It appears that this fails because we are not correctly updating the
    // analysis options in the driver when the file is modified.
    //return super.test_optionsFile_update_strongMode();
    // After a few other changes, the test now times out on my machine, so I'm
    // disabling it in order to prevent it from being flaky.
    fail('Test times out');
  }

  @failingTest
  test_path_filter_analysis_option() async {
    // This fails because we're not analyzing the analyis options file.
    return super.test_path_filter_analysis_option();
  }
}
