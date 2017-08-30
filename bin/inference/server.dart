// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Server component to display inference results using a web app.
library dart2js_info.bin.inference.server;

import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

String jsonDataFile;
String indexFile;
String scriptFile;

main(List<String> args) async {
  var host = 'localhost';
  var port = 8080;

  jsonDataFile = args.length > 0 ? args[0] : 'out.js.stats.json';
  indexFile = Platform.script.resolve('index.html').path;
  scriptFile = Platform.script.resolve('client.dart.js').path;

  await shelf.serve(_handler, host, port);
}

Future<shelf.Response> _handler(shelf.Request request) async {
  var path = request.url.path;
  if (path == 'data') {
    return new shelf.Response.ok(await new File(jsonDataFile).readAsString());
  }
  if (path == 'client.dart.js') {
    return new shelf.Response.ok(await new File(scriptFile).readAsString(),
        headers: JS_HEADERS);
  }
  if (path.startsWith('file/')) {
    return _fileHandler(request.change(path: 'file'));
  }
  return new shelf.Response.ok(await new File(indexFile).readAsString(),
      headers: HTML_HEADERS);
}

final _fileHandler = shelf_static.createStaticHandler('/');
const HTML_HEADERS = const {'content-type': 'text/html'};
const JS_HEADERS = const {'content-type': 'text/javascript'};
