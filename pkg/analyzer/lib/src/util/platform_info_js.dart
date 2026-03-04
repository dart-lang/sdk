// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/platform_info.dart';

final class PlatformInfoImpl extends PlatformInfo {
  const PlatformInfoImpl();

  @override
  Map<String, String> get environment => const {};

  @override
  String get executable => '';

  @override
  bool get isAndroid => false;

  @override
  bool get isFuchsia => false;

  @override
  bool get isIOS => false;

  @override
  bool get isLinux => false;

  @override
  bool get isMacOS => false;

  @override
  bool get isWindows => false;

  @override
  String get lineTerminator => '\n';

  @override
  String get operatingSystem => 'browser';

  @override
  String get pathSeparator => '/';

  @override
  String get resolvedExecutable => '';

  @override
  // The compilation environment does not contain 'dart.sdk.version' by default,
  // but it has been proposed in: https://dartbug.com/54785
  // For now users compiling compiling analyzer for web, will have to manually
  // specify -Ddart.sdk.version=<version> when building their code.
  String get version => String.fromEnvironment('dart.sdk.version');
}
