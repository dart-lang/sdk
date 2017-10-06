// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:test/test.dart';

/// Test metadata: to each node we attach a metadata that contains
/// a reference to this node's parent and this node formatted as string.
class Metadata {
  final Node parent;
  final String self;

  Metadata.forNode(Node n)
      : parent = n is TreeNode && MetadataRepository.isSupported(n.parent)
            ? n.parent
            : null,
        self = n.toString();

  Metadata(this.parent, this.self);
}

class TestMetadataRepository extends MetadataRepository<Metadata> {
  static const kTag = 'kernel.metadata.test';

  final String tag = kTag;

  final Map<Node, Metadata> mapping = <Node, Metadata>{};

  void writeToBinary(Metadata metadata, BinarySink sink) {
    sink.writeNodeReference(metadata.parent);
    sink.writeByteList(UTF8.encode(metadata.self));
  }

  Metadata readFromBinary(BinarySource source) {
    final parent = source.readNodeReference();
    final string = UTF8.decode(source.readByteList());
    return new Metadata(parent, string);
  }
}

class BytesBuilderSink implements Sink<List<int>> {
  final builder = new BytesBuilder(copy: false);

  @override
  void add(List<int> bytes) {
    builder.add(bytes);
  }

  @override
  void close() {}
}

/// Visitor that assigns [Metadata] object created with [Metadata.forNode] to
/// each supported node in the program.
class Annotator extends RecursiveVisitor<Null> {
  final TestMetadataRepository repository;

  Annotator(Program program)
      : repository = program.metadata[TestMetadataRepository.kTag];

  defaultNode(Node node) {
    super.defaultNode(node);
    if (MetadataRepository.isSupported(node)) {
      repository.mapping[node] = new Metadata.forNode(node);
    }
  }

  static void annotate(Program p) {
    globalDebuggingNames = new NameSystem();
    p.accept(new Annotator(p));
  }
}

/// Visitor that checks that each supported node in the program has correct
/// metadata.
class Validator extends RecursiveVisitor<Null> {
  final TestMetadataRepository repository;

  Validator(Program program)
      : repository = program.metadata[TestMetadataRepository.kTag];

  defaultNode(Node node) {
    super.defaultNode(node);
    if (MetadataRepository.isSupported(node)) {
      final m = repository.mapping[node];
      final expected = new Metadata.forNode(node);

      expect(m.parent, equals(expected.parent));
      expect(m.self, equals(expected.self));
    }
  }

  static void validate(Program p) {
    globalDebuggingNames = new NameSystem();
    p.accept(new Validator(p));
  }
}

Program fromBinary(List<int> bytes) {
  var program = new Program();
  program.addMetadataRepository(new TestMetadataRepository());
  new BinaryBuilderWithMetadata(bytes).readSingleFileProgram(program);
  return program;
}

List<int> toBinary(Program p) {
  final sink = new BytesBuilderSink();
  new BinaryPrinter(sink).writeProgramFile(p);
  return sink.builder.takeBytes();
}

main() {
  test('annotate-serialize-deserialize-validate', () async {
    final Uri platform = Uri.base
        .resolve(Platform.resolvedExecutable)
        .resolve("vm_platform.dill");
    final List<int> platformBinary =
        await new File(platform.toFilePath()).readAsBytes();

    final program = fromBinary(platformBinary);
    Annotator.annotate(program);
    Validator.validate(program);

    final annotatedProgramBinary = toBinary(program);
    final annotatedProgramFromBinary = fromBinary(annotatedProgramBinary);
    Validator.validate(annotatedProgramFromBinary);
  });
}
