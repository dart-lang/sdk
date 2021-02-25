// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.loading_units;

import 'package:kernel/ast.dart';

class LoadingUnit {
  final int id;
  final int parentId;
  final List<String> libraryUris;

  LoadingUnit(this.id, this.parentId, this.libraryUris);

  String toString() {
    var sb = new StringBuffer();
    sb.writeln("LoadingUnit(id=$id, parent=${parentId},");
    for (var uri in libraryUris) {
      sb.writeln("  $uri");
    }
    sb.write(")");
    return sb.toString();
  }
}

class LoadingUnitsMetadata {
  final List<LoadingUnit> loadingUnits;

  LoadingUnitsMetadata(this.loadingUnits);

  String toString() {
    var sb = new StringBuffer();
    sb.writeln("LoadingUnitsMetadata(");
    for (var unit in loadingUnits) {
      sb.writeln(unit.toString());
    }
    sb.write(")");
    return sb.toString();
  }
}

/// Repository for [LoadingUnitsMetadata].
class LoadingUnitsMetadataRepository
    extends MetadataRepository<LoadingUnitsMetadata> {
  static final repositoryTag = 'vm.loading-units.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, LoadingUnitsMetadata> mapping =
      <TreeNode, LoadingUnitsMetadata>{};

  @override
  void writeToBinary(
      LoadingUnitsMetadata metadata, Node node, BinarySink sink) {
    sink.writeUInt30(metadata.loadingUnits.length);
    for (LoadingUnit unit in metadata.loadingUnits) {
      sink.writeUInt30(unit.id);
      sink.writeUInt30(unit.parentId);
      sink.writeUInt30(unit.libraryUris.length);
      for (String uri in unit.libraryUris) {
        sink.writeStringReference(uri);
      }
    }
  }

  @override
  LoadingUnitsMetadata readFromBinary(Node node, BinarySource source) {
    int length = source.readUInt30();
    var units = <LoadingUnit>[];
    for (int i = 0; i < length; i++) {
      int id = source.readUInt30();
      int parentId = source.readUInt30();
      var libraryUris = <String>[];
      int length = source.readUInt30();
      for (int i = 0; i < length; i++) {
        libraryUris.add(source.readStringReference());
      }
      units.add(new LoadingUnit(id, parentId, libraryUris));
    }
    return new LoadingUnitsMetadata(units);
  }
}
