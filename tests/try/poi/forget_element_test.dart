// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of Compiler.forgetElement.
library trydart.forget_element_test;

import 'package:compiler/src/elements/elements.dart' show
    AstElement,
    ClassElement,
    Element,
    FunctionElement,
    LocalFunctionElement,
    MetadataAnnotation,
    ScopeContainerElement,
    VariableElement;

import 'package:compiler/src/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'package:compiler/src/tree/tree.dart' as tree;

import 'package:compiler/src/parser/partial_elements.dart' show
    PartialMetadataAnnotation;

import 'package:compiler/src/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/src/compile_time_constants.dart' show
    DartConstantCompiler;

import 'package:compiler/src/universe/universe.dart' show
    Universe;

import 'package:compiler/src/dart_types.dart' show
    DartType;

import 'compiler_test_case.dart';

import 'forget_element_assertion.dart' show
    assertUnimplementedLocalMetadata;

class ForgetElementTestCase extends CompilerTestCase {
  final int expectedClosureCount;

  final int expectedMetadataCount;

  final int expectedConstantCount;

  final int expectedInitialValueCount;

  final int expectedInitialDartValueCount;

  final int additionalClosureClassMaps;

  JavaScriptBackend get backend => compiler.backend;

  DartConstantCompiler get dartConstants =>
      backend.constantCompilerTask.dartConstantCompiler;

  Universe get codegenUniverse => compiler.enqueuer.codegen.universe;

  Universe get resolutionUniverse => compiler.enqueuer.resolution.universe;

  ForgetElementTestCase(
      String source,
      {int closureCount: 0,
       int metadataCount: 0,
       int constantCount: 0,
       int initialValueCount: 0,
       int initialDartValueCount: null,
       this.additionalClosureClassMaps: 0})
      : this.expectedClosureCount = closureCount,
        this.expectedMetadataCount = metadataCount,
        this.expectedConstantCount = constantCount,
        this.expectedInitialValueCount = initialValueCount,
        // Sometimes these numbers aren't the same. Appears to happen with
        // non-const fields, because those aren't compile-time constants in the
        // strict language specification sense.
        this.expectedInitialDartValueCount = (initialDartValueCount == null)
            ? initialValueCount : initialDartValueCount,
        super(source);

  Future run() => compile().then((LibraryElement library) {

    // Check that the compiler has recorded the expected number of closures.
    Expect.equals(
        expectedClosureCount, closuresInLibrary(library).length,
        'closure count');

    // Check that the compiler has recorded the expected number of metadata
    // annotations.
    Expect.equals(
        expectedMetadataCount, metadataInLibrary(library).length,
        'metadata count');

    // Check that the compiler has recorded the expected number of
    // constants. Since metadata is also constants, those must also be counted.
    Expect.equals(
        expectedConstantCount + expectedMetadataCount,
        constantsIn(library).length,
        'constant count');

    // Check that the compiler has recorded the expected number of initial
    // values.
    Expect.equals(
        expectedInitialValueCount,
        elementsWithJsInitialValuesIn(library).length,
        'number of fields with initial values (JS)');
    Expect.equals(
        expectedInitialDartValueCount,
        elementsWithDartInitialValuesIn(library).length,
        'number of fields with initial values (Dart)');

    // Check that the compiler has recorded the expected number of closure
    // class maps. There's always at least one, from main. Each top-level
    // element also seems to induce one.
    Expect.equals(
        expectedClosureCount + additionalClosureClassMaps,
        closureClassMapsIn(library).length - 1,
        'closure class map count ${closureClassMapsIn(library)}');


    // Forget about all elements.
    library.forEachLocalMember(compiler.forgetElement);

    // Check that all the closures were forgotten.
    Expect.isTrue(closuresInLibrary(library).isEmpty, 'closures');

    // Check that the metadata annotations were forgotten.
    Expect.isTrue(metadataInLibrary(library).isEmpty, 'metadata');

    // Check that the constants were forgotten.
    Expect.isTrue(constantsIn(library).isEmpty, 'constants');

    // Check that initial values were forgotten.
    Expect.isTrue(
        elementsWithJsInitialValuesIn(library).isEmpty,
        'fields with initial values (JS)');
    Expect.isTrue(
        elementsWithDartInitialValuesIn(library).isEmpty,
        'fields with initial values (Dart)');

    // Check that closure class maps were forgotten.
    Expect.isTrue(closureClassMapsIn(library).isEmpty, 'closure class maps');

    // Check that istantiated types and classes were forgotten.
    Expect.isTrue(
        resolutionTypesIn(library).isEmpty, 'resolution instantiatedTypes');
    Expect.isTrue(
        resolutionClassesIn(library).isEmpty, 'resolution instantiatedClasses');
    Expect.isTrue(
        codegenTypesIn(library).isEmpty, 'codegen instantiatedTypes');
    Expect.isTrue(
        codegenClassesIn(library).isEmpty, 'codegen instantiatedClasses');

    // Check that other members remembered by [Universe] were forgotten.
    Expect.isTrue(
        resolutionMembersIn(library).isEmpty, 'resolution misc members');
    Expect.isTrue(
        codegenMembersIn(library).isEmpty, 'codegen misc members');

    // Check that classes remembered by the enqueuer have been forgotten.
    Expect.isTrue(
        codegenSeenClassesIn(library).isEmpty, 'codegen seen classes');
    Expect.isTrue(
        resolutionSeenClassesIn(library).isEmpty, 'resolution seen classes');
  });

  Iterable closuresInLibrary(LibraryElement library) {
    return compiler.enqueuer.resolution.universe.allClosures.where(
        (LocalFunctionElement closure) => closure.library == library);
  }

  Iterable metadataInLibrary(LibraryElement library) {
    return backend.constants.metadataConstantMap.keys.where(
        (MetadataAnnotation metadata) {
          return metadata.annotatedElement.library == library;
        });
  }

  Iterable<tree.Node> nodesIn(LibraryElement library) {
    NodeCollector collector = new NodeCollector();
    library.forEachLocalMember((e) {
      if (e is AstElement && e.hasNode) {
        e.node.accept(collector);
      }

      // Due to quirks of history, only parameter metadata is recorded in AST
      // nodes, so they must be extracted from the elements.
      for (MetadataAnnotation metadata in e.metadata) {
        if (metadata is PartialMetadataAnnotation) {
          if (metadata.cachedNode != null) {
            metadata.cachedNode.accept(collector);
          }
        }
      }
    });

    List<MetadataAnnotation> metadata =
        (new MetadataCollector()..visit(library, null)).metadata;
    return collector.nodes;
  }

  Iterable constantsIn(LibraryElement library) {
    return nodesIn(library)
        .map((node) => backend.constants.nodeConstantMap[node])
        .where((constant) => constant != null);
  }

  Iterable elementsWithJsInitialValuesIn(LibraryElement library) {
    return backend.constants.initialVariableValues.keys.where(
        (VariableElement element) => element.library == library);
  }

  Iterable elementsWithDartInitialValuesIn(LibraryElement library) {
    return dartConstants.initialVariableValues.keys.where(
        (VariableElement element) => element.library == library);
  }

  Iterable closureClassMapsIn(LibraryElement library) {
    Map cache = compiler.closureToClassMapper.closureMappingCache;
    return nodesIn(library).where((node) => cache[node] != null);
  }

  Iterable codegenTypesIn(LibraryElement library) {
    return codegenUniverse.instantiatedTypes.where(
        (DartType type) => type.element.library == library);
  }

  Iterable codegenClassesIn(LibraryElement library) {
    return codegenUniverse.directlyInstantiatedClasses.where(
        (ClassElement cls) => cls.library == library);
  }

  Iterable codegenMembersIn(LibraryElement library) {
    sameLibrary(e) => e.library == library;
    return new Set()
        ..addAll(codegenUniverse.closurizedMembers.where(sameLibrary))
        ..addAll(codegenUniverse.fieldSetters.where(sameLibrary))
        ..addAll(codegenUniverse.fieldGetters.where(sameLibrary));
  }

  Iterable resolutionTypesIn(LibraryElement library) {
    return resolutionUniverse.instantiatedTypes.where(
        (DartType type) => type.element.library == library);
  }

  Iterable resolutionClassesIn(LibraryElement library) {
    return resolutionUniverse.directlyInstantiatedClasses.where(
        (ClassElement cls) => cls.library == library);
  }

  Iterable resolutionMembersIn(LibraryElement library) {
    sameLibrary(e) => e.library == library;
    return new Set()
        ..addAll(resolutionUniverse.closurizedMembers.where(sameLibrary))
        ..addAll(resolutionUniverse.fieldSetters.where(sameLibrary))
        ..addAll(resolutionUniverse.fieldGetters.where(sameLibrary));
  }

  Iterable codegenSeenClassesIn(LibraryElement library) {
    return compiler.enqueuer.codegen.processedClasses.where(
        (e) => e.library == library);
  }

  Iterable resolutionSeenClassesIn(LibraryElement library) {
    return compiler.enqueuer.resolution.processedClasses.where(
        (e) => e.library == library);
  }
}

class NodeCollector extends tree.Visitor {
  final List<tree.Node> nodes = <tree.Node>[];

  void visitNode(tree.Node node) {
    nodes.add(node);
    node.visitChildren(this);
  }
}

class MetadataCollector extends ElementVisitor {
  final List<MetadataAnnotation> metadata = <MetadataAnnotation>[];

  void visitElement(Element e, _) {
    metadata.addAll(e.metadata.toList());
  }

  void visitScopeContainerElement(ScopeContainerElement e, _) {
    super.visitScopeContainerElement(e);
    e.forEachLocalMember(this.visit);
  }

  void visitFunctionElement(FunctionElement e, _) {
    super.visitFunctionElement(e);
    if (e.hasFunctionSignature) {
      e.functionSignature.forEachParameter(this.visit);
    }
  }
}

void main() {
  runTests(tests);
}

List<CompilerTestCase> get tests => <CompilerTestCase>[

    // Edge case: empty body.
    new ForgetElementTestCase(
        'main() {}'),

    // Edge case: simple arrow function.
    new ForgetElementTestCase(
        'main() => null;'),

    // Test that a local closure is discarded correctly.
    new ForgetElementTestCase(
        'main() => (() => null)();',
        closureCount: 1),

    // Test that nested closures are discarded correctly.
    new ForgetElementTestCase(
        'main() => (() => (() => null)())();',
        closureCount: 2),

    // Test that nested closures are discarded correctly.
    new ForgetElementTestCase(
        'main() => (() => (() => (() => null)())())();',
        closureCount: 3),

    // Test that metadata on top-level function is discarded correctly.
    new ForgetElementTestCase(
        '@Constant() main() => null; $CONSTANT_CLASS',
        metadataCount: 1),

    // Test that metadata on top-level variable is discarded correctly.
    new ForgetElementTestCase(
        '@Constant() var x; main() => x; $CONSTANT_CLASS',
        metadataCount: 1,
        initialValueCount: 1,
        initialDartValueCount: 0),

    // Test that metadata on parameter on a local function is discarded
    // correctly.
    new ForgetElementTestCase(
        'main() => ((@Constant() x) => x)(null); $CONSTANT_CLASS',
        closureCount: 1,
        metadataCount: 1),

    // Test that a constant in a top-level method body is discarded
    // correctly.
    new ForgetElementTestCase(
        'main() => const Constant(); $CONSTANT_CLASS',
        constantCount: 1),

    // Test that a constant in a nested function body is discarded
    // correctly.
    new ForgetElementTestCase(
        'main() => (() => const Constant())(); $CONSTANT_CLASS',
        constantCount: 1,
        closureCount: 1),

    // Test that a constant in a nested function body is discarded
    // correctly.
    new ForgetElementTestCase(
        'main() => (() => (() => const Constant())())(); $CONSTANT_CLASS',
        constantCount: 1,
        closureCount: 2),

    // Test that a constant in a top-level variable initializer is
    // discarded correctly.
    new ForgetElementTestCase(
        'main() => x; var x = const Constant(); $CONSTANT_CLASS',
        constantCount: 1,
        initialValueCount: 1,
        initialDartValueCount: 0,
        additionalClosureClassMaps: 1),

    // Test that a constant in a parameter initializer is discarded
    // correctly.
    new ForgetElementTestCase(
        'main([x = const Constant()]) => x; $CONSTANT_CLASS',
        constantCount: 1,
        initialValueCount: 1),

    // Test that a constant in a parameter initializer is discarded
    // correctly (nested function).
    new ForgetElementTestCase(
        'main() => (([x = const Constant()]) => x)(); $CONSTANT_CLASS',
        closureCount: 1,
        constantCount: 1,
        initialValueCount: 1),

    // Test that a constant in a parameter initializer is discarded
    // correctly (deeply nested function).
    new ForgetElementTestCase(
        'main() => (() => (([x = const Constant()]) => x)())();'
        ' $CONSTANT_CLASS',
        closureCount: 2,
        constantCount: 1,
        initialValueCount: 1),

    // TODO(ahe): Add test for super sends [backend.aliasedSuperMembers].
]..addAll(assertUnimplementedLocalMetadata());
