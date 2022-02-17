// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart';

import '../executor/message_grouper.dart';
import '../executor/multi_executor.dart';
import '../executor/executor_base.dart';
import '../executor/serialization.dart';
import '../executor.dart';

/// Returns a [MacroExecutor] which loads macros as separate processes using
/// precompiled binaries and communicates with that program using
/// [serializationMode].
///
/// The [serializationMode] must be a `server` variant, and any precompiled
/// programs spawned must use the corresponding `client` variant.
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start(SerializationMode serializationMode) async =>
    new MultiMacroExecutor((Uri library, String name,
        {Uri? precompiledKernelUri}) {
      if (precompiledKernelUri == null) {
        throw new UnsupportedError(
            'This environment requires a non-null `precompiledKernelUri` to be '
            'passed when loading macros.');
      }

      // TODO: We actually assume this is a full precompiled AOT binary, and not
      // a kernel file. We launch it directly using `Process.start`.
      return _SingleProcessMacroExecutor.start(
          library, name, serializationMode, precompiledKernelUri.toFilePath());
    });

/// Actual implementation of the separate process based macro executor.
class _SingleProcessMacroExecutor extends ExternalMacroExecutorBase {
  /// The IOSink that writes to stdin of the external process.
  final IOSink outSink;

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() onClose;

  _SingleProcessMacroExecutor(
      {required Stream<Object> messageStream,
      required this.onClose,
      required this.outSink,
      required SerializationMode serializationMode})
      : super(
            messageStream: messageStream, serializationMode: serializationMode);

  static Future<_SingleProcessMacroExecutor> start(Uri library, String name,
      SerializationMode serializationMode, String programPath) async {
    Process process = await Process.start(programPath, []);
    process.stderr
        .transform(const Utf8Decoder())
        .listen((content) => throw new RemoteException(content));

    Stream<Object> messageStream;

    if (serializationMode == SerializationMode.byteDataServer) {
      messageStream = new MessageGrouper(process.stdout).messageStream;
    } else if (serializationMode == SerializationMode.jsonServer) {
      messageStream = process.stdout
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line)!);
    } else {
      throw new UnsupportedError(
          'Unsupported serialization mode \$serializationMode for '
          'ProcessExecutor');
    }

    return new _SingleProcessMacroExecutor(
        onClose: () {
          process.kill();
        },
        messageStream: messageStream,
        outSink: process.stdin,
        serializationMode: serializationMode);
  }

  @override
  void close() => onClose();

  /// Sends the [Serializer.result] to [stdin].
  ///
  /// Json results are serialized to a `String`, and separated by newlines.
  void sendResult(Serializer serializer) {
    if (serializationMode == SerializationMode.jsonServer) {
      outSink.writeln(jsonEncode(serializer.result));
    } else if (serializationMode == SerializationMode.byteDataServer) {
      Uint8List result = (serializer as ByteDataSerializer).result;
      int length = result.lengthInBytes;
      if (length > 0xffffffff) {
        throw new StateError('Message was larger than the allowed size!');
      }
      outSink.add([
        length >> 24 & 0xff,
        length >> 16 & 0xff,
        length >> 8 & 0xff,
        length & 0xff
      ]);
      outSink.add(result);
    } else {
      throw new UnsupportedError(
          'Unsupported serialization mode $serializationMode for '
          'ProcessExecutor');
    }
  }
}
