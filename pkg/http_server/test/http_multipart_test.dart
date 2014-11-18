// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:http_server/http_server.dart";
import "package:mime/mime.dart";
import "package:unittest/unittest.dart";
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class FormField {
  final String name;
  final value;
  final String contentType;
  final String filename;

  FormField(String this.name,
            this.value,
            {String this.contentType,
             String this.filename});

  bool operator==(other) {
    if (value.length != other.value.length) return false;
    for (int i = 0; i < value.length; i++) {
      if (value[i] != other.value[i]) {
        return false;
      }
    }
    return name == other.name &&
           contentType == other.contentType &&
           filename == other.filename;
  }

  String toString() {
    return "FormField('$name', '$value', '$contentType', '$filename')";
  }
}

void postDataTest(List<int> message,
                  String contentType,
                  String boundary,
                  List<FormField> expectedFields) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      String boundary = request.headers.contentType.parameters['boundary'];
      request
          .transform(new MimeMultipartTransformer(boundary))
          .map((part) => HttpMultipartFormData.parse(
              part, defaultEncoding: LATIN1))
          .map((multipart) {
            var future;
            if (multipart.isText) {
              future = multipart
                  .fold(new StringBuffer(), (b, s) => b..write(s))
                  .then((b) => b.toString());
            } else {
              future = multipart
                  .fold([], (b, s) => b..addAll(s));
            }
            return future
                .then((data) {
                  String contentType;
                  if (multipart.contentType != null) {
                    contentType = multipart.contentType.mimeType;
                  }
                  return new FormField(
                      multipart.contentDisposition.parameters['name'],
                      data,
                      contentType: contentType,
                      filename:
                          multipart.contentDisposition.parameters['filename']);
                });
          })
          .fold([], (l, f) => l..add(f))
          .then(Future.wait)
          .then((fields) {
            expect(fields, equals(expectedFields));
            request.response.close().then((_) => server.close());
          });
    });
    var client = new HttpClient();
    client.post('127.0.0.1', server.port, '/')
        .then((request) {
          request.headers.set('content-type',
                              'multipart/form-data; boundary=$boundary');
          request.add(message);
          return request.close();
        })
        .then((response) {
          client.close();
        });
  });
}

void testEmptyPostData() {
  var message = '''
------WebKitFormBoundaryU3FBruSkJKG0Yor1--\r\n''';

  postDataTest(message.codeUnits,
               'multipart/form-data',
               '----WebKitFormBoundaryU3FBruSkJKG0Yor1',
               []);
}

void testPostData() {
  var message = '''
\r\n--AaB03x\r
Content-Disposition: form-data; name="submit-name"\r
\r
Larry\r
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="file1.txt"\r
Content-Type: text/plain\r
\r
Content of file\r
--AaB03x--\r\n''';

  postDataTest(message.codeUnits,
               'multipart/form-data',
               'AaB03x',
               [new FormField('submit-name', 'Larry'),
                new FormField('files',
                              'Content of file',
                              contentType: 'text/plain',
                              filename: 'file1.txt')]);

  // Windows/IE style file upload.
  message = '''
\r\n--AaB03x\r
Content-Disposition: form-data; name="files"; filename="C:\\file1\\".txt"\r
Content-Type: text/plain\r
\r
Content of file\r
--AaB03x--\r\n''';


  postDataTest(message.codeUnits,
               'multipart/form-data',
               'AaB03x',
               [new FormField('files',
                              'Content of file',
                              contentType: 'text/plain',
                              filename: 'C:\\file1".txt')]);
  // Similar test using Chrome posting.
  message = [
      45, 45, 45, 45, 45, 45, 87, 101, 98, 75, 105, 116, 70, 111, 114, 109, 66,
      111, 117, 110, 100, 97, 114, 121, 81, 83, 113, 108, 56, 107, 68, 65, 76,
      77, 55, 116, 65, 107, 67, 49, 13, 10, 67, 111, 110, 116, 101, 110, 116,
      45, 68, 105, 115, 112, 111, 115, 105, 116, 105, 111, 110, 58, 32, 102,
      111, 114, 109, 45, 100, 97, 116, 97, 59, 32, 110, 97, 109, 101, 61, 34,
      115, 117, 98, 109, 105, 116, 45, 110, 97, 109, 101, 34, 13, 10, 13, 10,
      84, 101, 115, 116, 13, 10, 45, 45, 45, 45, 45, 45, 87, 101, 98, 75, 105,
      116, 70, 111, 114, 109, 66, 111, 117, 110, 100, 97, 114, 121, 81, 83, 113,
      108, 56, 107, 68, 65, 76, 77, 55, 116, 65, 107, 67, 49, 13, 10, 67, 111,
      110, 116, 101, 110, 116, 45, 68, 105, 115, 112, 111, 115, 105, 116, 105,
      111, 110, 58, 32, 102, 111, 114, 109, 45, 100, 97, 116, 97, 59, 32, 110,
      97, 109, 101, 61, 34, 102, 105, 108, 101, 115, 34, 59, 32, 102, 105, 108,
      101, 110, 97, 109, 101, 61, 34, 86, 69, 82, 83, 73, 79, 78, 34, 13, 10,
      67, 111, 110, 116, 101, 110, 116, 45, 84, 121, 112, 101, 58, 32, 97, 112,
      112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 111, 99, 116, 101, 116, 45,
      115, 116, 114, 101, 97, 109, 13, 10, 13, 10, 123, 32, 10, 32, 32, 34, 114,
      101, 118, 105, 115, 105, 111, 110, 34, 58, 32, 34, 50, 49, 56, 54, 48, 34,
      44, 10, 32, 32, 34, 118, 101, 114, 115, 105, 111, 110, 34, 32, 58, 32, 34,
      48, 46, 49, 46, 50, 46, 48, 95, 114, 50, 49, 56, 54, 48, 34, 44, 10, 32,
      32, 34, 100, 97, 116, 101, 34, 32, 32, 32, 32, 58, 32, 34, 50, 48, 49, 51,
      48, 52, 50, 51, 48, 48, 48, 52, 34, 10, 125, 13, 10, 45, 45, 45, 45, 45,
      45, 87, 101, 98, 75, 105, 116, 70, 111, 114, 109, 66, 111, 117, 110, 100,
      97, 114, 121, 81, 83, 113, 108, 56, 107, 68, 65, 76, 77, 55, 116, 65, 107,
      67, 49, 45, 45, 13, 10];

  var data = [
      123, 32, 10, 32, 32, 34, 114, 101, 118, 105, 115, 105, 111, 110, 34, 58,
      32, 34, 50, 49, 56, 54, 48, 34, 44, 10, 32, 32, 34, 118, 101, 114, 115,
      105, 111, 110, 34, 32, 58, 32, 34, 48, 46, 49, 46, 50, 46, 48, 95, 114,
      50, 49, 56, 54, 48, 34, 44, 10, 32, 32, 34, 100, 97, 116, 101, 34, 32, 32,
      32, 32, 58, 32, 34, 50, 48, 49, 51, 48, 52, 50, 51, 48, 48, 48, 52, 34,
      10, 125];

  postDataTest(message,
               'multipart/form-data',
               '----WebKitFormBoundaryQSql8kDALM7tAkC1',
               [new FormField('submit-name', 'Test'),
                new FormField('files',
                              data,
                              contentType: 'application/octet-stream',
                              filename: 'VERSION')]);

  message = [
      45, 45, 45, 45, 45, 45, 87, 101, 98, 75, 105, 116, 70, 111, 114, 109, 66,
      111, 117, 110, 100, 97, 114, 121, 118, 65, 86, 122, 117, 103, 75, 77, 116,
      90, 98, 121, 87, 111, 66, 71, 13, 10, 67, 111, 110, 116, 101, 110, 116,
      45, 68, 105, 115, 112, 111, 115, 105, 116, 105, 111, 110, 58, 32, 102,
      111, 114, 109, 45, 100, 97, 116, 97, 59, 32, 110, 97, 109, 101, 61, 34,
      110, 97, 109, 101, 34, 13, 10, 13, 10, 38, 35, 49, 50, 52, 48, 50, 59, 38,
      35, 49, 50, 52, 50, 53, 59, 38, 35, 49, 50, 51, 54, 52, 59, 38, 35, 49,
      50, 51, 57, 52, 59, 13, 10, 45, 45, 45, 45, 45, 45, 87, 101, 98, 75, 105,
      116, 70, 111, 114, 109, 66, 111, 117, 110, 100, 97, 114, 121, 118, 65, 86,
      122, 117, 103, 75, 77, 116, 90, 98, 121, 87, 111, 66, 71, 45, 45, 13, 10];

  postDataTest(message,
               'multipart/form-data',
               '----WebKitFormBoundaryvAVzugKMtZbyWoBG',
               [new FormField('name', 'ひらがな')]);

  message = [
      45, 45, 45, 45, 45, 45, 87, 101, 98, 75, 105, 116, 70, 111, 114, 109, 66,
      111, 117, 110, 100, 97, 114, 121, 102, 101, 48, 69, 122, 86, 49, 97, 78,
      121, 115, 68, 49, 98, 80, 104, 13, 10, 67, 111, 110, 116, 101, 110, 116,
      45, 68, 105, 115, 112, 111, 115, 105, 116, 105, 111, 110, 58, 32, 102,
      111, 114, 109, 45, 100, 97, 116, 97, 59, 32, 110, 97, 109, 101, 61, 34,
      110, 97, 109, 101, 34, 13, 10, 13, 10, 248, 118, 13, 10, 45, 45, 45, 45,
      45, 45, 87, 101, 98, 75, 105, 116, 70, 111, 114, 109, 66, 111, 117, 110,
      100, 97, 114, 121, 102, 101, 48, 69, 122, 86, 49, 97, 78, 121, 115, 68,
      49, 98, 80, 104, 45, 45, 13, 10];

  postDataTest(message,
               'multipart/form-data',
               '----WebKitFormBoundaryfe0EzV1aNysD1bPh',
               [new FormField('name', 'øv')]);
}


void main() {
  testEmptyPostData();
  testPostData();
}
