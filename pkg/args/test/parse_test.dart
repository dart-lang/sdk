// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parse_test;

import 'package:unittest/unittest.dart';
import 'package:args/args.dart';
import 'utils.dart';

void main() {
  group('ArgParser.parse()', () {
    test('does not destructively modify the argument list', () {
      var parser = new ArgParser();
      parser.addFlag('verbose');

      var args = ['--verbose'];
      var results = parser.parse(args);
      expect(args, equals(['--verbose']));
      expect(results['verbose'], isTrue);
    });

    group('flags', () {
      test('are true if present', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse(['--verbose']);
        expect(args['verbose'], isTrue);
      });

      test('default if missing', () {
        var parser = new ArgParser();
        parser.addFlag('a', defaultsTo: true);
        parser.addFlag('b', defaultsTo: false);

        var args = parser.parse([]);
        expect(args['a'], isTrue);
        expect(args['b'], isFalse);
      });

      test('are false if missing with no default', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse([]);
        expect(args['verbose'], isFalse);
      });

      test('throws if given a value', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        throwsFormat(parser, ['--verbose=true']);
      });

      test('are case-sensitive', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');
        parser.addFlag('Verbose');
        var results = parser.parse(['--verbose']);
        expect(results['verbose'], isTrue);
        expect(results['Verbose'], isFalse);
      });
    });

    group('flags negated with "no-"', () {
      test('set the flag to false', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse(['--no-verbose']);
        expect(args['verbose'], isFalse);
      });

      test('set the flag to true if the flag actually starts with "no-"', () {
        var parser = new ArgParser();
        parser.addFlag('no-body');

        var args = parser.parse(['--no-body']);
        expect(args['no-body'], isTrue);
      });

      test('are not preferred over a colliding one without', () {
        var parser = new ArgParser();
        parser.addFlag('no-strum');
        parser.addFlag('strum');

        var args = parser.parse(['--no-strum']);
        expect(args['no-strum'], isTrue);
        expect(args['strum'], isFalse);
      });

      test('fail for non-negatable flags', () {
        var parser = new ArgParser();
        parser.addFlag('strum', negatable: false);

        throwsFormat(parser, ['--no-strum']);
      });
    });

    group('callbacks', () {
      test('for present flags are invoked with the value', () {
        var a;
        var parser = new ArgParser();
        parser.addFlag('a', callback: (value) => a = value);

        var args = parser.parse(['--a']);
        expect(a, isTrue);
      });

      test('for absent flags are invoked with the default value', () {
        var a;
        var parser = new ArgParser();
        parser.addFlag('a', defaultsTo: false,
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, isFalse);
      });

      test('are invoked even if the flag is not present', () {
        var a = 'not called';
        var parser = new ArgParser();
        parser.addFlag('a', callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, isFalse);
      });

      test('for present options are invoked with the value', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', callback: (value) => a = value);

        var args = parser.parse(['--a=v']);
        expect(a, equals('v'));
      });

      test('for absent options are invoked with the default value', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', defaultsTo: 'v',
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, equals('v'));
      });

      test('are invoked even if the option is not present', () {
        var a = 'not called';
        var parser = new ArgParser();
        parser.addOption('a', callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, isNull);
      });

      test('for multiple present, allowMultiple, options are invoked with '
           'value as a list', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', allowMultiple: true,
            callback: (value) => a = value);

        var args = parser.parse(['--a=v', '--a=x']);
        expect(a, equals(['v', 'x']));
      });

      test('for single present, allowMultiple, options are invoked with '
           ' value as a single element list', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', allowMultiple: true,
            callback: (value) => a = value);

        var args = parser.parse(['--a=v']);
        expect(a, equals(['v']));
      });

      test('for absent, allowMultiple, options are invoked with default '
           'value as a list.', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', allowMultiple: true, defaultsTo: 'v',
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, equals(['v']));
      });

      test('for absent, allowMultiple, options are invoked with value '
           'as an empty list.', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', allowMultiple: true,
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a, isEmpty);
      });
    });

    group('abbreviations', () {
      test('are parsed with a preceding "-"', () {
        var parser = new ArgParser();
        parser.addFlag('arg', abbr: 'a');

        var args = parser.parse(['-a']);
        expect(args['arg'], isTrue);
      });

      test('can use multiple after a single "-"', () {
        var parser = new ArgParser();
        parser.addFlag('first', abbr: 'f');
        parser.addFlag('second', abbr: 's');
        parser.addFlag('third', abbr: 't');

        var args = parser.parse(['-tf']);
        expect(args['first'], isTrue);
        expect(args['second'], isFalse);
        expect(args['third'], isTrue);
      });

      test('can have multiple "-" args', () {
        var parser = new ArgParser();
        parser.addFlag('first', abbr: 'f');
        parser.addFlag('second', abbr: 's');
        parser.addFlag('third', abbr: 't');

        var args = parser.parse(['-s', '-tf']);
        expect(args['first'], isTrue);
        expect(args['second'], isTrue);
        expect(args['third'], isTrue);
      });

      test('can take arguments without a space separating', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        var args = parser.parse(['-flip']);
        expect(args['file'], equals('lip'));
      });

      test('can take arguments with a space separating', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        var args = parser.parse(['-f', 'name']);
        expect(args['file'], equals('name'));
      });

      test('allow non-option characters in the value', () {
        var parser = new ArgParser();
        parser.addOption('apple', abbr: 'a');

        var args = parser.parse(['-ab?!c']);
        expect(args['apple'], equals('b?!c'));
      });

      test('throw if unknown', () {
        var parser = new ArgParser();
        throwsFormat(parser, ['-f']);
      });

      test('throw if the value is missing', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        throwsFormat(parser, ['-f']);
      });

      test('throw if the value looks like an option', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');
        parser.addOption('other');

        throwsFormat(parser, ['-f', '--other']);
        throwsFormat(parser, ['-f', '--unknown']);
        throwsFormat(parser, ['-f', '-abbr']);
      });

      test('throw if the value is not allowed', () {
        var parser = new ArgParser();
        parser.addOption('mode', abbr: 'm', allowed: ['debug', 'release']);

        throwsFormat(parser, ['-mprofile']);
      });

      test('throw if any but the first is not a flag', () {
        var parser = new ArgParser();
        parser.addFlag('apple', abbr: 'a');
        parser.addOption('banana', abbr: 'b'); // Takes an argument.
        parser.addFlag('cherry', abbr: 'c');

        throwsFormat(parser, ['-abc']);
      });

      test('throw if it has a value but the option is a flag', () {
        var parser = new ArgParser();
        parser.addFlag('apple', abbr: 'a');
        parser.addFlag('banana', abbr: 'b');

        // The '?!' means this can only be understood as '--apple b?!c'.
        throwsFormat(parser, ['-ab?!c']);
      });

      test('are case-sensitive', () {
        var parser = new ArgParser();
        parser.addFlag('file', abbr: 'f');
        parser.addFlag('force', abbr: 'F');
        var results = parser.parse(['-f']);
        expect(results['file'], isTrue);
        expect(results['force'], isFalse);
      });
    });

    group('options', () {
      test('are parsed if present', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse(['--mode=release']);
        expect(args['mode'], equals('release'));
      });

      test('are null if not present', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse([]);
        expect(args['mode'], isNull);
      });

      test('default if missing', () {
        var parser = new ArgParser();
        parser.addOption('mode', defaultsTo: 'debug');
        var args = parser.parse([]);
        expect(args['mode'], equals('debug'));
      });

      test('allow the value to be separated by whitespace', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse(['--mode', 'release']);
        expect(args['mode'], equals('release'));
      });

      test('throw if unknown', () {
        var parser = new ArgParser();
        throwsFormat(parser, ['--unknown']);
        throwsFormat(parser, ['--nobody']); // Starts with "no".
      });

      test('throw if the arg does not include a value', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        throwsFormat(parser, ['--mode']);
      });

      test('throw if the value looks like an option', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        parser.addOption('other');

        throwsFormat(parser, ['--mode', '--other']);
        throwsFormat(parser, ['--mode', '--unknown']);
        throwsFormat(parser, ['--mode', '-abbr']);
      });

      test('do not throw if the value is in the allowed set', () {
        var parser = new ArgParser();
        parser.addOption('mode', allowed: ['debug', 'release']);
        var args = parser.parse(['--mode=debug']);
        expect(args['mode'], equals('debug'));
      });

      test('throw if the value is not in the allowed set', () {
        var parser = new ArgParser();
        parser.addOption('mode', allowed: ['debug', 'release']);
        throwsFormat(parser, ['--mode=profile']);
      });

      test('returns last provided value', () {
        var parser = new ArgParser();
        parser.addOption('define');
        var args = parser.parse(['--define=1', '--define=2']);
        expect(args['define'], equals('2'));
      });

      test('returns a List if multi-valued', () {
        var parser = new ArgParser();
        parser.addOption('define', allowMultiple: true);
        var args = parser.parse(['--define=1']);
        expect(args['define'], equals(['1']));
        args = parser.parse(['--define=1', '--define=2']);
        expect(args['define'], equals(['1','2']));
      });

      test('returns the default value for multi-valued arguments '
           'if not explicitly set', () {
        var parser = new ArgParser();
        parser.addOption('define', defaultsTo: '0', allowMultiple: true);
        var args = parser.parse(['']);
        expect(args['define'], equals(['0']));
      });

      test('are case-sensitive', () {
        var parser = new ArgParser();
        parser.addOption('verbose', defaultsTo: 'no');
        parser.addOption('Verbose', defaultsTo: 'no');
        var results = parser.parse(['--verbose', 'chatty']);
        expect(results['verbose'], equals('chatty'));
        expect(results['Verbose'], equals('no'));
      });
    });

    group('remaining args', () {
      test('stops parsing args when a non-option-like arg is encountered', () {
        var parser = new ArgParser();
        parser.addFlag('woof');
        parser.addOption('meow');
        parser.addOption('tweet', defaultsTo: 'bird');

        var results = parser.parse(['--woof', '--meow', 'v', 'not', 'option']);
        expect(results['woof'], isTrue);
        expect(results['meow'], equals('v'));
        expect(results['tweet'], equals('bird'));
        expect(results.rest, equals(['not', 'option']));
      });

      test('consumes "--" and stops', () {
        var parser = new ArgParser();
        parser.addFlag('woof', defaultsTo: false);
        parser.addOption('meow', defaultsTo: 'kitty');

        var results = parser.parse(['--woof', '--', '--meow']);
        expect(results['woof'], isTrue);
        expect(results['meow'], equals('kitty'));
        expect(results.rest, equals(['--meow']));
      });

      test('leaves "--" if not the first non-option', () {
        var parser = new ArgParser();
        parser.addFlag('woof');

        var results = parser.parse(['--woof', 'stop', '--', 'arg']);
        expect(results['woof'], isTrue);
        expect(results.rest, equals(['stop', '--', 'arg']));
      });
    });
  });
}
