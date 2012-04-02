#import("dart:io");
#import("dart:isolate");

class Server {
  Server() {
    HttpServer server = new HttpServer();
    server.listen("127.0.0.1", 0);
    port = server.port;
    server.onRequest = (HttpRequest request, HttpResponse response) {
      new Timer(100, (timer) => server.close());
    };
    server.onError = (Object exception) {
      Expect.fail("Close should not give an error.");
    };
  }
  int port;
}

class Client {
  Client(int port) {
    ReceivePort r = new ReceivePort();
    HttpClient client = new HttpClient();
    HttpClientConnection c = client.get("127.0.0.1", port, "/");
    c.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    c.onResponse = (HttpClientResponse response) {
      Expect.fail("Response should not be given, as not data was returned.");
    };
    c.onError = (Object exception) {
      r.close();
    };
  }
}

main() {
  Server server = new Server();
  new Client(server.port);
}
