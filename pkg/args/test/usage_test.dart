// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage_test;

import 'package:unittest/unittest.dart';
import 'package:args/args.dart';

void main() {
  group('ArgParser.getUsage()', () {
    test('negatable flags show "no-" in title', () {
      var parser = new ArgParser();
      parser.addFlag('mode', help: 'The mode');

      validateUsage(parser,
          '''
          --[no-]mode    The mode
          ''');
    });

    test('non-negatable flags don\'t show "no-" in title', () {
      var parser = new ArgParser();
      parser.addFlag('mode', negatable: false, help: 'The mode');

      validateUsage(parser,
          '''
          --mode    The mode
          ''');
    });

    test('if there are no abbreviations, there is no column for them', () {
      var parser = new ArgParser();
      parser.addFlag('mode', help: 'The mode');

      validateUsage(parser,
          '''
          --[no-]mode    The mode
          ''');
    });

    test('options are lined up past abbreviations', () {
      var parser = new ArgParser();
      parser.addFlag('mode', abbr: 'm', help: 'The mode');
      parser.addOption('long', help: 'Lacks an abbreviation');

      validateUsage(parser,
          '''
          -m, --[no-]mode    The mode
              --long         Lacks an abbreviation
          ''');
    });

    test('help text is lined up past the longest option', () {
      var parser = new ArgParser();
      parser.addFlag('mode', abbr: 'm', help: 'Lined up with below');
      parser.addOption('a-really-long-name', help: 'Its help text');

      validateUsage(parser,
          '''
          -m, --[no-]mode             Lined up with below
              --a-really-long-name    Its help text
          ''');
    });

    test('leading empty lines are ignored in help text', () {
      var parser = new ArgParser();
      parser.addFlag('mode', help: '\n\n\n\nAfter newlines');

      validateUsage(parser,
          '''
          --[no-]mode    After newlines
          ''');
    });

    test('trailing empty lines are ignored in help text', () {
      var parser = new ArgParser();
      parser.addFlag('mode', help: 'Before newlines\n\n\n\n');

      validateUsage(parser,
          '''
          --[no-]mode    Before newlines
          ''');
    });

    test('options are documented in the order they were added', () {
      var parser = new ArgParser();
      parser.addFlag('zebra', help: 'First');
      parser.addFlag('monkey', help: 'Second');
      parser.addFlag('wombat', help: 'Third');

      validateUsage(parser,
          '''
          --[no-]zebra     First
          --[no-]monkey    Second
          --[no-]wombat    Third
          ''');
    });

    test('the default value for a flag is shown if on', () {
      var parser = new ArgParser();
      parser.addFlag('affirm', help: 'Should be on', defaultsTo: true);
      parser.addFlag('negate', help: 'Should be off', defaultsTo: false);

      validateUsage(parser,
          '''
          --[no-]affirm    Should be on
                           (defaults to on)

          --[no-]negate    Should be off
          ''');
    });

    test('the default value for an option with no allowed list is shown', () {
      var parser = new ArgParser();
      parser.addOption('any', help: 'Can be anything', defaultsTo: 'whatevs');

      validateUsage(parser,
          '''
          --any    Can be anything
                   (defaults to "whatevs")
          ''');
    });

    test('the allowed list is shown', () {
      var parser = new ArgParser();
      parser.addOption('suit', help: 'Like in cards',
          allowed: ['spades', 'clubs', 'hearts', 'diamonds']);

      validateUsage(parser,
          '''
          --suit    Like in cards
                    [spades, clubs, hearts, diamonds]
          ''');
    });

    test('the default is highlighted in the allowed list', () {
      var parser = new ArgParser();
      parser.addOption('suit', help: 'Like in cards', defaultsTo: 'clubs',
          allowed: ['spades', 'clubs', 'hearts', 'diamonds']);

      validateUsage(parser,
          '''
          --suit    Like in cards
                    [spades, clubs (default), hearts, diamonds]
          ''');
    });

    test('the allowed help is shown', () {
      var parser = new ArgParser();
      parser.addOption('suit', help: 'Like in cards', defaultsTo: 'clubs',
          allowed: ['spades', 'clubs', 'diamonds', 'hearts'],
          allowedHelp: {
            'spades': 'Swords of a soldier',
            'clubs': 'Weapons of war',
            'diamonds': 'Money for this art',
            'hearts': 'The shape of my heart'
          });

      validateUsage(parser,
          '''
          --suit              Like in cards

                [clubs]       Weapons of war
                [diamonds]    Money for this art
                [hearts]      The shape of my heart
                [spades]      Swords of a soldier
          ''');
    });

    test("hidden options don't appear in the help", () {
      var parser = new ArgParser();
      parser.addOption('first', help: 'The first option');
      parser.addOption('second', hide: true);
      parser.addOption('third', help: 'The third option');


      validateUsage(parser,
          '''
          --first    The first option
          --third    The third option
          ''');
    });

    test("hidden flags don't appear in the help", () {
      var parser = new ArgParser();
      parser.addFlag('first', help: 'The first flag');
      parser.addFlag('second', hide: true);
      parser.addFlag('third', help: 'The third flag');


      validateUsage(parser,
          '''
          --[no-]first    The first flag
          --[no-]third    The third flag
          ''');
    });

    test("hidden options don't affect spacing", () {
      var parser = new ArgParser();
      parser.addFlag('first', help: 'The first flag');
      parser.addFlag('second-very-long-option', hide: true);
      parser.addFlag('third', help: 'The third flag');


      validateUsage(parser,
          '''
          --[no-]first    The first flag
          --[no-]third    The third flag
          ''');
    });
  });
}

void validateUsage(ArgParser parser, String expected) {
  expected = unindentString(expected);
  expect(parser.getUsage(), equals(expected));
}

// TODO(rnystrom): Replace one in test_utils.
String unindentString(String text) {
  var lines = text.split('\n');

  // Count the indentation of the last line.
  var whitespace = new RegExp('^ *');
  var indent = whitespace.firstMatch(lines[lines.length - 1])[0].length;

  // Drop the last line. It only exists for specifying indentation.
  lines.removeLast();

  // Strip indentation from the remaining lines.
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.length <= indent) {
      // It's short, so it must be nothing but whitespace.
      if (line.trim() != '') {
        throw new ArgumentError(
            'Line "$line" does not have enough indentation.');
      }

      lines[i] = '';
    } else {
      if (line.substring(0, indent).trim() != '') {
        throw new ArgumentError(
            'Line "$line" does not have enough indentation.');
      }

      lines[i] = line.substring(indent);
    }
  }

  return lines.join('\n');
}
