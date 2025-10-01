// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All three libraries have an HttpRequest class.
export "conditional_export_lib4.dart"
    if (dart.library.io) "dart:io"
    if (dart.library.html) "dart:html";
