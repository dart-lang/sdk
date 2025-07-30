// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This export is needed because package `dartdoc` imports the `TimestampedData`
// class from here.
//
// TODO(paulberry): update dartdoc's import, so that this library can be
// deprecated and eventually removed.

export 'package:analyzer/source/timestamped_data.dart' show TimestampedData;
