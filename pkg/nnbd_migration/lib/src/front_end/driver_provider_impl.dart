// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/api_for_nnbd_migration.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;

class DriverProviderImpl implements DriverProvider {
  @override
  final ResourceProvider resourceProvider;

  final AnalysisContext analysisContext;

  DriverProviderImpl(this.resourceProvider, this.analysisContext);

  @override
  AnalysisSession getAnalysisSession(String path) =>
      analysisContext.currentSession;
}
