// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 *
 * Encoders and decoders for converting between different data representations,
 * including JSON and UTF-8.
 *
 * In addition to converters for common data representations, this library
 * provides support for implementing converters in a way which makes them easy to
 * chain and to use with streams.
 *
 * The `dart:convert` library works in both web apps and command-line apps.
 * To use it:
 *
 *     import 'dart:convert';
 *
 * Two commonly used converters are the top-level instances of
 * [JsonCodec] and [Utf8Codec], named JSON and UTF8, respectively.
 *
 * JSON is a simple text format for representing
 * structured objects and collections.
 * The JSON encoder/decoder transforms between strings and
 * object structures, such as lists and maps, using the JSON format.
 *
 * UTF-8 is a common variable-width encoding that can represent
 * every character in the Unicode character set.
 * The UTF-8 encoder/decoder transforms between Strings and bytes.
 *
 * Converters are often used with streams
 * to transform the data that comes through the stream
 * as it becomes available.
 * The following code uses two converters.
 * The first is a UTF-8 decoder, which converts the data from bytes to UTF-8
 * as it's read from a file,
 * The second is an instance of [LineSplitter],
 * which splits the data on newline boundaries.
 *
 *     int lineNumber = 1;
 *     Stream<List<int>> stream = new File('quotes.txt').openRead();
 *
 *     stream.transform(UTF8.decoder)
 *           .transform(const LineSplitter())
 *           .listen((line) {
 *             if (showLineNumbers) {
 *               stdout.write('${lineNumber++} ');
 *             }
 *             stdout.writeln(line);
 *           });
 *
 * See the documentation for the [Codec] and [Converter] classes
 * for information about creating your own converters.
 */
library dart.convert;

import 'dart:async';
import 'dart:typed_data';

part 'ascii.dart';
part 'byte_conversion.dart';
part 'chunked_conversion.dart';
part 'codec.dart';
part 'converter.dart';
part 'encoding.dart';
part 'html_escape.dart';
part 'json.dart';
part 'latin1.dart';
part 'line_splitter.dart';
part 'string_conversion.dart';
part 'utf.dart';
