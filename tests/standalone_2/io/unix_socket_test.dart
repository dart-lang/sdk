// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';

import 'test_utils.dart' show withTempDir;

Future testAddress(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var server = await ServerSocket.bind(address, 0);

  var client = await Socket.connect(address, server.port);
  var completer = Completer<void>();
  server.listen((socket) async {
    Expect.equals(socket.port, 0);
    Expect.equals(socket.port, server.port);
    Expect.equals(client.port, socket.remotePort);
    Expect.equals(client.remotePort, socket.port);

    // Client has not bound to a path. This is an unnamed socket.
    Expect.equals(socket.remoteAddress.toString(), "InternetAddress('', Unix)");
    Expect.equals(client.remoteAddress.toString(), address.toString());
    socket.destroy();
    client.destroy();
    await server.close();
    completer.complete();
  });
  await completer.future;
}

testBindShared(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var socket = await ServerSocket.bind(address, 0, shared: true);
  Expect.isTrue(socket.port == 0);

  // Same path
  var socket2 = await ServerSocket.bind(address, 0, shared: true);
  Expect.equals(socket.address.address, socket2.address.address);
  Expect.equals(socket.port, socket2.port);

  // Test relative path
  var path = name.substring(name.lastIndexOf('/') + 1);
  address = InternetAddress('${name}/../${path}/sock',
      type: InternetAddressType.unix);

  var socket3 = await ServerSocket.bind(address, 0, shared: true);
  Expect.isTrue(FileSystemEntity.identicalSync(
      socket.address.address, socket3.address.address));
  Expect.equals(socket.port, socket2.port);
  await socket.close();
  await socket2.close();
  await socket3.close();
}

testBind(String name) async {
  final address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  final server = await ServerSocket.bind(address, 0, shared: false);
  Expect.isTrue(server.address.toString().contains(name));
  // Unix domain socket does not have a valid port number.
  Expect.equals(server.port, 0);

  final serverContinue = Completer();
  final clientContinue = Completer();
  server.listen((s) async {
    await serverContinue.future;
    clientContinue.complete();
  });

  final socket = await Socket.connect(address, server.port);
  socket.write(" socket content");
  serverContinue.complete();
  await clientContinue.future;

  socket.destroy();
  await server.close();
}

Future testListenCloseListenClose(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  ServerSocket socket = await ServerSocket.bind(address, 0, shared: true);
  ServerSocket socket2 =
      await ServerSocket.bind(address, socket.port, shared: true);

  // The second socket should have kept the OS socket alive. We can therefore
  // test if it is working correctly.
  await socket.close();

  // For robustness we ignore any clients unrelated to this test.
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  socket2.listen((Socket client) async {
    client.add(sendData);
    await Future.wait([client.drain(), client.close()]);
  });

  final client = await Socket.connect(address, socket2.port);
  List<int> data = [];
  var completer = Completer<void>();
  client.listen(data.addAll, onDone: () {
    Expect.listEquals(sendData, data);
    completer.complete();
  });
  await completer.future;
  await client.close();

  // Close the second server socket.
  await socket2.close();
}

Future testSourceAddressConnect(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  ServerSocket server = await ServerSocket.bind(address, 0);

  var completer = Completer<void>();
  var localAddress =
      InternetAddress('$name/local', type: InternetAddressType.unix);
  server.listen((Socket socket) async {
    Expect.equals(socket.address.address, address.address);
    Expect.equals(socket.remoteAddress.address, localAddress.address);
    socket.drain();
    socket.close();
    completer.complete();
  });

  Socket client =
      await Socket.connect(address, server.port, sourceAddress: localAddress);
  Expect.equals(client.remoteAddress.address, address.address);
  await completer.future;
  await client.close();
  await client.drain();
  await server.close();
}

Future testAbstractAddress(String uniqueName) async {
  if (!Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  var serverAddress =
      InternetAddress('@temp.sock.$uniqueName', type: InternetAddressType.unix);
  ServerSocket server = await ServerSocket.bind(serverAddress, 0);
  final completer = Completer<void>();
  final content = 'random string';
  server.listen((Socket socket) {
    socket.listen((data) {
      Expect.equals(content, utf8.decode(data));
      socket.close();
      server.close();
      completer.complete();
    });
  });

  Socket client = await Socket.connect(serverAddress, 0);
  client.write(content);
  await client.drain();
  await client.close();
  await completer.future;
}

String getAbstractSocketTestFileName() {
  var executable = Platform.executable;
  var dirIndex = executable.lastIndexOf('dart');
  var buffer = new StringBuffer(executable.substring(0, dirIndex));
  buffer.write('abstract_socket_test');
  return buffer.toString();
}

Future testShortAbstractAddress(String uniqueName) async {
  if (!Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  var retries = 10;
  var retryDelay = const Duration(seconds: 1);
  Process process;
  var stdoutFuture;
  var stderrFuture;
  try {
    var socketAddress = '@temp.sock.$uniqueName';
    var abstractSocketServer = getAbstractSocketTestFileName();
    // check if the executable exists, some build configurations do not
    // build it (e.g: precompiled simarm/simarm64)
    if (!File(abstractSocketServer).existsSync()) {
      return;
    }

    // Start up a subprocess that listens on [socketAddress].
    process = await Process.start(abstractSocketServer, [socketAddress]);
    stdoutFuture = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(stdout.write)
        .asFuture(null);
    stderrFuture = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(stderr.write)
        .asFuture(null);
    var serverAddress =
        InternetAddress(socketAddress, type: InternetAddressType.unix);

    // The subprocess may take some time to start, so retry setting up the
    // connection a few times.
    Socket client;
    while (true) {
      try {
        client = await Socket.connect(serverAddress, 0);
        break;
      } catch (e, st) {
        if (retries <= 0) {
          rethrow;
        }
        retries--;
      }
      await Future.delayed(retryDelay);
    }

    List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    List<int> data = [];
    var completer = Completer<void>();
    client.listen(data.addAll, onDone: () {
      Expect.listEquals(sendData, data);
      completer.complete();
    });
    client.add(sendData);
    await client.close();
    await completer.future;
    client.destroy();
    var exitCode = await process.exitCode;
    process = null;
    Expect.equals(exitCode, 0);
  } catch (e, st) {
    Expect.fail('Failed with exception:\n$e\n$st');
  } finally {
    process?.kill(ProcessSignal.sigkill);
    await stdoutFuture;
    await stderrFuture;
    await process?.exitCode;
  }
}

Future testExistingFile(String name) async {
  // Test that a leftover file(In case of previous process being killed and
  // finalizer doesn't clean up the file) will be cleaned up and bind() should
  // be able to bind to the socket.
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  // Create a file with the same name
  File(address.address).createSync();
  try {
    ServerSocket server = await ServerSocket.bind(address, 0);
    server.close();
  } catch (e) {
    Expect.type<SocketException>(e);
    return;
  }
  Expect.fail("bind should fail with existing file");
}

Future testSetSockOpt(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var server = await ServerSocket.bind(address, 0, shared: false);

  var sub;
  sub = server.listen((s) {
    sub.cancel();
    server.close();
  });

  var socket = await Socket.connect(address, server.port);
  socket.write(" socket content");

  // Get some socket options.
  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelTcp, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelUdp, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelIPv4, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelIPv6, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelSocket, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Protocol not available'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option = RawSocketOption.fromBool(
          RawSocketOption.IPv4MulticastInterface, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option = RawSocketOption.fromBool(
          RawSocketOption.IPv6MulticastInterface, i, false);
      var result = socket.getRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  // Set some socket options
  try {
    socket.setOption(SocketOption.tcpNoDelay, true);
  } catch (e) {
    Expect.isTrue(e.toString().contains('Operation not supported'));
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelTcp, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelUdp, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelIPv4, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelIPv6, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option =
          RawSocketOption.fromBool(RawSocketOption.levelSocket, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Protocol not available'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option = RawSocketOption.fromBool(
          RawSocketOption.IPv4MulticastInterface, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  for (int i = 0; i < 5; i++) {
    try {
      RawSocketOption option = RawSocketOption.fromBool(
          RawSocketOption.IPv6MulticastInterface, i, false);
      var result = socket.setRawOption(option);
    } catch (e) {
      Expect.isTrue(e.toString().contains('Operation not supported'));
    }
  }

  socket.destroy();
  await server.close();
}

Future testHttpServer(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var httpServer = await HttpServer.bind(address, 0);

  var sub;
  sub = httpServer.listen((s) {
    sub.cancel();
    httpServer.close();
  });

  var socket = await Socket.connect(address, httpServer.port);

  socket.destroy();
  await httpServer.close();
}

Future testFileMessage(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }

  final firstMessageReceived = Completer<void>();
  final completer = Completer<bool>();

  final address =
      InternetAddress('$tempDirPath/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    print('server started a socket $socket');
    socket.listen((e) {
      if (e == RawSocketEvent.read) {
        final SocketMessage message = socket.readMessage();
        if (message == null) {
          return;
        }
        print('server received message $message');
        final String messageData = String.fromCharCodes(message.data);
        print('server received messageData $messageData');
        if (messageData == 'EmptyMessage') {
          Expect.equals('EmptyMessage'.length, message.data.length);
          Expect.isTrue(message.controlMessages.isEmpty);
          return;
        }
        Expect.equals('Hello', messageData);
        Expect.equals('Hello'.length, message.data.length);
        Expect.equals(1, message.controlMessages.length);
        final SocketControlMessage controlMessage = message.controlMessages[0];
        final handles = controlMessage.extractHandles();
        Expect.isNotNull(handles);
        Expect.equals(1, handles.length);
        final receivedFile = handles[0].toFile();
        receivedFile.writeStringSync('Hello, server!\n');
        print("server has written to the $receivedFile file");
        socket.write('abc'.codeUnits);
        firstMessageReceived.complete();
      } else if (e == RawSocketEvent.readClosed) {
        print('server socket got readClosed');
        socket.close();
        server.close();
      }
    });
  });

  final file = File('$tempDirPath/myfile.txt');
  final randomAccessFile = file.openSync(mode: FileMode.write);
  // Send a message with sample file.
  final socket = await RawSocket.connect(address, 0);
  socket.listen((e) async {
    if (e == RawSocketEvent.write) {
      randomAccessFile.writeStringSync('Hello, client!\n');
      socket.sendMessage(<SocketControlMessage>[
        SocketControlMessage.fromHandles(
            <ResourceHandle>[ResourceHandle.fromFile(randomAccessFile)])
      ], 'Hello'.codeUnits);
      await firstMessageReceived.future;
      print('client sent a message');
      socket.sendMessage(<SocketControlMessage>[], 'EmptyMessage'.codeUnits);
      print('client sent a message without control data');
    } else if (e == RawSocketEvent.read) {
      final data = socket.read();
      Expect.equals('abc', String.fromCharCodes(data));
      Expect.equals(
          'Hello, client!\nHello, server!\n', file.readAsStringSync());
      socket.close();
      completer.complete(true);
    }
  });

  return completer.future;
}

Future testTooLargeControlMessage(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final completer = Completer<bool>();
  final address =
      InternetAddress('$tempDirPath/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    print('server started a socket $socket');
    socket.listen((e) {
      if (e == RawSocketEvent.read) {
        throw "Server should not receive request from the client";
      } else if (e == RawSocketEvent.readClosed) {
        socket.close();
        server.close();
      }
    });
  });

  final file = File('$tempDirPath/myfile.txt');
  final randomAccessFile = file.openSync(mode: FileMode.write);
  // Send a message with sample file.
  final socket = await RawSocket.connect(address, 0);

  runZonedGuarded(
      () => socket.listen((e) {
            if (e == RawSocketEvent.write) {
              randomAccessFile.writeStringSync('Hello, client!\n');
              const int largeHandleCount = 1024;
              final manyResourceHandles = List<ResourceHandle>.filled(
                  largeHandleCount, ResourceHandle.fromFile(randomAccessFile));
              socket.sendMessage(<SocketControlMessage>[
                SocketControlMessage.fromHandles(manyResourceHandles)
              ], 'Hello'.codeUnits);
              server.close();
              socket.close();
            }
          }), (e, st) {
    // print('Got expected unhandled exception $e $st');
    Expect.equals(true, e is SocketException);
    completer.complete(true);
  });

  return completer.future;
}

Future testFileMessageWithShortRead(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }

  final completer = Completer<bool>();

  final address =
      InternetAddress('$tempDirPath/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    print('server started a socket $socket');
    socket.listen((e) {
      if (e == RawSocketEvent.read) {
        Expect.throws(
            () => socket.readMessage(0),
            (e) =>
                e is ArgumentError &&
                e.toString().contains('Illegal length 0'));
        final SocketMessage message = socket.readMessage(/*count=*/ 1);
        if (message == null) {
          return;
        }
        print('server received message $message');
        final String messageData = String.fromCharCodes(message.data);
        print('messageData: $messageData');
        if (messageData[0] == 'H') {
          Expect.equals(1, message.controlMessages.length);
          final SocketControlMessage controlMessage =
              message.controlMessages[0];
          final handles = controlMessage.extractHandles();
          Expect.isNotNull(handles);
          Expect.equals(1, handles.length);
          final handlesAgain = controlMessage.extractHandles();
          Expect.isNotNull(handlesAgain);
          Expect.equals(1, handlesAgain.length);
          handles[0].toFile().writeStringSync('Hello, server!\n');
          socket.write('abc'.codeUnits);
        } else {
          Expect.equals('i', messageData[0]);
          Expect.equals(0, message.controlMessages.length);
        }
      } else if (e == RawSocketEvent.readClosed) {
        print('server socket got readClosed');
        socket.close();
        server.close();
      }
    });
  });

  final file = File('$tempDirPath/myfile.txt');
  final randomAccessFile = file.openSync(mode: FileMode.write);
  // Send a message with sample file.
  final socket = await RawSocket.connect(address, 0);
  socket.listen((e) {
    if (e == RawSocketEvent.write) {
      randomAccessFile.writeStringSync('Hello, client!\n');
      socket.sendMessage(<SocketControlMessage>[
        SocketControlMessage.fromHandles(
            <ResourceHandle>[ResourceHandle.fromFile(randomAccessFile)])
      ], 'Hi'.codeUnits);
      print('client sent a message');
    } else if (e == RawSocketEvent.read) {
      final data = socket.read();
      Expect.equals('abc', String.fromCharCodes(data));
      Expect.equals(
          'Hello, client!\nHello, server!\n', file.readAsStringSync());
      socket.close();
      completer.complete(true);
    }
  });

  return completer.future;
}

Future<RawServerSocket> createTestServer() async {
  final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  return server
    ..listen((client) {
      String receivedData = "";

      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.read:
            assert(client.available() > 0);
            final buffer = client.read(200);
            receivedData += String.fromCharCodes(buffer);
            break;
          case RawSocketEvent.readClosed:
            client.close();
            server.close();
            break;
          case RawSocketEvent.closed:
            Expect.equals(
                "Hello, client 1!\nHello, client 2!\nHello, server!\n",
                receivedData);
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onError: (e) {
        print("client ERROR $e");
      });
    });
}

Future testSocketMessage(String uniqueName) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }

  final address =
      InternetAddress('$uniqueName/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    socket.listen((e) {
      switch (e) {
        case RawSocketEvent.read:
          final SocketMessage message = socket.readMessage();
          if (message == null) {
            return;
          }
          Expect.equals('Hello', String.fromCharCodes(message.data));
          Expect.equals(1, message.controlMessages.length);
          final SocketControlMessage controlMessage =
              message.controlMessages[0];
          final handles = controlMessage.extractHandles();
          Expect.isNotNull(handles);
          Expect.equals(1, handles.length);
          final receivedSocket = handles[0].toRawSocket();
          receivedSocket.write('Hello, server!\n'.codeUnits);
          socket.write('server replied'.codeUnits);
          receivedSocket.close();
          break;
        case RawSocketEvent.readClosed:
          socket.close();
          server.close();
          break;
      }
    });
  });

  final RawServerSocket testServer = await createTestServer();
  final testSocket = await RawSocket.connect("127.0.0.1", testServer.port);

  // Send a message with opened [testSocket] socket.
  final socket = await RawSocket.connect(address, 0);
  socket.listen((e) {
    switch (e) {
      case RawSocketEvent.write:
        testSocket.write('Hello, client 1!\n'.codeUnits);
        socket.sendMessage(<SocketControlMessage>[
          SocketControlMessage.fromHandles(
              <ResourceHandle>[ResourceHandle.fromRawSocket(testSocket)])
        ], 'Hello'.codeUnits);
        testSocket.write('Hello, client 2!\n'.codeUnits);
        break;
      case RawSocketEvent.read:
        final data = socket.read();
        if (data == null) {
          return;
        }

        final dataString = String.fromCharCodes(data);
        Expect.equals('server replied', dataString);
        socket.close();
        testSocket.close();
        testServer.close();
    }
  });
}

Future testStdioMessage(String tempDirPath, {bool caller = false}) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }

  final completer = Completer<bool>();

  if (caller) {
    final process = await Process.start(Platform.resolvedExecutable, <String>[
      ...Platform.executableArguments,
      '--verbosity=warning', // CFE info/hints pollute the stderr we are trying to test
      Platform.script.toFilePath(),
      '--start-stdio-message-test'
    ]);
    String processStdout = "";
    String processStderr = "";
    process.stdout.transform(utf8.decoder).listen((line) {
      processStdout += line;
      print('stdout:>$line<');
    });
    process.stderr.transform(utf8.decoder).listen((line) {
      processStderr += line;
      print('stderr:>$line<');
    });
    process.stdin.writeln('Caller wrote to stdin');

    Expect.equals(0, await process.exitCode);
    Expect.equals("client sent a message\nHello, server!\n", processStdout);
    Expect.equals(
        "client wrote to stderr\nHello, server too!\n", processStderr);
    return;
  }

  final address =
      InternetAddress('$tempDirPath/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    socket.listen((e) {
      if (e == RawSocketEvent.read) {
        final SocketMessage message = socket.readMessage();
        if (message == null) {
          return;
        }
        Expect.equals('Hello', String.fromCharCodes(message.data));
        Expect.equals(message.controlMessages.length, 1);
        final SocketControlMessage controlMessage = message.controlMessages[0];
        final handles = controlMessage.extractHandles();
        Expect.isNotNull(handles);
        Expect.equals(3, handles.length);
        final receivedStdin = handles[0].toFile();
        final receivedString = String.fromCharCodes(receivedStdin.readSync(32));
        Expect.equals('Caller wrote to stdin\n', receivedString);
        final receivedStdout = handles[1].toFile();
        receivedStdout.writeStringSync('Hello, server!\n');
        final receivedStderr = handles[2].toFile();
        receivedStderr.writeStringSync('Hello, server too!\n');
        socket.write('abc'.codeUnits);
      } else if (e == RawSocketEvent.readClosed) {
        socket.close();
        server.close();
      }
    });
  });

  final file = File('$tempDirPath/myfile.txt');
  final randomAccessFile = file.openSync(mode: FileMode.write);
  // Send a message with sample file.
  var socket = await RawSocket.connect(address, 0);
  socket.listen((e) {
    if (e == RawSocketEvent.write) {
      socket.sendMessage(<SocketControlMessage>[
        SocketControlMessage.fromHandles(<ResourceHandle>[
          ResourceHandle.fromStdin(stdin),
          ResourceHandle.fromStdout(stdout),
          ResourceHandle.fromStdout(stderr)
        ])
      ], 'Hello'.codeUnits);
      stdout.writeln('client sent a message');
      stderr.writeln('client wrote to stderr');
    } else if (e == RawSocketEvent.read) {
      final data = socket.read();
      if (data == null) {
        return;
      }
      Expect.equals('abc', String.fromCharCodes(data));
      socket.close();
      completer.complete(true);
    }
  });

  return completer.future;
}

Future testReadPipeMessage(String uniqueName) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final address =
      InternetAddress('$uniqueName/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    socket.listen((e) async {
      switch (e) {
        case RawSocketEvent.read:
          final SocketMessage message = socket.readMessage();
          if (message == null) {
            return;
          }
          Expect.equals('Hello', String.fromCharCodes(message.data));
          Expect.equals(1, message.controlMessages.length);
          final SocketControlMessage controlMessage =
              message.controlMessages[0];
          final handles = controlMessage.extractHandles();
          Expect.isNotNull(handles);
          Expect.equals(1, handles.length);
          final receivedPipe = handles[0].toReadPipe();
          Expect.equals('Hello over pipe!',
              await receivedPipe.transform(utf8.decoder).join());
          socket.write('server replied'.codeUnits);
          break;
        case RawSocketEvent.readClosed:
          socket.close();
          server.close();
          break;
      }
    });
  });

  final RawServerSocket testServer = await createTestServer();
  final testPipe = await Pipe.create();

  // Send a message containing an open pipe.
  final socket = await RawSocket.connect(address, 0);
  socket.listen((e) {
    switch (e) {
      case RawSocketEvent.write:
        socket.sendMessage(<SocketControlMessage>[
          SocketControlMessage.fromHandles(
              <ResourceHandle>[ResourceHandle.fromReadPipe(testPipe.read)])
        ], 'Hello'.codeUnits);
        testPipe.write.add('Hello over pipe!'.codeUnits);
        testPipe.write.close();
        break;
      case RawSocketEvent.read:
        final data = socket.read();
        if (data == null) {
          return;
        }

        final dataString = String.fromCharCodes(data);
        Expect.equals('server replied', dataString);
        socket.close();
        testPipe.write.close();
        testServer.close();
    }
  });
}

Future testWritePipeMessage(String uniqueName) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final address =
      InternetAddress('$uniqueName/sock', type: InternetAddressType.unix);
  final server = await RawServerSocket.bind(address, 0, shared: false);

  server.listen((RawSocket socket) async {
    socket.listen((e) async {
      switch (e) {
        case RawSocketEvent.read:
          final SocketMessage message = socket.readMessage();
          if (message == null) {
            return;
          }
          Expect.equals('Hello', String.fromCharCodes(message.data));
          Expect.equals(1, message.controlMessages.length);
          final SocketControlMessage controlMessage =
              message.controlMessages[0];
          final handles = controlMessage.extractHandles();
          Expect.isNotNull(handles);
          Expect.equals(1, handles.length);
          final receivedPipe = handles[0].toWritePipe();

          receivedPipe.add('Hello over pipe!'.codeUnits);
          receivedPipe.close();
          socket.write('server replied'.codeUnits);
          break;
        case RawSocketEvent.readClosed:
          socket.close();
          server.close();
          break;
      }
    });
  });

  final RawServerSocket testServer = await createTestServer();
  final testPipe = await Pipe.create();

  // Send a message containing an open pipe.
  final socket = await RawSocket.connect(address, 0);
  socket.listen((e) async {
    switch (e) {
      case RawSocketEvent.write:
        socket.sendMessage(<SocketControlMessage>[
          SocketControlMessage.fromHandles(
              <ResourceHandle>[ResourceHandle.fromWritePipe(testPipe.write)])
        ], 'Hello'.codeUnits);

        Expect.equals('Hello over pipe!',
            await testPipe.read.transform(utf8.decoder).join());
        break;
      case RawSocketEvent.read:
        final data = socket.read();
        if (data == null) {
          return;
        }

        final dataString = String.fromCharCodes(data);
        Expect.equals('server replied', dataString);
        socket.close();
        testPipe.write.close();
        testServer.close();
    }
  });
}

Future testDeleteFile(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final address =
      InternetAddress('$tempDirPath/sock', type: InternetAddressType.unix);
  var server = await RawServerSocket.bind(address, 0, shared: false);
  final file = File('$tempDirPath/sock');
  Expect.isTrue(file.existsSync());
  Expect.isTrue(await file.exists());
  file.deleteSync();
  Expect.isFalse(file.existsSync());
  Expect.isFalse(await file.exists());
  await server.close();

  server = await RawServerSocket.bind(address, 0, shared: false);
  Expect.isTrue(file.existsSync());
  Expect.isTrue(await file.exists());
  await file.delete();
  Expect.isFalse(file.existsSync());
  Expect.isFalse(await file.exists());
  await server.close();
}

Future testFileStat(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final name = '$tempDirPath/sock';
  final address = InternetAddress(name, type: InternetAddressType.unix);
  var server = await RawServerSocket.bind(address, 0, shared: false);
  FileStat fileStat = FileStat.statSync(name);
  Expect.equals(FileSystemEntityType.unixDomainSock, fileStat.type);
  server.close();
}

Future testFileRename(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final name1 = '$tempDirPath/sock1';
  final name2 = '$tempDirPath/sock2';
  final address = InternetAddress(name1, type: InternetAddressType.unix);
  var server = await RawServerSocket.bind(address, 0, shared: false);
  final file1 = File(name1);
  final file2 = file1.renameSync(name2);
  Expect.isFalse(file1.existsSync());
  Expect.isTrue(file2.existsSync());
  await server.close();
  file2.deleteSync();
  Expect.isFalse(file1.existsSync());
  Expect.isFalse(file2.existsSync());
}

Future testFileCopy(String tempDirPath) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final name1 = '$tempDirPath/sock1';
  final name2 = '$tempDirPath/sock2';
  final address = InternetAddress(name1, type: InternetAddressType.unix);
  final file1 = File(name1);
  var server = await RawServerSocket.bind(address, 0, shared: false);
  try {
    final file2 = file1.copySync(name2);
    Expect.isFalse(true);
  } catch (e) {
    Expect.isTrue(e is FileSystemException);
  }
  await server.close();
  Expect.isFalse(file1.existsSync());
}

void main(List<String> args) async {
  runZonedGuarded(() async {
    if (args.length > 0 && args[0] == '--start-stdio-message-test') {
      await withTempDir('unix_socket_test', (Directory dir) async {
        await testStdioMessage('${dir.path}', caller: false);
      });
      return;
    }

    await withTempDir('unix_socket_test', (Directory dir) async {
      await testAddress('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testBind('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testBindShared('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testListenCloseListenClose('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testSourceAddressConnect('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testAbstractAddress(dir.uri.pathSegments.last);
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testExistingFile('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testSetSockOpt('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testHttpServer('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testShortAbstractAddress(dir.uri.pathSegments.last);
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testFileMessage('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testFileMessageWithShortRead('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testTooLargeControlMessage('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testSocketMessage('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testReadPipeMessage('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testWritePipeMessage('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testStdioMessage('${dir.path}', caller: true);
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testDeleteFile('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testFileStat('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testFileRename('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testFileCopy('${dir.path}');
    });
  }, (e, st) {
    if (Platform.isMacOS || Platform.isLinux || Platform.isAndroid) {
      Expect.fail("Unexpected exception $e is thrown:\n$st");
    } else {
      Expect.isTrue(e is SocketException);
      Expect.isTrue(e.toString().contains('not available'));
    }
  });
}
