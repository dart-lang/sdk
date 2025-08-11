// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class ExceptionsPage extends DiagnosticPageWithNav {
  ExceptionsPage(DiagnosticsSite site)
    : super(
        site,
        'exceptions',
        'Exceptions',
        description: 'Exceptions from the analysis server.',
      );

  Iterable<ServerException> get exceptions => server.exceptions.items;

  @override
  String get navDetail => '${exceptions.length}';

  @override
  Future<void> generateContent(Map<String, String> params) async {
    if (exceptions.isEmpty) {
      blankslate('No exceptions encountered!');
    } else {
      for (var ex in exceptions) {
        h3('Exception ${ex.exception}');
        p(
          '${escape(ex.message)}<br>${writeOption('fatal', ex.fatal)}',
          raw: true,
        );
        pre(() {
          buf.writeln('<code>${escape(ex.stackTrace.toString())}</code>');
        }, classes: 'scroll-table');
      }
    }
  }
}
