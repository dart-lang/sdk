// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

var _httpClient;

void _loadHttp(sendPort, uri) {
  if (_httpClient == null) {
    _httpClient = new HttpClient()..maxConnectionsPerHost = 6;
  }
  _httpClient.getUrl(uri)
    .then((HttpClientRequest request) => request.close())
    .then((HttpClientResponse response) {
      var builder = new BytesBuilder(copy: false);
      response.listen(
          builder.add,
          onDone: () {
            if (response.statusCode != 200) {
              var msg = 'Failure getting $uri: '
                        '${response.statusCode} ${response.reasonPhrase}';
              sendPort.send(msg);
            } else {
              sendPort.send(builder.takeBytes());
            }
          },
          onError: (e) {
            sendPort.send(e.toString());
          });
    })
    .catchError((e) {
      sendPort.send(e.toString());
    });
  // It's just here to push an event on the event loop so that we invoke the
  // scheduled microtasks.
  Timer.run(() {});
}

void _loadFile(sendPort, path) {
  var sourceFile = new File(path);
  sourceFile.readAsBytes().then((data) {
    sendPort.send(data);
  },
  onError: (e) {
    sendPort.send(e.toString());
  });
}

var dataUriRegex = new RegExp(
    r"data:([\w-]+/[\w-]+)?(;charset=([\w-]+))?(;base64)?,(.*)");

void _loadDataUri(sendPort, uri) {
  try {
    var match = dataUriRegex.firstMatch(uri.toString());
    if (match == null) throw "Malformed data uri";

    var mimeType = match.group(1);
    var encoding = match.group(3);
    var maybeBase64 = match.group(4);
    var encodedData = match.group(5);

    if (mimeType != "application/dart") {
      throw "MIME-type must be application/dart";
    }
    if (encoding != "utf-8") {
      // Default is ASCII. The C++ portion of the embedder assumes UTF-8.
      throw "Only utf-8 encoding is supported";
    }
    if (maybeBase64 != null) {
      throw "Only percent encoding is supported";
    }

    var data = UTF8.encode(Uri.decodeComponent(encodedData));
    sendPort.send(data);
  } catch (e) {
    sendPort.send("Invalid data uri ($uri) $e");
  }
}

_processLoadRequest(request) {
  var sp = request[0];
  var uri = Uri.parse(request[1]);
  if (uri.scheme == 'file') {
    _loadFile(sp, uri.toFilePath());
  } else if ((uri.scheme == 'http') || (uri.scheme == 'https')) {
    _loadHttp(sp, uri);
  } else if ((uri.scheme == 'data')) {
    _loadDataUri(sp, uri);
  } else {
    sp.send('Unknown scheme (${uri.scheme}) for $uri');
  }
}
