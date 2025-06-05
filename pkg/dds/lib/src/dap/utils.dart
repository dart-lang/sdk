// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import '../rpc_error_codes.dart';

/// Returns whether this URI is something that can be resolved to a file-like
/// URI via the VM Service.
bool isResolvableUri(Uri uri) {
  return !uri.isScheme('file') &&
      // Custom-scheme versions of file, like `dart-macro+file://`
      !uri.scheme.endsWith('+file') &&
      !uri.isScheme('http') &&
      !uri.isScheme('https') &&
      // Parsed stack frames may have URIs with no scheme and the text
      // "unparsed" if they looked like stack frames but had no file
      // information.
      !uri.isScheme('') &&
      // Valid URIs will always have a non-empty path. Empty paths usually
      // indicate badly parsed URIs when parsing stack frames.
      // The string 'usage: ' will parse as a valid URI in `parseStackFrame`.
      !uri.hasEmptyPath;
}

/// Attempts to parse a line as a stack frame in order to read path/line/col
/// information.
///
/// Frames that do not look like real Dart stack frames (such as including path
/// or URIs that look like real Dart libraries) will be filtered out but it
/// should not be assumed that if a value is returned that the input
/// was necessarily a stack frame.
StackFrameLocation? parseDartStackFrame(String line) {
  final frame = _parseStackFrame(line);
  final uri = frame?.uri;
  return uri != null && _isDartUri(uri) ? frame : null;
}

/// Checks whether [uri] is a possible Dart URI that should be mapped to try
/// and attach location metadata to an output event.
///
/// This is a performance optimization to avoid calling the VM's
/// `lookupResolvedUris` method for output events that are probably not
/// stack frames.
bool _isDartUri(Uri uri) {
  // Stack frame parsing captures a lot of things that aren't real URIs, often
  // with no scheme or empty paths.
  if (!uri.hasScheme || uri.hasEmptyPath) {
    return false;
  }

  // Anything starting with dart: is potential
  // - dart:io
  if (uri.isScheme('dart')) {
    return true;
  }

  // Only accept package: and file: URIs if they end with .dart.
  // - package:foo/foo.dart
  // - file:///c:/foo/bar.dart
  if (uri.isScheme('package') ||
      uri.isScheme('file') ||
      uri.scheme.endsWith('+file')) {
    return uri.path.endsWith('.dart');
  }

  // Some other scheme we didn't recognize and likely cannot parse.
  return false;
}

/// A [RegExp] for extracting URIs and optional line/columns out of a line from
/// a stack trace.
final _stackFrameLocationPattern =
    // Characters we consider part of a path:
    //
    //   - `\w` word characters
    //   - `.` dots (valid in paths)
    //   - `-` dash (valid in paths and URI schemes)
    //   - `:` colons (scheme or drive letters)
    //   - `/` forward slashes (URIs)
    //   - `\` black slashes (Windows paths)
    //   - `%` percent (URL percent encoding)
    //   - `+` plus (possible URL encoding of space)
    //
    // To avoid matching too much, we don't allow spaces even though they could
    // appear in relative paths. Most output should be URIs where they would be
    // encoded.
    //
    // The whole string must end with the line/col sequence, a non-word
    // character or be the end of the line. This avoids matching some strings
    // that contain ".dart" but probably aren't valid paths, like ".dart2".
    RegExp(r'([\w\.\-:\/\\%+]+\.dart)(?:(?:(?: +|:)(\d+):(\d+))|\W|$)');

/// Attempts to parse a line as a stack frame in order to read path/line/col
/// information.
///
/// It should not be assumed that if a value is returned that the input
/// was necessarily a stack frame.
StackFrameLocation? _parseStackFrame(String input) {
  var match = _stackFrameLocationPattern.firstMatch(input);
  if (match == null) return null;

  var uriMatch = match.group(1);
  var lineMatch = match.group(2);
  var colMatch = match.group(3);

  var uri = uriMatch != null ? Uri.tryParse(uriMatch) : null;
  var line = lineMatch != null ? int.tryParse(lineMatch) : null;
  var col = colMatch != null ? int.tryParse(colMatch) : null;

  if (uriMatch == null || uri == null) {
    return null;
  }

  // If the URI has no scheme, assume a relative path from Directory.current.
  if (!uri.hasScheme && path.isRelative(uriMatch)) {
    var currentDirectoryPath = Directory.current.path;
    if (currentDirectoryPath.isNotEmpty) {
      uri = Uri.file(path.join(currentDirectoryPath, uriMatch));
    }
  }

  return (uri: uri, line: line, column: col);
}

/// Checks whether [flag] is in [args], allowing for both underscore and
/// dash format.
bool containsVmFlag(List<String> args, String flag) {
  final flagUnderscores = flag.replaceAll('-', '_');
  final flagDashes = flag.replaceAll('_', '-');
  return args.contains(flagUnderscores) || args.contains(flagDashes);
}

typedef StackFrameLocation = ({Uri uri, int? line, int? column});

extension RpcErrorExtension on vm.RPCError {
  /// Whether this [vm.RPCError] is some kind of "VM Service connection has gone"
  /// error that may occur if the VM is shut down.
  bool get isServiceDisposedError {
    if (code == RpcErrorCodes.kServiceDisappeared ||
        code == RpcErrorCodes.kConnectionDisposed) {
      return true;
    }

    if (code == RpcErrorCodes.kExtensionError) {
      // Always ignore "client is closed" and "closed with pending request"
      // errors because these can always occur during shutdown if we were
      // just starting to send (or had just sent) a request.
      return message.contains("The client is closed") ||
          message.contains("The client closed with pending request") ||
          message.contains("Service connection disposed");
    }

    return false;
  }
}
