// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Converters for JSON and UTF-8, as well as support for creating additional 
 * converters.
 */
library dart.convert;

import 'dart:async';
import 'dart:json' as OLD_JSON_LIB;

part 'byte_conversion.dart';
part 'chunked_conversion.dart';
part 'codec.dart';
part 'converter.dart';
part 'encoding.dart';
part 'json.dart';
part 'line_splitter.dart';
part 'string_conversion.dart';
part 'utf.dart';
