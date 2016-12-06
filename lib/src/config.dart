// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.config;

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:linter/src/plugin/linter_plugin.dart';

export 'package:analyzer/src/lint/config.dart';

/// Processes analysis options files and translates them into [LintConfig]s.
class AnalysisOptionsProcessor extends OptionsProcessor {
  final List<Exception> exceptions = <Exception>[];
  final LinterPlugin plugin;
  AnalysisOptionsProcessor(this.plugin);

  @override
  void onError(Exception exception) {
    //TODO(pq): handle exceptions
    exceptions.add(exception);
  }

  @override
  void optionsProcessed(AnalysisContext context, Map<String, Object> options) {
    var lints = plugin.registerLints(context, parseConfig(options));
    if (lints.isNotEmpty) {
      var options = new AnalysisOptionsImpl.from(context.analysisOptions);
      options.lint = true;
      context.analysisOptions = options;
    }
  }
}
