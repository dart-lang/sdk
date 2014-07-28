// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf.constants;

/**
 * Invalid codepoints or encodings may be substituted with the value U+fffd.
 */
const int UNICODE_REPLACEMENT_CHARACTER_CODEPOINT = 0xfffd;
const int UNICODE_BOM = 0xfeff;
const int UNICODE_UTF_BOM_LO = 0xff;
const int UNICODE_UTF_BOM_HI = 0xfe;

const int UNICODE_BYTE_ZERO_MASK = 0xff;
const int UNICODE_BYTE_ONE_MASK = 0xff00;
const int UNICODE_VALID_RANGE_MAX = 0x10ffff;
const int UNICODE_PLANE_ONE_MAX = 0xffff;
const int UNICODE_UTF16_RESERVED_LO = 0xd800;
const int UNICODE_UTF16_RESERVED_HI = 0xdfff;
const int UNICODE_UTF16_OFFSET = 0x10000;
const int UNICODE_UTF16_SURROGATE_UNIT_0_BASE = 0xd800;
const int UNICODE_UTF16_SURROGATE_UNIT_1_BASE = 0xdc00;
const int UNICODE_UTF16_HI_MASK = 0xffc00;
const int UNICODE_UTF16_LO_MASK = 0x3ff;
