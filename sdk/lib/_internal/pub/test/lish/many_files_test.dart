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

/// The depth of directories to use when creating files to tickle
/// argument-length limits.
final _depth = 10;

/// The maximum number of characters in a path component.
///
/// Only Windows has this tight of a constraint, but we abide by it on all
/// operating systems to avoid specializing the test too much.
final _componentMax = 255;

main() {
  initConfig();

  integration('archives and uploads a package', () {
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
      var dir = p.join(sandboxDir, appPath);
      for (var i = 0; i < _depth; i++) {
        dir = p.join(dir, "x" * _componentMax);
        new Directory(dir).createSync();
      }

      var pathLength = (_componentMax + 1) * _depth;
      var filesToCreate = (argMax / pathLength).ceil();
      for (var i = 0; i < filesToCreate; i++) {
        var filePath = p.join(dir, "x" * _componentMax);
        var iString = i.toString();
        filePath = filePath.substring(0, filePath.length - iString.length) +
            iString;

        new File(filePath).writeAsStringSync("");
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
