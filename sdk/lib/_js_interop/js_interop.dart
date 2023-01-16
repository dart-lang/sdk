// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// JS interop library meant to be used with inline classes. See
// https://dart.dev/web/js-interop for more details on how to use JS interop.

// Export the `dart:_js_annotations` version of the `@JS` annotation. This is
// mostly identical to the `package:js` version, except this is meant to be used
// for sound top-level external members and inline classes instead of the
// `package:js` classes.
export 'dart:_js_annotations' show JS;
