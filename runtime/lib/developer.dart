// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch bool debugger({bool when: true, String msg}) native "Developer_debugger";

patch inspect(object) native "Developer_inspect";

patch log({int sequenceNumber,
           int millisecondsSinceEpoch,
           int level,
           String name,
           String message,
           Zone zone,
           Object error,
           StackTrace stackTrace}) native "Developer_log";