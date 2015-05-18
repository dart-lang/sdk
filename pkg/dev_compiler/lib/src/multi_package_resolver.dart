// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.multi_package_resolver;

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' show join;

/// A package resolver that supports a non-standard package layout, where
/// packages with dotted names are expanded to a hierarchy of directories, and
/// packages can be found on one or more locations.
class MultiPackageResolver extends UriResolver {
  final List<String> searchPaths;
  MultiPackageResolver(this.searchPaths);

  @override
  Source resolveAbsolute(Uri uri) {
    var path = _expandPath(uri);
    if (path == null) return null;

    var resolvedPath = _resolve(path);
    if (resolvedPath == null) return null;

    return new FileBasedSource.con2(uri, new JavaFile(resolvedPath));
  }

  /// Resolve [path] by looking at each prefix in [searchPaths] and returning
  /// the first location where `prefix + path` exists.
  String _resolve(String path) {
    for (var prefix in searchPaths) {
      var resolvedPath = join(prefix, path);
      if (new File(resolvedPath).existsSync()) return resolvedPath;
    }
    return null;
  }

  /// Expand `uri.path`, replacing dots in the package name with slashes.
  String _expandPath(Uri uri) {
    if (uri.scheme != 'package') return null;
    var path = uri.path;
    var slashPos = path.indexOf('/');
    var packagePath = path.substring(0, slashPos).replaceAll(".", "/");
    var filePath = path.substring(slashPos + 1);
    return '${packagePath}/lib/${filePath}';
  }
}
