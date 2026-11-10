// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(64210): Update this to use the native version for wasm.
// Export [EnumSet] depending on the compilation target.
export 'utilities_collection_native.dart'
    if (dart.library.js_interop) 'utilities_collection_js.dart';
