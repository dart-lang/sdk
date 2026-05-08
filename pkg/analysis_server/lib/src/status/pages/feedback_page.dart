// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/util/platform_info.dart';

class FeedbackPage extends DiagnosticPage {
  FeedbackPage(DiagnosticsSite site)
    : super(
        site,
        'feedback',
        'Feedback',
        description: 'How to provide feedback and file issues.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var issuesUrl = 'https://github.com/dart-lang/sdk/issues';
    p(
      'To file issues or feature requests, see our '
      '<a href="$issuesUrl">bug tracker</a>. When filing an issue, please describe:',
      raw: true,
    );
    ul([
      'what you were doing',
      'what occurred',
      'what you think the expected behavior should have been',
    ], (line) => buf.writeln(line));

    var ideInfo = <String>[];
    var clientId = server.options.clientId;
    if (clientId != null) {
      ideInfo.add(clientId);
    }
    var clientVersion = server.options.clientVersion;
    if (clientVersion != null) {
      ideInfo.add(clientVersion);
    }
    var ideText = ideInfo.map((str) => '<code>$str</code>').join(', ');

    p('Other data to include:');
    ul([
      "the IDE you are using and its version${ideText.isEmpty ? '' : ' ($ideText)'}",
      'the Dart SDK version (<code>${escape(sdkVersion)}</code>)',
      'your operating system (<code>${escape(platform.operatingSystem)}</code>)',
    ], (line) => buf.writeln(line));

    p('Thanks!');
  }
}
