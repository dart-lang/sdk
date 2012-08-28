// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Long term, it would probably be better if we do not use
// executable code to define the locations of libraries.

#library('library_map');
#import('../../../lib/_internal/libraries.dart', prefix: "libs");

/**
 * Simple structure providing the path to a library and an optional path
 * to a patch file for the library.
 */
class LibraryInfo {
  final libs.LibraryInfo info;
  const LibraryInfo(this.info);

  String get libraryPath() {
    String libPath = info.dart2jsPath;
    if (libPath === null) libPath = info.path;
    return "lib/$libPath";
  }

  String get patchPath() {
    if (info.dart2jsPatchPath === null) return null;
    return "lib/${info.dart2jsPatchPath}";
  }

  bool get isInternal => info.category === "Internal";
}

class Dart2JSLibraryMap {
  const Dart2JSLibraryMap();

  LibraryInfo operator[](String dartName) {
    libs.LibraryInfo info = libs.LIBRARIES[dartName];
    if (info === null) return null;
    if (!info.isDart2JsLibrary()) {
      // Dart2js can't handle internal libraries for other backends.
      return null;
    }
    return new LibraryInfo(info);
  }
}

final Dart2JSLibraryMap DART2JS_LIBRARY_MAP = const Dart2JSLibraryMap();
