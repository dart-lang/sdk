// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// The diagnostics for a library, and the requirements for using them.
///
/// When fine-grained dependencies are enabled, we compute this bundle for a
/// library, and store it in the byte store. When we need diagnostics for a
/// file from this library, we retrieve the bundle, and check if the
/// requirements are satisfied. If they are, we can reuse the diagnostics.
/// Otherwise, we need to re-analyze the library.
class LibraryDiagnosticsBundle {
  final ManifestItemId id;
  final Uint8List requirementsBytes;
  RequirementsManifest? _requirements;

  /// A map from the URI of a file in the library to the serialized bytes of
  /// its analysis results. The bytes represent an `AnalysisDriverResolvedUnit`,
  /// which includes diagnostics and the index.
  final Map<Uri, Uint8List> serializedFileResults;

  factory LibraryDiagnosticsBundle.fromBytes(Uint8List bytes) {
    var reader = BinaryReader(bytes);
    reader.initFromTableTrailer();
    return LibraryDiagnosticsBundle._(
      id: ManifestItemId.read(reader),
      requirementsBytes: reader.readUint8List(),
      serializedFileResults: reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () => reader.readUint8List(),
      ),
    );
  }

  LibraryDiagnosticsBundle._({
    required this.id,
    required this.requirementsBytes,
    required this.serializedFileResults,
  });

  RequirementsManifest get requirements {
    return _requirements ??= RequirementsManifest.fromBytes(requirementsBytes);
  }

  bool isDigestSatisfied({
    required ByteStore byteStore,
    required LinkedElementFactory elementFactory,
    required String bundleKey,
  }) {
    var digestKey = _getDigestKey(bundleKey);
    var digestBytes = byteStore.get(digestKey);
    if (digestBytes == null) {
      return false;
    }

    var digest = RequirementsManifestDigest.fromBytes(digestBytes);
    return digest.bundleId == id && digest.isSatisfied(elementFactory);
  }

  static void write({
    required ByteStore byteStore,
    required String key,
    required ManifestItemId id,
    required RequirementsManifest requirements,
    required Map<Uri, Uint8List> serializedFileResults,
    required OperationPerformanceImpl performance,
  }) {
    var writer = BinaryWriter();
    id.write(writer);

    var requirementsBytes = requirements.toBytes();
    writer.writeUint8List(requirementsBytes);

    writer.writeMap(
      serializedFileResults,
      writeKey: (uri) => writer.writeUri(uri),
      writeValue: (bytes) => writer.writeUint8List(bytes),
    );

    writer.writeTableTrailer();
    var bytes = writer.takeBytes();

    performance.getDataInt('bytes').add(bytes.length);
    byteStore.putGet(key, bytes);
  }

  /// Writes the digest of [requirements] under a separate key.
  static void writeDigest({
    required ByteStore byteStore,
    required LinkedElementFactory elementFactory,
    required String bundleKey,
    required ManifestItemId bundleId,
    required RequirementsManifest requirements,
  }) {
    byteStore.putGet(
      _getDigestKey(bundleKey),
      requirements
          .toDigest(elementFactory: elementFactory, bundleId: bundleId)
          .toBytes(),
    );
  }

  static String _getDigestKey(String bundleKey) {
    return '$bundleKey.digest';
  }
}
