// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/element.dart'
    show CompilationUnitElement, LibraryElement;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:path/path.dart' as path;

import '../compiler.dart' show AbstractCompiler;
import '../info.dart';
import '../utils.dart' show canonicalLibraryName;
import '../options.dart' show CodegenOptions;

abstract class CodeGenerator {
  final AbstractCompiler compiler;
  final AnalysisContext context;
  final CodegenOptions options;

  CodeGenerator(AbstractCompiler compiler)
      : compiler = compiler,
        context = compiler.context,
        options = compiler.options.codegenOptions;

  /// Return a hash, if any, that can be used for caching purposes. When two
  /// invocations to this function return the same hash, the underlying
  /// code-generator generated the same code.
  String generateLibrary(LibraryUnit unit);

  static List<String> _searchPaths = () {
    // TODO(vsm): Can we remove redundancy with multi_package_resolver logic?
    var packagePaths =
        new String.fromEnvironment('package_paths', defaultValue: null);
    if (packagePaths == null) return null;
    var list = packagePaths.split(',');
    // Normalize the paths.
    list = new List<String>.from(list.map(_dirToPrefix));
    // The current directory is implicitly in the search path.
    list.add(_dirToPrefix(path.current));
    // Sort by reverse length to prefer longer prefixes.
    // This ensures that we get the minimum valid suffix.  E.g., if we have:
    // - root/
    // - root/generated/
    // in our search path, and the path "root/generated/foo/bar.dart", we'll
    // compute "foo/bar.dart" instead of "generated/foo/bar.dart" in the search
    // below.
    list.sort((s1, s2) => s2.length - s1.length);
    return list;
  }() as List<String>;

  static String _dirToPrefix(String dir) {
    dir = path.absolute(dir);
    dir = path.normalize(dir);
    if (!dir.endsWith(path.separator)) {
      dir = dir + path.separator;
    }
    return dir;
  }

  static String _convertIfPackage(String dir) {
    assert(path.isRelative(dir));
    var parts = path.split(dir);
    var index = parts.indexOf('lib');
    if (index < 0) {
      // Not a package.
      return dir;
    }
    // This is a package.
    // Convert: foo/bar/lib/baz/hi
    // to: packages/foo.bar/baz/hi
    var packageName = parts.sublist(0, index).join('.');
    var prefix = path.join('packages', packageName);
    var suffix = path.joinAll(parts.sublist(index + 1));
    return path.join(prefix, suffix);
  }

  static String _getOutputDirectory(
      String name, CompilationUnitElement unitElement) {
    var uri = unitElement.source.uri.toString();
    String suffix;
    if (uri.startsWith('dart:') || _searchPaths == null) {
      // Use the library name as the directory.
      suffix = name;
    } else if (uri.startsWith('package:')) {
      suffix = uri.replaceFirst('package:', 'packages/');
      suffix = path.dirname(suffix);
    } else {
      // Recover the original search path and use the relative path
      // from there as the directory.
      // TODO(vsm): Is there a better way to get the resolved path?
      var resolvedPath = unitElement.toString();
      var resolvedDir = path.dirname(resolvedPath);
      for (var prefix in _searchPaths) {
        if (resolvedDir.startsWith(prefix)) {
          suffix = resolvedDir.substring(prefix.length);
          break;
        }
      }
    }
    assert(suffix != null);
    assert(path.isRelative(suffix));
    return _convertIfPackage(suffix);
  }

  static Uri uriFor(LibraryElement lib) {
    var unitElement = lib.definingCompilationUnit;
    var uri = unitElement.source.uri;
    if (uri.scheme == 'dart') return uri;
    if (uri.scheme == 'package') return uri;
    var suffix = _getOutputDirectory(canonicalLibraryName(lib), unitElement);
    suffix = path.join(suffix, uri.pathSegments.last);
    var parts = path.split(suffix);
    var index = parts.indexOf('packages');
    if (index < 0) {
      // Not a package.
      // TODO(leafp) These may need to be adjusted
      // relative to the import location
      return new Uri(path: suffix);
    }
    assert(index == 0);
    return new Uri(
        scheme: 'package', path: path.joinAll(parts.sublist(index + 1)));
  }
}
