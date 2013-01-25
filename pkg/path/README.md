A comprehensive, cross-platform path manipulation library for Dart.

The pathos library provides common operations for manipulating file paths:
joining, splitting, normalizing, etc.

We've tried very hard to make this library do the "right" thing on whatever
platform you run it on. When you use the top-level functions, it will assume
the host OS's path style and work with that. If you want to specifically work
with paths of a specific style, you can construct a `path.Builder` for that
style.

## Using

The path library was designed to be imported with a prefix, though you don't
have to if you don't want to:

    import 'package:pathos/path.dart' as path;

## Top-level functions

The most common way to use the library is through the top-level functions.
These manipulate path strings based on your current working directory and the
path style (POSIX or Windows) of the host operating system.

### String get current

Gets the path to the current working directory.

### String get separator

Gets the path separator for the current platform. On Mac and Linux, this
is `/`. On Windows, it's `\`.

### String absolute(String path)

Converts [path] to an absolute path by resolving it relative to the current
working directory. If [path] is already an absolute path, just returns it.

    path.absolute('foo/bar.txt'); // -> /your/current/dir/foo/bar.txt

### String basename(String path)

Gets the part of [path] after the last separator.

    path.basename('path/to/foo.dart'); // -> 'foo.dart'
    path.basename('path/to');          // -> 'to'

Trailing separators are ignored.

    builder.basename('path/to/'); // -> 'to'

### String basenameWithoutExtension(String path)

Gets the part of [path] after the last separator, and without any trailing
file extension.

    path.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'

Trailing separators are ignored.

    builder.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'

### String dirname(String path)

Gets the part of [path] before the last separator.

    path.dirname('path/to/foo.dart'); // -> 'path/to'
    path.dirname('path/to');          // -> 'to'

Trailing separators are ignored.

    builder.dirname('path/to/'); // -> 'path'

### String extension(String path)

Gets the file extension of [path]: the portion of [basename] from the last
`.` to the end (including the `.` itself).

    path.extension('path/to/foo.dart');    // -> '.dart'
    path.extension('path/to/foo');         // -> ''
    path.extension('path.to/foo');         // -> ''
    path.extension('path/to/foo.dart.js'); // -> '.js'

If the file name starts with a `.`, then that is not considered the
extension:

    path.extension('~/.bashrc');    // -> ''
    path.extension('~/.notes.txt'); // -> '.txt'

### String rootPrefix(String path)

Returns the root of [path], if it's absolute, or the empty string if it's
relative.

    // Unix
    path.rootPrefix('path/to/foo'); // -> ''
    path.rootPrefix('/path/to/foo'); // -> '/'

    // Windows
    path.rootPrefix(r'path\to\foo'); // -> ''
    path.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'

### bool isAbsolute(String path)

Returns `true` if [path] is an absolute path and `false` if it is a
relative path. On POSIX systems, absolute paths start with a `/` (forward
slash). On Windows, an absolute path starts with `\\`, or a drive letter
followed by `:/` or `:\`.

### bool isRelative(String path)

Returns `true` if [path] is a relative path and `false` if it is absolute.
On POSIX systems, absolute paths start with a `/` (forward slash). On
Windows, an absolute path starts with `\\`, or a drive letter followed by
`:/` or `:\`.

### String join(String part1, [String part2, String part3, ...])

Joins the given path parts into a single path using the current platform's
[separator]. Example:

    path.join('path', 'to', 'foo'); // -> 'path/to/foo'

If any part ends in a path separator, then a redundant separator will not
be added:

    path.join('path/', 'to', 'foo'); // -> 'path/to/foo

If a part is an absolute path, then anything before that will be ignored:

    path.join('path', '/to', 'foo'); // -> '/to/foo'

### List<String> split(String path)

Splits [path] into its components using the current platform's [separator].

    path.split('path/to/foo'); // -> ['path', 'to', 'foo']

The path will *not* be normalized before splitting.

    path.split('path/../foo'); // -> ['path', '..', 'foo']

If [path] is absolute, the root directory will be the first element in the
array. Example:

    // Unix
    path.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']

    // Windows
    path.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']

### String normalize(String path)

Normalizes [path], simplifying it by handling `..`, and `.`, and
removing redundant path separators whenever possible.

    path.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
String normalize(String path) => _builder.normalize(path);

### String relative(String path, {String from})

Attempts to convert [path] to an equivalent relative path from the current
directory.

    // Given current directory is /root/path:
    path.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
    path.relative('/root/other.dart'); // -> '../other.dart'

If the [from] argument is passed, [path] is made relative to that instead.

    path.relative('/root/path/a/b.dart',
        from: '/root/path'); // -> 'a/b.dart'
    path.relative('/root/other.dart',
        from: '/root/path'); // -> '../other.dart'

Since there is no relative path from one drive letter to another on Windows,
this will return an absolute path in that case.

    path.relative(r'D:\other', from: r'C:\home'); // -> 'D:\other'

### String withoutExtension(String path)

Removes a trailing extension from the last part of [path].

    withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'

## The path.Builder class

In addition to the functions, path exposes a `path.Builder` class. This lets
you configure the root directory and path style that paths are built using
explicitly instead of assuming the current working directory and host OS's path
style.

You won't often use this, but it can be useful if you do a lot of path
manipulation relative to some root directory.

    var builder = new path.Builder(root: '/other/root');
    builder.relative('/other/root/foo.txt'); // -> 'foo.txt'

It exposes the same methods and getters as the top-level functions, with the
addition of:

### new Builder({Style style, String root})

Creates a new path builder for the given style and root directory.

If [style] is omitted, it uses the host operating system's path style. If
[root] is omitted, it defaults to the current working directory. If [root]
is relative, it is considered relative to the current working directory.

### Style style

The style of path that this builder works with.

### String root

The root directory that relative paths will be relative to.

### String get separator

Gets the path separator for the builder's [style]. On Mac and Linux,
this is `/`. On Windows, it's `\`.

### String rootPrefix(String path)

Returns the root of [path], if it's absolute, or an empty string if it's
relative.

    // Unix
    builder.rootPrefix('path/to/foo'); // -> ''
    builder.rootPrefix('/path/to/foo'); // -> '/'

    // Windows
    builder.rootPrefix(r'path\to\foo'); // -> ''
    builder.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'

### String resolve(String part1, [String part2, String part3, ...])

Creates a new path by appending the given path parts to the [root].
Equivalent to [join()] with [root] as the first argument. Example:

    var builder = new Builder(root: 'root');
    builder.resolve('path', 'to', 'foo'); // -> 'root/path/to/foo'

## The path.Style class

The path library can work with two different "flavors" of path: POSIX and
Windows. The differences between these are encapsulated by the `path.Style`
enum class. There are two instances of it:

### path.Style.posix

POSIX-style paths use "/" (forward slash) as separators. Absolute paths
start with "/". Used by UNIX, Linux, Mac OS X, and others.

### path.Style.windows

Windows paths use "\" (backslash) as separators. Absolute paths start with
a drive letter followed by a colon (example, "C:") or two backslashes
("\\") for UNC paths.

## FAQ

### Where can I use this?

Currently, Dart has no way of encapsulating configuration-specific code.
Ideally, this library would be able to import dart:io when that's available or
dart:html when that is. That would let it seamlessly work on both.

Until then, this only works on the standalone VM. It's API is not coupled to
dart:io, but it uses it internally to determine the current working directory.

### Why doesn't this make paths first-class objects?

When you have path *objects*, then every API that takes a path has to decide if
it accepts strings, path objects, or both.

 *  Accepting strings is the most convenient, but then it seems weird to have
    these path objects that aren't actually accepted by anything that needs a
    path. Once you've created a path, you have to always call `.toString()` on
    it before you can do anything useful with it.

 *  Requiring objects forces users to wrap path strings in these objects, which
    is tedious. It also means coupling that API to whatever library defines this
    path class. If there are multiple "path" libraries that each define their
    own path types, then any library that works with paths has to pick which one
    it uses.

 *  Taking both means you can't type your API. That defeats the purpose of
    having a path type: why have a type if your APIs can't annotate that they
    use it?

Given that, we've decided this library should simply treat paths as strings.

### How cross-platform is this?

We believe this library handles most of the corner cases of Windows paths
(POSIX paths are generally pretty straightforward):

 *  It understands that *both* "/" and "\" are valid path separators, not just
    "\".

 *  It can accurately tell if a path is absolute based on drive-letters or UNC
    prefix.

 *  It understands that "/foo" is not an absolute path on Windows.

 *  It knows that "C:\foo\one.txt" and "c:/foo\two.txt" are two files in the
    same directory.

If you find a problem, surprise or something that's unclear, please don't
hesitate to [file a bug](http://dartbug.com/new) and let us know.
