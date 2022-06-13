// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import "dart:_internal"
    show
        allocateOneByteString,
        allocateTwoByteString,
        CodeUnits,
        ClassID,
        copyRangeFromUint8ListToOneByteString,
        doubleToIntBits,
        EfficientLengthIterable,
        FixedLengthListMixin,
        IterableElementError,
        ListIterator,
        Lists,
        mix64,
        POWERS_OF_TEN,
        SubListIterable,
        UnmodifiableListMixin,
        has63BitSmis,
        makeFixedListUnmodifiable,
        makeListFixedLength,
        patch,
        unsafeCast,
        writeIntoOneByteString,
        writeIntoTwoByteString;

import "dart:collection"
    show
        HashMap,
        IterableBase,
        LinkedHashMap,
        LinkedList,
        LinkedListEntry,
        ListBase,
        MapBase,
        Maps,
        UnmodifiableMapBase,
        UnmodifiableMapView;

import 'dart:math' show Random;

import "dart:typed_data"
    show Endian, Uint8List, Int64List, Uint16List, Uint32List;

import 'dart:wasm';

typedef _Smi = int; // For compatibility with VM patch files
