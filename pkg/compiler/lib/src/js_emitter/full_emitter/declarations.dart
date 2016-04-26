// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.full_emitter;

/// Enables debugging of fast/slow objects using V8-specific primitives.
const DEBUG_FAST_OBJECTS = false;

/**
 * Call-back for adding property with [name] and [value].
 */
typedef jsAst.Property AddPropertyFunction(
    jsAst.Name name, jsAst.Expression value);

// Compact field specifications.  The format of the field specification is
// <accessorName>:<fieldName><suffix> where the suffix and accessor name
// prefix are optional.  The suffix directs the generation of getter and
// setter methods.  Each of the getter and setter has two bits to determine
// the calling convention.  Setter listed below, getter is similar.
//
//     00: no setter
//     01: function(value) { this.field = value; }
//     10: function(receiver, value) { receiver.field = value; }
//     11: function(receiver, value) { this.field = value; }
//
// The suffix encodes 4 bits using three ASCII ranges of non-identifier
// characters.
const FIELD_CODE_CHARACTERS = r"<=>?@{|}~%&'()*";
const NO_FIELD_CODE = 0;
const FIRST_FIELD_CODE = 1;
const RANGE1_FIRST = 0x3c; //  <=>?@    encodes 1..5
const RANGE1_LAST = 0x40;
const RANGE2_FIRST = 0x7b; //  {|}~     encodes 6..9
const RANGE2_LAST = 0x7e;
const RANGE3_FIRST = 0x25; //  %&'()*+  encodes 10..16
const RANGE3_LAST = 0x2b;
