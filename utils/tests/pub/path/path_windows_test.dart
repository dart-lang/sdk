// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path_test;

import 'dart:io' as io;

import '../../../../pkg/unittest/lib/unittest.dart';
import '../../../pub/path.dart' as path;

main() {
  var builder = new path.Builder(style: path.Style.windows,
                                 root: r'C:\root\path');

  if (new path.Builder().style == path.Style.windows) {
    group('absolute', () {
      expect(path.absolute(r'a\b.txt'), path.join(path.current, r'a\b.txt'));
      expect(path.absolute(r'C:\a\b.txt'), r'C:\a\b.txt');
      expect(path.absolute(r'\\a\b.txt'), r'\\a\b.txt');
    });
  }

  group('separator', () {
    expect(builder.separator, '\\');
  });

  test('extension', () {
    expect(builder.extension(''), '');
    expect(builder.extension('foo.dart'), '.dart');
    expect(builder.extension('foo.dart.js'), '.js');
    expect(builder.extension(r'a.b\c'), '');
    expect(builder.extension('a.b/c.d'), '.d');
    expect(builder.extension(r'~\.bashrc'), '');
    expect(builder.extension(r'a.b/c'), r'');
  });

  test('filename', () {
    expect(builder.filename(r''), '');
    expect(builder.filename(r'a'), 'a');
    expect(builder.filename(r'a\b'), 'b');
    expect(builder.filename(r'a\b\c'), 'c');
    expect(builder.filename(r'a\b.c'), 'b.c');
    expect(builder.filename(r'a\'), '');
    expect(builder.filename(r'a/'), '');
    expect(builder.filename(r'a\.'), '.');
    expect(builder.filename(r'a\b/c'), r'c');
  });

  test('filenameWithoutExtension', () {
    expect(builder.filenameWithoutExtension(''), '');
    expect(builder.filenameWithoutExtension('a'), 'a');
    expect(builder.filenameWithoutExtension(r'a\b'), 'b');
    expect(builder.filenameWithoutExtension(r'a\b\c'), 'c');
    expect(builder.filenameWithoutExtension(r'a\b.c'), 'b');
    expect(builder.filenameWithoutExtension(r'a\'), '');
    expect(builder.filenameWithoutExtension(r'a\.'), '.');
    expect(builder.filenameWithoutExtension(r'a\b/c'), r'c');
    expect(builder.filenameWithoutExtension(r'a\.bashrc'), '.bashrc');
    expect(builder.filenameWithoutExtension(r'a\b\c.d.e'), 'c.d');
  });

  test('isAbsolute', () {
    expect(builder.isAbsolute(''), false);
    expect(builder.isAbsolute('a'), false);
    expect(builder.isAbsolute(r'a\b'), false);
    expect(builder.isAbsolute(r'\a'), false);
    expect(builder.isAbsolute(r'\a\b'), false);
    expect(builder.isAbsolute('~'), false);
    expect(builder.isAbsolute('.'), false);
    expect(builder.isAbsolute(r'..\a'), false);
    expect(builder.isAbsolute(r'a:/a\b'), true);
    expect(builder.isAbsolute(r'D:/a/b'), true);
    expect(builder.isAbsolute(r'c:\'), true);
    expect(builder.isAbsolute(r'B:\'), true);
    expect(builder.isAbsolute(r'c:\a'), true);
    expect(builder.isAbsolute(r'C:\a'), true);
    expect(builder.isAbsolute(r'\\a'), true);
    expect(builder.isAbsolute(r'\\'), true);
  });

  test('isRelative', () {
    expect(builder.isRelative(''), true);
    expect(builder.isRelative('a'), true);
    expect(builder.isRelative(r'a\b'), true);
    expect(builder.isRelative(r'\a'), true);
    expect(builder.isRelative(r'\a\b'), true);
    expect(builder.isRelative('~'), true);
    expect(builder.isRelative('.'), true);
    expect(builder.isRelative(r'..\a'), true);
    expect(builder.isRelative(r'a:/a\b'), false);
    expect(builder.isRelative(r'D:/a/b'), false);
    expect(builder.isRelative(r'c:\'), false);
    expect(builder.isRelative(r'B:\'), false);
    expect(builder.isRelative(r'c:\a'), false);
    expect(builder.isRelative(r'C:\a'), false);
    expect(builder.isRelative(r'\\a'), false);
    expect(builder.isRelative(r'\\'), false);
  });

  group('join', () {
    test('allows up to eight parts', () {
      expect(builder.join('a'), 'a');
      expect(builder.join('a', 'b'), r'a\b');
      expect(builder.join('a', 'b', 'c'), r'a\b\c');
      expect(builder.join('a', 'b', 'c', 'd'), r'a\b\c\d');
      expect(builder.join('a', 'b', 'c', 'd', 'e'), r'a\b\c\d\e');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f'), r'a\b\c\d\e\f');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f', 'g'), r'a\b\c\d\e\f\g');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'),
          r'a\b\c\d\e\f\g\h');
    });

    test('does not add separator if a part ends or begins in one', () {
      expect(builder.join(r'a\', 'b', r'c\', 'd'), r'a\b\c\d');
      expect(builder.join('a/', 'b'), r'a/b');
      expect(builder.join('a', '/b'), 'a/b');
      expect(builder.join('a', r'\b'), r'a\b');
    });

    test('ignores parts before an absolute path', () {
      expect(builder.join('a', '/b', '/c', 'd'), r'a/b/c\d');
      expect(builder.join('a', r'c:\b', 'c', 'd'), r'c:\b\c\d');
      expect(builder.join('a', r'\\b', r'\\c', 'd'), r'\\c\d');
    });
  });

  group('normalize', () {
    test('simple cases', () {
      expect(builder.normalize(''), '');
      expect(builder.normalize('.'), '.');
      expect(builder.normalize('..'), '..');
      expect(builder.normalize('a'), 'a');
      expect(builder.normalize('C:/'), r'C:/');
      expect(builder.normalize(r'C:\'), r'C:\');
      expect(builder.normalize(r'\\'), r'\\');
    });

    test('collapses redundant separators', () {
      expect(builder.normalize(r'a\b\c'), r'a\b\c');
      expect(builder.normalize(r'a\\b\\\c\\\\d'), r'a\b\c\d');
    });

    test('eliminates "." parts', () {
      expect(builder.normalize(r'.\'), '.');
      expect(builder.normalize(r'c:\.'), r'c:\');
      expect(builder.normalize(r'B:\.\'), r'B:\');
      expect(builder.normalize(r'\\.'), r'\\');
      expect(builder.normalize(r'\\.\'), r'\\');
      expect(builder.normalize(r'.\.'), '.');
      expect(builder.normalize(r'a\.\b'), r'a\b');
      expect(builder.normalize(r'a\.b\c'), r'a\.b\c');
      expect(builder.normalize(r'a\./.\b\.\c'), r'a\b\c');
      expect(builder.normalize(r'.\./a'), 'a');
      expect(builder.normalize(r'a/.\.'), 'a');
    });

    test('eliminates ".." parts', () {
      expect(builder.normalize('..'), '..');
      expect(builder.normalize(r'..\'), '..');
      expect(builder.normalize(r'..\..\..'), r'..\..\..');
      expect(builder.normalize(r'../..\..\'), r'..\..\..');
      // TODO(rnystrom): Is this how Python handles absolute paths on Windows?
      expect(builder.normalize(r'\\..'), r'\\');
      expect(builder.normalize(r'\\..\..\..'), r'\\');
      expect(builder.normalize(r'\\..\../..\a'), r'\\a');
      expect(builder.normalize(r'c:\..'), r'c:\');
      expect(builder.normalize(r'A:/..\..\..'), r'A:/');
      expect(builder.normalize(r'b:\..\..\..\a'), r'b:\a');
      expect(builder.normalize(r'a\..'), '.');
      expect(builder.normalize(r'a\b\..'), 'a');
      expect(builder.normalize(r'a\..\b'), 'b');
      expect(builder.normalize(r'a\.\..\b'), 'b');
      expect(builder.normalize(r'a\b\c\..\..\d\e\..'), r'a\d');
      expect(builder.normalize(r'a\b\..\..\..\..\c'), r'..\..\c');
    });

    test('removes trailing separators', () {
      expect(builder.normalize(r'.\'), '.');
      expect(builder.normalize(r'.\\'), '.');
      expect(builder.normalize(r'a/'), 'a');
      expect(builder.normalize(r'a\b\'), r'a\b');
      expect(builder.normalize(r'a\b\\\'), r'a\b');
    });

    test('normalizes separators', () {
      expect(builder.normalize(r'a/b\c'), r'a\b\c');
    });
  });

  group('relative', () {
    group('from absolute root', () {
      test('given absolute path in root', () {
        expect(builder.relative(r'C:\'), r'..\..');
        expect(builder.relative(r'C:\root'), '..');
        expect(builder.relative(r'C:\root\path'), '.');
        expect(builder.relative(r'C:\root\path\a'), 'a');
        expect(builder.relative(r'C:\root\path\a\b.txt'), r'a\b.txt');
        expect(builder.relative(r'C:\root\a\b.txt'), r'..\a\b.txt');
      });

      test('given absolute path outside of root', () {
        expect(builder.relative(r'C:\a\b'), r'..\..\a\b');
        expect(builder.relative(r'C:\root\path\a'), 'a');
        expect(builder.relative(r'C:\root\path\a\b.txt'), r'a\b.txt');
        expect(builder.relative(r'C:\root\a\b.txt'), r'..\a\b.txt');
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(builder.relative(''), '.');
        expect(builder.relative('.'), '.');
        expect(builder.relative('a'), 'a');
        expect(builder.relative(r'a\b.txt'), r'a\b.txt');
        expect(builder.relative(r'..\a\b.txt'), r'..\a\b.txt');
        expect(builder.relative(r'a\.\b\..\c.txt'), r'a\c.txt');
      });
    });

    group('from relative root', () {
      var r = new path.Builder(style: path.Style.windows, root: r'foo\bar');

      // These tests rely on the current working directory, so don't do the
      // right thing if you run them on the wrong platform.
      if (io.Platform.operatingSystem == 'windows') {
        test('given absolute path', () {
          var b = new path.Builder(style: path.Style.windows);
          expect(r.relative(r'C:\'), b.join(b.relative(r'C:\'), r'..\..'));
          expect(r.relative(r'C:\a\b'),
              b.join(b.relative(r'C:\'), r'..\..\a\b'));
        });
      }

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative(r'a\b.txt'), r'a\b.txt');
        expect(r.relative(r'..\a/b.txt'), r'..\a\b.txt');
        expect(r.relative(r'a\./b\../c.txt'), r'a\c.txt');
      });
    });

    test('given absolute with differnt root prefix', () {
      expect(builder.relative(r'D:\a\b'), r'D:\a\b');
      expect(builder.relative(r'\\a\b'), r'\\a\b');
    });
  });

  group('resolve', () {
    test('allows up to seven parts', () {
      expect(builder.resolve('a'), r'C:\root\path\a');
      expect(builder.resolve('a', 'b'), r'C:\root\path\a\b');
      expect(builder.resolve('a', 'b', 'c'), r'C:\root\path\a\b\c');
      expect(builder.resolve('a', 'b', 'c', 'd'), r'C:\root\path\a\b\c\d');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e'),
          r'C:\root\path\a\b\c\d\e');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e', 'f'),
          r'C:\root\path\a\b\c\d\e\f');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e', 'f', 'g'),
          r'C:\root\path\a\b\c\d\e\f\g');
    });

    test('does not add separator if a part ends in one', () {
      expect(builder.resolve(r'a\', 'b', r'c\', 'd'), r'C:\root\path\a\b\c\d');
      expect(builder.resolve('a/', 'b'), r'C:\root\path\a/b');
    });

    test('ignores parts before an absolute path', () {
      expect(builder.resolve('a', '/b', '/c', 'd'), r'C:\root\path\a/b/c\d');
      expect(builder.resolve('a', r'c:\b', 'c', 'd'), r'c:\b\c\d');
      expect(builder.resolve('a', r'\\b', r'\\c', 'd'), r'\\c\d');
    });
  });

  test('withoutExtension', () {
    expect(builder.withoutExtension(''), '');
    expect(builder.withoutExtension('a'), 'a');
    expect(builder.withoutExtension('.a'), '.a');
    expect(builder.withoutExtension('a.b'), 'a');
    expect(builder.withoutExtension(r'a\b.c'), r'a\b');
    expect(builder.withoutExtension(r'a\b.c.d'), r'a\b.c');
    expect(builder.withoutExtension(r'a\'), r'a\');
    expect(builder.withoutExtension(r'a\b\'), r'a\b\');
    expect(builder.withoutExtension(r'a\.'), r'a\.');
    expect(builder.withoutExtension(r'a\.b'), r'a\.b');
    expect(builder.withoutExtension(r'a.b\c'), r'a.b\c');
    expect(builder.withoutExtension(r'a\b/c'), r'a\b/c');
    expect(builder.withoutExtension(r'a\b/c.d'), r'a\b/c');
  });
}
