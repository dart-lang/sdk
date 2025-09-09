// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/fine/requirements.dart';

/// The diagnostics for a library, and the requirements for using them.
///
/// When fine-grained dependencies are enabled, we compute this bundle for a
/// library, and store it in the byte store. When we need diagnostics for a
/// file from this library, we retrieve the bundle, and check if the
/// requirements are satisfied. If they are, we can reuse the diagnostics.
/// Otherwise, we need to re-analyze the library.
class LibraryDiagnosticsBundle {
  final RequirementsManifest requirements;

  /// The last API signature that we have checked.
  String? _validatedApiSignature;

  /// A map from the URI of a file in the library to the serialized bytes of
  /// its analysis results. The bytes represent an `AnalysisDriverResolvedUnit`,
  /// which includes diagnostics and the index.
  final Map<Uri, Uint8List> serializedFileResults;

  LibraryDiagnosticsBundle({
    required this.requirements,
    required this.serializedFileResults,
  });

  factory LibraryDiagnosticsBundle.fromBytes(Uint8List bytes) {
    var reader = SummaryDataReader(bytes);
    return LibraryDiagnosticsBundle(
      requirements: RequirementsManifest.read(reader),
      serializedFileResults: reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () => reader.readUint8List(),
      ),
    );
  }

  void addValidated(String apiSignature) {
    _validatedApiSignature = apiSignature;
  }

  bool isValidated(String apiSignature) {
    return _validatedApiSignature == apiSignature;
  }

  Uint8List toBytes() {
    var sink = BufferedSink();
    requirements.write(sink);
    sink.writeMap(
      serializedFileResults,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (bytes) => sink.writeUint8List(bytes),
    );
    return sink.takeBytes();
  }
}
