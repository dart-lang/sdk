// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/utilities/hash/blake3.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';

/// The persisted trust state for an analyzer plugin.
enum TrustSetting { trusted, untrusted, unset }

/// Manages persistent trust decisions for analyzer plugins.
///
/// Trust state is stored in `<state-location>/.workspace_trust/workspace_trust.json`.
///
/// Plugins can be trusted at their exact current code contents via a BLAKE3
/// content digest (via `--trust-plugins`).
class WorkspaceTrust {
  static const String _stateFolderName = '.workspace_trust';
  static const String _fileName = 'workspace_trust.json';
  static const String _pluginsKey = 'plugins';
  static const String _hashesKey = 'hashes';

  final ResourceProvider _resourceProvider;
  final File? _storageFile;

  new(this._resourceProvider, [File? storageFile])
    : _storageFile =
          storageFile ??
          _resourceProvider
              .getStateLocation(_stateFolderName)
              ?.getFile(_fileName);

  /// Computes a deterministic hex-encoded BLAKE3-256 digest of all files in
  /// [folder] in sorted relative-path order (excluding `.dart_tool` and `.git`
  /// directories), or returns `null` if [folder] does not exist or cannot be
  /// read.
  @visibleForTesting
  String? computeFolderHash(Folder folder) {
    if (!folder.exists) {
      return null;
    }
    var pathContext = _resourceProvider.pathContext;
    var files = <(String, File)>[];

    void collectFiles(Folder current) {
      for (var child in current.getChildren()) {
        if (child is Folder) {
          var name = child.shortName;
          if (name == '.dart_tool' || name == '.git') {
            continue;
          }
          collectFiles(child);
        } else if (child is File) {
          var relativePath = pathContext
              .split(pathContext.relative(child.path, from: folder.path))
              .join('/');
          files.add((relativePath, child));
        }
      }
    }

    try {
      collectFiles(folder);
      files.sort((a, b) => a.$1.compareTo(b.$1));
      var sink = ScalarBlake3Sink();
      for (var (relativePath, file) in files) {
        var pathBytes = utf8.encode(relativePath);
        var fileBytes = file.readAsBytesSync();
        sink.add(utf8.encode('${pathBytes.length}:'));
        sink.add(pathBytes);
        sink.add(utf8.encode('${fileBytes.length}:'));
        sink.add(fileBytes);
      }
      return hex.encode(sink.finish());
    } on FileSystemException {
      return null;
    }
  }

  /// Returns the effective [TrustSetting] for [pluginName] with optional
  /// resolved [pluginFolder].
  ///
  /// If [pluginFolder] is provided and its current contents match a previously
  /// trusted BLAKE3 digest for [pluginName], returns [TrustSetting.trusted].
  /// Otherwise, returns [TrustSetting.unset].
  @visibleForTesting
  TrustSetting getTrust(String pluginName, {Folder? pluginFolder}) {
    if (pluginFolder != null && isContentTrusted(pluginName, pluginFolder)) {
      return .trusted;
    }
    return .unset;
  }

  /// Returns whether any trusted content hashes are recorded for [pluginName].
  bool hasTrustedHashes(String pluginName) {
    var data = _readPlugins()[pluginName];
    return data != null && data.contentHashes.isNotEmpty;
  }

  /// Returns whether the current contents of [pluginFolder] match a trusted
  /// BLAKE3 digest recorded for [pluginName].
  bool isContentTrusted(String pluginName, Folder pluginFolder) {
    var data = _readPlugins()[pluginName];
    if (data == null || data.contentHashes.isEmpty) return false;

    var hash = computeFolderHash(pluginFolder);
    return hash != null && data.contentHashes.contains(hash);
  }

  /// Computes the BLAKE3 digest of [pluginFolder] and persists it as trusted
  /// for [pluginName].
  ///
  /// Returns `null` if [pluginFolder] does not exist or cannot be read.
  String? setContentTrust(String pluginName, Folder pluginFolder) {
    var hash = computeFolderHash(pluginFolder);
    if (hash == null) return null;

    var plugins = _readPlugins();
    var data = plugins.putIfAbsent(pluginName, _PluginTrustData.new);
    data.contentHashes.add(hash);
    _writePlugins(plugins);
    return hash;
  }

  Map<String, _PluginTrustData> _readPlugins() {
    var storageFile = _storageFile;
    if (storageFile == null || !storageFile.exists) return {};

    Object? decoded;
    try {
      var contents = storageFile.readAsStringSync();
      decoded = jsonDecode(contents);
    } catch (_) {
      // If the file is corrupted or unreadable, treat as empty (untrusted).
      return {};
    }

    if (decoded is! Map<String, Object?>) return {};

    var plugins = decoded[_pluginsKey];
    if (plugins is! Map<String, Object?>) return {};

    var result = <String, _PluginTrustData>{};
    for (var MapEntry(key: pluginName, :value) in plugins.entries) {
      if (value is! Map<String, Object?>) continue;

      var data = _PluginTrustData();
      if (value[_hashesKey] case List<Object?> contentHashes) {
        for (var contentHash in contentHashes) {
          if (contentHash is String) {
            data.contentHashes.add(contentHash);
          }
        }
      }
      result[pluginName] = data;
    }
    return result;
  }

  void _writePlugins(Map<String, _PluginTrustData> plugins) {
    var storageFile = _storageFile;
    if (storageFile == null) return;

    try {
      storageFile.parent.create();
      var jsonMap = {
        _pluginsKey: {
          for (var MapEntry(:key, :value) in plugins.entries)
            key: {
              if (value.contentHashes.isNotEmpty)
                _hashesKey: value.contentHashes.toList(),
            },
        },
      };
      var contents = const JsonEncoder.withIndent('  ').convert(jsonMap);
      storageFile.writeAsStringSync('$contents\n');
    } catch (_) {
      // Ignore write failures (e.g. read-only filesystem).
    }
  }
}

class _PluginTrustData {
  final Set<String> contentHashes = {};
}
