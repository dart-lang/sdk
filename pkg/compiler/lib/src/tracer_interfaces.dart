// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Tracer {
  void traceGraph(String name, var irObject);
  void traceJavaScriptText(String name, String Function() getText);
  void close();
}
