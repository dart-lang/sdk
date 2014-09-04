// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for some of the utility helper functions used by the compiler.
library polymer.test.build.messages_test;

import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:code_transformers/messages/messages.dart';
import 'package:source_span/source_span.dart';

main() {
  group('snippet', () {
    test('template with no-args works', () {
      expect(new MessageTemplate(_id('code_transformers', 1),
            'this message has no args', '', '').snippet,
          'this message has no args');
    });

    test('template with args throws', () {
      expect(() => new MessageTemplate(_id('code_transformers', 1),
            'this message has %-args-%', '', '')
          .snippet,
          throws);
    });

    test('can pass arguments to create snippet', () {
      expect(new MessageTemplate(_id('code_transformers', 1),
            'a %-b-% c something %-name-% too', '', '')
          .create({'b': "1", 'name': 'foo'}).snippet,
          'a 1 c something foo too');
    });
  });

  test('equals', () {
      expect(new MessageId('hi', 23) == new MessageId('hi', 23), isTrue);
      expect(new MessageId('foo', 23) != new MessageId('bar', 23), isTrue);
      expect(new MessageId('foo', 22) != new MessageId('foo', 23), isTrue);
  });

  for (var encode in [true, false]) {
    var toJson = encode 
        ? (o) => o.toJson()
        : (o) => JSON.decode(JSON.encode(o));
    group('serialize/deserialize ${encode ? "and stringify": ""}', () {
      test('message id', () {
        _eq(msg) {
          expect(new MessageId.fromJson(toJson(msg)) == msg, isTrue);
        }
        _eq(const MessageId('hi', 23));
        _eq(new MessageId('hi', 23));
        _eq(new MessageId('a_b', 23));
        _eq(new MessageId('a-b', 23));
        _eq(new MessageId('a-b-', 3));
        _eq(new MessageId('a', 21));
      });

      test('message', () {
        _eq(msg) {
          var parsed = new Message.fromJson(toJson(msg));
          expect(msg.id, parsed.id);
          expect(msg.snippet, parsed.snippet);
        }
        _eq(new Message(_id('hi', 33), 'snippet here'));
        _eq(new MessageTemplate(_id('hi', 33), 'snippet', 'ignored', 'ignored'));
      });

      test('log entry', () {
        _eq(entry) {
          var parsed = new BuildLogEntry.fromJson(toJson(entry));
          expect(entry.message.id, parsed.message.id);
          expect(entry.message.snippet, entry.message.snippet);
          expect(entry.level, parsed.level);
          expect(entry.span, parsed.span);
        }
        _eq(_entry(33, 'hi there', 12));
        _eq(_entry(33, 'hi there-', 11));
      });

      test('log entry table', () {
        var table = new LogEntryTable();
        table.add(_entry(11, 'hi there', 23));
        table.add(_entry(13, 'hi there', 21));
        table.add(_entry(11, 'hi there', 26));
        expect(table.entries.length, 2);
        expect(table.entries[_id('hi', 11)].length, 2);
        expect(table.entries[_id('hi', 13)].length, 1);

        var table2 = new LogEntryTable.fromJson(toJson(table));
        expect(table2.entries.length, 2);
        expect(table2.entries[_id('hi', 11)].length, 2);
        expect(table2.entries[_id('hi', 13)].length, 1);
        expect(table2.entries[_id('hi', 11)][0].span,
            table.entries[_id('hi', 11)][0].span);
        expect(table2.entries[_id('hi', 11)][1].span,
            table.entries[_id('hi', 11)][1].span);
        expect(table2.entries[_id('hi', 13)][0].span,
            table.entries[_id('hi', 13)][0].span);
      });
    });
  }
}
_id(s, i) => new MessageId(s, i);
_entry(id, snippet, offset) => new BuildLogEntry(
    new Message(_id('hi', id), snippet),
    new SourceSpan(
      new SourceLocation(offset, sourceUrl: 'a', line: 1, column: 3),
      new SourceLocation(offset + 2, sourceUrl: 'a', line: 1, column: 5),
      'hi'),
    'Warning');
