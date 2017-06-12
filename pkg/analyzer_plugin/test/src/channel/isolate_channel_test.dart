// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/channel/isolate_channel.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(PluginIsolateChannelTest);
}

@reflectiveTest
class PluginIsolateChannelTest {
  TestSendPort sendPort;
  PluginIsolateChannel channel;

  void setUp() {
    sendPort = new TestSendPort();
    channel = new PluginIsolateChannel(sendPort);
  }

  void tearDown() {
    // If the test doesn't listen to the channel, then close will not cancel the
    // subscription and the process will not terminate.
    try {
      channel.listen((request) {});
    } catch (exception) {
      // Ignore the exception if the test has already registered a listener.
    }
    channel.close();
  }

  @failingTest
  Future<Null> test_close() async {
    bool done = false;
    channel.listen((Request request) {}, onDone: () {
      done = true;
    });
    channel.close();
    // TODO(brianwilkerson) Figure out how to wait until the handler has been
    // called.
    await _pumpEventQueue();
    expect(done, isTrue);
  }

  Future<Null> test_listen() async {
    Request sentRequest = new PluginShutdownParams().toRequest('5');
    Request receivedRequest;
    channel.listen((Request request) {
      receivedRequest = request;
    });
    sendPort.receivePort.send(sentRequest.toJson());
    await _pumpEventQueue(1);
    expect(receivedRequest, sentRequest);
  }

  void test_sendNotification() {
    Notification notification =
        new PluginErrorParams(false, '', '').toNotification();
    channel.sendNotification(notification);
    expect(sendPort.sentMessages, hasLength(1));
    expect(sendPort.sentMessages[0], notification.toJson());
  }

  void test_sendResponse() {
    Response response = new PluginShutdownResult().toResponse('3', 1);
    channel.sendResponse(response);
    expect(sendPort.sentMessages, hasLength(1));
    expect(sendPort.sentMessages[0], response.toJson());
  }

  /**
   * Returns a [Future] that completes after pumping the event queue [times]
   * times. By default, this should pump the event queue enough times to allow
   * any code to run, as long as it's not waiting on some external event.
   */
  Future<Null> _pumpEventQueue([int times = 5000]) {
    if (times == 0) return new Future.value();
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return new Future.delayed(Duration.ZERO, () => _pumpEventQueue(times - 1));
  }
}

/**
 * A send port used in tests.
 */
class TestSendPort implements SendPort {
  /**
   * The receive port used to receive messages from the server.
   */
  SendPort receivePort;

  /**
   * The messages sent to the server.
   */
  List<Object> sentMessages = <Object>[];

  @override
  void send(message) {
    if (receivePort == null) {
      if (message is SendPort) {
        receivePort = message;
      } else {
        fail('Did not receive a receive port as the first communication.');
      }
    } else {
      sentMessages.add(message);
    }
  }
}
