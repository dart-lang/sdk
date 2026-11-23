// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as path;

/// The file suffix used for virtual macro files in the analyzer.
const macroClientFileSuffix = '.macro.dart';

/// The URI scheme used for virtual macro files on the client.
const macroClientUriScheme = 'dart-macro+file';

const _hexDigits = '0123456789ABCDEF';

/// A class for converting between internal analyzer file paths/references and
/// URIs used by clients.
///
/// The simplest form of this class simple translates between file paths and
/// `file://` URIs but depending on client capabilities some paths/URIs may be
/// re-written to support features like virtual files for macros.
abstract class ClientUriConverter {
  final path.Context _context;

  /// The URI schemes that are supported by this converter.
  ///
  /// This always includes 'file' and may optionally include others like
  /// 'dart-macro+file'.
  final Set<String> supportedSchemes;

  /// The URI schemes that are supported by this converter except 'file'.
  final Set<String> supportedNonFileSchemes;

  /// Creates a converter that does nothing besides translation between file
  /// paths and `file://` URIs.
  factory noop(path.Context context) => _NoOpConverter(context);

  /// Creates a converter that translates paths/URIs for virtual files such as
  /// those created by macros.
  factory withVirtualFileSupport(path.Context context) =>
      _VirtualFileClientUriConverter(context);

  new _(this._context, [this.supportedNonFileSchemes = const {}])
    : supportedSchemes = {'file', ...supportedNonFileSchemes};

  /// Converts client FilePath (which may be a URI or a file path depending on
  /// client capbilities) into a file path/reference from the analyzer.
  ///
  /// This is the legacy protocol equiv of [fromClientUri].
  String fromClientFilePath(String filePathOrUri);

  /// Converts a URI provided by the client into a file path/reference that can
  /// be used by the analyzer.
  ///
  /// This is the LSP equiv of [fromClientFilePath].
  String fromClientUri(Uri uri);

  /// Converts a file path/reference from the analyzer into a client FilePath
  /// (which may be a URI or a file path depending on client capbilities).
  ///
  /// This is the legacy protocol equiv of [toClientUri].
  String toClientFilePath(String filePath);

  /// Converts a file path/reference from the analyzer into a URI to be sent to
  /// the client.
  ///
  /// This is the LSP equiv of [toClientFilePath].
  Uri toClientUri(String filePath);
}

class _NoOpConverter extends ClientUriConverter {
  new(super.context) : super._();

  @override
  String fromClientFilePath(String filePathOrUri) => filePathOrUri;

  @override
  String fromClientUri(Uri uri) => _context.fromUri(uri);

  @override
  String toClientFilePath(String filePath) => filePath;

  @override
  Uri toClientUri(String filePath) => _context.toUri(filePath);
}

class _VirtualFileClientUriConverter extends ClientUriConverter {
  new(path.Context context) : super._(context, {macroClientUriScheme});

  @override
  String fromClientFilePath(String filePathOrUri) =>
      fromClientUri(Uri.parse(filePathOrUri));

  @override
  String fromClientUri(Uri uri) {
    // For URIs with no scheme, assume it was a relative path and provide a
    // better message than "scheme '' is not supported".
    if (uri.scheme.isEmpty) {
      throw ArgumentError.value(
        uri.toString(),
        'uri',
        'URI is not a valid file:// URI',
      );
    }

    if (!supportedSchemes.contains(uri.scheme)) {
      var supportedSchemesString = supportedSchemes.isEmpty
          ? '(none)'
          : supportedSchemes.map((scheme) => "'$scheme'").join(', ');
      throw ArgumentError.value(
        uri.toString(),
        'uri',
        "URI scheme '${uri.scheme}' is not supported. "
            'Allowed schemes are $supportedSchemesString.',
      );
    }

    switch (uri.scheme) {
      // Map macro scheme back to 'file:///.../x.macro.dart'.
      case macroClientUriScheme:
        var pathWithoutExtension = uri.path.substring(
          0,
          uri.path.length - '.dart'.length,
        );
        var newPath = '$pathWithoutExtension$macroClientFileSuffix';
        return _context.fromUri(uri.replace(scheme: 'file', path: newPath));

      default:
        return _context.fromUri(uri);
    }
  }

  @override
  String toClientFilePath(String filePath) {
    if (_isMacroFile(filePath)) {
      return toClientUri(filePath).toString();
    }
    return _fileUriString(filePath);
  }

  @override
  Uri toClientUri(String filePath) {
    // Map '/.../x.macro.dart' onto macro scheme.
    if (_isMacroFile(filePath)) {
      var pathWithoutSuffix = filePath.substring(
        0,
        filePath.length - macroClientFileSuffix.length,
      );
      var newPath = '$pathWithoutSuffix.dart';
      return _context.toUri(newPath).replace(scheme: macroClientUriScheme);
    }

    return _context.toUri(filePath);
  }

  /// Returns the `file:` URI of [filePath], the same as
  /// `_context.toUri(filePath).toString()`.
  ///
  /// The [filePath] must be absolute and normalized.
  String _fileUriString(String filePath) {
    if (_context.style == path.Style.posix) {
      return _encodeFileUri('file://', filePath);
    }
    if (_context.style == path.Style.windows && _hasDriveRoot(filePath)) {
      return _encodeFileUri('file:///', filePath.replaceAll(r'\', '/'));
    }
    return _context.toUri(filePath).toString();
  }

  bool _isMacroFile(String filePath) {
    return filePath.endsWith(macroClientFileSuffix) &&
        supportedSchemes.contains(macroClientUriScheme);
  }

  /// Returns [prefix] followed by [uriPath], with the characters that are not
  /// allowed in a URI path percent-encoded as UTF-8, like [Uri] does.
  static String _encodeFileUri(String prefix, String uriPath) {
    StringBuffer? buffer;
    var start = 0;
    var length = uriPath.length;
    for (var i = 0; i < length; i++) {
      if (_isPathCharacter(uriPath.codeUnitAt(i))) {
        continue;
      }
      var end = i + 1;
      while (end < length && !_isPathCharacter(uriPath.codeUnitAt(end))) {
        end++;
      }
      buffer ??= StringBuffer(prefix);
      buffer.write(uriPath.substring(start, i));
      for (var byte in utf8.encode(uriPath.substring(i, end))) {
        buffer.writeCharCode(0x25); // %
        buffer.writeCharCode(_hexDigits.codeUnitAt(byte >> 4));
        buffer.writeCharCode(_hexDigits.codeUnitAt(byte & 0xF));
      }
      start = end;
      i = end - 1;
    }
    if (buffer == null) {
      return '$prefix$uriPath';
    }
    buffer.write(uriPath.substring(start));
    return buffer.toString();
  }

  /// Whether [filePath] starts with a drive letter, `:`, and `\`.
  static bool _hasDriveRoot(String filePath) {
    if (filePath.length < 3) return false;
    if (filePath.codeUnitAt(1) != 0x3A) return false; // :
    if (filePath.codeUnitAt(2) != 0x5C) return false; // \
    var letter = filePath.codeUnitAt(0) | 0x20;
    return letter >= 0x61 && letter <= 0x7A; // a-z
  }

  /// Whether [codeUnit] is written to a URI path as is: an unreserved
  /// character, a sub-delimiter, `:`, `@`, or the separator `/`.
  static bool _isPathCharacter(int codeUnit) {
    if (codeUnit >= 0x61 && codeUnit <= 0x7A) return true; // a-z
    if (codeUnit >= 0x40 && codeUnit <= 0x5A) return true; // @ A-Z
    if (codeUnit >= 0x26 && codeUnit <= 0x3B) return true; // &'()*+,-./0-9:;
    return codeUnit == 0x21 || // !
        codeUnit == 0x24 || // $
        codeUnit == 0x3D || // =
        codeUnit == 0x5F || // _
        codeUnit == 0x7E; // ~
  }
}
