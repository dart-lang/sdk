// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test the Path class in dart:io.

import "package:expect/expect.dart";
import "dart:io";

void main() {
  testBaseFunctions();
  testRaw();
  testToNativePath();
  testCanonicalize();
  testJoinAppend();
  testRelativeTo();
  testWindowsShare();
  testWindowsDrive();
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
    testGetters(new Path(r"c:\foo\bar\fisk.hest"),
                ['/c:/foo/bar', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path("\\foo\\bar\\"),
                ['/foo/bar', '', '', ''],
                'absolute canonical trailing');
    testGetters(new Path("\\foo\\bar\\hest"),
                ['/foo/bar', 'hest', 'hest', ''],
                'absolute canonical');
    testGetters(new Path(r"foo/bar\hest/.fisk"),
                ['foo/bar/hest', '.fisk', '', 'fisk'],
                'canonical');
    testGetters(new Path(r"foo//bar\\hest/\/.fisk."),
                ['foo//bar//hest', '.fisk.', '.fisk', ''],
                '');
  } else {
    // Make sure that backslashes are uninterpreted on other platforms.
    testGetters(new Path(r"c:\foo\bar\fisk.hest"),
                ['', r'c:\foo\bar\fisk.hest', r'c:\foo\bar\fisk', 'hest'],
                'canonical');
    testGetters(new Path(r"/foo\bar/bif/fisk.hest"),
                [r'/foo\bar/bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path(r"//foo\bar///bif////fisk.hest"),
                [r'//foo\bar///bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute');
    testGetters(new Path(r"/foo\ bar/bif/gule\ fisk.hest"),
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

void testRaw() {
  Expect.equals(new Path.raw('c:\\foo/bar bad').toString(), 'c:\\foo/bar bad');
  Expect.equals(new Path.raw('').toString(), '');
  Expect.equals(new Path.raw('\\bar\u2603\n.').toString(), '\\bar\u2603\n.');
}

void testToNativePath() {
  Expect.equals('.', new Path('').toNativePath());
  Expect.equals('.', new Path('.').toNativePath());
  Expect.equals('.', new Path('a_file').directoryPath.toNativePath());
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
  if (Platform.operatingSystem == 'windows') {
    t('c:/foo/../../..', '/c:/');
    t('c:/foo/../../bad/dad/./..', '/c:/bad');
  } else {
    t('c:/foo/../../..', '..');
    t('c:/foo/../../bad/dad/./..', 'bad');
  }
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
  // Cases where the arguments are absolute paths.
  Expect.equals('c/d',
                new Path('/a/b/c/d').relativeTo(new Path('/a/b')).toString());
  Expect.equals('c/d',
                new Path('/a/b/c/d').relativeTo(new Path('/a/b/')).toString());
  Expect.equals('.',
                new Path('/a').relativeTo(new Path('/a')).toString());

  // Trailing slash in the base path has no effect.  This matches Path.join
  // semantics, but not URL join semantics.
  Expect.equals('../../z/x/y',
      new Path('/a/b/z/x/y').relativeTo(new Path('/a/b/c/d/')).toString());
  Expect.equals('../../z/x/y',
      new Path('/a/b/z/x/y').relativeTo(new Path('/a/b/c/d')).toString());
  Expect.equals('../../z/x/y/',
      new Path('/a/b/z/x/y/').relativeTo(new Path('/a/b/c/d')).toString());

  Expect.equals('../../../z/x/y',
      new Path('/z/x/y').relativeTo(new Path('/a/b/c')).toString());
  Expect.equals('../../../z/x/y',
      new Path('/z/x/y').relativeTo(new Path('/a/b/c/')).toString());

  // Cases where the arguments are relative paths.
  Expect.equals('c/d',
      new Path('a/b/c/d').relativeTo(new Path('a/b')).toString());
  Expect.equals('c/d',
      new Path('/a/b/c/d').relativeTo(new Path('/a/b/')).toString());
  Expect.equals('.',
      new Path('a/b/c').relativeTo(new Path('a/b/c')).toString());
  Expect.equals('.',
      new Path('').relativeTo(new Path('')).toString());
  Expect.equals('.',
      new Path('.').relativeTo(new Path('.')).toString());
  Expect.equals('a',
      new Path('a').relativeTo(new Path('.')).toString());
  Expect.equals('..',
      new Path('..').relativeTo(new Path('.')).toString());
  Expect.equals('..',
      new Path('.').relativeTo(new Path('a')).toString());
  Expect.equals('.',
      new Path('..').relativeTo(new Path('..')).toString());
  Expect.equals('./',
      new Path('a/b/f/../c/').relativeTo(new Path('a/e/../b/c')).toString());
  Expect.equals('d',
      new Path('a/b/f/../c/d').relativeTo(new Path('a/e/../b/c')).toString());
  Expect.equals('..',
      new Path('a/b/f/../c').relativeTo(new Path('a/e/../b/c/e/')).toString());
  Expect.equals('../..',
      new Path('').relativeTo(new Path('a/b/')).toString());
  Expect.equals('../../..',
      new Path('..').relativeTo(new Path('a/b')).toString());
  Expect.equals('../b/c/d/',
      new Path('b/c/d/').relativeTo(new Path('a/')).toString());
  Expect.equals('../a/b/c',
      new Path('x/y/a//b/./f/../c').relativeTo(new Path('x//y/z')).toString());

  // Case where base is a substring of relative:
  Expect.equals('a/b',
      new Path('/x/y//a/b').relativeTo(new Path('/x/y/')).toString());
  Expect.equals('a/b',
      new Path('x/y//a/b').relativeTo(new Path('x/y/')).toString());
  Expect.equals('../ya/b',
      new Path('/x/ya/b').relativeTo(new Path('/x/y')).toString());
  Expect.equals('../ya/b',
      new Path('x/ya/b').relativeTo(new Path('x/y')).toString());
  Expect.equals('../b',
      new Path('x/y/../b').relativeTo(new Path('x/y/.')).toString());
  Expect.equals('a/b/c',
      new Path('x/y/a//b/./f/../c').relativeTo(new Path('x/y')).toString());
  Expect.equals('.',
      new Path('/x/y//').relativeTo(new Path('/x/y/')).toString());
  Expect.equals('.',
      new Path('/x/y/').relativeTo(new Path('/x/y')).toString());

  // Should always throw - no relative path can be constructed.
  Expect.throws(() =>
                new Path('a/b').relativeTo(new Path('../../d')));
  // Should always throw - relative and absolute paths are compared.
  Expect.throws(() =>
                new Path('/a/b').relativeTo(new Path('c/d')));

  Expect.throws(() =>
                new Path('a/b').relativeTo(new Path('/a/b')));

}

// Test that Windows share information is maintained through
// Path operations.
void testWindowsShare() {
  // Windows share information only makes sense on Windows.
  if (Platform.operatingSystem != 'windows') return;
  var path = new Path(r'\\share\a\b\..\c');
  Expect.isTrue(path.isAbsolute);
  Expect.isTrue(path.isWindowsShare);
  Expect.isFalse(path.hasTrailingSeparator);
  var canonical = path.canonicalize();
  Expect.isTrue(canonical.isAbsolute);
  Expect.isTrue(canonical.isWindowsShare);
  Expect.isFalse(path.isCanonical);
  Expect.isTrue(canonical.isCanonical);
  var joined = canonical.join(new Path('d/e/f'));
  Expect.isTrue(joined.isAbsolute);
  Expect.isTrue(joined.isWindowsShare);
  var relativeTo = joined.relativeTo(canonical);
  Expect.isFalse(relativeTo.isAbsolute);
  Expect.isFalse(relativeTo.isWindowsShare);
  var nonShare = new Path('/share/a/c/d/e');
  Expect.throws(() => nonShare.relativeTo(canonical));
  Expect.isTrue(canonical.toString().startsWith('/share/a'));
  Expect.isTrue(canonical.toNativePath().startsWith(r'\\share\a'));
  Expect.listEquals(['share', 'a', 'c'], canonical.segments());
  var appended = canonical.append('d');
  Expect.isTrue(appended.isAbsolute);
  Expect.isTrue(appended.isWindowsShare);
  var directoryPath = canonical.directoryPath;
  Expect.isTrue(directoryPath.isAbsolute);
  Expect.isTrue(directoryPath.isWindowsShare);
}

// Test that Windows drive information is handled correctly in relative
// Path operations.
void testWindowsDrive() {
  // Windows drive information only makes sense on Windows.
  if (Platform.operatingSystem != 'windows') return;
  // Test that case of drive letters is ignored, and that drive letters
  // are treated specially.
  var CPath = new Path(r'C:\a\b\..\c');
  var cPath = new Path(r'c:\a\b\d');
  var C2Path = new Path(r'C:\a\b\d');
  var C3Path = new Path(r'C:\a\b');
  var C4Path = new Path(r'C:\');
  var c4Path = new Path(r'c:\');
  var DPath = new Path(r'D:\a\b\d\e');
  var NoPath = new Path(r'\a\b\c\.');

  Expect.throws(() => CPath.relativeTo(DPath));
  Expect.throws(() => CPath.relativeTo(NoPath));
  Expect.throws(() => NoPath.relativeTo(CPath));
  Expect.equals('../../c', CPath.relativeTo(cPath).toString());
  Expect.equals('../b/d', cPath.relativeTo(CPath).toString());
  Expect.equals('.', DPath.relativeTo(DPath).toString());
  Expect.equals('.', NoPath.relativeTo(NoPath).toString());
  Expect.equals('.', C2Path.relativeTo(cPath).toString());
  Expect.equals('..', C3Path.relativeTo(cPath).toString());
  Expect.equals('d', cPath.relativeTo(C3Path).toString());
  Expect.equals('a/b/d', cPath.relativeTo(C4Path).toString());
  Expect.equals('../../../', C4Path.relativeTo(cPath).toString());
  Expect.equals('a/b', C3Path.relativeTo(c4Path).toString());
}
