// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../test_pub.dart';

/// The pub process running "pub serve".
ScheduledProcess _pubServer;

/// The ephemeral port assigned to the running server.
int _port;

/// The code for a transformer that renames ".txt" files to ".out" and adds a
/// ".out" suffix.
const REWRITE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }
}
""";

/// Returns the source code for a Dart library defining a Transformer that
/// rewrites Dart files.
///
/// The transformer defines a constant named TOKEN whose value is [id]. When the
/// transformer transforms another Dart file, it will look for a "TOKEN"
/// constant definition there and modify it to include *this* transformer's
/// TOKEN value as well.
///
/// If [import] is passed, it should be the name of a package that defines its
/// own TOKEN constant. The primary library of that package will be imported
/// here and its TOKEN value will be added to this library's.
String dartTransformer(String id, {String import}) {
  if (import != null) {
    id = '$id imports \${$import.TOKEN}';
    import = 'import "package:$import/$import.dart" as $import;';
  } else {
    import = '';
  }

  return """
import 'dart:async';

import 'package:barback/barback.dart';
$import

const TOKEN = "$id";

final _tokenRegExp = new RegExp(r'^const TOKEN = "(.*?)";\$', multiLine: true);

class DartTransformer extends Transformer {
  DartTransformer();

  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(transform.primaryInput.id,
          contents.replaceAllMapped(_tokenRegExp, (match) {
        return 'const TOKEN = "(\${match[1]}, \$TOKEN)";';
      })));
    });
  }
}
""";
}

/// Schedules starting the "pub serve" process.
///
/// If [shouldInstallFirst] is `true`, validates that pub install is run first.
///
/// Returns the `pub serve` process.
ScheduledProcess startPubServe({bool shouldInstallFirst: false}) {
  // Use port 0 to get an ephemeral port.
  _pubServer = startPub(args: ["serve", "--port=0"]);

  if (shouldInstallFirst) {
    expect(_pubServer.nextLine(),
        completion(startsWith("Dependencies have changed")));
    expect(_pubServer.nextLine(),
        completion(startsWith("Resolving dependencies...")));
    expect(_pubServer.nextLine(),
        completion(equals("Dependencies installed!")));
  }

  expect(_pubServer.nextLine().then(_parsePort), completes);
  return _pubServer;
}

/// Parses the port number from the "Serving blah on localhost:1234" line
/// printed by pub serve.
void _parsePort(String line) {
  var match = new RegExp(r"localhost:(\d+)").firstMatch(line);
  assert(match != null);
  _port = int.parse(match[1]);
}

void endPubServe() {
  _pubServer.kill();
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with [expected].
void requestShouldSucceed(String urlPath, String expected) {
  schedule(() {
    return http.get("http://localhost:$_port/$urlPath").then((response) {
      expect(response.body, equals(expected));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a 404.
void requestShould404(String urlPath) {
  schedule(() {
    return http.get("http://localhost:$_port/$urlPath").then((response) {
      expect(response.statusCode, equals(404));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP POST to the running pub server with [urlPath] and verifies
/// that it responds with a 405.
void postShould405(String urlPath) {
  schedule(() {
    return http.post("http://localhost:$_port/$urlPath").then((response) {
      expect(response.statusCode, equals(405));
    });
  }, "request $urlPath");
}

/// Reads lines from pub serve's stdout until it prints the build success
/// message.
///
/// The schedule will not proceed until the output is found. If not found, it
/// will eventually time out.
void waitForBuildSuccess() {
  nextLine() {
    return _pubServer.nextLine().then((line) {
      if (line.contains("successfully")) return;

      // This line wasn't it, so ignore it and keep trying.
      return nextLine();
    });
  }

  schedule(nextLine);
}
