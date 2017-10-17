// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:convert";
import "dart:typed_data";

main() {
  testMediaType();

  testRoundTrip("");
  testRoundTrip("a");
  testRoundTrip("ab");
  testRoundTrip("abc");
  testRoundTrip("abcd");
  testRoundTrip("Content with special%25 characters: # ? = % # ? = %");
  testRoundTrip("blåbærgrød", UTF8);
  testRoundTrip("blåbærgrød", LATIN1);

  testUriEquals("data:,abc?d");
  testUriEquals("DATA:,ABC?D");
  testUriEquals("data:,a%20bc?d");
  testUriEquals("DATA:,A%20BC?D");
  testUriEquals("data:,abc?d%23e"); // # must and will be is escaped.

  // Test that UriData.uri normalizes path and query.

  testUtf8Encoding("\u1000\uffff");
  testBytes();
  testInvalidCharacters();
  testNormalization();
  testErrors();
}

void testMediaType() {
  for (var mimeType in ["", "text/plain", "text/javascript"]) {
    for (var charset in ["", ";charset=US-ASCII", ";charset=UTF-8"]) {
      for (var base64 in ["", ";base64"]) {
        bool isBase64 = base64.isNotEmpty;
        var text = "data:$mimeType$charset$base64,";
        var uri = UriData.parse(text);

        String expectedCharset =
            charset.isEmpty ? "US-ASCII" : charset.substring(9);
        String expectedMimeType = mimeType.isEmpty ? "text/plain" : mimeType;

        Expect.equals(text, "$uri");
        Expect.equals(expectedMimeType, uri.mimeType);
        Expect.equals(expectedCharset, uri.charset);
        Expect.equals(isBase64, uri.isBase64);
      }
    }
  }
}

void testRoundTrip(String content, [Encoding encoding]) {
  UriData dataUri = new UriData.fromString(content, encoding: encoding);
  Expect.isFalse(dataUri.isBase64);
  Uri uri = dataUri.uri;
  expectUriEquals(new Uri.dataFromString(content, encoding: encoding), uri);

  if (encoding != null) {
    UriData dataUriParams =
        new UriData.fromString(content, parameters: {"charset": encoding.name});
    Expect.equals("$dataUri", "$dataUriParams");
  }

  Expect.equals(encoding ?? ASCII, Encoding.getByName(dataUri.charset));
  Expect.equals(content, dataUri.contentAsString(encoding: encoding));
  Expect.equals(content, dataUri.contentAsString());
  Expect.equals(content, (encoding ?? ASCII).decode(dataUri.contentAsBytes()));

  uri = dataUri.uri;
  Expect.equals(uri.toString(), dataUri.toString());
  Expect.equals(dataUri.toString(), new UriData.fromUri(uri).toString());

  dataUri = new UriData.fromBytes(content.codeUnits);
  Expect.listEquals(content.codeUnits, dataUri.contentAsBytes());
  Expect.equals(content, dataUri.contentAsString(encoding: LATIN1));

  uri = dataUri.uri;
  Expect.equals(uri.toString(), dataUri.toString());
  Expect.equals(dataUri.toString(), new UriData.fromUri(uri).toString());
  // Check that the URI is properly normalized.
  expectUriEquals(uri, Uri.parse("$uri"));
}

void testUtf8Encoding(String content) {
  UriData uri = new UriData.fromString(content, encoding: UTF8);
  Expect.equals(content, uri.contentAsString(encoding: UTF8));
  Expect.listEquals(UTF8.encode(content), uri.contentAsBytes());
}

void testInvalidCharacters() {
  // SPACE, CTL and tspecial, plus '%' and '#' (URI gen-delim)
  // This contains all ASCII character that are not valid in attribute/value
  // parts.
  var invalid =
      '\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x7f'
      ' ()<>@,;:"/[]?=%#\x80\u{1000}\u{10000}';
  var invalidNoSlash = invalid.replaceAll('/', '');
  var dataUri = new UriData.fromString(invalid,
      encoding: UTF8,
      mimeType: "$invalidNoSlash/$invalidNoSlash",
      parameters: {invalid: invalid});

  Expect.equals(invalid, dataUri.contentAsString());
  Expect.equals("$invalidNoSlash/$invalidNoSlash", dataUri.mimeType);
  Expect.equals(invalid, dataUri.parameters[invalid]);

  var uri = dataUri.uri;
  Expect.equals("$uri", "$dataUri");
  expectUriEquals(uri, Uri.parse("$uri")); // Check that it's canonicalized.
  Expect.equals("$dataUri", new UriData.fromUri(uri).toString());
}

void testBytes() {
  void testList(List<int> list) {
    var dataUri = new UriData.fromBytes(list);
    Expect.equals("application/octet-stream", dataUri.mimeType);
    Expect.isTrue(dataUri.isBase64);
    Expect.listEquals(list, dataUri.contentAsBytes());

    dataUri = new UriData.fromBytes(list, percentEncoded: true);
    Expect.equals("application/octet-stream", dataUri.mimeType);
    Expect.isFalse(dataUri.isBase64);
    Expect.listEquals(list, dataUri.contentAsBytes());

    var string = new String.fromCharCodes(list);

    dataUri = new UriData.fromString(string, encoding: LATIN1);
    Expect.equals("text/plain", dataUri.mimeType);
    Expect.isFalse(dataUri.isBase64);
    Expect.listEquals(list, dataUri.contentAsBytes());

    dataUri = new UriData.fromString(string, encoding: LATIN1, base64: true);
    Expect.equals("text/plain", dataUri.mimeType);
    Expect.isTrue(dataUri.isBase64);
    Expect.listEquals(list, dataUri.contentAsBytes());
  }

  void testLists(List<int> list) {
    testList(list);
    for (int i = 0; i < 27; i++) {
      testList(list.sublist(i, i + i)); // All lengths from 0 to 27.
    }
  }

  var bytes = new Uint8List(512);
  for (int i = 0; i < bytes.length; i++) {
    bytes[i] = i;
  }
  testLists(bytes);
  testLists(new List.from(bytes));
  testLists(new List.unmodifiable(bytes));
}

void testNormalization() {
  // Base-64 normalization.

  // Normalized URI-alphabet characters.
  Expect.equals(
      "data:;base64,AA/+", UriData.parse("data:;base64,AA_-").toString());
  // Normalized escapes.
  Expect.equals(
      "data:;base64,AB==", UriData.parse("data:;base64,A%42=%3D").toString());
  Expect.equals("data:;base64,/+/+",
      UriData.parse("data:;base64,%5F%2D%2F%2B").toString());
  // Normalized padded data.
  Expect.equals(
      "data:;base64,AA==", UriData.parse("data:;base64,AA%3D%3D").toString());
  Expect.equals(
      "data:;base64,AAA=", UriData.parse("data:;base64,AAA%3D").toString());
  // Normalized unpadded data.
  Expect.equals(
      "data:;base64,AA==", UriData.parse("data:;base64,AA").toString());
  Expect.equals(
      "data:;base64,AAA=", UriData.parse("data:;base64,AAA").toString());

  // "URI normalization" of non-base64 content.
  var uri = UriData.parse("data:,\x20\xa0");
  Expect.equals("data:,%20%C2%A0", uri.toString());
  uri = UriData.parse("data:,x://x@y:[z]:42/p/./?q=x&y=z#?#\u1234\u{12345}");
  Expect.equals(
      "data:,x://x@y:%5Bz%5D:42/p/./?q=x&y=z%23?%23%E1%88%B4%F0%92%8D%85",
      uri.toString());
}

void testErrors() {
  // Invalid constructor parameters.
  Expect.throwsArgumentError(
      () => new UriData.fromBytes([], mimeType: "noslash"));
  Expect.throwsArgumentError(() => new UriData.fromBytes([257]));
  Expect.throwsArgumentError(() => new UriData.fromBytes([-1]));
  Expect.throwsArgumentError(() => new UriData.fromBytes([0x10000000]));
  Expect.throwsArgumentError(
      () => new UriData.fromString("", mimeType: "noslash"));

  Expect.throwsArgumentError(
      () => new Uri.dataFromBytes([], mimeType: "noslash"));
  Expect.throwsArgumentError(() => new Uri.dataFromBytes([257]));
  Expect.throwsArgumentError(() => new Uri.dataFromBytes([-1]));
  Expect.throwsArgumentError(() => new Uri.dataFromBytes([0x10000000]));
  Expect.throwsArgumentError(
      () => new Uri.dataFromString("", mimeType: "noslash"));

  // Empty parameters allowed, not an error.
  var uri = new UriData.fromString("", mimeType: "", parameters: {});
  Expect.equals("data:,", "$uri");
  // Empty parameter key or value is an error.
  Expect.throwsArgumentError(
      () => new UriData.fromString("", parameters: {"": "X"}));
  Expect.throwsArgumentError(
      () => new UriData.fromString("", parameters: {"X": ""}));

  // Not recognizing charset is an error.
  uri = UriData.parse("data:;charset=arglebargle,X");
  Expect.throws(() {
    uri.contentAsString();
  });
  // Doesn't throw if we specify the encoding.
  Expect.equals("X", uri.contentAsString(encoding: ASCII));

  // Parse format.
  Expect.throwsFormatException(() => UriData.parse("notdata:,"));
  Expect.throwsFormatException(() => UriData.parse("text/plain,noscheme"));
  Expect.throwsFormatException(() => UriData.parse("data:noseparator"));
  Expect.throwsFormatException(() => UriData.parse("data:noslash,text"));
  Expect.throwsFormatException(
      () => UriData.parse("data:type/sub;noequals,text"));
  Expect.throwsFormatException(() => UriData.parse("data:type/sub;knocomma="));
  Expect.throwsFormatException(
      () => UriData.parse("data:type/sub;k=v;nocomma"));
  Expect.throwsFormatException(() => UriData.parse("data:type/sub;k=nocomma"));
  Expect.throwsFormatException(() => UriData.parse("data:type/sub;k=v;base64"));

  void formatError(String input) {
    Expect.throwsFormatException(() => UriData.parse("data:;base64,$input"),
        input);
  }

  // Invalid base64 format (detected when parsed).
  for (var a = 0; a <= 4; a++) {
    for (var p = 0; p <= 4; p++) {
      // Base-64 encoding must have length divisible by four and no more
      // than two padding characters at the end.
      if (p < 3 && (a + p) % 4 == 0) continue;
      if (p == 0 && a > 1) continue;
      formatError("A" * a + "=" * p);
      formatError("A" * a + "%3D" * p);
    }
  }
  // Invalid base64 encoding: padding not at end.
  formatError("AA=A");
  formatError("A=AA");
  formatError("=AAA");
  formatError("A==A");
  formatError("==AA");
  formatError("===A");
  formatError("AAA%3D=");
  formatError("A%3D==");

  // Invalid unpadded data.
  formatError("A");
  formatError("AAAAA");

  // Invalid characters.
  formatError("AAA*");
  formatError("AAA\x00");
  formatError("AAA\\");
  formatError("AAA,");

  // Invalid escapes.
  formatError("AAA%25");
  formatError("AAA%7F");
  formatError("AAA%7F");
}

/// Checks that two [Uri]s are exactly the same.
expectUriEquals(Uri expect, Uri actual) {
  Expect.equals(expect.scheme, actual.scheme, "scheme");
  Expect.equals(expect.hasAuthority, actual.hasAuthority, "hasAuthority");
  Expect.equals(expect.userInfo, actual.userInfo, "userInfo");
  Expect.equals(expect.host, actual.host, "host");
  Expect.equals(expect.hasPort, actual.hasPort, "hasPort");
  Expect.equals(expect.port, actual.port, "port");
  Expect.equals(expect.port, actual.port, "port");
  Expect.equals(expect.hasQuery, actual.hasQuery, "hasQuery");
  Expect.equals(expect.query, actual.query, "query");
  Expect.equals(expect.hasFragment, actual.hasFragment, "hasFragment");
  Expect.equals(expect.fragment, actual.fragment, "fragment");
}

void testUriEquals(String uriText) {
  var data = UriData.parse(uriText);
  var uri = Uri.parse(uriText);
  Expect.equals(data.uri, uri);
  Expect.equals(data.toString(), uri.data.toString());
  Expect.equals(data.toString(), uri.toString());
}
