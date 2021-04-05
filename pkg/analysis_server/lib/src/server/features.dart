// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The set of features enabled in a server session.
///
/// When some features are not enabled, the server might avoid doing work
/// that is only required for these features.
class FeatureSet {
  final bool completion;
  final bool search;

  FeatureSet({
    this.completion = true,
    this.search = true,
  });
}
