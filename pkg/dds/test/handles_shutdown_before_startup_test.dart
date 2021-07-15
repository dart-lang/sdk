// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:dds/src/dds_impl.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'common/fakes.dart';

class ImmediatelyClosedPeer extends FakePeer {
  // Immediately complete the returned future to act as if we've closed.
  @override
  Future<void> listen() => Future.value();
}

class ImmediatelyClosedErrorPeer extends FakePeer {
  // Immediately complete the returned future with an error to act as if we've
  // encountered a connection issue.
  @override
  Future<void> listen() => Future.error('Connection lost');
}

// Regression test for https://github.com/flutter/flutter/issues/86361.
void main() {
  webSocketBuilder = (Uri _) => FakeWebSocketChannel();

  test('Shutdown before server startup complete', () async {
    peerBuilder =
        (WebSocketChannel _, dynamic __) async => ImmediatelyClosedPeer();
    try {
      await DartDevelopmentService.startDartDevelopmentService(
        Uri(scheme: 'http'),
      );
    } on DartDevelopmentServiceException {
      /* We expect to fail to start */
    }
  });

  test('Error shutdown before server startup complete', () async {
    peerBuilder =
        (WebSocketChannel _, dynamic __) async => ImmediatelyClosedErrorPeer();
    try {
      await DartDevelopmentService.startDartDevelopmentService(
        Uri(scheme: 'http'),
      );
    } on DartDevelopmentServiceException {
      /* We expect to fail to start */
    }
  });
}
