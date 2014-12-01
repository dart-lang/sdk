// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import "package:unittest/unittest.dart";
import "package:mime/mime.dart";

void _testParse(String message,
               String boundary,
               [List<Map> expectedHeaders,
                List expectedParts,
                bool expectError = false]) {
  Future testWrite(List<int> data, [int chunkSize = -1]) {
    StreamController controller = new StreamController(sync: true);

    var stream = controller.stream.transform(
        new MimeMultipartTransformer(boundary));
    int i = 0;
    var completer = new Completer();
    var futures = [];
    stream.listen((multipart) {
      int part = i++;
      if (expectedHeaders != null) {
        expect(multipart.headers, equals(expectedHeaders[part]));
      }
      futures.add(multipart.fold([], (buffer, data) => buffer..addAll(data))
          .then((data) {
            if (expectedParts[part] != null) {
              expect(data, equals(expectedParts[part].codeUnits));
            }
          }));
    }, onError: (error) {
      if (!expectError) throw error;
    }, onDone: () {
      if (expectedParts != null) {
        expect(i, equals(expectedParts.length));
      }
      Future.wait(futures).then(completer.complete);
    });

    if (chunkSize == -1) chunkSize = data.length;

    int written = 0;
    for (int pos = 0; pos < data.length; pos += chunkSize) {
      int remaining = data.length - pos;
      int writeLength = min(chunkSize, remaining);
      controller.add(data.sublist(pos, pos + writeLength));
      written += writeLength;
    }
    controller.close();

    return completer.future;
  }

  // Test parsing the data three times delivering the data in
  // different chunks.
  List<int> data = message.codeUnits;
  test('test', () {
    expect(Future.wait([
        testWrite(data),
        testWrite(data, 10),
        testWrite(data, 2),
        testWrite(data, 1)]),
        completes);
  });
}

void _testParseValid() {
  // Empty message from Chrome form post.
  var message = '------WebKitFormBoundaryU3FBruSkJKG0Yor1--\r\n';
  _testParse(message, "----WebKitFormBoundaryU3FBruSkJKG0Yor1", [], []);

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
  var headers1 = <String, String>{"content-type": "text/plain"};
  var headers2 = <String, String>{"content-type": "application/octet-stream",
                              "content-transfer-encoding": "base64"};
  var body1 = "This is the body of the message.";
  var body2 = """
PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=""";
  _testParse(message, "frontier", [headers1, headers2], [body1, body2]);

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
  _testParse(message, "AaB03x", [headers1, headers2], [body1, body2]);

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
  var headers3 = <String, String>{
      "content-disposition": "form-data; name=\"checkbox_input\""};
  var headers4 = <String, String>{
      "content-disposition": "form-data; name=\"radio_input\""};
  body1 = "text";
  body2 = "password";
  var body3 = "on";
  var body4 = "on";
  _testParse(message,
            "----WebKitFormBoundaryQ3cgYAmGRF8yOeYB",
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
  _testParse(message,
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
  _testParse(message,
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
  var headers = <String, String>{"content-type": "text/plain"};
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
  _testParse(message, "boundary", [headers, headers], [body1, body2]);

  // Without initial CRLF.
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
  _testParse(message, "xxx", null, ["\r\nBody 1", "\r\nBody2"]);
}

void _testParseInvalid() {
  // Missing end boundary.
  var message = """
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
  _testParse(message, "xxx", null, [null, null], true);
}

void main() {
  _testParseValid();
  _testParseInvalid();
}
