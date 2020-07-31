// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An extension conflicting with the one from "on_object.dart";
extension AlsoOnObject on Object {
  String get onObject => "also object";
}
