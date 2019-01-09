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
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

/// Test metadata: to each node we attach a metadata that contains
/// * node formatted as string
/// * reference to its enclosing member
/// * type representing the first type parameter of its enclosing function
class Metadata {
  final String string;
  final Reference _memberRef;
  final DartType type;

  Member get member => _memberRef?.asMember;

  Metadata.forNode(TreeNode n)
      : this(n.toString(), getMemberReference(getMemberForMetadata(n)),
            getTypeForMetadata(n));

  Metadata(this.string, this._memberRef, this.type);
}

Member getMemberForMetadata(TreeNode node) {
  final parent = node.parent;
  if (parent == null) return null;
  if (parent is Member) return parent;
  return getMemberForMetadata(parent);
}

DartType getTypeForMetadata(TreeNode node) {
  final parent = node.parent;
  if (parent == null) return const VoidType();
  if (parent is FunctionNode) {
    if (parent.typeParameters.isEmpty) {
      return const VoidType();
    }
    return new TypeParameterType(parent.typeParameters[0]);
  }
  return getTypeForMetadata(parent);
}

class TestMetadataRepository extends MetadataRepository<Metadata> {
  static const kTag = 'kernel.metadata.test';

  final String tag = kTag;

  final Map<TreeNode, Metadata> mapping = <TreeNode, Metadata>{};

  void writeToBinary(Metadata metadata, Node node, BinarySink sink) {
    expect(metadata, equals(mapping[node]));
    sink.writeByteList(utf8.encode(metadata.string));
    sink.writeStringReference(metadata.string);
    sink.writeNullAllowedCanonicalNameReference(metadata.member?.canonicalName);
    sink.writeDartType(metadata.type);
  }

  Metadata readFromBinary(Node node, BinarySource source) {
    final string1 = utf8.decode(source.readByteList());
    final string2 = source.readStringReference();
    final memberRef = source.readCanonicalNameReference()?.reference;
    final type = source.readDartType();
    expect(string1, equals(string2));
    return new Metadata(string2, memberRef, type);
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
/// each supported node in the component.
class Annotator extends RecursiveVisitor<Null> {
  final TestMetadataRepository repository;

  Annotator(Component component)
      : repository = component.metadata[TestMetadataRepository.kTag];

  defaultTreeNode(TreeNode node) {
    super.defaultTreeNode(node);
    if (MetadataRepository.isSupported(node)) {
      repository.mapping[node] = new Metadata.forNode(node);
    }
  }

  static void annotate(Component p) {
    globalDebuggingNames = new NameSystem();
    p.accept(new Annotator(p));
  }
}

/// Visitor that checks that each supported node in the component has correct
/// metadata.
class Validator extends RecursiveVisitor<Null> {
  final TestMetadataRepository repository;

  Validator(Component component)
      : repository = component.metadata[TestMetadataRepository.kTag];

  defaultTreeNode(TreeNode node) {
    super.defaultTreeNode(node);
    if (MetadataRepository.isSupported(node)) {
      final m = repository.mapping[node];
      final expected = new Metadata.forNode(node);

      expect(m.string, equals(expected.string));
      expect(m.member, equals(expected.member));
      expect(m.type, equals(expected.type));
    }
  }

  static void validate(Component p) {
    globalDebuggingNames = new NameSystem();
    p.accept(new Validator(p));
  }
}

Component fromBinary(List<int> bytes) {
  var component = new Component();
  component.addMetadataRepository(new TestMetadataRepository());
  new BinaryBuilderWithMetadata(bytes).readSingleFileComponent(component);
  return component;
}

List<int> toBinary(Component p) {
  final sink = new BytesBuilderSink();
  new BinaryPrinter(sink).writeComponentFile(p);
  return sink.builder.takeBytes();
}

main() {
  test('annotate-serialize-deserialize-validate', () async {
    final Uri platform = computePlatformBinariesLocation(forceBuildDir: true)
        .resolve("vm_platform_strong.dill");
    final List<int> platformBinary =
        await new File(platform.toFilePath()).readAsBytes();

    final component = fromBinary(platformBinary);
    Annotator.annotate(component);
    Validator.validate(component);

    final annotatedComponentBinary = toBinary(component);
    final annotatedComponentFromBinary = fromBinary(annotatedComponentBinary);
    Validator.validate(annotatedComponentFromBinary);
  });
}
