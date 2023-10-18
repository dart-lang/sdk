// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal"
    show
        CodeUnits,
        ClassID,
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
        unsafeCast;

import "dart:_internal" as _internal show Symbol;

import 'dart:_js_helper' show JS, JSSyntaxRegExp, quoteStringForRegExp;

import 'dart:_js_types' show JSStringImpl;

import "dart:collection"
    show
        HashMap,
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

import 'dart:_object_helper';
import 'dart:_string_helper';

import 'dart:_wasm';

part "bool.dart";
part "closure.dart";
part "double_patch.dart";
part "errors_patch.dart";
part "growable_list.dart";
part "identical_patch.dart";
part "list.dart";
part "named_parameters.dart";
part "object_patch.dart";
part "record_patch.dart";
part "regexp_patch.dart";
part "stack_trace_patch.dart";
part "stopwatch_patch.dart";
part "type.dart";
part "uri_patch.dart";

typedef _Smi = int; // For compatibility with VM patch files

String _symbolToString(Symbol s) =>
    _internal.Symbol.getName(s as _internal.Symbol);
