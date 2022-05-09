// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'constants.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerDomainTest);
  });
}

@reflectiveTest
class ServerDomainTest extends PubPackageAnalysisServerTest {
  Future<void> test_getVersion() async {
    var request = ServerGetVersionParams().toRequest('0');
    var response = await handleSuccessfulRequest(request);
    expect(
        response.toJson(),
        equals({
          Response.ID: '0',
          Response.RESULT: {VERSION: PROTOCOL_VERSION}
        }));
  }

  Future<void> test_setSubscriptions_invalidServiceName() async {
    var request = Request('0', SERVER_REQUEST_SET_SUBSCRIPTIONS, {
      SUBSCRIPTIONS: ['noSuchService']
    });
    var response = await handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_setSubscriptions_success() async {
    expect(server.serverServices, isEmpty);
    // send request
    var request =
        ServerSetSubscriptionsParams([ServerService.STATUS]).toRequest('0');
    await handleSuccessfulRequest(request);
    // set of services has been changed
    expect(server.serverServices, contains(ServerService.STATUS));
  }

  Future<void> test_shutdown() async {
    var request = ServerShutdownParams().toRequest('0');
    await handleSuccessfulRequest(request);
  }
}
