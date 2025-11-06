// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('Please use package:analyzer/source/timestamped_data.dart instead.')
library;

// This export is needed because there are versions of package `dartdoc` that
// import the `TimestampedData` class from here.
//
// All of those versions have an analyzer constraint < 9.0.0, so once the
// analyzer version gets bumped to 9.0.0, it will be safe to remove this file.
//
// TODO(paulberry): remove this file in analyzer version 9.0.0.

export 'package:analyzer/source/timestamped_data.dart' show TimestampedData;
