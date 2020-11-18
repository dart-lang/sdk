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
      : this(
            n.leakingDebugToString(),
            // Refers to the member, not about the function => use getter.
            getMemberReferenceGetter(getMemberForMetadata(n)),
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
    return new TypeParameterType(parent.typeParameters[0], Nullability.legacy);
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

typedef NodePredicate = bool Function(TreeNode node);

/// Visitor calling [handle] function on every node which can have metadata
/// associated with it and also satisfies the given [predicate].
class Visitor extends RecursiveVisitor<Null> {
  final NodePredicate predicate;
  final void Function(TreeNode) handle;

  Visitor(this.predicate, this.handle);

  defaultTreeNode(TreeNode node) {
    super.defaultTreeNode(node);
    if (MetadataRepository.isSupported(node) && predicate(node)) {
      handle(node);
    }
  }
}

/// Visit the given component assigning [Metadata] object created with
/// [Metadata.forNode] to each supported node in the component which matches
/// [shouldAnnotate] predicate.
void annotate(Component p, NodePredicate shouldAnnotate) {
  globalDebuggingNames = new NameSystem();
  final repository = p.metadata[TestMetadataRepository.kTag];
  p.accept(new Visitor(shouldAnnotate, (node) {
    repository.mapping[node] = new Metadata.forNode(node);
  }));
}

/// Visit the given component and checks that each supported node in the
/// component matching [shouldAnnotate] predicate has correct metadata.
void validate(Component p, NodePredicate shouldAnnotate) {
  globalDebuggingNames = new NameSystem();
  final repository = p.metadata[TestMetadataRepository.kTag];
  p.accept(new Visitor(shouldAnnotate, (node) {
    final m = repository.mapping[node];
    final expected = new Metadata.forNode(node);

    expect(m, isNotNull);
    expect(m.string, equals(expected.string));
    expect(m.member, equals(expected.member));
    expect(m.type, equals(expected.type));
  }));
}

Component fromBinary(List<int> bytes) {
  var component = new Component();
  component.addMetadataRepository(new TestMetadataRepository());
  new BinaryBuilderWithMetadata(bytes).readComponent(component);
  return component;
}

List<int> toBinary(Component p) {
  final sink = new BytesBuilderSink();
  new BinaryPrinter(sink).writeComponentFile(p);
  return sink.builder.takeBytes();
}

main() async {
  bool anyNode(TreeNode node) => true;
  bool onlyMethods(TreeNode node) =>
      node is Procedure &&
      node.kind == ProcedureKind.Method &&
      node.enclosingClass != null;

  final Uri platform = computePlatformBinariesLocation(forceBuildDir: true)
      .resolve("vm_platform_strong.dill");
  final List<int> platformBinary =
      await new File(platform.toFilePath()).readAsBytes();

  Future<void> testRoundTrip(List<int> Function(List<int>) binaryTransformer,
      NodePredicate shouldAnnotate) async {
    final component = fromBinary(platformBinary);
    annotate(component, shouldAnnotate);
    validate(component, shouldAnnotate);
    expect(component.metadata[TestMetadataRepository.kTag].mapping.length,
        greaterThan(0));

    final annotatedComponentBinary = binaryTransformer(toBinary(component));
    final annotatedComponentFromBinary = fromBinary(annotatedComponentBinary);
    validate(annotatedComponentFromBinary, shouldAnnotate);
    expect(
        annotatedComponentFromBinary
            .metadata[TestMetadataRepository.kTag].mapping.length,
        greaterThan(0));
  }

  test('annotate-serialize-deserialize-validate', () async {
    await testRoundTrip((binary) => binary, anyNode);
  });

  test('annotate-serialize-deserialize-validate-only-methods', () async {
    await testRoundTrip((binary) => binary, onlyMethods);
  });

  test('annotate-serialize-deserialize-twice-then-validate', () async {
    // This test validates that serializing a component that was just
    // deserialized (without visiting anything) works.
    await testRoundTrip((binary) => toBinary(fromBinary(binary)), anyNode);
  });

  test('annotate-serialize-deserialize-twice-then-validate-only-methods',
      () async {
    // This test validates that serializing a component that was just
    // deserialized (without visiting anything) works.
    await testRoundTrip((binary) => toBinary(fromBinary(binary)), onlyMethods);
  });
}
