// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The scalarlist library is used for Dart server applications,
 * which run on a stand-alone Dart VM from the command line.
 * *This library does not work in browser based applications.*
 *
 * This library allows you to work with arrays of scalar values
 * of various sizes.
 */
library dart_scalarlist;

// TODO(ager): Inline the contents of byte_arrays.dart here and get
// rid of scalarlist_sources.gypi when the VM understands normal
// library structure for builtin libraries.
part 'byte_arrays.dart';
