// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An object that can map the file paths of analyzed files to the file paths of
/// the HTML files used to view the content of those files.
class PathMapper {
  /// A table mapping the file paths of analyzed files to the file paths of the
  /// HTML files used to view the content of those files.
  final Map<String, String> pathMap = {};

  /// Initialize a newly created path mapper.
  PathMapper();

  /// Return the path of the HTML file used to view the content of the analyzed
  /// file with the given [path].
  String map(String path) {
    return pathMap[path] ?? path;
  }
}
