// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

/// Wrapper class for some static utilities.
class GenUtil {
  // Picks a top directory (command line, environment, or current).
  static String getTop(String top) {
    if (top == null || top == '') {
      top = Platform.environment['DART_TOP'];
    }
    if (top == null || top == '') {
      top = Directory.current.path;
    }
    return top;
  }

  // Create an analyzer session.
  static AnalysisSession createAnalysisSession([String dart_top]) {
    // Set paths. Note that for this particular use case, packageRoot can be
    // any directory. Here, we set it to the top of the SDK development, and
    // derive the required sdkPath from there.
    final String packageRoot = getTop(dart_top);
    if (packageRoot == null) {
      throw StateError('No environment variable DART_TOP');
    }
    final sdkPath = '$packageRoot/sdk';

    // This does most of the hard work of getting the analyzer configured
    // correctly. Typically the included paths are the files and directories
    // that need to be analyzed, but the SDK is always available, so it isn't
    // really important for this particular use case. We use the implementation
    // class in order to pass in the sdkPath directly.
    final provider = PhysicalResourceProvider.INSTANCE;
    final collection = AnalysisContextCollectionImpl(
        includedPaths: <String>[packageRoot],
        excludedPaths: <String>[packageRoot + "/pkg/front_end/test"],
        resourceProvider: provider,
        sdkPath: sdkPath);
    return collection.contexts[0].currentSession;
  }
}
