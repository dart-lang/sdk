// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to combine all the ._buildLog.* logs into one ._buildLog file.
library polymer.src.build.log_combiner;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/parser.dart' show parseFragment;

import 'common.dart';
import 'wrapped_logger.dart';

/// Logic to combine all the ._buildLog.* logs into one ._buildLog file.
class BuildLogCombiner extends Transformer with PolymerTransformer {
  final TransformOptions options;

  BuildLogCombiner(this.options);

  /// Run only on entry point html files and only if
  /// options.injectBuildLogsInOutput is true.
  bool isPrimary(idOrAsset) {
    if (!options.injectBuildLogsInOutput) return false;
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return options.isHtmlEntryPoint(id);
  }

  Future apply(Transform transform) {
    // Combine all ._buildLogs* files into one ._buildLogs file.
    return WrappedLogger.combineLogFiles(transform);
  }
}
