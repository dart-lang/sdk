// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library uses the Dart analyzer to find the exports for a set of
/// libraries. It stores these exports in an [ExportMap]. This is used to
/// display exported members as part of the exporting library, since dart2js
/// doesn't provide this information itself.
library export_map;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as pathos;

import 'dartdoc/utils.dart';

/// A class that tracks which libraries export which other libraries.
class ExportMap {
  /// A map from libraries to their [Export]s.
  ///
  /// Each key is the absolute path of a library on the filesystem, and each
  /// value is a list of [Export]s for that library. There's guaranteed to be
  /// only one [Export] of a given library in a given list.
  final Map<String, List<Export>> exports;

  /// A cache of the transitive exports for each library. The keys are paths to
  /// libraries. The values are maps from the exported path to the [Export]
  /// objects, to make it easier to merge multiple exports of the same library.
  final _transitiveExportsByPath = <String, Map<String, Export>>{};

  /// Parse an export map from a set of [libraries], which should be Dart import
  /// [Uri]s. [packageRoot] should be the path to the `packages` directory to
  /// use when resolving `package:` imports and libraries. Libraries that are
  /// not available on the local machine will be ignored.
  ///
  /// In addition to parsing the exports in [libraries], this will parse the
  /// exports in all libraries transitively reachable from [libraries] via
  /// `import` or `export`.
  factory ExportMap.parse(Iterable<Uri> libraries, String packageRoot) {
    var exports = <String, List<Export>>{};

    void traverse(String path) {
      if (exports.containsKey(path)) return;

      var importsAndExports;
      try {
        importsAndExports = _importsAndExportsForFile(path, packageRoot);
      } on FileSystemException catch (_) {
        // Ignore unreadable/nonexistent files.
        return;
      }

      var exportsForLibrary = <String, Export>{};
      for (var export in importsAndExports.last) {
        addOrMergeExport(exportsForLibrary, export.path, export);
      }
      exports[path] = new List.from(exportsForLibrary.values);
      exports[path].map((directive) => directive.path).forEach(traverse);
      importsAndExports.first.forEach(traverse);
    }

    for (var library in libraries) {
      var path = importUriToPath(library, packageRoot: packageRoot);
      if (path != null) traverse(path);
    }

    return new ExportMap._(exports);
  }

  ExportMap._(this.exports);

  /// Returns a list of all the paths of exported libraries that [this] is aware
  /// of.
  List<String> get allExportedFiles => exports.values.expand((e) => e)
      .map((directive) => directive.path).toList();

  /// Returns a list of all exports that [library] transitively exports. This
  /// means that if [library] exports another library that in turn exports a
  /// third, the third library will be included in the returned list.
  ///
  /// This will automatically handle nested `hide` and `show` directives on the
  /// exports, as well as merging multiple exports of the same library.
  List<Export> transitiveExports(String library) {
    Map<String, Export> _getTransitiveExportsByPath(String path) {
      if (_transitiveExportsByPath.containsKey(path)) {
        return _transitiveExportsByPath[path];
      }

      var exportsByPath = <String, Export>{};
      _transitiveExportsByPath[path] = exportsByPath;
      if (exports[path] == null) return exportsByPath;

      for (var export in exports[path]) {
        exportsByPath[export.path] = export;
      }

      for (var export in exports[path]) {
        for (var subExport in _getTransitiveExportsByPath(export.path).values) {
          subExport = export.compose(subExport);
          if (exportsByPath.containsKey(subExport.path)) {
            subExport = subExport.merge(exportsByPath[subExport.path]);
          }
          exportsByPath[subExport.path] = subExport;
        }
      }
      return exportsByPath;
    }

    var path = pathos.normalize(pathos.absolute(library));
    return _getTransitiveExportsByPath(path).values.toList();
  }
}

/// A class that represents one library exporting another.
class Export {
  /// The absolute path of the library that contains this export.
  final String exporter;

  /// The absolute path of the library being exported.
  final String path;

  /// The set of identifiers that are explicitly being exported. If this is
  /// non-empty, no identifiers other than these will be visible.
  ///
  /// One or both of [show] and [hide] will always be empty.
  Set<String> get show => _show;
  Set<String> _show;

  /// The set of identifiers that are not exported.
  ///
  /// One or both of [show] and [hide] will always be empty.
  Set<String> get hide => _hide;
  Set<String> _hide;

  /// Whether or not members exported are hidden by default.
  bool get _hideByDefault => !show.isEmpty;

  /// Creates a new export.
  ///
  /// This will normalize [show] and [hide] so that if both are non-empty, only
  /// [show] will be set.
  Export(this.exporter, this.path, {Iterable<String> show,
      Iterable<String> hide}) {
    _show = new Set<String>.from(show == null ? [] : show);
    _hide = new Set<String>.from(hide == null ? [] : hide);

    if (!_show.isEmpty) {
      _show.removeAll(_hide);
      _hide = new Set<String>();
    }
  }

  /// Returns a new [Export] that represents [this] composed with [nested], as
  /// though [this] was used to export a library that in turn exported [nested].
  Export compose(Export nested) {
    var show = new Set<String>();
    var hide = new Set<String>();

    if (this._hideByDefault) {
      show.addAll(this.show);
      if (nested._hideByDefault) {
        show.retainAll(nested.show);
      } else {
        show.removeAll(nested.hide);
      }
    } else if (nested._hideByDefault) {
      show.addAll(nested.show);
      show.removeAll(this.hide);
    } else {
      hide.addAll(this.hide);
      hide.addAll(nested.hide);
    }

    return new Export(this.exporter, nested.path, show: show, hide: hide);
  }

  /// Returns a new [Export] that merges [this] with [nested], as though both
  /// exports were included in the same library.
  ///
  /// [this] and [other] must have the same values for [exporter] and [path].
  Export merge(Export other) {
    if (this.path != other.path) {
      throw new ArgumentError("Can't merge two Exports with different paths: "
          "export '$path' from '$exporter' and export '${other.path}' from "
          "'${other.exporter}'.");
    } if (this.exporter != other.exporter) {
      throw new ArgumentError("Can't merge two Exports with different "
          "exporters: export '$path' from '$exporter' and export "
          "'${other.path}' from '${other.exporter}'.");
    }

    var show = new Set<String>();
    var hide = new Set<String>();

    if (this._hideByDefault) {
      if (other._hideByDefault) {
        show.addAll(this.show);
        show.addAll(other.show);
      } else {
        hide.addAll(other.hide);
        hide.removeAll(this.show);
      }
    } else {
      hide.addAll(this.hide);
      if (other._hideByDefault) {
        hide.removeAll(other.show);
      } else {
        hide.retainAll(other.hide);
      }
    }

    return new Export(exporter, path, show: show, hide: hide);
  }

  /// Returns whether or not a member named [name] is visible through this
  /// import, as goverend by [show] and [hide].
  bool isMemberVisible(String name) =>
    _hideByDefault ? show.contains(name) : !hide.contains(name);

  bool operator==(other) => other is Export && other.exporter == exporter &&
      other.path == path && show.containsAll(other.show) &&
      other.show.containsAll(show) && hide.containsAll(other.hide) &&
      other.hide.containsAll(hide);

  int get hashCode {
    var hashCode = exporter.hashCode ^ path.hashCode;
    hashCode = show.reduce(hashCode, (hash, name) => hash ^ name.hashCode);
    return hide.reduce(hashCode, (hash, name) => hash ^ name.hashCode);
  }

  String toString() {
    var combinator = '';
    if (!show.isEmpty) {
      combinator = ' show ${show.join(', ')}';
    } else if (!hide.isEmpty) {
      combinator = ' hide ${hide.join(', ')}';
    }
    return "export '$path'$combinator (from $exporter)";
  }
}

/// Returns a list of imports and a list of exports for the dart library at
/// [file]. [packageRoot] is used to resolve `package:` URLs.
///
/// The imports are a list of absolute paths, while the exports are [Export]
/// objects.
Pair<List<String>, List<Export>> _importsAndExportsForFile(String file,
    String packageRoot) {
  var collector = new _ImportExportCollector();
  parseDartFile(file).accept(collector);

  var imports = collector.imports.map((import) {
    return _pathForDirective(import, pathos.dirname(file), packageRoot);
  }).where((import) => import != null).toList();

  var exports = collector.exports.map((export) {
    var path = _pathForDirective(export, pathos.dirname(file), packageRoot);
    if (path == null) return null;

    path = pathos.normalize(pathos.absolute(path));
    var show = export.combinators
        .where((combinator) => combinator is ShowCombinator)
        .expand((combinator) => combinator.shownNames.map((name) => name.name));
    var hide = export.combinators
        .where((combinator) => combinator is HideCombinator)
        .expand((combinator) =>
            combinator.hiddenNames.map((name) => name.name));

    return new Export(file, path, show: show, hide: hide);
  }).where((export) => export != null).toList();

  return new Pair<List<String>, List<Export>>(imports, exports);
}

/// Returns the absolute path to the library imported by [directive], or `null`
/// if it doesn't refer to a file on the local filesystem.
///
/// [basePath] is the path from which relative imports should be resolved.
/// [packageRoot] is the path from which `package:` imports should be resolved.
String _pathForDirective(NamespaceDirective directive, String basePath,
    String packageRoot) {
  var uri = Uri.parse(stringLiteralToString(directive.uri));
  var path = importUriToPath(uri, basePath: basePath, packageRoot: packageRoot);
  if (path == null) return null;
  return pathos.normalize(pathos.absolute(path));
}

/// A simple visitor that collects import and export nodes.
class _ImportExportCollector extends GeneralizingASTVisitor {
  final imports = <ImportDirective>[];
  final exports = <ExportDirective>[];

  _ImportExportCollector();

  visitImportDirective(ImportDirective node) => imports.add(node);
  visitExportDirective(ExportDirective node) => exports.add(node);
}
