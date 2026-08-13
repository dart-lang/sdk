// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "prefix_importer_tree_shaken_deferred.dart" deferred as d;

@pragma("vm:prefer-inline")
load() => d.loadLibrary();

@pragma("vm:prefer-inline")
foo() => d.bar();
