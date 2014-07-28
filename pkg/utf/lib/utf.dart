// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for encoding and decoding Unicode characters in UTF-8, UTF-16, and
 * UTF-32.
 */
library utf;

import "dart:async";
import "dart:collection";

import "src/constants.dart";
import 'src/utf_16_code_unit_decoder.dart';
import 'src/list_range.dart';
import 'src/util.dart';

export 'src/constants.dart';
export 'src/utf_16_code_unit_decoder.dart';

part "src/utf/utf_stream.dart";
part "src/utf/utf8.dart";
part "src/utf/utf16.dart";
part "src/utf/utf32.dart";
