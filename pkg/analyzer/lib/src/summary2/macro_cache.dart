// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

class MacroCacheBundle {
  final List<MacroCacheLibrary> libraries;

  MacroCacheBundle({
    required this.libraries,
  });

  factory MacroCacheBundle.fromBytes(
    LibraryCycle cycle,
    Uint8List bytes,
  ) {
    return MacroCacheBundle.read(
      cycle,
      SummaryDataReader(bytes),
    );
  }

  factory MacroCacheBundle.read(
    LibraryCycle cycle,
    SummaryDataReader reader,
  ) {
    return MacroCacheBundle(
      libraries: reader.readTypedList(
        () => MacroCacheLibrary.read(cycle, reader),
      ),
    );
  }

  Uint8List toBytes() {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);
    write(sink);
    return sink.flushAndTake();
  }

  void write(BufferedSink sink) {
    sink.writeList(libraries, (library) {
      library.write(sink);
    });
  }
}

class MacroCacheLibrary {
  /// The file view of the library.
  final LibraryFileKind kind;

  /// The combination of API signatures of all library files.
  final Uint8List apiSignature;

  /// Whether any macro of the library introspected anything.
  final bool hasAnyIntrospection;

  final String code;

  MacroCacheLibrary({
    required this.kind,
    required this.apiSignature,
    required this.hasAnyIntrospection,
    required this.code,
  });

  factory MacroCacheLibrary.read(
    LibraryCycle cycle,
    SummaryDataReader reader,
  ) {
    var path = reader.readStringUtf8();
    return MacroCacheLibrary(
      // This is safe because the key of the bundle depends on paths.
      kind: cycle.libraries.firstWhere((e) => e.file.path == path),
      apiSignature: reader.readUint8List(),
      hasAnyIntrospection: reader.readBool(),
      code: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(kind.file.path);
    sink.writeUint8List(apiSignature);
    sink.writeBool(hasAnyIntrospection);
    sink.writeStringUtf8(code);
  }
}
