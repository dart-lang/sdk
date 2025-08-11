// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';

class NotFoundPage extends DiagnosticPage {
  @override
  final String path;

  NotFoundPage(DiagnosticsSite site, this.path)
    : super(site, '', '404 Not found', description: "'$path' not found.");

  @override
  Future<void> generateContent(Map<String, String> params) async {}
}
