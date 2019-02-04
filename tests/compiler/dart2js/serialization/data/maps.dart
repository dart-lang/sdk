// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  createMap();
  createDictionary();
  returnUnion(true);
  returnUnion(false);
}

createMap() => {0: 1};

createDictionary() => {'foo': 'bar'};

returnUnion(bool b) => b ? createMap() : createDictionary();
