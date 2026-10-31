// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/utilities/hash/blake3.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';

/// Manages persistent trust decisions for analyzer plugins.
///
/// Trust state is stored in `<state-location>/.plugin_trust/plugin_trust.json`.
///
/// Plugins can be trusted or untrusted by their generalized configured source
/// (via `--always-trust-plugins` or `--never-trust-plugins`), or trusted at
/// their exact current code contents via a BLAKE3 content digest (via
/// `--trust-plugins`).
class PluginTrust {
  static const String _stateFolderName = '.plugin_trust';
  static const String _fileName = 'plugin_trust.json';
  static const String _pluginsKey = 'plugins';
  static const String _sourcesKey = 'sources';
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

  /// Returns the persisted source-level trust setting for [pluginName] from
  /// [source] (which is set either via `--always-trust-plugins` or
  /// `--never-trust-plugins`), without checking content hashes.
  TrustSetting getSourceTrust(String pluginName, PluginSource source) {
    var generalizedSource = _generalizeSource(pluginName, source);
    var data = _readPlugins()[pluginName];
    return switch (data?.sources[generalizedSource]) {
      true => .trusted,
      false => .untrusted,
      null => .unset,
    };
  }

  /// Returns the effective [TrustSetting] for [pluginName] configured with
  /// [source] and optional resolved [pluginFolder].
  ///
  /// 1. If [source] (generalized) is explicitly trusted or untrusted, returns
  ///    that [TrustSetting].
  /// 2. Otherwise, if [pluginFolder] is provided and its current contents match
  ///    a previously trusted BLAKE3 digest for [pluginName], returns
  ///    [TrustSetting.trusted].
  /// 3. Otherwise, returns [TrustSetting.unset].
  @visibleForTesting
  TrustSetting getTrust(
    String pluginName,
    PluginSource source, {
    Folder? pluginFolder,
  }) {
    var sourceTrust = getSourceTrust(pluginName, source);
    if (sourceTrust != .unset) return sourceTrust;

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
  /// If [source] (generalized) was previously marked as explicitly untrusted,
  /// that entry is cleared so the content trust takes effect.
  ///
  /// Returns `null` if [pluginFolder] does not exist or cannot be read.
  String? setContentTrust(
    String pluginName,
    PluginSource source,
    Folder pluginFolder,
  ) {
    var hash = computeFolderHash(pluginFolder);
    if (hash == null) return null;

    var plugins = _readPlugins();
    var data = plugins.putIfAbsent(pluginName, _PluginTrustData.new);
    data.contentHashes.add(hash);
    var generalizedSource = _generalizeSource(pluginName, source);
    if (data.sources[generalizedSource] == false) {
      data.sources.remove(generalizedSource);
    }
    _writePlugins(plugins);
    return hash;
  }

  /// Persists the source-level [trusted] state for [pluginName] from [source].
  ///
  /// When [trusted] is `false`, any previously trusted content hashes for
  /// [pluginName] are also cleared.
  void setSourceTrust(
    String pluginName,
    PluginSource source, {
    required bool trusted,
  }) {
    var generalizedSource = _generalizeSource(pluginName, source);
    var plugins = _readPlugins();
    var data = plugins.putIfAbsent(pluginName, _PluginTrustData.new);
    data.sources[generalizedSource] = trusted;
    if (!trusted) {
      data.contentHashes.clear();
    }
    _writePlugins(plugins);
  }

  String _canonicalize(String dirPath) {
    var pathContext = _resourceProvider.pathContext;
    var normalized = pathContext.normalize(pathContext.absolute(dirPath));
    try {
      return _resourceProvider
          .getFolder(normalized)
          .resolveSymbolicLinksSync()
          .path;
    } on FileSystemException {
      return normalized;
    }
  }

  /// Returns the "generalized" source identifier for a plugin named
  /// [pluginName] configured with [source].
  ///
  /// * For [VersionedPluginSource], returns
  ///   `<hostedUrl>/packages/<pluginName>`, ignoring any version constraint.
  /// * For [GitPluginSource], returns the git URL (and `#<path>` if a path is
  ///   specified), ignoring any `ref` or `tagPattern`.
  /// * For [PathPluginSource], returns the canonicalized directory path.
  String _generalizeSource(String pluginName, PluginSource source) {
    return switch (source) {
      VersionedPluginSource(:var hostedUrl) =>
        '${_normalizeHostedUrl(hostedUrl)}/packages/$pluginName',
      GitPluginSource(:var url, :var path) =>
        path == null || path.isEmpty ? url : '$url#$path',
      PathPluginSource(:var path) => _canonicalize(path),
    };
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
      if (value[_sourcesKey] case Map<String, Object?> sources) {
        for (var MapEntry(key: sourceKey, value: isTrusted)
            in sources.entries) {
          if (isTrusted is bool) {
            data.sources[sourceKey] = isTrusted;
          }
        }
      }
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
              if (value.sources.isNotEmpty) _sourcesKey: value.sources,
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

  static String _normalizeHostedUrl(String? hostedUrl) {
    var url = hostedUrl ?? 'https://pub.dev';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

/// The persisted trust state for an analyzer plugin.
enum TrustSetting { trusted, untrusted, unset }

class _PluginTrustData {
  final Map<String, bool> sources = {};
  final Set<String> contentHashes = {};
}
