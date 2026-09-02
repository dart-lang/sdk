// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('pluralize', () {
    test('zero', () {
      expect(pluralize('cat', 0), 'cats');
    });

    test('one', () {
      expect(pluralize('cat', 1), 'cat');
    });

    test('many', () {
      expect(pluralize('cat', 2), 'cats');
    });
  });

  group('relativePath', () {
    test('direct', () {
      var dir = Directory('foo');
      expect(relativePath('path', dir), 'path');
    });

    test('nested', () {
      var dir = Directory('foo');
      expect(relativePath(path.join(dir.absolute.path, 'path'), dir), 'path');
    });
  });

  group('trimEnd', () {
    test('null suffix', () {
      expect(trimEnd('string', null), 'string');
    });

    test('suffix empty', () {
      expect(trimEnd('string', ''), 'string');
    });

    test('suffix miss', () {
      expect(trimEnd('string', 'suf'), 'string');
    });

    test('suffix hit', () {
      expect(trimEnd('string', 'ring'), 'st');
    });
  });

  group('FileSystemEntityExtension', () {
    test('isDartFile', () {
      expect(File('foo.dart').isDartFile, isTrue);
      expect(Directory('foo.dartt').isDartFile, isFalse);
      expect(File('foo.dartt').isDartFile, isFalse);
      expect(File('foo.darrt').isDartFile, isFalse);
      expect(File('bar.bart').isDartFile, isFalse);
      expect(File('bazdart').isDartFile, isFalse);
    });

    test('name', () {
      expect(Directory('').name, '');
      expect(Directory('dirName').name, 'dirName');
      expect(Directory('dirName${path.separator}').name, 'dirName');
      expect(File('').name, '');
      expect(File('foo.dart').name, 'foo.dart');
      expect(File('${path.separator}foo.dart').name, 'foo.dart');
    });

    test('basenameWithoutExtension', () {
      expect(File('foo.dart').basenameWithoutExtension, equals('foo'));
      expect(File('foo.bar.dart').basenameWithoutExtension, equals('foo.bar'));
      expect(File('foo').basenameWithoutExtension, equals('foo'));
      expect(File('').basenameWithoutExtension, equals(''));
    });
  });

  group('wrapText', () {
    test('oneLine_wordLongerThanLine', () {
      expect(wrapText('http://long-url', width: 10), equals('http://long-url'));
    });

    test('singleLine', () {
      expect(wrapText('one two', width: 10), equals('one two'));
    });

    test('singleLine_exactLength', () {
      expect(wrapText('one twoooo', width: 10), equals('one twoooo'));
    });

    test('singleLine_exactLength_minusOne', () {
      expect(wrapText('one twooo', width: 10), equals('one twooo'));
    });

    test('singleLine_exactLength_plusOne', () {
      expect(wrapText('one twooooo', width: 10), equals('one\ntwooooo'));
    });

    test('twoLines_exactLength', () {
      expect(
        wrapText('one two three four', width: 10),
        equals('one two\nthree four'),
      );
    });

    test('twoLines_exactLength_minusOne', () {
      expect(
        wrapText('one two three fou', width: 10),
        equals('one two\nthree fou'),
      );
    });

    test('twoLines_exactLength_plusOne', () {
      expect(
        wrapText('one two three fourr', width: 10),
        equals('one two\nthree\nfourr'),
      );
    });

    test('twoLines_lastLineEndsWithSpace', () {
      expect(wrapText('one two three ', width: 10), equals('one two\nthree '));
    });

    test('twoLines_multipleSpacesAtSplit', () {
      expect(
        wrapText('one two.  Three', width: 10),
        equals('one two. \nThree'),
      );
    });

    test('twoLines_noSpaceLastLine', () {
      expect(wrapText('one two three', width: 10), equals('one two\nthree'));
    });

    test('twoLines_wordLongerThanLine_firstLine', () {
      expect(
        wrapText('http://long-url word', width: 10),
        equals('http://long-url\nword'),
      );
    });

    test('twoLines_wordLongerThanLine_lastLine', () {
      expect(
        wrapText('word http://long-url', width: 10),
        equals('word\nhttp://long-url'),
      );
    });

    test('ansiColorCodes', () {
      const green = '\x1B[32m';
      const reset = '\x1B[0m';
      expect(
        wrapText('one ${green}two three$reset four', width: 10),
        equals('one ${green}two\nthree$reset four'),
      );
    });

    test('ansiMultipleEscapes', () {
      const bold = '\x1B[1m';
      const green = '\x1B[32m';
      const reset = '\x1B[0m';
      expect(
        wrapText('one $bold${green}two three$reset four', width: 10),
        equals('one $bold${green}two\nthree$reset four'),
      );
    });

    test('ansiTrueColor', () {
      const trueColor = '\x1B[38;2;255;85;85m';
      const reset = '\x1B[0m';
      expect(
        wrapText('one ${trueColor}two three$reset four', width: 10),
        equals('one ${trueColor}two\nthree$reset four'),
      );
    });

    test('ansiColorAtWrapBoundary', () {
      const green = '\x1B[32m';
      const reset = '\x1B[0m';
      // The escape sequence is immediately before a space that triggers wrapping.
      expect(
        wrapText('one two$green three$reset four', width: 7),
        equals('one two$green\nthree$reset\nfour'),
      );
    });
  });

  group('MarkdownTable', () {
    test('generate', () {
      const numbers = ['zero', 'one', 'two', 'three', 'four'];

      var table = MarkdownTable();
      table.startRow()
        ..cell('Number')
        ..cell('Value')
        ..cell('Words');
      for (var foo in [1, 2, 3, 4]) {
        table.startRow()
          ..cell(numbers[foo])
          ..cell(foo.toStringAsFixed(1), right: true)
          ..cell('bar ' * foo);
      }
      var result = table.finish();
      expect(
        result,
        equals('''
| Number | Value | Words            |
| ------ | ----- | ---------------- |
| one    |   1.0 | bar              |
| two    |   2.0 | bar bar          |
| three  |   3.0 | bar bar bar      |
| four   |   4.0 | bar bar bar bar  |
'''),
      );
    });
  });

  group('isValidPackageName', () {
    test('valid names', () {
      expect(isValidPackageName('foo'), isTrue);
      expect(isValidPackageName('foo_bar'), isTrue);
      expect(isValidPackageName('f_o_o'), isTrue);
      expect(isValidPackageName('_foo'), isTrue);
    });

    test('invalid names containing capitals', () {
      expect(isValidPackageName('Foo'), isFalse);
      expect(isValidPackageName('fooBar'), isFalse);
      expect(isValidPackageName('FOO'), isFalse);
    });

    test('invalid names starting with digits', () {
      expect(isValidPackageName('1foo'), isFalse);
      expect(isValidPackageName('1_foo'), isFalse);
    });

    test('invalid names containing special characters', () {
      expect(isValidPackageName('foo-bar'), isFalse);
      expect(isValidPackageName('foo.bar'), isFalse);
      expect(isValidPackageName('foo\$bar'), isFalse);
    });

    test('invalid names that are Dart keywords', () {
      expect(isValidPackageName('class'), isFalse);
      expect(isValidPackageName('void'), isFalse);
      expect(isValidPackageName('import'), isFalse);
      expect(isValidPackageName('abstract'), isFalse);
      expect(isValidPackageName('var'), isFalse);
      expect(isValidPackageName('null'), isFalse);
      expect(isValidPackageName('true'), isFalse);
      expect(isValidPackageName('false'), isFalse);
    });
  });

  group('projectNameToLowerCase', () {
    test('lowercase name stays same', () {
      expect(projectNameToLowerCase('foo'), equals('foo'));
      expect(projectNameToLowerCase('foo_bar'), equals('foo_bar'));
    });

    test('uppercase converted to lowercase', () {
      expect(projectNameToLowerCase('FOO'), equals('foo'));
    });

    test('camelCase and PascalCase converted to snake_case', () {
      expect(projectNameToLowerCase('fooBar'), equals('foo_bar'));
      expect(projectNameToLowerCase('FooBar'), equals('foo_bar'));
      expect(
        projectNameToLowerCase('MyAwesomeProject'),
        equals('my_awesome_project'),
      );
    });

    test('already snake_case mixed case converted to lowercase', () {
      expect(projectNameToLowerCase('foo_Bar'), equals('foo_bar'));
      expect(projectNameToLowerCase('Foo_Bar'), equals('foo_bar'));
    });

    test('single capital letters converted correctly', () {
      expect(projectNameToLowerCase('A'), equals('a'));
      expect(projectNameToLowerCase('fooA'), equals('foo_a'));
    });
  });

  group('normalizeProjectName', () {
    test('replaces dashes and spaces with underscores', () {
      expect(normalizeProjectName('foo-bar'), equals('foo_bar'));
      expect(normalizeProjectName('foo bar'), equals('foo_bar'));
      expect(normalizeProjectName('Foo-Bar'), equals('foo__bar'));
    });

    test('replaces consecutive dashes and spaces', () {
      expect(normalizeProjectName('foo--bar  baz'), equals('foo__bar__baz'));
    });

    test('strips file extensions', () {
      expect(normalizeProjectName('foo.dart'), equals('foo'));
      expect(normalizeProjectName('foo-bar.dart'), equals('foo_bar'));
      expect(normalizeProjectName('foo.bar'), equals('foo'));
    });
  });

  group('globalDartdevOptionsParser', () {
    test('defines expected flags', () {
      final parser = globalDartdevOptionsParser();
      expect(parser.options.containsKey('verbose'), isTrue);
      expect(parser.options['verbose']!.abbr, equals('v'));
      expect(parser.options['verbose']!.negatable, isFalse);

      expect(parser.options.containsKey('version'), isTrue);
      expect(parser.options.containsKey('enable-analytics'), isTrue);
      expect(parser.options.containsKey('disable-analytics'), isTrue);
      expect(parser.options.containsKey('suppress-analytics'), isTrue);
    });

    test('hides diagnostics when verbose is false', () {
      final parser = globalDartdevOptionsParser(verbose: false);
      expect(parser.options['diagnostics']!.hide, isTrue);
    });

    test('shows diagnostics when verbose is true', () {
      final parser = globalDartdevOptionsParser(verbose: true);
      expect(parser.options['diagnostics']!.hide, isFalse);
    });
  });
}
