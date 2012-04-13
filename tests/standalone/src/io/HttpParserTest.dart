// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../../runtime/bin/http_parser.dart");

class HttpParserTest {
  static void runAllTests() {
    testParseRequest();
    testParseResponse();
    testParseInvalidRequest();
    testParseInvalidResponse();
  }

  static void _testParseRequest(String request,
                                String expectedMethod,
                                String expectedUri,
                                [int expectedContentLength = -1,
                                 int expectedBytesReceived = 0,
                                 Map expectedHeaders = null,
                                 bool chunked = false,
                                 bool upgrade = false,
                                 int unparsedLength = 0]) {
    _HttpParser httpParser;
    bool headersCompleteCalled;
    bool dataEndCalled;
    String method;
    String uri;
    Map headers;
    int contentLength;
    int bytesReceived;

    void reset() {
      httpParser = new _HttpParser();
      httpParser.requestStart = (m, u) { method = m; uri = u; };
      httpParser.responseStart = (s, r) { Expect.fail("Expected request"); };
      httpParser.headerReceived = (f, v) {
        Expect.isFalse(headersCompleteCalled);
        headers[f] = v;
      };
      httpParser.headersComplete = () {
        Expect.isFalse(headersCompleteCalled);
        if (!chunked) {
          Expect.equals(expectedContentLength, httpParser.contentLength);
        } else {
          Expect.equals(-1, httpParser.contentLength);
        }
        if (expectedHeaders != null) {
          expectedHeaders.forEach(
              (String name, String value) =>
                  Expect.equals(value, headers[name]));
        }
        Expect.equals(upgrade, httpParser.upgrade);
        headersCompleteCalled = true;
      };
      httpParser.dataReceived = (List<int> data) {
        Expect.isTrue(headersCompleteCalled);
        bytesReceived += data.length;
      };
      httpParser.dataEnd = (close) {
        Expect.isFalse(close);
        dataEndCalled = true;
      };

      headersCompleteCalled = false;
      dataEndCalled = false;
      method = null;
      uri = null;
      headers = new Map();
      bytesReceived = 0;
    }

    void testWrite(List<int> requestData, [int chunkSize = -1]) {
      if (chunkSize == -1) chunkSize = requestData.length;
      reset();
      int written = 0;
      int unparsed;
      for (int pos = 0; pos < requestData.length; pos += chunkSize) {
        int remaining = requestData.length - pos;
        int writeLength = Math.min(chunkSize, remaining);
        written += writeLength;
        int parsed = httpParser.writeList(requestData, pos, writeLength);
        unparsed = writeLength - parsed;
        if (httpParser.upgrade) {
          unparsed += requestData.length - written;
          break;
        } else {
          Expect.equals(0, unparsed);
        }
      }
      Expect.equals(expectedMethod, method);
      Expect.equals(expectedUri, uri);
      Expect.isTrue(headersCompleteCalled);
      Expect.equals(expectedBytesReceived, bytesReceived);
      if (!upgrade) Expect.isTrue(dataEndCalled);
      if (unparsedLength == 0) {
        Expect.equals(0, unparsed);
      } else {
        Expect.equals(unparsedLength, unparsed);
      }
    }

    // Test parsing the request three times delivering the data in
    // different chunks.
    List<int> requestData = request.charCodes();
    testWrite(requestData);
    testWrite(requestData, 10);
    testWrite(requestData, 1);
  }

  static void _testParseInvalidRequest(String request) {
    _HttpParser httpParser;
    bool errorCalled;

    void reset() {
      httpParser = new _HttpParser();
      httpParser.responseStart = (s, r) { Expect.fail("Expected request"); };
      httpParser.error = (e) {
        errorCalled = true;
      };

      errorCalled = false;
    }

    void testWrite(List<int> requestData, [int chunkSize = -1]) {
      if (chunkSize == -1) chunkSize = requestData.length;
      reset();
      for (int pos = 0; pos < requestData.length; pos += chunkSize) {
        int remaining = requestData.length - pos;
        int writeLength = Math.min(chunkSize, remaining);
        httpParser.writeList(requestData, pos, writeLength);
      }
      Expect.isTrue(errorCalled);
    }

    // Test parsing the request three times delivering the data in
    // different chunks.
    List<int> requestData = request.charCodes();
    testWrite(requestData);
    testWrite(requestData, 10);
    testWrite(requestData, 1);
  }

  static void _testParseResponse(String response,
                                 int expectedStatusCode,
                                 String expectedReasonPhrase,
                                 [int expectedContentLength = -1,
                                  int expectedBytesReceived = 0,
                                  Map expectedHeaders = null,
                                  bool chunked = false,
                                  bool close = false,
                                  String responseToMethod = null,
                                  bool connectionClose = false,
                                  bool upgrade = false,
                                  int unparsedLength = 0]) {
    _HttpParser httpParser;
    bool headersCompleteCalled;
    bool dataEndCalled;
    bool dataEndClose;
    int statusCode;
    String reasonPhrase;
    Map headers;
    int contentLength;
    int bytesReceived;

    void reset() {
      httpParser = new _HttpParser();
      if (responseToMethod != null) {
        httpParser.responseToMethod = responseToMethod;
      }
      httpParser.requestStart = (m, u) => Expect.fail("Expected response");
      httpParser.responseStart = (s, r) {
        statusCode = s;
        reasonPhrase = r;
      };
      httpParser.headerReceived = (f, v) {
        Expect.isFalse(headersCompleteCalled);
        headers[f] = v;
      };
      httpParser.headersComplete = () {
        Expect.isFalse(headersCompleteCalled);
        if (!chunked && !close) {
          Expect.equals(expectedContentLength, httpParser.contentLength);
        } else {
          Expect.equals(-1, httpParser.contentLength);
        }
        if (expectedHeaders != null) {
          expectedHeaders.forEach((String name, String value) {
            Expect.equals(value, headers[name]);
          });
        }
        Expect.equals(upgrade, httpParser.upgrade);
        headersCompleteCalled = true;
      };
      httpParser.dataReceived = (List<int> data) {
        Expect.isTrue(headersCompleteCalled);
        bytesReceived += data.length;
      };
      httpParser.dataEnd = (close) {
        dataEndCalled = true;
        dataEndClose = close;
      };

      headersCompleteCalled = false;
      dataEndCalled = false;
      dataEndClose = null;
      statusCode = -1;
      reasonPhrase = null;
      headers = new Map();
      bytesReceived = 0;
    }

    void testWrite(List<int> requestData, [int chunkSize = -1]) {
      if (chunkSize == -1) chunkSize = requestData.length;
      reset();
      int written = 0;
      int unparsed;
      for (int pos = 0; pos < requestData.length; pos += chunkSize) {
        int remaining = requestData.length - pos;
        int writeLength = Math.min(chunkSize, remaining);
        written += writeLength;
        int parsed = httpParser.writeList(requestData, pos, writeLength);
        unparsed = writeLength - parsed;
        if (httpParser.upgrade) {
          unparsed += requestData.length - written;
          break;
        } else {
          Expect.equals(0, unparsed);
        }
      }
      if (close) httpParser.connectionClosed();
      Expect.equals(expectedStatusCode, statusCode);
      Expect.equals(expectedReasonPhrase, reasonPhrase);
      Expect.isTrue(headersCompleteCalled);
      Expect.equals(expectedBytesReceived, bytesReceived);
      if (!upgrade) {
        Expect.isTrue(dataEndCalled);
        if (close) Expect.isTrue(dataEndClose);
        Expect.equals(dataEndClose, connectionClose);
      }
      if (unparsedLength == 0) {
        Expect.equals(0, unparsed);
      } else {
        Expect.equals(unparsedLength, unparsed);
      }
    }

    // Test parsing the request three times delivering the data in
    // different chunks.
    List<int> responseData = response.charCodes();
    testWrite(responseData);
    testWrite(responseData, 10);
    testWrite(responseData, 1);
  }

  static void _testParseInvalidResponse(String response, [bool close = false]) {
    _HttpParser httpParser;
    bool errorCalled;

    void reset() {
      httpParser = new _HttpParser();
      httpParser.requestStart = (m, u) => Expect.fail("Expected response");
      httpParser.error = (e) => errorCalled = true;

      errorCalled = false;
    }

    void testWrite(List<int> requestData, [int chunkSize = -1]) {
      if (chunkSize == -1) chunkSize = requestData.length;
      reset();
      for (int pos = 0; pos < requestData.length; pos += chunkSize) {
        int remaining = requestData.length - pos;
        int writeLength = Math.min(chunkSize, remaining);
        httpParser.writeList(requestData, pos, writeLength);
      }
      if (close) httpParser.connectionClosed();
      Expect.isTrue(errorCalled);
    }

    // Test parsing the request three times delivering the data in
    // different chunks.
    List<int> responseData = response.charCodes();
    testWrite(responseData);
    testWrite(responseData, 10);
    testWrite(responseData, 1);
  }

  static void testParseRequest() {
    String request;
    Map headers;
    request = "GET / HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "GET", "/");

    request = "POST / HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "POST", "/");

    request = "GET /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "GET", "/index.html");

    request = "POST /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "POST", "/index.html");

    request = "H /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "H", "/index.html");

    request = "HT /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "HT", "/index.html");

    request = "HTT /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "HTT", "/index.html");

    request = "HTTP /index.html HTTP/1.1\r\n\r\n";
    _testParseRequest(request, "HTTP", "/index.html");

    request = """
POST /test HTTP/1.1\r
AAA: AAA\r
\r
""";
    _testParseRequest(request, "POST", "/test");

    request = """
POST /test HTTP/1.1\r
\r
""";
    _testParseRequest(request, "POST", "/test");

    request = """
POST /test HTTP/1.1\r
Header-A: AAA\r
X-Header-B: bbb\r
\r
""";
    headers = new Map();
    headers["header-a"] = "AAA";
    headers["x-header-b"] = "bbb";
    _testParseRequest(request, "POST", "/test", expectedHeaders: headers);

    request = """
POST /test HTTP/1.1\r
Empty-Header-1:\r
Empty-Header-2:\r
        \r
\r
""";
    headers = new Map();
    headers["empty-header-1"] = "";
    headers["empty-header-2"] = "";
    _testParseRequest(request, "POST", "/test", expectedHeaders: headers);

    request = """
POST /test HTTP/1.1\r
Header-A:   AAA\r
X-Header-B:\t \t bbb\r
\r
""";
    headers = new Map();
    headers["header-a"] = "AAA";
    headers["x-header-b"] = "bbb";
    _testParseRequest(request, "POST", "/test", expectedHeaders: headers);

    request = """
POST /test HTTP/1.1\r
Header-A:   AA\r
 A\r
X-Header-B:           b\r
  b\r
\t    b\r
\r
""";
    headers = new Map();
    headers["header-a"] = "AAA";
    headers["x-header-b"] = "bbb";
    _testParseRequest(request, "POST", "/test", expectedHeaders: headers);

    request = """
POST /test HTTP/1.1\r
Content-Length: 10\r
\r
0123456789""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: 10,
                      expectedBytesReceived: 10);

    // Test connection close header.
    request = """
GET /test HTTP/1.1\r
Connection: close\r
\r\n""";
    _testParseRequest(request, "GET", "/test");

    // Test chunked encoding.
    request = """
POST /test HTTP/1.1\r
Transfer-Encoding: chunked\r
\r
5\r
01234\r
5\r
56789\r
0\r\n\r\n""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: -1,
                      expectedBytesReceived: 10,
                      chunked: true);

    // Test mixing chunked encoding and content length (content length
    // is ignored).
    request = """
POST /test HTTP/1.1\r
Content-Length: 7\r
Transfer-Encoding: chunked\r
\r
5\r
01234\r
5\r
56789\r
0\r\n\r\n""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: -1,
                      expectedBytesReceived: 10,
                      chunked: true);

    // Test mixing chunked encoding and content length (content length
    // is ignored).
    request = """
POST /test HTTP/1.1\r
Transfer-Encoding: chunked\r
Content-Length: 3\r
\r
5\r
01234\r
5\r
56789\r
0\r\n\r\n""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: -1,
                      expectedBytesReceived: 10,
                      chunked: true);

    // Test upper and lower case hex digits in chunked encoding.
    request = """
POST /test HTTP/1.1\r
Transfer-Encoding: chunked\r
\r
1E\r
012345678901234567890123456789\r
1e\r
012345678901234567890123456789\r
0\r\n\r\n""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: -1,
                      expectedBytesReceived: 60,
                      chunked: true);

    // Test chunk extensions in chunked encoding.
    request = """
POST /test HTTP/1.1\r
Transfer-Encoding: chunked\r
\r
1E;xxx\r
012345678901234567890123456789\r
1E;yyy=zzz\r
012345678901234567890123456789\r
0\r\n\r\n""";
    _testParseRequest(request,
                      "POST",
                      "/test",
                      expectedContentLength: -1,
                      expectedBytesReceived: 60,
                      chunked: true);

    // Test HTTP upgrade.
    request = """
GET /irc HTTP/1.1\r
Upgrade: irc/1.2\r
Connection: Upgrade\r
\r\n\x01\x01\x01\x01\x01\x02\x02\x02\x02\xFF""";
    headers = new Map();
    headers["upgrade"] = "irc/1.2";
    _testParseRequest(request,
                      "GET",
                      "/irc",
                      expectedHeaders: headers,
                      upgrade: true,
                      unparsedLength: 10);

    // Test HTTP upgrade with protocol data.
    request = """
GET /irc HTTP/1.1\r
Upgrade: irc/1.2\r
Connection: Upgrade\r
\r\n""";
    headers = new Map();
    headers["upgrade"] = "irc/1.2";
    _testParseRequest(request,
                      "GET",
                      "/irc",
                      expectedHeaders: headers,
                      upgrade: true);

    // Test websocket upgrade.
    request = """
GET /chat HTTP/1.1\r
Host: server.example.com\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Origin: http://example.com\r
Sec-WebSocket-Version: 13\r
\r\n""";
    headers = new Map();
    headers["host"] = "server.example.com";
    headers["upgrade"] = "websocket";
    headers["sec-websocket-key"] = "dGhlIHNhbXBsZSBub25jZQ==";
    headers["origin"] = "http://example.com";
    headers["sec-websocket-version"] = "13";
    _testParseRequest(request,
                      "GET",
                      "/chat",
                      expectedHeaders: headers,
                      upgrade: true);


    // Test websocket upgrade with protocol data. NOTE: When using the
    // WebSocket protocol this should never happen as the client
    // should not send protocol data before processing the request
    // part of the opening handshake. However the HTTP parser should
    // still handle this.
    request = """
GET /chat HTTP/1.1\r
Host: server.example.com\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Origin: http://example.com\r
Sec-WebSocket-Version: 13\r
\r\n0123456""";
    headers = new Map();
    headers["host"] = "server.example.com";
    headers["upgrade"] = "websocket";
    headers["sec-websocket-key"] = "dGhlIHNhbXBsZSBub25jZQ==";
    headers["origin"] = "http://example.com";
    headers["sec-websocket-version"] = "13";
    _testParseRequest(request,
                      "GET",
                      "/chat",
                      expectedHeaders: headers,
                      upgrade: true,
                      unparsedLength: 7);
  }

  static void testParseResponse() {
    String response;
    Map headers;
    response = "HTTP/1.1 100 Continue\r\nContent-Length: 0\r\n\r\n";
    _testParseResponse(response, 100, "Continue", expectedContentLength: 0);

    response = "HTTP/1.1 100 Continue\r\nContent-Length: 10\r\n\r\n";
    _testParseResponse(response,
                       100,
                       "Continue",
                       expectedContentLength: 10,
                       expectedBytesReceived: 0);

    response = "HTTP/1.1 204 No Content\r\nContent-Length: 11\r\n\r\n";
    _testParseResponse(response,
                       204,
                       "No Content",
                       expectedContentLength: 11,
                       expectedBytesReceived: 0);

    response = "HTTP/1.1 304 Not Modified\r\nContent-Length: 12\r\n\r\n";
    _testParseResponse(response,
                       304,
                       "Not Modified",
                       expectedContentLength: 12,
                       expectedBytesReceived: 0);

    response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
    _testParseResponse(response, 200, "OK", expectedContentLength: 0);

    response = "HTTP/1.1 404 Not found\r\nContent-Length: 0\r\n\r\n";
    _testParseResponse(response, 404, "Not found", expectedContentLength: 0);

    response = "HTTP/1.1 500 Server error\r\nContent-Length: 0\r\n\r\n";
    _testParseResponse(response, 500, "Server error", expectedContentLength: 0);

    // Test response to HEAD request.
    response = """
HTTP/1.1 200 OK\r
Content-Length: 20\r
Content-Type: text/html\r
\r\n""";
    headers = new Map();
    headers["content-length"] = "20";
    headers["content-type"] = "text/html";
    _testParseResponse(response,
                       200,
                       "OK",
                       responseToMethod: "HEAD",
                       expectedContentLength: 20,
                       expectedBytesReceived: 0,
                       expectedHeaders: headers);

    // Test content.
    response = """
HTTP/1.1 200 OK\r
Content-Length: 20\r
\r
01234567890123456789""";
    _testParseResponse(response,
                       200,
                       "OK",
                       expectedContentLength: 20,
                       expectedBytesReceived: 20);

    // Test upper and lower case hex digits in chunked encoding.
    response = """
HTTP/1.1 200 OK\r
Transfer-Encoding: chunked\r
\r
1A\r
01234567890123456789012345\r
1f\r
0123456789012345678901234567890\r
0\r\n\r\n""";
    _testParseResponse(response,
                       200,
                       "OK",
                       expectedContentLength: -1,
                       expectedBytesReceived: 57,
                       chunked: true);

    // Test connection close header.
    response = """
HTTP/1.1 200 OK\r
Content-Length: 0\r
Connection: close\r
\r\n""";
    _testParseResponse(response,
                       200,
                       "OK",
                       expectedContentLength: 0,
                       connectionClose: true);

    // Test HTTP response without any transfer length indications
    // where closing the connections indicates end of body.
    response = """
HTTP/1.1 200 OK\r
\r
01234567890123456789012345
0123456789012345678901234567890
""";
    _testParseResponse(response,
                       200,
                       "OK",
                       expectedContentLength: -1,
                       expectedBytesReceived: 59,
                       close: true,
                       connectionClose: true);

    // Test HTTP upgrade.
    response = """
HTTP/1.1 101 Switching Protocols\r
Upgrade: irc/1.2\r
Connection: Upgrade\r
\r\n""";
    headers = new Map();
    headers["upgrade"] = "irc/1.2";
    _testParseResponse(response,
                       101,
                       "Switching Protocols",
                       expectedHeaders: headers,
                       upgrade: true);

    // Test HTTP upgrade with protocol data.
    response = """
HTTP/1.1 101 Switching Protocols\r
Upgrade: irc/1.2\r
Connection: Upgrade\r
\r\n\x00\x10\x20\x30\x40\x50\x60\x70\x80\x90\xA0\xB0\xC0\xD0\xE0\xF0""";
    headers = new Map();
    headers["upgrade"] = "irc/1.2";
    _testParseResponse(response,
                       101,
                       "Switching Protocols",
                       expectedHeaders: headers,
                       upgrade: true,
                       unparsedLength: 16);

    // Test websocket upgrade.
    response = """
HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r
\r\n""";
    headers = new Map();
    headers["upgrade"] = "websocket";
    headers["sec-websocket-accept"] = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";
    _testParseResponse(response,
                       101,
                       "Switching Protocols",
                       expectedHeaders: headers,
                       upgrade: true);

    // Test websocket upgrade with protocol data.
    response = """
HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r
\r\nABCD""";
    headers = new Map();
    headers["upgrade"] = "websocket";
    headers["sec-websocket-accept"] = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";
    _testParseResponse(response,
                       101,
                       "Switching Protocols",
                       expectedHeaders: headers,
                       upgrade: true,
                       unparsedLength: 4);
  }

  static void testParseInvalidRequest() {
    String request;
    request = "GET /\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "GET / \r\n\r\n";
    _testParseInvalidRequest(request);

    request = "/ HTTP/1.1\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "GET HTTP/1.1\r\n\r\n";
    _testParseInvalidRequest(request);

    request = " / HTTP/1.1\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "@ / HTTP/1.1\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "GET / TTP/1.1\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "GET / HTTP/1.\r\n\r\n";
    _testParseInvalidRequest(request);

    request = "GET / HTTP/1.1\r\nKeep-Alive: False\r\nbadheader\r\n\r\n";
    _testParseInvalidRequest(request);

    // Currently no HTTP 1.0 support.
    request = "GET / HTTP/1.0\r\n\r\n";
    _testParseInvalidRequest(request);
  }

  static void testParseInvalidResponse() {
    String response;

    response = "HTTP/1.1\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 \r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 200\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 200 \r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 OK\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "200 OK\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1. 200 OK\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 200 O\rK\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 000 OK\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 999 Server Error\r\nContent-Length: 0\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 200 OK\r\nContent-Length: x\r\n\r\n";
    _testParseInvalidResponse(response);

    response = "HTTP/1.1 200 OK\r\nbadheader\r\n\r\n";
    _testParseInvalidResponse(response);

    response = """
HTTP/1.1 200 OK\r
Transfer-Encoding: chunked\r
\r
1A\r
01234567890123456789012345\r
1g\r
0123456789012345678901234567890\r
0\r\n\r\n""";
    _testParseInvalidResponse(response);
  }
}


void main() {
  HttpParserTest.runAllTests();
}
