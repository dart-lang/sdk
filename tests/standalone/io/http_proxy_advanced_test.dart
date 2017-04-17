// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "package:convert/convert.dart";
import "package:crypto/crypto.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";
import 'dart:convert';

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

class Server {
  HttpServer server;
  bool secure;
  int proxyHops;
  List<String> directRequestPaths;
  int requestCount = 0;

  Server(this.proxyHops, this.directRequestPaths, this.secure);

  Future<Server> start() {
    return (secure
        ? HttpServer.bindSecure("localhost", 0, serverContext)
        : HttpServer.bind("localhost", 0)).then((s) {
      server = s;
      server.listen(requestHandler);
      return this;
    });
  }

  void requestHandler(HttpRequest request) {
    var response = request.response;
    requestCount++;
    // Check whether a proxy or direct connection is expected.
    bool direct = directRequestPaths.fold(
        false, (prev, path) => prev ? prev : path == request.uri.path);
    if (!secure && !direct && proxyHops > 0) {
      Expect.isNotNull(request.headers[HttpHeaders.VIA]);
      Expect.equals(1, request.headers[HttpHeaders.VIA].length);
      Expect.equals(
          proxyHops, request.headers[HttpHeaders.VIA][0].split(",").length);
    } else {
      Expect.isNull(request.headers[HttpHeaders.VIA]);
    }
    var body = new StringBuffer();
    onRequestComplete() {
      String path = request.uri.path.substring(1);
      if (path != "A") {
        String content = "$path$path$path";
        Expect.equals(content, body.toString());
      }
      response.write(request.uri.path);
      response.close();
    }

    request.listen((data) {
      body.write(new String.fromCharCodes(data));
    }, onDone: onRequestComplete);
  }

  void shutdown() {
    server.close();
  }

  int get port => server.port;
}

Future<Server> setupServer(int proxyHops,
    {List<String> directRequestPaths: const <String>[], secure: false}) {
  Server server = new Server(proxyHops, directRequestPaths, secure);
  return server.start();
}

class ProxyServer {
  final bool ipV6;
  HttpServer server;
  HttpClient client;
  int requestCount = 0;
  String authScheme;
  String realm = "test";
  String username;
  String password;

  var ha1;
  String serverAlgorithm = "MD5";
  String serverQop = "auth";
  Set ncs = new Set();

  var nonce = "12345678"; // No need for random nonce in test.

  ProxyServer({this.ipV6: false}) : client = new HttpClient();

  void useBasicAuthentication(String username, String password) {
    this.username = username;
    this.password = password;
    authScheme = "Basic";
  }

  void useDigestAuthentication(String username, String password) {
    this.username = username;
    this.password = password;
    authScheme = "Digest";

    // Calculate ha1.
    var digest = md5.convert("${username}:${realm}:${password}".codeUnits);
    ha1 = hex.encode(digest.bytes);
  }

  basicAuthenticationRequired(request) {
    request.fold(null, (x, y) {}).then((_) {
      var response = request.response;
      response.headers
          .set(HttpHeaders.PROXY_AUTHENTICATE, "Basic, realm=$realm");
      response.statusCode = HttpStatus.PROXY_AUTHENTICATION_REQUIRED;
      response.close();
    });
  }

  digestAuthenticationRequired(request, {stale: false}) {
    request.fold(null, (x, y) {}).then((_) {
      var response = request.response;
      response.statusCode = HttpStatus.PROXY_AUTHENTICATION_REQUIRED;
      StringBuffer authHeader = new StringBuffer();
      authHeader.write('Digest');
      authHeader.write(', realm="$realm"');
      authHeader.write(', nonce="$nonce"');
      if (stale) authHeader.write(', stale="true"');
      if (serverAlgorithm != null) {
        authHeader.write(', algorithm=$serverAlgorithm');
      }
      if (serverQop != null) authHeader.write(', qop="$serverQop"');
      response.headers.set(HttpHeaders.PROXY_AUTHENTICATE, authHeader);
      response.close();
    });
  }

  Future<ProxyServer> start() {
    var x = new Completer();
    var host = ipV6 ? "::1" : "localhost";
    HttpServer.bind(host, 0).then((s) {
      server = s;
      x.complete(this);
      server.listen((HttpRequest request) {
        requestCount++;
        if (username != null && password != null) {
          if (request.headers[HttpHeaders.PROXY_AUTHORIZATION] == null) {
            if (authScheme == "Digest") {
              digestAuthenticationRequired(request);
            } else {
              basicAuthenticationRequired(request);
            }
            return;
          } else {
            Expect.equals(
                1, request.headers[HttpHeaders.PROXY_AUTHORIZATION].length);
            String authorization =
                request.headers[HttpHeaders.PROXY_AUTHORIZATION][0];
            if (authScheme == "Basic") {
              List<String> tokens = authorization.split(" ");
              Expect.equals("Basic", tokens[0]);
              String auth = BASE64.encode(UTF8.encode("$username:$password"));
              if (auth != tokens[1]) {
                basicAuthenticationRequired(request);
                return;
              }
            } else {
              HeaderValue header =
                  HeaderValue.parse(authorization, parameterSeparator: ",");
              Expect.equals("Digest", header.value);
              var uri = header.parameters["uri"];
              var qop = header.parameters["qop"];
              var cnonce = header.parameters["cnonce"];
              var nc = header.parameters["nc"];
              Expect.equals(username, header.parameters["username"]);
              Expect.equals(realm, header.parameters["realm"]);
              Expect.equals("MD5", header.parameters["algorithm"]);
              Expect.equals(nonce, header.parameters["nonce"]);
              Expect.equals(request.uri.toString(), uri);
              if (qop != null) {
                // A server qop of auth-int is downgraded to none by the client.
                Expect.equals("auth", serverQop);
                Expect.equals("auth", header.parameters["qop"]);
                Expect.isNotNull(cnonce);
                Expect.isNotNull(nc);
                Expect.isFalse(ncs.contains(nc));
                ncs.add(nc);
              } else {
                Expect.isNull(cnonce);
                Expect.isNull(nc);
              }
              Expect.isNotNull(header.parameters["response"]);

              var digest = md5.convert("${request.method}:${uri}".codeUnits);
              var ha2 = hex.encode(digest.bytes);

              var x;
              if (qop == null || qop == "" || qop == "none") {
                digest = md5.convert("$ha1:${nonce}:$ha2".codeUnits);
              } else {
                digest = md5.convert(
                    "$ha1:${nonce}:${nc}:${cnonce}:${qop}:$ha2".codeUnits);
              }
              Expect.equals(
                  hex.encode(digest.bytes), header.parameters["response"]);

              // Add a bogus Proxy-Authentication-Info for testing.
              var info = 'rspauth="77180d1ab3d6c9de084766977790f482", '
                  'cnonce="8f971178", '
                  'nc=000002c74, '
                  'qop=auth';
              request.response.headers.set("Proxy-Authentication-Info", info);
            }
          }
        }
        // Open the connection from the proxy.
        if (request.method == "CONNECT") {
          var tmp = request.uri.toString().split(":");
          Socket.connect(tmp[0], int.parse(tmp[1])).then((socket) {
            request.response.reasonPhrase = "Connection established";
            request.response.detachSocket().then((detached) {
              socket.pipe(detached);
              detached.pipe(socket);
            });
          });
        } else {
          client
              .openUrl(request.method, request.uri)
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
            clientRequest.headers
                .add(HttpHeaders.VIA, "${viaPrefix}1.1 localhost:$port");
            // Copy all content.
            return request.pipe(clientRequest);
          }).then((HttpClientResponse clientResponse) {
            clientResponse.pipe(request.response);
          });
        }
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

Future<ProxyServer> setupProxyServer({ipV6: false}) {
  ProxyServer proxyServer = new ProxyServer(ipV6: ipV6);
  return proxyServer.start();
}

int testProxyIPV6DoneCount = 0;
void testProxyIPV6() {
  setupProxyServer(ipV6: true).then((proxyServer) {
    setupServer(1, directRequestPaths: ["/4"]).then((server) {
      setupServer(1, directRequestPaths: ["/4"], secure: true)
          .then((secureServer) {
        HttpClient client = new HttpClient(context: clientContext);

        List<String> proxy = ["PROXY [::1]:${proxyServer.port}"];
        client.findProxy = (Uri uri) {
          // Pick the proxy configuration based on the request path.
          int index = int.parse(uri.path.substring(1));
          return proxy[index];
        };

        for (int i = 0; i < proxy.length; i++) {
          test(bool secure) {
            String url = secure
                ? "https://localhost:${secureServer.port}/$i"
                : "http://localhost:${server.port}/$i";

            client
                .postUrl(Uri.parse(url))
                .then((HttpClientRequest clientRequest) {
              String content = "$i$i$i";
              clientRequest.write(content);
              return clientRequest.close();
            }).then((HttpClientResponse response) {
              response.listen((_) {}, onDone: () {
                testProxyIPV6DoneCount++;
                if (testProxyIPV6DoneCount == proxy.length * 2) {
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

int testProxyFromEnviromentDoneCount = 0;
void testProxyFromEnviroment() {
  setupProxyServer().then((proxyServer) {
    setupServer(1).then((server) {
      setupServer(1, secure: true).then((secureServer) {
        HttpClient client = new HttpClient(context: clientContext);

        client.findProxy = (Uri uri) {
          return HttpClient.findProxyFromEnvironment(uri, environment: {
            "http_proxy": "localhost:${proxyServer.port}",
            "https_proxy": "localhost:${proxyServer.port}"
          });
        };

        const int loopCount = 5;
        for (int i = 0; i < loopCount; i++) {
          test(bool secure) {
            String url = secure
                ? "https://localhost:${secureServer.port}/$i"
                : "http://localhost:${server.port}/$i";

            client
                .postUrl(Uri.parse(url))
                .then((HttpClientRequest clientRequest) {
              String content = "$i$i$i";
              clientRequest.write(content);
              return clientRequest.close();
            }).then((HttpClientResponse response) {
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
Future testProxyAuthenticate(bool useDigestAuthentication) {
  testProxyAuthenticateCount = 0;
  var completer = new Completer();

  setupProxyServer().then((proxyServer) {
    setupServer(1).then((server) {
      setupServer(1, secure: true).then((secureServer) {
        HttpClient client = new HttpClient(context: clientContext);

        Completer step1 = new Completer();
        Completer step2 = new Completer();

        if (useDigestAuthentication) {
          proxyServer.useDigestAuthentication("dart", "password");
        } else {
          proxyServer.useBasicAuthentication("dart", "password");
        }

        // Test with no authentication.
        client.findProxy = (Uri uri) {
          return "PROXY localhost:${proxyServer.port}";
        };

        const int loopCount = 2;
        for (int i = 0; i < loopCount; i++) {
          test(bool secure) {
            String url = secure
                ? "https://localhost:${secureServer.port}/$i"
                : "http://localhost:${server.port}/$i";

            client
                .postUrl(Uri.parse(url))
                .then((HttpClientRequest clientRequest) {
              String content = "$i$i$i";
              clientRequest.write(content);
              return clientRequest.close();
            }).then((HttpClientResponse response) {
              Expect.fail("No response expected");
            }).catchError((e) {
              testProxyAuthenticateCount++;
              if (testProxyAuthenticateCount == loopCount * 2) {
                Expect.equals(0, server.requestCount);
                Expect.equals(0, secureServer.requestCount);
                step1.complete(null);
              }
            });
          }

          test(false);
          test(true);
        }
        step1.future.then((_) {
          testProxyAuthenticateCount = 0;
          if (useDigestAuthentication) {
            client.findProxy =
                (Uri uri) => "PROXY localhost:${proxyServer.port}";
            client.addProxyCredentials("localhost", proxyServer.port, "test",
                new HttpClientDigestCredentials("dart", "password"));
          } else {
            client.findProxy = (Uri uri) {
              return "PROXY dart:password@localhost:${proxyServer.port}";
            };
          }

          for (int i = 0; i < loopCount; i++) {
            test(bool secure) {
              var path = useDigestAuthentication ? "A" : "$i";
              String url = secure
                  ? "https://localhost:${secureServer.port}/$path"
                  : "http://localhost:${server.port}/$path";

              client
                  .postUrl(Uri.parse(url))
                  .then((HttpClientRequest clientRequest) {
                String content = "$i$i$i";
                clientRequest.write(content);
                return clientRequest.close();
              }).then((HttpClientResponse response) {
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
            client.addProxyCredentials("localhost", proxyServer.port, "realm",
                new HttpClientBasicCredentials("dart", "password"));
            return new Future.value(true);
          };

          for (int i = 0; i < loopCount; i++) {
            test(bool secure) {
              String url = secure
                  ? "https://localhost:${secureServer.port}/A"
                  : "http://localhost:${server.port}/A";

              client
                  .postUrl(Uri.parse(url))
                  .then((HttpClientRequest clientRequest) {
                String content = "$i$i$i";
                clientRequest.write(content);
                return clientRequest.close();
              }).then((HttpClientResponse response) {
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
                    completer.complete(null);
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

  return completer.future;
}

int testRealProxyDoneCount = 0;
void testRealProxy() {
  setupServer(1).then((server) {
    HttpClient client = new HttpClient(context: clientContext);
    client.addProxyCredentials("localhost", 8080, "test",
        new HttpClientBasicCredentials("dart", "password"));

    List<String> proxy = [
      "PROXY localhost:8080",
      "PROXY localhost:8080; PROXY hede.hule.hest:8080",
      "PROXY hede.hule.hest:8080; PROXY localhost:8080",
      "PROXY localhost:8080; DIRECT"
    ];

    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client
          .getUrl(Uri.parse("http://localhost:${server.port}/$i"))
          .then((HttpClientRequest clientRequest) {
        String content = "$i$i$i";
        clientRequest.contentLength = content.length;
        clientRequest.write(content);
        return clientRequest.close();
      }).then((HttpClientResponse response) {
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
    HttpClient client = new HttpClient(context: clientContext);

    List<String> proxy = [
      "PROXY dart:password@localhost:8080",
      "PROXY dart:password@localhost:8080; PROXY hede.hule.hest:8080",
      "PROXY hede.hule.hest:8080; PROXY dart:password@localhost:8080",
      "PROXY dart:password@localhost:8080; DIRECT"
    ];

    client.findProxy = (Uri uri) {
      // Pick the proxy configuration based on the request path.
      int index = int.parse(uri.path.substring(1));
      return proxy[index];
    };

    for (int i = 0; i < proxy.length; i++) {
      client
          .getUrl(Uri.parse("http://localhost:${server.port}/$i"))
          .then((HttpClientRequest clientRequest) {
        String content = "$i$i$i";
        clientRequest.contentLength = content.length;
        clientRequest.write(content);
        return clientRequest.close();
      }).then((HttpClientResponse response) {
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

main() {
  testProxyIPV6();
  testProxyFromEnviroment();
  // The two invocations use the same global variable for state -
  // run one after the other.
  testProxyAuthenticate(false).then((_) => testProxyAuthenticate(true));

  // This test is not normally run. It can be used for locally testing
  // with a real proxy server (e.g. Apache).
  // testRealProxy();
  // testRealProxyAuth();
}
