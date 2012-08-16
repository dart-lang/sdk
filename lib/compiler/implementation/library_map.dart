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
class LibraryInfo {
  final String libraryPath;
  final String patchPath;

  /** If [:true:], the library is not part of the public API. */
  final bool isInternal;

  const LibraryInfo(this.libraryPath,
                    [this.patchPath = null, this.isInternal = false]);
}

/**
 * Specifies the location of Dart platform libraries.
 */
final Map<String, LibraryInfo> DART2JS_LIBRARY_MAP
    = const <String, LibraryInfo> {
  "core": const LibraryInfo(
      "lib/compiler/implementation/lib/core.dart"),
  "coreimpl": const LibraryInfo(
      "lib/compiler/implementation/lib/coreimpl.dart",
      "lib/compiler/implementation/lib/coreimpl_patch.dart"),
  "_js_helper": const LibraryInfo(
      "lib/compiler/implementation/lib/js_helper.dart", isInternal: true),
  "_interceptors": const LibraryInfo(
      "lib/compiler/implementation/lib/interceptors.dart", isInternal: true),
  "crypto": const LibraryInfo(
      "lib/crypto/crypto.dart"),
  "dom_deprecated": const LibraryInfo(
      "lib/dom/dart2js/dom_dart2js.dart", isInternal: true),
  "html": const LibraryInfo(
      "lib/html/dart2js/html_dart2js.dart"),
  "io": const LibraryInfo(
      "lib/compiler/implementation/lib/io.dart"),
  "isolate": const LibraryInfo(
      "lib/isolate/isolate_dart2js.dart"),
  "json": const LibraryInfo("lib/json/json.dart"),
  "math": const LibraryInfo(
      "lib/math/math.dart",
      "lib/compiler/implementation/lib/math_patch.dart", isInternal: true),
  "uri": const LibraryInfo("lib/uri/uri.dart"),
  "utf": const LibraryInfo("lib/utf/utf.dart"),
  "web": const LibraryInfo("lib/web/web.dart"),
};
