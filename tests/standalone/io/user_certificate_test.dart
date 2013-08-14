// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies the SecureSocket functions addCertificate,
// importCertificatesWithPrivateKeys, changeTrust, getCertificate, and
// removeCertificate.

// It loads a copy of the test certificate database,
// removes all certificates and keys, then imports the certificates and keys
// again.  Then it runs a secure server, using the user certificate (a
// certificate with private key), and starts client processes that use
// addCertificate to trust the certificate that signed the server's certificate.
// The clients then test that they can successfully connect to the server.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:io";
import "dart:async";

void main() {
  Directory tempDirectory = new Directory('').createTempSync();
  String scriptDirectory = dirname(Platform.script);
  String database = join(scriptDirectory, 'pkcert');
  String serverDatabase = join(tempDirectory.path, 'server');
  String clientDatabase = join(tempDirectory.path, 'client');
  new Directory(serverDatabase).createSync();
  new Directory(clientDatabase).createSync();

  cleanUp() {
    if (Platform.isWindows) {
      // Delay directory deletion until after this script exits.
      // The certificate database files are locked until then.
      Process.start('start',  // Starts a detatched process.
                    [Platform.executable,
                     join(scriptDirectory, 'delete_a_directory_later.dart'),
                     tempDirectory.path],
                     runInShell: true);
    } else {
      tempDirectory.delete(recursive: true);
    }
  }

  Future.wait([
      copyFileToDirectory(join(database, 'cert9.db'), serverDatabase),
      copyFileToDirectory(join(database, 'key4.db'), serverDatabase),
      copyFileToDirectory(join(database, 'cert9.db'), clientDatabase),
      copyFileToDirectory(join(database, 'key4.db'), clientDatabase),
  ]).then((_) {
    SecureSocket.initialize(database: serverDatabase,
                            password: 'dartdart',
                            readOnly: false);
    for (var nickname in ['localhost_cert', 'myauthority_cert']) {
      Expect.isNotNull(SecureSocket.getCertificate(nickname));
      SecureSocket.removeCertificate(nickname);
      Expect.isNull(SecureSocket.getCertificate(nickname));
    }

    var mycerts = new File(join(database, 'localhost.p12')).readAsBytesSync();
    SecureSocket.importCertificatesWithPrivateKeys(mycerts, 'dartdart');

    checkCertificate('localhost_cert', 'CN=localhost', 'CN=myauthority');
    checkCertificate('myauthority_cert', 'CN=myauthority', 'CN=myauthority');

    SecureSocket.removeCertificate('myauthority_cert');
    return runServer().then((server) {
      var tests = ['certificate_test_client.dart',
                   'certificate_test_client_database.dart'];
      return Future.wait(tests.map((test) =>
          Process.run(Platform.executable,
                      ['--checked',
                       join(scriptDirectory, test),
                       server.port.toString(),
                       join(database, 'myauthority.pem'),
                       clientDatabase])))
      .then(verifyResults)
      .whenComplete(server.close);
    });
  })
  .whenComplete(cleanUp);
}

checkCertificate(nickname, subject, issuer) {
  var cert = SecureSocket.getCertificate(nickname);
  Expect.isTrue(cert is X509Certificate);
  Expect.equals(subject, cert.subject);
  Expect.equals(issuer, cert.issuer);
}

Future<SecureServerSocket> runServer() =>
  SecureServerSocket.bind("localhost", 0, "localhost_cert")
    .then((server) => server..listen((socket) => socket.pipe(socket)));

verifyResults(results) => results.map(verifyResult);
verifyResult(ProcessResult result) {
  if (result.exitCode != 0 ||  !result.stdout.contains('SUCCESS')) {
    print("Client failed with exit code ${result.exitCode}");
    print("  stdout (expected \"SUCCESS\\n\"):");
    print(result.stdout);
    print("  stderr:");
    print(result.stderr);
    Expect.fail("Client failed");
  }
}

Future copyFileToDirectory(String file, String directory) {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Process.run('cp', [file, directory]);
    case 'windows':
      return Process.run('cmd.exe', ['/C', 'copy $file $directory']);
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}
