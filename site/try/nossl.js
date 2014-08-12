// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

try {
  document.location = 'https://try.dartlang.org/';
} catch (e) {
  // Ignored.
}

document.documentElement.innerHTML = (
'<head>' +
'<meta charset="utf-8">' +
'<meta http-equiv="refresh" content="0;URL=\'https://try.dartlang.org/\'" />' +
'<title>Redirecting</title>' +
'</head>' +
'<body>' +
'<p>This page has moved to <a href="https://try.dartlang.org/">https://try.dartlang.org/</a>.</p>' +
'</body>');
