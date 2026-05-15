// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show InitializeParams;
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';

/// A utility for normalizing paths in log entries.
class LogNormalizer {
  /// A map from the path-to-be-replaced to the replacement string.
  ///
  /// Paths are canonicalized to lowercase and the replacement regex is
  /// case-insensitive.
  final Map<String, String> _replacements =
      CanonicalizedMap<String, String, String>((key) => key.toLowerCase());

  /// A lazily built reverse map for [_replacements].
  Map<String, String>? _denormalizedReplacements;

  /// A cached regex for all current replacements to allow them to occur in a
  /// single pass.
  RegExp? _replacementPattern;

  /// A cached regex for all current denormalizations to allow them to occur in
  /// a single pass.
  RegExp? _denormalizationPattern;

  /// Extracts paths and URIs from an LSP initialize request and adds
  /// replacements for each.
  void addLspWorkspaceReplacements(Message message) {
    var params = message.params;
    if (params == null ||
        !InitializeParams.canParse(params, nullLspJsonReporter)) {
      return;
    }

    var initializeParams = InitializeParams.fromJson(params);

    // Record rootPath and rootUri separately even though we handle both URIs
    // and paths for each replacement, because we don't know for certain that
    // the client provided us the same in each.
    if (initializeParams.rootPath case var rootPath?) {
      addReplacementsForPath(rootPath, 'rootPath');
    }
    if (initializeParams.rootUri case var rootUri?) {
      addReplacementsForUri(rootUri, 'rootUri');
    }

    if (initializeParams.workspaceFolders case var workspaceFolders?) {
      for (var i = 0; i < workspaceFolders.length; i++) {
        var uri = workspaceFolders[i].uri;
        addReplacementsForUri(uri, 'workspaceFolder-$i');
      }
    }
  }

  /// Adds a replacement for the given [inputPath] in both path and URI form.
  ///
  /// Replacements assume the path (or URI) appear as quoted strings in the
  /// JSON (and therefore must be preceeded by a quote and followed by a
  /// path/uri separator or another quote).
  ///
  /// The replacement will be formatted as `{{$name}}` for URIs and
  /// `{{$name:filePath}}` for file paths to allow for reversing this
  /// replacement.
  void addReplacementsForPath(String inputPath, String name) {
    if (inputPath.isEmpty) return;

    var uri = Uri.file(inputPath);
    var uriString = uri.toString();

    void addWithQuotesAndTrailingSlash(
      String input,
      List<String> separators,
      String replacement,
    ) {
      _replacements['"$input"'] = '"$replacement"';
      for (var separator in separators) {
        _replacements['"$input$separator'] = '"$replacement$separator';
      }
    }

    // Compute replacement strings.
    var pathReplacement = '{{$name:filePath}}';
    var uriReplacement = '{{$name}}';

    // All replacements must be in the map because we need to look up the values
    // during replacement so if the regex matches variations, we need to be able
    // to find them here.

    // Paths
    var pathSeparators = ['/', r'\'];
    addWithQuotesAndTrailingSlash(
      _jsonEncode(inputPath),
      pathSeparators,
      pathReplacement,
    );
    addWithQuotesAndTrailingSlash(inputPath, pathSeparators, pathReplacement);

    // URIs
    var uriSeparators = ['/'];
    addWithQuotesAndTrailingSlash(
      _jsonEncode(uriString),
      uriSeparators,
      uriReplacement,
    );
    addWithQuotesAndTrailingSlash(uriString, uriSeparators, uriReplacement);

    // Reset the cached pattern so it's built on the next call to normalize.
    _replacementPattern = null;
    _denormalizedReplacements = null;
    _denormalizationPattern = null;
  }

  /// A convenience method for calling [addReplacementsForPath] when you have a
  /// [Uri].
  ///
  /// Only if the URI is a 'file://' URI will it be recorded.
  void addReplacementsForUri(Uri uri, String replacement) {
    if (uri.isScheme('file')) {
      addReplacementsForPath(uri.toFilePath(), replacement);
    }
  }

  /// Restores [normalizedContent] to full paths/URIs by performing the opposite
  /// replacements.
  ///
  /// Where normalization collapsed multiple equivalent strings into one (for
  /// example different casing or URI encoding), they will all be restored to
  /// a single canonical version.
  String denormalize(String normalizedContent) {
    if (_replacements.isEmpty) return normalizedContent;

    var denormalizedReplacements = _denormalizedReplacements ??=
        _buildDenormalizedReplacements();

    var denormalizationPattern = _denormalizationPattern ??= RegExp(
      denormalizedReplacements.keys.map(RegExp.escape).join('|'),
    );

    return normalizedContent.replaceAllMapped(
      denormalizationPattern,
      (match) => denormalizedReplacements[match[0]]!,
    );
  }

  /// Returns the given value (object, map, literal) as a JSON string with
  /// file/URIs normalized.
  String normalize(Object? value) {
    var json = jsonEncode(_canonicalizeObject(value));
    if (_replacements.isEmpty) return json;

    // Build a single regex that matches any of the replacements.
    var replacementPattern = _replacementPattern ??= RegExp(
      (_replacements.keys.toList()
            // Sort keys longest-to-shortest so that we always replace the
            // largest part of the path if there are nested workspace folders.
            ..sort((a, b) => b.length.compareTo(a.length)))
          .map(RegExp.escape)
          .join('|'),
      caseSensitive: false,
    );

    // Replace with the respective value from the replacement map.
    return json.replaceAllMapped(
      replacementPattern,
      (match) => _replacements[match[0]]!,
    );
  }

  Map<String, String> _buildDenormalizedReplacements() {
    var denormalizedReplacements = <String, String>{};
    for (var MapEntry(:key, :value) in _replacements.entries) {
      // Multiple original strings can normalize to the same placeholder.
      // Use the first value as the canonical form.
      denormalizedReplacements.putIfAbsent(value, () => key);
    }
    return denormalizedReplacements;
  }

  /// A 'toEncodable' implementation for [JsonEncoder] that will canonicalize
  /// any input URIs to remove unnecessary escaping (such as colons and
  /// ampersands) from the client.
  ///
  /// This is done during JSON serialization for performance. Our normalization
  /// regex is built as a set of literals and there are many combinations of
  /// encoded/unencoded characters that would balloon the number of patterns.
  Object? _canonicalizeObject(Object? value) {
    if (value is String) {
      return _canonicalizeString(value);
    }

    if (value is List<Object?>) {
      return value.map(_canonicalizeObject).toList();
    }

    if (value is Map<Object?, Object?>) {
      return {
        for (var MapEntry(:key, :value) in value.entries)
          _canonicalizeObject(key): _canonicalizeObject(value),
      };
    }

    return value;
  }

  /// Canonicalize [value] to remove unnecessary escaping (such as colons and
  /// ampersands) from the client.
  String _canonicalizeString(String value) {
    if (!value.startsWith('file:')) {
      return value;
    }

    var uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }

    // Extract the path and then re-encode as a file URI in Dart. The encoding
    // will then match what we put into the replacement map.
    return Uri.file(uri.toFilePath()).toString();
  }

  /// Returns a JSON-encoded version of [inputString] without the surrounding
  /// quotes.
  String _jsonEncode(String inputString) {
    var encoded = json.encode(inputString);
    return encoded.substring(1, encoded.length - 1);
  }
}
