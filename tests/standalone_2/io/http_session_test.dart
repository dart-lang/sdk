// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';

const SESSION_ID = "DARTSESSID";

String getSessionId(List<Cookie> cookies) {
  var id = cookies.fold(null, (last, cookie) {
    if (last != null) return last;
    if (cookie.name.toUpperCase() == SESSION_ID) {
      Expect.isTrue(cookie.httpOnly);
      return cookie.value;
    }
    return null;
  });
  Expect.isNotNull(id);
  return id;
}

Future<String> connectGetSession(HttpClient client, int port,
    [String session]) {
  return client.get("127.0.0.1", port, "/").then((request) {
    if (session != null) {
      request.cookies.add(new Cookie(SESSION_ID, session));
    }
    return request.close();
  }).then((response) {
    return response.fold(getSessionId(response.cookies), (v, _) => v);
  });
}

void testSessions(int sessionCount) {
  var client = new HttpClient();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var sessions = new Set();
    server.listen((request) {
      sessions.add(request.session.id);
      request.response.close();
    });

    var futures = <Future>[];
    for (int i = 0; i < sessionCount; i++) {
      futures.add(connectGetSession(client, server.port).then((session) {
        Expect.isNotNull(session);
        Expect.isTrue(sessions.contains(session));
        return connectGetSession(client, server.port, session).then((session2) {
          Expect.equals(session2, session);
          Expect.isTrue(sessions.contains(session2));
          return session2;
        });
      }));
    }
    Future.wait(futures).then((clientSessions) {
      Expect.equals(sessions.length, sessionCount);
      Expect.setEquals(new Set.from(clientSessions), sessions);
      server.close();
      client.close();
    });
  });
}

void testTimeout(int sessionCount) {
  var client = new HttpClient();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.sessionTimeout = 1;
    var timeouts = <Future>[];
    server.listen((request) {
      var c = new Completer();
      timeouts.add(c.future);
      request.session.onTimeout = () {
        c.complete(null);
      };
      request.response.close();
    });

    var futures = <Future>[];
    for (int i = 0; i < sessionCount; i++) {
      futures.add(connectGetSession(client, server.port));
    }
    Future.wait(futures).then((clientSessions) {
      Future.wait(timeouts).then((_) {
        futures = <Future>[];
        for (var id in clientSessions) {
          futures
              .add(connectGetSession(client, server.port, id).then((session) {
            Expect.isNotNull(session);
            Expect.notEquals(id, session);
          }));
        }
        Future.wait(futures).then((_) {
          server.close();
          client.close();
        });
      });
    });
  });
}

void testSessionsData() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    bool firstHit = false;
    bool secondHit = false;
    server.listen((request) {
      var c = new Completer();
      var session = request.session;
      if (session.isNew) {
        Expect.isFalse(firstHit);
        Expect.isFalse(secondHit);
        firstHit = true;
        session["data"] = "some data";
      } else {
        Expect.isTrue(firstHit);
        Expect.isFalse(secondHit);
        secondHit = true;
        Expect.isTrue(session.containsKey("data"));
        Expect.equals("some data", session["data"]);
      }
      ;
      request.response.close();
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}, onDone: () {
        var id = getSessionId(response.cookies);
        Expect.isNotNull(id);
        client.get("127.0.0.1", server.port, "/").then((request) {
          request.cookies.add(new Cookie(SESSION_ID, id));
          return request.close();
        }).then((response) {
          response.listen((_) {}, onDone: () {
            Expect.isTrue(firstHit);
            Expect.isTrue(secondHit);
            Expect.equals(id, getSessionId(response.cookies));
            server.close();
            client.close();
          });
        });
      });
    });
  });
}

void testSessionsDestroy() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    bool firstHit = false;
    server.listen((request) {
      var session = request.session;
      if (session.isNew) {
        Expect.isFalse(firstHit);
        firstHit = true;
      } else {
        Expect.isTrue(firstHit);
        session.destroy();
        var session2 = request.session;
        Expect.notEquals(session.id, session2.id);
      }
      ;
      request.response.close();
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}, onDone: () {
        var id = getSessionId(response.cookies);
        Expect.isNotNull(id);
        client.get("127.0.0.1", server.port, "/").then((request) {
          request.cookies.add(new Cookie(SESSION_ID, id));
          return request.close();
        }).then((response) {
          response.listen((_) {}, onDone: () {
            Expect.isTrue(firstHit);
            Expect.notEquals(id, getSessionId(response.cookies));
            server.close();
            client.close();
          });
        });
      });
    });
  });
}

void main() {
  testSessions(1);
  testTimeout(5);
  testSessionsData();
  testSessionsDestroy();
}
