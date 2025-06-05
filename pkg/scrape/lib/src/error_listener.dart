// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';

import '../scrape.dart';

/// A simple [DiagnosticListener] that just collects the reported diagnostics.
class SimpleDiagnosticListener implements DiagnosticListener {
  final Scrape _scrape;
  final bool _printDiagnostics;
  bool _hadDiagnostic = false;

  SimpleDiagnosticListener(this._scrape, this._printDiagnostics);

  bool get hadDiagnostic => _hadDiagnostic;

  @override
  void onError(Diagnostic diagnostic) {
    _hadDiagnostic = true;

    if (_printDiagnostics) {
      _scrape.log(diagnostic);
    }
  }
}
