// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:uri");

class Server {
  HttpServer server;
  int proxyHops;
  List<String> directRequestPaths;
  int requestCount = 0;

  Server(this.proxyHops, this.directRequestPaths) : server = new HttpServer();

  void start() {
    server.listen("127.0.0.1", 0);
    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
          requestCount++;
          // Check whether a proxy or direct connection is expected.
          bool direct = directRequestPaths.reduce(
              false,
              (prev, path) => prev ? prev : path == request.path);
          if (!direct && proxyHops > 0) {
            Expect.isNotNull(request.headers[HttpHeaders.VIA]);
            Expect.equals(1, request.headers[HttpHeaders.VIA].length);
            Expect.equals(
                proxyHops,
                request.headers[HttpHeaders.VIA][0].split(",").length);
          } else {
            Expect.isNull(request.headers[HttpHeaders.VIA]);
          }
          StringInputStream stream = new StringInputStream(request.inputStream);
          StringBuffer body = new StringBuffer();
          stream.onData = () => body.add(stream.read());
          stream.onClosed = () {
            String path = request.path.substring(1);
            String content = "$path$path$path";
            Expect.equals(content, body.toString());
            response.outputStream.writeString(request.path);
            response.outputStream.close();
          };
        };
  }

  void shutdown() {
    server.close();
  }

  int get port => server.port;
}

Server setupServer(int proxyHops,
                   [List<String> directRequestPaths = const <String>[]]) {
  Server server = new Server(proxyHops, directRequestPaths);
  server.start();
  return server;
}

class ProxyServer {
  HttpServer server;
  HttpClient client;
  int requestCount = 0;

  ProxyServer() : server = new HttpServer(), client = new HttpClient();

  void start() {
    server.listen("127.0.0.1", 0);
    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
          requestCount++;
          // Open the connection from the proxy.
          HttpClientConnection conn =
              client.openUrl(request.method, new Uri.fromString(request.path));
          conn.onRequest = (HttpClientRequest clientRequest) {
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
            request.inputStream.pipe(clientRequest.outputStream);
          };
          conn.onResponse = (HttpClientResponse clientResponse) {
            clientResponse.inputStream.pipe(response.outputStream);
          };
        };
  }

  void shutdown() {
    server.close();
    client.shutdown();
  }

  int get port => server.port;
}

ProxyServer setupProxyServer() {
  ProxyServer proxyServer = new ProxyServer();
  proxyServer.start();
  return proxyServer;
}

testInvalidProxy() {
  HttpClient client = new HttpClient();

  // TODO(sgjesse): This should not throw errors, but call
  // HttpClientConnection onError.
  client.findProxy = (Uri uri) => "XXX";
  Expect.throws(
      () => client.getUrl(new Uri.fromString("http://www.google.com/test")),
      (e) => e is HttpException);

  client.findProxy = (Uri uri) => "PROXY www.google.com";
  Expect.throws(
      () => client.getUrl(new Uri.fromString("http://www.google.com/test")),
      (e) => e is HttpException);

  client.findProxy = (Uri uri) => "PROXY www.google.com:http";
  Expect.throws(
      () => client.getUrl(new Uri.fromString("http://www.google.com/test")),
      (e) => e is HttpException);
}

int testDirectDoneCount = 0;
void testDirectProxy() {
  Server server = setupServer(0);
  HttpClient client = new HttpClient();
  List<String> proxy =
      ["DIRECT", " DIRECT ", "DIRECT ;", " DIRECT ; ",
       ";DIRECT", " ; DIRECT ", ";;DIRECT;;"];

  client.findProxy = (Uri uri) {
    int index = int.parse(uri.path.substring(1));
    return proxy[index];
  };

  for (int i = 0; i < proxy.length; i++) {
    HttpClientConnection conn =
        client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/$i"));
    conn.onRequest = (HttpClientRequest clientRequest) {
      String content = "$i$i$i";
      clientRequest.contentLength = content.length;
      clientRequest.outputStream.writeString(content);
      clientRequest.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onData = () => response.inputStream.read();
      response.inputStream.onClosed = () {
        testDirectDoneCount++;
        if (testDirectDoneCount == proxy.length) {
          Expect.equals(proxy.length, server.requestCount);
          server.shutdown();
          client.shutdown();
        }
      };
    };
  }
}

int testProxyDoneCount = 0;
void testProxy() {
  ProxyServer proxyServer = setupProxyServer();
  Server server = setupServer(1, ["/4"]);
  HttpClient client = new HttpClient();

  List<String> proxy =
      ["PROXY localhost:${proxyServer.port}",
       "PROXY localhost:${proxyServer.port}; PROXY hede.hule.hest:8080",
       "PROXY hede.hule.hest:8080; PROXY localhost:${proxyServer.port}",
       "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; PROXY localhost:${proxyServer.port}",
       "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; DIRECT",
       "PROXY localhost:${proxyServer.port}; DIRECT"];

  client.findProxy = (Uri uri) {
    // Pick the proxy configuration based on the request path.
    int index = int.parse(uri.path.substring(1));
    return proxy[index];
  };

  for (int i = 0; i < proxy.length; i++) {
    HttpClientConnection conn =
        client.postUrl(
            new Uri.fromString("http://127.0.0.1:${server.port}/$i"));
    conn.onRequest = (HttpClientRequest clientRequest) {
      String content = "$i$i$i";
      clientRequest.outputStream.writeString(content);
      clientRequest.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onData = () => response.inputStream.read();
      response.inputStream.onClosed = () {
        testProxyDoneCount++;
        if (testProxyDoneCount == proxy.length) {
          Expect.equals(proxy.length, server.requestCount);
          proxyServer.shutdown();
          server.shutdown();
          client.shutdown();
        }
      };
    };
  }
}

int testProxyChainDoneCount = 0;
void testProxyChain() {
  // Setup two proxy servers having the first using the second as its proxy.
  ProxyServer proxyServer1 = setupProxyServer();
  ProxyServer proxyServer2 = setupProxyServer();
  proxyServer1.client.findProxy = (_) => "PROXY 127.0.0.1:${proxyServer2.port}";

  Server server = setupServer(2, ["/4"]);
  HttpClient client = new HttpClient();

  List<String> proxy =
      ["PROXY localhost:${proxyServer1.port}",
       "PROXY localhost:${proxyServer1.port}; PROXY hede.hule.hest:8080",
       "PROXY hede.hule.hest:8080; PROXY localhost:${proxyServer1.port}",
       "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; PROXY localhost:${proxyServer1.port}",
       "PROXY hede.hule.hest:8080; PROXY hede.hule.hest:8181; DIRECT",
       "PROXY localhost:${proxyServer1.port}; DIRECT"];

  client.findProxy = (Uri uri) {
    // Pick the proxy configuration based on the request path.
    int index = int.parse(uri.path.substring(1));
    return proxy[index];
  };

  for (int i = 0; i < proxy.length; i++) {
    HttpClientConnection conn =
        client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/$i"));
    conn.onRequest = (HttpClientRequest clientRequest) {
      String content = "$i$i$i";
      clientRequest.contentLength = content.length;
      clientRequest.outputStream.writeString(content);
      clientRequest.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onData = () => response.inputStream.read();
      response.inputStream.onClosed = () {
        testProxyChainDoneCount++;
        if (testProxyChainDoneCount == proxy.length) {
          Expect.equals(proxy.length, server.requestCount);
          proxyServer1.shutdown();
          proxyServer2.shutdown();
          server.shutdown();
          client.shutdown();
        }
      };
    };
  }
}

int testRealProxyDoneCount = 0;
void testRealProxy() {
  Server server = setupServer(1);
  HttpClient client = new HttpClient();

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
    HttpClientConnection conn =
       client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/$i"));
    conn.onRequest = (HttpClientRequest clientRequest) {
      String content = "$i$i$i";
      clientRequest.contentLength = content.length;
      clientRequest.outputStream.writeString(content);
      clientRequest.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onData = () => response.inputStream.read();
      response.inputStream.onClosed = () {
        testRealProxyDoneCount++;
        if (testRealProxyDoneCount == proxy.length) {
          Expect.equals(proxy.length, server.requestCount);
          server.shutdown();
          client.shutdown();
        }
      };
    };
  }
}

main() {
  testInvalidProxy();
  testDirectProxy();
  testProxy();
  testProxyChain();
  // This test is not normally run. It can be used for locally testing
  // with a real proxy server (e.g. Apache).
  // testRealProxy();
}
