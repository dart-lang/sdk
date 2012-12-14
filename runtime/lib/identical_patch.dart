// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch bool identical(Object a, Object b) {
  throw new Error('Should not reach the body of identical');  
}
