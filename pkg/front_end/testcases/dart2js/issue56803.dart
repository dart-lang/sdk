// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String? maybe = bool.fromEnvironment("not there") ? "string" : null;
extension type const Ext._(String _) implements String {
  const Ext()
      : assert(maybe != null, "Must not be null"),
        _ = "OK";
}
void main() {
  var c = const Ext();
  print(c);
}
