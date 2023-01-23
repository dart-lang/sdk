// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Background: The verifier has shown exponential behavior on stuff like this.

test() {
  List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List<List>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> x = [];
}
