// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';

import '../fix_processor.dart';

/// A base class defining support for writing fix processor tests for
/// data-driven fixes.
abstract class DataDrivenFixProcessorTest extends FixProcessorTest {
  /// Return the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  /// Set the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    addPackageFile('p', 'lib.dart', content);
  }

  /// Set the data on which this test is based.
  void setPackageData(Transform transform) {
    DataDriven.transformSetsForTests = [
      TransformSet()..addTransform(transform)
    ];
  }
}
