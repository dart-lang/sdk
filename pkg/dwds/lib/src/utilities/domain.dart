// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

Never throwInvalidParam(String method, String message) {
  throw RPCError(method, RPCErrorKind.kInvalidParams.code, message);
}
