// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The names of the `dart:` libraries that make up deprecated JS interop.
///
/// Web compilers can disallow these libraries (for example via
/// `--no-deprecated-js-interop`) by considering them unsupported. The CFE then
/// reports imports of them with a message describing how to migrate away from
/// them, instead of the generic message for unavailable libraries.
const Set<String> deprecatedJsInteropLibraryNames = {
  'html',
  'html_common',
  'indexed_db',
  'js',
  'js_util',
  'svg',
  'web_audio',
  'web_gl',
};
