// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:math");

#source("../../../runtime/bin/websocket.dart");
#source("../../../runtime/bin/websocket_impl.dart");

class WebSocketFrame {
  WebSocketFrame(int opcode, List<int> data);
}

// Class that when hooked up to the web socket protocol processor will
// collect the message and expect it to be equal to the
// expectedMessage field when fully received.
class WebSocketMessageCollector {
  WebSocketMessageCollector(_WebSocketProtocolProcessor this.processor,
                            [List<int> this.expectedMessage = null]) {
    processor.onMessageStart = onMessageStart;
    processor.onMessageData = onMessageData;
    processor.onMessageEnd = onMessageEnd;
    processor.onClosed = onClosed;
  }

  void onMessageStart(int type) {
    data = new List<int>();
  }

  void onMessageData(List<int> buffer, int index, int count) {
    data.addAll(buffer.getRange(index, count));
  }

  void onMessageEnd() {
    messageCount++;
    Expect.listEquals(expectedMessage, data);
    data = null;
  }

  void onClosed(int status, String reason) {
    closeCount++;
  }

  void onError(e) {
    Expect.fail("Unexpected error $e");
  }

  _WebSocketProtocolProcessor processor;
  List<int> expectedMessage;

  List<int> data;
  int messageCount = 0;
  int closeCount = 0;
}


// Web socket constants.
final int FRAME_OPCODE_TEXT = 1;
final int FRAME_OPCODE_BINARY = 2;


// Function for building a web socket frame.
List<int> createFrame(bool fin,
                      int opcode,
                      int maskingKey,
                      List<int> data,
                      int offset,
                      int count) {
  int frameSize = 2;
  if (count > 125) frameSize += 2;
  if (count > 65535) frameSize += 6;
  frameSize += count;
  // No masking.
  assert(maskingKey == null);
  List<int> frame = new List<int>(frameSize);
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
  frame.setRange(frameIndex, count, data, offset);
  return frame;
}


// Test processing messages which are sent in a single frame.
void testFullMessages() {
  // Use the same web socket protocol processor for all frames.
  _WebSocketProtocolProcessor processor = new _WebSocketProtocolProcessor();
  WebSocketMessageCollector mc = new WebSocketMessageCollector(processor);

  int messageCount = 0;

  void testMessage(int opcode, List<int> message) {
    mc.expectedMessage = message;
    List<int> frame = createFrame(
        true, opcode, null, message, 0, message.length);

    // Update the processor with one big chunk.
    messageCount++;
    processor.update(frame, 0, frame.length);
    Expect.isNull(mc.data);
    Expect.equals(0, processor._state);

    // Only run this part on small messages.
    if (message.length < 1000) {
      // Update the processor one byte at the time.
      messageCount++;
      for (int i = 0; i < frame.length; i++) {
        processor.update(frame, i, 1);
      }
      Expect.equals(0, processor._state);
      Expect.isNull(mc.data);

      // Update the processor two bytes at the time.
      messageCount++;
      for (int i = 0; i < frame.length; i += 2) {
        processor.update(frame, i, i + 1 < frame.length ? 2 : 1);
      }
      Expect.equals(0, processor._state);
      Expect.isNull(mc.data);
    }
  }

  void runTest(int from, int to, int step) {
    for (int messageLength = from; messageLength < to; messageLength += step) {
      List<int> message = new List<int>(messageLength);
      for (int i = 0; i < messageLength; i++) message[i] = i & 0xFF;
      testMessage(FRAME_OPCODE_TEXT, message);
      testMessage(FRAME_OPCODE_BINARY, message);
    }
  }

  // Test different message sizes.
  runTest(0, 10, 1);
  runTest(120, 130, 1);
  runTest(0, 1000, 100);
  runTest(65534, 65537, 1);
  print("Messages test, messages $messageCount");
  Expect.equals(messageCount, mc.messageCount);
  Expect.equals(0, mc.closeCount);
}


// Test processing of frames which are split into fragments.
void testFragmentedMessages() {
  // Use the same web socket protocol processor for all frames.
  _WebSocketProtocolProcessor processor = new _WebSocketProtocolProcessor();
  WebSocketMessageCollector mc = new WebSocketMessageCollector(processor);

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
      List<int> frame = createFrame(lastFrame,
                                    firstFrame ? opcode : 0x00,
                                    null,
                                    message,
                                    messageIndex,
                                    payloadSize);
      frameCount++;
      messageIndex += payloadSize;
      processor.update(frame, 0, frame.length);
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
      for (int i = 0; i < messageLength; i++) message[i] = i & 0xFF;
      testMessageFragmentation(FRAME_OPCODE_TEXT, message);
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
  Expect.equals(0, mc.closeCount);
}

void main() {
  testFullMessages();
  testFragmentedMessages();
}
