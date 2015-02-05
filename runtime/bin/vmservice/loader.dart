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

_processLoadRequest(request) {
  var sp = request[0];
  var uri = Uri.parse(request[1]);
  if (uri.scheme == 'file') {
    _loadFile(sp, uri.toFilePath());
  } else if ((uri.scheme == 'http') || (uri.scheme == 'https')) {
    _loadHttp(sp, uri);
  } else {
    sp.send('Unknown scheme for $uri');
  }
}