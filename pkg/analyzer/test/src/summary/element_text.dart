// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../util/element_printer.dart';
import '../../util/tree_string_sink.dart';
import 'resolved_ast_printer.dart';

/// Set this path to automatically replace expectations in invocations of
/// [checkElementText] with the new actual texts.
const String? _testPath = null;

/// The list of replacements that update expectations.
final List<_Replacement> _replacements = [];

/// The cached content of the file with the [_testPath].
String? _testCode;

/// The cache line information for the [_testPath] file.
LineInfo? _testCodeLines;

void applyCheckElementTextReplacements() {
  if (_testPath != null && _replacements.isNotEmpty) {
    _replacements.sort((a, b) => b.offset - a.offset);
    String newCode = _testCode!;
    for (var replacement in _replacements) {
      newCode = newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }
    File(_testPath!).writeAsStringSync(newCode);
  }
}

/// Write the given [library] elements into the canonical text presentation
/// taking into account the [configuration]. Then compare the actual text with
/// the given [expected] one.
void checkElementTextWithConfiguration(
  LibraryElement library,
  String expected, {
  ElementTextConfiguration? configuration,
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
  var writer = _ElementWriter(
    sink: sink,
    elementPrinter: elementPrinter,
    configuration: configuration ?? ElementTextConfiguration(),
  );
  writer.writeLibraryElement(library);

  String actualText = buffer.toString();
  actualText =
      actualText.split('\n').map((line) => line.trimRight()).join('\n');

  if (_testPath != null && actualText != expected) {
    if (_testCode == null) {
      _testCode = File(_testPath!).readAsStringSync();
      _testCodeLines = LineInfo.fromContent(_testCode!);
    }

    try {
      throw 42;
    } catch (e, trace) {
      String traceString = trace.toString();

      // Assuming traceString contains "$_testPath:$invocationLine:$column",
      // figure out the value of invocationLine.

      int testFilePathOffset = traceString.lastIndexOf(_testPath!);
      expect(testFilePathOffset, isNonNegative);

      // Sanity check: there must be ':' after the path.
      expect(traceString[testFilePathOffset + _testPath!.length], ':');

      int lineOffset = testFilePathOffset + _testPath!.length + ':'.length;
      int invocationLine = int.parse(traceString.substring(
          lineOffset, traceString.indexOf(':', lineOffset)));
      int invocationOffset =
          _testCodeLines!.getOffsetOfLine(invocationLine - 1);

      const String rawStringPrefix = "r'''";
      int expectationOffset =
          _testCode!.indexOf(rawStringPrefix, invocationOffset);

      // Sanity check: there must be no other strings or blocks.
      expect(_testCode!.substring(invocationOffset, expectationOffset),
          isNot(anyOf(contains("'"), contains('"'), contains('}'))));

      expectationOffset += rawStringPrefix.length;
      int expectationEnd = _testCode!.indexOf("'''", expectationOffset);

      _replacements.add(
          _Replacement(expectationOffset, expectationEnd, '\n$actualText'));
    }
  }

  // Print the actual text to simplify copy/paste into the expectation.
  // if (actualText != expected) {
  //   print('-------- Actual --------');
  //   print('$actualText------------------------');
  // }

  expect(actualText, expected);
}

class ElementTextConfiguration {
  bool Function(Object) filter;
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

  /// Assert that the [accessor] of the [property] is correctly linked to
  /// the same enclosing element as the [property].
  void _assertSyntheticAccessorEnclosing(
      PropertyInducingElement property, PropertyAccessorElement accessor) {
    if (accessor.isSynthetic) {
      // Usually we have a non-synthetic property, and a synthetic accessor.
    } else {
      // But it is possible to have a non-synthetic setter.
      // class A {
      //   final int foo;
      //   set foo(int newValue) {}
      // }
      expect(accessor.isSetter, isTrue);
    }

    expect(accessor.variable, same(property));

    var propertyEnclosing = property.enclosingElement2;
    expect(accessor.enclosingElement2, same(propertyEnclosing));

    if (propertyEnclosing is CompilationUnitElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    } else if (propertyEnclosing is InterfaceElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    }
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

  /// TODO(scheglov) Replace with reference?
  String _getElementLocationString(Element? element) {
    if (element == null || element is MultiplyDefinedElement) {
      return 'null';
    }

    String onlyName(String uri) {
      if (uri.startsWith('file:///')) {
        return uri.substring(uri.lastIndexOf('/') + 1);
      }
      return uri;
    }

    var location = element.location!;
    List<String> components = location.components.toList();
    if (components.isNotEmpty) {
      components[0] = onlyName(components[0]);
    }
    if (components.length >= 2) {
      components[1] = onlyName(components[1]);
      if (components[0] == components[1]) {
        components.removeAt(0);
      }
    }
    return components.join(';');
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

  void _writeClassElement(InterfaceElement e) {
    _sink.writeIndentedLine(() {
      if (e is ClassElement) {
        _sink.writeIf(e.isAbstract, 'abstract ');
        _sink.writeIf(e.isMacro, 'macro ');
        _sink.writeIf(e.isSealed, 'sealed ');
        _sink.writeIf(e.isBase, 'base ');
        _sink.writeIf(e.isInterface, 'interface ');
        _sink.writeIf(e.isFinal, 'final ');
        _sink.writeIf(e.isInline, 'inline ');
        _sink.writeIf(e.isMixinClass, 'mixin ');
      }
      _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');

      if (e is EnumElement) {
        _sink.write('enum ');
      } else if (e is MixinElement) {
        _sink.writeIf(e.isBase, 'base ');
        _sink.write('mixin ');
      } else {
        _sink.write('class ');
      }
      if (e is ClassElement) {
        _sink.writeIf(e.isMixinApplication, 'alias ');
      }

      _writeName(e);
    });

    _sink.withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);

      final supertype = e.supertype;
      if (supertype != null &&
          (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
        _writeType('supertype', supertype);
      }

      if (e is MixinElement) {
        var superclassConstraints = e.superclassConstraints;
        if (superclassConstraints.isEmpty) {
          throw StateError('At least Object is expected.');
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
        expect(constructors, isNotEmpty);
        _writeElements('constructors', constructors, _writeConstructorElement);
      }

      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
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
    } else {
      var classReference = reference.parent!.parent!;
      // We need this `if` for duplicate declarations.
      // The reference might be filled by another declaration.
      if (identical(classReference.element, e.enclosingElement2)) {
        expect(reference.element, same(e));
      }
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isFactory, 'factory ');
      expect(e.isAbstract, isFalse);
      _writeName(e);
    });

    _sink.withIndent(() {
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
        final enclosingElement = superConstructor.enclosingElement2;
        if (enclosingElement is ClassElement &&
            !enclosingElement.isDartCoreObject) {
          _elementPrinter.writeElement('superConstructor', superConstructor);
        }
      }

      var redirectedConstructor = e.redirectedConstructor;
      if (redirectedConstructor != null) {
        _elementPrinter.writeElement(
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
      expect(e.nonSynthetic, same(e.enclosingElement2));
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
        // TODO(scheglov) Use the same writer as for resolved AST.
        _sink.write(exported.reference);
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
    var map = e.exportNamespace.definedNames;
    var names = map.keys.toList()..sort();
    for (var name in names) {
      var element = map[name];
      var elementLocationStr = _getElementLocationString(element);
      _sink.writelnWithIndent('$name: $elementLocationStr');
    }
  }

  void _writeExtensionElement(ExtensionElement e) {
    _sink.writeIndentedLine(() {
      _writeName(e);
    });

    _sink.withIndent(() {
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
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeFieldFormalParameterField(ParameterElement e) {
    if (e is FieldFormalParameterElement) {
      var field = e.field;
      if (field != null) {
        _elementPrinter.writeElement('field', field);
      } else {
        _sink.writelnWithIndent('field: <null>');
      }
    }
  }

  void _writeFunctionElement(FunctionElement e) {
    expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isExternal, 'external ');
      _writeName(e);
      _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType2);
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

  void _writeLibraryAugmentations(LibraryElementImpl e) {
    if (configuration.withLibraryAugmentations) {
      final augmentations = e.augmentations;
      if (augmentations.isNotEmpty) {
        _sink.writelnWithIndent('augmentations');
        _sink.withIndent(() {
          for (final element in augmentations) {
            _sink.writeIndent();
            _elementPrinter.writeElement0(element);
          }
        });
      }
    }
  }

  void _writeLibraryOrAugmentationElement(LibraryOrAugmentationElementImpl e) {
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

    _writeElements('augmentationImports', e.augmentationImports,
        _writeAugmentationImportElement);

    _sink.writelnWithIndent('definingUnit');
    _sink.withIndent(() {
      _writeUnitElement(e.definingCompilationUnit);
    });

    if (e is LibraryElementImpl) {
      _writeLibraryAugmentations(e);
    }
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

  void _writeMethodElement(MethodElement e) {
    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');

      _writeName(e);
      _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);

      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType2);
      _writeNonSyntheticElement(e);
    });

    if (e.isSynthetic && e.enclosingElement2 is EnumElementImpl) {
      expect(e.name, 'toString');
      expect(e.nonSynthetic, same(e.enclosingElement2));
    } else {
      _assertNonSyntheticElementSelf(e);
    }
  }

  void _writeName(Element e) {
    // TODO(scheglov) Use 'name' everywhere.
    var name = e is ConstructorElement ? e.name : e.displayName;
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
      _elementPrinter.writeElement('nonSynthetic', e.nonSynthetic);
    }
  }

  void _writeParameterElement(ParameterElement e) {
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
      if (uri is DirectiveUriWithUnit) {
        _writeUnitElement(uri.unit);
      }
    });
  }

  void _writePropertyAccessorElement(PropertyAccessorElement e) {
    e as PropertyAccessorElementImpl;

    PropertyInducingElement variable = e.variable;
    expect(variable, isNotNull);

    var variableEnclosing = variable.enclosingElement2;
    if (variableEnclosing is CompilationUnitElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is InterfaceElement) {
      expect(variableEnclosing.fields, contains(variable));
    }

    if (e.isGetter) {
      expect(variable.getter, same(e));
      if (variable.setter != null) {
        expect(variable.setter!.variable, same(variable));
      }
    } else {
      expect(variable.setter, same(e));
      if (variable.getter != null) {
        expect(variable.getter!.variable, same(variable));
      }
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
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);

      expect(e.typeParameters, isEmpty);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType2);
      _writeNonSyntheticElement(e);
      writeLinking();
    });
  }

  void _writePropertyInducingElement(PropertyInducingElement e) {
    e as PropertyInducingElementImpl;

    DartType type = e.type;
    expect(type, isNotNull);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      expect(e.getter, isNotNull);
      _assertSyntheticAccessorEnclosing(e, e.getter!);

      if (e.setter != null) {
        _assertSyntheticAccessorEnclosing(e, e.setter!);
      }

      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
      _assertNonSyntheticElementSelf(e);
    }

    _sink.writeIndentedLine(() {
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
    });
  }

  void _writeShouldUseTypeForInitializerInference(
    PropertyInducingElementImpl e,
  ) {
    if (!e.isSynthetic) {
      _sink.writelnWithIndent(
        'shouldUseTypeForInitializerInference: '
        '${e.shouldUseTypeForInitializerInference}',
      );
    }
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
        _elementPrinter.writeElement(
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
          _writeType('returnType', aliasedElement.returnType2);
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

  void _writeUnitElement(CompilationUnitElement e) {
    _writeElements('classes', e.classes, _writeClassElement);
    _writeElements('enums', e.enums, _writeClassElement);
    _writeElements('extensions', e.extensions, _writeExtensionElement);
    _writeElements('mixins', e.mixins, _writeClassElement);
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

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}

extension on ClassElement {
  bool get isMacro {
    final self = this;
    return self is ClassElementImpl && self.isMacro;
  }
}
