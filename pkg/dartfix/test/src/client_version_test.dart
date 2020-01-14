// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_context.dart';

void main() {
  test('client version', () {
    // The edit.dartfix protocol is experimental and will continue to evolve
    // an so dartfix will only work with this specific version of the
    // analysis_server_client package.
    // If the protocol changes, then a new version of both the
    // analysis_server_client and dartfix packages must be published.
    expect(clientVersion, clientVersionInDartfixPubspec);
  });
}

String get clientVersion =>
    findValue(findFile('pkg/analysis_server_client/pubspec.yaml'), 'version');

String get clientVersionInDartfixPubspec =>
    findValue(findFile('pkg/dartfix/pubspec.yaml'), 'analysis_server_client');
