// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class Request {}

class Response {}

typedef Handler = FutureOr<Response> Function(Request request);

typedef Typedef = int Function(int?);
