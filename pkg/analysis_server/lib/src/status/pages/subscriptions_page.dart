// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';

class SubscriptionsPage extends DiagnosticPageWithNav {
  @override
  LegacyAnalysisServer server;

  SubscriptionsPage(DiagnosticsSite site, this.server)
    : super(
        site,
        'subscriptions',
        'Subscriptions',
        description: 'Registered subscriptions to analysis server events.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    // server domain
    h3('Server domain subscriptions');
    ul(ServerService.values, (item) {
      if (server.serverServices.contains(item)) {
        buf.write('$item (has subscriptions)');
      } else {
        buf.write('$item (no subscriptions)');
      }
    });

    // analysis domain
    h3('Analysis domain subscriptions');
    for (var service in AnalysisService.values) {
      buf.writeln('${service.name}<br>');
      ul(server.analysisServices[service] ?? {}, (item) {
        buf.write('$item');
      });
    }
  }
}
