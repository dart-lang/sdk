// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('args_test');

#import('../../../lib/unittest/unittest.dart');
#import('../../../lib/args/args.dart');

main() {
  group('ArgParser.addFlag()', () {
    test('throws IllegalArgumentException if the flag already exists', () {
      var parser = new ArgParser();
      parser.addFlag('foo');
      throwsIllegalArg(() => parser.addFlag('foo'));
    });

    test('throws IllegalArgumentException if the option already exists', () {
      var parser = new ArgParser();
      parser.addOption('foo');
      throwsIllegalArg(() => parser.addFlag('foo'));
    });

    test('throws IllegalArgumentException if the abbreviation exists', () {
      var parser = new ArgParser();
      parser.addFlag('foo', abbr: 'f');
      throwsIllegalArg(() => parser.addFlag('flummox', abbr: 'f'));
    });

    test('throws IllegalArgumentException if the abbreviation is longer '
         'than one character', () {
      var parser = new ArgParser();
      throwsIllegalArg(() => parser.addFlag('flummox', abbr: 'flu'));
    });
  });

  group('ArgParser.addOption()', () {
    test('throws IllegalArgumentException if the flag already exists', () {
      var parser = new ArgParser();
      parser.addFlag('foo');
      throwsIllegalArg(() => parser.addOption('foo'));
    });

    test('throws IllegalArgumentException if the option already exists', () {
      var parser = new ArgParser();
      parser.addOption('foo');
      throwsIllegalArg(() => parser.addOption('foo'));
    });

    test('throws IllegalArgumentException if the abbreviation exists', () {
      var parser = new ArgParser();
      parser.addFlag('foo', abbr: 'f');
      throwsIllegalArg(() => parser.addOption('flummox', abbr: 'f'));
    });

    test('throws IllegalArgumentException if the abbreviation is longer '
         'than one character', () {
      var parser = new ArgParser();
      throwsIllegalArg(() => parser.addOption('flummox', abbr: 'flu'));
    });
  });

  group('ArgParser.parse()', () {
    group('flags', () {
      test('are true if present', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse(['--verbose']);
        expect(args['verbose']).isTrue();
      });

      test('default if missing', () {
        var parser = new ArgParser();
        parser.addFlag('a', defaultsTo: true);
        parser.addFlag('b', defaultsTo: false);

        var args = parser.parse([]);
        expect(args['a']).isTrue();
        expect(args['b']).isFalse();
      });

      test('are false if missing with no default', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse([]);
        expect(args['verbose']).isFalse();
      });

      test('throws if given a value', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        throwsBadFormat(parser, ['--verbose=true']);
      });
    });

    group('flags negated with "no-"', () {
      test('set the flag to false', () {
        var parser = new ArgParser();
        parser.addFlag('verbose');

        var args = parser.parse(['--no-verbose']);
        expect(args['verbose']).isFalse();
      });

      test('set the flag to true if the flag actually starts with "no-"', () {
        var parser = new ArgParser();
        parser.addFlag('no-body');

        var args = parser.parse(['--no-body']);
        expect(args['no-body']).isTrue();
      });

      test('are not preferred over a colliding one without', () {
        var parser = new ArgParser();
        parser.addFlag('no-strum');
        parser.addFlag('strum');

        var args = parser.parse(['--no-strum']);
        expect(args['no-strum']).isTrue();
        expect(args['strum']).isFalse();
      });
    });

    group('callbacks', () {
      test('for present flags are invoked with the value', () {
        var a;
        var parser = new ArgParser();
        parser.addFlag('a', callback: (value) => a = value);

        var args = parser.parse(['--a']);
        expect(a).isTrue();
      });

      test('for absent flags are invoked with the default value', () {
        var a;
        var parser = new ArgParser();
        parser.addFlag('a', defaultsTo: false,
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a).isFalse();
      });

      test('are invoked even if the flag is not present', () {
        var a = 'not called';
        var parser = new ArgParser();
        parser.addFlag('a', callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a).isFalse();
      });

      test('for present options are invoked with the value', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', callback: (value) => a = value);

        var args = parser.parse(['--a=v']);
        expect(a).equals('v');
      });

      test('for absent options are invoked with the default value', () {
        var a;
        var parser = new ArgParser();
        parser.addOption('a', defaultsTo: 'v',
            callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a).equals('v');
      });

      test('are invoked even if the option is not present', () {
        var a = 'not called';
        var parser = new ArgParser();
        parser.addOption('a', callback: (value) => a = value);

        var args = parser.parse([]);
        expect(a).isNull();
      });
    });

    group('abbreviations', () {
      test('are parsed with a preceding "-"', () {
        var parser = new ArgParser();
        parser.addFlag('arg', abbr: 'a');

        var args = parser.parse(['-a']);
        expect(args['arg']).isTrue();
      });

      test('can use multiple after a single "-"', () {
        var parser = new ArgParser();
        parser.addFlag('first', abbr: 'f');
        parser.addFlag('second', abbr: 's');
        parser.addFlag('third', abbr: 't');

        var args = parser.parse(['-tf']);
        expect(args['first']).isTrue();
        expect(args['second']).isFalse();
        expect(args['third']).isTrue();
      });

      test('can have multiple "-" args', () {
        var parser = new ArgParser();
        parser.addFlag('first', abbr: 'f');
        parser.addFlag('second', abbr: 's');
        parser.addFlag('third', abbr: 't');

        var args = parser.parse(['-s', '-tf']);
        expect(args['first']).isTrue();
        expect(args['second']).isTrue();
        expect(args['third']).isTrue();
      });

      test('can take arguments without a space separating', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        var args = parser.parse(['-flip']);
        expect(args['file']).equals('lip');
      });

      test('can take arguments with a space separating', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        var args = parser.parse(['-f', 'name']);
        expect(args['file']).equals('name');
      });

      test('allow non-option characters in the value', () {
        var parser = new ArgParser();
        parser.addOption('apple', abbr: 'a');

        var args = parser.parse(['-ab?!c']);
        expect(args['apple']).equals('b?!c');
      });

      test('throw if unknown', () {
        var parser = new ArgParser();
        throwsBadFormat(parser, ['-f']);
      });

      test('throw if the value is missing', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');

        throwsBadFormat(parser, ['-f']);
      });

      test('throw if the value looks like an option', () {
        var parser = new ArgParser();
        parser.addOption('file', abbr: 'f');
        parser.addOption('other');

        throwsBadFormat(parser, ['-f', '--other']);
        throwsBadFormat(parser, ['-f', '--unknown']);
        throwsBadFormat(parser, ['-f', '-abbr']);
      });

      test('throw if the value is not allowed', () {
        var parser = new ArgParser();
        parser.addOption('mode', abbr: 'm', allowed: ['debug', 'release']);

        throwsBadFormat(parser, ['-mprofile']);
      });

      test('throw if any but the first is not a flag', () {
        var parser = new ArgParser();
        parser.addFlag('apple', abbr: 'a');
        parser.addOption('banana', abbr: 'b'); // Takes an argument.
        parser.addFlag('cherry', abbr: 'c');

        throwsBadFormat(parser, ['-abc']);
      });

      test('throw if it has a value but the option is a flag', () {
        var parser = new ArgParser();
        parser.addFlag('apple', abbr: 'a');
        parser.addFlag('banana', abbr: 'b');

        // The '?!' means this can only be understood as '--apple b?!c'.
        throwsBadFormat(parser, ['-ab?!c']);
      });
    });

    group('options', () {
      test('are parsed if present', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse(['--mode=release']);
        expect(args['mode']).equals('release');
      });

      test('are null if not present', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse([]);
        expect(args['mode']).isNull();
      });

      test('default if missing', () {
        var parser = new ArgParser();
        parser.addOption('mode', defaultsTo: 'debug');
        var args = parser.parse([]);
        expect(args['mode']).equals('debug');
      });

      test('allow the value to be separated by whitespace', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        var args = parser.parse(['--mode', 'release']);
        expect(args['mode']).equals('release');
      });

      test('throw if unknown', () {
        var parser = new ArgParser();
        throwsBadFormat(parser, ['--unknown']);
        throwsBadFormat(parser, ['--nobody']); // Starts with "no".
      });

      test('throw if the arg does not include a value', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        throwsBadFormat(parser, ['--mode']);
      });

      test('throw if the value looks like an option', () {
        var parser = new ArgParser();
        parser.addOption('mode');
        parser.addOption('other');

        throwsBadFormat(parser, ['--mode', '--other']);
        throwsBadFormat(parser, ['--mode', '--unknown']);
        throwsBadFormat(parser, ['--mode', '-abbr']);
      });

      test('do not throw if the value is in the allowed set', () {
        var parser = new ArgParser();
        parser.addOption('mode', allowed: ['debug', 'release']);
        var args = parser.parse(['--mode=debug']);
        expect(args['mode']).equals('debug');
      });

      test('throw if the value is not in the allowed set', () {
        var parser = new ArgParser();
        parser.addOption('mode', allowed: ['debug', 'release']);
        throwsBadFormat(parser, ['--mode=profile']);
      });
    });

    group('remaining args', () {
      test('stops parsing args when a non-option-like arg is encountered', () {
        var parser = new ArgParser();
        parser.addFlag('woof');
        parser.addOption('meow');
        parser.addOption('tweet', defaultsTo: 'bird');

        var results = parser.parse(['--woof', '--meow', 'v', 'not', 'option']);
        expect(results['woof']).isTrue();
        expect(results['meow']).equals('v');
        expect(results['tweet']).equals('bird');
        expect(results.rest).equalsCollection(['not', 'option']);
      });

      test('stops parsing at "--"', () {
        var parser = new ArgParser();
        parser.addFlag('woof', defaultsTo: false);
        parser.addOption('meow', defaultsTo: 'kitty');

        var results = parser.parse(['--woof', '--', '--meow']);
        expect(results['woof']).isTrue();
        expect(results['meow']).equals('kitty');
        expect(results.rest).equalsCollection(['--meow']);
      });
    });
  });

  group('ArgParser.getUsage()', () {
    test('flags show "no-" in title', () {
      var parser = new ArgParser();
      parser.addFlag('mode', help: 'The mode');

      validateUsage(parser,
          '''
          --[no-]mode    The mode
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
  });

  group('ArgResults[]', () {
    test('throws if the name is not an option', () {
      var parser = new ArgParser();
      var results = parser.parse([]);
      throwsIllegalArg(() => results['unknown']);
    });
  });
}

throwsIllegalArg(function) {
  expectThrow(function, (e) => e is IllegalArgumentException);
}

throwsBadFormat(ArgParser parser, List<String> args) {
  expectThrow(() => parser.parse(args), (e) => e is ArgFormatException);
}

validateUsage(ArgParser parser, String expected) {
  expected = unindentString(expected);
  expect(parser.getUsage()).equals(expected);
}

// TODO(rnystrom): Replace one in test_utils.
String unindentString(String text) {
  var lines = text.split('\n');

  // Count the indentation of the last line.
  var whitespace = const RegExp('^ *');
  var indent = whitespace.firstMatch(lines[lines.length - 1])[0].length;

  // Drop the last line. It only exists for specifying indentation.
  lines.removeLast();

  // Strip indentation from the remaining lines.
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.length <= indent) {
      // It's short, so it must be nothing but whitespace.
      if (line.trim() != '') {
        throw new IllegalArgumentException(
            'Line "$line" does not have enough indentation.');
      }

      lines[i] = '';
    } else {
      if (line.substring(0, indent).trim() != '') {
        throw new IllegalArgumentException(
            'Line "$line" does not have enough indentation.');
      }

      lines[i] = line.substring(indent);
    }
  }

  return Strings.join(lines, '\n');
}
