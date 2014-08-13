// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

void testCookies() {
  var cookies = [{'abc': 'def'},
                 {'ABC': 'DEF'},
                 {'Abc': 'Def'},
                 {'Abc': 'Def', 'SID': 'sffFSDF4FsdfF56765'}];

  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      // Collect the cookies in a map.
      var cookiesMap = {};
      request.cookies.forEach((c) => cookiesMap[c.name] = c.value);
      int index = int.parse(request.uri.path.substring(1));
      Expect.mapEquals(cookies[index], cookiesMap);
      // Return the same cookies to the client.
      cookiesMap.forEach((k, v) {
        request.response.cookies.add(new Cookie(k, v));
      });
      request.response.close();
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < cookies.length; i++) {
      client.get("127.0.0.1", server.port, "/$i")
          .then((request) {
            // Send the cookies to the server.
            cookies[i].forEach((k, v) {
              request.cookies.add(new Cookie(k, v));
            });
            return request.close();
          })
          .then((response) {
            // Expect the same cookies back.
            var cookiesMap = {};
            response.cookies.forEach((c) => cookiesMap[c.name] = c.value);
            Expect.mapEquals(cookies[i], cookiesMap);
            response.cookies.forEach((c) => Expect.isTrue(c.httpOnly));
            response.listen(
                (d) {},
                onDone: () {
                  if (++count == cookies.length) {
                    client.close();
                    server.close();
                  }
                });
          })
          .catchError((e, trace) {
            String msg = "Unexpected error $e";
            if (trace != null) msg += "\nStackTrace: $trace";
            Expect.fail(msg);
         });
    }
  });
}

void main() {
  testCookies();
}
