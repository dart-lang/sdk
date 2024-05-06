// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Contains runtime utils for reload tests.
//
// Should be imported directly by test files, not test runners.

export 'src/_reload_utils_api.dart'
    if (dart.library.io) 'src/_vm_reload_utils.dart'
    if (dart.library.js_interop) 'src/_ddc_reload_utils.dart';
