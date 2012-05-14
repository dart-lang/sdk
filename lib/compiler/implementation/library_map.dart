// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Long term, it would probably be better if we do not use
// executable code to define the locations of libraries.

#library('library_map');

/**
 * Specifies the location of Dart platform libraries.
 */
final Map<String,String> DART2JS_LIBRARY_MAP = const <String> {
  "core": "lib/compiler/implementation/lib/core.dart",
  "coreimpl": "lib/compiler/implementation/lib/coreimpl.dart",
  "_js_helper": "lib/compiler/implementation/lib/js_helper.dart",
  "_interceptors": "lib/compiler/implementation/lib/interceptors.dart",
  "crypto": "lib/crypto/crypto.dart",
  "dom_deprecated": "lib/dom/frog/dom_frog.dart",
  "html": "lib/html/frog/html_frog.dart",
  "io": "lib/compiler/implementation/lib/io.dart",
  "isolate": "lib/isolate/isolate_leg.dart",
  "json": "lib/json/json.dart",
  "uri": "lib/uri/uri.dart",
  "utf": "lib/utf/utf.dart",
};
