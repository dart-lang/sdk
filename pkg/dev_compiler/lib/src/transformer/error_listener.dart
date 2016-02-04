// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.transformer.error_listener;

import 'package:barback/barback.dart' show TransformLogger;
import 'package:analyzer/analyzer.dart'
    show AnalysisError, ErrorSeverity, AnalysisErrorListener;

class TransformAnalysisErrorListener extends AnalysisErrorListener {
  TransformLogger _logger;
  TransformAnalysisErrorListener(this._logger);

  @override
  void onError(AnalysisError error) {
    // TODO(ochafik): Proper location / span.
    switch (error.errorCode.errorSeverity) {
      case ErrorSeverity.ERROR:
        _logger.error(error.message);
        break;
      case ErrorSeverity.WARNING:
        _logger.warning(error.message);
        break;
      default:
        _logger.info(error.message);
        break;
    }
  }
}
