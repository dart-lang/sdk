// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of metrics collected during the runtime of a Dart app.
///
/// The contents of the map depend on the platform. The map values are simple
/// objects (strings, numbers, Booleans). There is always an entry for the key
/// `'runtime'` with a [String] value.
Map<String, Object> get runtimeMetrics {
  return {'runtime': 'unknown'};
}
