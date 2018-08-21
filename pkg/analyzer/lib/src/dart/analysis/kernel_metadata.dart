// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:front_end/src/fasta/builder/qualified_name.dart';
import 'package:front_end/src/fasta/kernel/metadata_collector.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart' as kernel;

/// Additional information that Analyzer needs for nodes.
class AnalyzerMetadata {
  /// The offset of the beginning of the node code.
  int codeOffset = -1;

  /// The length of the node code.
  int codeLength = 0;

  /// If the node is a named constructor, the offset of the name.
  /// Otherwise `-1`.
  int constructorNameOffset = -1;

  /// Optional documentation comment, may be `null`.
  String documentationComment;

  /// If the node is an import library dependency, the offset of the prefix.
  /// Otherwise `-1`.
  int importPrefixOffset = -1;

  /// Return the [AnalyzerMetadata] for the [node], or `null` absent.
  static AnalyzerMetadata forNode(kernel.TreeNode node) {
    var repository =
        node.enclosingComponent.metadata[AnalyzerMetadataRepository.TAG];
    if (repository != null) {
      return repository.mapping[node];
    }
    return null;
  }
}

/// Analyzer specific implementation of [MetadataCollector].
class AnalyzerMetadataCollector implements MetadataCollector {
  @override
  final AnalyzerMetadataRepository repository =
      new AnalyzerMetadataRepository();

  @override
  void setCodeStartEnd(kernel.TreeNode node, int start, int end) {
    var metadata = repository._forWriting(node);
    metadata.codeOffset = start;
    metadata.codeLength = end - start;
  }

  @override
  void setConstructorNameOffset(kernel.Member node, Object name) {
    if (name is QualifiedName) {
      var metadata = repository._forWriting(node);
      metadata.constructorNameOffset = name.charOffset;
    }
  }

  @override
  void setDocumentationComment(kernel.NamedNode node, String comment) {
    var metadata = repository._forWriting(node);
    metadata.documentationComment = comment;
  }

  @override
  void setImportPrefixOffset(kernel.LibraryDependency node, int offset) {
    var metadata = repository._forWriting(node);
    metadata.importPrefixOffset = offset;
  }
}

/// Factory for creating Analyzer specific sink and repository.
class AnalyzerMetadataFactory implements MetadataFactory {
  @override
  int get version => 1;

  @override
  MetadataCollector newCollector() {
    return new AnalyzerMetadataCollector();
  }

  @override
  kernel.MetadataRepository newRepositoryForReading() {
    return new AnalyzerMetadataRepository();
  }
}

/// Index of metadata.
class AnalyzerMetadataIndex {
  final Map<kernel.Library, List<kernel.TreeNode>> libraryNodes = {};
  AnalyzerMetadataRepository repository;

  /// The [library] was invalidated, flush its metadata.
  void invalidate(kernel.Library library) {
    var nodes = libraryNodes.remove(library);
    nodes?.forEach(repository.mapping.remove);
  }

  /// A [newComponent] has been compiled, with new, and only new, metadata.
  /// Merge the existing [repository] into the new one, and replace it.
  void replaceComponent(kernel.Component newComponent) {
    AnalyzerMetadataRepository newRepository =
        newComponent.metadata[AnalyzerMetadataRepository.TAG];
    if (newRepository != null) {
      _indexNewMetadata(newRepository);
      if (repository != null) {
        // Copy the new (partial) metadata into the existing metadata repository
        // and replace the reference to the partial data with the full data.
        repository.mapping.addAll(newRepository.mapping);
        newComponent.metadata[AnalyzerMetadataRepository.TAG] = repository;
      } else {
        repository = newRepository;
      }
    } else {
      newComponent.metadata[AnalyzerMetadataRepository.TAG] = repository;
    }
  }

  void _indexNewMetadata(AnalyzerMetadataRepository newRepository) {
    for (var node in newRepository.mapping.keys) {
      var library = _enclosingLibrary(node);
      assert(library != null);

      var nodes = libraryNodes[library];
      if (nodes == null) {
        nodes = <kernel.TreeNode>[];
        libraryNodes[library] = nodes;
      }

      nodes.add(node);
    }
  }

  static kernel.Library _enclosingLibrary(kernel.TreeNode node) {
    for (; node != null; node = node.parent) {
      if (node is kernel.Library) {
        return node;
      }
    }
    return null;
  }
}

/// Analyzer specific implementation of [kernel.MetadataRepository].
class AnalyzerMetadataRepository
    implements kernel.MetadataRepository<AnalyzerMetadata> {
  static const TAG = 'kernel.metadata.analyzer';

  @override
  final String tag = TAG;

  @override
  final Map<kernel.TreeNode, AnalyzerMetadata> mapping =
      <kernel.TreeNode, AnalyzerMetadata>{};

  @override
  AnalyzerMetadata readFromBinary(
      kernel.Node node, kernel.BinarySource source) {
    return new AnalyzerMetadata()
      ..codeOffset = _readOffset(source)
      ..codeLength = _readLength(source)
      ..constructorNameOffset = _readOffset(source)
      ..documentationComment = _readOptionalString(source)
      ..importPrefixOffset = _readOffset(source);
  }

  @override
  void writeToBinary(
      AnalyzerMetadata metadata, kernel.Node node, kernel.BinarySink sink) {
    _writeOffset(sink, metadata.codeOffset);
    _writeLength(sink, metadata.codeLength);
    _writeOffset(sink, metadata.constructorNameOffset);
    _writeOptionalString(sink, metadata.documentationComment);
    _writeOffset(sink, metadata.importPrefixOffset);
  }

  /// Return the existing or new [AnalyzerMetadata] instance for the [node].
  AnalyzerMetadata _forWriting(kernel.TreeNode node) {
    return mapping[node] ??= new AnalyzerMetadata();
  }

  int _readLength(kernel.BinarySource source) {
    return source.readUint32();
  }

  int _readOffset(kernel.BinarySource source) {
    return source.readUint32() - 1;
  }

  String _readOptionalString(kernel.BinarySource source) {
    int flag = source.readByte();
    if (flag == 1) {
      List<int> bytes = source.readByteList();
      return utf8.decode(bytes);
    } else {
      return null;
    }
  }

  /// The [length] value must be `>= 0`.
  void _writeLength(kernel.BinarySink sink, int length) {
    assert(length >= 0);
    sink.writeUInt32(length);
  }

  /// The [offset] value must be `>= -1`.
  void _writeOffset(kernel.BinarySink sink, int offset) {
    assert(offset >= -1);
    sink.writeUInt32(1 + offset);
  }

  void _writeOptionalString(kernel.BinarySink sink, String str) {
    if (str != null) {
      sink.writeByte(1);
      List<int> bytes = utf8.encode(str);
      sink.writeByteList(bytes);
    } else {
      sink.writeByte(0);
    }
  }
}
