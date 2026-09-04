// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

String localFile(String path) => Platform.script.resolve(path).toFilePath();

final SecurityContext serverContext = SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(
    localFile('certificates/server_key.pem'),
    password: 'dartdart',
  );

final SecurityContext clientContext = SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

Uint8List makePayload(int length) {
  final result = Uint8List(length);
  for (var i = 0; i < result.length; i++) {
    result[i] = (i * 31 + i ~/ 251) & 0xff;
  }
  return result;
}

int checksum(List<int> data) {
  var result = 0;
  for (final byte in data) {
    result = (result + byte) & 0x7fffffff;
  }
  return result;
}

class DelegatingRawSocket extends Stream<RawSocketEvent> implements RawSocket {
  final RawSocket socket;

  DelegatingRawSocket(this.socket);

  bool get readEventsEnabled => socket.readEventsEnabled;
  set readEventsEnabled(bool value) => socket.readEventsEnabled = value;

  bool get writeEventsEnabled => socket.writeEventsEnabled;
  set writeEventsEnabled(bool value) => socket.writeEventsEnabled = value;

  int available() => socket.available();
  Uint8List? read([int? len]) => socket.read(len);
  SocketMessage? readMessage([int? count]) => socket.readMessage(count);
  int write(List<int> buffer, [int offset = 0, int? count]) =>
      socket.write(buffer, offset, count);
  int sendMessage(
    List<SocketControlMessage> controlMessages,
    List<int> data, [
    int offset = 0,
    int? count,
  ]) => socket.sendMessage(controlMessages, data, offset, count);

  int get port => socket.port;
  int get remotePort => socket.remotePort;
  InternetAddress get address => socket.address;
  InternetAddress get remoteAddress => socket.remoteAddress;

  Future<RawSocket> close() async {
    await socket.close();
    return this;
  }

  void shutdown(SocketDirection direction) => socket.shutdown(direction);
  bool setOption(SocketOption option, bool enabled) =>
      socket.setOption(option, enabled);
  Uint8List getRawOption(RawSocketOption option) => socket.getRawOption(option);
  void setRawOption(RawSocketOption option) => socket.setRawOption(option);

  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => socket.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class SynchronousErrorRawSocket extends DelegatingRawSocket {
  Function? _onError;
  bool _errorSent = false;

  SynchronousErrorRawSocket(super.socket);

  void _sendSynchronousError() {
    if (_errorSent) return;
    _errorSent = true;
    final handler = _onError;
    if (handler != null) {
      Function.apply(handler, [
        const SocketException('Synchronous transport failure'),
        StackTrace.current,
      ]);
    }
  }

  @override
  Uint8List? read([int? len]) {
    _sendSynchronousError();
    return null;
  }

  @override
  int write(List<int> buffer, [int offset = 0, int? count]) {
    _sendSynchronousError();
    return 0;
  }

  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onError = onError;
    return super.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class BlockNextWriteRawSocket extends DelegatingRawSocket {
  bool blockNextWrite = false;

  BlockNextWriteRawSocket(super.socket);

  @override
  int write(List<int> buffer, [int offset = 0, int? count]) {
    if (blockNextWrite) {
      blockNextWrite = false;
      return 0;
    }
    return super.write(buffer, offset, count);
  }
}

class InvalidCountRawSocket extends DelegatingRawSocket {
  final bool invalidRead;

  InvalidCountRawSocket(super.socket, {required this.invalidRead});

  @override
  Uint8List? read([int? len]) {
    if (invalidRead) return Uint8List((len ?? 1) + 1);
    return super.read(len);
  }

  @override
  int write(List<int> buffer, [int offset = 0, int? count]) {
    if (!invalidRead) return (count ?? buffer.length - offset) + 1;
    return super.write(buffer, offset, count);
  }
}

class ReentrantWriteRawSocket extends DelegatingRawSocket {
  RawSecureSocket? secureSocket;
  Uint8List? reentrantData;
  int? reentrantResult;

  ReentrantWriteRawSocket(super.socket);

  void arm(RawSecureSocket socket, Uint8List data) {
    secureSocket = socket;
    reentrantData = data;
  }

  @override
  int write(List<int> buffer, [int offset = 0, int? count]) {
    final socket = secureSocket;
    final data = reentrantData;
    if (socket != null && data != null) {
      secureSocket = null;
      reentrantData = null;
      reentrantResult = socket.write(data);
    }
    return super.write(buffer, offset, count);
  }
}

Future<(int, int)> consume(Stream<List<int>> stream) async {
  var length = 0;
  var sum = 0;
  await for (final data in stream) {
    length += data.length;
    sum = (sum + checksum(data)) & 0x7fffffff;
  }
  return (length, sum);
}

Future<ServerSocket> bindServer() =>
    ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

Future<void> testSlowReceiverBackpressure(Uint8List payload) async {
  final received = Completer<(int, int)>();
  final serverDone = Completer<void>();
  final server = await bindServer();
  final serverSubscription = server.listen((socket) async {
    try {
      final secureSocket = await SecureSocket.secureServer(
        socket,
        serverContext,
        bufferedData: const [],
      );
      // Let the sender fill its bounded plaintext queue before consuming.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      received.complete(await consume(secureSocket));
      await secureSocket.close();
      serverDone.complete();
    } catch (error, stackTrace) {
      if (!received.isCompleted) {
        received.completeError(error, stackTrace);
      }
      if (!serverDone.isCompleted) {
        serverDone.completeError(error, stackTrace);
      }
    }
  });

  final client = await SecureSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
    context: clientContext,
  );
  client.add(payload);
  await client.flush();
  await client.close();

  final result = await received.future;
  client.destroy();
  Expect.equals(payload.length, result.$1);
  Expect.equals(checksum(payload), result.$2);
  await serverDone.future;
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testFullPlaintextRingBackpressure(int payloadLength) async {
  const chunkCount = 2048;
  final payload = makePayload(payloadLength);
  final received = Completer<(int, int)>();
  final serverDone = Completer<void>();
  final server = await bindServer();
  final serverSubscription = server.listen((socket) async {
    try {
      final secureSocket = await SecureSocket.secureServer(
        socket,
        serverContext,
        bufferedData: const [],
      );
      // Force the sender through non-blocking socket backpressure after each
      // write has exactly filled the current plaintext ring.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      received.complete(await consume(secureSocket));
      await secureSocket.close();
      serverDone.complete();
    } catch (error, stackTrace) {
      if (!received.isCompleted) {
        received.completeError(error, stackTrace);
      }
      if (!serverDone.isCompleted) {
        serverDone.completeError(error, stackTrace);
      }
    }
  });

  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final client = await RawSecureSocket.secure(
    rawClient,
    context: clientContext,
  );
  final writesDone = Completer<void>();
  var payloadOffset = 0;
  var chunksWritten = 0;
  var firstWrite = true;
  late final StreamSubscription<RawSocketEvent> clientSubscription;
  clientSubscription = client.listen(
    (event) {
      if (event == RawSocketEvent.read) {
        while (client.read() != null) {}
        client.readEventsEnabled = true;
        return;
      }
      if (event != RawSocketEvent.write || writesDone.isCompleted) return;
      try {
        // One RawSecureSocket.write call per event is part of the regression:
        // the call exactly fills the ring without bypassing backpressure.
        final written = client.write(
          payload,
          payloadOffset,
          payload.length - payloadOffset,
        );
        if (firstWrite) {
          // A 16 KiB write first advances the 1 KiB ring to the intermediate
          // 4 KiB class; a later writable event advances it to 16 KiB.
          Expect.equals(
            payload.length > 4 * 1024 ? 4 * 1024 : payload.length,
            written,
          );
          firstWrite = false;
        }
        payloadOffset += written;
        if (payloadOffset == payload.length) {
          payloadOffset = 0;
          chunksWritten++;
        }
        if (chunksWritten == chunkCount) {
          client.writeEventsEnabled = false;
          client.shutdown(SocketDirection.send);
          writesDone.complete();
        } else {
          client.writeEventsEnabled = true;
        }
      } catch (error, stackTrace) {
        writesDone.completeError(error, stackTrace);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!writesDone.isCompleted) {
        writesDone.completeError(error, stackTrace);
      }
    },
  );
  client.readEventsEnabled = true;
  client.writeEventsEnabled = true;

  await writesDone.future.timeout(const Duration(seconds: 30));
  final result = await received.future.timeout(const Duration(seconds: 30));
  Expect.equals(payload.length * chunkCount, result.$1);
  Expect.equals((checksum(payload) * chunkCount) & 0x7fffffff, result.$2);

  await serverDone.future;
  await client.close();
  await clientSubscription.cancel();
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testServerFullPlaintextRingBackpressure(int payloadLength) async {
  const chunkCount = 2048;
  final payload = makePayload(payloadLength);
  final server = await RawSecureServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
    serverContext,
  );
  final serverConnection = server.first;
  final client = await SecureSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
    context: clientContext,
  );
  final secureServer = await serverConnection;
  await server.close();

  final writesDone = Completer<void>();
  var payloadOffset = 0;
  var chunksWritten = 0;
  var firstWrite = true;
  late final StreamSubscription<RawSocketEvent> serverSubscription;
  serverSubscription = secureServer.listen(
    (event) {
      if (event == RawSocketEvent.read) {
        while (secureServer.read() != null) {}
        secureServer.readEventsEnabled = true;
        return;
      }
      if (event != RawSocketEvent.write || writesDone.isCompleted) return;
      try {
        final written = secureServer.write(
          payload,
          payloadOffset,
          payload.length - payloadOffset,
        );
        if (firstWrite) {
          Expect.equals(
            payload.length > 4 * 1024 ? 4 * 1024 : payload.length,
            written,
          );
          firstWrite = false;
        }
        payloadOffset += written;
        if (payloadOffset == payload.length) {
          payloadOffset = 0;
          chunksWritten++;
        }
        if (chunksWritten == chunkCount) {
          secureServer.writeEventsEnabled = false;
          secureServer.shutdown(SocketDirection.send);
          writesDone.complete();
        } else {
          secureServer.writeEventsEnabled = true;
        }
      } catch (error, stackTrace) {
        writesDone.completeError(error, stackTrace);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!writesDone.isCompleted) {
        writesDone.completeError(error, stackTrace);
      }
    },
  );
  secureServer.readEventsEnabled = true;
  secureServer.writeEventsEnabled = true;

  // Match the benchmark's server-side encode path while forcing transport
  // backpressure independently of machine speed.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final received = consume(client);
  await writesDone.future.timeout(const Duration(seconds: 30));
  final result = await received.timeout(const Duration(seconds: 30));
  Expect.equals(payload.length * chunkCount, result.$1);
  Expect.equals((checksum(payload) * chunkCount) & 0x7fffffff, result.$2);

  await client.close();
  client.destroy();
  await secureServer.close();
  await serverSubscription.cancel();
}

Future<void> testPublicRawSocketImplementation(Uint8List payload) async {
  final server = await bindServer();
  final serverConnection = server.first;
  final secureServerConnection = serverConnection.then(
    (socket) => SecureSocket.secureServer(
      socket,
      serverContext,
      bufferedData: const [],
    ),
  );
  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final client = await RawSecureSocket.secure(
    DelegatingRawSocket(rawClient),
    context: clientContext,
  );
  final serverClient = await secureServerConnection;

  final received = BytesBuilder(copy: false);
  final readClosed = Completer<void>();
  final clientSubscription = client.listen((event) {
    if (event == RawSocketEvent.read) {
      while (true) {
        final data = client.read();
        if (data == null) break;
        received.add(data);
      }
    } else if (event == RawSocketEvent.readClosed) {
      if (!readClosed.isCompleted) readClosed.complete();
    }
  });

  serverClient.add(payload);
  await serverClient.flush();
  await serverClient.close();
  serverClient.destroy();
  await readClosed.future;

  final result = received.takeBytes();
  Expect.equals(payload.length, result.length);
  Expect.equals(checksum(payload), checksum(result));

  await client.close();
  await clientSubscription.cancel();
  await server.close();
}

Future<void> testNestedSecureSocketCleanReadClose() async {
  const payload = [1, 2, 3, 4];
  final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final secureServerConnection = Completer<RawSecureSocket>();
  final serverSubscription = server.listen((rawSocket) async {
    try {
      final inner = await RawSecureSocket.secureServer(
        rawSocket,
        serverContext,
        bufferedData: const [],
      );
      final outer = await RawSecureSocket.secureServer(
        inner,
        serverContext,
        bufferedData: const [],
      );
      secureServerConnection.complete(outer);
      Expect.equals(payload.length, outer.write(payload));
      outer.shutdown(SocketDirection.send);
    } catch (error, stackTrace) {
      if (!secureServerConnection.isCompleted) {
        secureServerConnection.completeError(error, stackTrace);
      }
    }
  });

  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final innerClient = await RawSecureSocket.secure(
    rawClient,
    context: clientContext,
  );
  final outerClient = await RawSecureSocket.secure(
    innerClient,
    context: clientContext,
  );
  final outerServer = await secureServerConnection.future;

  final received = BytesBuilder(copy: false);
  final readClosed = Completer<void>();
  Object? streamError;
  final clientSubscription = outerClient.listen(
    (event) {
      if (event == RawSocketEvent.read) {
        while (true) {
          final data = outerClient.read();
          if (data == null) break;
          received.add(data);
        }
      } else if (event == RawSocketEvent.readClosed) {
        if (!readClosed.isCompleted) readClosed.complete();
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      streamError = error;
      if (!readClosed.isCompleted) readClosed.complete();
    },
  );
  outerClient.readEventsEnabled = true;

  await readClosed.future.timeout(const Duration(seconds: 10));
  Expect.isNull(streamError);
  Expect.listEquals(payload, received.takeBytes());

  await outerClient.close();
  await outerServer.close();
  await clientSubscription.cancel();
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testGrowDuringWriteRetry() async {
  final received = Completer<(int, int)>();
  final server = await bindServer();
  final serverSubscription = server.listen((socket) async {
    try {
      final secureSocket = await SecureSocket.secureServer(
        socket,
        serverContext,
        bufferedData: const [],
      );
      received.complete(await consume(secureSocket));
      await secureSocket.close();
    } catch (error, stackTrace) {
      if (!received.isCompleted) {
        received.completeError(error, stackTrace);
      }
    }
  });

  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final transport = BlockNextWriteRawSocket(rawClient);
  final client = await RawSecureSocket.secure(
    transport,
    context: clientContext,
  );
  final clientSubscription = client.listen((event) {
    if (event == RawSocketEvent.read) {
      while (client.read() != null) {}
    }
  });

  final first = makePayload(2 * 1024);
  final second = makePayload(4 * 1024);
  transport.blockNextWrite = true;
  Expect.equals(first.length, client.write(first));
  // The first SSL_write is now waiting on its transport. This write grows the
  // plaintext backing allocation and retries with the original bytes as an
  // unchanged prefix at a different address.
  Expect.equals(second.length, client.write(second));
  client.shutdown(SocketDirection.send);

  final result = await received.future.timeout(const Duration(seconds: 30));
  Expect.equals(first.length + second.length, result.$1);
  Expect.equals((checksum(first) + checksum(second)) & 0x7fffffff, result.$2);

  await client.close();
  await clientSubscription.cancel();
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testReentrantFallbackWriteIsBackpressured() async {
  final received = Completer<(int, int)>();
  final server = await bindServer();
  final serverSubscription = server.listen((socket) async {
    try {
      final secureSocket = await SecureSocket.secureServer(
        socket,
        serverContext,
        bufferedData: const [],
      );
      received.complete(await consume(secureSocket));
      await secureSocket.close();
    } catch (error, stackTrace) {
      if (!received.isCompleted) {
        received.completeError(error, stackTrace);
      }
    }
  });

  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final transport = ReentrantWriteRawSocket(rawClient);
  final client = await RawSecureSocket.secure(
    transport,
    context: clientContext,
  );
  Completer<void>? writeReady;
  final clientSubscription = client.listen((event) {
    if (event == RawSocketEvent.read) {
      while (client.read() != null) {}
    } else if (event == RawSocketEvent.write) {
      final ready = writeReady;
      if (ready != null && !ready.isCompleted) ready.complete();
    }
  });

  final first = makePayload(512);
  final reentrant = makePayload(8 * 1024);
  transport.arm(client, reentrant);
  Expect.equals(first.length, client.write(first));
  // The transport callback runs inside SSL_write. The nested write must not
  // replace or mutate the plaintext backing passed to that native call.
  Expect.equals(0, transport.reentrantResult);
  var reentrantOffset = client.write(reentrant);
  Expect.isTrue(reentrantOffset > 0);
  while (reentrantOffset < reentrant.length) {
    final written = client.write(
      reentrant,
      reentrantOffset,
      reentrant.length - reentrantOffset,
    );
    if (written > 0) {
      reentrantOffset += written;
      continue;
    }
    writeReady = Completer<void>();
    client.writeEventsEnabled = true;
    await writeReady!.future.timeout(const Duration(seconds: 10));
    writeReady = null;
  }
  client.shutdown(SocketDirection.send);

  final result = await received.future.timeout(const Duration(seconds: 30));
  Expect.equals(first.length + reentrant.length, result.$1);
  Expect.equals(
    (checksum(first) + checksum(reentrant)) & 0x7fffffff,
    result.$2,
  );

  await client.close();
  await clientSubscription.cancel();
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testUpgradeAfterNativeReadClosed() async {
  final server = await bindServer();
  final serverClosed = server.first.then((socket) => socket.close());
  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final readClosed = Completer<void>();
  final subscription = rawClient.listen((event) {
    if (event == RawSocketEvent.readClosed && !readClosed.isCompleted) {
      readClosed.complete();
    }
  });
  await readClosed.future;

  Object? handshakeError;
  try {
    await RawSecureSocket.secure(
      rawClient,
      subscription: subscription,
      context: clientContext,
    );
  } catch (error) {
    handshakeError = error;
  }
  Expect.isTrue(handshakeError is HandshakeException);

  await rawClient.close();
  await subscription.cancel();
  final closedServerClient = await serverClosed;
  closedServerClient.destroy();
  await server.close();
}

Future<void> testSynchronousFallbackTransportError() async {
  final server = await bindServer();
  final serverConnection = server.first;
  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final serverClient = await serverConnection;

  Object? handshakeError;
  try {
    await RawSecureSocket.secure(
      SynchronousErrorRawSocket(rawClient),
      context: clientContext,
    );
  } catch (error) {
    handshakeError = error;
  }
  Expect.isTrue(handshakeError is SocketException);

  await rawClient.close();
  await serverClient.close();
  serverClient.destroy();
  await server.close();
}

Future<void> testConcurrentShortWriteHandshakeFailures() async {
  const connectionCount = 32;

  Future<void> runOne(int index) async {
    final server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      null,
    );
    final clientDone =
        SecureSocket.connect(
          InternetAddress.loopbackIPv4,
          server.port,
          context: clientContext,
        ).then<void>(
          (socket) {
            socket.destroy();
            Expect.fail('Client $index unexpectedly completed its handshake');
          },
          onError: (Object error, StackTrace stackTrace) {
            Expect.isTrue(
              error is HandshakeException || error is SocketException,
            );
          },
        );
    final serverDone = Completer<void>();
    final subscription = server.listen(
      (socket) {
        socket.destroy();
        if (!serverDone.isCompleted) {
          serverDone.completeError(
            StateError('Server $index unexpectedly completed its handshake'),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) async {
        if (serverDone.isCompleted) return;
        try {
          Expect.isTrue(
            error is HandshakeException || error is SocketException,
          );
          await clientDone;
          await server.close();
          serverDone.complete();
        } catch (error, stackTrace) {
          serverDone.completeError(error, stackTrace);
        }
      },
      cancelOnError: false,
    );

    try {
      await serverDone.future.timeout(const Duration(seconds: 10));
    } finally {
      await server.close();
      await subscription.cancel();
    }
  }

  // Forced short writes can complete without leaving an OS write pending. In
  // that case the TLS state machine must retry from the reported byte progress
  // instead of waiting for a transport event which is not guaranteed to fire.
  await Future.wait([
    for (var index = 0; index < connectionCount; index++) runOne(index),
  ]).timeout(const Duration(seconds: 30));
}

Future<void> testFallbackTransportRejectsInvalidCounts() async {
  Future<Object> connectWithInvalidTransport({
    required bool invalidRead,
  }) async {
    final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = server.first;
    final rawClient = await RawSocket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );
    final serverClient = await accepted;
    final transport = InvalidCountRawSocket(
      rawClient,
      invalidRead: invalidRead,
    );
    if (invalidRead) {
      Expect.equals(1, serverClient.write(const [0]));
    }

    Object? handshakeError;
    try {
      await RawSecureSocket.secure(
        transport,
        context: clientContext,
      ).timeout(const Duration(seconds: 5));
    } catch (error) {
      handshakeError = error;
    }
    await transport.close();
    await serverClient.close();
    await server.close();
    return handshakeError ?? StateError('Invalid transport count was accepted');
  }

  final invalidWrite = await connectWithInvalidTransport(invalidRead: false);
  Expect.isTrue(invalidWrite is ArgumentError);
  Expect.isTrue(invalidWrite.toString().contains('invalid byte count'));
  final invalidRead = await connectWithInvalidTransport(invalidRead: true);
  Expect.isTrue(invalidRead is ArgumentError);
  Expect.isTrue(invalidRead.toString().contains('invalid byte count'));
}

Future<void> testNativeDescriptorLifetimeAcrossGC() async {
  // Regression test: On Windows and Fuchsia, fd is a pointer to a heap Handle*
  // object. If RawSecureSocket secures a RawSocket and the original Dart
  // RawSocket object is garbage-collected while TLS operations are active, the
  // native Handle* must not be deleted prematurely.
  final server = await bindServer();
  final serverDone = Completer<void>();
  final payload = makePayload(64 * 1024);

  final serverSubscription = server.listen((socket) async {
    try {
      final secureServer = await SecureSocket.secureServer(
        socket,
        serverContext,
        bufferedData: const [],
      );
      final received = await consume(secureServer);
      Expect.equals(payload.length, received.$1);
      Expect.equals(checksum(payload), received.$2);
      await secureServer.close();
      serverDone.complete();
    } catch (error, stackTrace) {
      if (!serverDone.isCompleted) {
        serverDone.completeError(error, stackTrace);
      }
    }
  });

  // Secure client in a scope and drop all references to the underlying Socket.
  SecureSocket? secureClient;
  {
    final plainClient = await Socket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );
    secureClient = await SecureSocket.secure(
      plainClient,
      context: clientContext,
    );
  }

  // Force memory allocation to trigger GC cycles while the secure socket is active.
  for (var i = 0; i < 5; i++) {
    Uint8List(8 * 1024 * 1024);
  }

  secureClient.add(payload);
  await secureClient.flush();
  await secureClient.close();

  await serverDone.future.timeout(const Duration(seconds: 15));
  secureClient.destroy();
  await server.close();
  await serverSubscription.cancel();
}

Future<void> testAbruptDisconnectDuringHandshakeAndTransfer() async {
  // Regression test: When a peer abruptly disconnects or aborts during TLS
  // handshake or I/O, OS error codes (WSAECONNRESET, ERROR_OPERATION_ABORTED,
  // ECONNRESET, etc.) must not crash the BoringSSL custom socket BIO or abort
  // the VM. Instead, stream events or Socket/Handshake exceptions must be
  // delivered gracefully.
  final server = await bindServer();
  final serverSubscription = server.listen((socket) async {
    // Abruptly destroy the socket immediately after accepting.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    socket.destroy();
  });

  for (var i = 0; i < 8; i++) {
    try {
      final client = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
        context: clientContext,
        timeout: const Duration(seconds: 5),
      );
      client.destroy();
    } catch (e) {
      Expect.isTrue(
        e is SocketException ||
            e is HandshakeException ||
            e is TimeoutException,
      );
    }
  }

  await server.close();
  await serverSubscription.cancel();
}

Future<void> testUpgradeAfterCustomSocketReadClosed() async {
  // Regression test: A non-native custom RawSocket (such as DelegatingRawSocket
  // or a custom stream wrapper) upgraded to TLS with an existing subscription
  // that already consumed the readClosed event must detect the closed state
  // and fail the handshake gracefully with HandshakeException instead of
  // hanging indefinitely.
  final server = await bindServer();
  final serverClosed = server.first.then((socket) => socket.close());
  final rawClient = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final customClient = DelegatingRawSocket(rawClient);
  final readClosed = Completer<void>();
  final subscription = customClient.listen((event) {
    if (event == RawSocketEvent.readClosed && !readClosed.isCompleted) {
      readClosed.complete();
    }
  });
  await readClosed.future;

  Object? handshakeError;
  try {
    await RawSecureSocket.secure(
      customClient,
      subscription: subscription,
      context: clientContext,
    ).timeout(const Duration(seconds: 5));
  } catch (error) {
    handshakeError = error;
  }
  Expect.isTrue(handshakeError is HandshakeException);

  await customClient.close();
  await subscription.cancel();
  final closedServerClient = await serverClosed;
  closedServerClient.destroy();
  await server.close();
}

Future<void> main() async {
  await testConcurrentShortWriteHandshakeFailures();
  await testFallbackTransportRejectsInvalidCounts();
  await testNativeDescriptorLifetimeAcrossGC();
  await testAbruptDisconnectDuringHandshakeAndTransfer();
  // This is hundreds of times larger than the initial 1 KiB plaintext rings
  // and exercises growth and repeated wraparound without encrypted staging.
  final payload = makePayload(2 * 1024 * 1024 + 257);
  await testSlowReceiverBackpressure(payload);
  // A ring reserves one byte to distinguish full from empty, so these are the
  // exact usable capacities of the 1, 4, and 16 KiB backings.
  for (final payloadLength in const [1 * 1024, 4 * 1024, 16 * 1024]) {
    await testFullPlaintextRingBackpressure(payloadLength);
    await testServerFullPlaintextRingBackpressure(payloadLength);
  }
  await testPublicRawSocketImplementation(payload.sublist(0, 64 * 1024 + 17));
  await testNestedSecureSocketCleanReadClose();
  await testGrowDuringWriteRetry();
  await testReentrantFallbackWriteIsBackpressured();
  await testUpgradeAfterNativeReadClosed();
  await testUpgradeAfterCustomSocketReadClosed();
  await testSynchronousFallbackTransportError();
}
