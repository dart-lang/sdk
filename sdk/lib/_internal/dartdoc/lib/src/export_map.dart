// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library uses the Dart analyzer to find the exports for a set of
/// libraries. It stores these exports in an [ExportMap]. This is used to
/// display exported members as part of the exporting library, since dart2js
/// doesn't provide this information itself.
library export_map;

import '../../../compiler/implementation/mirrors/mirrors.dart';
import '../../../compiler/implementation/mirrors/mirrors_util.dart';

/// A class that tracks which libraries export which other libraries.
class ExportMap {
  /// A map from libraries to their [Export]s.
  ///
  /// Each key is a library and each value is a list of [Export]s for that
  /// library. There's guaranteed to be only one [Export] of a given library
  /// in a given list.
  final Map<LibraryMirror, List<Export>> exports = {};

  /// A cache of the transitive exports for each library. The values are maps
  /// from the exported libraries to the [Export] objects, to make it easier to
  /// merge multiple exports of the same library.
  Map<LibraryMirror, Map<LibraryMirror, Export>> _transitiveExports = {};

  ExportMap(MirrorSystem mirrors) {
    mirrors.libraries.values.where((lib) => !_isDartLibrary(lib))
                            .forEach(_computeExports);
  }

  bool _isDartLibrary(LibraryMirror lib) => lib.uri.scheme == 'dart';

  /// Compute all non-dart: exports in [library].
  void _computeExports(LibraryMirror library) {
    var exportMap = {};
    library.libraryDependencies
        .where((mirror) =>
            mirror.isExport && !_isDartLibrary(mirror.targetLibrary))
        .map((mirror) => new Export.fromMirror(mirror))
        .forEach((export) {
      var target = export.exported;
      if (exportMap.containsKey(target)) {
        exportMap[target] = exportMap[target].merge(export);
      } else {
        exportMap[target] = export;
      }
    });
    exports[library] = exportMap.values.toList();
  }

  /// Returns a list of all exports that [library] transitively exports. This
  /// means that if [library] exports another library that in turn exports a
  /// third, the third library will be included in the returned list.
  ///
  /// This will automatically handle nested `hide` and `show` directives on the
  /// exports, as well as merging multiple exports of the same library.
  List<Export> transitiveExports(LibraryMirror library) {
    Map<LibraryMirror, Export> _getTransitiveExports(LibraryMirror library) {
      if (_transitiveExports.containsKey(library)) {
        return _transitiveExports[library];
      }

      var exportsByPath = <LibraryMirror, Export>{};
      _transitiveExports[library] = exportsByPath;
      if (exports[library] == null) return exportsByPath;

      for (var export in exports[library]) {
        exportsByPath[export.exported] = export;
      }

      for (var export in exports[library]) {
        for (var subExport in _getTransitiveExports(export.exported).values) {
          subExport = export.compose(subExport);
          if (exportsByPath.containsKey(subExport.exported)) {
            subExport = subExport.merge(exportsByPath[subExport.exported]);
          }
          exportsByPath[subExport.exported] = subExport;
        }
      }
      return exportsByPath;
    }

    return _getTransitiveExports(library).values.toList();
  }
}

/// A class that represents one library exporting another.
class Export {
  /// The library that contains this export.
  final LibraryMirror exporter;

  /// The library being exported.
  final LibraryMirror exported;

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
  factory Export.fromMirror(LibraryDependencyMirror mirror) {
    var show = <String>[];
    var hide = <String>[];
    for (var combinator in mirror.combinators) {
      if (combinator.isShow) {
        show.addAll(combinator.identifiers);
      }
      if (combinator.isHide) {
        hide.addAll(combinator.identifiers);
      }
    }
    return new Export(
        mirror.sourceLibrary, mirror.targetLibrary, show: show, hide: hide);
  }

  Export(this.exporter, this.exported,
         {Iterable<String> show, Iterable<String> hide}) {
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

    return new Export(this.exporter, nested.exported, show: show, hide: hide);
  }

  /// Returns a new [Export] that merges [this] with [nested], as though both
  /// exports were included in the same library.
  ///
  /// [this] and [other] must have the same values for [exporter] and [path].
  Export merge(Export other) {
    if (this.exported != other.exported) {
      throw new ArgumentError("Can't merge two Exports with different paths: "
          "export '$exported' from '$exporter' and export '${other.exported}' "
          "from '${other.exporter}'.");
    } if (this.exporter != other.exporter) {
      throw new ArgumentError("Can't merge two Exports with different "
          "exporters: export '$exported' from '$exporter' and export "
          "'${other.exported}' from '${other.exporter}'.");
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

    return new Export(exporter, exported, show: show, hide: hide);
  }

  /// Returns whether or not a member named [name] is visible through this
  /// import, as goverend by [show] and [hide].
  bool isMemberVisible(String name) =>
    _hideByDefault ? show.contains(name) : !hide.contains(name);

  bool operator==(other) => other is Export && other.exporter == exporter &&
      other.exported == exported && show.containsAll(other.show) &&
      other.show.containsAll(show) && hide.containsAll(other.hide) &&
      other.hide.containsAll(hide);

  int get hashCode {
    var hashCode = exporter.hashCode ^ exported.hashCode;
    combineHashCode(name) => hashCode ^= name.hashCode;
    show.forEach(combineHashCode);
    hide.forEach(combineHashCode);
    return hashCode;
  }

  String toString() {
    var combinator = '';
    if (!show.isEmpty) {
      combinator = ' show ${show.join(', ')}';
    } else if (!hide.isEmpty) {
      combinator = ' hide ${hide.join(', ')}';
    }
    return "export '${displayName(exported)}'"
           "$combinator (from ${displayName(exporter)})";
  }
}
