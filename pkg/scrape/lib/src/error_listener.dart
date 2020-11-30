// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:scrape/scrape.dart';

/// A simple [AnalysisErrorListener] that just collects the reported errors.
class ErrorListener implements AnalysisErrorListener {
  final Scrape _scrape;
  final bool _printErrors;
  bool _hadError = false;

  ErrorListener(this._scrape, this._printErrors);

  bool get hadError => _hadError;

  @override
  void onError(AnalysisError error) {
    _hadError = true;

    if (_printErrors) {
      _scrape.log(error);
    }
  }
}
