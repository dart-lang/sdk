// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> args) async {
  if (args[0] == 'child') {
    // Get the Dart script file and start the grandchild process.
    var scriptFile = new File(
      Platform.script.resolve("process_child_script.dart").toFilePath(),
    );
    var args = <String>[]..addAll([scriptFile.path, 'grandchild']);
    var process = await Process.start(Platform.executable, args);

    // Read the port number from the grandchild's stdout stream.
    final portNumber = await process.stdout.transform(utf8.decoder).first;

    // Relay the port number to the parent process by printing it.
    print('${portNumber.trim()}');

    // The child process can exit now.
    exit(0);
  } else {
    // Grand child process code.

    // Create a server socket and bind it to a random port.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

    // Print the port number to stdout so that it is relayed by the child
    // to the parent process and it can read it.
    print('${server.port}');

    // Now listen for incoming connections, this will confirm to the parent
    // that the grandchild is still alive after the child exits.
    await for (var socket in server) {
      // Listen for data from the client.
      socket.listen(
        (data) {
          final message = utf8.decode(data);
        },
        onDone: () {
          server.close();
          exit(0);
        },
        onError: (error) {
          server.close();
          exit(1);
        },
      );
    }
  }
}
