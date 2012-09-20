// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a copy of the VM's dart:scalarlist library. This API is not
// usable when running inside a web browser. Nevertheless, we
// provide a mock version of the dart:scalarlist so that we can
// statically analyze programs that use dart:scalarlist.

/**
 * The scalarlist library is used for Dart server applications,
 * which run on a stand-alone Dart VM from the command line.
 * *This library does not work in browser based applications.*
 *
 * This library allows you to work with arrays of scalar values
 * of various sizes.
 */
#library("dart:scalarlist");
#source("../../../scalarlist/scalarlist.dart");
