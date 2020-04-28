// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// An object that can map the file paths of analyzed files to the file paths of
/// the HTML files used to view the content of those files.
class PathMapper {
  /// The resource provider used to map paths.
  ResourceProvider provider;

  /// The index to be used when creating the next synthetic file name.
  int nextIndex = 1;

  /// Initialize a newly created path mapper.
  PathMapper(this.provider);

  /// Return the path of the HTML file used to view the content of the analyzed
  /// file with the given [path].
  String map(String path) {
    return Uri.file(path).path;
  }
}
