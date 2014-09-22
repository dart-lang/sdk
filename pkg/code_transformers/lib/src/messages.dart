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
Dart code, but in any other language (like HTML or CSS) use relative URLs that
first go all the way to the `packages/` directory.

The rules for correctly writing these imports are subtle and have a lot of
special cases. Please review
<https://www.dartlang.org/polymer/app-directories.html> to learn
more.
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

See [issue 15797](http://dartbug.com/15797) and
<https://www.dartlang.org/polymer/app-directories.html> to learn more.
''');
