// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart' as stack;

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
/// should not be assumed that if a [stack.Frame] is returned that the input
/// was necessarily a stack frame or that calling `toString` will return the
/// original input text.
stack.Frame? parseDartStackFrame(String line) {
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

/// Attempts to parse a line as a stack frame in order to read path/line/col
/// information.
///
/// It should not be assumed that if a [stack.Frame] is returned that the input
/// was necessarily a stack frame or that calling `toString` will return the
/// original input text.
stack.Frame? _parseStackFrame(String line) {
  // Because we split on \n, on Windows there may be trailing \r which prevents
  // package:stack_trace from parsing correctly.
  line = line.trim();

  /// Helper to try parsing a frame with [parser], returning `null` if it
  /// fails to parse.
  stack.Frame? tryParseFrame(stack.Frame Function(String) parser) {
    final frame = parser(line);
    return frame is stack.UnparsedFrame ? null : frame;
  }

  // Try different formats of stack frames.
  // pkg:stack_trace does not have a generic Frame.parse() and Trace.parse()
  // doesn't work well when the content includes non-stack-frame lines
  // (https://github.com/dart-lang/stack_trace/issues/115).
  return tryParseFrame((line) => stack.Frame.parseVM(line)) ??
      // TODO(dantup): Tidy up when constructor tear-offs are available.
      tryParseFrame((line) => stack.Frame.parseV8(line)) ??
      tryParseFrame((line) => stack.Frame.parseSafari(line)) ??
      tryParseFrame((line) => stack.Frame.parseFirefox(line)) ??
      tryParseFrame((line) => stack.Frame.parseIE(line)) ??
      tryParseFrame((line) => stack.Frame.parseFriendly(line));
}

/// Checks whether [flag] is in [args], allowing for both underscore and
/// dash format.
bool containsVmFlag(List<String> args, String flag) {
  final flagUnderscores = flag.replaceAll('-', '_');
  final flagDashes = flag.replaceAll('_', '-');
  return args.contains(flagUnderscores) || args.contains(flagDashes);
}
