// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library options_helper;

import 'package:compiler/src/options.dart';
export 'package:compiler/src/options.dart';

class MockDiagnosticOptions implements DiagnosticOptions {
  const MockDiagnosticOptions();

  bool get fatalWarnings => false;
  bool get terseDiagnostics => false;
  bool get suppressWarnings => false;
  bool get suppressHints => false;
  bool get showAllPackageWarnings => false;
  bool get hidePackageWarnings => true;
  bool showPackageWarningsFor(Uri uri) => false;
}
