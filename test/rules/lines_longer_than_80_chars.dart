// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N lines_longer_than_80_chars`

var short = 'This is a short line'; // OK
var line80 =
    '                                                                   '; // OK
var line81 =
    '                                                                  '; // LINT
var long =
    'This line is a long, very long, very very long, very very very long, very very very very long'; // LINT

var uriIsOk =
    'https://dart.dev/guides/language/effective-dart/style#avoid-lines-longer-than-80-characters'; // OK

var posixPathIsOk =
    '/home/dart.dev/guides/language/effective-dart/style#avoid-lines-longer-than-80-characters'; // OK

var windowsPathIsOk =
    r'C:\home\dart.dev\guides\language\effective-dart\style\avoid-lines-longer-than-80-characters'; // OK

var multilinesOK = '''
This line is a long, very long, very very long, very very very long, very very very very long
''';

var interpolated = 'this $uriIsOk that';

var line80EndingWithCRLF =
    '                                                                   '; // OK
