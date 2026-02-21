// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/util/platform_info.dart';

final class PlatformInfoImpl extends PlatformInfo {
  const PlatformInfoImpl();

  @override
  Map<String, String> get environment => Platform.environment;

  @override
  String get executable => Platform.executable;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isFuchsia => Platform.isFuchsia;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  bool get isLinux => Platform.isLinux;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isWindows => Platform.isWindows;

  @override
  String get lineTerminator => Platform.lineTerminator;

  @override
  String get operatingSystem => Platform.operatingSystem;

  @override
  String get pathSeparator => Platform.pathSeparator;

  @override
  String get resolvedExecutable => Platform.resolvedExecutable;

  @override
  String get version => Platform.version;
}
