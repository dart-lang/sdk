#import("dart:io");
#import("dart:isolate");

void sendData(List<int> data, int port) {
  Socket socket = new Socket("127.0.0.1", port);
  socket.onConnect = () {
    socket.onData = () {
      Expect.fail("No data response was expected");
    };
    socket.outputStream.onNoPendingWrites = () {
      socket.close(true);
    };
    socket.outputStream.write(data);
  };
}

class EarlyCloseTest {
  EarlyCloseTest(this.data,
                 String this.exception,
                 [bool this.expectRequest = false]);

  Future execute(HttpServer server) {
    Completer c = new Completer();

    bool calledOnRequest = false;
    bool calledOnError = false;
    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
          Expect.isTrue(expectRequest);
          Expect.isFalse(calledOnError);
          Expect.isFalse(calledOnRequest, "onRequest called multiple times");
          calledOnRequest = true;
        };
    ReceivePort port = new ReceivePort();
    server.onError = (error) {
      Expect.isFalse(calledOnError);
      Expect.equals(exception, error.message);
      Expect.equals(expectRequest, calledOnRequest);
      calledOnError = true;
      port.close();
      c.complete(null);
    };

    List<int> d;
    if (data is List<int>) d = data;
    if (data is String) d = data.charCodes();
    if (d == null) Expect.fail("Invalid data");
    sendData(d, server.port);

    return c.future;
  }

  final data;
  final String exception;
  final bool expectRequest;
}

void testEarlyClose() {
  List<EarlyCloseTest> tests = new List<EarlyCloseTest>();
  void add(Object data, String exception, [bool expectRequest = false]) {
    tests.add(new EarlyCloseTest(data, exception, expectRequest));
  }
  // The empty packet is valid.

  // Close while sending header
  add("G", "Connection closed before full header was received");
  add("GET /", "Connection closed before full header was received");
  add("GET / HTTP/1.1", "Connection closed before full header was received");
  add("GET / HTTP/1.1\r\n", "Connection closed before full header was received");

  // Close while sending content
  add("GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n",
      "Connection closed before full body was received",
      expectRequest: true);
  add("GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n1",
      "Connection closed before full body was received",
      expectRequest: true);


  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0);
  void runTest(Iterator it) {
    if (it.hasNext()) {
      it.next().execute(server).then((_) => runTest(it));
    } else {
      server.close();
    }
  }
  runTest(tests.iterator());
}

void main() {
  testEarlyClose();
}
