// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution.deferred_load;

import '../common.dart';
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart' show ConstantExpression;
import '../constants/values.dart'
    show ConstantValue, ConstructedConstantValue, StringConstantValue;
import '../deferred_load.dart';
import '../elements/elements.dart'
    show
        AstElement,
        AccessorElement,
        ClassElement,
        Element,
        ExportElement,
        ImportElement,
        LibraryElement,
        MemberElement,
        MetadataAnnotation,
        PrefixElement,
        ResolvedAstKind,
        TypedefElement;
import '../elements/resolution_types.dart';
import '../resolution/resolution.dart' show AnalyzableElementX;
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart' as ast;
import '../util/util.dart' show Setlet;
import 'tree_elements.dart' show TreeElements;

class AstDeferredLoadTask extends DeferredLoadTask {
  /// DeferredLibrary from dart:async
  ClassElement get deferredLibraryClass =>
      compiler.resolution.commonElements.deferredLibraryClass;

  AstDeferredLoadTask(Compiler compiler) : super(compiler);

  Iterable<ImportElement> importsTo(
      Element element, covariant LibraryElement library) {
    if (element.isClassMember) {
      element = element.enclosingClass;
    }
    if (element.isAccessor) {
      element = (element as AccessorElement).abstractField;
    }
    return library.getImportsFor(element);
  }

  void checkForDeferredErrorCases(LibraryElement library) {
    var usedPrefixes = new Setlet<String>();
    // The last deferred import we saw with a given prefix (if any).
    var prefixDeferredImport = new Map<String, ImportElement>();
    for (ImportElement import in library.imports) {
      _detectOldSyntax(import);
      _detectDuplicateErrorCases(import, usedPrefixes, prefixDeferredImport);
    }
  }

  /// Give an error if the old annotation-based syntax has been used.
  void _detectOldSyntax(ImportElement import) {
    List<MetadataAnnotation> metadataList = import.metadata;
    if (metadataList != null) {
      for (MetadataAnnotation metadata in metadataList) {
        metadata.ensureResolved(compiler.resolution);
        ConstantValue value =
            compiler.constants.getConstantValue(metadata.constant);
        ResolutionDartType type =
            value.getType(compiler.resolution.commonElements);
        Element element = type.element;
        if (element == deferredLibraryClass) {
          reporter.reportErrorMessage(import, MessageKind.DEFERRED_OLD_SYNTAX);
        }
      }
    }
  }

  /// Detect duplicate prefixes of deferred libraries.
  ///
  /// There are 4 cases of duplicate prefixes:
  ///   1.
  ///       import "lib.dart" deferred as a;
  ///       import "lib2.dart" deferred as a;
  ///
  ///   2.
  ///       import "lib.dart" deferred as a;
  ///       import "lib2.dart" as a;
  ///
  ///   3.
  ///       import "lib.dart" as a;
  ///       import "lib2.dart" deferred as a;
  ///
  ///   4.
  ///       import "lib.dart" as a;
  ///       import "lib2.dart" as a;
  ///
  /// We must be able to signal error for case 1, 2, 3, but accept case 4.
  void _detectDuplicateErrorCases(
      ImportElement import,
      Set<String> usedPrefixes,
      Map<String, ImportElement> prefixDeferredImport) {
    String prefix = import.prefix?.name;
    // The last import we saw with the same prefix.
    ImportElement previousDeferredImport = prefixDeferredImport[prefix];
    if (import.isDeferred) {
      if (prefix == null) {
        reporter.reportErrorMessage(
            import, MessageKind.DEFERRED_LIBRARY_WITHOUT_PREFIX);
      } else {
        prefixDeferredImport[prefix] = import;
      }
    }
    if (prefix != null) {
      if (previousDeferredImport != null ||
          (import.isDeferred && usedPrefixes.contains(prefix))) {
        ImportElement failingImport =
            (previousDeferredImport != null) ? previousDeferredImport : import;
        reporter.reportErrorMessage(failingImport.prefix,
            MessageKind.DEFERRED_LIBRARY_DUPLICATE_PREFIX);
      }
      usedPrefixes.add(prefix);
    }
  }

  void collectConstantsInBody(
      covariant AstElement element, Set<ConstantValue> constants) {
    if (element.resolvedAst.kind != ResolvedAstKind.PARSED) return;

    TreeElements treeElements = element.resolvedAst.elements;
    assert(treeElements != null);

    // TODO(johnniwinther): Add only expressions that are actually needed.
    // Currently we have some noise here: Some potential expressions are
    // seen that should never be added (for instance field initializers
    // in constant constructors, like `this.field = parameter`). And some
    // implicit constant expression are seen that we should be able to add
    // (like primitive constant literals like `true`, `"foo"` and `0`).
    // See dartbug.com/26406 for context.
    treeElements
        .forEachConstantNode((ast.Node node, ConstantExpression expression) {
      if (compiler.serialization.isDeserialized(element)) {
        if (!expression.isPotential) {
          // Enforce evaluation of [expression].
          backend.constants.getConstantValue(expression);
        }
      }

      // Explicitly depend on the backend constants.
      if (backend.constants.hasConstantValue(expression)) {
        ConstantValue value = backend.constants.getConstantValue(expression);
        assert(
            value != null,
            failedAt(
                node,
                "Constant expression without value: "
                "${expression.toStructuredText()}."));
        constants.add(value);
      } else {
        assert(
            expression.isImplicit || expression.isPotential,
            failedAt(
                node,
                "Unexpected unevaluated constant expression: "
                "${expression.toStructuredText()}."));
      }
    });
  }

  void addDeferredMirrorElements(WorkQueue queue) {
    for (ImportElement deferredImport in allDeferredImports) {
      addMirrorElementsForLibrary(queue, deferredImport.importedLibrary,
          importSets.singleton(deferredImport));
    }
  }

  void addMirrorElementsForLibrary(
      WorkQueue queue, covariant LibraryElement root, ImportSet newSet) {
    void handleElementIfResolved(Element element) {
      // If an element is the target of a MirrorsUsed annotation but never used
      // It will not be resolved, and we should not call isNeededForReflection.
      // TODO(sigurdm): Unresolved elements should just answer false when
      // asked isNeededForReflection. Instead an internal error is triggered.
      // So we have to filter them out here.
      if (element is AnalyzableElementX && !element.hasTreeElements) return;

      bool isAccessibleByReflection(Element element) {
        if (element.isLibrary) {
          return false;
        } else if (element.isClass) {
          ClassElement cls = element;
          return compiler.backend.mirrorsData
              .isClassAccessibleByReflection(cls);
        } else if (element.isTypedef) {
          TypedefElement typedef = element;
          return compiler.backend.mirrorsData
              .isTypedefAccessibleByReflection(typedef);
        } else {
          MemberElement member = element;
          return compiler.backend.mirrorsData
              .isMemberAccessibleByReflection(member);
        }
      }

      if (isAccessibleByReflection(element)) {
        queue.addElement(element, newSet, isMirrorUsage: true);
      }
    }

    // For each deferred import we analyze all elements reachable from the
    // imported library through non-deferred imports.
    void handleLibrary(LibraryElement library) {
      library.implementation.forEachLocalMember((Element element) {
        handleElementIfResolved(element);
      });

      void processMetadata(Element element) {
        for (MetadataAnnotation metadata in element.metadata) {
          ConstantValue constant =
              backend.constants.getConstantValueForMetadata(metadata);
          if (constant != null) {
            queue.addConstant(constant, newSet);
          }
        }
      }

      processMetadata(library);
      library.imports.forEach(processMetadata);
      library.exports.forEach(processMetadata);
    }

    _nonDeferredReachableLibraries(root).forEach(handleLibrary);
  }

  /// Returns the transitive closure of all libraries that are imported
  /// from root without DeferredLibrary annotations.
  Set<LibraryElement> _nonDeferredReachableLibraries(LibraryElement root) {
    Set<LibraryElement> result = new Set<LibraryElement>();

    void traverseLibrary(LibraryElement library) {
      if (result.contains(library)) return;
      result.add(library);

      iterateDependencies(LibraryElement library) {
        for (ImportElement import in library.imports) {
          if (!import.isDeferred) {
            LibraryElement importedLibrary = import.importedLibrary;
            traverseLibrary(importedLibrary);
          }
        }
        for (ExportElement export in library.exports) {
          LibraryElement exportedLibrary = export.exportedLibrary;
          traverseLibrary(exportedLibrary);
        }
      }

      iterateDependencies(library);
      if (library.isPatched) {
        iterateDependencies(library.implementation);
      }
    }

    traverseLibrary(root);
    result.add(compiler.resolution.commonElements.coreLibrary);
    return result;
  }

  /// If [send] is a static send with a deferred element, returns the
  /// [PrefixElement] that the first prefix of the send resolves to.
  /// Otherwise returns null.
  ///
  /// Precondition: send must be static.
  ///
  /// Example:
  ///
  /// import "a.dart" deferred as a;
  ///
  /// main() {
  ///   print(a.loadLibrary.toString());
  ///   a.loadLibrary().then((_) {
  ///     a.run();
  ///     a.foo.method();
  ///   });
  /// }
  ///
  /// Returns null for a.loadLibrary() (the special
  /// function loadLibrary is not deferred). And returns the PrefixElement for
  /// a.run() and a.foo.
  /// a.loadLibrary.toString() and a.foo.method() are dynamic sends - and
  /// this functions should not be called on them.
  PrefixElement deferredPrefixElement(ast.Send send, TreeElements elements) {
    Element element = elements[send];
    // The DeferredLoaderGetter is not deferred, therefore we do not return the
    // prefix.
    if (element != null && element.isDeferredLoaderGetter) return null;

    ast.Node firstNode(ast.Node node) {
      if (node is! ast.Send) {
        return node;
      } else {
        ast.Send send = node;
        ast.Node receiver = send.receiver;
        ast.Node receiverFirst = firstNode(receiver);
        if (receiverFirst != null) {
          return receiverFirst;
        } else {
          return firstNode(send.selector);
        }
      }
    }

    ast.Node first = firstNode(send);
    ast.Node identifier = first.asIdentifier();
    if (identifier == null) return null;
    Element maybePrefix = elements[identifier];
    if (maybePrefix != null && maybePrefix.isPrefix) {
      PrefixElement prefixElement = maybePrefix;
      if (prefixElement.isDeferred) {
        return prefixElement;
      }
    }
    return null;
  }

  /// Returns a name for a deferred import.
  // TODO(sigmund): delete support for the old annotation-style syntax.
  String computeImportDeferName(ImportElement declaration, Compiler compiler) {
    String result;
    if (declaration.isDeferred) {
      if (declaration.prefix != null) {
        result = declaration.prefix.name;
      } else {
        // This happens when the deferred import isn't declared with a prefix.
        assert(compiler.compilationFailed);
        result = '';
      }
    } else {
      // Finds the first argument to the [DeferredLibrary] annotation
      List<MetadataAnnotation> metadatas = declaration.metadata;
      assert(metadatas != null);
      for (MetadataAnnotation metadata in metadatas) {
        metadata.ensureResolved(compiler.resolution);
        ConstantValue value =
            compiler.constants.getConstantValue(metadata.constant);
        ResolutionDartType type =
            value.getType(compiler.resolution.commonElements);
        Element element = type.element;
        if (element ==
            compiler.resolution.commonElements.deferredLibraryClass) {
          ConstructedConstantValue constant = value;
          StringConstantValue s = constant.fields.values.single;
          result = s.primitiveValue;
          break;
        }
      }
    }
    assert(result != null);
    return result;
  }
}
