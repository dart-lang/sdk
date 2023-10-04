// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../util/element_printer.dart';
import '../../util/tree_string_sink.dart';
import 'resolved_ast_printer.dart';

String getLibraryText({
  required LibraryElementImpl library,
  required ElementTextConfiguration configuration,
}) {
  final buffer = StringBuffer();
  final sink = TreeStringSink(
    sink: buffer,
    indent: '',
  );
  final elementPrinter = ElementPrinter(
    sink: sink,
    configuration: ElementPrinterConfiguration(),
    selfUriStr: '${library.source.uri}',
  );
  final writer = _ElementWriter(
    sink: sink,
    elementPrinter: elementPrinter,
    configuration: configuration,
  );
  writer.writeLibraryElement(library);
  return buffer.toString();
}

class ElementTextConfiguration {
  bool Function(Object) filter;
  bool withAugmentedWithoutAugmentation = false;
  bool withCodeRanges = false;
  bool withConstantInitializers = true;
  bool withConstructors = true;
  bool withDisplayName = false;
  bool withExportScope = false;
  bool withFunctionTypeParameters = false;
  bool withImports = true;
  bool withLibraryAugmentations = false;
  bool withMetadata = true;
  bool withNonSynthetic = false;
  bool withPropertyLinking = false;
  bool withRedirectedConstructors = false;
  bool withReferences = false;
  bool withSyntheticDartCoreImport = false;

  ElementTextConfiguration({
    this.filter = _filterTrue,
  });

  static bool _filterTrue(Object element) => true;
}

/// Writes the canonical text presentation of elements.
class _ElementWriter {
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;
  final ElementTextConfiguration configuration;
  final _IdMap _idMap = _IdMap();

  _ElementWriter({
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
    required this.configuration,
  })  : _sink = sink,
        _elementPrinter = elementPrinter;

  void writeLibraryElement(LibraryElement e) {
    e as LibraryElementImpl;

    _sink.writelnWithIndent('library');
    _sink.withIndent(() {
      var name = e.name;
      if (name.isNotEmpty) {
        _sink.writelnWithIndent('name: $name');
      }

      var nameOffset = e.nameOffset;
      if (nameOffset != -1) {
        _sink.writelnWithIndent('nameOffset: $nameOffset');
      }

      _writeLibraryOrAugmentationElement(e);

      _writeElements('parts', e.parts, _writePartElement);

      if (configuration.withExportScope) {
        _sink.writelnWithIndent('exportedReferences');
        _sink.withIndent(() {
          _writeExportedReferences(e);
        });
        _sink.writelnWithIndent('exportNamespace');
        _sink.withIndent(() {
          _writeExportNamespace(e);
        });
      }
    });
  }

  void _assertNonSyntheticElementSelf(Element element) {
    expect(element.isSynthetic, isFalse);
    expect(element.nonSynthetic, same(element));
  }

  ResolvedAstPrinter _createAstPrinter() {
    return ResolvedAstPrinter(
      sink: _sink,
      elementPrinter: _elementPrinter,
      configuration: ResolvedNodeTextConfiguration()
        // TODO(scheglov) https://github.com/dart-lang/sdk/issues/49101
        ..withParameterElements = false,
      withOffsets: true,
    );
  }

  void _validateAugmentedInstanceElement(InstanceElementImpl e) {
    final augmented = e.augmented;

    // Find the end of the augmentations chain.
    // It will be a declaration in valid code.
    InstanceElementImpl? endOfAugmentations = e;
    while (endOfAugmentations != null && endOfAugmentations.isAugmentation) {
      endOfAugmentations = endOfAugmentations.augmentationTarget;
    }

    // If does not end with a declaration.
    if (endOfAugmentations == null) {
      expect(augmented, isNull);
      return;
    }

    // ...otherwise we must have the augmented data.
    expect(augmented, isNotNull);
    expect(augmented, same(endOfAugmentations.augmented));
  }

  void _writeAugmentation(ElementImpl e) {
    if (e case AugmentableElement(:final augmentation?)) {
      _elementPrinter.writeNamedElement('augmentation', augmentation);
    }
  }

  void _writeAugmentationElement(LibraryAugmentationElementImpl e) {
    _writeLibraryOrAugmentationElement(e);
  }

  void _writeAugmentationImportElement(AugmentationImportElement e) {
    final uri = e.uri;
    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _sink.withIndent(() {
      _writeMetadata(e);
      if (uri is DirectiveUriWithAugmentationImpl) {
        _writeAugmentationElement(uri.augmentation);
      }
    });
  }

  void _writeAugmentationTarget(ElementImpl e) {
    if (e is AugmentableElement && e.isAugmentation) {
      _elementPrinter.writeNamedElement(
        'augmentationTarget',
        e.augmentationTarget,
      );
    }
  }

  void _writeAugmented(InstanceElementImpl e) {
    // TODO(scheglov) enable for other types
    if (!(e is ClassElementImpl || e is MixinElementImpl)) {
      return;
    }

    if (e.isAugmentation) {
      return;
    }

    // No augmentation, not interesting.
    if (e.augmentation == null) {
      expect(e.augmented, TypeMatcher<NotAugmentedInstanceElementImpl>());
      if (!configuration.withAugmentedWithoutAugmentation) {
        return;
      }
    }

    final augmented = e.augmented;
    if (augmented == null) {
      return;
    }

    void writeFields() {
      final sorted = augmented.fields.sortedBy((e) => e.name);
      _elementPrinter.writeElementList('fields', sorted);
    }

    void writeConstructors() {
      if (augmented is AugmentedInterfaceElementImpl) {
        final sorted = augmented.constructors.sortedBy((e) => e.name);
        expect(sorted, isNotEmpty);
        _elementPrinter.writeElementList('constructors', sorted);
      }
    }

    void writeAccessors() {
      final sorted = augmented.accessors.sortedBy((e) => e.name);
      _elementPrinter.writeElementList('accessors', sorted);
    }

    void writeMethods() {
      final sorted = augmented.methods.sortedBy((e) => e.name);
      _elementPrinter.writeElementList('methods', sorted);
    }

    _sink.writelnWithIndent('augmented');
    _sink.withIndent(() {
      switch (augmented) {
        case AugmentedClassElement():
          _elementPrinter.writeTypeList('mixins', augmented.mixins);
          _elementPrinter.writeTypeList('interfaces', augmented.interfaces);
          writeFields();
          writeConstructors();
          writeAccessors();
          writeMethods();
        case AugmentedMixinElement():
          _elementPrinter.writeTypeList(
            'superclassConstraints',
            augmented.superclassConstraints,
          );
          _elementPrinter.writeTypeList('interfaces', augmented.interfaces);
          writeFields();
          writeAccessors();
          writeMethods();
      }
      // TODO(scheglov) Add other types and properties
    });
  }

  void _writeBodyModifiers(ExecutableElement e) {
    if (e.isAsynchronous) {
      expect(e.isSynchronous, isFalse);
      _sink.write(' async');
    }

    if (e.isSynchronous && e.isGenerator) {
      expect(e.isAsynchronous, isFalse);
      _sink.write(' sync');
    }

    _sink.writeIf(e.isGenerator, '*');

    if (e is ExecutableElementImpl && e.invokesSuperSelf) {
      _sink.write(' invokesSuperSelf');
    }
  }

  void _writeCodeRange(Element e) {
    if (configuration.withCodeRanges && !e.isSynthetic) {
      e as ElementImpl;
      _sink.writelnWithIndent('codeOffset: ${e.codeOffset}');
      _sink.writelnWithIndent('codeLength: ${e.codeLength}');
    }
  }

  void _writeConstantInitializer(Element e) {
    if (configuration.withConstantInitializers) {
      if (e is ConstVariableElement) {
        var initializer = e.constantInitializer;
        if (initializer != null) {
          _sink.writelnWithIndent('constantInitializer');
          _sink.withIndent(() {
            _writeNode(initializer);
          });
        }
      }
    }
  }

  void _writeConstructorElement(ConstructorElement e) {
    e as ConstructorElementImpl;

    // Check that the reference exists, and filled with the element.
    var reference = e.reference;
    if (reference == null) {
      fail('Every constructor must have a reference.');
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isFactory, 'factory ');
      expect(e.isAbstract, isFalse);
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeDisplayName(e);

      var periodOffset = e.periodOffset;
      var nameEnd = e.nameEnd;
      if (periodOffset != null && nameEnd != null) {
        _sink.writelnWithIndent('periodOffset: $periodOffset');
        _sink.writelnWithIndent('nameEnd: $nameEnd');
      }

      _writeParameterElements(e.parameters);

      _writeElements(
        'constantInitializers',
        e.constantInitializers,
        _writeNode,
      );

      var superConstructor = e.superConstructor;
      if (superConstructor != null) {
        final enclosingElement = superConstructor.enclosingElement;
        if (enclosingElement is ClassElement &&
            !enclosingElement.isDartCoreObject) {
          _elementPrinter.writeNamedElement(
            'superConstructor',
            superConstructor,
          );
        }
      }

      var redirectedConstructor = e.redirectedConstructor;
      if (redirectedConstructor != null) {
        _elementPrinter.writeNamedElement(
          'redirectedConstructor',
          redirectedConstructor,
        );
      }

      _writeNonSyntheticElement(e);
    });

    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
      expect(e.nonSynthetic, same(e.enclosingElement));
    } else {
      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
    }
  }

  void _writeDirectiveUri(DirectiveUri uri) {
    if (uri is DirectiveUriWithAugmentationImpl) {
      _sink.write('${uri.augmentation.source.uri}');
    } else if (uri is DirectiveUriWithLibraryImpl) {
      _sink.write('${uri.library.source.uri}');
    } else if (uri is DirectiveUriWithUnit) {
      _sink.write('${uri.unit.source.uri}');
    } else if (uri is DirectiveUriWithSource) {
      _sink.write("source '${uri.source.uri}'");
    } else if (uri is DirectiveUriWithRelativeUri) {
      _sink.write("relativeUri '${uri.relativeUri}'");
    } else if (uri is DirectiveUriWithRelativeUriString) {
      _sink.write("relativeUriString '${uri.relativeUriString}'");
    } else {
      _sink.write('noRelativeUriString');
    }
  }

  void _writeDisplayName(Element e) {
    if (configuration.withDisplayName) {
      _sink.writelnWithIndent('displayName: ${e.displayName}');
    }
  }

  void _writeDocumentation(Element element) {
    var documentation = element.documentationComment;
    if (documentation != null) {
      var str = documentation;
      str = str.replaceAll('\n', r'\n');
      str = str.replaceAll('\r', r'\r');
      _sink.writelnWithIndent('documentationComment: $str');
    }
  }

  void _writeElements<T extends Object>(
    String name,
    List<T> elements,
    void Function(T) f,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var element in filtered) {
          f(element);
        }
      });
    }
  }

  void _writeExportedReferences(LibraryElementImpl e) {
    final exportedReferences = e.exportedReferences.toList();
    exportedReferences.sortBy((e) => e.reference.toString());

    for (final exported in exportedReferences) {
      _sink.writeIndentedLine(() {
        if (exported is ExportedReferenceDeclared) {
          _sink.write('declared ');
        } else if (exported is ExportedReferenceExported) {
          _sink.write('exported${exported.locations} ');
        }
        _elementPrinter.writeReference(exported.reference);
      });
    }
  }

  void _writeExportElement(LibraryExportElement e) {
    e.location;

    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _sink.withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeExportNamespace(LibraryElement e) {
    final map = e.exportNamespace.definedNames;
    final sortedEntries = map.entries.sortedBy((entry) => entry.key);
    for (final entry in sortedEntries) {
      _elementPrinter.writeNamedElement(entry.key, entry.value);
    }
  }

  void _writeExtensionElement(ExtensionElementImpl e) {
    _sink.writeIndentedLine(() {
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeType('extendedType', e.extendedType);
    });

    _sink.withIndent(() {
      _writeElements('fields', e.fields, _writePropertyInducingElement);
      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeMethods(e.methods);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeFieldFormalParameterField(ParameterElement e) {
    if (e is FieldFormalParameterElement) {
      var field = e.field;
      if (field != null) {
        _elementPrinter.writeNamedElement('field', field);
      } else {
        _sink.writelnWithIndent('field: <null>');
      }
    }
  }

  void _writeFunctionElement(FunctionElementImpl e) {
    expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isExternal, 'external ');
      _writeName(e);
      _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeImportElement(LibraryImportElement e) {
    e.location;

    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
      _sink.writeIf(e.isSynthetic, ' synthetic');
      _writeImportElementPrefix(e.prefix);
    });

    _sink.withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });
  }

  void _writeImportElementPrefix(ImportElementPrefix? prefix) {
    if (prefix != null) {
      _sink.writeIf(prefix is DeferredImportElementPrefix, ' deferred');
      _sink.write(' as ');
      _writeName(prefix.element);
    }
  }

  void _writeInterfaceElement(InterfaceElementImpl e) {
    _sink.writeIndentedLine(() {
      if (e.isAugmentation) {
        _sink.write('augment ');
      }

      switch (e) {
        case ClassElementImpl():
          _sink.writeIf(e.isAbstract, 'abstract ');
          _sink.writeIf(e.isMacro, 'macro ');
          _sink.writeIf(e.isSealed, 'sealed ');
          _sink.writeIf(e.isBase, 'base ');
          _sink.writeIf(e.isInterface, 'interface ');
          _sink.writeIf(e.isFinal, 'final ');
          _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
          _sink.writeIf(e.isMixinClass, 'mixin ');
          _sink.write('class ');
          _sink.writeIf(e.isMixinApplication, 'alias ');
        case EnumElementImpl():
          _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
          _sink.write('enum ');
        case ExtensionTypeElementImpl():
          _sink.writeIf(
            e.hasRepresentationSelfReference,
            'hasRepresentationSelfReference ',
          );
          _sink.writeIf(
            e.hasImplementsSelfReference,
            'hasImplementsSelfReference ',
          );
          _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
        case MixinElementImpl():
          _sink.writeIf(e.isBase, 'base ');
          _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
          _sink.write('mixin ');
      }

      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);

      if (!e.isAugmentation) {
        final supertype = e.supertype;
        if (supertype != null &&
            (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
          _writeType('supertype', supertype);
        }
      }

      if (e is ExtensionTypeElementImpl) {
        _elementPrinter.writeNamedElement('representation', e.representation);
        _elementPrinter.writeNamedElement(
            'primaryConstructor', e.primaryConstructor);
        _elementPrinter.writeNamedType('typeErasure', e.typeErasure);
      }

      if (e is MixinElementImpl) {
        final superclassConstraints = e.superclassConstraints;
        if (!e.isAugmentation) {
          if (superclassConstraints.isEmpty) {
            throw StateError('At least Object is expected.');
          }
        }
        _elementPrinter.writeTypeList(
          'superclassConstraints',
          superclassConstraints,
        );
      }

      _elementPrinter.writeTypeList('mixins', e.mixins);
      _elementPrinter.writeTypeList('interfaces', e.interfaces);

      _writeElements('fields', e.fields, _writePropertyInducingElement);

      var constructors = e.constructors;
      if (e is MixinElement) {
        expect(constructors, isEmpty);
      } else if (configuration.withConstructors) {
        _writeElements('constructors', constructors, _writeConstructorElement);
      }

      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeMethods(e.methods);

      _validateAugmentedInstanceElement(e);
      _writeAugmented(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeLibraryAugmentations(LibraryElementImpl e) {
    if (configuration.withLibraryAugmentations) {
      final augmentations = e.augmentations;
      if (augmentations.isNotEmpty) {
        _sink.writelnWithIndent('augmentations');
        _sink.withIndent(() {
          for (final element in augmentations) {
            _sink.writeIndent();
            _elementPrinter.writeElement(element);
          }
        });
      }
    }
  }

  void _writeLibraryOrAugmentationElement(LibraryOrAugmentationElementImpl e) {
    if (e is LibraryAugmentationElementImpl) {
      if (e.macroGenerated case final macroGenerated?) {
        _sink.writelnWithIndent('macroGeneratedCode');
        _sink.writeln('---');
        _sink.write(macroGenerated.code);
        _sink.writeln('---');
      }
    }

    _writeDocumentation(e);
    _writeMetadata(e);
    _writeSinceSdkVersion(e);

    if (configuration.withImports) {
      var imports = e.libraryImports.where((import) {
        return configuration.withSyntheticDartCoreImport || !import.isSynthetic;
      }).toList();
      _writeElements('imports', imports, _writeImportElement);
    }

    _writeElements('exports', e.libraryExports, _writeExportElement);

    _sink.writelnWithIndent('definingUnit');
    _sink.withIndent(() {
      _writeUnitElement(e.definingCompilationUnit);
    });

    if (e is LibraryElementImpl) {
      _writeLibraryAugmentations(e);
    }

    _writeElements('augmentationImports', e.augmentationImports,
        _writeAugmentationImportElement);
  }

  void _writeMetadata(Element element) {
    if (configuration.withMetadata) {
      var annotations = element.metadata;
      if (annotations.isNotEmpty) {
        _sink.writelnWithIndent('metadata');
        _sink.withIndent(() {
          for (var annotation in annotations) {
            annotation as ElementAnnotationImpl;
            _writeNode(annotation.annotationAst);
          }
        });
      }
    }
  }

  void _writeMethodElement(MethodElementImpl e) {
    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');

      _writeName(e);
      _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);

      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType);
      _writeNonSyntheticElement(e);

      if (e.isAugmentation) {
        _elementPrinter.writeNamedElement(
          'augmentationTarget',
          e.augmentationTarget,
        );
      }

      final augmentation = e.augmentation;
      if (augmentation != null) {
        _elementPrinter.writeNamedElement('augmentation', augmentation);
      }
    });

    if (e.isSynthetic && e.enclosingElement is EnumElementImpl) {
      expect(e.name, 'toString');
      expect(e.nonSynthetic, same(e.enclosingElement));
    } else {
      _assertNonSyntheticElementSelf(e);
    }
  }

  void _writeMethods(List<MethodElementImpl> elements) {
    _writeElements('methods', elements, _writeMethodElement);
  }

  void _writeName(Element e) {
    final String name;
    switch (e) {
      case ExtensionElement(name: null):
        name = '<null>';
      default:
        name = e.name!;
    }

    if (e is PropertyAccessorElement && e.isSetter) {
      expect(name, endsWith('='));
    }

    _sink.write(name);
    _sink.write(name.isNotEmpty ? ' @' : '@');
    _sink.write(e.nameOffset);
  }

  void _writeNamespaceCombinator(NamespaceCombinator e) {
    _sink.writeIndentedLine(() {
      if (e is ShowElementCombinator) {
        _sink.write('show: ');
        _sink.write(e.shownNames.join(', '));
      } else if (e is HideElementCombinator) {
        _sink.write('hide: ');
        _sink.write(e.hiddenNames.join(', '));
      }
    });
  }

  void _writeNamespaceCombinators(List<NamespaceCombinator> elements) {
    _writeElements('combinators', elements, _writeNamespaceCombinator);
  }

  void _writeNode(AstNode node) {
    _sink.writeIndent();
    node.accept(
      _createAstPrinter(),
    );
  }

  void _writeNonSyntheticElement(Element e) {
    if (configuration.withNonSynthetic) {
      _elementPrinter.writeNamedElement('nonSynthetic', e.nonSynthetic);
    }
  }

  void _writeParameterElement(ParameterElement e) {
    e as ParameterElementImpl;

    _sink.writeIndentedLine(() {
      if (e.isRequiredPositional) {
        _sink.write('requiredPositional ');
      } else if (e.isOptionalPositional) {
        _sink.write('optionalPositional ');
      } else if (e.isRequiredNamed) {
        _sink.write('requiredNamed ');
      } else if (e.isOptionalNamed) {
        _sink.write('optionalNamed ');
      }

      if (e is ConstVariableElement) {
        _sink.write('default ');
      }

      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isCovariant, 'covariant ');
      _sink.writeIf(e.isFinal, 'final ');

      if (e is FieldFormalParameterElement) {
        _sink.write('this.');
      } else if (e is SuperFormalParameterElement) {
        _sink.write('super.');
      }

      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeType('type', e.type);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
      _writeFieldFormalParameterField(e);
      _writeSuperConstructorParameter(e);
    });
  }

  void _writeParameterElements(List<ParameterElement> elements) {
    _writeElements('parameters', elements, _writeParameterElement);
  }

  void _writePartElement(PartElement e) {
    final uri = e.uri;
    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _sink.withIndent(() {
      _writeMetadata(e);
      if (uri is DirectiveUriWithUnitImpl) {
        _writeUnitElement(uri.unit);
      }
    });
  }

  void _writePropertyAccessorElement(PropertyAccessorElement e) {
    e as PropertyAccessorElementImpl;

    PropertyInducingElement variable = e.variable;
    expect(variable, isNotNull);

    var variableEnclosing = variable.enclosingElement;
    if (variableEnclosing is CompilationUnitElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is InterfaceElement) {
      expect(variableEnclosing.fields, contains(variable));
    }

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
      _assertNonSyntheticElementSelf(e);
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');

      if (e.isGetter) {
        _sink.write('get ');
      } else {
        _sink.write('set ');
      }

      _writeName(e);
      _writeBodyModifiers(e);
    });

    void writeLinking() {
      if (configuration.withPropertyLinking) {
        _sink.writelnWithIndent('id: ${_idMap[e]}');
        _sink.writelnWithIndent('variable: ${_idMap[e.variable]}');
      }
    }

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);

      expect(e.typeParameters, isEmpty);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType);
      _writeNonSyntheticElement(e);
      writeLinking();
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });
  }

  void _writePropertyInducingElement(PropertyInducingElement e) {
    e as PropertyInducingElementImpl;

    DartType type = e.type;
    expect(type, isNotNull);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      if (!e.isAugmentation) {
        expect(e.getter, isNotNull);
      }

      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
      _assertNonSyntheticElementSelf(e);
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e is FieldElementImpl && e.isAbstract, 'abstract ');
      _sink.writeIf(e is FieldElementImpl && e.isCovariant, 'covariant ');
      _sink.writeIf(e is FieldElementImpl && e.isExternal, 'external ');
      _sink.writeIf(e.isLate, 'late ');
      _sink.writeIf(e.isFinal, 'final ');
      _sink.writeIf(e.isConst, 'const ');
      if (e is FieldElementImpl) {
        _sink.writeIf(e.isEnumConstant, 'enumConstant ');
        _sink.writeIf(e.isPromotable, 'promotable ');
      }

      _writeName(e);
    });

    void writeLinking() {
      if (configuration.withPropertyLinking) {
        _sink.writelnWithIndent('id: ${_idMap[e]}');

        final getter = e.getter;
        if (getter != null) {
          _sink.writelnWithIndent('getter: ${_idMap[getter]}');
        }

        final setter = e.setter;
        if (setter != null) {
          _sink.writelnWithIndent('setter: ${_idMap[setter]}');
        }
      }
    }

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);
      _writeType('type', e.type);
      _writeShouldUseTypeForInitializerInference(e);
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
      writeLinking();
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });
  }

  void _writeReference(ElementImpl e) {
    if (!configuration.withReferences) {
      return;
    }

    if (e.reference case final reference?) {
      _sink.writeIndentedLine(() {
        _sink.write('reference: ');
        _elementPrinter.writeReference(reference);
      });
    }
  }

  void _writeShouldUseTypeForInitializerInference(
    PropertyInducingElementImpl e,
  ) {
    if (e.isSynthetic) return;
    if (!e.hasInitializer) return;

    _sink.writelnWithIndent(
      'shouldUseTypeForInitializerInference: '
      '${e.shouldUseTypeForInitializerInference}',
    );
  }

  void _writeSinceSdkVersion(Element e) {
    final sinceSdkVersion = e.sinceSdkVersion;
    if (sinceSdkVersion != null) {
      _sink.writelnWithIndent('sinceSdkVersion: $sinceSdkVersion');
    }
  }

  void _writeSuperConstructorParameter(ParameterElement e) {
    if (e is SuperFormalParameterElement) {
      var superParameter = e.superConstructorParameter;
      if (superParameter != null) {
        _elementPrinter.writeNamedElement(
          'superConstructorParameter',
          superParameter,
        );
      } else {
        _sink.writelnWithIndent('superConstructorParameter: <null>');
      }
    }
  }

  void _writeType(String name, DartType type) {
    _elementPrinter.writeNamedType(name, type);

    if (configuration.withFunctionTypeParameters) {
      if (type is FunctionType) {
        _sink.withIndent(() {
          _writeParameterElements(type.parameters);
        });
      }
    }
  }

  void _writeTypeAliasElement(TypeAliasElement e) {
    e as TypeAliasElementImpl;

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);

      var aliasedType = e.aliasedType;
      _writeType('aliasedType', aliasedType);

      var aliasedElement = e.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElementImpl) {
        _sink.writelnWithIndent('aliasedElement: GenericFunctionTypeElement');
        _sink.withIndent(() {
          _writeTypeParameterElements(aliasedElement.typeParameters);
          _writeParameterElements(aliasedElement.parameters);
          _writeType('returnType', aliasedElement.returnType);
        });
      }
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeInferenceError(Element e) {
    TopLevelInferenceError? inferenceError;
    if (e is MethodElementImpl) {
      inferenceError = e.typeInferenceError;
    } else if (e is PropertyInducingElementImpl) {
      inferenceError = e.typeInferenceError;
    }

    if (inferenceError != null) {
      String kindName = inferenceError.kind.toString();
      if (kindName.startsWith('TopLevelInferenceErrorKind.')) {
        kindName = kindName.substring('TopLevelInferenceErrorKind.'.length);
      }
      _sink.writelnWithIndent('typeInferenceError: $kindName');
      _sink.withIndent(() {
        if (kindName == 'dependencyCycle') {
          _sink.writelnWithIndent('arguments: ${inferenceError?.arguments}');
        }
      });
    }
  }

  void _writeTypeParameterElement(TypeParameterElement e) {
    e as TypeParameterElementImpl;

    _sink.writeIndentedLine(() {
      _sink.write('${e.variance} ');
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeCodeRange(e);

      var bound = e.bound;
      if (bound != null) {
        _writeType('bound', bound);
      }

      var defaultType = e.defaultType;
      if (defaultType != null) {
        _writeType('defaultType', defaultType);
      }

      _writeMetadata(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeParameterElements(List<TypeParameterElement> elements) {
    _writeElements('typeParameters', elements, _writeTypeParameterElement);
  }

  void _writeUnitElement(CompilationUnitElementImpl e) {
    _writeElements('classes', e.classes, _writeInterfaceElement);
    _writeElements('enums', e.enums, _writeInterfaceElement);
    _writeElements('extensions', e.extensions, _writeExtensionElement);
    _writeElements(
      'extensionTypes',
      e.extensionTypes,
      _writeInterfaceElement,
    );
    _writeElements('mixins', e.mixins, _writeInterfaceElement);
    _writeElements('typeAliases', e.typeAliases, _writeTypeAliasElement);
    _writeElements(
      'topLevelVariables',
      e.topLevelVariables,
      _writePropertyInducingElement,
    );
    _writeElements(
      'accessors',
      e.accessors,
      _writePropertyAccessorElement,
    );
    _writeElements('functions', e.functions, _writeFunctionElement);
  }
}

class _IdMap {
  final Map<Element, String> fieldMap = Map.identity();
  final Map<Element, String> getterMap = Map.identity();
  final Map<Element, String> setterMap = Map.identity();

  String operator [](Element element) {
    if (element is FieldElement) {
      return fieldMap[element] ??= 'field_${fieldMap.length}';
    } else if (element is TopLevelVariableElement) {
      return fieldMap[element] ??= 'variable_${fieldMap.length}';
    } else if (element is PropertyAccessorElement && element.isGetter) {
      return getterMap[element] ??= 'getter_${getterMap.length}';
    } else if (element is PropertyAccessorElement && element.isSetter) {
      return setterMap[element] ??= 'setter_${setterMap.length}';
    } else {
      return '???';
    }
  }
}
