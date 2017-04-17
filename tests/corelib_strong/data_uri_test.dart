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

  testUtf8Encoding("\u1000\uffff");
  testBytes();
  testInvalidCharacters();
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

bool badArgument(e) => e is ArgumentError;
bool badFormat(e) => e is FormatException;

void testErrors() {
  // Invalid constructor parameters.
  Expect.throws(() {
    new UriData.fromBytes([], mimeType: "noslash");
  }, badArgument);
  Expect.throws(() {
    new UriData.fromBytes([257]);
  }, badArgument);
  Expect.throws(() {
    new UriData.fromBytes([-1]);
  }, badArgument);
  Expect.throws(() {
    new UriData.fromBytes([0x10000000]);
  }, badArgument);
  Expect.throws(() {
    new UriData.fromString("", mimeType: "noslash");
  }, badArgument);

  Expect.throws(() {
    new Uri.dataFromBytes([], mimeType: "noslash");
  }, badArgument);
  Expect.throws(() {
    new Uri.dataFromBytes([257]);
  }, badArgument);
  Expect.throws(() {
    new Uri.dataFromBytes([-1]);
  }, badArgument);
  Expect.throws(() {
    new Uri.dataFromBytes([0x10000000]);
  }, badArgument);
  Expect.throws(() {
    new Uri.dataFromString("", mimeType: "noslash");
  }, badArgument);

  // Empty parameters allowed, not an error.
  var uri = new UriData.fromString("", mimeType: "", parameters: {});
  Expect.equals("data:,", "$uri");
  // Empty parameter key or value is an error.
  Expect.throws(
      () => new UriData.fromString("", parameters: {"": "X"}), badArgument);
  Expect.throws(
      () => new UriData.fromString("", parameters: {"X": ""}), badArgument);

  // Not recognizing charset is an error.
  uri = UriData.parse("data:;charset=arglebargle,X");
  Expect.throws(() {
    uri.contentAsString();
  });
  // Doesn't throw if we specify the encoding.
  Expect.equals("X", uri.contentAsString(encoding: ASCII));

  // Parse format.
  Expect.throws(() {
    UriData.parse("notdata:,");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("text/plain,noscheme");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:noseparator");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:noslash,text");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:type/sub;noequals,text");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:type/sub;knocomma=");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:type/sub;k=v;nocomma");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:type/sub;k=nocomma");
  }, badFormat);
  Expect.throws(() {
    UriData.parse("data:type/sub;k=v;base64");
  }, badFormat);

  // Invalid base64 format (only detected when decodeing).
  for (var a = 0; a <= 4; a++) {
    for (var p = 0; p <= 4; p++) {
      // Base-64 encoding must have length divisible by four and no more
      // than two padding characters at the end.
      if (p < 3 && (a + p) % 4 == 0) continue;
      uri = UriData.parse("data:;base64," + "A" * a + "=" * p);
      Expect.throws(uri.contentAsBytes, badFormat);
    }
  }
  // Invalid base64 encoding: padding not at end.
  uri = UriData.parse("data:;base64,AA=A");
  Expect.throws(uri.contentAsBytes, badFormat);
  uri = UriData.parse("data:;base64,A=AA");
  Expect.throws(uri.contentAsBytes, badFormat);
  uri = UriData.parse("data:;base64,=AAA");
  Expect.throws(uri.contentAsBytes, badFormat);
  uri = UriData.parse("data:;base64,A==A");
  Expect.throws(uri.contentAsBytes, badFormat);
  uri = UriData.parse("data:;base64,==AA");
  Expect.throws(uri.contentAsBytes, badFormat);
  uri = UriData.parse("data:;base64,===A");
  Expect.throws(uri.contentAsBytes, badFormat);
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
