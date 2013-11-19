A comprehensive, cross-platform path manipulation library for Dart.

The path package provides common operations for manipulating paths:
joining, splitting, normalizing, etc.

We've tried very hard to make this library do the "right" thing on whatever
platform you run it on, including in the browser. When you use the top-level
functions, it will assume the current platform's path style and work with
that. If you want to explicitly work with paths of a specific style, you can
construct a `path.Context` for that style.

## Using

The path library was designed to be imported with a prefix, though you don't
have to if you don't want to:

    import 'package:path/path.dart' as path;

The most common way to use the library is through the top-level functions.
These manipulate path strings based on your current working directory and
the path style (POSIX, Windows, or URLs) of the host platform. For example:

    path.join("directory", "file.txt");

This calls the top-level [join] function to join "directory" and
"file.txt" using the current platform's directory separator.

If you want to work with paths for a specific platform regardless of the
underlying platform that the program is running on, you can create a
[Context] and give it an explicit [Style]:

    var context = new path.Context(style: Style.windows);
    context.join("directory", "file.txt");

This will join "directory" and "file.txt" using the Windows path separator,
even when the program is run on a POSIX machine.

## FAQ

### Where can I use this?

Pathos runs on the Dart VM and in the browser under both dart2js and Dartium.
Under dart2js, it currently returns "." as the current working directory, while
under Dartium it returns the current URL.

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
    expect it?

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

### What is a "path" in the browser?

If you use this package in a browser, then it considers the "platform" to be
the browser itself and uses URL strings to represent "browser paths".
