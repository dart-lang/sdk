// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'dart:io';
library;

import 'package:analyzer/src/util/platform_info_js.dart'
    if (dart.library.io) 'package:analyzer/src/util/platform_info_io.dart';

/// A proxy for [Platform] from `dart:io` which also works on web.
const platform = PlatformInfoImpl();

abstract class PlatformInfo {
  const PlatformInfo();

  /// Returns [Platform.environment].
  ///
  /// On web this will return an empty map.
  Map<String, String> get environment;

  /// Returns [Platform.executable], or empty string on web.
  String get executable;

  /// Returns [Platform.isAndroid].
  bool get isAndroid;

  /// Returns [Platform.isFuchsia].
  bool get isFuchsia;

  /// Returns [Platform.isIOS].
  bool get isIOS;

  /// Returns [Platform.isLinux].
  bool get isLinux;

  /// Returns [Platform.isMacOS].
  bool get isMacOS;

  /// Returns [Platform.isWindows].
  bool get isWindows;

  /// Returns [Platform.lineTerminator], or `'\n'` on web.
  String get lineTerminator;

  /// Returns [Platform.operatingSystem], or `'browser'` on web.
  String get operatingSystem;

  /// Returns [Platform.pathSeparator], or `'/'` on web.
  String get pathSeparator;

  /// Returns [Platform.resolvedExecutable], or empty string on web.
  String get resolvedExecutable;

  /// Returns [Platform.version] from 'dart:io'.
  ///
  /// On web this will return `String.fromEnvironment('dart.sdk.version')`
  /// which the person building the Dart SDK for web is required to set
  /// themselves, pending:
  /// https://github.com/dart-lang/sdk/issues/54785
  String get version;
}
