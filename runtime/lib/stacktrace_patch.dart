// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class StackTrace {
  /* patch */ String get _fullStackTrace native "Stacktrace_getFullStacktrace";

  /* patch */ String get _stackTrace native "Stacktrace_getStacktrace";

  /* patch */ void _setupFullStackTrace()
      native "Stacktrace_setupFullStacktrace";
}

