// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Future downloadFile(Uri url, String destination) {
  var client = new HttpClient();
  return client
      .getUrl(url)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
    if (response.statusCode != HttpStatus.OK) {
      throw new Exception("Http status code (${response.statusCode}) "
          "was not 200. Aborting.");
    }
    var sink = new File(destination).openWrite();
    return response.pipe(sink).then((_) {
      client.close();
    });
  });
}

void main(List<String> arguments) {
  die(String message) {
    print(message);
    exit(1);
  }

  if (arguments.length != 2) {
    var scriptName = Platform.script.pathSegments.last;
    die("Usage dart $scriptName <url> <destination-file>");
  }

  var url = Uri.parse(arguments[0]);
  var destination = arguments[1];

  if (!['http', 'https'].contains(url.scheme)) {
    die("Unsupported scheme in uri $url");
  }

  print("Downloading $url to $destination.");
  downloadFile(url, destination).then((_) {
    print("Download finished.");
  }).catchError((error) {
    die("An unexpected error occured: $error.");
  });
}
