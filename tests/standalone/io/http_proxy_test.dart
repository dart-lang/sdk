// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import 'dart:crypto';
import "dart:io";
import "dart:uri";
import 'dart:utf';

class Server {
  HttpServer server;
  bool secure;
  int proxyHops;
  List<String> directRequestPaths;
  int requestCount = 0;

  Server(this.proxyHops, this.directRequestPaths, this.secure);

  Future<Server> start() {
    var x = new Completer();
    Future f = secure
        ? HttpServer.bindSecure(
            "127.0.0.1", 0, certificateName: 'localhost_cert')
        : HttpServer.bind();
    return f.then((s) {
      server = s;
      x.complete(this);
      server.listen((request) {
        var response = request.response;
        requestCount++;
        // Check whether a proxy or direct connection is expected.
        bool direct = directRequestPaths.fold(
            false,
            (prev, path) => prev ? prev : path == request.uri.path);
        if (!direct && proxyHops > 0) {
          Expect.isNotNull(request.headers[HttpHeaders.VIA]);
          Expect.equals(1, request.headers[HttpHeaders.VIA].length);
          Expect.equals(
              proxyHops,
              request.headers[HttpHeaders.VIA][0].split(",").length);
        } else {
          Expect.isNull(request.headers[HttpHeaders.VIA]);
        }
        var body = new StringBuffer();
        request.listen(
            (data) {
              body.write(new String.fromCharCodes(data));
            },
            onDone: () {
              String path = request.uri.path.substring(1);
              if (path != "A") {
                String content = "$path$path$path";
                Expect.equals(content, body.toString());
              }
              response.write(request.uri.path);
              response.close();
            });
      });
      return x.future;
    });
  }

  void shutdown() {
    server.close();
  }

  int get port => server.port;
}

Future<Server> setupServer(int proxyHops,
                   {List<String> directRequestPaths: const <String>[],
                    secure: false}) {
  Server server = new Server(proxyHops, directRequestPaths, secure);
  return server.start();
}

class ProxyServer {
  HttpServer server;
  HttpClient client;
  int requestCount = 0;
  String username;
  String password;

  ProxyServer() : client = new HttpClient();

  authenticationRequired(request) {
    request.fold(null, (x, y) {}).then((_) {
      var response = request.response;
      response.headers.set(HttpHeaders.PROXY_AUTHENTICATE,
                           "Basic, realm=realm");
      response.statusCode = HttpStatus.PROXY_AUTHENTICATION_REQUIRED;
      response.close();
    });
  }

  Future<ProxyServer> start() {
    var x = new Completer();
    HttpServer.bind().then((s) {
      server = s;
      x.complete(this);
      server.listen((HttpRequest request) {
        requestCount++;
        if (username != null && password != null) {
          if (request.headers[HttpHeaders.PROXY_AUTHORIZATION] == null) {
            authenticationRequired(request);
            return;
          } else {
            Expect.equals(
                1, request.headers[HttpHeaders.PROXY_AUTHORIZATION].length);
            String authorization =
              request.headers[HttpHeaders.PROXY_AUTHORIZATION][0];
            List<String> tokens = authorization.split(" ");
            Expect.equals("Basic", tokens[0]);
            String auth =
                CryptoUtils.bytesToBase64(encodeUtf8("$username:$password"));
            if (auth != tokens[1]) {
              authenticationRequired(request);
              return;
            }
          }
        }
        // Open the connection from the proxy.
        client.openUrl(request.method, request.uri)
          .then((HttpClientRequest clientRequest) {
            // Forward all headers.
            request.headers.forEach((String name, List<String> values) {
              values.forEach((String value) {
                if (name != "content-length" && name != "via") {
                  clientRequest.headers.add(name, value);
                }
              });
            });
            // Special handling of Content-Length and Via.
            clientRequest.contentLength = request.contentLength;
            List<String> via = request.headers[HttpHeaders.VIA];
            String viaPrefix = via == null ? "" : "${via[0]}, ";
            clientRequest.headers.add(
                HttpHeaders.VIA, "${viaPrefix}1.1 localhost:$port");
            // Copy all content.
            return request.pipe(clientRequest);
          })
          .then((HttpClientResponse clientResponse) {
            clientResponse.pipe(request.response);
          });
      });
    });
    return x.future;
  }

  void shutdown() {
    server.close();
    client.close();
  }

  int get port => server.port;
}

Future<ProxyServer> setupProxyServer() {
  ProxyServer proxyServer = new ProxyServer();
  return proxyServer.start();
}

testInvalidProxy() {
  HttpClient client = new HttpClient();

  client.findProxy = (Uri uri) => "";
  client.getUrl(Uri.parse("http://www.google.com/test"))
    .catchError((error) {}, test: (e) => e is HttpException);

  client.findProxy = (Uri uri) => "XXX";
  client.getUrl(Uri.parse("http://www.google.com/test"))
    .catchError((error) {}, test: (e) => e is HttpException);

  client.findProxy = (Uri uri) => "PROXY www.google.com";
  client.getUrl(Uri.parse("http://www.google.com/test"))
    .catchError((error) {}, test: (e) => e is HttpException);

  client.findProxy = (Uri uri) => "PROXY www.google.com:http";
  client.getUrl(Uri.parse("http://www.google.com/test"))
    .catchError((error) {}, test: (e) => e is HttpException);
}

int testDirectDoneCount = 0;
void testDirectProxy() {
  setupServer(0).then((server) {
    HttpClient client = new HttpClient();
    List<String> proxy =
        ["DIRECT", " DIRECT ", "DIRECT ;", " DIRECT ; ",
         ";DIRECT", " ; DIRECT ", ";;DIRECT;;"];

    client.findProxy = (Uri uri) {
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client.getUrl(Uri.parse("http://127.0.0.1:${server.port}/$i"))
        .then((HttpClientRequest clientRequest) {
          String content = "$i$i$i";
          clientRequest.contentLength = content.length;
          clientRequest.write(content);
          return clientRequest.close();
        })
       .then((HttpClientResponse response) {
          response.listen((_) {}, onDone: () {
            testDirectDoneCount++;
            if (testDirectDoneCount == proxy.length) {
              Expect.equals(proxy.length, server.requestCount);
              server.shutdown();
              client.close();
            }
          });
        });
    }
  });
}

int testProxyDoneCount = 0;
void testProxy() {
  setupProxyServer().then((proxyServer) {
  setupServer(1, directRequestPaths: ["/4"]).then((server) {
  setupServer(1, directRequestPaths: ["/4"], secure: true).then((secureServer) {
    HttpClient client = new HttpClient();

    List<String> proxy;
    if (Platform.operatingSystem == "windows") {
      proxy =
          ["PROXY localhost:${proxyServer.port}",
           "PROXY localhost:${proxyServer.port}; PROXY hede.hule.hest:8080",
           "PROXY localhost:${proxyServer.port}",
           ""
               " PROXY localhost:${proxyServer.port}",
           "DIRECT",
           "PROXY localhost:${proxyServer.port}; DIRECT"];
    } else {
      proxy =
          ["PROXY localhost:${proxyServer.port}",
           "PROXY localhost:${proxyServer.port}; PROXY hede.hule.hest:8080",
           "PROXY hede.hule.hest:8080; PROXY localhost:${proxyServer.port}",
           "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181;"
               " PROXY localhost:${proxyServer.port}",
           "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; DIRECT",
           "PROXY localhost:${proxyServer.port}; DIRECT"];
    }
    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      test(bool secure) {
        String url = secure
            ? "https://localhost:${secureServer.port}/$i"
            : "http://127.0.0.1:${server.port}/$i";

        client.postUrl(Uri.parse(url))
          .then((HttpClientRequest clientRequest) {
            String content = "$i$i$i";
            clientRequest.write(content);
            return clientRequest.close();
          })
          .then((HttpClientResponse response) {
            response.listen((_) {}, onDone: () {
              testProxyDoneCount++;
              if (testProxyDoneCount == proxy.length * 2) {
                Expect.equals(proxy.length, server.requestCount);
                Expect.equals(proxy.length, secureServer.requestCount);
                proxyServer.shutdown();
                server.shutdown();
                secureServer.shutdown();
                client.close();
              }
            });
          });
      }

      test(false);
      test(true);
    }
  });
  });
  });
}

int testProxyChainDoneCount = 0;
void testProxyChain() {
  // Setup two proxy servers having the first using the second as its proxy.
  setupProxyServer().then((proxyServer1) {
  setupProxyServer().then((proxyServer2) {
  proxyServer1.client.findProxy = (_) => "PROXY 127.0.0.1:${proxyServer2.port}";

  setupServer(2, directRequestPaths: ["/4"]).then((server) {
    HttpClient client = new HttpClient();

    List<String> proxy;
    if (Platform.operatingSystem == "windows") {
      proxy =
          ["PROXY localhost:${proxyServer1.port}",
           "PROXY localhost:${proxyServer1.port}; PROXY hede.hule.hest:8080",
           "PROXY localhost:${proxyServer1.port}",
           "PROXY localhost:${proxyServer1.port}",
           "DIRECT",
           "PROXY localhost:${proxyServer1.port}; DIRECT"];
    } else {
      proxy =
          ["PROXY localhost:${proxyServer1.port}",
           "PROXY localhost:${proxyServer1.port}; PROXY hede.hule.hest:8080",
           "PROXY hede.hule.hest:8080; PROXY localhost:${proxyServer1.port}",
           "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181;"
               " PROXY localhost:${proxyServer1.port}",
           "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; DIRECT",
           "PROXY localhost:${proxyServer1.port}; DIRECT"];
    }

    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client.getUrl(Uri.parse("http://127.0.0.1:${server.port}/$i"))
        .then((HttpClientRequest clientRequest) {
          String content = "$i$i$i";
          clientRequest.contentLength = content.length;
          clientRequest.write(content);
          return clientRequest.close();
        })
        .then((HttpClientResponse response) {
          response.listen((_) {}, onDone: () {
            testProxyChainDoneCount++;
            if (testProxyChainDoneCount == proxy.length) {
              Expect.equals(proxy.length, server.requestCount);
              proxyServer1.shutdown();
              proxyServer2.shutdown();
              server.shutdown();
              client.close();
            }
          });
        });
    }
  });
  });
  });
}

int testProxyFromEnviromentDoneCount = 0;
void testProxyFromEnviroment() {
  setupProxyServer().then((proxyServer) {
  setupServer(1).then((server) {
  setupServer(1, secure: true).then((secureServer) {
    HttpClient client = new HttpClient();

    client.findProxy = (Uri uri) {
      return HttpClient.findProxyFromEnvironment(
          uri,
          environment: {"http_proxy": "localhost:${proxyServer.port}",
                        "https_proxy": "localhost:${proxyServer.port}"});
    };

    const int loopCount = 5;
    for (int i = 0; i < loopCount; i++) {
      test(bool secure) {
        String url = secure
            ? "https://localhost:${secureServer.port}/$i"
            : "http://127.0.0.1:${server.port}/$i";

        client.postUrl(Uri.parse(url))
          .then((HttpClientRequest clientRequest) {
            String content = "$i$i$i";
            clientRequest.write(content);
            return clientRequest.close();
          })
          .then((HttpClientResponse response) {
            response.listen((_) {}, onDone: () {
              testProxyFromEnviromentDoneCount++;
              if (testProxyFromEnviromentDoneCount == loopCount * 2) {
                Expect.equals(loopCount, server.requestCount);
                Expect.equals(loopCount, secureServer.requestCount);
                proxyServer.shutdown();
                server.shutdown();
                secureServer.shutdown();
                client.close();
              }
            });
          });
      }

      test(false);
      test(true);
    }
  });
  });
  });
}


int testProxyAuthenticateCount = 0;
void testProxyAuthenticate() {
  setupProxyServer().then((proxyServer) {
  proxyServer.username = "test";
  proxyServer.password = "test";
  setupServer(1).then((server) {
  setupServer(1, secure: true).then((secureServer) {
    HttpClient client = new HttpClient();

    Completer step1 = new Completer();
    Completer step2 = new Completer();

    // Test with no authentication.
    client.findProxy = (Uri uri) {
      return "PROXY localhost:${proxyServer.port}";
    };

    const int loopCount = 2;
    for (int i = 0; i < loopCount; i++) {
      test(bool secure) {
        String url = secure
            ? "https://localhost:${secureServer.port}/$i"
            : "http://127.0.0.1:${server.port}/$i";

        client.postUrl(Uri.parse(url))
          .then((HttpClientRequest clientRequest) {
            String content = "$i$i$i";
            clientRequest.write(content);
            return clientRequest.close();
          })
          .then((HttpClientResponse response) {
            response.listen((_) {}, onDone: () {
              testProxyAuthenticateCount++;
              Expect.equals(HttpStatus.PROXY_AUTHENTICATION_REQUIRED,
                            response.statusCode);
              if (testProxyAuthenticateCount == loopCount * 2) {
                Expect.equals(0, server.requestCount);
                Expect.equals(0, secureServer.requestCount);
                step1.complete(null);
              }
            });
          });
      }

      test(false);
      test(true);
    }

    step1.future.then((_) {
      testProxyAuthenticateCount = 0;
      client.findProxy = (Uri uri) {
        return "PROXY test:test@localhost:${proxyServer.port}";
      };

      for (int i = 0; i < loopCount; i++) {
        test(bool secure) {
          String url = secure
              ? "https://localhost:${secureServer.port}/$i"
              : "http://127.0.0.1:${server.port}/$i";

          client.postUrl(Uri.parse(url))
            .then((HttpClientRequest clientRequest) {
              String content = "$i$i$i";
              clientRequest.write(content);
              return clientRequest.close();
            })
            .then((HttpClientResponse response) {
              response.listen((_) {}, onDone: () {
                testProxyAuthenticateCount++;
                Expect.equals(HttpStatus.OK, response.statusCode);
                if (testProxyAuthenticateCount == loopCount * 2) {
                  Expect.equals(loopCount, server.requestCount);
                  Expect.equals(loopCount, secureServer.requestCount);
                  step2.complete(null);
                }
              });
            });
        }

        test(false);
        test(true);
      }
    });

    step2.future.then((_) {
      testProxyAuthenticateCount = 0;
      client.findProxy = (Uri uri) {
        return "PROXY localhost:${proxyServer.port}";
      };

      client.authenticateProxy = (host, port, scheme, realm) {
        client.addProxyCredentials(
            "localhost",
            proxyServer.port,
            "realm",
            new HttpClientBasicCredentials("test", "test"));
        return new Future.value(true);
      };

      for (int i = 0; i < loopCount; i++) {
        test(bool secure) {
          String url = secure
              ? "https://localhost:${secureServer.port}/A"
              : "http://127.0.0.1:${server.port}/A";

          client.postUrl(Uri.parse(url))
            .then((HttpClientRequest clientRequest) {
              String content = "$i$i$i";
              clientRequest.write(content);
              return clientRequest.close();
            })
            .then((HttpClientResponse response) {
              response.listen((_) {}, onDone: () {
                testProxyAuthenticateCount++;
                Expect.equals(HttpStatus.OK, response.statusCode);
                if (testProxyAuthenticateCount == loopCount * 2) {
                  Expect.equals(loopCount * 2, server.requestCount);
                  Expect.equals(loopCount * 2, secureServer.requestCount);
                  proxyServer.shutdown();
                  server.shutdown();
                  secureServer.shutdown();
                  client.close();
                }
              });
            });
        }
        test(false);
        test(true);
      }
    });

  });
  });
  });
}

int testRealProxyDoneCount = 0;
void testRealProxy() {
  setupServer(1).then((server) {
    HttpClient client = new HttpClient();
     client.addProxyCredentials("localhost",
                                8080,
                                "test",
                                new HttpClientBasicCredentials("test", "test"));

    List<String> proxy =
        ["PROXY localhost:8080",
         "PROXY localhost:8080; PROXY hede.hule.hest:8080",
         "PROXY hede.hule.hest:8080; PROXY localhost:8080",
         "PROXY localhost:8080; DIRECT"];

    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client.getUrl(Uri.parse("http://127.0.0.1:${server.port}/$i"))
        .then((HttpClientRequest clientRequest) {
          String content = "$i$i$i";
          clientRequest.contentLength = content.length;
          clientRequest.write(content);
          return clientRequest.close();
        })
        .then((HttpClientResponse response) {
          response.listen((_) {}, onDone: () {
            if (++testRealProxyDoneCount == proxy.length) {
              Expect.equals(proxy.length, server.requestCount);
              server.shutdown();
              client.close();
            }
          });
        });
    }
  });
}

int testRealProxyAuthDoneCount = 0;
void testRealProxyAuth() {
  setupServer(1).then((server) {
    HttpClient client = new HttpClient();

    List<String> proxy =
        ["PROXY test:test@localhost:8080",
         "PROXY test:test@localhost:8080; PROXY hede.hule.hest:8080",
         "PROXY hede.hule.hest:8080; PROXY test:test@localhost:8080",
         "PROXY test:test@localhost:8080; DIRECT"];

    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client.getUrl(Uri.parse("http://127.0.0.1:${server.port}/$i"))
        .then((HttpClientRequest clientRequest) {
          String content = "$i$i$i";
          clientRequest.contentLength = content.length;
          clientRequest.write(content);
          return clientRequest.close();
        })
        .then((HttpClientResponse response) {
          response.listen((_) {}, onDone: () {
            if (++testRealProxyAuthDoneCount == proxy.length) {
              Expect.equals(proxy.length, server.requestCount);
              server.shutdown();
              client.close();
            }
          });
        });
    }
  });
}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: 'dartdart');
}

main() {
  InitializeSSL();
  testInvalidProxy();
  testDirectProxy();
  testProxy();
  testProxyChain();
  testProxyFromEnviroment();
  testProxyAuthenticate();
  // This test is not normally run. It can be used for locally testing
  // with a real proxy server (e.g. Apache).
  //testRealProxy();
  //testRealProxyAuth();
}
