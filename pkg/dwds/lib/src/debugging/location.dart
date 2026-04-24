// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/parser.dart';
import 'package:source_maps/source_maps.dart';

var _startTokenId = 1337;

/// A source location, with both Dart and JS information.
class Location {
  final JsLocation jsLocation;

  final DartLocation dartLocation;

  /// An arbitrary integer value used to represent this location.
  final int tokenPos;

  Location._(this.jsLocation, this.dartLocation) : tokenPos = _startTokenId++;

  static Location from(
    String module,
    TargetLineEntry lineEntry,
    TargetEntry entry,
    DartUri dartUri,
    String? runtimeScriptId,
  ) {
    final dartLine = entry.sourceLine;
    final dartColumn = entry.sourceColumn;
    final jsLine = lineEntry.line;
    final jsColumn = entry.column;

    // lineEntry data is 0 based according to:
    // https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k
    return Location._(
      JsLocation.fromZeroBased(module, jsLine, jsColumn, runtimeScriptId),
      DartLocation.fromZeroBased(dartUri, dartLine ?? 0, dartColumn ?? 0),
    );
  }

  @override
  String toString() => '$dartLocation -> $jsLocation';
}

/// Location information for a Dart source.
class DartLocation {
  final DartUri uri;

  /// 1 based row offset within the Dart source code.
  final int line;

  /// 1 based column offset within the Dart source code.
  final int column;

  DartLocation._(this.uri, this.line, this.column);

  int compareTo(DartLocation other) => compareToLine(other.line, other.column);

  int compareToLine(int otherLine, int otherColumn) {
    final result = line.compareTo(otherLine);
    return result == 0 ? column.compareTo(otherColumn) : result;
  }

  @override
  int get hashCode => Object.hashAll([uri, line, column]);

  @override
  bool operator ==(Object other) {
    if (other is! DartLocation) {
      return false;
    }
    return uri.serverPath == other.uri.serverPath &&
        line == other.line &&
        column == other.column;
  }

  @override
  String toString() => '[${uri.serverPath}:$line:$column]';

  factory DartLocation.fromZeroBased(DartUri uri, int line, int column) =>
      DartLocation._(uri, line + 1, column + 1);
}

/// Location information for a JS source.
class JsLocation {
  final String module;

  /// 0 based row offset within the JS source code.
  final int line;

  /// 0 based column offset within the JS source code.
  final int column;

  /// The Runtime.ScriptId of a script in Chrome.
  ///
  /// See https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-ScriptId
  String? runtimeScriptId;

  JsLocation._(this.module, this.line, this.column, this.runtimeScriptId);

  int compareTo(JsLocation other) => compareToLine(other.line, other.column);

  int compareToLine(int otherLine, int otherColumn) {
    final result = line.compareTo(otherLine);
    return result == 0 ? column.compareTo(otherColumn) : result;
  }

  @override
  String toString() => '[$module:$line:$column]';

  // JS Location is 0 based according to:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger#type-Location
  factory JsLocation.fromZeroBased(
    String module,
    int line,
    int column,
    String? runtimeScriptId,
  ) => JsLocation._(module, line, column, runtimeScriptId);
}

/// Contains meta data for known [Location]s.
class Locations {
  final _logger = Logger('Locations');

  /// [Location] data for Dart server path.
  final Map<String, Set<Location>> _sourceToLocation = {};
  final Map<String, AsyncMemoizer<Set<Location>>> _locationMemoizer = {};

  /// `tokenPosTable` for Dart server path, as defined in the
  /// Dart VM Service Protocol:
  /// https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#script
  final Map<String, List<List<int>>> _sourceToTokenPosTable = {};

  /// The set of all known [Location]s for a module.
  final Map<String, Set<Location>> _moduleToLocations = {};

  final AssetReader _assetReader;
  final Modules _modules;
  final String _root;

  late String _entrypoint;

  Locations(this._assetReader, this._modules, this._root);

  Modules get modules => _modules;

  /// Initialize any caches.
  ///
  /// If [modifiedModuleReport] is not null, only invalidates the caches for the
  /// modified modules instead.
  Future<void> initialize(
    String entrypoint, {
    ModifiedModuleReport? modifiedModuleReport,
  }) async {
    // If we know that only certain modules are deleted or added, we can only
    // invalidate those.
    if (modifiedModuleReport != null) {
      for (final module in modifiedModuleReport.modifiedModules) {
        _locationMemoizer.remove(module);
        _moduleToLocations.remove(module);
        final sources = await _modules.sourcesForModule(module);
        if (sources != null) {
          for (final serverPath in sources) {
            _sourceToTokenPosTable.remove(serverPath);
            _sourceToLocation.remove(serverPath);
          }
        }
      }
      return;
    }
    _locationMemoizer.clear();
    _moduleToLocations.clear();
    _sourceToTokenPosTable.clear();
    _sourceToLocation.clear();
    _entrypoint = entrypoint;
  }

  /// Returns all [Location] data for a provided Dart source.
  Future<Set<Location>> locationsForDart(String serverPath) async {
    final module = await _modules.moduleForSource(serverPath);
    if (module == null) {
      _logger.warning('No module for server path $serverPath');
    } else {
      await _locationsForModule(module);
    }
    return _sourceToLocation[serverPath] ?? {};
  }

  /// Returns all [Location] data for a provided JS server path.
  Future<Set<Location>> locationsForUrl(String url) async {
    if (url.isEmpty) return {};

    final dartUri = DartUri(url, _root);
    final serverPath = dartUri.serverPath;
    final module = await globalToolConfiguration.loadStrategy
        .moduleForServerPath(_entrypoint, serverPath);

    final cache = _moduleToLocations[module];
    if (cache != null) return cache;
    if (module != null) {
      await _locationsForModule(module);
    }
    return _moduleToLocations[module] ?? {};
  }

  /// Find the [Location] for the given Dart source position.
  ///
  /// The [line] number is 1-based.
  Future<Location?> locationForDart(DartUri uri, int line, int column) async {
    final locations = await locationsForDart(uri.serverPath);
    return _bestDartLocation(locations, line, column);
  }

  /// Find the [Location] for the given JS source position.
  ///
  /// The [line] number is 0-based.
  Future<Location?> locationForJs(String url, int line, int? column) async {
    final locations = await locationsForUrl(url);
    return _bestJsLocation(locations, line, column);
  }

  /// Find closest existing Dart location for the line and column.
  ///
  /// Dart columns for breakpoints are either exact or start at the
  /// beginning of the line - return the first existing location
  /// that comes after the given column.
  Location? _bestDartLocation(
    Iterable<Location> locations,
    int line,
    int column,
  ) {
    Location? bestLocation;
    for (final location in locations) {
      if (location.dartLocation.line == line &&
          location.dartLocation.column >= column) {
        bestLocation ??= location;
        if (location.dartLocation.compareTo(bestLocation.dartLocation) < 0) {
          bestLocation = location;
        }
      }
    }
    return bestLocation;
  }

  /// Find closest existing JavaScript location for the line and column.
  ///
  /// Some JS locations are not stored in the source maps, so we find the
  /// closest existing location coming before the given column.
  ///
  /// This is a known problem that other code bases solve using by finding
  /// the closest location to the current one:
  ///
  /// https://github.com/microsoft/vscode-js-debug/blob/536f96bae61a3d87546b61bc7916097904c81429/src/common/sourceUtils.ts#L286
  Location? _bestJsLocation(
    Iterable<Location> locations,
    int line,
    int? column,
  ) {
    column ??= 0;
    Location? bestLocation;
    for (final location in locations) {
      if (location.jsLocation.compareToLine(line, column) <= 0) {
        bestLocation ??= location;
        if (location.jsLocation.compareTo(bestLocation.jsLocation) > 0) {
          bestLocation = location;
        }
      }
    }
    return bestLocation;
  }

  /// Returns the tokenPosTable for the provided Dart script path as defined
  /// in:
  /// https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#script
  Future<List<List<int>>> tokenPosTableFor(String serverPath) async {
    var tokenPosTable = _sourceToTokenPosTable[serverPath];
    if (tokenPosTable != null) return tokenPosTable;
    // Construct the tokenPosTable which is of the form:
    // [lineNumber, (tokenId, columnNumber)*]
    tokenPosTable = <List<int>>[];
    final locations = await locationsForDart(serverPath);
    final lineNumberToLocation = <int, Set<Location>>{};
    for (final location in locations) {
      lineNumberToLocation
          .putIfAbsent(location.dartLocation.line, () => <Location>{})
          .add(location);
    }
    for (final lineNumber in lineNumberToLocation.keys) {
      final locations = lineNumberToLocation[lineNumber]!;
      tokenPosTable.add([
        lineNumber,
        for (final location in locations) ...[
          location.tokenPos,
          location.dartLocation.column,
        ],
      ]);
    }
    _sourceToTokenPosTable[serverPath] = tokenPosTable;
    return tokenPosTable;
  }

  /// Returns all known [Location]s for the provided [module].
  ///
  /// [module] refers to the JS path of a DDC module without the extension.
  ///
  /// This will populate the [_sourceToLocation] and [_moduleToLocations] maps.
  Future<Set<Location>> _locationsForModule(String module) {
    final memoizer = _locationMemoizer.putIfAbsent(module, AsyncMemoizer.new);

    return memoizer.runOnce(() async {
      if (_moduleToLocations.containsKey(module)) {
        return _moduleToLocations[module]!;
      }
      final result = <Location>{};
      if (module.isEmpty) return _moduleToLocations[module] = result;
      if (module.endsWith('dart_sdk') ||
          (module.endsWith('dart_library') &&
              !module.endsWith('.dart_library'))) {
        return result;
      }
      final modulePath = await globalToolConfiguration.loadStrategy
          .serverPathForModule(_entrypoint, module);
      if (modulePath == null) {
        _logger.warning('No module path for module: $module');
        return result;
      }
      final sourceMapPath = await globalToolConfiguration.loadStrategy
          .sourceMapPathForModule(_entrypoint, module);
      if (sourceMapPath == null) {
        _logger.warning('No sourceMap path for module: $module');
        return result;
      }
      final sourceMapContents = await _assetReader.sourceMapContents(
        sourceMapPath,
      );
      final scriptLocation = p.url.dirname(
        '/${stripLeadingSlashes(modulePath)}',
      );

      if (sourceMapContents == null) return result;

      final runtimeScriptId = await _modules.getRuntimeScriptIdForModule(
        _entrypoint,
        module,
      );

      // This happens to be a [SingleMapping] today in DDC.
      final mapping = parse(sourceMapContents);
      if (mapping is SingleMapping) {
        // Create TokenPos for each entry in the source map.
        for (final lineEntry in mapping.lines) {
          for (final entry in lineEntry.entries) {
            final location = _locationForSourceMapEntry(
              lineEntry: lineEntry,
              entry: entry,
              modulePath: modulePath,
              runtimeScriptId: runtimeScriptId,
              sourceUrls: mapping.urls,
              scriptLocation: scriptLocation,
            );
            if (location != null) {
              result.add(location);
            }
          }
        }
      }
      for (final location in result) {
        _sourceToLocation
            .putIfAbsent(
              location.dartLocation.uri.serverPath,
              () => <Location>{},
            )
            .add(location);
      }
      return _moduleToLocations[module] = result;
    });
  }

  /// Creates a TokenPos [Location] for an entry in the source map.
  Location? _locationForSourceMapEntry({
    required TargetLineEntry lineEntry,
    required TargetEntry entry,
    required String modulePath,
    required String? runtimeScriptId,
    required List<String> sourceUrls,
    required String scriptLocation,
  }) {
    final index = entry.sourceUrlId;
    if (index == null) return null;
    // Source map URLS are relative to the script. They may have platform
    // separators or they may use URL semantics. To be sure, we split and
    // re-join them.
    // This works on Windows because path treats both / and \ as separators.
    // It will fail if the path has both separators in it.
    final relativeSegments = p.split(sourceUrls[index]);
    final path = p.url.normalize(
      p.url.joinAll([scriptLocation, ...relativeSegments]),
    );

    try {
      final dartUri = DartUri(path, _root);
      return Location.from(
        modulePath,
        lineEntry,
        entry,
        dartUri,
        runtimeScriptId,
      );
    } catch (error) {
      // DartUri throws if the path format is unrecognized. Log any errors and
      // return null in that case.
      _logger.warning('Error adding location for $path: $error');
      return null;
    }
  }
}
