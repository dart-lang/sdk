// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test the Path class in dart:io.

#import("dart:io");

void main() {
  testBaseFunctions();
  testCanonicalize();
  testJoinAppend();
  testRelativeTo();
}

void testBaseFunctions() {
  testGetters(new Path("/foo/bar/fisk.hest"),
              ['/foo/bar', 'fisk.hest', 'fisk', 'hest'],
              'absolute canonical');
  testGetters(new Path(''),
              ['', '', '', ''],
              'empty');
  // This corner case leaves a trailing slash for the root.
  testGetters(new Path('/'),
              ['/', '', '', ''],
              'absolute canonical trailing');
  testGetters(new Path('.'),
              ['', '.', '.', ''],
              'canonical');
  testGetters(new Path('..'),
              ['', '..', '..', ''],
              'canonical');
  testGetters(new Path('/ab,;- .c.d'),
              ['/', 'ab,;- .c.d', 'ab,;- .c', 'd'],
              'absolute canonical');

  // Canonical and non-canonical cases
  testGetters(new Path("a/b/../c/./d/e"),
              ['a/b/../c/./d', 'e', 'e', ''],
              '');
  testGetters(new Path("a./b../..c/.d/e"),
              ['a./b../..c/.d', 'e', 'e', ''],
              'canonical');
  // .. is allowed at the beginning of a canonical relative path.
  testGetters(new Path("../../a/b/c/d/"),
              ['../../a/b/c/d', '', '', ''],
              'canonical trailing');

  // '.' at the end of a path is not considered an extension.
  testGetters(new Path("a/b.c/."),
              ['a/b.c', '.', '.', ''],
              '');
  // '..' at the end of a path is not considered an extension.
  testGetters(new Path("a/bc/../.."),
              ['a/bc/..', '..', '..', ''],
              '');

  // Test the special path cleaning operations on the Windows platform.
  if (Platform.operatingSystem == 'windows') {
    testGetters(new Path.fromNative(r"c:\foo\bar\fisk.hest"),
                ['/c:/foo/bar', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path.fromNative("\\foo\\bar\\"),
                ['/foo/bar', '', '', ''],
                'absolute canonical trailing');
    testGetters(new Path.fromNative("\\foo\\bar\\hest"),
                ['/foo/bar', 'hest', 'hest', ''],
                'absolute canonical');
    testGetters(new Path.fromNative(r"foo/bar\hest/.fisk"),
                ['foo/bar/hest', '.fisk', '', 'fisk'],
                'canonical');
    testGetters(new Path.fromNative(r"foo//bar\\hest/\/.fisk."),
                ['foo//bar//hest', '.fisk.', '.fisk', ''],
                '');
  } else {
    // Make sure that backslashes are uninterpreted on other platforms.
    testGetters(new Path.fromNative(r"/foo\bar/bif/fisk.hest"),
                [r'/foo\bar/bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path.fromNative(r"//foo\bar///bif////fisk.hest"),
                [r'//foo\bar///bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute');
    testGetters(new Path.fromNative(r"/foo\ bar/bif/gule\ fisk.hest"),
                [r'/foo\ bar/bif', r'gule\ fisk.hest', r'gule\ fisk', 'hest'],
                'absolute canonical');
  }
}


void testGetters(Path path, List components, String properties) {
  final int DIRNAME = 0;
  final int FILENAME = 1;
  final int FILENAME_NO_EXTENSION = 2;
  final int EXTENSION = 3;
  Expect.equals(components[DIRNAME], path.directoryPath.toString());
  Expect.equals(components[FILENAME], path.filename);
  Expect.equals(components[FILENAME_NO_EXTENSION],
                path.filenameWithoutExtension);
  Expect.equals(components[EXTENSION], path.extension);

  Expect.equals(path.isCanonical, properties.contains('canonical'));
  Expect.equals(path.isAbsolute, properties.contains('absolute'));
  Expect.equals(path.hasTrailingSeparator, properties.contains('trailing'));
}

void testCanonicalize() {
  Function t = (input, canonicalized) {
    Expect.equals(canonicalized, new Path(input).canonicalize().toString());
  };

  t('.', '.');
  t('./.', '.');
  t('foo/..', '.');
  t('../foo', '../foo');
  t('/../foo', '/foo');
  t('/foo/..', '/');
  t('/foo/../', '/');
  t('/c:/../foo', '/c:/foo');
  t('/c:/foo/..', '/c:/');
  t('/c:/foo/../', '/c:/');
  t('/c:/foo/../..', '/c:/');
  t('/c:/foo/../../', '/c:/');
  t('..', '..');
  t('', '.');
  t('/', '/');
  t('../foo/bar/..', '../foo');
  t('/../foo/bar/..', '/foo');
  t('foo/bar/../../../joe/../..', '../..');
  t('a/b/c/../../..d/./.e/f././', 'a/..d/.e/f./');
  t('/%:/foo/../..', '/%:/');
  t('c:/foo/../../..', '..');
  t('c:/foo/../../bad/dad/./..', 'bad');
}

void testJoinAppend() {
  void testJoin(String a, String b, String c) {
    Expect.equals(new Path(a).join(new Path(b)).toString(), c);
  }

  testJoin('/a/b', 'c/d', '/a/b/c/d');
  testJoin('a/', 'b/c/', 'a/b/c/');
  testJoin('a/b/./c/..//', 'd/.././..//e/f//', 'a/e/f/');
  testJoin('a/b', 'c/../../../..', '..');
  testJoin('a/b', 'c/../../../', '.');
  testJoin('/a/b', 'c/../../../..', '/');
  testJoin('/a/b', 'c/../../../', '/');
  testJoin('a/b', 'c/../../../../../', '../../');
  testJoin('a/b/c', '../../d', 'a/d');
  testJoin('/a/b/c', '../../d', '/a/d');
  testJoin('/a/b/c', '../../d/', '/a/d/');
  testJoin('a/b/c', '../../d/', 'a/d/');

  void testAppend(String a, String b, String c) {
    Expect.equals(new Path(a).append(b).toString(), c);
  }

  testAppend('/a/b', 'c', '/a/b/c');
  testAppend('a/b/', 'cd', 'a/b/cd');
  testAppend('.', '..', './..');
  testAppend('a/b', '/c/d', 'a/b//c/d');
  testAppend('', 'foo/bar', 'foo/bar');
  testAppend('/foo', '', '/foo/');

  // .join can only join a relative path to a path.
  // It cannot join an absolute path to a path.
  Expect.throws(() => new Path('/a/b/').join(new Path('/c/d')));
}

void testRelativeTo() {
  Expect.equals('c/d',
                new Path('/a/b/c/d').relativeTo(new Path('/a/b')).toString());
  Expect.equals('c/d',
                new Path('/a/b/c/d').relativeTo(new Path('/a/b/')).toString());
  Expect.equals('.',
                new Path('/a').relativeTo(new Path('/a')).toString());

  // Trailing / in base path represents directory
  Expect.equals('../../z/x/y',
      new Path('/a/b/z/x/y').relativeTo(new Path('/a/b/c/d/')).toString());
  Expect.equals('../z/x/y',
      new Path('/a/b/z/x/y').relativeTo(new Path('/a/b/c/d')).toString());
  Expect.equals('../z/x/y/',
      new Path('/a/b/z/x/y/').relativeTo(new Path('/a/b/c/d')).toString());

  Expect.equals('../../z/x/y',
      new Path('/z/x/y').relativeTo(new Path('/a/b/c')).toString());
  Expect.equals('../../../z/x/y',
      new Path('/z/x/y').relativeTo(new Path('/a/b/c/')).toString());

  // Not implemented yet.  Should return new Path('../b/c/d/').
  Expect.throws(() =>
                new Path('b/c/d/').relativeTo(new Path('a/')));
  // Should always throw - no relative path can be constructed.
  Expect.throws(() =>
                new Path('a/b').relativeTo(new Path('../../d')));
}
