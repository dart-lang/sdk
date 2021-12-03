// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of metrics for events that happen before `main()` is entered.
///
/// The contents of the map depend on the platform. The map values are simple
/// objects (strings, numbers, Booleans). There is always an entry for the key
/// `'runtime'` with a [String] value.
Map<String, Object> get startupMetrics {
  return {'runtime': 'unknown'};
}
