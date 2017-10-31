// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:convert";
import "dart:io";

testAddressParse() async {
  print(new InternetAddress("1.0.2.3").rawAddress);
  print(new InternetAddress("1.0.2.3").type);

  print(new InternetAddress("::1").rawAddress);
  print(new InternetAddress("::1").type);

  try {
    print(new InternetAddress("localhost"));
  } catch (e) {
    print(e);
  }
}

testSimpleBind() async {
  var s = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  print("port = ${s.port}");
  await s.close();
}

testSimpleConnect() async {
  var server = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  print("server port = ${server.port}");
  server.listen((socket) {
    print("listen socket port = ${socket.port}");
    socket.close();
  });
  var socket = await RawSocket.connect("127.0.0.1", server.port);
  print("socket port = ${socket.port}");
  if (socket.remoteAddress.address != "127.0.0.1" ||
      socket.remoteAddress.type != InternetAddressType.IP_V4) {
    throw "Bad remote address ${socket.remoteAddress}";
  }
  if (socket.remotePort is! int) {
    throw "Bad remote port ${socket.remotePort}";
  }
  await server.close();
  await socket.close();
}

testSimpleReadWriteClose() async {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the client finishes fully reading the
  // echo, it closes the socket. When the server receives the close event, it
  // closes its end of the socket too.

  const messageSize = 1000;
  int serverReadCount = 0;
  int clientReadCount = 0;

  List<int> createTestData() {
    return new List<int>.generate(messageSize, (index) => index & 0xff);
  }

  void verifyTestData(List<int> data) {
    assert(messageSize == data.length);
    List<int> expected = createTestData();
    for (int i = 0; i < messageSize; i++) {
      assert(expected[i] == data[i]);
    }
  }

  var server = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  server.listen((client) {
    int bytesRead = 0;
    int bytesWritten = 0;
    bool closedEventReceived = false;
    List<int> data = new List<int>(messageSize);
    bool doneReading = false;

    client.writeEventsEnabled = false;
    client.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          if (doneReading) {
            break;
          }
          print("client READ event bytesRead = $bytesRead");
          assert(bytesWritten == 0);
          assert(client.available() > 0);
          var buffer = client.read(200);
          print("client READ event: read ${buffer.length} more bytes");
          data.setRange(bytesRead, bytesRead + buffer.length, buffer);
          bytesRead += buffer.length;
          if (bytesRead == data.length) {
            verifyTestData(data);
            print("client READ event. Done reading, enabling writes");
            client.writeEventsEnabled = true;
            doneReading = true;
          }
          break;
        case RawSocketEvent.WRITE:
          assert(!client.writeEventsEnabled);
          bytesWritten +=
              client.write(data, bytesWritten, data.length - bytesWritten);
          print("client WRITE event: $bytesWritten written");
          if (bytesWritten < data.length) {
            client.writeEventsEnabled = true;
          }
          if (bytesWritten == data.length) {
            print("client WRITE event: done writing.");
          }
          break;
        case RawSocketEvent.READ_CLOSED:
          print("client READ_CLOSED event");
          client.close();
          server.close();
          break;
        case RawSocketEvent.CLOSED:
          assert(!closedEventReceived);
          print("client CLOSED event");
          closedEventReceived = true;
          break;
        default:
          throw "Unexpected event $event";
      }
    }, onError: (e) {
      print("client ERROR $e");
    }, onDone: () {
      assert(closedEventReceived);
    });
  });

  {
    var completer = new Completer();
    var socket = await RawSocket.connect("127.0.0.1", server.port);
    int bytesRead = 0;
    int bytesWritten = 0;
    bool closedEventReceived = false;
    List<int> data = createTestData();

    socket.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          assert(socket.available() > 0);
          print("server READ event: ${bytesRead} read");
          var buffer = socket.read();
          print("server READ event: read ${buffer.length} more bytes");
          data.setRange(bytesRead, bytesRead + buffer.length, buffer);
          bytesRead += buffer.length;
          if (bytesRead == messageSize) {
            print("server READ event: done reading");
            socket.close();
          }
          break;
        case RawSocketEvent.WRITE:
          assert(bytesRead == 0);
          assert(!socket.writeEventsEnabled);
          bytesWritten +=
              socket.write(data, bytesWritten, data.length - bytesWritten);
          print("server WRITE event: ${bytesWritten} written");
          if (bytesWritten < data.length) {
            socket.writeEventsEnabled = true;
          } else {
            print("server WRITE event: done writing");
            data = new List<int>(messageSize);
          }
          break;
        case RawSocketEvent.READ_CLOSED:
          print("server READ_CLOSED event");
          verifyTestData(data);
          socket.close();
          break;
        case RawSocketEvent.CLOSED:
          assert(!closedEventReceived);
          print("server CLOSED event");
          closedEventReceived = true;
          break;
        default:
          throw "Unexpected event $event";
      }
    }, onError: (e) {
      print("server ERROR $e");
    }, onDone: () {
      assert(closedEventReceived);
      completer.complete(null);
    });

    return completer.future;
  }
}

testSimpleReadWriteShutdown({bool dropReads}) async {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.

  const messageSize = 1000;
  int serverReadCount = 0;
  int clientReadCount = 0;

  List<int> createTestData() {
    return new List<int>.generate(messageSize, (index) => index & 0xff);
  }

  void verifyTestData(List<int> data) {
    assert(messageSize == data.length);
    List<int> expected = createTestData();
    for (int i = 0; i < messageSize; i++) {
      assert(expected[i] == data[i]);
    }
  }

  var server = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  server.listen((client) {
    int bytesRead = 0;
    int bytesWritten = 0;
    bool closedEventReceived = false;
    List<int> data = new List<int>(messageSize);
    bool doneReading = false;

    client.writeEventsEnabled = false;
    client.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          if (doneReading) {
            break;
          }
          if (dropReads) {
            if (serverReadCount != 10) {
              serverReadCount++;
              break;
            } else {
              serverReadCount = 0;
            }
          }
          print("client READ event bytesRead = $bytesRead");
          assert(bytesWritten == 0);
          assert(client.available() > 0);
          var buffer = client.read(200);
          print("client READ event: read ${buffer.length} more bytes");
          data.setRange(bytesRead, bytesRead + buffer.length, buffer);
          bytesRead += buffer.length;
          if (bytesRead == data.length) {
            verifyTestData(data);
            print("client READ event. Done reading, enabling writes");
            client.writeEventsEnabled = true;
            doneReading = true;
          }
          break;
        case RawSocketEvent.WRITE:
          assert(!client.writeEventsEnabled);
          bytesWritten +=
              client.write(data, bytesWritten, data.length - bytesWritten);
          print("client WRITE event: $bytesWritten written");
          if (bytesWritten < data.length) {
            client.writeEventsEnabled = true;
          }
          if (bytesWritten == data.length) {
            print("client WRITE event: done writing.");
            client.shutdown(SocketDirection.SEND);
          }
          break;
        case RawSocketEvent.READ_CLOSED:
          print("client READ_CLOSED event");
          server.close();
          break;
        case RawSocketEvent.CLOSED:
          assert(!closedEventReceived);
          print("client CLOSED event");
          closedEventReceived = true;
          break;
        default:
          throw "Unexpected event $event";
      }
    }, onDone: () {
      assert(closedEventReceived);
    });
  });

  {
    var completer = new Completer();
    var socket = await RawSocket.connect("127.0.0.1", server.port);
    int bytesRead = 0;
    int bytesWritten = 0;
    bool closedEventReceived = false;
    List<int> data = createTestData();

    socket.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          assert(socket.available() > 0);
          if (dropReads) {
            if (clientReadCount != 10) {
              clientReadCount++;
              break;
            } else {
              clientReadCount = 0;
            }
          }
          print("server READ event: ${bytesRead} read");
          var buffer = socket.read();
          print("server READ event: read ${buffer.length} more bytes");
          data.setRange(bytesRead, bytesRead + buffer.length, buffer);
          bytesRead += buffer.length;
          break;
        case RawSocketEvent.WRITE:
          assert(bytesRead == 0);
          assert(!socket.writeEventsEnabled);
          bytesWritten +=
              socket.write(data, bytesWritten, data.length - bytesWritten);
          print("server WRITE event: ${bytesWritten} written");
          if (bytesWritten < data.length) {
            socket.writeEventsEnabled = true;
          } else {
            print("server WRITE event: done writing");
            data = new List<int>(messageSize);
          }
          break;
        case RawSocketEvent.READ_CLOSED:
          print("server READ_CLOSED event");
          verifyTestData(data);
          socket.close();
          break;
        case RawSocketEvent.CLOSED:
          assert(!closedEventReceived);
          print("server CLOSED event");
          closedEventReceived = true;
          break;
        default:
          throw "Unexpected event $event";
      }
    }, onDone: () {
      assert(closedEventReceived);
      completer.complete(null);
    });

    return completer.future;
  }
}

Future testProcess() async {
  String exe = Platform.resolvedExecutable;
  print("Running $exe --version");
  Process p = await Process.start(exe, ["--version"]);
  p.stderr.transform(UTF8.decoder).listen(print);
  int code = await p.exitCode;
  print("$exe --version exited with code $code");
}

void testProcessRunSync() {
  String exe = Platform.resolvedExecutable;
  print("Running $exe --version");
  var result = Process.runSync(exe, ["--version"]);
  print("$exe --version exited with code ${result.exitCode}");
  print("$exe --version had stdout = '${result.stdout}'");
  print("$exe --version had stderr = '${result.stderr}'");
}

Future testKill() async {
  String exe = Platform.resolvedExecutable;
  String script = Platform.script.path;
  print("Running $exe $script");
  Process p = await Process.start(exe, [script, "infinite-loop"]);
  await new Future.delayed(const Duration(seconds: 1));
  p.kill();
  int code = await p.exitCode;
  print("$exe $script exited with code $code");
}

Future testLs(String path) async {
  Stream<FileSystemEntity> stream = (new Directory(path)).list();
  await for (FileSystemEntity fse in stream) {
    print(fse.path);
  }
}

void testPlatformEnvironment() {
  Map<String, String> env = Platform.environment;
  for (String k in env.keys) {
    String v = env[k];
    print("$k = '$v'");
  }
}

Future testCopy() async {
  final String sourceName = "foo";
  final String destName = "bar";
  Directory tmp = await Directory.systemTemp.createTemp("testCopy");
  File sourceFile = new File("${tmp.path}/$sourceName");
  File destFile = new File("${tmp.path}/$destName");
  List<int> data = new List<int>.generate(10 * 1024, (int i) => i & 0xff);
  await sourceFile.writeAsBytes(data);
  await sourceFile.copy(destFile.path);
  List<int> resultData = await destFile.readAsBytes();
  assert(data.length == resultData.length);
  for (int i = 0; i < data.length; i++) {
    assert(data[i] == resultData[i]);
  }
  await sourceFile.delete();
  await destFile.delete();
  await tmp.delete();
}

Future testRecursiveDelete() async {
  Directory tmp0 = await Directory.systemTemp.createTemp("testRD");
  Directory tmp1 = await tmp0.createTemp("testRD");
  Directory tmp2 = await tmp1.createTemp("testRD");
  File file0 = new File("${tmp0.path}/file");
  File file1 = new File("${tmp1.path}/file");
  File file2 = new File("${tmp2.path}/file");
  List<int> data = new List<int>.generate(10 * 1024, (int i) => i & 0xff);
  await file0.writeAsBytes(data);
  await file1.writeAsBytes(data);
  await file2.writeAsBytes(data);

  await tmp0.delete(recursive: true);

  assert(!await file2.exists());
  assert(!await file1.exists());
  assert(!await file0.exists());
  assert(!await tmp2.exists());
  assert(!await tmp1.exists());
  assert(!await tmp0.exists());
}

bool testFileOpenDirectoryFails() {
  File dir = new File(Directory.systemTemp.path);
  try {
    dir.openSync();
  } on FileSystemException catch (e) {
    return true;
  } catch (e) {
    print("Unexpected Exception: $e");
    return false;
  }
}


Future testListInterfaces() async {
  List<NetworkInterface> interfaces = await NetworkInterface.list();
  print('Found ${interfaces.length} interfaces:');
  for (var iface in interfaces) {
    print('\t$iface');
  }
}

main(List<String> args) async {
  if (args.length >= 1) {
    if (args[0] == "infinite-loop") {
      while (true);
    }
  }

  print("Hello, Fuchsia!");

  print("testAddressParse");
  await testAddressParse();
  print("testAddressParse done");

  print("testSimpleBind");
  await testSimpleBind();
  print("testSimpleBind done");

  print("testSimpleConnect");
  await testSimpleConnect();
  print("testSimpleConnect done");

  print("testSimpleReadWriteClose");
  await testSimpleReadWriteClose();
  print("testSimpleReadWriteClose done");

  print("testSimpleReadWriteShutdown");
  await testSimpleReadWriteShutdown(dropReads: false);
  print("testSimpleReadWriteShutdown done");

  print("lsTest");
  await testLs("/");
  print("lsTest done");

  print("testPlatformEnvironment");
  testPlatformEnvironment();
  print("testPlatformEnvironment done");

  print("testProcess");
  await testProcess();
  print("testProcess done");

  print("testProcessRunSync");
  testProcessRunSync();
  print("testProcessRunSync done");

  print("testKill");
  await testKill();
  print("testKill done");

  print("testCopy");
  await testCopy();
  print("testCopy done");

  print("testRecursiveDelete");
  await testRecursiveDelete();
  print("testRecursiveDelete done");

  print("testFileOpenDirectoryFails");
  bool result = testFileOpenDirectoryFails();
  if (result) {
    print("testFileOpenDirectoryFails done");
  } else {
    print("testFileOpenDirectoryFails FAILED");
  }

  print('testListInterfaces');
  await testListInterfaces();
  print('testListInterfaces done');

  print("Goodbyte, Fuchsia!");
}
