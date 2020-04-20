// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_cli/src/context_cache.dart';
import 'package:analyzer_cli/src/options.dart';

abstract class HasContextMixin {
  ContextCache get contextCache;
  ResourceProvider get resourceProvider;

  /// Based on the command line options, performantly get cached analysis
  /// options for the context.
  AnalysisOptionsImpl createAnalysisOptionsForCommandLineOptions(
      CommandLineOptions options, String source) {
    if (options.analysisOptionsFile != null) {
      var file = resourceProvider.getFile(options.analysisOptionsFile);
      if (!file.exists) {
        printAndFail('Options file not found: ${options.analysisOptionsFile}',
            exitCode: ErrorSeverity.ERROR.ordinal);
      }
    }

    return getContextInfo(options, source).analysisOptions;
  }

  /// Based on the [CommandLineOptions], and a specific [Source] within those
  /// options if any are specified, performantly get cached info about the
  /// context.
  ContextCacheEntry getContextInfo(CommandLineOptions options, String source) {
    if (options.sourceFiles.isEmpty) {
      return contextCache.forSource(resourceProvider.pathContext.current);
    }

    return contextCache.forSource(source);
  }
}
