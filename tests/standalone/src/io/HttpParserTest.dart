// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../../runtime/bin/http_parser.dart");

class HttpParserTest {
  static void runAllTests() {
    testParseRequest();
    testParseResponse();
  }

  static void _testParseRequest(String request,
                                String expectedMethod,
                                String expectedUri,
                                [int expectedContentLength = -1,
                                 int expectedBytesReceived = 0,
                                 Map expectedHeaders = null,
                                 bool chunked = false]) {
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
        headersCompleteCalled = true;
      };
      httpParser.dataReceived = (List<int> data) {
        Expect.isTrue(headersCompleteCalled);
        bytesReceived += data.length;
      };
      httpParser.dataEnd = () => dataEndCalled = true;

      headersCompleteCalled = false;
      dataEndCalled = false;
      method = null;
      uri = null;
      headers = new Map();
      bytesReceived = 0;
    }

    void checkExpectations() {
      Expect.equals(expectedMethod, method);
      Expect.equals(expectedUri, uri);
      Expect.isTrue(headersCompleteCalled);
      Expect.equals(expectedBytesReceived, bytesReceived);
      Expect.isTrue(dataEndCalled);
    }

    void testWrite(List<int> requestData, [int chunkSize = -1]) {
      if (chunkSize == -1) chunkSize = requestData.length;
      reset();
      for (int pos = 0; pos < requestData.length; pos += chunkSize) {
        int remaining = requestData.length - pos;
        int writeLength = Math.min(chunkSize, remaining);
        httpParser.writeList(requestData, pos, writeLength);
      }
      checkExpectations();
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
                                  String responseToMethod = null]) {
    _HttpParser httpParser;
    bool headersCompleteCalled;
    bool dataEndCalled;
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
        headersCompleteCalled = true;
      };
      httpParser.dataReceived = (List<int> data) {
        Expect.isTrue(headersCompleteCalled);
        bytesReceived += data.length;
      };
      httpParser.dataEnd = () => dataEndCalled = true;

      headersCompleteCalled = false;
      dataEndCalled = false;
      statusCode = -1;
      reasonPhrase = null;
      headers = new Map();
      bytesReceived = 0;
    }

    void checkExpectations() {
      Expect.equals(expectedStatusCode, statusCode);
      Expect.equals(expectedReasonPhrase, reasonPhrase);
      Expect.isTrue(headersCompleteCalled);
      Expect.equals(expectedBytesReceived, bytesReceived);
      Expect.isTrue(dataEndCalled);
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
      checkExpectations();
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

    // Test HTTP response without any transfer length indications
    // where closing the connections indicated end of body.
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
                     close: true);
  }
}


void main() {
  HttpParserTest.runAllTests();
}
