// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

const SESSION_ID = "DARTSESSID";

String getSessionId(List<Cookie> cookies) {
  var id = cookies.reduce(null, (last, cookie) {
    if (last != null) return last;
    if (cookie.name.toUpperCase() == SESSION_ID) {
      return cookie.value;
    }
    return null;
  });
  Expect.isNotNull(id);
  return id;
}

Future<String> connectGetSession(int port, [String session]) {
  var c = new Completer();
  var client = new HttpClient();
  var conn = client.get("127.0.0.1", port, "/");
  conn.onRequest = (request) {
    if (session != null) {
      request.cookies.add(new Cookie(SESSION_ID, session));
    }
    request.outputStream.close();
  };
  conn.onResponse = (response) {
    client.shutdown();
    c.complete(getSessionId(response.cookies));
  };
  return c.future;
}

void testSessions(int sessionCount) {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0);
  var sessions = new Set();
  server.defaultRequestHandler = (request, response) {
    sessions.add(request.session().id);
    response.outputStream.close();
  };

  var futures = [];
  for (int i = 0; i < sessionCount; i++) {
    futures.add(connectGetSession(server.port).chain((session) {
      Expect.isNotNull(session);
      Expect.isTrue(sessions.contains(session));
      return connectGetSession(server.port, session).transform((session2) {
        Expect.equals(session2, session);
        Expect.isTrue(sessions.contains(session2));
        return session2;
        });
    }));
  }
  Futures.wait(futures).then((clientSessions) {
    Expect.equals(sessions.length, sessionCount);
    Expect.setEquals(new Set.from(clientSessions), sessions);
    server.close();
  });
}

void testTimeout(int sessionCount) {
  HttpServer server = new HttpServer();
  server.sessionTimeout = 0;
  server.listen("127.0.0.1", 0);
  var timeouts = [];
  server.defaultRequestHandler = (request, response) {
    var c = new Completer();
    timeouts.add(c.future);
    request.session().onTimeout = () {
      c.complete(null);
    };
    response.outputStream.close();
  };

  var futures = [];
  for (int i = 0; i < sessionCount; i++) {
    futures.add(connectGetSession(server.port));
  }
  Futures.wait(futures).then((clientSessions) {
    Futures.wait(timeouts).then((_) {
      futures = [];
      for (var id in clientSessions) {
        futures.add(connectGetSession(server.port, id).transform((session) {
          Expect.isNotNull(session);
          Expect.notEquals(id, session);
        }));
      }
      Futures.wait(futures).then((_) {
        server.close();
      });
    });
  });
}

void main() {
  testSessions(5);
  testTimeout(5);
}
