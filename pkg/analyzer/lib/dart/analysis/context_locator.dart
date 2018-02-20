// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:meta/meta.dart';

/**
 * Determines the list of analysis contexts that can be used to analyze the
 * files and folders that should be analyzed given a list of included files and
 * folders and a list of excluded files and folders.
 */
abstract class ContextLocator {
  /**
   * Initialize a newly created context locator. If a [resourceProvider] is
   * supplied, it will be used to access the file system. Otherwise the default
   * resource provider will be used.
   */
  factory ContextLocator({ResourceProvider resourceProvider}) =
      ContextLocatorImpl;

  /**
   * Return a list of the analysis contexts that should be used to analyze the
   * files that are included by the list of [includedPaths] and not excluded by
   * the list of [excludedPaths].
   *
   * If the [packagesFile] is specified, then it is assumed to be the path to
   * the `.packages` file that should be used in place of the one that would be
   * found by looking in the directories containing the context roots.
   *
   * If the [sdkPath] is specified, then it is used as the path to the root of
   * the SDK that should be used during analysis.
   */
  List<AnalysisContext> locateContexts(
      {@required List<String> includedPaths,
      List<String> excludedPaths: const <String>[],
      String packagesFile: null,
      String sdkPath: null});
}
