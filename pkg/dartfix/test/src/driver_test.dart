// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}
