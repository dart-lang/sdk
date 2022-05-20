// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--no-enable-fast-object-copy
// VMOptions=--enable-fast-object-copy

import 'dart:io';
import 'dart:isolate';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import '../timeline_utils.dart';

final int wordSize = sizeOf<IntPtr>();
final bool useCompressedPointers =
    wordSize == 8 && (Platform.isAndroid || Platform.isIOS);

final int kAllocationSize = 2 * wordSize;
final int headerSize = wordSize;
final int slotSize = useCompressedPointers ? 4 : wordSize;

final int objectBaseSize = headerSize;
final int arrayBaseSize = headerSize + 2 * slotSize;
final int typedDataBaseSize = headerSize + 2 * wordSize;

int objectSize(int slots) => toAllocationSize(headerSize + slots * slotSize);
int arraySize(int elements) =>
    toAllocationSize(headerSize + 2 * slotSize + elements * slotSize);
int typedDataSize(int length) =>
    toAllocationSize(headerSize + 2 * wordSize + length);

int toAllocationSize(int value) =>
    (value + kAllocationSize - 1) & ~(kAllocationSize - 1);

Future main(List<String> args) async {
  if (const bool.fromEnvironment('dart.vm.product')) {
    return; // No timeline support
  }

  if (args.contains('--child')) {
    final rp = ReceivePort();
    final sendPort = rp.sendPort;

    sendPort.send(Object());
    sendPort.send(List<dynamic>.filled(2, null)
      ..[0] = Object()
      ..[1] = Object());
    sendPort.send(Uint8List(11));

    rp.close();
    return;
  }

  final timelineEvents = await runAndCollectTimeline('Isolate', ['--child']);
  final mainIsolateId = findMainIsolateId(timelineEvents);
  final copyOperations = getCopyOperations(timelineEvents, mainIsolateId);

  // We're only interested in the last 3 operations (which are done by the
  // application).
  copyOperations.removeRange(0, copyOperations.length - 3);

  Expect.equals(1, copyOperations[0].objectsCopied);
  Expect.equals(3, copyOperations[1].objectsCopied);
  Expect.equals(1, copyOperations[2].objectsCopied);

  Expect.equals(objectSize(0), copyOperations[0].bytesCopied);
  Expect.equals(
      arraySize(2) + 2 * objectSize(0), copyOperations[1].bytesCopied);
  Expect.equals(typedDataSize(11), copyOperations[2].bytesCopied);
}

List<ObjectCopyOperation> getCopyOperations(
    List<TimelineEvent> events, String isolateId) {
  final copyOperations = <ObjectCopyOperation>[];

  int startTs = null;
  int startTts = null;

  for (final e in events) {
    if (e.isolateId != isolateId) continue;
    if (e.name != 'CopyMutableObjectGraph') continue;

    if (startTts != null) {
      if (!e.isEnd) throw 'Missing end of copy event';

      final us = e.ts - startTs;
      final threadUs = e.tts - startTts;
      copyOperations.add(ObjectCopyOperation(
          us,
          threadUs,
          int.parse(e.args['AllocatedBytes']),
          int.parse(e.args['CopiedObjects'])));

      startTs = null;
      startTts = null;
      continue;
    }

    if (!e.isStart) throw 'Expected end of copy event';
    startTs = e.ts;
    startTts = e.tts;
  }
  return copyOperations;
}

class ObjectCopyOperation {
  final int us;
  final int threadUs;
  final int bytesCopied;
  final int objectsCopied;

  ObjectCopyOperation(
      this.us, this.threadUs, this.bytesCopied, this.objectsCopied);

  String toString() =>
      'ObjectCopyOperation($us, $threadUs, $bytesCopied, $objectsCopied)';
}
