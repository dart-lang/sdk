// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.media_type_test;

import 'package:shelf/src/media_type.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("parse", () {
    test("parses a simple MIME type", () {
      var type = new MediaType.parse("text/plain");
      expect(type.type, equals("text"));
      expect(type.subtype, equals("plain"));
    });

    test("allows leading whitespace", () {
      expect(new MediaType.parse(" text/plain").mimeType, equals("text/plain"));
      expect(new MediaType.parse("\ttext/plain").mimeType,
          equals("text/plain"));
    });

    test("allows trailing whitespace", () {
      expect(new MediaType.parse("text/plain ").mimeType, equals("text/plain"));
      expect(new MediaType.parse("text/plain\t").mimeType,
          equals("text/plain"));
    });

    test("disallows separators in the MIME type", () {
      expect(() => new MediaType.parse("te(xt/plain"), throwsFormatException);
      expect(() => new MediaType.parse("text/pla=in"), throwsFormatException);
    });

    test("disallows whitespace around the slash", () {
      expect(() => new MediaType.parse("text /plain"), throwsFormatException);
      expect(() => new MediaType.parse("text/ plain"), throwsFormatException);
    });

    test("parses parameters", () {
      var type = new MediaType.parse("text/plain;foo=bar;baz=bang");
      expect(type.mimeType, equals("text/plain"));
      expect(type.parameters, equals({"foo": "bar", "baz": "bang"}));
    });

    test("allows whitespace around the semicolon", () {
      var type = new MediaType.parse("text/plain ; foo=bar ; baz=bang");
      expect(type.mimeType, equals("text/plain"));
      expect(type.parameters, equals({"foo": "bar", "baz": "bang"}));
    });

    test("disallows whitespace around the equals", () {
      expect(() => new MediaType.parse("text/plain; foo =bar"),
          throwsFormatException);
      expect(() => new MediaType.parse("text/plain; foo= bar"),
          throwsFormatException);
    });

    test("disallows separators in the parameters", () {
      expect(() => new MediaType.parse("text/plain; fo:o=bar"),
          throwsFormatException);
      expect(() => new MediaType.parse("text/plain; foo=b@ar"),
          throwsFormatException);
    });

    test("parses quoted parameters", () {
      var type = new MediaType.parse(
          'text/plain; foo="bar space"; baz="bang\\\\escape"');
      expect(type.mimeType, equals("text/plain"));
      expect(type.parameters, equals({
        "foo": "bar space",
        "baz": "bang\\escape"
      }));
    });
  });

  group("change", () {
    var type;
    setUp(() {
      type = new MediaType.parse("text/plain; foo=bar; baz=bang");
    });

    test("uses the existing fields by default", () {
      var newType = type.change();
      expect(newType.type, equals("text"));
      expect(newType.subtype, equals("plain"));
      expect(newType.parameters, equals({"foo": "bar", "baz": "bang"}));
    });

    test("[type] overrides the existing type", () {
      expect(type.change(type: "new").type, equals("new"));
    });

    test("[subtype] overrides the existing subtype", () {
      expect(type.change(subtype: "new").subtype, equals("new"));
    });

    test("[mimeType] overrides the existing type and subtype", () {
      var newType = type.change(mimeType: "image/png");
      expect(newType.type, equals("image"));
      expect(newType.subtype, equals("png"));
    });

    test("[parameters] overrides and adds to existing parameters", () {
      expect(type.change(parameters: {
        "foo": "zap",
        "qux": "fblthp"
      }).parameters, equals({
        "foo": "zap",
        "baz": "bang",
        "qux": "fblthp"
      }));
    });

    test("[clearParameters] removes existing parameters", () {
      expect(type.change(clearParameters: true).parameters, isEmpty);
    });

    test("[clearParameters] with [parameters] removes before adding", () {
      var newType = type.change(
          parameters: {"foo": "zap"},
          clearParameters: true);
      expect(newType.parameters, equals({"foo": "zap"}));
    });

    test("[type] with [mimeType] is illegal", () {
      expect(() => type.change(type: "new", mimeType: "image/png"),
          throwsArgumentError);
    });

    test("[subtype] with [mimeType] is illegal", () {
      expect(() => type.change(subtype: "new", mimeType: "image/png"),
          throwsArgumentError);
    });
  });

  group("toString", () {
    test("serializes a simple MIME type", () {
      expect(new MediaType("text", "plain").toString(), equals("text/plain"));
    });

    test("serializes a token parameter as a token", () {
      expect(new MediaType("text", "plain", {"foo": "bar"}).toString(),
          equals("text/plain; foo=bar"));
    });

    test("serializes a non-token parameter as a quoted string", () {
      expect(new MediaType("text", "plain", {"foo": "bar baz"}).toString(),
          equals('text/plain; foo="bar baz"'));
    });

    test("escapes a quoted string as necessary", () {
      expect(new MediaType("text", "plain", {"foo": 'bar"\x7Fbaz'}).toString(),
          equals('text/plain; foo="bar\\"\\\x7Fbaz"'));
    });

    test("serializes multiple parameters", () {
      expect(new MediaType("text", "plain", {
        "foo": "bar", "baz": "bang"
      }).toString(), equals("text/plain; foo=bar; baz=bang"));
    });
  });
}
