// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test "relative" on all styles of path.Context, on all platforms.

import "package:unittest/unittest.dart";
import "package:path/path.dart" as path;

import "utils.dart";

void main() {
  test("test relative", () {
    relativeTest(new path.Context(style: path.Style.posix, current: '.'), '/');
    relativeTest(new path.Context(style: path.Style.posix, current: '/'), '/');
    relativeTest(new path.Context(style: path.Style.windows, current: r'd:\'),
                 r'c:\');
    relativeTest(new path.Context(style: path.Style.windows, current: '.'),
                 r'c:\');
    relativeTest(new path.Context(style: path.Style.url, current: 'file:///'),
                 'http://myserver/');
    relativeTest(new path.Context(style: path.Style.url, current: '.'),
                 'http://myserver/');
    relativeTest(new path.Context(style: path.Style.url, current: 'file:///'),
                 '/');
    relativeTest(new path.Context(style: path.Style.url, current: '.'), '/');
  });
}

void relativeTest(path.Context context, String prefix) {
  var isRelative = (context.current == '.');
  // Cases where the arguments are absolute paths.
  expectRelative(result, pathArg, fromArg) {
    expect(context.normalize(result), context.relative(pathArg, from: fromArg));
  }

  expectRelative('c/d', '${prefix}a/b/c/d', '${prefix}a/b');
  expectRelative('c/d', '${prefix}a/b/c/d', '${prefix}a/b/');
  expectRelative('.', '${prefix}a', '${prefix}a');
  // Trailing slashes in the inputs have no effect.
  expectRelative('../../z/x/y', '${prefix}a/b/z/x/y', '${prefix}a/b/c/d/');
  expectRelative('../../z/x/y', '${prefix}a/b/z/x/y', '${prefix}a/b/c/d');
  expectRelative('../../z/x/y', '${prefix}a/b/z/x/y/', '${prefix}a/b/c/d');
  expectRelative('../../../z/x/y', '${prefix}z/x/y', '${prefix}a/b/c');
  expectRelative('../../../z/x/y', '${prefix}z/x/y', '${prefix}a/b/c/');

  // Cases where the arguments are relative paths.
  expectRelative('c/d', 'a/b/c/d', 'a/b');
  expectRelative('.', 'a/b/c', 'a/b/c');
  expectRelative('.', 'a/d/../b/c', 'a/b/c/');
  expectRelative('.', '', '');
  expectRelative('.', '.', '');
  expectRelative('.', '', '.');
  expectRelative('.', '.', '.');
  expectRelative('.', '..', '..');
  if (isRelative) expectRelative('..', '..', '.');
  expectRelative('a', 'a', '');
  expectRelative('a', 'a', '.');
  expectRelative('..', '.', 'a');
  expectRelative('.', 'a/b/f/../c', 'a/e/../b/c');
  expectRelative('d', 'a/b/f/../c/d', 'a/e/../b/c');
  expectRelative('..', 'a/b/f/../c', 'a/e/../b/c/e/');
  expectRelative('../..', '', 'a/b/');
  if (isRelative) expectRelative('../../..', '..', 'a/b/');
  expectRelative('../b/c/d', 'b/c/d/', 'a/');
  expectRelative('../a/b/c', 'x/y/a//b/./f/../c', 'x//y/z');

  // Case where from is an exact substring of path.
  expectRelative('a/b', '${prefix}x/y//a/b', '${prefix}x/y/');
  expectRelative('a/b', 'x/y//a/b', 'x/y/');
  expectRelative('../ya/b', '${prefix}x/ya/b', '${prefix}x/y');
  expectRelative('../ya/b', 'x/ya/b', 'x/y');
  expectRelative('../b', 'x/y/../b', 'x/y/.');
  expectRelative('a/b/c', 'x/y/a//b/./f/../c', 'x/y');
  expectRelative('.', '${prefix}x/y//', '${prefix}x/y/');
  expectRelative('.', '${prefix}x/y/', '${prefix}x/y');

  // Should always throw - no relative path can be constructed.
  if (isRelative) {
    expect(() => context.relative('.', from: '..'), throwsPathException);
    expect(() => context.relative('a/b', from: '../../d'),
           throwsPathException);
    expect(() => context.relative('a/b', from: '${prefix}a/b'),
           throwsPathException);
    // An absolute path relative from a relative path returns the absolute path.
    expectRelative('${prefix}a/b', '${prefix}a/b', 'c/d');
  }
}
