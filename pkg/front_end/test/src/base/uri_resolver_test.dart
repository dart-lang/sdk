// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/uri_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriResolverTestNative);
    defineReflectiveTests(UriResolverTestPosix);
    defineReflectiveTests(UriResolverTestWindows);
  });
}

/// Generic URI resolver tests which do not depend on the particular path
/// context in use.
abstract class UriResolverTest {
  p.Context get pathContext;

  void test_badScheme() {
    _expectResolutionUri('foo:bar/baz.dart', Uri.parse('foo:bar/baz.dart'));
  }

  void test_dart() {
    _expectResolution('dart:core', _p('sdk/lib/core/core.dart'));
    _expectResolution('dart:async', _p('sdk/lib/async/async.dart'));
  }

  void test_dartLeadingSlash() {
    _expectResolution('dart:/core', null);
  }

  void test_dartLeadingSlash2() {
    _expectResolution('dart://core', null);
  }

  void test_dartLeadingSlash3() {
    _expectResolution('dart:///core', null);
  }

  void test_dartPart() {
    _expectResolution('dart:core/bool.dart', _p('sdk/lib/core/bool.dart'));
  }

  void test_file() {
    _expectResolution(_fileUri('foo.dart'), _p('foo.dart'));
  }

  void test_fileLongPath() {
    _expectResolution(_fileUri('foo/bar.dart'), _p('foo/bar.dart'));
  }

  void test_noSchemeAbsolute() {
    _expectResolutionUri('/foo.dart', Uri.parse('/foo.dart'));
  }

  void test_noSchemeRelative() {
    _expectResolution('foo.dart', 'foo.dart');
  }

  void test_package() {
    _expectResolution('package:foo/bar.dart', _p('packages/foo/lib/bar.dart'));
    _expectResolution('package:bar/baz.dart', _p('packages/bar/lib/baz.dart'));
  }

  void test_packageLeadingSlash() {
    _expectResolution('package:/foo', null);
  }

  void test_packageLeadingSlash2() {
    _expectResolution('package://foo', null);
  }

  void test_packageLeadingSlash3() {
    _expectResolution('package:///foo', null);
  }

  void test_packageLongPath() {
    _expectResolution(
        'package:foo/bar/baz.dart', _p('packages/foo/lib/bar/baz.dart'));
  }

  void test_packageNoPath() {
    // In practice "package:foo/" is meaningless.  But the VM treats it as
    // resolving to the package's lib directory (and then later reports the
    // error when trying to open that directory as a file), so for consistency
    // we do the same.
    _expectResolution('package:foo/', _p('packages/foo/lib/'));
  }

  void test_packageNoSlash() {
    _expectResolution('package:foo', null);
  }

  void test_packageUnmatchedName() {
    _expectResolution('package:doesNotExist/foo.dart', null);
  }

  /// Verifies that the resolution of [uriString] produces the path
  /// [expectedResult].
  void _expectResolution(String uriString, String expectedResult) {
    _expectResolutionUri(uriString,
        expectedResult == null ? null : pathContext.toUri(expectedResult));
  }

  /// Verifies that the resolution of [uriString] produces the URI
  /// [expectedResult].
  void _expectResolutionUri(String uriString, Uri expectedResult) {
    var packages = {
      'foo': _u('packages/foo/lib/'),
      'bar': _u('packages/bar/lib/')
    };
    var sdkLibraries = {
      'core': _u('sdk/lib/core/core.dart'),
      'async': _u('sdk/lib/async/async.dart')
    };
    var uriResolver = new UriResolver(packages, sdkLibraries);
    expect(uriResolver.resolve(Uri.parse(uriString)), expectedResult);
  }

  /// Prepends "file:///", plus a Windows drive letter if applicable, to the
  /// given path.
  String _fileUri(String pathPart) {
    if (pathContext.separator == '/') {
      return 'file:///$pathPart';
    } else {
      return 'file:///C:/$pathPart';
    }
  }

  /// Converts a posix style path into a path appropriate for the current path
  /// context.
  String _p(String posixPath) {
    if (!posixPath.startsWith('/')) posixPath = '/$posixPath';
    if (pathContext.separator == '/') return posixPath;
    // Windows
    return 'C:${posixPath.replaceAll('/', pathContext.separator)}';
  }

  /// Converts a posix style path into a file URI.
  Uri _u(String posixPath) => pathContext.toUri(_p(posixPath));
}

/// Override of [UriResolverTest] which uses the native path context for the
/// platform the test is running on.
@reflectiveTest
class UriResolverTestNative extends UriResolverTest {
  final p.Context pathContext = p.context;
}

/// Override of [UriResolverTest] which uses a posix path context, regardless of
/// the platform the test is running on.
@reflectiveTest
class UriResolverTestPosix extends UriResolverTest {
  final p.Context pathContext = p.posix;
}

/// Override of [UriResolverTest] which uses a windows path context, regardless
/// of the platform the test is running on.
@reflectiveTest
class UriResolverTestWindows extends UriResolverTest {
  final p.Context pathContext = p.windows;

  void test_fileWindowsLocal() {
    _expectResolution('file:///C:/foo/bar.dart', r'C:\foo\bar.dart');
  }

  void test_fileWindowsUNC() {
    _expectResolution(
        'file://computer/directory/foo.dart', r'\\computer\directory\foo.dart');
  }
}
