// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_collection_literals`

import 'dart:collection';

void main() {
  var listToLint = new List(); //LINT
  var mapToLint = new Map(); // LINT
  var LinkedHashMapToLint = new LinkedHashMap(); // LINT

  var constructedListInsideLiteralList = [[], new List()]; // LINT

  var literalListInsideLiteralList = [[], []]; // OK

  var fiveLengthList = new List(5); // OK

  var namedConstructorList = new List.filled(5, true); // OK
  var namedConstructorMap = new Map.identity(); // OK
  var namedConstructorLinkedHashMap = new LinkedHashMap.identity(); // OK

  var literalList = []; // OK
  var literalMap = {}; // OK
}
