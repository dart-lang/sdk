// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

main() {
  var builder = new path.Builder(style: path.Style.url,
      root: 'http://dartlang.org/root/path');

  test('separator', () {
    expect(builder.separator, '/');
  });

  test('extension', () {
    expect(builder.extension(''), '');
    expect(builder.extension('foo.dart'), '.dart');
    expect(builder.extension('foo.dart.js'), '.js');
    expect(builder.extension('a.b/c'), '');
    expect(builder.extension('a.b/c.d'), '.d');
    expect(builder.extension(r'a.b\c'), r'.b\c');
    expect(builder.extension('foo.dart/'), '.dart');
    expect(builder.extension('foo.dart//'), '.dart');
  });

  test('rootPrefix', () {
    expect(builder.rootPrefix(''), '');
    expect(builder.rootPrefix('a'), '');
    expect(builder.rootPrefix('a/b'), '');
    expect(builder.rootPrefix('http://dartlang.org/a/c'),
        'http://dartlang.org');
    expect(builder.rootPrefix('file:///a/c'), 'file://');
    expect(builder.rootPrefix('/a/c'), '/');
    expect(builder.rootPrefix('http://dartlang.org/'), 'http://dartlang.org');
    expect(builder.rootPrefix('file:///'), 'file://');
    expect(builder.rootPrefix('http://dartlang.org'), 'http://dartlang.org');
    expect(builder.rootPrefix('file://'), 'file://');
    expect(builder.rootPrefix('/'), '/');
  });

  test('dirname', () {
    expect(builder.dirname(''), '.');
    expect(builder.dirname('a'), '.');
    expect(builder.dirname('a/b'), 'a');
    expect(builder.dirname('a/b/c'), 'a/b');
    expect(builder.dirname('a/b.c'), 'a');
    expect(builder.dirname('a/'), '.');
    expect(builder.dirname('a/.'), 'a');
    expect(builder.dirname(r'a\b/c'), r'a\b');
    expect(builder.dirname('http://dartlang.org/a'), 'http://dartlang.org');
    expect(builder.dirname('file:///a'), 'file://');
    expect(builder.dirname('/a'), '/');
    expect(builder.dirname('http://dartlang.org///a'), 'http://dartlang.org');
    expect(builder.dirname('file://///a'), 'file://');
    expect(builder.dirname('///a'), '/');
    expect(builder.dirname('http://dartlang.org/'), 'http://dartlang.org');
    expect(builder.dirname('http://dartlang.org'), 'http://dartlang.org');
    expect(builder.dirname('file:///'), 'file://');
    expect(builder.dirname('file://'), 'file://');
    expect(builder.dirname('/'), '/');
    expect(builder.dirname('http://dartlang.org///'), 'http://dartlang.org');
    expect(builder.dirname('file://///'), 'file://');
    expect(builder.dirname('///'), '/');
    expect(builder.dirname('a/b/'), 'a');
    expect(builder.dirname(r'a/b\c'), 'a');
    expect(builder.dirname('a//'), '.');
    expect(builder.dirname('a/b//'), 'a');
    expect(builder.dirname('a//b'), 'a');
  });

  test('basename', () {
    expect(builder.basename(''), '');
    expect(builder.basename('a'), 'a');
    expect(builder.basename('a/b'), 'b');
    expect(builder.basename('a/b/c'), 'c');
    expect(builder.basename('a/b.c'), 'b.c');
    expect(builder.basename('a/'), 'a');
    expect(builder.basename('a/.'), '.');
    expect(builder.basename(r'a\b/c'), 'c');
    expect(builder.basename('http://dartlang.org/a'), 'a');
    expect(builder.basename('file:///a'), 'a');
    expect(builder.basename('/a'), 'a');
    expect(builder.basename('http://dartlang.org/'), 'http://dartlang.org');
    expect(builder.basename('http://dartlang.org'), 'http://dartlang.org');
    expect(builder.basename('file:///'), 'file://');
    expect(builder.basename('file://'), 'file://');
    expect(builder.basename('/'), '/');
    expect(builder.basename('a/b/'), 'b');
    expect(builder.basename(r'a/b\c'), r'b\c');
    expect(builder.basename('a//'), 'a');
    expect(builder.basename('a/b//'), 'b');
    expect(builder.basename('a//b'), 'b');
    expect(builder.basename('a b/c d.e f'), 'c d.e f');
  });

  test('basenameWithoutExtension', () {
    expect(builder.basenameWithoutExtension(''), '');
    expect(builder.basenameWithoutExtension('.'), '.');
    expect(builder.basenameWithoutExtension('..'), '..');
    expect(builder.basenameWithoutExtension('a'), 'a');
    expect(builder.basenameWithoutExtension('a/b'), 'b');
    expect(builder.basenameWithoutExtension('a/b/c'), 'c');
    expect(builder.basenameWithoutExtension('a/b.c'), 'b');
    expect(builder.basenameWithoutExtension('a/'), 'a');
    expect(builder.basenameWithoutExtension('a/.'), '.');
    expect(builder.basenameWithoutExtension(r'a/b\c'), r'b\c');
    expect(builder.basenameWithoutExtension('a/.bashrc'), '.bashrc');
    expect(builder.basenameWithoutExtension('a/b/c.d.e'), 'c.d');
    expect(builder.basenameWithoutExtension('a//'), 'a');
    expect(builder.basenameWithoutExtension('a/b//'), 'b');
    expect(builder.basenameWithoutExtension('a//b'), 'b');
    expect(builder.basenameWithoutExtension('a/b.c/'), 'b');
    expect(builder.basenameWithoutExtension('a/b.c//'), 'b');
    expect(builder.basenameWithoutExtension('a/b c.d e.f g'), 'b c.d e');
  });

  test('isAbsolute', () {
    expect(builder.isAbsolute(''), false);
    expect(builder.isAbsolute('a'), false);
    expect(builder.isAbsolute('a/b'), false);
    expect(builder.isAbsolute('http://dartlang.org/a'), true);
    expect(builder.isAbsolute('file:///a'), true);
    expect(builder.isAbsolute('/a'), true);
    expect(builder.isAbsolute('http://dartlang.org/a/b'), true);
    expect(builder.isAbsolute('file:///a/b'), true);
    expect(builder.isAbsolute('/a/b'), true);
    expect(builder.isAbsolute('http://dartlang.org/'), true);
    expect(builder.isAbsolute('file:///'), true);
    expect(builder.isAbsolute('http://dartlang.org'), true);
    expect(builder.isAbsolute('file://'), true);
    expect(builder.isAbsolute('/'), true);
    expect(builder.isAbsolute('~'), false);
    expect(builder.isAbsolute('.'), false);
    expect(builder.isAbsolute('../a'), false);
    expect(builder.isAbsolute('C:/a'), false);
    expect(builder.isAbsolute(r'C:\a'), false);
    expect(builder.isAbsolute(r'\\a'), false);
  });

  test('isRelative', () {
    expect(builder.isRelative(''), true);
    expect(builder.isRelative('a'), true);
    expect(builder.isRelative('a/b'), true);
    expect(builder.isRelative('http://dartlang.org/a'), false);
    expect(builder.isRelative('file:///a'), false);
    expect(builder.isRelative('/a'), false);
    expect(builder.isRelative('http://dartlang.org/a/b'), false);
    expect(builder.isRelative('file:///a/b'), false);
    expect(builder.isRelative('/a/b'), false);
    expect(builder.isRelative('http://dartlang.org/'), false);
    expect(builder.isRelative('file:///'), false);
    expect(builder.isRelative('http://dartlang.org'), false);
    expect(builder.isRelative('file://'), false);
    expect(builder.isRelative('/'), false);
    expect(builder.isRelative('~'), true);
    expect(builder.isRelative('.'), true);
    expect(builder.isRelative('../a'), true);
    expect(builder.isRelative('C:/a'), true);
    expect(builder.isRelative(r'C:\a'), true);
    expect(builder.isRelative(r'\\a'), true);
  });

  test('isRootRelative', () {
    expect(builder.isRootRelative(''), false);
    expect(builder.isRootRelative('a'), false);
    expect(builder.isRootRelative('a/b'), false);
    expect(builder.isRootRelative('http://dartlang.org/a'), false);
    expect(builder.isRootRelative('file:///a'), false);
    expect(builder.isRootRelative('/a'), true);
    expect(builder.isRootRelative('http://dartlang.org/a/b'), false);
    expect(builder.isRootRelative('file:///a/b'), false);
    expect(builder.isRootRelative('/a/b'), true);
    expect(builder.isRootRelative('http://dartlang.org/'), false);
    expect(builder.isRootRelative('file:///'), false);
    expect(builder.isRootRelative('http://dartlang.org'), false);
    expect(builder.isRootRelative('file://'), false);
    expect(builder.isRootRelative('/'), true);
    expect(builder.isRootRelative('~'), false);
    expect(builder.isRootRelative('.'), false);
    expect(builder.isRootRelative('../a'), false);
    expect(builder.isRootRelative('C:/a'), false);
    expect(builder.isRootRelative(r'C:\a'), false);
    expect(builder.isRootRelative(r'\\a'), false);
  });

  group('join', () {
    test('allows up to eight parts', () {
      expect(builder.join('a'), 'a');
      expect(builder.join('a', 'b'), 'a/b');
      expect(builder.join('a', 'b', 'c'), 'a/b/c');
      expect(builder.join('a', 'b', 'c', 'd'), 'a/b/c/d');
      expect(builder.join('a', 'b', 'c', 'd', 'e'), 'a/b/c/d/e');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f'), 'a/b/c/d/e/f');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f', 'g'), 'a/b/c/d/e/f/g');
      expect(builder.join('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'),
          'a/b/c/d/e/f/g/h');
    });

    test('does not add separator if a part ends in one', () {
      expect(builder.join('a/', 'b', 'c/', 'd'), 'a/b/c/d');
      expect(builder.join('a\\', 'b'), r'a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(builder.join('a', 'http://dartlang.org', 'b', 'c'),
          'http://dartlang.org/b/c');
      expect(builder.join('a', 'file://', 'b', 'c'), 'file:///b/c');
      expect(builder.join('a', '/', 'b', 'c'), '/b/c');
      expect(builder.join('a', '/b', 'http://dartlang.org/c', 'd'),
          'http://dartlang.org/c/d');
      expect(builder.join(
              'a', 'http://google.com/b', 'http://dartlang.org/c', 'd'),
          'http://dartlang.org/c/d');
      expect(builder.join('a', '/b', '/c', 'd'), '/c/d');
      expect(builder.join('a', r'c:\b', 'c', 'd'), r'a/c:\b/c/d');
      expect(builder.join('a', r'\\b', 'c', 'd'), r'a/\\b/c/d');
    });

    test('preserves roots before a root-relative path', () {
      expect(builder.join('http://dartlang.org', 'a', '/b', 'c'),
          'http://dartlang.org/b/c');
      expect(builder.join('file://', 'a', '/b', 'c'), 'file:///b/c');
      expect(builder.join('file://', 'a', '/b', 'c', '/d'), 'file:///d');
    });

    test('ignores trailing nulls', () {
      expect(builder.join('a', null), equals('a'));
      expect(builder.join('a', 'b', 'c', null, null), equals('a/b/c'));
    });

    test('ignores empty strings', () {
      expect(builder.join(''), '');
      expect(builder.join('', ''), '');
      expect(builder.join('', 'a'), 'a');
      expect(builder.join('a', '', 'b', '', '', '', 'c'), 'a/b/c');
      expect(builder.join('a', 'b', ''), 'a/b');
    });

    test('disallows intermediate nulls', () {
      expect(() => builder.join('a', null, 'b'), throwsArgumentError);
      expect(() => builder.join(null, 'a'), throwsArgumentError);
    });

    test('Join does not modify internal ., .., or trailing separators', () {
      expect(builder.join('a/', 'b/c/'), 'a/b/c/');
      expect(builder.join('a/b/./c/..//', 'd/.././..//e/f//'),
             'a/b/./c/..//d/.././..//e/f//');
      expect(builder.join('a/b', 'c/../../../..'), 'a/b/c/../../../..');
      expect(builder.join('a', 'b${builder.separator}'), 'a/b/');
    });
  });

  group('joinAll', () {
    test('allows more than eight parts', () {
      expect(builder.joinAll(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']),
          'a/b/c/d/e/f/g/h/i');
    });

    test('ignores parts before an absolute path', () {
      expect(builder.joinAll(['a', 'http://dartlang.org', 'b', 'c']),
          'http://dartlang.org/b/c');
      expect(builder.joinAll(['a', 'file://', 'b', 'c']), 'file:///b/c');
      expect(builder.joinAll(['a', '/', 'b', 'c']), '/b/c');
      expect(builder.joinAll(['a', '/b', 'http://dartlang.org/c', 'd']),
          'http://dartlang.org/c/d');
      expect(builder.joinAll(
              ['a', 'http://google.com/b', 'http://dartlang.org/c', 'd']),
          'http://dartlang.org/c/d');
      expect(builder.joinAll(['a', '/b', '/c', 'd']), '/c/d');
      expect(builder.joinAll(['a', r'c:\b', 'c', 'd']), r'a/c:\b/c/d');
      expect(builder.joinAll(['a', r'\\b', 'c', 'd']), r'a/\\b/c/d');
    });

    test('preserves roots before a root-relative path', () {
      expect(builder.joinAll(['http://dartlang.org', 'a', '/b', 'c']),
          'http://dartlang.org/b/c');
      expect(builder.joinAll(['file://', 'a', '/b', 'c']), 'file:///b/c');
      expect(builder.joinAll(['file://', 'a', '/b', 'c', '/d']), 'file:///d');
    });
  });

  group('split', () {
    test('simple cases', () {
      expect(builder.split(''), []);
      expect(builder.split('.'), ['.']);
      expect(builder.split('..'), ['..']);
      expect(builder.split('foo'), equals(['foo']));
      expect(builder.split('foo/bar.txt'), equals(['foo', 'bar.txt']));
      expect(builder.split('foo/bar/baz'), equals(['foo', 'bar', 'baz']));
      expect(builder.split('foo/../bar/./baz'),
          equals(['foo', '..', 'bar', '.', 'baz']));
      expect(builder.split('foo//bar///baz'), equals(['foo', 'bar', 'baz']));
      expect(builder.split('foo/\\/baz'), equals(['foo', '\\', 'baz']));
      expect(builder.split('.'), equals(['.']));
      expect(builder.split(''), equals([]));
      expect(builder.split('foo/'), equals(['foo']));
      expect(builder.split('http://dartlang.org//'),
          equals(['http://dartlang.org']));
      expect(builder.split('file:////'), equals(['file://']));
      expect(builder.split('//'), equals(['/']));
    });

    test('includes the root for absolute paths', () {
      expect(builder.split('http://dartlang.org/foo/bar/baz'),
          equals(['http://dartlang.org', 'foo', 'bar', 'baz']));
      expect(builder.split('file:///foo/bar/baz'),
          equals(['file://', 'foo', 'bar', 'baz']));
      expect(builder.split('/foo/bar/baz'), equals(['/', 'foo', 'bar', 'baz']));
      expect(builder.split('http://dartlang.org/'),
          equals(['http://dartlang.org']));
      expect(builder.split('http://dartlang.org'),
          equals(['http://dartlang.org']));
      expect(builder.split('file:///'), equals(['file://']));
      expect(builder.split('file://'), equals(['file://']));
      expect(builder.split('/'), equals(['/']));
    });
  });

  group('normalize', () {
    test('simple cases', () {
      expect(builder.normalize(''), '.');
      expect(builder.normalize('.'), '.');
      expect(builder.normalize('..'), '..');
      expect(builder.normalize('a'), 'a');
      expect(builder.normalize('http://dartlang.org/'), 'http://dartlang.org');
      expect(builder.normalize('http://dartlang.org'), 'http://dartlang.org');
      expect(builder.normalize('file://'), 'file://');
      expect(builder.normalize('file:///'), 'file://');
      expect(builder.normalize('/'), '/');
      expect(builder.normalize(r'\'), r'\');
      expect(builder.normalize('C:/'), 'C:');
      expect(builder.normalize(r'C:\'), r'C:\');
      expect(builder.normalize(r'\\'), r'\\');
      expect(builder.normalize('a/./\xc5\u0bf8-;\u{1f085}\u{00}/c/d/../'),
             'a/\xc5\u0bf8-;\u{1f085}\u{00}/c');
    });

    test('collapses redundant separators', () {
      expect(builder.normalize(r'a/b/c'), r'a/b/c');
      expect(builder.normalize(r'a//b///c////d'), r'a/b/c/d');
    });

    test('does not collapse separators for other platform', () {
      expect(builder.normalize(r'a\\b\\\c'), r'a\\b\\\c');
    });

    test('eliminates "." parts', () {
      expect(builder.normalize('./'), '.');
      expect(builder.normalize('http://dartlang.org/.'), 'http://dartlang.org');
      expect(builder.normalize('file:///.'), 'file://');
      expect(builder.normalize('/.'), '/');
      expect(builder.normalize('http://dartlang.org/./'),
          'http://dartlang.org');
      expect(builder.normalize('file:///./'), 'file://');
      expect(builder.normalize('/./'), '/');
      expect(builder.normalize('./.'), '.');
      expect(builder.normalize('a/./b'), 'a/b');
      expect(builder.normalize('a/.b/c'), 'a/.b/c');
      expect(builder.normalize('a/././b/./c'), 'a/b/c');
      expect(builder.normalize('././a'), 'a');
      expect(builder.normalize('a/./.'), 'a');
    });

    test('eliminates ".." parts', () {
      expect(builder.normalize('..'), '..');
      expect(builder.normalize('../'), '..');
      expect(builder.normalize('../../..'), '../../..');
      expect(builder.normalize('../../../'), '../../..');
      expect(builder.normalize('http://dartlang.org/..'),
          'http://dartlang.org');
      expect(builder.normalize('file:///..'), 'file://');
      expect(builder.normalize('/..'), '/');
      expect(builder.normalize('http://dartlang.org/../../..'),
          'http://dartlang.org');
      expect(builder.normalize('file:///../../..'), 'file://');
      expect(builder.normalize('/../../..'), '/');
      expect(builder.normalize('http://dartlang.org/../../../a'),
          'http://dartlang.org/a');
      expect(builder.normalize('file:///../../../a'), 'file:///a');
      expect(builder.normalize('/../../../a'), '/a');
      expect(builder.normalize('c:/..'), '.');
      expect(builder.normalize('A:/../../..'), '../..');
      expect(builder.normalize('a/..'), '.');
      expect(builder.normalize('a/b/..'), 'a');
      expect(builder.normalize('a/../b'), 'b');
      expect(builder.normalize('a/./../b'), 'b');
      expect(builder.normalize('a/b/c/../../d/e/..'), 'a/d');
      expect(builder.normalize('a/b/../../../../c'), '../../c');
      expect(builder.normalize('z/a/b/../../..\../c'), 'z/..\../c');
      expect(builder.normalize('a/b\c/../d'), 'a/d');
    });

    test('does not walk before root on absolute paths', () {
      expect(builder.normalize('..'), '..');
      expect(builder.normalize('../'), '..');
      expect(builder.normalize('http://dartlang.org/..'),
          'http://dartlang.org');
      expect(builder.normalize('http://dartlang.org/../a'),
             'http://dartlang.org/a');
      expect(builder.normalize('file:///..'), 'file://');
      expect(builder.normalize('file:///../a'), 'file:///a');
      expect(builder.normalize('/..'), '/');
      expect(builder.normalize('a/..'), '.');
      expect(builder.normalize('../a'), '../a');
      expect(builder.normalize('/../a'), '/a');
      expect(builder.normalize('c:/../a'), 'a');
      expect(builder.normalize('/../a'), '/a');
      expect(builder.normalize('a/b/..'), 'a');
      expect(builder.normalize('../a/b/..'), '../a');
      expect(builder.normalize('a/../b'), 'b');
      expect(builder.normalize('a/./../b'), 'b');
      expect(builder.normalize('a/b/c/../../d/e/..'), 'a/d');
      expect(builder.normalize('a/b/../../../../c'), '../../c');
      expect(builder.normalize('a/b/c/../../..d/./.e/f././'), 'a/..d/.e/f.');
    });

    test('removes trailing separators', () {
      expect(builder.normalize('./'), '.');
      expect(builder.normalize('.//'), '.');
      expect(builder.normalize('a/'), 'a');
      expect(builder.normalize('a/b/'), 'a/b');
      expect(builder.normalize(r'a/b\'), r'a/b\');
      expect(builder.normalize('a/b///'), 'a/b');
    });
  });

  group('relative', () {
    group('from absolute root', () {
      test('given absolute path in root', () {
        expect(builder.relative('http://dartlang.org'), '../..');
        expect(builder.relative('http://dartlang.org/'), '../..');
        expect(builder.relative('/'), '../..');
        expect(builder.relative('http://dartlang.org/root'), '..');
        expect(builder.relative('/root'), '..');
        expect(builder.relative('http://dartlang.org/root/path'), '.');
        expect(builder.relative('/root/path'), '.');
        expect(builder.relative('http://dartlang.org/root/path/a'), 'a');
        expect(builder.relative('/root/path/a'), 'a');
        expect(builder.relative('http://dartlang.org/root/path/a/b.txt'),
            'a/b.txt');
        expect(builder.relative('/root/path/a/b.txt'), 'a/b.txt');
        expect(builder.relative('http://dartlang.org/root/a/b.txt'),
            '../a/b.txt');
        expect(builder.relative('/root/a/b.txt'), '../a/b.txt');
      });

      test('given absolute path outside of root', () {
        expect(builder.relative('http://dartlang.org/a/b'), '../../a/b');
        expect(builder.relative('/a/b'), '../../a/b');
        expect(builder.relative('http://dartlang.org/root/path/a'), 'a');
        expect(builder.relative('/root/path/a'), 'a');
        expect(builder.relative('http://dartlang.org/root/path/a/b.txt'),
            'a/b.txt');
        expect(builder.relative('http://dartlang.org/root/path/a/b.txt'),
            'a/b.txt');
        expect(builder.relative('http://dartlang.org/root/a/b.txt'),
            '../a/b.txt');
      });

      test('given absolute path with different hostname/protocol', () {
        expect(builder.relative(r'http://google.com/a/b'),
            r'http://google.com/a/b');
        expect(builder.relative(r'file:///a/b'),
            r'file:///a/b');
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(builder.relative(''), '.');
        expect(builder.relative('.'), '.');
        expect(builder.relative('a'), 'a');
        expect(builder.relative('a/b.txt'), 'a/b.txt');
        expect(builder.relative('../a/b.txt'), '../a/b.txt');
        expect(builder.relative('a/./b/../c.txt'), 'a/c.txt');
      });

      // Regression
      test('from root-only path', () {
        expect(builder.relative('http://dartlang.org',
                from: 'http://dartlang.org'),
            '.');
        expect(builder.relative('http://dartlang.org/root/path',
                from: 'http://dartlang.org'),
            'root/path');
      });
    });

    group('from relative root', () {
      var r = new path.Builder(style: path.Style.url, root: 'foo/bar');

      test('given absolute path', () {
        expect(r.relative('http://google.com/'), equals('http://google.com'));
        expect(r.relative('http://google.com'), equals('http://google.com'));
        expect(r.relative('file:///'), equals('file://'));
        expect(r.relative('file://'), equals('file://'));
        expect(r.relative('/'), equals('/'));
        expect(r.relative('/a/b'), equals('/a/b'));
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative('a/b.txt'), 'a/b.txt');
        expect(r.relative('../a/b.txt'), '../a/b.txt');
        expect(r.relative('a/./b/../c.txt'), 'a/c.txt');
      });
    });

    group('from root-relative root', () {
      var r = new path.Builder(style: path.Style.url, root: '/foo/bar');

      test('given absolute path', () {
        expect(r.relative('http://google.com/'), equals('http://google.com'));
        expect(r.relative('http://google.com'), equals('http://google.com'));
        expect(r.relative('file:///'), equals('file://'));
        expect(r.relative('file://'), equals('file://'));
        expect(r.relative('/'), equals('../..'));
        expect(r.relative('/a/b'), equals('../../a/b'));
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative('a/b.txt'), 'a/b.txt');
        expect(r.relative('../a/b.txt'), '../a/b.txt');
        expect(r.relative('a/./b/../c.txt'), 'a/c.txt');
      });
    });

    test('from a root with extension', () {
      var r = new path.Builder(style: path.Style.url, root: '/dir.ext');
      expect(r.relative('/dir.ext/file'), 'file');
    });

    test('with a root parameter', () {
      expect(builder.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(
          builder.relative('/foo/bar/baz', from: 'http://dartlang.org/foo/bar'),
          equals('baz'));
      expect(
          builder.relative('http://dartlang.org/foo/bar/baz', from: '/foo/bar'),
          equals('baz'));
      expect(builder.relative('http://dartlang.org/foo/bar/baz',
              from: 'file:///foo/bar'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(builder.relative('http://dartlang.org/foo/bar/baz',
          from: 'http://dartlang.org/foo/bar'), equals('baz'));
      expect(
          builder.relative('/foo/bar/baz', from: 'file:///foo/bar'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(
          builder.relative('file:///foo/bar/baz', from: '/foo/bar'),
          equals('file:///foo/bar/baz'));

      expect(builder.relative('..', from: '/foo/bar'), equals('../../root'));
      expect(builder.relative('..', from: 'http://dartlang.org/foo/bar'),
          equals('../../root'));
      expect(builder.relative('..', from: 'file:///foo/bar'),
          equals('http://dartlang.org/root'));
      expect(builder.relative('..', from: '/foo/bar'), equals('../../root'));

      expect(builder.relative('http://dartlang.org/foo/bar/baz',
              from: 'foo/bar'),
          equals('../../../../foo/bar/baz'));
      expect(builder.relative('file:///foo/bar/baz', from: 'foo/bar'),
          equals('file:///foo/bar/baz'));
      expect(builder.relative('/foo/bar/baz', from: 'foo/bar'),
          equals('../../../../foo/bar/baz'));

      expect(builder.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('with a root parameter and a relative root', () {
      var r = new path.Builder(style: path.Style.url, root: 'relative/root');
      expect(r.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(
          r.relative('/foo/bar/baz', from: 'http://dartlang.org/foo/bar'),
          equals('/foo/bar/baz'));
      expect(
          r.relative('http://dartlang.org/foo/bar/baz', from: '/foo/bar'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(r.relative('http://dartlang.org/foo/bar/baz',
              from: 'file:///foo/bar'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(r.relative('http://dartlang.org/foo/bar/baz',
          from: 'http://dartlang.org/foo/bar'), equals('baz'));

      expect(r.relative('http://dartlang.org/foo/bar/baz', from: 'foo/bar'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(r.relative('file:///foo/bar/baz', from: 'foo/bar'),
          equals('file:///foo/bar/baz'));
      expect(r.relative('/foo/bar/baz', from: 'foo/bar'),
          equals('/foo/bar/baz'));

      expect(r.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('from a . root', () {
      var r = new path.Builder(style: path.Style.url, root: '.');
      expect(r.relative('http://dartlang.org/foo/bar/baz'),
          equals('http://dartlang.org/foo/bar/baz'));
      expect(r.relative('file:///foo/bar/baz'), equals('file:///foo/bar/baz'));
      expect(r.relative('/foo/bar/baz'), equals('/foo/bar/baz'));
      expect(r.relative('foo/bar/baz'), equals('foo/bar/baz'));
    });
  });

  group('resolve', () {
    test('allows up to seven parts', () {
      expect(builder.resolve('a'), 'http://dartlang.org/root/path/a');
      expect(builder.resolve('a', 'b'), 'http://dartlang.org/root/path/a/b');
      expect(builder.resolve('a', 'b', 'c'),
          'http://dartlang.org/root/path/a/b/c');
      expect(builder.resolve('a', 'b', 'c', 'd'),
          'http://dartlang.org/root/path/a/b/c/d');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e'),
          'http://dartlang.org/root/path/a/b/c/d/e');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e', 'f'),
          'http://dartlang.org/root/path/a/b/c/d/e/f');
      expect(builder.resolve('a', 'b', 'c', 'd', 'e', 'f', 'g'),
          'http://dartlang.org/root/path/a/b/c/d/e/f/g');
    });

    test('does not add separator if a part ends in one', () {
      expect(builder.resolve('a/', 'b', 'c/', 'd'),
          'http://dartlang.org/root/path/a/b/c/d');
      expect(builder.resolve(r'a\', 'b'),
          r'http://dartlang.org/root/path/a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(builder.resolve('a', '/b', '/c', 'd'), 'http://dartlang.org/c/d');
      expect(builder.resolve('a', '/b', 'file:///c', 'd'), 'file:///c/d');
      expect(builder.resolve('a', r'c:\b', 'c', 'd'),
          r'http://dartlang.org/root/path/a/c:\b/c/d');
      expect(builder.resolve('a', r'\\b', 'c', 'd'),
          r'http://dartlang.org/root/path/a/\\b/c/d');
    });
  });

  test('withoutExtension', () {
    expect(builder.withoutExtension(''), '');
    expect(builder.withoutExtension('a'), 'a');
    expect(builder.withoutExtension('.a'), '.a');
    expect(builder.withoutExtension('a.b'), 'a');
    expect(builder.withoutExtension('a/b.c'), 'a/b');
    expect(builder.withoutExtension('a/b.c.d'), 'a/b.c');
    expect(builder.withoutExtension('a/'), 'a/');
    expect(builder.withoutExtension('a/b/'), 'a/b/');
    expect(builder.withoutExtension('a/.'), 'a/.');
    expect(builder.withoutExtension('a/.b'), 'a/.b');
    expect(builder.withoutExtension('a.b/c'), 'a.b/c');
    expect(builder.withoutExtension(r'a.b\c'), r'a');
    expect(builder.withoutExtension(r'a/b\c'), r'a/b\c');
    expect(builder.withoutExtension(r'a/b\c.d'), r'a/b\c');
    expect(builder.withoutExtension('a/b.c/'), 'a/b/');
    expect(builder.withoutExtension('a/b.c//'), 'a/b//');
  });


  test('fromUri', () {
    expect(builder.fromUri(Uri.parse('http://dartlang.org/path/to/foo')),
        'http://dartlang.org/path/to/foo');
    expect(builder.fromUri(Uri.parse('http://dartlang.org/path/to/foo/')),
        'http://dartlang.org/path/to/foo/');
    expect(builder.fromUri(Uri.parse('file:///path/to/foo')),
        'file:///path/to/foo');
    expect(builder.fromUri(Uri.parse('foo/bar')), 'foo/bar');
    expect(builder.fromUri(Uri.parse('http://dartlang.org/path/to/foo%23bar')),
        'http://dartlang.org/path/to/foo%23bar');
  });

  test('toUri', () {
    expect(builder.toUri('http://dartlang.org/path/to/foo'),
        Uri.parse('http://dartlang.org/path/to/foo'));
    expect(builder.toUri('http://dartlang.org/path/to/foo/'),
        Uri.parse('http://dartlang.org/path/to/foo/'));
    expect(builder.toUri('file:///path/to/foo'),
        Uri.parse('file:///path/to/foo'));
    expect(builder.toUri('foo/bar'), Uri.parse('foo/bar'));
    expect(builder.toUri('http://dartlang.org/path/to/foo%23bar'),
        Uri.parse('http://dartlang.org/path/to/foo%23bar'));
  });
}
