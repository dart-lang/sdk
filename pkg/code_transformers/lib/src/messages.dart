// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains all warning messages produced by the code_transformers package.
library code_transformers.src.messages;

import 'package:code_transformers/messages/messages.dart';

const NO_ABSOLUTE_PATHS = const MessageTemplate(
    const MessageId('code_transformers', 1),
    'absolute paths not allowed: "%-url-%"',
    'Absolute paths not allowed',
    '''
The transformers processing your code were trying to resolve a URL and identify
a file that they correspond to. Currently only relative paths can be resolved.
''');

const INVALID_URL_TO_OTHER_PACKAGE = const MessageTemplate(
    const MessageId('code_transformers', 2),
    'Invalid URL to reach to another package: %-url-%. Path '
    'reaching to other packages must first reach up all the '
    'way to the %-prefix-% directory. For example, try changing the URL '
    'to: %-fixedUrl-%',
    'Invalid URL to reach another package',
    '''
To reach an asset that belongs to another package, use `package:` URLs in
Dart code, but in any other language (like HTML or CSS) use relative URLs.

These are the rules you must follow to write URLs that refer to files in other
packages:

  * If the file containing the relative URL is an entrypoint under `web`, use
    `packages/package_name/path_to_file`

  * If the file containing the URL is under `web`, but in a different directory
    than your entrypoint, walk out to the same level as the entrypoint first,
    then enter the `packages` directory.

    **Note**: If two entrypoints include the file under `web` containing the
    URL, either both entrypoints have to live in the same directory, or you need
    to move the file to the `lib` directory.

  * If the file containing the URL lives under `lib`, walk up as many levels as
    directories you have + 1. This is because code in `lib/a/b` is loaded from
    `packages/package_name/a/b`.

The rules are easier to follow if you know how the code is laid out for
Dartium before you build, and how it is laid out after you build it with `pub
build`. Consider the following example:

   package a
      lib/
        |- a1.html

      web/
        |- a2.html

   package b
      lib/
        |- b1.html
        |- b2/
            |- b3.html

   package c
      lib/
        |- c3.html

      web/
        |- index.html
        |- index.dart
        |- c1/
            |- c2.html

If your app is package `c`, then `pub get` generates a packages directory under
the web directory, like this:

      web/
        |- index.html
        |- index.dart
        |- c1/
        |   |- c2.html
        |- packages/
            |- a/
            |   |- a1.html
            |- b/
            |   |- b1.html
            |   |- b2/
            |       |- b3.html
            |- c/
                |- c3.html

Note that no `lib` directory is under the `packages` directory.
When you launch `web/index.html` in Dartium, Dartium loads `package:` imports from
`web/packages/`.

If you need to refer to any file in other packages from `index.html`, you can
simply do `packages/package_name/path_to_file`. For example
`packages/b/b2/b3.html`. From `index.html` you can also refer to files under the
web directory of the same package using a simple relative URL, like
`c1/c2.html`.

However, if you want to load `a1.html` from `c2.html`, you need to reach out to
the packages directory that lives next to your entrypoint and then load the file
from there, for example `../packages/a/a1.html`. Because pub generates symlinks
to the packages directory also under c1, you may be tempted to write
`packages/a/a1.html`, but that is incorrect - it would yield a canonicalization
error (see more below).

If you want to load a file from the lib directory of your own package, you
should also use a package URL. For example, `packages/c/c3.html` and not
`../lib/c3.html`. This will allow you to write code in `lib` in a way that it
can be used within and outside your package without making any changes to it.

Because any time you reach inside a `lib/` directory you do so using a
`packages/` URL, the rules for reaching into other files in other packages are
always consistent: go up to exit the `packages` directory and go back inside to
the file you are looking for.  For example, to reach `a1.html` from `b3.html`
you need to write `../../../packages/a/a1.html`.

The motivation behind all these rules is that URLs need to work under many
scenarios at once:

  * They need to work in Dartium without any code transformation: resolving the
    path in the context of a simple HTTP server, or using `file:///` URLs,
    should yield a valid path to assets. The `packages` directory is safe to use
    because pub already creates it next to entrypoints of your application.

  * They need to be canonical. To take advantage of caching, multiple URLs
    reaching the same asset should resolve to the same absolute URL.
    
    Also, in projects that use HTML imports (like polymer) tools support that
    you reach a library with either Dart imports or HTML imports, and correctly
    resolve them to be the same library. The rules are designed to allow tools
    to support this.

    For example, consider you have an import might like:

        <link rel=import href=packages/a/a.html>

    where a.html has `<script type="application/dart" src="a.dart">`. If your
    Dart entrypoint also loads `"package:a/a.dart"`,  then a tool need to make
    sure that both versions of `a.dart` are loaded from the same URL. Otherwise,
    you may see errors at runtime like: `A is not a subtype of A`, which can be
    extremely confusing.

    When you follow the rules above, our tools can detect the pattern in the
    HTML-import URL containing `packages/` and canonicalize the import
    by converting `packages/a/a.dart` into `package:a/a.dart` under the hood.

  * They need to continue to be valid after applications are built.
    Technically this could be done automatically with pub transformers, but to
    make sure that code works also in Dartium with a simple HTTP Server,
    existing transformers do not fix URLs, they just detect inconsistencies and
    produce an error message like this one, instead.
''');

const INVALID_PREFIX_PATH = const MessageTemplate(
    const MessageId('code_transformers', 3),
    'incomplete %-prefix-%/ path. It should have at least 3 '
    'segments %-prefix-%/name/path_from_name\'s_%-folder-%_dir',
    'Incomplete URL to asset in another package',
    '''
URLs that refer to assets in other packages need to explicitly mention the
`packages/` directory. In the future this requirement might be removed, but for
now you must use a canonical URL form for it.

For example, if `packages/a/a.html` needs to import `packages/b/b.html`,
you might expect a.html to import `../b/b.html`. Instead, it must import
`../../packages/b/b.html`.
See [issue 15797](http://dartbug.com/15797).
''');
