// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=http_server_response_test.dart

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:typed_data";

// Platform.script may refer to a AOT or JIT snapshot, which are significantly
// larger.
File scriptSource = new File(
    Platform.script.resolve("http_server_response_test.dart").toFilePath());

void testServerRequest(void handler(server, request),
    {int bytes, bool closeClient}) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.defaultResponseHeaders.clear();
    server.listen((request) {
      handler(server, request);
    });

    var client = new HttpClient();
    // We only close the client on either
    // - Bad response headers
    // - Response done (with optional errors in between).
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      int received = 0;
      var subscription;
      subscription = response.listen((data) {
        if (closeClient == true) {
          subscription.cancel();
          client.close();
        } else {
          received += data.length;
        }
      }, onDone: () {
        if (bytes != null) Expect.equals(received, bytes);
        client.close();
      }, onError: (error) {
        Expect.isTrue(error is HttpException);
      });
    }).catchError((error) {
      client.close();
    }, test: (e) => e is HttpException);
  });
}

void testResponseDone() {
  testServerRequest((server, request) {
    request.response.close();
    request.response.done.then((response) {
      Expect.equals(request.response, response);
      server.close();
    });
  });

  testServerRequest((server, request) {
    new File("__nonexistent_file_")
        .openRead()
        .pipe(request.response)
        .catchError((e) {
      server.close();
    });
  });

  testServerRequest((server, request) {
    request.response.done.then((_) {
      server.close();
    });
    request.response.contentLength = 0;
    request.response.close();
  });
}

void testResponseAddStream() {
  File file = scriptSource;
  int bytes = file.lengthSync();

  testServerRequest((server, request) {
    request.response.addStream(file.openRead()).then((response) {
      response.close();
      response.done.then((_) => server.close());
    });
  }, bytes: bytes);

  testServerRequest((server, request) {
    request.response.addStream(file.openRead()).then((response) {
      request.response.addStream(file.openRead()).then((response) {
        response.close();
        response.done.then((_) => server.close());
      });
    });
  }, bytes: bytes * 2);

  testServerRequest((server, request) {
    var controller = new StreamController(sync: true);
    request.response.addStream(controller.stream).then((response) {
      response.close();
      response.done.then((_) => server.close());
    });
    controller.close();
  }, bytes: 0);

  testServerRequest((server, request) {
    request.response
        .addStream(new File("__nonexistent_file_").openRead())
        .catchError((e) {
      server.close();
    });
  });

  testServerRequest((server, request) {
    new File("__nonexistent_file_")
        .openRead()
        .pipe(request.response)
        .catchError((e) {
      server.close();
    });
  });
}

void testResponseAddStreamClosed() {
  File file = scriptSource;
  testServerRequest((server, request) {
    request.response.addStream(file.openRead()).then((response) {
      response.close();
      response.done.then((_) => server.close());
    });
  }, closeClient: true);

  testServerRequest((server, request) {
    int count = 0;
    write() {
      request.response.addStream(file.openRead()).then((response) {
        request.response.write("sync data");
        count++;
        if (count < 1000) {
          write();
        } else {
          response.close();
          response.done.then((_) => server.close());
        }
      });
    }

    write();
  }, closeClient: true);
}

void testResponseAddClosed() {
  File file = scriptSource;
  testServerRequest((server, request) {
    request.response.add(file.readAsBytesSync());
    request.response.close();
    request.response.done.then((_) => server.close());
  }, closeClient: true);

  testServerRequest((server, request) {
    for (int i = 0; i < 1000; i++) {
      request.response.add(file.readAsBytesSync());
    }
    request.response.close();
    request.response.done.then((_) => server.close());
  }, closeClient: true);

  testServerRequest((server, request) {
    int count = 0;
    write() {
      request.response.add(file.readAsBytesSync());
      Timer.run(() {
        count++;
        if (count < 1000) {
          write();
        } else {
          request.response.close();
          request.response.done.then((_) => server.close());
        }
      });
    }

    write();
  }, closeClient: true);
}

void testBadResponseAdd() {
  testServerRequest((server, request) {
    request.response.contentLength = 0;
    request.response.add([0]);
    request.response.close();
    request.response.done.catchError((error) {
      server.close();
    }, test: (e) => e is HttpException);
  });

  testServerRequest((server, request) {
    request.response.contentLength = 5;
    request.response.add([0, 0, 0]);
    request.response.add([0, 0, 0]);
    request.response.close();
    request.response.done.catchError((error) {
      server.close();
    }, test: (e) => e is HttpException);
  });

  testServerRequest((server, request) {
    request.response.contentLength = 0;
    request.response.add(new Uint8List(64 * 1024));
    request.response.add(new Uint8List(64 * 1024));
    request.response.add(new Uint8List(64 * 1024));
    request.response.close();
    request.response.done.catchError((error) {
      server.close();
    }, test: (e) => e is HttpException);
  });
}

void testBadResponseClose() {
  testServerRequest((server, request) {
    request.response.contentLength = 5;
    request.response.close();
    request.response.done.catchError((error) {
      server.close();
    }, test: (e) => e is HttpException);
  });

  testServerRequest((server, request) {
    request.response.contentLength = 5;
    request.response.add([0]);
    request.response.close();
    request.response.done.catchError((error) {
      server.close();
    }, test: (e) => e is HttpException);
  });
}

void testIgnoreRequestData() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      // Ignore request data.
      request.response.write("all-okay");
      request.response.close();
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/").then((request) {
      request.contentLength = 1024 * 1024;
      request.add(new Uint8List(1024 * 1024));
      return request.close();
    }).then((response) {
      response.fold(0, (s, b) => s + b.length).then((bytes) {
        Expect.equals(8, bytes);
        server.close();
      });
    });
  });
}

void testWriteCharCode() {
  testServerRequest((server, request) {
    // Test that default is latin-1 (only 2 bytes).
    request.response.writeCharCode(0xFF);
    request.response.writeCharCode(0xFF);
    request.response.close().then((_) {
      server.close();
    });
  }, bytes: 2);
}

void main() {
  testResponseDone();
  testResponseAddStream();
  testResponseAddStreamClosed();
  testResponseAddClosed();
  testBadResponseAdd();
  testBadResponseClose();
  testIgnoreRequestData();
  testWriteCharCode();
}
