// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Long term, it would probably be better if we do not use
// executable code to define the locations of libraries.

#library('library_map');
/**
 * Simple struct holding the path to a library and an optional path
 * to a patch file for the library.
 */
class LibraryPatchPath {
  final String libraryPath;
  final String patchPath;
  const LibraryPatchPath(this.libraryPath, this.patchPath);
}

/**
 * Specifies the location of Dart platform libraries.
 */
final Map<String,LibraryPatchPath> DART2JS_LIBRARY_MAP
    = const <LibraryPatchPath> {
  "core": const LibraryPatchPath(
      "lib/compiler/implementation/lib/core.dart", null),
  "coreimpl": const LibraryPatchPath(
      "lib/compiler/implementation/lib/coreimpl.dart", null),
  "_js_helper": const LibraryPatchPath(
      "lib/compiler/implementation/lib/js_helper.dart", null),
  "_interceptors": const LibraryPatchPath(
      "lib/compiler/implementation/lib/interceptors.dart", null),
  "crypto": const LibraryPatchPath(
      "lib/crypto/crypto.dart", null),
  "dom_deprecated": const LibraryPatchPath(
      "lib/dom/frog/dom_frog.dart", null),
  "html": const LibraryPatchPath(
      "lib/html/frog/html_frog.dart", null),
  "io": const LibraryPatchPath(
      "lib/compiler/implementation/lib/io.dart", null),
  "isolate": const LibraryPatchPath(
      "lib/isolate/isolate_leg.dart", null),
  "json": const LibraryPatchPath(
      "lib/json/json.dart", null),
  "math": const LibraryPatchPath(
      "lib/math/math.dart",
      "lib/compiler/implementation/lib/math.dartp"),
  "uri": const LibraryPatchPath(
      "lib/uri/uri.dart", null),
  "utf": const LibraryPatchPath(
      "lib/utf/utf.dart", null),
  "web": const LibraryPatchPath(
      "lib/web/web.dart", null),
};
