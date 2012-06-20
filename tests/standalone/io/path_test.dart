// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test the Path class in dart:io.

#import("dart:io");

void main() {
  testBaseFunctions();
  testCanonicalize();
}

void testBaseFunctions() {
  testGetters(new Path("/foo/bar/fisk.hest"),
              ['/foo/bar', 'fisk.hest', 'fisk', 'hest'],
              'absolute canonical');
  testGetters(new Path("/foo/bar/fisk.hest"),
              ['/foo/bar', 'fisk.hest', 'fisk', 'hest'],
              'absolute canonical');
  testGetters(new Path("/foo/bar/fisk.hest"),
              ['/foo/bar', 'fisk.hest', 'fisk', 'hest'],
              'absolute canonical');
  testGetters(new Path(''),
    ['', '', '', ''],
    'empty');
  // This corner case leaves a trailing slash for the root.
  testGetters(new Path('/'),
    ['/', '', '', ''],
    'absolute directory canonical trailing');
  testGetters(new Path('.'),
    ['', '.', '', ''],
    'canonical');
  testGetters(new Path('/ab,;- .c.d'),
    ['/', 'ab,;- .c.d', 'ab,;- .c', 'd'],
    'absolute directory canonical');

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
    'canonical directory trailing');

  // Test the special path cleaning operations on the Windows platform.
  if (Platform.operatingSystem == 'windows') {
    testGetters(new Path.fromNative(@"c:\foo\bar\fisk.hest"),
                ['/c:/foo/bar', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path.fromNative("\\foo\\bar\\"),
                ['/foo/bar', '', '', ''],
                'absolute directory canonical trailing');
    testGetters(new Path.fromNative("\\foo\\bar\\hest"),
                ['/foo/bar', 'hest', 'hest', ''],
                'absolute canonical');
    testGetters(new Path.fromNative(@"foo/bar\hest/.fisk"),
                ['foo/bar/hest', '.fisk', '', 'fisk'],
                'canonical');
    testGetters(new Path.fromNative(@"foo//bar\\hest/\/.fisk"),
                ['foo//bar//hest', '.fisk', '', 'fisk'],
                '');
  } else {
    // Make sure that backslashes are uninterpreted on other platforms.
    testGetters(new Path.fromNative(@"/foo\bar/bif/fisk.hest"),
                [@'/foo\bar/bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute canonical');
    testGetters(new Path.fromNative(@"//foo\bar///bif////fisk.hest"),
                [@'//foo\bar///bif', 'fisk.hest', 'fisk', 'hest'],
                'absolute');
    testGetters(new Path.fromNative(@"/foo\ bar/bif/gule\ fisk.hest"),
                [@'/foo\ bar/bif', @'gule\ fisk.hest', @'gule\ fisk', 'hest'],
                'absolute canonical');
  }
}


void testGetters(Path path, List components, String properties) {
  final int DIRNAME = 0;
  final int FILENAME = 1;
  final int BASENAME = 2;
  final int EXTENSION = 3;
  Expect.equals(components[DIRNAME], path.directoryPath.toString());
  Expect.equals(components[FILENAME], path.filename);
  Expect.equals(components[BASENAME], path.filenameWithoutExtension);
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
