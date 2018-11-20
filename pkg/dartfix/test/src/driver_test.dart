// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:dartfix/src/driver.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

main() {
  test('protocol version', () {
    // The edit.dartfix protocol is experimental and will continue to evolve
    // an so dartfix will only work with this specific version of the protocol.
    // If the protocol changes, then a new version of both the
    // analysis_server_client and dartfix packages must be published.
    expect(new Version.parse(PROTOCOL_VERSION), Driver.expectedProtocolVersion);
  });

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

File findFile(String relPath) {
  Directory dir = Directory.current;
  while (true) {
    final file = new File.fromUri(dir.uri.resolve(relPath));
    if (file.existsSync()) {
      return file;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Failed to find $relPath');
    }
    dir = parent;
  }
}

String findValue(File pubspec, String key) {
  List<String> lines = pubspec.readAsLinesSync();
  for (String line in lines) {
    if (line.trim().startsWith('$key:')) {
      return line.split(':')[1].trim();
    }
  }
  fail('Failed to find $key in ${pubspec.path}');
}
