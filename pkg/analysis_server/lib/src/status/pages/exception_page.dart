// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';

class ExceptionPage extends DiagnosticPage {
  final StackTrace trace;

  ExceptionPage(DiagnosticsSite site, String message, this.trace)
    : super(site, '', '500 Oops', description: message);

  @override
  Future<void> generateContent(Map<String, String> params) async {
    p(trace.toString(), style: 'white-space: pre');
  }
}
