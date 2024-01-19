// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:path/path.dart' as path;

/// The file suffix used for virtual macro files in the analyzer.
const macroClientFileSuffix = '.macro.dart';

/// The URI scheme used for virtual macro files on the client.
const macroClientUriScheme = 'dart-macro+file';

/// A class for converting between internal analyzer file paths/references and
/// URIs used by clients.
///
/// The simplest form of this class simple translates between file paths and
/// `file://` URIs but depending on client capabilities some paths/URIs may be
/// re-written to support features like virtual files for macros.
class ClientUriConverter {
  final path.Context _context;

  /// The URI schemes that are supported by this converter.
  ///
  /// This always includes 'file' and may optionally include others like
  /// 'dart-macro+file'.
  final Set<String> supportedSchemes;

  /// The URI schemes that are supported by this converter except 'file'.
  final Set<String> supportedNonFileSchemes;

  /// A set of document filters for Dart files in the supported schemes.
  final List<TextDocumentFilterWithScheme> filters;

  /// Creates a converter that does nothing besides translation between file
  /// paths and `file://` URIs.
  ClientUriConverter.noop(path.Context context) : this._(context);

  /// Creates a converter that translates paths/URIs for virtual files such as
  /// those created by macros.
  ClientUriConverter.withVirtualFileSupport(path.Context context)
      : this._(context, {macroClientUriScheme});

  ClientUriConverter._(this._context, [this.supportedNonFileSchemes = const {}])
      : supportedSchemes = {'file', ...supportedNonFileSchemes},
        filters = [
          for (var scheme in {'file', ...supportedNonFileSchemes})
            TextDocumentFilterWithScheme(language: 'dart', scheme: scheme)
        ];

  /// Converts a URI provided by the client into a file path/reference that can
  /// be used by the analyzer.
  String fromClientUri(Uri uri) {
    // For URIs with no scheme, assume it was a relative path and provide a
    // better message than "scheme '' is not supported".
    if (uri.scheme.isEmpty) {
      throw ArgumentError.value(uri, 'uri', 'URI is not a valid file:// URI');
    }

    if (!supportedSchemes.contains(uri.scheme)) {
      var supportedSchemesString =
          supportedSchemes.map((scheme) => "'$scheme'").join(', ');
      throw ArgumentError.value(
        uri,
        'uri',
        "URI scheme '${uri.scheme}' is not supported. "
            'Allowed schemes are $supportedSchemesString.',
      );
    }

    switch (uri.scheme) {
      // Map macro scheme back to 'file:///.../x.macro.dart'.
      case macroClientUriScheme:
        var pathWithoutExtension =
            uri.path.substring(0, uri.path.length - '.dart'.length);
        var newPath = '$pathWithoutExtension$macroClientFileSuffix';
        return _context.fromUri(uri.replace(scheme: 'file', path: newPath));

      default:
        return _context.fromUri(uri);
    }
  }

  /// Converts a file path/reference from the analyzer into a URI to be sent to
  /// the client.
  Uri toClientUri(String filePath) {
    // Map '/.../x.macro.dart' onto macro scheme.
    if (filePath.endsWith(macroClientFileSuffix) &&
        supportedSchemes.contains(macroClientUriScheme)) {
      var pathWithoutSuffix =
          filePath.substring(0, filePath.length - macroClientFileSuffix.length);
      var newPath = '$pathWithoutSuffix.dart';
      return _context.toUri(newPath).replace(scheme: macroClientUriScheme);
    }

    return _context.toUri(filePath);
  }
}
