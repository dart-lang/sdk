// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.io;

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:developer";
import "dart:io";
import "dart:math";
import "dart:typed_data";
import "dart:isolate";

part "../../../sdk/lib/_http/crypto.dart";
part "../../../sdk/lib/_http/http_impl.dart";
part "../../../sdk/lib/_http/http_date.dart";
part "../../../sdk/lib/_http/http_parser.dart";
part "../../../sdk/lib/_http/http_headers.dart";
part "../../../sdk/lib/_http/http_session.dart";
part "../../../sdk/lib/_http/websocket.dart";
part "../../../sdk/lib/_http/websocket_impl.dart";

class WebSocketFrame {
  WebSocketFrame(int opcode, List<int> data);
}

// Class that when hooked up to the web socket protocol transformer will
// collect the message and expect it to be equal to the
// expectedMessage field when fully received.
class WebSocketMessageCollector {
  List<int> expectedMessage;

  int messageCount = 0;

  var data;

  Function onClosed;

  WebSocketMessageCollector(Stream stream,
      [List<int> this.expectedMessage = null]) {
    stream.listen(onMessageData, onDone: onClosed, onError: onError);
  }

  void onMessageData(buffer) {
    if (buffer is String) {
      buffer = UTF8.encode(buffer);
    }
    Expect.listEquals(expectedMessage, buffer);
    messageCount++;
    data = buffer;
  }

  void onError(e, trace) {
    String msg = "Unexpected error $e";
    if (trace != null) msg += "\nStackTrace: $trace";
    Expect.fail(msg);
  }
}

// Web socket constants.
const int FRAME_OPCODE_TEXT = 1;
const int FRAME_OPCODE_BINARY = 2;

// Function for building a web socket frame.
List<int> createFrame(bool fin, int opcode, int maskingKey, List<int> data,
    int offset, int count) {
  int frameSize = 2;
  if (count > 125) frameSize += 2;
  if (count > 65535) frameSize += 6;
  frameSize += count;
  // No masking.
  assert(maskingKey == null);
  List<int> frame = new Uint8List(frameSize);
  int frameIndex = 0;
  frame[frameIndex++] = (fin ? 0x80 : 0x00) | opcode;
  if (count < 126) {
    frame[frameIndex++] = count;
  } else if (count < 65536) {
    frame[frameIndex++] = 126;
    frame[frameIndex++] = count >> 8;
    frame[frameIndex++] = count & 0xFF;
  } else {
    frame[frameIndex++] = 127;
    for (int i = 0; i < 8; i++) {
      frame[frameIndex++] = count >> ((7 - i) * 8) & 0xFF;
    }
  }
  frame.setRange(frameIndex, frameIndex + count, data, offset);
  return frame;
}

// Test processing messages which are sent in a single frame.
void testFullMessages() {
  void testMessage(int opcode, List<int> message) {
    int messageCount = 0;
    // Use the same web socket protocol transformer for all frames.
    var transformer = new _WebSocketProtocolTransformer();
    var controller = new StreamController(sync: true);
    WebSocketMessageCollector mc = new WebSocketMessageCollector(
        controller.stream.transform(transformer), message);

    List<int> frame =
        createFrame(true, opcode, null, message, 0, message.length);

    // Update the transformer with one big chunk.
    messageCount++;
    controller.add(frame);
    mc.onClosed = () {
      Expect.isNotNull(mc.data);
      Expect.equals(0, transformer._state);

      mc.data = null;

      // Only run this part on small messages.
      if (message.length < 1000) {
        // Update the transformer one byte at the time.
        messageCount++;
        for (int i = 0; i < frame.length; i++) {
          controller.add(<int>[frame[i]]);
        }
        Expect.equals(0, transformer._state);
        Expect.isNotNull(mc.data);
        mc.data = null;

        // Update the transformer two bytes at the time.
        messageCount++;
        for (int i = 0; i < frame.length; i += 2) {
          controller.add(frame.sublist(i, min(i + 2, frame.length)));
        }
        Expect.equals(0, transformer._state);
        Expect.isNotNull(mc.data);
      }
      Expect.equals(messageCount, mc.messageCount);
      print("Messages test, messages $messageCount");
    };
    controller.close();
  }

  void runTest(int from, int to, int step) {
    for (int messageLength = from; messageLength < to; messageLength += step) {
      List<int> message = new List<int>(messageLength);
      for (int i = 0; i < messageLength; i++) message[i] = i & 0x7F;
      testMessage(FRAME_OPCODE_TEXT, message);
      for (int i = 0; i < messageLength; i++) message[i] = i & 0xFF;
      testMessage(FRAME_OPCODE_BINARY, message);
    }
  }

  // Test different message sizes.
  runTest(0, 10, 1);
  runTest(120, 130, 1);
  runTest(0, 1000, 100);
  runTest(65534, 65537, 1);
}

// Test processing of frames which are split into fragments.
void testFragmentedMessages() {
  // Use the same web socket protocol transformer for all frames.
  var transformer = new _WebSocketProtocolTransformer();
  var controller = new StreamController(sync: true);
  WebSocketMessageCollector mc =
      new WebSocketMessageCollector(controller.stream.transform(transformer));

  int messageCount = 0;
  int frameCount = 0;

  void testFragmentMessage(int opcode, List<int> message, int fragmentSize) {
    messageCount++;
    int messageIndex = 0;
    int remaining = message.length;
    bool firstFrame = true;
    bool lastFrame = false;
    while (!lastFrame) {
      int payloadSize = min(fragmentSize, remaining);
      lastFrame = payloadSize == remaining;
      List<int> frame = createFrame(lastFrame, firstFrame ? opcode : 0x00, null,
          message, messageIndex, payloadSize);
      frameCount++;
      messageIndex += payloadSize;
      controller.add(frame);
      remaining -= payloadSize;
      firstFrame = false;
    }
  }

  void testMessageFragmentation(int opcode, List<int> message) {
    mc.expectedMessage = message;

    // Test with fragmenting the message in different fragment sizes.
    if (message.length <= 10) {
      for (int i = 1; i < 10; i++) {
        testFragmentMessage(opcode, message, i);
      }
    } else {
      testFragmentMessage(opcode, message, 10);
      testFragmentMessage(opcode, message, 100);
    }
  }

  void runTest(int from, int to, int step) {
    for (int messageLength = from; messageLength < to; messageLength += step) {
      List<int> message = new List<int>(messageLength);
      for (int i = 0; i < messageLength; i++) message[i] = i & 0x7F;
      testMessageFragmentation(FRAME_OPCODE_TEXT, message);
      for (int i = 0; i < messageLength; i++) message[i] = i & 0xFF;
      testMessageFragmentation(FRAME_OPCODE_BINARY, message);
    }
  }

  // Test different message sizes.
  runTest(0, 10, 1);
  runTest(120, 130, 1);
  runTest(0, 1000, 100);
  runTest(65534, 65537, 1);
  print("Fragment messages test, messages $messageCount, frames $frameCount");
  Expect.equals(messageCount, mc.messageCount);
}

void testUnmaskedMessage() {
  var transformer = new _WebSocketProtocolTransformer(true);
  var controller = new StreamController(sync: true);
  asyncStart();
  controller.stream.transform(transformer).listen((_) {}, onError: (e) {
    asyncEnd();
  });
  var message = new Uint8List(10);
  List<int> frame =
      createFrame(true, FRAME_OPCODE_BINARY, null, message, 0, message.length);
  controller.add(frame);
}

void main() {
  testFullMessages();
  testFragmentedMessages();
  testUnmaskedMessage();
}
