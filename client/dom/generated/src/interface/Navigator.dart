// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Navigator {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final Geolocation geolocation;

  final String language;

  final DOMMimeTypeArray mimeTypes;

  final bool onLine;

  final String platform;

  final DOMPluginArray plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates();

  bool javaEnabled();

  void registerProtocolHandler(String scheme, String url, String title);
}
