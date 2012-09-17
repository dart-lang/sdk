// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('logging_test');

// TODO(rnystrom): Use "package:" import when test.dart supports it (#4968).
#import('../lib/logging.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  test('level comparison is a valid comparator', () {
    var level1 = const Level('NOT_REAL1', 253);
    expect(level1 == level1);
    expect(level1 <= level1);
    expect(level1 >= level1);
    expect(level1 < level1, isFalse);
    expect(level1 > level1, isFalse);

    var level2 = const Level('NOT_REAL2', 455);
    expect(level1 <= level2);
    expect(level1 < level2);
    expect(level2 >= level1);
    expect(level2 > level1);

    var level3 = const Level('NOT_REAL3', 253);
    expect(level1 !== level3); // different instances
    expect(level1 == level3); // same value.
  });

  test('default levels are in order', () {
    final levels = const [
        Level.ALL, Level.FINEST, Level.FINER, Level.FINE, Level.CONFIG,
        Level.INFO, Level.WARNING, Level.SEVERE, Level.SHOUT, Level.OFF
      ];

    for (int i = 0; i < levels.length; i++) {
      for (int j = i + 1; j < levels.length; j++) {
        expect(levels[i] < levels[j]);
      }
    }
  });

  test('levels are comparable', () {
    final unsorted = [
        Level.INFO, Level.CONFIG, Level.FINE, Level.SHOUT, Level.OFF,
        Level.FINER, Level.ALL, Level.WARNING, Level.FINEST,  Level.SEVERE,
      ];
    final sorted = const [
        Level.ALL, Level.FINEST, Level.FINER, Level.FINE, Level.CONFIG,
        Level.INFO, Level.WARNING, Level.SEVERE, Level.SHOUT, Level.OFF
      ];
    expect(unsorted, isNot(orderedEquals(sorted)));

    unsorted.sort((a, b) => a.compareTo(b));
    expect(unsorted, orderedEquals(sorted));
  });

  test('levels are hashable', () {
    var map = new Map<Level, String>();
    map[Level.INFO] = 'info';
    map[Level.SHOUT] = 'shout';
    expect(map[Level.INFO], equals('info'));
    expect(map[Level.SHOUT], equals('shout'));
  });

  test('logger name cannot start with a "." ', () {
    expect(() => new Logger('.c'), throws);
  });

  test('logger naming is hierarchical', () {
    Logger c = new Logger('a.b.c');
    expect(c.name, equals('c'));
    expect(c.parent.name, equals('b'));
    expect(c.parent.parent.name, equals('a'));
    expect(c.parent.parent.parent.name, equals(''));
    expect(c.parent.parent.parent.parent, isNull);
  });

  test('logger full name', () {
    Logger c = new Logger('a.b.c');
    expect(c.fullName, equals('a.b.c'));
    expect(c.parent.fullName, equals('a.b'));
    expect(c.parent.parent.fullName, equals('a'));
    expect(c.parent.parent.parent.fullName, equals(''));
    expect(c.parent.parent.parent.parent, isNull);
  });

  test('logger parent-child links are correct', () {
    Logger a = new Logger('a');
    Logger b = new Logger('a.b');
    Logger c = new Logger('a.c');
    expect(a == b.parent);
    expect(a == c.parent);
    expect(a.children['b'] == b);
    expect(a.children['c'] == c);
  });

  test('loggers are singletons', () {
    Logger a1 = new Logger('a');
    Logger a2 = new Logger('a');
    Logger b = new Logger('a.b');
    Logger root = Logger.root;
    expect(a1 === a2);
    expect(a1 === b.parent);
    expect(root === a1.parent);
    expect(root === new Logger(''));
  });

  group('mutating levels', () {
    Logger root = Logger.root;
    Logger a = new Logger('a');
    Logger b = new Logger('a.b');
    Logger c = new Logger('a.b.c');
    Logger d = new Logger('a.b.c.d');
    Logger e = new Logger('a.b.c.d.e');

    setUp(() {
      hierarchicalLoggingEnabled = true;
      root.level = Level.INFO;
      a.level = null;
      b.level = null;
      c.level = null;
      d.level = null;
      e.level = null;
      root.on.record.clear();
      a.on.record.clear();
      b.on.record.clear();
      c.on.record.clear();
      d.on.record.clear();
      e.on.record.clear();
      hierarchicalLoggingEnabled = false;
      root.level = Level.INFO;
    });

    test('cannot set level if hierarchy is disabled', () {
      expect(() {a.level = Level.FINE;}, throws);
    });

    test('loggers effective level - no hierarchy', () {
      expect(root.level, equals(Level.INFO));
      expect(a.level, equals(Level.INFO));
      expect(b.level, equals(Level.INFO));

      root.level = Level.SHOUT;

      expect(root.level, equals(Level.SHOUT));
      expect(a.level, equals(Level.SHOUT));
      expect(b.level, equals(Level.SHOUT));
    });

    test('loggers effective level - with hierarchy', () {
      hierarchicalLoggingEnabled = true;
      expect(root.level, equals(Level.INFO));
      expect(a.level, equals(Level.INFO));
      expect(b.level, equals(Level.INFO));
      expect(c.level, equals(Level.INFO));

      root.level = Level.SHOUT;
      b.level = Level.FINE;

      expect(root.level, equals(Level.SHOUT));
      expect(a.level, equals(Level.SHOUT));
      expect(b.level, equals(Level.FINE));
      expect(c.level, equals(Level.FINE));
    });

    test('isLoggable is appropriate', () {
      hierarchicalLoggingEnabled = true;
      root.level = Level.SEVERE;
      c.level = Level.ALL;
      e.level = Level.OFF;

      expect(root.isLoggable(Level.SHOUT));
      expect(root.isLoggable(Level.SEVERE));
      expect(!root.isLoggable(Level.WARNING));
      expect(c.isLoggable(Level.FINEST));
      expect(c.isLoggable(Level.FINE));
      expect(!e.isLoggable(Level.SHOUT));
    });

    test('add/remove handlers - no hierarchy', () {
      int calls = 0;
      var handler = (_) { calls++; };
      c.on.record.add(handler);
      root.info("foo");
      root.info("foo");
      expect(calls, equals(2));
      c.on.record.remove(handler);
      root.info("foo");
      expect(calls, equals(2));
    });

    test('add/remove handlers - with hierarchy', () {
      hierarchicalLoggingEnabled = true;
      int calls = 0;
      var handler = (_) { calls++; };
      c.on.record.add(handler);
      root.info("foo");
      root.info("foo");
      expect(calls, equals(0));
    });

    test('logging methods store appropriate level', () {
      root.level = Level.ALL;
      var rootMessages = [];
      root.on.record.add((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.finest('1');
      root.finer('2');
      root.fine('3');
      root.config('4');
      root.info('5');
      root.warning('6');
      root.severe('7');
      root.shout('8');

      expect(rootMessages, equals([
        'FINEST: 1',
        'FINER: 2',
        'FINE: 3',
        'CONFIG: 4',
        'INFO: 5',
        'WARNING: 6',
        'SEVERE: 7',
        'SHOUT: 8']));
    });

    test('message logging - no hierarchy', () {
      root.level = Level.WARNING;
      var rootMessages = [];
      var aMessages = [];
      var cMessages = [];
      c.on.record.add((record) {
        cMessages.add('${record.level}: ${record.message}');
      });
      a.on.record.add((record) {
        aMessages.add('${record.level}: ${record.message}');
      });
      root.on.record.add((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.info('1');
      root.fine('2');
      root.shout('3');

      b.info('4');
      b.severe('5');
      b.warning('6');
      b.fine('7');

      c.fine('8');
      c.warning('9');
      c.shout('10');

      expect(rootMessages, equals([
            // 'INFO: 1' is not loggable
            // 'FINE: 2' is not loggable
            'SHOUT: 3',
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10']));

      // no hierarchy means we all hear the same thing.
      expect(aMessages, equals(rootMessages));
      expect(cMessages, equals(rootMessages));
    });

    test('message logging - with hierarchy', () {
      hierarchicalLoggingEnabled = true;

      b.level = Level.WARNING;

      var rootMessages = [];
      var aMessages = [];
      var cMessages = [];
      c.on.record.add((record) {
        cMessages.add('${record.level}: ${record.message}');
      });
      a.on.record.add((record) {
        aMessages.add('${record.level}: ${record.message}');
      });
      root.on.record.add((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.info('1');
      root.fine('2');
      root.shout('3');

      b.info('4');
      b.severe('5');
      b.warning('6');
      b.fine('7');

      c.fine('8');
      c.warning('9');
      c.shout('10');

      expect(rootMessages, equals([
            'INFO: 1',
            // 'FINE: 2' is not loggable
            'SHOUT: 3',
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10']));

      expect(aMessages, equals([
            // 1,2 and 3 are lower in the hierarchy
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10']));

      expect(cMessages, equals([
            // 1 - 7 are lower in the hierarchy
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10']));
    });
  });
}
