// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

// TODO(https://github.com/dart-lang/sdk/issues/64888): Revisit these URLs
// with the rest of the served URL layout.

/// Finds the `.dart` files that the source maps point to, so that browser
/// devtools can show them.
///
/// Each source map lists its sources relative to its `.js` file, so the URL
/// path says which kind of source it is:
/// - `web/<path>.dart`: the app's own files, in its `web/` directory.
/// - `packages/<package>/<path>.dart`: a library in a package's `lib/`
///   (including the app's own package), resolved with its package config.
/// - `dart-sdk/lib/<path>.dart`: the Dart SDK's libraries, where the SDK's
///   `dart_sdk.js.map` points.
class DartSources {
  /// The app's `web/` directory.
  final String webDirectory;

  /// The package config the app was compiled with.
  final PackageConfig packageConfig;

  final String _sdkLibDirectory;

  /// [sdkRoot] is the SDK the app was compiled with.
  DartSources({
    required this.webDirectory,
    required this.packageConfig,
    required String sdkRoot,
  }) : _sdkLibDirectory = p.join(sdkRoot, 'lib');

  /// The `.dart` source at the decoded URL [pathSegments], or `null` if it
  /// isn't a Dart source this serves.
  ///
  /// Only returns existing `.dart` files inside the three roots above (after
  /// resolving symbolic links).
  File? resolve(List<String> pathSegments) {
    if (pathSegments.isEmpty ||
        !pathSegments.last.endsWith('.dart') ||
        !pathSegments.every(isSafeUrlSegment)) {
      return null;
    }
    switch (pathSegments) {
      case ['web', ...final rest] when rest.isNotEmpty:
        return _within(webDirectory, rest);
      case ['packages', final package, ...final rest] when rest.isNotEmpty:
        final pkg = packageConfig[package];
        if (pkg == null) return null;
        final packageRoot = p.fromUri(pkg.root);
        final packageUriRoot = p.fromUri(pkg.packageUriRoot);
        // Reject custom configs with `"packageUri": "."` (or omitted
        // `packageUri`), where `packageUriRoot` is the whole package root and
        // would expose `bin/`, `tool/`, or `test/`.
        if (!p.isWithin(packageRoot, packageUriRoot)) return null;
        return _within(packageUriRoot, rest);
      case ['dart-sdk', 'lib', ...final rest] when rest.isNotEmpty:
        return _within(_sdkLibDirectory, rest);
      default:
        return null;
    }
  }

  /// The existing file at [segments] inside [root] (after resolving symbolic
  /// links on both [root] and the target), or `null` if missing or outside
  /// [root].
  static File? _within(String root, List<String> segments) {
    final candidatePath = p.joinAll([root, ...segments]);
    if (!p.isWithin(root, candidatePath)) return null;
    final file = File(candidatePath);
    if (!file.existsSync()) return null;
    try {
      final resolvedRoot = Directory(root).resolveSymbolicLinksSync();
      final resolvedFile = file.resolveSymbolicLinksSync();
      return p.isWithin(resolvedRoot, resolvedFile) ? file : null;
    } on FileSystemException {
      return null;
    }
  }
}

/// Whether [segment] is a safe decoded URL path segment.
///
/// Rejects empty segments, `.` and `..`, hidden dotfiles other than
/// `.well-known`, path or Windows drive separators (`/`, `\`, `:`), and NUL
/// bytes.
bool isSafeUrlSegment(String segment) =>
    segment.isNotEmpty &&
    (segment == '.well-known' || !segment.startsWith('.')) &&
    !segment.contains('/') &&
    !segment.contains(r'\') &&
    !segment.contains(':') &&
    !segment.contains('\x00');
