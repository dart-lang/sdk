// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: stringInterpolation:Depends on nothing, Changes [] field static.*/
stringInterpolation() => '${null}';

/*element: main:Depends on nothing, Changes [] field static.*/
main() {
  stringInterpolation();
}
