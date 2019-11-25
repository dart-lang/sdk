// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as path;

/// An object that can map the file paths of analyzed files to the file paths of
/// the HTML files used to view the content of those files.
class PathMapper {
  /// The resource provider used to map paths.
  ResourceProvider provider;

  /// The absolute path of the folder that should contain all of the generated
  /// HTML files.
  final String outputFolder;

  /// The root of the package containing the files being migrated.
  final String packageRoot;

  /// A table mapping the file paths of analyzed files to the file paths of the
  /// HTML files used to view the content of those files.
  final Map<String, String> pathMap = {};

  /// The index to be used when creating the next synthetic file name.
  int nextIndex = 1;

  /// Initialize a newly created path mapper.
  PathMapper(this.provider, this.outputFolder, this.packageRoot);

  /// Return the path of the HTML file used to view the content of the analyzed
  /// file with the given [path].
  String map(String path) {
    return pathMap.putIfAbsent(path, () => _computePathFor(path));
  }

  /// Return the path of the HTML file corresponding to the Dart file with the
  /// given [path].
  String _computePathFor(String filePath) {
    path.Context context = provider.pathContext;
    if (context.isWithin(packageRoot, filePath)) {
      String packageParent = context.dirname(packageRoot);
      String relative = context.relative(filePath, from: packageParent);
      return context.join(
          outputFolder, context.setExtension(relative, '.html'));
    }
    // TODO(brianwilkerson) Find a better mapping algorithm, that would produce
    //  a more readable URI. For example, have other packages and the sdk be
    //  parallel to the directory containing the files for the library being
    //  migrated.
    return context.join(outputFolder, 'aux', 'f${nextIndex++}.html');
  }
}
