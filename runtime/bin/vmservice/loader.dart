// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

var _httpClient;

// Send a response to the requesting isolate.
void _sendResponse(SendPort sp, int id, dynamic data) {
  assert((data is List<int>) || (data is String));
  var msg = new List(2);
  msg[0] = id;
  msg[1] = data;
  sp.send(msg);
}

void _loadHttp(SendPort sp, int id, Uri uri) {
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
              var msg = "Failure getting $uri:\n"
                        "  ${response.statusCode} ${response.reasonPhrase}";
              _sendResponse(sp, id, msg);
            } else {
              _sendResponse(sp, id, builder.takeBytes());
            }
          },
          onError: (e) {
            _sendResponse(sp, d, e.toString());
          });
    })
    .catchError((e) {
      _sendResponse(sp, id, e.toString());
    });
  // It's just here to push an event on the event loop so that we invoke the
  // scheduled microtasks.
  Timer.run(() {});
}

void _loadFile(SendPort sp, int id, Uri uri) {
  var path = uri.toFilePath();
  var sourceFile = new File(path);
  sourceFile.readAsBytes().then((data) {
    _sendResponse(sp, id, data);
  },
  onError: (e) {
    var err = "Error loading $uri:\n  $e";
    _sendResponse(sp, id, err);
  });
}

var dataUriRegex = new RegExp(
    r"data:([\w-]+/[\w-]+)?(;charset=([\w-]+))?(;base64)?,(.*)");

void _loadDataUri(SendPort sp, int id, Uri uri) {
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
    _sendResponse(sp, id, data);
  } catch (e) {
    _sendResponse(sp, id, "Invalid data uri ($uri):\n  $e");
  }
}

_processLoadRequest(request) {
  SendPort sp = request[0];
  int id = request[1];
  String resource = request[2];
  var uri = Uri.parse(request[2]);
  if (uri.scheme == 'file') {
    _loadFile(sp, id, uri);
  } else if ((uri.scheme == 'http') || (uri.scheme == 'https')) {
    _loadHttp(sp, id, uri);
  } else if ((uri.scheme == 'data')) {
    _loadDataUri(sp, id, uri);
  } else {
    sp.send([id, 'Unknown scheme (${uri.scheme}) for $uri']);
  }
}
