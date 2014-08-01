// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library to create and parse source maps.
///
/// Create a source map using [SourceMapBuilder]. For example:
///     var json = (new SourceMapBuilder()
///         ..add(inputSpan1, outputSpan1)
///         ..add(inputSpan2, outputSpan2)
///         ..add(inputSpan3, outputSpan3)
///         .toJson(outputFile);
///
/// Use the source_span package's [SourceSpan] and [SourceFile] classes to
/// specify span locations.
///
/// Parse a source map using [parse], and call `spanFor` on the returned mapping
/// object. For example:
///     var mapping = parse(json);
///     mapping.spanFor(outputSpan1.line, outputSpan1.column)
///
/// ## Getting the code ##
///
/// This library is distributed as a [pub][] package. To install this package,
/// add the following to your `pubspec.yaml` file:
///
///     dependencies:
///       source_maps: any
///
/// After you run `pub install`, you should be able to access this library by
/// importing `package:source_maps/source_maps.dart`.
///
/// For more information, see the
/// [source_maps package on pub.dartlang.org][pkg].
///
/// [pub]: http://pub.dartlang.org
/// [pkg]: http://pub.dartlang.org/packages/source_maps
library source_maps;

export "builder.dart";
export "parser.dart";
export "printer.dart";
export "refactor.dart";
export 'src/source_map_span.dart';
