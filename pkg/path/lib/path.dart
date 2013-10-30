// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A comprehensive, cross-platform path manipulation library.
///
/// ## Installing ##
///
/// Use [pub][] to install this package. Add the following to your
/// `pubspec.yaml` file.
///
///     dependencies:
///       path: any
///
/// Then run `pub install`.
///
/// For more information, see the [path package on pub.dartlang.org][pkg].
///
/// [pub]: http://pub.dartlang.org
/// [pkg]: http://pub.dartlang.org/packages/path
///
/// ## Usage ##
///
/// The path library was designed to be imported with a prefix, though you don't
/// have to if you don't want to:
///
///     import 'package:path/path.dart' as path;
///
/// The most common way to use the library is through the top-level functions.
/// These manipulate path strings based on your current working directory and
/// the path style (POSIX, Windows, or URLs) of the host platform. For example:
///
///     path.join("directory", "file.txt");
///
/// This calls the top-level [join] function to join "directory" and "file.txt"
/// using the current platform's directory separator.
///
/// If you want to work with paths for a specific platform regardless of the
/// underlying platform that the program is running on, you can create a
/// [Builder] and give it an explicit [Style]:
///
///     var builder = new path.Builder(style: Style.windows);
///     builder.join("directory", "file.txt");
///
/// This will join "directory" and "file.txt" using the Windows path separator,
/// even when the program is run on a POSIX machine.
library path;

@MirrorsUsed(targets: 'dart.dom.html.window, '
    'dart.io.Directory.current, '
    'dart.io.Platform.operatingSystem')
import 'dart:mirrors';

/// An internal builder for the current OS so we can provide a straight
/// functional interface and not require users to create one.
final _builder = new Builder();

/// A default builder for manipulating POSIX paths.
final posix = new Builder(style: Style.posix);

/// A default builder for manipulating Windows paths.
final windows = new Builder(style: Style.windows);

/// A default builder for manipulating URLs.
final url = new Builder(style: Style.url);

/// Inserts [length] elements in front of the [list] and fills them with the
/// [fillValue].
void _growListFront(List list, int length, fillValue) =>
  list.insertAll(0, new List.filled(length, fillValue));

/// If we're running in the server-side Dart VM, this will return a
/// [LibraryMirror] that gives access to the `dart:io` library.
///
/// If `dart:io` is not available, this returns null.
LibraryMirror get _io => currentMirrorSystem().libraries[Uri.parse('dart:io')];

// TODO(nweiz): when issue 6490 or 6943 are fixed, make this work under dart2js.
/// If we're running in Dartium, this will return a [LibraryMirror] that gives
/// access to the `dart:html` library.
///
/// If `dart:html` is not available, this returns null.
LibraryMirror get _html =>
  currentMirrorSystem().libraries[Uri.parse('dart:html')];

/// Gets the path to the current working directory.
///
/// In the browser, this means the current URL. When using dart2js, this
/// currently returns `.` due to technical constraints. In the future, it will
/// return the current URL.
String get current {
  if (_io != null) {
    return (_io.declarations[#Directory] as ClassMirror)
        .getField(#current).reflectee.path;
  } else if (_html != null) {
    return _html.getField(#window).reflectee.location.href;
  } else {
    return '.';
  }
}

/// Gets the path separator for the current platform. This is `\` on Windows
/// and `/` on other platforms (including the browser).
String get separator => _builder.separator;

/// Converts [path] to an absolute path by resolving it relative to the current
/// working directory. If [path] is already an absolute path, just returns it.
///
///     path.absolute('foo/bar.txt'); // -> /your/current/dir/foo/bar.txt
String absolute(String path) => join(current, path);

/// Gets the part of [path] after the last separator.
///
///     path.basename('path/to/foo.dart'); // -> 'foo.dart'
///     path.basename('path/to');          // -> 'to'
///
/// Trailing separators are ignored.
///
///     builder.basename('path/to/'); // -> 'to'
String basename(String path) => _builder.basename(path);

/// Gets the part of [path] after the last separator, and without any trailing
/// file extension.
///
///     path.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
///
/// Trailing separators are ignored.
///
///     builder.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'
String basenameWithoutExtension(String path) =>
    _builder.basenameWithoutExtension(path);

/// Gets the part of [path] before the last separator.
///
///     path.dirname('path/to/foo.dart'); // -> 'path/to'
///     path.dirname('path/to');          // -> 'path'
///
/// Trailing separators are ignored.
///
///     builder.dirname('path/to/'); // -> 'path'
///
/// If an absolute path contains no directories, only a root, then the root
/// is returned.
///
///     path.dirname('/');  // -> '/' (posix)
///     path.dirname('c:\');  // -> 'c:\' (windows)
///
/// If a relative path has no directories, then '.' is returned.
///
///     path.dirname('foo');  // -> '.'
///     path.dirname('');  // -> '.'
String dirname(String path) => _builder.dirname(path);

/// Gets the file extension of [path]: the portion of [basename] from the last
/// `.` to the end (including the `.` itself).
///
///     path.extension('path/to/foo.dart');    // -> '.dart'
///     path.extension('path/to/foo');         // -> ''
///     path.extension('path.to/foo');         // -> ''
///     path.extension('path/to/foo.dart.js'); // -> '.js'
///
/// If the file name starts with a `.`, then that is not considered the
/// extension:
///
///     path.extension('~/.bashrc');    // -> ''
///     path.extension('~/.notes.txt'); // -> '.txt'
String extension(String path) => _builder.extension(path);

// TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
/// Returns the root of [path], if it's absolute, or the empty string if it's
/// relative.
///
///     // Unix
///     path.rootPrefix('path/to/foo'); // -> ''
///     path.rootPrefix('/path/to/foo'); // -> '/'
///
///     // Windows
///     path.rootPrefix(r'path\to\foo'); // -> ''
///     path.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'
///
///     // URL
///     path.rootPrefix('path/to/foo'); // -> ''
///     path.rootPrefix('http://dartlang.org/path/to/foo');
///       // -> 'http://dartlang.org'
String rootPrefix(String path) => _builder.rootPrefix(path);

/// Returns `true` if [path] is an absolute path and `false` if it is a
/// relative path.
///
/// On POSIX systems, absolute paths start with a `/` (forward slash). On
/// Windows, an absolute path starts with `\\`, or a drive letter followed by
/// `:/` or `:\`. For URLs, absolute paths either start with a protocol and
/// optional hostname (e.g. `http://dartlang.org`, `file://`) or with a `/`.
///
/// URLs that start with `/` are known as "root-relative", since they're
/// relative to the root of the current URL. Since root-relative paths are still
/// absolute in every other sense, [isAbsolute] will return true for them. They
/// can be detected using [isRootRelative].
bool isAbsolute(String path) => _builder.isAbsolute(path);

/// Returns `true` if [path] is a relative path and `false` if it is absolute.
/// On POSIX systems, absolute paths start with a `/` (forward slash). On
/// Windows, an absolute path starts with `\\`, or a drive letter followed by
/// `:/` or `:\`.
bool isRelative(String path) => _builder.isRelative(path);

/// Returns `true` if [path] is a root-relative path and `false` if it's not.
///
/// URLs that start with `/` are known as "root-relative", since they're
/// relative to the root of the current URL. Since root-relative paths are still
/// absolute in every other sense, [isAbsolute] will return true for them. They
/// can be detected using [isRootRelative].
///
/// No POSIX and Windows paths are root-relative.
bool isRootRelative(String path) => _builder.isRootRelative(path);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     path.join('path', 'to', 'foo'); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     path.join('path/', 'to', 'foo'); // -> 'path/to/foo
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     path.join('path', '/to', 'foo'); // -> '/to/foo'
String join(String part1, [String part2, String part3, String part4,
            String part5, String part6, String part7, String part8]) =>
  _builder.join(part1, part2, part3, part4, part5, part6, part7, part8);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     path.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     path.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     path.joinAll(['path', '/to', 'foo']); // -> '/to/foo'
///
/// For a fixed number of parts, [join] is usually terser.
String joinAll(Iterable<String> parts) => _builder.joinAll(parts);

// TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
/// Splits [path] into its components using the current platform's [separator].
///
///     path.split('path/to/foo'); // -> ['path', 'to', 'foo']
///
/// The path will *not* be normalized before splitting.
///
///     path.split('path/../foo'); // -> ['path', '..', 'foo']
///
/// If [path] is absolute, the root directory will be the first element in the
/// array. Example:
///
///     // Unix
///     path.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']
///
///     // Windows
///     path.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']
///
///     // Browser
///     path.split('http://dartlang.org/path/to/foo');
///       // -> ['http://dartlang.org', 'path', 'to', 'foo']
List<String> split(String path) => _builder.split(path);

/// Normalizes [path], simplifying it by handling `..`, and `.`, and
/// removing redundant path separators whenever possible.
///
///     path.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
String normalize(String path) => _builder.normalize(path);

/// Attempts to convert [path] to an equivalent relative path from the current
/// directory.
///
///     // Given current directory is /root/path:
///     path.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
///     path.relative('/root/other.dart'); // -> '../other.dart'
///
/// If the [from] argument is passed, [path] is made relative to that instead.
///
///     path.relative('/root/path/a/b.dart',
///         from: '/root/path'); // -> 'a/b.dart'
///     path.relative('/root/other.dart',
///         from: '/root/path'); // -> '../other.dart'
///
/// If [path] and/or [from] are relative paths, they are assumed to be relative
/// to the current directory.
///
/// Since there is no relative path from one drive letter to another on Windows,
/// or from one hostname to another for URLs, this will return an absolute path
/// in those cases.
///
///     // Windows
///     path.relative(r'D:\other', from: r'C:\home'); // -> 'D:\other'
///
///     // URL
///     path.relative('http://dartlang.org', from: 'http://pub.dartlang.org');
///       // -> 'http://dartlang.org'
String relative(String path, {String from}) =>
    _builder.relative(path, from: from);

/// Removes a trailing extension from the last part of [path].
///
///     withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
String withoutExtension(String path) => _builder.withoutExtension(path);

/// Returns the path represented by [uri].
///
/// For POSIX and Windows styles, [uri] must be a `file:` URI. For the URL
/// style, this will just convert [uri] to a string.
///
///     // POSIX
///     path.fromUri(Uri.parse('file:///path/to/foo'))
///       // -> '/path/to/foo'
///
///     // Windows
///     path.fromUri(Uri.parse('file:///C:/path/to/foo'))
///       // -> r'C:\path\to\foo'
///
///     // URL
///     path.fromUri(Uri.parse('http://dartlang.org/path/to/foo'))
///       // -> 'http://dartlang.org/path/to/foo'
String fromUri(Uri uri) => _builder.fromUri(uri);

/// Returns the URI that represents [path].
///
/// For POSIX and Windows styles, this will return a `file:` URI. For the URL
/// style, this will just convert [path] to a [Uri].
///
///     // POSIX
///     path.toUri('/path/to/foo')
///       // -> Uri.parse('file:///path/to/foo')
///
///     // Windows
///     path.toUri(r'C:\path\to\foo')
///       // -> Uri.parse('file:///C:/path/to/foo')
///
///     // URL
///     path.toUri('http://dartlang.org/path/to/foo')
///       // -> Uri.parse('http://dartlang.org/path/to/foo')
///
/// If [path] is relative, a relative URI will be returned.
///
///     path.toUri('path/to/foo')
///       // -> Uri.parse('path/to/foo')
Uri toUri(String path) => _builder.toUri(path);

/// Validates that there are no non-null arguments following a null one and
/// throws an appropriate [ArgumentError] on failure.
_validateArgList(String method, List<String> args) {
  for (var i = 1; i < args.length; i++) {
    // Ignore nulls hanging off the end.
    if (args[i] == null || args[i - 1] != null) continue;

    var numArgs;
    for (numArgs = args.length; numArgs >= 1; numArgs--) {
      if (args[numArgs - 1] != null) break;
    }

    // Show the arguments.
    var message = new StringBuffer();
    message.write("$method(");
    message.write(args.take(numArgs)
        .map((arg) => arg == null ? "null" : '"$arg"')
        .join(", "));
    message.write("): part ${i - 1} was null, but part $i was not.");
    throw new ArgumentError(message.toString());
  }
}

/// An instantiable class for manipulating paths. Unlike the top-level
/// functions, this lets you explicitly select what platform the paths will use.
class Builder {
  /// Creates a new path builder for the given style and root directory.
  ///
  /// If [style] is omitted, it uses the host operating system's path style. If
  /// only [root] is omitted, it defaults ".". If *both* [style] and [root] are
  /// omitted, [root] defaults to the current working directory.
  ///
  /// On the browser, the path style is [Style.url]. In Dartium, [root] defaults
  /// to the current URL. When using dart2js, it currently defaults to `.` due
  /// to technical constraints.
  factory Builder({Style style, String root}) {
    if (root == null) {
      if (style == null) {
        root = current;
      } else {
        root = ".";
      }
    }

    if (style == null) style = Style.platform;

    return new Builder._(style, root);
  }

  Builder._(this.style, this.root);

  /// The style of path that this builder works with.
  final Style style;

  /// The root directory that relative paths will be relative to.
  final String root;

  /// Gets the path separator for the builder's [style]. On Mac and Linux,
  /// this is `/`. On Windows, it's `\`.
  String get separator => style.separator;

  /// Gets the part of [path] after the last separator on the builder's
  /// platform.
  ///
  ///     builder.basename('path/to/foo.dart'); // -> 'foo.dart'
  ///     builder.basename('path/to');          // -> 'to'
  ///
  /// Trailing separators are ignored.
  ///
  ///     builder.basename('path/to/'); // -> 'to'
  String basename(String path) => _parse(path).basename;

  /// Gets the part of [path] after the last separator on the builder's
  /// platform, and without any trailing file extension.
  ///
  ///     builder.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
  ///
  /// Trailing separators are ignored.
  ///
  ///     builder.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'
  String basenameWithoutExtension(String path) =>
    _parse(path).basenameWithoutExtension;

  /// Gets the part of [path] before the last separator.
  ///
  ///     builder.dirname('path/to/foo.dart'); // -> 'path/to'
  ///     builder.dirname('path/to');          // -> 'path'
  ///
  /// Trailing separators are ignored.
  ///
  ///     builder.dirname('path/to/'); // -> 'path'
  String dirname(String path) {
    var parsed = _parse(path);
    parsed.removeTrailingSeparators();
    if (parsed.parts.isEmpty) return parsed.root == null ? '.' : parsed.root;
    if (parsed.parts.length == 1) {
      return parsed.root == null ? '.' : parsed.root;
    }
    parsed.parts.removeLast();
    parsed.separators.removeLast();
    parsed.removeTrailingSeparators();
    return parsed.toString();
  }

  /// Gets the file extension of [path]: the portion of [basename] from the last
  /// `.` to the end (including the `.` itself).
  ///
  ///     builder.extension('path/to/foo.dart'); // -> '.dart'
  ///     builder.extension('path/to/foo'); // -> ''
  ///     builder.extension('path.to/foo'); // -> ''
  ///     builder.extension('path/to/foo.dart.js'); // -> '.js'
  ///
  /// If the file name starts with a `.`, then it is not considered an
  /// extension:
  ///
  ///     builder.extension('~/.bashrc');    // -> ''
  ///     builder.extension('~/.notes.txt'); // -> '.txt'
  String extension(String path) => _parse(path).extension;

  // TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
  /// Returns the root of [path], if it's absolute, or an empty string if it's
  /// relative.
  ///
  ///     // Unix
  ///     builder.rootPrefix('path/to/foo'); // -> ''
  ///     builder.rootPrefix('/path/to/foo'); // -> '/'
  ///
  ///     // Windows
  ///     builder.rootPrefix(r'path\to\foo'); // -> ''
  ///     builder.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'
  ///
  ///     // URL
  ///     builder.rootPrefix('path/to/foo'); // -> ''
  ///     builder.rootPrefix('http://dartlang.org/path/to/foo');
  ///       // -> 'http://dartlang.org'
  String rootPrefix(String path) {
    var root = _parse(path).root;
    return root == null ? '' : root;
  }

  /// Returns `true` if [path] is an absolute path and `false` if it is a
  /// relative path.
  ///
  /// On POSIX systems, absolute paths start with a `/` (forward slash). On
  /// Windows, an absolute path starts with `\\`, or a drive letter followed by
  /// `:/` or `:\`. For URLs, absolute paths either start with a protocol and
  /// optional hostname (e.g. `http://dartlang.org`, `file://`) or with a `/`.
  ///
  /// URLs that start with `/` are known as "root-relative", since they're
  /// relative to the root of the current URL. Since root-relative paths are
  /// still absolute in every other sense, [isAbsolute] will return true for
  /// them. They can be detected using [isRootRelative].
  bool isAbsolute(String path) => _parse(path).isAbsolute;

  /// Returns `true` if [path] is a relative path and `false` if it is absolute.
  /// On POSIX systems, absolute paths start with a `/` (forward slash). On
  /// Windows, an absolute path starts with `\\`, or a drive letter followed by
  /// `:/` or `:\`.
  bool isRelative(String path) => !this.isAbsolute(path);

  /// Returns `true` if [path] is a root-relative path and `false` if it's not.
  ///
  /// URLs that start with `/` are known as "root-relative", since they're
  /// relative to the root of the current URL. Since root-relative paths are
  /// still absolute in every other sense, [isAbsolute] will return true for
  /// them. They can be detected using [isRootRelative].
  ///
  /// No POSIX and Windows paths are root-relative.
  bool isRootRelative(String path) => _parse(path).isRootRelative;

  /// Joins the given path parts into a single path. Example:
  ///
  ///     builder.join('path', 'to', 'foo'); // -> 'path/to/foo'
  ///
  /// If any part ends in a path separator, then a redundant separator will not
  /// be added:
  ///
  ///     builder.join('path/', 'to', 'foo'); // -> 'path/to/foo
  ///
  /// If a part is an absolute path, then anything before that will be ignored:
  ///
  ///     builder.join('path', '/to', 'foo'); // -> '/to/foo'
  ///
  String join(String part1, [String part2, String part3, String part4,
              String part5, String part6, String part7, String part8]) {
    var parts = [part1, part2, part3, part4, part5, part6, part7, part8];
    _validateArgList("join", parts);
    return joinAll(parts.where((part) => part != null));
  }

  /// Joins the given path parts into a single path. Example:
  ///
  ///     builder.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'
  ///
  /// If any part ends in a path separator, then a redundant separator will not
  /// be added:
  ///
  ///     builder.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo
  ///
  /// If a part is an absolute path, then anything before that will be ignored:
  ///
  ///     builder.joinAll(['path', '/to', 'foo']); // -> '/to/foo'
  ///
  /// For a fixed number of parts, [join] is usually terser.
  String joinAll(Iterable<String> parts) {
    var buffer = new StringBuffer();
    var needsSeparator = false;
    var isAbsoluteAndNotRootRelative = false;

    for (var part in parts.where((part) => part != '')) {
      if (this.isRootRelative(part) && isAbsoluteAndNotRootRelative) {
        // If the new part is root-relative, it preserves the previous root but
        // replaces the path after it.
        var oldRoot = this.rootPrefix(buffer.toString());
        buffer.clear();
        buffer.write(oldRoot);
        buffer.write(part);
      } else if (this.isAbsolute(part)) {
        isAbsoluteAndNotRootRelative = !this.isRootRelative(part);
        // An absolute path discards everything before it.
        buffer.clear();
        buffer.write(part);
      } else {
        if (part.length > 0 && part[0].contains(style.separatorPattern)) {
          // The part starts with a separator, so we don't need to add one.
        } else if (needsSeparator) {
          buffer.write(separator);
        }

        buffer.write(part);
      }

      // Unless this part ends with a separator, we'll need to add one before
      // the next part.
      needsSeparator = part.contains(style.needsSeparatorPattern);
    }

    return buffer.toString();
  }

  // TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
  /// Splits [path] into its components using the current platform's
  /// [separator]. Example:
  ///
  ///     builder.split('path/to/foo'); // -> ['path', 'to', 'foo']
  ///
  /// The path will *not* be normalized before splitting.
  ///
  ///     builder.split('path/../foo'); // -> ['path', '..', 'foo']
  ///
  /// If [path] is absolute, the root directory will be the first element in the
  /// array. Example:
  ///
  ///     // Unix
  ///     builder.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']
  ///
  ///     // Windows
  ///     builder.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']
  List<String> split(String path) {
    var parsed = _parse(path);
    // Filter out empty parts that exist due to multiple separators in a row.
    parsed.parts = parsed.parts.where((part) => !part.isEmpty)
                               .toList();
    if (parsed.root != null) parsed.parts.insert(0, parsed.root);
    return parsed.parts;
  }

  /// Normalizes [path], simplifying it by handling `..`, and `.`, and
  /// removing redundant path separators whenever possible.
  ///
  ///     builder.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
  String normalize(String path) {
    var parsed = _parse(path);
    parsed.normalize();
    return parsed.toString();
  }

  /// Creates a new path by appending the given path parts to the [root].
  /// Equivalent to [join()] with [root] as the first argument. Example:
  ///
  ///     var builder = new Builder(root: 'root');
  ///     builder.resolve('path', 'to', 'foo'); // -> 'root/path/to/foo'
  String resolve(String part1, [String part2, String part3, String part4,
              String part5, String part6, String part7]) {
    return join(root, part1, part2, part3, part4, part5, part6, part7);
  }

  /// Attempts to convert [path] to an equivalent relative path relative to
  /// [root].
  ///
  ///     var builder = new Builder(root: '/root/path');
  ///     builder.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
  ///     builder.relative('/root/other.dart'); // -> '../other.dart'
  ///
  /// If the [from] argument is passed, [path] is made relative to that instead.
  ///
  ///     builder.relative('/root/path/a/b.dart',
  ///         from: '/root/path'); // -> 'a/b.dart'
  ///     builder.relative('/root/other.dart',
  ///         from: '/root/path'); // -> '../other.dart'
  ///
  /// If [path] and/or [from] are relative paths, they are assumed to be
  /// relative to [root].
  ///
  /// Since there is no relative path from one drive letter to another on
  /// Windows, this will return an absolute path in that case.
  ///
  ///     builder.relative(r'D:\other', from: r'C:\other'); // -> 'D:\other'
  ///
  /// This will also return an absolute path if an absolute [path] is passed to
  /// a builder with a relative [root].
  ///
  ///     var builder = new Builder(r'some/relative/path');
  ///     builder.relative(r'/absolute/path'); // -> '/absolute/path'
  String relative(String path, {String from}) {
    from = from == null ? root : this.join(root, from);

    // We can't determine the path from a relative path to an absolute path.
    if (this.isRelative(from) && this.isAbsolute(path)) {
      return this.normalize(path);
    }

    // If the given path is relative, resolve it relative to the root of the
    // builder.
    if (this.isRelative(path) || this.isRootRelative(path)) {
      path = this.resolve(path);
    }

    // If the path is still relative and `from` is absolute, we're unable to
    // find a path from `from` to `path`.
    if (this.isRelative(path) && this.isAbsolute(from)) {
      throw new ArgumentError('Unable to find a path to "$path" from "$from".');
    }

    var fromParsed = _parse(from)..normalize();
    var pathParsed = _parse(path)..normalize();

    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '.') {
      return pathParsed.toString();
    }

    // If the root prefixes don't match (for example, different drive letters
    // on Windows), then there is no relative path, so just return the absolute
    // one. In Windows, drive letters are case-insenstive and we allow
    // calculation of relative paths, even if a path has not been normalized.
    if (fromParsed.root != pathParsed.root &&
        ((fromParsed.root ==  null || pathParsed.root == null) ||
          fromParsed.root.toLowerCase().replaceAll('/', '\\') !=
          pathParsed.root.toLowerCase().replaceAll('/', '\\'))) {
      return pathParsed.toString();
    }

    // Strip off their common prefix.
    while (fromParsed.parts.length > 0 && pathParsed.parts.length > 0 &&
           fromParsed.parts[0] == pathParsed.parts[0]) {
      fromParsed.parts.removeAt(0);
      fromParsed.separators.removeAt(1);
      pathParsed.parts.removeAt(0);
      pathParsed.separators.removeAt(1);
    }

    // If there are any directories left in the from path, we need to walk up
    // out of them. If a directory left in the from path is '..', it cannot
    // be cancelled by adding a '..'.
    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '..') {
      throw new ArgumentError('Unable to find a path to "$path" from "$from".');
    }
    _growListFront(pathParsed.parts, fromParsed.parts.length, '..');
    pathParsed.separators[0] = '';
    pathParsed.separators.insertAll(1,
        new List.filled(fromParsed.parts.length, style.separator));

    // Corner case: the paths completely collapsed.
    if (pathParsed.parts.length == 0) return '.';

    // Corner case: path was '.' and some '..' directories were added in front.
    // Don't add a final '/.' in that case.
    if (pathParsed.parts.length > 1 && pathParsed.parts.last == '.') {
      pathParsed.parts.removeLast();
      pathParsed.separators..removeLast()..removeLast()..add('');
    }

    // Make it relative.
    pathParsed.root = '';
    pathParsed.removeTrailingSeparators();

    return pathParsed.toString();
  }

  /// Removes a trailing extension from the last part of [path].
  ///
  ///     builder.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
  String withoutExtension(String path) {
    var parsed = _parse(path);

    for (var i = parsed.parts.length - 1; i >= 0; i--) {
      if (!parsed.parts[i].isEmpty) {
        parsed.parts[i] = parsed.basenameWithoutExtension;
        break;
      }
    }

    return parsed.toString();
  }

  /// Returns the path represented by [uri].
  ///
  /// For POSIX and Windows styles, [uri] must be a `file:` URI. For the URL
  /// style, this will just convert [uri] to a string.
  ///
  ///     // POSIX
  ///     builder.fromUri(Uri.parse('file:///path/to/foo'))
  ///       // -> '/path/to/foo'
  ///
  ///     // Windows
  ///     builder.fromUri(Uri.parse('file:///C:/path/to/foo'))
  ///       // -> r'C:\path\to\foo'
  ///
  ///     // URL
  ///     builder.fromUri(Uri.parse('http://dartlang.org/path/to/foo'))
  ///       // -> 'http://dartlang.org/path/to/foo'
  String fromUri(Uri uri) => style.pathFromUri(uri);

  /// Returns the URI that represents [path].
  ///
  /// For POSIX and Windows styles, this will return a `file:` URI. For the URL
  /// style, this will just convert [path] to a [Uri].
  ///
  ///     // POSIX
  ///     builder.toUri('/path/to/foo')
  ///       // -> Uri.parse('file:///path/to/foo')
  ///
  ///     // Windows
  ///     builder.toUri(r'C:\path\to\foo')
  ///       // -> Uri.parse('file:///C:/path/to/foo')
  ///
  ///     // URL
  ///     builder.toUri('http://dartlang.org/path/to/foo')
  ///       // -> Uri.parse('http://dartlang.org/path/to/foo')
  Uri toUri(String path) {
    if (isRelative(path)) {
      return style.relativePathToUri(path);
    } else {
      return style.absolutePathToUri(join(root, path));
    }
  }

  _ParsedPath _parse(String path) {
    var before = path;

    // Remove the root prefix, if any.
    var root = style.getRoot(path);
    var isRootRelative = style.getRelativeRoot(path) != null;
    if (root != null) path = path.substring(root.length);

    // Split the parts on path separators.
    var parts = [];
    var separators = [];

    var firstSeparator = style.separatorPattern.matchAsPrefix(path);
    if (firstSeparator != null) {
      separators.add(firstSeparator[0]);
      path = path.substring(firstSeparator[0].length);
    } else {
      separators.add('');
    }

    var start = 0;
    for (var match in style.separatorPattern.allMatches(path)) {
      parts.add(path.substring(start, match.start));
      separators.add(match[0]);
      start = match.end;
    }

    // Add the final part, if any.
    if (start < path.length) {
      parts.add(path.substring(start));
      separators.add('');
    }

    return new _ParsedPath(style, root, isRootRelative, parts, separators);
  }
}

/// An enum type describing a "flavor" of path.
abstract class Style {
  /// POSIX-style paths use "/" (forward slash) as separators. Absolute paths
  /// start with "/". Used by UNIX, Linux, Mac OS X, and others.
  static final posix = new _PosixStyle();

  /// Windows paths use "\" (backslash) as separators. Absolute paths start with
  /// a drive letter followed by a colon (example, "C:") or two backslashes
  /// ("\\") for UNC paths.
  // TODO(rnystrom): The UNC root prefix should include the drive name too, not
  // just the "\\".
  static final windows = new _WindowsStyle();

  /// URLs aren't filesystem paths, but they're supported to make it easier to
  /// manipulate URL paths in the browser.
  ///
  /// URLs use "/" (forward slash) as separators. Absolute paths either start
  /// with a protocol and optional hostname (e.g. `http://dartlang.org`,
  /// `file://`) or with "/".
  static final url = new _UrlStyle();

  /// The style of the host platform.
  ///
  /// When running on the command line, this will be [windows] or [posix] based
  /// on the host operating system. On a browser, this will be [url].
  static final platform = _getPlatformStyle();

  /// Gets the type of the host platform.
  static Style _getPlatformStyle() {
    if (_io == null) return Style.url;

    if ((_io.declarations[#Platform] as ClassMirror).getField(#operatingSystem)
        .reflectee == 'windows') {
      return Style.windows;
    }

    return Style.posix;
  }

  /// The name of this path style. Will be "posix" or "windows".
  String get name;

  /// The path separator for this style. On POSIX, this is `/`. On Windows,
  /// it's `\`.
  String get separator;

  /// The [Pattern] that can be used to match a separator for a path in this
  /// style. Windows allows both "/" and "\" as path separators even though "\"
  /// is the canonical one.
  Pattern get separatorPattern;

  /// The [Pattern] that matches path components that need a separator after
  /// them.
  ///
  /// Windows and POSIX styles just need separators when the previous component
  /// doesn't already end in a separator, but the URL always needs to place a
  /// separator between the root and the first component, even if the root
  /// already ends in a separator character. For example, to join "file://" and
  /// "usr", an additional "/" is needed (making "file:///usr").
  Pattern get needsSeparatorPattern;

  /// The [Pattern] that can be used to match the root prefix of an absolute
  /// path in this style.
  Pattern get rootPattern;

  /// The [Pattern] that can be used to match the root prefix of a root-relative
  /// path in this style.
  ///
  /// This can be null to indicate that this style doesn't support root-relative
  /// paths.
  final Pattern relativeRootPattern = null;

  /// A [Builder] that uses this style.
  Builder get builder => new Builder(style: this);

  /// Gets the root prefix of [path] if path is absolute. If [path] is relative,
  /// returns `null`.
  String getRoot(String path) {
    // TODO(rnystrom): Use firstMatch() when #7080 is fixed.
    var matches = rootPattern.allMatches(path);
    if (matches.isNotEmpty) return matches.first[0];
    return getRelativeRoot(path);
  }

  /// Gets the root prefix of [path] if it's root-relative.
  ///
  /// If [path] is relative or absolute and not root-relative, returns `null`.
  String getRelativeRoot(String path) {
    if (relativeRootPattern == null) return null;
    // TODO(rnystrom): Use firstMatch() when #7080 is fixed.
    var matches = relativeRootPattern.allMatches(path);
    if (matches.isEmpty) return null;
    return matches.first[0];
  }

  /// Returns the path represented by [uri] in this style.
  String pathFromUri(Uri uri);

  /// Returns the URI that represents the relative path made of [parts].
  Uri relativePathToUri(String path) =>
      new Uri(pathSegments: builder.split(path));

  /// Returns the URI that represents [path], which is assumed to be absolute.
  Uri absolutePathToUri(String path);

  String toString() => name;
}

/// The style for POSIX paths.
class _PosixStyle extends Style {
  _PosixStyle();

  final name = 'posix';
  final separator = '/';
  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(r'[^/]$');
  final rootPattern = new RegExp(r'^/');

  String pathFromUri(Uri uri) {
    if (uri.scheme == '' || uri.scheme == 'file') {
      return Uri.decodeComponent(uri.path);
    }
    throw new ArgumentError("Uri $uri must have scheme 'file:'.");
  }

  Uri absolutePathToUri(String path) {
    var parsed = builder._parse(path);
    if (parsed.parts.isEmpty) {
      // If the path is a bare root (e.g. "/"), [components] will
      // currently be empty. We add two empty components so the URL constructor
      // produces "file:///", with a trailing slash.
      parsed.parts.addAll(["", ""]);
    } else if (parsed.hasTrailingSeparator) {
      // If the path has a trailing slash, add a single empty component so the
      // URI has a trailing slash as well.
      parsed.parts.add("");
    }

    return new Uri(scheme: 'file', pathSegments: parsed.parts);
  }
}

/// The style for Windows paths.
class _WindowsStyle extends Style {
  _WindowsStyle();

  final name = 'windows';
  final separator = '\\';
  final separatorPattern = new RegExp(r'[/\\]');
  final needsSeparatorPattern = new RegExp(r'[^/\\]$');
  final rootPattern = new RegExp(r'^(\\\\|[a-zA-Z]:[/\\])');

  String pathFromUri(Uri uri) {
    if (uri.scheme != '' && uri.scheme != 'file') {
      throw new ArgumentError("Uri $uri must have scheme 'file:'.");
    }

    var path = uri.path;
    if (uri.host == '') {
      // Drive-letter paths look like "file:///C:/path/to/file". The
      // replaceFirst removes the extra initial slash.
      if (path.startsWith('/')) path = path.replaceFirst("/", "");
    } else {
      // Network paths look like "file://hostname/path/to/file".
      path = '\\\\${uri.host}$path';
    }
    return Uri.decodeComponent(path.replaceAll("/", "\\"));
  }

  Uri absolutePathToUri(String path) {
    var parsed = builder._parse(path);
    if (parsed.root == r'\\') {
      // Network paths become "file://hostname/path/to/file".

      var host = parsed.parts.removeAt(0);

      if (parsed.parts.isEmpty) {
        // If the path is a bare root (e.g. "\\hostname"), [parsed.parts] will
        // currently be empty. We add two empty components so the URL
        // constructor produces "file://hostname/", with a trailing slash.
        parsed.parts.addAll(["", ""]);
      } else if (parsed.hasTrailingSeparator) {
        // If the path has a trailing slash, add a single empty component so the
        // URI has a trailing slash as well.
        parsed.parts.add("");
      }

      return new Uri(scheme: 'file', host: host, pathSegments: parsed.parts);
    } else {
      // Drive-letter paths become "file:///C:/path/to/file".

      // If the path is a bare root (e.g. "C:\"), [parsed.parts] will currently
      // be empty. We add an empty component so the URL constructor produces
      // "file:///C:/", with a trailing slash. We also add an empty component if
      // the URL otherwise has a trailing slash.
      if (parsed.parts.length == 0 || parsed.hasTrailingSeparator) {
        parsed.parts.add("");
      }

      // Get rid of the trailing "\" in "C:\" because the URI constructor will
      // add a separator on its own.
      parsed.parts.insert(0, parsed.root.replaceAll(separatorPattern, ""));

      return new Uri(scheme: 'file', pathSegments: parsed.parts);
    }
  }
}

/// The style for URL paths.
class _UrlStyle extends Style {
  _UrlStyle();

  final name = 'url';
  final separator = '/';
  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(
      r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");
  final rootPattern = new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");
  final relativeRootPattern = new RegExp(r"^/");

  String pathFromUri(Uri uri) => uri.toString();

  Uri relativePathToUri(String path) => Uri.parse(path);
  Uri absolutePathToUri(String path) => Uri.parse(path);
}

// TODO(rnystrom): Make this public?
class _ParsedPath {
  /// The [Style] that was used to parse this path.
  Style style;

  /// The absolute root portion of the path, or `null` if the path is relative.
  /// On POSIX systems, this will be `null` or "/". On Windows, it can be
  /// `null`, "//" for a UNC path, or something like "C:\" for paths with drive
  /// letters.
  String root;

  /// Whether this path is root-relative.
  ///
  /// See [Builder.isRootRelative].
  bool isRootRelative;

  /// The path-separated parts of the path. All but the last will be
  /// directories.
  List<String> parts;

  /// The path separators preceding each part.
  ///
  /// The first one will be an empty string unless the root requires a separator
  /// between it and the path. The last one will be an empty string unless the
  /// path ends with a trailing separator.
  List<String> separators;

  /// The file extension of the last non-empty part, or "" if it doesn't have
  /// one.
  String get extension => _splitExtension()[1];

  /// `true` if this is an absolute path.
  bool get isAbsolute => root != null;

  _ParsedPath(this.style, this.root, this.isRootRelative, this.parts,
      this.separators);

  String get basename {
    var copy = this.clone();
    copy.removeTrailingSeparators();
    if (copy.parts.isEmpty) return root == null ? '' : root;
    return copy.parts.last;
  }

  String get basenameWithoutExtension => _splitExtension()[0];

  bool get hasTrailingSeparator =>
      !parts.isEmpty && (parts.last == '' || separators.last != '');

  void removeTrailingSeparators() {
    while (!parts.isEmpty && parts.last == '') {
      parts.removeLast();
      separators.removeLast();
    }
    if (separators.length > 0) separators[separators.length - 1] = '';
  }

  void normalize() {
    // Handle '.', '..', and empty parts.
    var leadingDoubles = 0;
    var newParts = [];
    for (var part in parts) {
      if (part == '.' || part == '') {
        // Do nothing. Ignore it.
      } else if (part == '..') {
        // Pop the last part off.
        if (newParts.length > 0) {
          newParts.removeLast();
        } else {
          // Backed out past the beginning, so preserve the "..".
          leadingDoubles++;
        }
      } else {
        newParts.add(part);
      }
    }

    // A relative path can back out from the start directory.
    if (!isAbsolute) {
      _growListFront(newParts, leadingDoubles, '..');
    }

    // If we collapsed down to nothing, do ".".
    if (newParts.length == 0 && !isAbsolute) {
      newParts.add('.');
    }

    // Canonicalize separators.
    var newSeparators = new List.generate(
        newParts.length, (_) => style.separator, growable: true);
    newSeparators.insert(0,
        isAbsolute && newParts.length > 0 &&
                root.contains(style.needsSeparatorPattern) ?
            style.separator : '');

    parts = newParts;
    separators = newSeparators;

    // Normalize the Windows root if needed.
    if (root != null && style == Style.windows) {
      root = root.replaceAll('/', '\\');
    }
    removeTrailingSeparators();
  }

  String toString() {
    var builder = new StringBuffer();
    if (root != null) builder.write(root);
    for (var i = 0; i < parts.length; i++) {
      builder.write(separators[i]);
      builder.write(parts[i]);
    }
    builder.write(separators.last);

    return builder.toString();
  }

  /// Splits the last non-empty part of the path into a `[basename, extension`]
  /// pair.
  ///
  /// Returns a two-element list. The first is the name of the file without any
  /// extension. The second is the extension or "" if it has none.
  List<String> _splitExtension() {
    var file = parts.lastWhere((p) => p != '', orElse: () => null);

    if (file == null) return ['', ''];
    if (file == '..') return ['..', ''];

    var lastDot = file.lastIndexOf('.');

    // If there is no dot, or it's the first character, like '.bashrc', it
    // doesn't count.
    if (lastDot <= 0) return [file, ''];

    return [file.substring(0, lastDot), file.substring(lastDot)];
  }

  _ParsedPath clone() => new _ParsedPath(
      style, root, isRootRelative,
      new List.from(parts), new List.from(separators));
}
