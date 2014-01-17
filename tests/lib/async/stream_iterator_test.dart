// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:unittest/unittest.dart";

main() {
  test("stream iterator basic", () {
    StreamController c = new StreamController();
    Stream s = c.stream;
    StreamIterator i = new StreamIterator(s);
    i.moveNext().then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(42, i.current);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(37, i.current);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isFalse);
    }));
    c.add(42);
    c.add(37);
    c.close();
  });

  test("stream iterator prefilled", () {
    StreamController c = new StreamController();
    c.add(42);
    c.add(37);
    c.close();
    Stream s = c.stream;
    StreamIterator i = new StreamIterator(s);
    i.moveNext().then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(42, i.current);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(37, i.current);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isFalse);
    }));
  });

  test("stream iterator error", () {
    StreamController c = new StreamController();
    Stream s = c.stream;
    StreamIterator i = new StreamIterator(s);
    i.moveNext().then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(42, i.current);
      return i.moveNext();
    })).then((bool b) {
      fail("Result not expected");
    }, onError: expectAsync1((e) {
      expect("BAD", e);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isFalse);
    }));
    c.add(42);
    c.addError("BAD");
    c.add(37);
    c.close();
  });

  test("stream iterator current/moveNext during move", () {
    StreamController c = new StreamController();
    Stream s = c.stream;
    StreamIterator i = new StreamIterator(s);
    i.moveNext().then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(42, i.current);
      new Timer(const Duration(milliseconds:100), expectAsync0(() {
        expect(i.current, null);
        expect(() { i.moveNext(); }, throws);
        c.add(37);
        c.close();
      }));
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isTrue);
      expect(37, i.current);
      return i.moveNext();
    })).then(expectAsync1((bool b) {
      expect(b, isFalse);
    }));
    c.add(42);
  });
}
