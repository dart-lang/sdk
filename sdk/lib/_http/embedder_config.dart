// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

/// Embedder-specific `dart:_http` configuration.

/// [HttpClient] will disallow HTTP URLs if this value is set to `false`.
@pragma("vm:entry-point")
bool _embedderAllowsHttp = true;
