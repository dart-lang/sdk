// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:math');

#source("../../../runtime/bin/http_parser.dart");
#source("../../../runtime/bin/mime_multipart_parser.dart");

void testParse(String message,
               String boundary,
               [List<Map> expectedHeaders,
               List expectedParts]) {
  _MimeMultipartParser parser;
  int partCount;
  Map headers;
  List<int> currentPart;
  bool lastPartCalled;

  void reset() {
    parser = new _MimeMultipartParser(boundary);
    parser.partStart = (f, v) {
    };
    parser.headerReceived = (f, v) {
      headers[f] = v;
    };
    parser.headersComplete = () {
      if (expectedHeaders != null) {
        expectedHeaders[partCount].forEach(
            (String name, String value) {
              Expect.equals(value, headers[name]);
            });
      }
    };
    parser.partDataReceived = (List<int> data) {
      if (currentPart == null) currentPart = new List<int>();
      currentPart.addAll(data);
    };
    parser.partEnd = (lastPart) {
      Expect.isFalse(lastPartCalled);
      lastPartCalled = lastPart;
      if (expectedParts[partCount] != null) {
        List<int> expectedPart;
        if (expectedParts[partCount] is String) {
          expectedPart = expectedParts[partCount].charCodes;
        } else {
          expectedPart = expectedParts[partCount];
        }
        Expect.listEquals(expectedPart, currentPart);
      }
      currentPart = null;
      partCount++;
      if (lastPart) Expect.equals(expectedParts.length, partCount);
    };

    partCount = 0;
    headers = new Map();
    currentPart = null;
    lastPartCalled = false;
  }

  void testWrite(List<int> data, [int chunkSize = -1]) {
    if (chunkSize == -1) chunkSize = data.length;
    reset();
    int written = 0;
    int unparsed;
    for (int pos = 0; pos < data.length; pos += chunkSize) {
      int remaining = data.length - pos;
      int writeLength = min(chunkSize, remaining);
      written += writeLength;
      int parsed =
          parser.update(data.getRange(pos, writeLength), 0, writeLength);
      unparsed = writeLength - parsed;
      Expect.equals(0, unparsed);
    }
    Expect.isTrue(lastPartCalled);
  }

  // Test parsing the data three times delivering the data in
  // different chunks.
  List<int> data = message.charCodes;
  testWrite(data);
  testWrite(data, 10);
  testWrite(data, 2);
  testWrite(data, 1);
}

void testParseValid() {
  String message;
  Map headers;
  Map headers1;
  Map headers2;
  Map headers3;
  Map headers4;
  String body1;
  String body2;
  String body3;
  String body4;

  // Sample from Wikipedia.
  message = """
This is a message with multiple parts in MIME format.\r
--frontier\r
Content-Type: text/plain\r
\r
This is the body of the message.\r
--frontier\r
Content-Type: application/octet-stream\r
Content-Transfer-Encoding: base64\r
\r
PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=\r
--frontier--\r\n""";
  headers1 = <String, String>{"content-type": "text/plain"};
  headers2 = <String, String>{"content-type": "application/octet-stream",
                              "content-transfer-encoding": "base64"};
  body1 = "This is the body of the message.";
  body2 = """
PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=""";
  testParse(message, "frontier", [headers1, headers2], [body1, body2]);

  // Sample from HTML 4.01 Specification.
  message = """
\r\n--AaB03x\r
Content-Disposition: form-data; name=\"submit-name\"\r
\r
Larry\r
--AaB03x\r
Content-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r
Content-Type: text/plain\r
\r
... contents of file1.txt ...\r
--AaB03x--\r\n""";
  headers1 = <String, String>{
      "content-disposition": "form-data; name=\"submit-name\""};
  headers2 = <String, String>{
      "content-type": "text/plain",
      "content-disposition": "form-data; name=\"files\"; filename=\"file1.txt\""
  };
  body1 = "Larry";
  body2 = "... contents of file1.txt ...";
  testParse(message, "AaB03x", [headers1, headers2], [body1, body2]);

  // Longer form from submitting the following from Chrome.
  //
  // <html>
  // <body>
  // <FORM action="http://127.0.0.1:1234/"
  //     enctype="multipart/form-data"
  //     method="post">
  //  <P>
  //  Text: <INPUT type="text" name="text_input">
  //  Password: <INPUT type="password" name="password_input">
  //  Checkbox: <INPUT type="checkbox" name="checkbox_input">
  //  Radio: <INPUT type="radio" name="radio_input">
  //  Send <INPUT type="submit">
  //  </P>
  // </FORM>
  // </body>
  // </html>

  message = """
\r\n------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name=\"text_input\"\r
\r
text\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name=\"password_input\"\r
\r
password\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name=\"checkbox_input\"\r
\r
on\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name=\"radio_input\"\r
\r
on\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB--\r\n""";
  headers1 = <String, String>{
      "content-disposition": "form-data; name=\"text_input\""};
  headers2 = <String, String>{
      "content-disposition": "form-data; name=\"password_input\""};
  headers3 = <String, String>{
      "content-disposition": "form-data; name=\"checkbox_input\""};
  headers4 = <String, String>{
      "content-disposition": "form-data; name=\"radio_input\""};
  body1 = "text";
  body2 = "password";
  body3 = "on";
  body4 = "on";
  testParse(message,
            "----webkitformboundaryq3cgyamgrf8yoeyb",
            [headers1, headers2, headers3, headers4],
            [body1, body2, body3, body4]);

  // Same form from Firefox.
  message = """
\r\n-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name=\"text_input\"\r
\r
text\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name=\"password_input\"\r
\r
password\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name=\"checkbox_input\"\r
\r
on\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name=\"radio_input\"\r
\r
on\r
-----------------------------52284550912143824192005403738--\r\n""";
  testParse(message,
            "---------------------------52284550912143824192005403738",
            [headers1, headers2, headers3, headers4],
            [body1, body2, body3, body4]);

  // And Internet Explorer
  message = """
\r\n-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name=\"text_input\"\r
\r
text\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name=\"password_input\"\r
\r
password\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name=\"checkbox_input\"\r
\r
on\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name=\"radio_input\"\r
\r
on\r
-----------------------------7dc8f38c60326--\r\n""";
  testParse(message,
            "---------------------------7dc8f38c60326",
            [headers1, headers2, headers3, headers4],
            [body1, body2, body3, body4]);

  // Test boundary prefix inside prefix and content.
  message = """
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r
--bounda\r
--boundar\r
--boundary\r
Content-Type: text/plain\r
\r
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r\r
--bounda\r\r\r
--boundar\r\r\r\r
--boundary\r
Content-Type: text/plain\r
\r
--boundar\r
--bounda\r
--bound\r
--boun\r
--bou\r
--bo\r
--b\r\r\r\r
--\r\r\r
-\r\r
--boundary--\r\n""";
  headers = <String, String>{"content-type": "text/plain"};
  body1 = """
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r\r
--bounda\r\r\r
--boundar\r\r\r""";
  body2 = """
--boundar\r
--bounda\r
--bound\r
--boun\r
--bou\r
--bo\r
--b\r\r\r\r
--\r\r\r
-\r""";
  testParse(message, "boundary", [headers, headers], [body1, body2]);
}

void testParseInvalid() {
  String message;

  // Missing initial CRLF. One body part less.
  message = """
--xxx\r
\r
\r
Body 1\r
--xxx\r
\r
\r
Body2\r
--xxx--\r\n""";
  Expect.throws(() => testParse(message, "xxx", null, [null, null]));

  // Missing end boundary.
  message = """
\r
--xxx\r
\r
\r
Body 1\r
--xxx\r
\r
\r
Body2\r
--xxx\r\n""";
  Expect.throws(() => testParse(message, "xxx", null, [null, null]));
}

void main() {
  testParseValid();
  testParseInvalid();
}
