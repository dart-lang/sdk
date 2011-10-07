// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBKeyRangeWrappingImplementation extends DOMWrapperBase implements IDBKeyRange {
  IDBKeyRangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBKey get lower() { return LevelDom.wrapIDBKey(_ptr.lower); }

  bool get lowerOpen() { return _ptr.lowerOpen; }

  IDBKey get upper() { return LevelDom.wrapIDBKey(_ptr.upper); }

  bool get upperOpen() { return _ptr.upperOpen; }

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) {
    if (lowerOpen === null) {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper)));
      }
    } else {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen));
      } else {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen, upperOpen));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound), open));
    }
  }

  IDBKeyRange only(IDBKey value) {
    return LevelDom.wrapIDBKeyRange(_ptr.only(LevelDom.unwrap(value)));
  }

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound), open));
    }
  }
}
