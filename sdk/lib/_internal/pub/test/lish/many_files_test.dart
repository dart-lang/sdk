// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

/// The maximum number of bytes in an entire path.
///
/// This is [Windows's number][MAX_PATH], which is a much tighter constraint
/// than OS X or Linux. We subtract one because Windows counts it as the number
/// of bytes in a path C string including the terminating NUL but we only count
/// characters here.
///
/// We use this limit on all platforms for consistency.
///
/// [MAX_PATH]: https://msdn.microsoft.com/en-us/library/windows/desktop/aa383130(v=vs.85).aspx
const _pathMax = 260 - 1;

main() {
  initConfig();

  integration('archives and uploads a package with more files than can fit on '
      'the command line', () {
    d.validPackage.create();

    var argMax;
    if (Platform.isWindows) {
      // On Windows, the maximum argument list length is 8^5 bytes.
      argMax = math.pow(8, 5);
    } else {
      // On POSIX, the maximum argument list length can be retrieved
      // automatically.
      var result = Process.runSync("getconf", ["ARG_MAX"]);
      if (result.exitCode != 0) {
        fail("getconf failed with exit code ${result.exitCode}:\n"
            "${result.stderr}");
      }

      argMax = int.parse(result.stdout);
    }

    schedule(() {
      var appRoot = p.join(sandboxDir, appPath);

      // We'll make the filenames as long as possible to reduce the number of
      // files we have to create to hit the maximum. However, the tar process
      // uses relative paths, which means we can't count the root as part of the
      // length.
      var lengthPerFile = _pathMax - appRoot.length;

      // Create enough files to hit [argMax]. This may be a slight overestimate,
      // since other options are passed to the tar command line, but we don't
      // know how long those will be.
      var filesToCreate = (argMax / lengthPerFile).ceil();

      for (var i = 0; i < filesToCreate; i++) {
        var iString = i.toString();

        // The file name contains "x"s to make the path hit [_pathMax],
        // followed by a number to distinguish different files.
        var fileName =
          "x" * (_pathMax - appRoot.length - iString.length - 1) + iString;

        new File(p.join(appRoot, fileName)).writeAsStringSync("");
      }
    });

    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      return new shelf.Response.ok(JSON.encode({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
    });

    pub.stdout.expect(startsWith('Uploading...'));
    pub.stdout.expect('Package test_pkg 1.0.0 uploaded!');
    pub.shouldExit(exit_codes.SUCCESS);
  });
}
