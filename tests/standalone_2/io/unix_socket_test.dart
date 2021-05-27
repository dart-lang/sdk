// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:expect/expect.dart';

Future testAddress(String name) async {
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var server = await ServerSocket.bind(address, 0);

  var type = FileSystemEntity.typeSync(address.address);

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
  var address = InternetAddress('$name/sock', type: InternetAddressType.unix);
  var server = await ServerSocket.bind(address, 0, shared: false);
  Expect.isTrue(server.address.toString().contains(name));
  // Unix domain socket does not have a valid port number.
  Expect.equals(server.port, 0);

  var type = FileSystemEntity.typeSync(address.address);

  var sub;
  sub = server.listen((s) {
    sub.cancel();
    server.close();
  });

  var socket = await Socket.connect(address, server.port);
  socket.write(" socket content");

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

  var type = FileSystemEntity.typeSync(address.address);

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

  var type = FileSystemEntity.typeSync(address.address);

  Socket client =
      await Socket.connect(address, server.port, sourceAddress: localAddress);
  Expect.equals(client.remoteAddress.address, address.address);
  await completer.future;
  await client.close();
  await client.drain();
  await server.close();
}

Future testAbstractAddress() async {
  if (!Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  var serverAddress =
      InternetAddress('@temp.sock', type: InternetAddressType.unix);
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

Future testShortAbstractAddress() async {
  if (!Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  Process process;
  try {
    var socketAddress = '@hidden';
    var abstractSocketServer = getAbstractSocketTestFileName();
    process = await Process.start(abstractSocketServer, [socketAddress]);
    var serverAddress =
        InternetAddress(socketAddress, type: InternetAddressType.unix);
    Socket client = await Socket.connect(serverAddress, 0);
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

// Create socket in temp directory
Future withTempDir(String prefix, Future<void> test(Directory dir)) async {
  var tempDir = Directory.systemTemp.createTempSync(prefix);
  try {
    await test(tempDir);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main() async {
  try {
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
    await testAbstractAddress();
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testExistingFile('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testSetSockOpt('${dir.path}');
    });
    await withTempDir('unix_socket_test', (Directory dir) async {
      await testHttpServer('${dir.path}');
    });
    await testShortAbstractAddress();
  } catch (e) {
    if (Platform.isMacOS || Platform.isLinux || Platform.isAndroid) {
      Expect.fail("Unexpected exception $e is thrown");
    } else {
      Expect.isTrue(e is SocketException);
      Expect.isTrue(e.toString().contains('not available'));
    }
  }
}
