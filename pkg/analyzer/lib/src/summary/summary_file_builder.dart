// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('Use package:analyzer/dart/sdk/build_sdk_summary.dart instead')
library summary_file_builder;

import 'package:analyzer/dart/sdk/build_sdk_summary.dart' as api;
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';

/// Build summary for SDK the at the given [sdkPath].
///
/// If [embedderYamlPath] is provided, then libraries from this file are
/// appended to the libraries of the specified SDK.
List<int> buildSdkSummary({
  @required ResourceProvider resourceProvider,
  @required String sdkPath,
  String embedderYamlPath,
}) {
  return api.buildSdkSummary(
    resourceProvider: resourceProvider,
    sdkPath: sdkPath,
    embedderYamlPath: embedderYamlPath,
  );
}
