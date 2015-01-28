library ddc.src.codegen.code_generator;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart' show CompilationUnit;
import 'package:path/path.dart' as path;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/report.dart';
import 'package:ddc/src/checker/rules.dart';

abstract class CodeGenerator {
  final String outDir;
  final Uri root;
  final TypeRules rules;

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
  }();

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

  String _getOutputDirectory(LibraryInfo info, CompilationUnit unit) {
    var uri = unit.element.source.uri.toString();
    String suffix;
    if (uri.startsWith('dart:') || _searchPaths == null) {
      // Use the library name as the directory.
      suffix = info.name;
    } else {
      // Recover the original search path and use the relative path
      // from there as the directory.
      // TODO(vsm): Is there a better way to get the resolved path?
      var resolvedPath = unit.element.toString();
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
    suffix = _convertIfPackage(suffix);
    var fileDir = path.join(outDir, suffix);
    var dir = new Directory(fileDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return fileDir;
  }

  CodeGenerator(String outDir, this.root, this.rules)
      : outDir = path.absolute(outDir);

  // TODO(jmesserly): JS generates per library outputs, so it does not use this
  // method and instead overrides generateLibrary.
  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
  }

  void generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info,
      CheckerReporter reporter) {
    for (var unit in units) {
      var outputDir = _getOutputDirectory(info, unit);
      reporter.enterSource(unit.element.source);
      generateUnit(unit, info, outputDir);
      reporter.leaveSource();
    }
  }
}
