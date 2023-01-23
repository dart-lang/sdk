// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
        intBitsToDouble,
        IterableElementError,
        jsonEncode,
        ListIterator,
        Lists,
        mix64,
        POWERS_OF_TEN,
        SubListIterable,
        UnmodifiableListMixin,
        makeFixedListUnmodifiable,
        makeListFixedLength,
        patch,
        unsafeCast,
        writeIntoOneByteString,
        writeIntoTwoByteString;

import "dart:_internal" as _internal show Symbol;

import 'dart:_js_helper' show JSSyntaxRegExp, quoteStringForRegExp;

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

import 'dart:convert' show Encoding, utf8;

import 'dart:math' show Random;

import "dart:typed_data" show Uint8List, Uint16List;

import 'dart:wasm';

part "bool.dart";
part "date_patch.dart";
part "double.dart";
part "errors_patch.dart";
part "function.dart";
part "growable_list.dart";
part "identical_patch.dart";
part "int.dart";
part "list.dart";
part "object_patch.dart";
part "regexp_patch.dart";
part "stack_trace_patch.dart";
part "stopwatch_patch.dart";
part "string_buffer_patch.dart";
part "string_patch.dart";
part "type.dart";
part "uri_patch.dart";

typedef _Smi = int; // For compatibility with VM patch files

String _symbolToString(Symbol s) =>
    _internal.Symbol.getName(s as _internal.Symbol);
