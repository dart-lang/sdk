// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:async";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

void main(List<String> args) {
  if (!args.contains('--child')) {
    runAllTestsInChildProcesses();
  } else {
    InitializeSSL(useDatabase: args.contains('--database'),
                  useBuiltinRoots: args.contains('--builtin-roots'));
    testGoogleUrl(args.contains('--builtin-roots'));
  }
}

void InitializeSSL({bool useDatabase, bool useBuiltinRoots}) {
  // If the built-in root certificates aren't loaded, the connection
  // should signal an error.  Even when an external database is loaded,
  // they should not be loaded.
  if (useDatabase) {
    var certificateDatabase = Platform.script.resolve('pkcert').toFilePath();
    SecureSocket.initialize(database: certificateDatabase,
                            password: 'dartdart',
                            useBuiltinRoots: useBuiltinRoots);
  } else {
    SecureSocket.initialize(useBuiltinRoots: useBuiltinRoots);
  }
}

void testGoogleUrl(bool expectSuccess) {
  // We need to use an external server that is backed by a
  // built-in root certificate authority.

  // First, check if the lookup fails.  If not then run the test.
  InternetAddress.lookup('www.google.com').then((_) {
    HttpClient client = new HttpClient();
    client.getUrl(Uri.parse('https://www.google.com'))
      .then((request) {
        request.followRedirects = false;
        return request.close();
      })
      .then((response) {
        Expect.isTrue(expectSuccess, "Unexpected successful connection");
        print('SUCCESS');
        return response.drain().catchError((_) {});
      })
      .catchError((error) {
        // Allow SocketExceptions if www.google.com is unreachable or down.
        Expect.isTrue((!expectSuccess && error is HandshakeException) ||
                      error is SocketException);
        print('SUCCESS');
      })
      .whenComplete(client.close);
  },
  onError: (e) {
    // Lookup failed.
    Expect.isTrue(e is SocketException);
    print('SUCCESS');
  });
}

void runAllTestsInChildProcesses() {
  Future runChild(List<String> scriptArguments) {
    return Process.run(Platform.executable,
                       []..addAll(Platform.executableArguments)
                         ..add(Platform.script.toFilePath())
                         ..addAll(scriptArguments))
    .then((ProcessResult result) {
      if (result.exitCode != 0 || !result.stdout.contains('SUCCESS')) {
        print("Client failed");
        print("  stdout:");
        print(result.stdout);
        print("  stderr:");
        print(result.stderr);
        Expect.fail('Client subprocess exit code: ${result.exitCode}');
      }
    });
  }

  asyncStart();
  Future.wait([runChild(['--child']),
               runChild(['--child', '--database']),
               runChild(['--child', '--builtin-roots']),
               runChild(['--child', '--builtin-roots', '--database'])])
      .then((_) => asyncEnd());
  }
