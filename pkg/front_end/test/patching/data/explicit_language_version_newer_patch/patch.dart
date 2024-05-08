// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*error: message=The language version override has to be the same in the library and its patch(es).*/ // @dart=%VERSION_MARKER1%

// ignore: import_internal_library
import 'dart:_internal';

@patch
/*member: method:patch*/
int method(int? i) => i!;
