// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_child_script.dart

import "package:expect/expect.dart";
import 'package:path/path.dart';

import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> args) async {
  // Get the Dart script file for the child process and start the child
  // process.
  var scriptFile = new File(
    Platform.script.resolve("process_child_script.dart").toFilePath(),
  );
  var args = <String>[]..addAll([scriptFile.path, 'child']);
  var process = await Process.start(Platform.executable, args);

  // Listen to the child's stdout to get the relayed port number of
  // the grand child process.
  final portString = await process.stdout.transform(utf8.decoder).first;
  final port = int.parse(portString);

  print('Received grandchild port $port from child. Child should now exit.');
  var exitCode = await process.exitCode;
  Expect.equals(0, exitCode);

  // Now that the child has exited, connect to the grandchild to make
  // sure it is still running and has not exited because the child exited.
  try {
    // Connect to the grandchild's server socket.
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    print('Parent: Connected to grandchild.');

    // Send messages to the grandchild.
    print('Parent: Sending messages...');
    socket.writeln('Hello from the parent!');
    await Future.delayed(Duration(seconds: 1));
    socket.writeln('How are you?');
    await Future.delayed(Duration(seconds: 1));
    socket.writeln('Closing the connection.');

    // Close the connection.
    await socket.close();
    print('Parent: Disconnected from grandchild.');
  } on SocketException catch (e) {
    // If we are unable to connect to the grandchild process it means
    // the grandchild process has exited and so this would be an error.
    print('Parent: Could not connect to grandchild: $e');
    Expect.equals(0, 1); // Force an error.
  }

  print('Parent: Exiting.');
  exit(0);
}
