// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/flutter/devtools/issues/3571): move to devtools_shared.
class RegisteredServiceDescription {
  const RegisteredServiceDescription._({
    required this.service,
    required this.title,
  });

  final String service;
  final String title;
}

/// Flutter memory service registered by Flutter Tools.
///
/// We call this service to get version information about the Flutter Android memory info
/// using Android's ADB.
const flutterMemory = RegisteredServiceDescription._(
  service: 'flutterMemoryInfo',
  title: 'Flutter Memory Info',
);

const flutterListViews = '_flutter.listViews';

/// Flutter engine returns estimate how much memory is used by layer/picture raster
/// cache entries in bytes.
const flutterEngineRasterCache = '_flutter.estimateRasterCacheMemory';
