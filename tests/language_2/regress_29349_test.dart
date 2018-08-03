// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<T> get<T>(T item) => <T>[item];
List<T> get2<T>(T item) => <T>[item];

void main() {
 print(get(1));
 print(get2(1));
}
