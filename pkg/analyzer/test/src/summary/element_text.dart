// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../util/element_printer.dart';
import 'resolved_ast_printer.dart';

String getLibraryText({
  required LibraryElementImpl library,
  required ElementTextConfiguration configuration,
  String indent = '',
}) {
  var buffer = StringBuffer();
  var sink = TreeStringSink(sink: buffer, indent: '');
  writeLibrary(sink: sink, library: library, configuration: configuration);
  return buffer.toString();
}

void writeLibrary({
  required TreeStringSink sink,
  required LibraryElementImpl library,
  required ElementTextConfiguration configuration,
}) {
  var elementPrinter = ElementPrinter(
    sink: sink,
    configuration: configuration.elementPrinterConfiguration,
  );

  var writer2 = _Element2Writer(
    sink: sink,
    elementPrinter: elementPrinter,
    configuration: configuration,
  );
  writer2.writeLibraryElement(library);
}

class ElementTextConfiguration {
  ElementPrinterConfiguration elementPrinterConfiguration =
      ElementPrinterConfiguration();
  bool Function(Object) filter;
  bool withAllSupertypes = false;
  bool withCodeRanges = false;
  bool withConstantInitializers = true;
  bool withConstructors = true;
  bool withDisplayName = false;
  bool withExportScope = false;
  bool withFunctionTypeParameters = false;
  bool withImports = true;
  bool withLibraryAugmentations = false;
  bool withLibraryFragments = true;
  bool withMetadata = true;
  bool withNonSynthetic = false;
  bool withRedirectedConstructors = false;
  bool withReferences = true;
  bool withReturnType = true;
  bool withSyntheticDartCoreImport = false;
  bool withSyntheticGetters = true;

  ElementTextConfiguration({this.filter = _filterTrue});

  void forClassConstructors({Set<String> classNames = const {}}) {
    filter = (o) {
      switch (o) {
        case LibraryFragment():
          return true;
        case ClassFragmentImpl():
          return classNames.contains(o.name);
        case ClassElement():
          return classNames.contains(o.name);
        case ConstructorFragment():
        case ConstructorElement():
          return true;
      }
      return false;
    };
  }

  void forPromotableFields({
    Set<String> classNames = const {},
    Set<String> enumNames = const {},
    Set<String> extensionTypeNames = const {},
    Set<String> mixinNames = const {},
    Set<String> fieldNames = const {},
  }) {
    filter = (o) {
      switch (o) {
        case LibraryFragment():
          return false;
        case ClassElement():
          return classNames.contains(o.name);
        case ConstructorElement():
          return false;
        case EnumElement():
          return enumNames.contains(o.name);
        case ExtensionTypeElement():
          return extensionTypeNames.contains(o.name);
        case FieldElement():
          return fieldNames.isEmpty || fieldNames.contains(o.name);
        case MixinElement():
          return mixinNames.contains(o.name);
        case PropertyAccessorElement():
          return false;
      }
      return true;
    };
  }

  static bool _filterTrue(Object element) => true;
}

/// Writes the canonical text presentation of elements.
abstract class _AbstractElementWriter {
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;
  final ElementTextConfiguration configuration;

  _AbstractElementWriter({
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
    required this.configuration,
  }) : _sink = sink,
       _elementPrinter = elementPrinter;

  IdMap get _idMap => _elementPrinter.idMap;

  ResolvedAstPrinter _createAstPrinter() {
    return ResolvedAstPrinter(
      sink: _sink,
      elementPrinter: _elementPrinter,
      configuration: ResolvedNodeTextConfiguration()
        // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49101
        ..withParameterElements = false,
      withOffsets: true,
    );
  }

  void _writeDirectiveUri(DirectiveUri uri) {
    if (uri is DirectiveUriWithLibraryImpl) {
      _sink.write('${uri.library.source.uri}');
    } else if (uri is DirectiveUriWithUnit) {
      _sink.write('${uri.libraryFragment.source.uri}');
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

  void _writeExportedReferences(LibraryElementImpl e) {
    var exportedReferences = e.exportedReferences.toList();
    exportedReferences.sortBy((e) => e.reference.toString());

    for (var exported in exportedReferences) {
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

  void _writeFieldNameNonPromotabilityInfo(
    Map<String, FieldNameNonPromotabilityInfo>? info,
  ) {
    if (info == null || info.isEmpty) {
      return;
    }

    _sink.writelnWithIndent('fieldNameNonPromotabilityInfo');
    _sink.withIndent(() {
      for (var entry in info.entries) {
        _sink.writelnWithIndent(entry.key);
        _sink.withIndent(() {
          _elementPrinter.writeElementList2(
            'conflictingFields',
            entry.value.conflictingFields,
          );
          _elementPrinter.writeElementList2(
            'conflictingGetters',
            entry.value.conflictingGetters,
          );
          _elementPrinter.writeElementList2(
            'conflictingNsmClasses',
            entry.value.conflictingNsmClasses,
          );
        });
      }
    });
  }

  void _writeNode(AstNode node) {
    _sink.writeIndent();
    node.accept(_createAstPrinter());
  }

  void _writeReference(ElementImpl e) {
    if (!configuration.withReferences) {
      return;
    }

    var reference = e.reference;
    if (reference != null) {
      _sink.writeIndentedLine(() {
        _sink.write('reference: ');
        _elementPrinter.writeReference(reference);
      });
    }
  }
}

/// Writes the canonical text presentation of elements.
class _Element2Writer extends _AbstractElementWriter {
  _Element2Writer({
    required super.sink,
    required super.elementPrinter,
    required super.configuration,
  });

  void writeLibraryElement(LibraryElementImpl e) {
    expect(e.enclosingElement, isNull);

    _sink.writelnWithIndent('library');
    _sink.withIndent(() {
      _writeReference(e);

      var name = e.name;
      if (name.isNotEmpty) {
        _sink.writelnWithIndent('name: $name');
      }

      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);

      // _writeList(
      //   'libraryExports',
      //   e.libraryExports,
      //   _writeLibraryExportElement,
      // );

      if (configuration.withLibraryFragments) {
        _writeFragmentList(
          'fragments',
          null,
          e.fragments,
          _writeLibraryFragment,
        );
      }

      _writeElementList('classes', e, e.classes, _writeInstanceElement);
      _writeElementList('enums', e, e.enums, _writeInstanceElement);
      _writeElementList('extensions', e, e.extensions, _writeInstanceElement);
      _writeElementList(
        'extensionTypes',
        e,
        e.extensionTypes,
        _writeInstanceElement,
      );
      _writeElementList('mixins', e, e.mixins, _writeInstanceElement);
      _writeElementList(
        'typeAliases',
        e,
        e.typeAliases,
        _writeTypeAliasElement,
      );

      _writeElementList(
        'topLevelVariables',
        e,
        e.topLevelVariables,
        _writeTopLevelVariableElement,
      );

      _writeElementList(
        'getters',
        e,
        e.getters.where((getter) {
          if (!configuration.withSyntheticGetters && getter.isSynthetic) {
            return false;
          }
          return true;
        }).toList(),
        _writeGetterElement,
      );

      _writeElementList('setters', e, e.setters, _writeSetterElement);
      _writeElementList(
        'functions',
        e,
        e.topLevelFunctions,
        _writeTopLevelFunctionElement,
      );

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

      _writeFieldNameNonPromotabilityInfo(e.fieldNameNonPromotabilityInfo);
    });
  }

  void _assertNonSyntheticElementSelf(Element element) {
    expect(element.isSynthetic, isFalse);
    expect(element.nonSynthetic, same(element));
  }

  void _writeConstantInitializerExpression(String name, Expression expression) {
    if (_idMap.existingExpressionId(expression) case var id?) {
      _sink.writelnWithIndent('$name: $id');
    } else {
      var id = _idMap[expression];
      _sink.writelnWithIndent('$name: $id');
      _sink.withIndent(() {
        _writeNode(expression);
      });
    }
  }

  void _writeConstructorElement(ConstructorElement e) {
    e as ConstructorElementImpl;

    // Check that the reference exists, and filled with the element.
    // var reference = e.reference;
    // if (reference == null) {
    //   fail('Every constructor must have a reference.');
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isFactory, 'factory ');
      _sink.writeIf(e.isExtensionTypeMember, 'isExtensionTypeMember ');
      expect(e.isAbstract, isFalse);
      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeDisplayName(e);

      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );

      _writeList('constantInitializers', e.constantInitializers, _writeNode);

      var superConstructor = e.superConstructor;
      if (superConstructor != null) {
        var enclosingElement = superConstructor.enclosingElement;
        if (enclosingElement is ClassElementImpl &&
            !enclosingElement.isDartCoreObject) {
          _writeElementReference('superConstructor', superConstructor);
        }
      }

      var redirectedConstructor = e.redirectedConstructor;
      if (redirectedConstructor != null) {
        _writeElementReference('redirectedConstructor', redirectedConstructor);
      }

      // _writeNonSyntheticElement(e);
    });

    // if (e.isSynthetic) {
    //   expect(e.nameOffset, -1);
    //   expect(e.nonSynthetic, same(e.enclosingElement));
    // } else {
    //   expect(e.nameOffset, isPositive);
    // }
  }

  void _writeConstructorFragment(ConstructorFragment f) {
    f as ConstructorFragmentImpl;

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');
      _sink.writeIf(f.isExternal, 'external ');
      _sink.writeIf(f.isConst, 'const ');
      _sink.writeIf(f.isFactory, 'factory ');
      expect(f.isAbstract, isFalse);
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeFragmentCodeRange(f);
      // _writeDisplayName(f);

      _sink.writelnWithIndent('typeName: ${f.typeName}');
      if (f.typeNameOffset case var typeNameOffset?) {
        _sink.writelnWithIndent('typeNameOffset: $typeNameOffset');
      }

      if (f.periodOffset case var periodOffset?) {
        _sink.writelnWithIndent('periodOffset: $periodOffset');
      }

      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );

      // _writeNonSyntheticElement(f);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeFragmentReference('previousFragment', f.previousFragment);
    });

    expect(f.isAsynchronous, isFalse);
    expect(f.isGenerator, isFalse);
  }

  void _writeDocumentation(String? documentation) {
    if (documentation != null) {
      var str = documentation;
      str = str.replaceAll('\n', r'\n');
      str = str.replaceAll('\r', r'\r');
      _sink.writelnWithIndent('documentationComment: $str');
    }
  }

  void _writeElementList<E extends ElementImpl>(
    String name,
    ElementImpl expectedEnclosingElement,
    List<E> elements,
    void Function(E) write,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var element in filtered) {
          expect(element.enclosingElement, expectedEnclosingElement);
          write(element);
        }
      });
    }
  }

  void _writeElementName(Element e) {
    var name = e.name ?? '<null-name>';
    _sink.write(name);

    switch (e) {
      case MethodElement():
        if (e.name == '-' && e.formalParameters.isEmpty) {
          expect(e.lookupName, 'unary-');
        } else {
          expect(e.lookupName, e.name);
        }
      case SetterElement():
        if (e.name case var name?) {
          expect(e.lookupName, '$name=');
        } else {
          expect(e.lookupName, isNull);
        }
      default:
        expect(e.lookupName, e.name);
    }
  }

  void _writeElementReference(String name, Element? e) {
    if (!configuration.withReferences) {
      return;
    }

    if (e == null) {
      return;
    }

    _elementPrinter.writeNamedElement2(name, e);
  }

  void _writeExportNamespace(LibraryElement e) {
    var map = e.exportNamespace.definedNames2;
    var sortedEntries = map.entries.sortedBy((entry) => entry.key);
    for (var entry in sortedEntries) {
      _elementPrinter.writeNamedElement2(entry.key, entry.value);
    }
  }

  void _writeFieldElement(FieldElementImpl e) {
    e as InternalFieldElement;
    DartType type = e.type;
    expect(type, isNotNull);

    // if (e.isSynthetic) {
    //   expect(e.nameOffset, -1);
    // } else {
    //   if (!e.isAugmentation) {
    //     expect(e.getter, isNotNull);
    //   }

    //   expect(e.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(e);
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isCovariant, 'covariant ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isLate, 'late ');
      _sink.writeIf(e.isFinal, 'final ');
      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isEnumConstant, 'enumConstant ');
      _sink.writeIf(e.isPromotable, 'promotable ');
      _sink.writeIf(e.hasInitializer, 'hasInitializer ');

      _writeElementName(e);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');

    //     var getter = e.getter;
    //     if (getter != null) {
    //       _sink.writelnWithIndent('getter: ${_idMap[getter]}');
    //     }

    //     var setter = e.setter;
    //     if (setter != null) {
    //       _sink.writelnWithIndent('setter: ${_idMap[setter]}');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      if (e.hasEnclosingTypeParameterReference) {
        _sink.writelnWithIndent('hasEnclosingTypeParameterReference: true');
      }
      // _writeDocumentation(e.documentationComment);
      // _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeCodeRange(e);
      // _writeTypeInferenceError(e);
      _writeType('type', e.type);
      // _writeShouldUseTypeForInitializerInference(e);
      _writeVariableElementConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeElementReference('getter', e.getter);
      _writeElementReference('setter', e.setter);
    });
  }

  void _writeFieldFragment(FieldFragmentImpl f) {
    // TODO(brianwilkerson): Implement `type`.
    // DartType type = e.type;
    // expect(type, isNotNull);

    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    // // TODO(brianwilkerson): Implement `isAugmentation`.
    //   if (!f.isAugmentation) {
    //     expect(f.getter2, isNotNull);
    //   }
    //   expect(f.nameOffset, isPositive);
    //   // _assertNonSyntheticElementSelf(e);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');
      _sink.writeIf(f.hasInitializer, 'hasInitializer ');

      _writeFragmentName(f);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[f]}');

    //     var getter = f.getter2;
    //     if (getter != null) {
    //       _sink.writelnWithIndent('getter: ${_idMap[getter]}');
    //     }

    //     var setter = f.setter2;
    //     if (setter != null) {
    //       _sink.writelnWithIndent('setter: ${_idMap[setter]}');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      // _writeDocumentation(f.documentationComment);
      // _writeMetadata(f.metadata);
      // _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);
      // _writeTypeInferenceError(f);
      // _writeType('type', f.type);
      // _writeShouldUseTypeForInitializerInference(f);
      _writeVariableFragmentInitializer(f);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeFormalParameterElement(FormalParameterElement e) {
    e as FormalParameterElementImpl;
    // if (e.isNamed && e.enclosingElement is ExecutableElement) {
    //   expect(e.reference, isNotNull);
    // } else {
    //   expect(e.reference, isNull);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(e);
      if (e.isRequiredPositional) {
        _sink.write('requiredPositional ');
      } else if (e.isOptionalPositional) {
        _sink.write('optionalPositional ');
      } else if (e.isRequiredNamed) {
        _sink.write('requiredNamed ');
      } else if (e.isOptionalNamed) {
        _sink.write('optionalNamed ');
      }

      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.isCovariant, 'covariant ');
      _sink.writeIf(e.isFinal, 'final ');
      _sink.writeIf(e.hasImplicitType, 'hasImplicitType ');

      if (e is FieldFormalParameterFragmentImpl) {
        _sink.write('this.');
      } else if (e is SuperFormalParameterFragmentImpl) {
        _sink.writeIf(e.hasDefaultValue, 'hasDefaultValue ');
        _sink.write('super.');
      }

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeType('type', e.type);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeCodeRange(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeVariableElementConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // _writeFieldFormalParameterField(e);
      // _writeSuperConstructorParameter(e);
    });
  }

  void _writeFormalParameterFragment(FormalParameterFragment f) {
    f as FormalParameterFragmentImpl;
    // if (f.isNamed && f.enclosingFragment is ExecutableFragment) {
    //   expect(f.reference, isNotNull);
    // } else {
    //   expect(f.reference, isNull);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      // if (f.isRequiredPositional) {
      //   _sink.write('requiredPositional ');
      // } else if (f.isOptionalPositional) {
      //   _sink.write('optionalPositional ');
      // } else if (f.isRequiredNamed) {
      //   _sink.write('requiredNamed ');
      // } else if (f.isOptionalNamed) {
      //   _sink.write('optionalNamed ');
      // }

      // _sink.writeIf(f.isConst, 'const ');
      // _sink.writeIf(f.isCovariant, 'covariant ');
      // _sink.writeIf(f.isFinal, 'final ');

      if (f is FieldFormalParameterFragmentImpl) {
        _sink.write('this.');
      } else if (f is SuperFormalParameterFragmentImpl) {
        // _sink.writeIf(f.hasDefaultValue, 'hasDefaultValue ');
        _sink.write('super.');
      }

      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      // _writeType('type', f.type);
      _writeMetadata(f.metadata);
      // _writeCodeRange(f);
      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters,
        _writeTypeParameterFragment,
      );
      _writeFragmentList(
        'parameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      _writeVariableFragmentInitializer(f);
      // _writeNonSyntheticElement(e);
      // _writeFieldFormalParameterField(e);
      // _writeSuperConstructorParameter(e);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeFragmentBodyModifiers(ExecutableFragment f) {
    if (f.isAsynchronous) {
      expect(f.isSynchronous, isFalse);
      _sink.write(' async');
    }

    if (f.isSynchronous && f.isGenerator) {
      expect(f.isAsynchronous, isFalse);
      _sink.write(' sync');
    }

    _sink.writeIf(f.isGenerator, '*');

    if (f is ExecutableFragmentImpl && f.invokesSuperSelf) {
      _sink.write(' invokesSuperSelf');
    }
  }

  void _writeFragmentCodeRange(Fragment f) {
    if (configuration.withCodeRanges) {
      if (f is FragmentImpl) {
        if (!f.isSynthetic) {
          _sink.writelnWithIndent('codeOffset: ${f.codeOffset}');
          _sink.writelnWithIndent('codeLength: ${f.codeLength}');
        }
      }
    }
  }

  void _writeFragmentList<E extends Fragment>(
    String name,
    Fragment? expectedEnclosingFragment,
    List<E> elements,
    void Function(E) write,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var element in filtered) {
          if (expectedEnclosingFragment != null) {
            expect(element.enclosingFragment, expectedEnclosingFragment);
          }
          write(element);
        }
      });
    }
  }

  void _writeFragmentName(FragmentImpl f) {
    if (f.name == null) {
      expect(f.nameOffset, isNull);
    }

    _sink.write(f.name ?? '<null-name>');
    _writeFragmentOffsets(f);
  }

  void _writeFragmentOffsets(FragmentImpl f) {
    if (f is LibraryFragmentImpl) {
      expect(f.nameOffset, isNull);
      expect(f.firstTokenOffset, 0);
      if (f.offset == 0) {
        return;
      }
    }

    _sink.write(' (nameOffset:${f.nameOffset ?? '<null>'})');
    _sink.write(' (firstTokenOffset:${f.firstTokenOffset ?? '<null>'})');
    _sink.write(' (offset:${f.offset})');
  }

  void _writeFragmentReference(String name, Fragment? f) {
    if (!configuration.withReferences) {
      return;
    }

    if (f == null) {
      return;
    }

    _sink.writeIndentedLine(() {
      _sink.write(name);
      _sink.write(': ');
      _sink.write(_idMap[f]);
    });
  }

  void _writeGetterElement(GetterElementImpl e) {
    var variable = e.variable;
    var variableEnclosing = variable.enclosingElement;
    if (variableEnclosing is LibraryElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is InterfaceElement) {
      // TODO(augmentations): Remove the invocations of `field.baseElement`.
      //  There shouldn't be any members in the list of fields.
      expect(
        variableEnclosing.fields.map((field) => field.baseElement),
        contains(variable.baseElement),
      );
    }

    // if (e.isSynthetic) {
    //   expect(e.nameOffset, -1);
    // } else {
    //   expect(e.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(e);
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isExtensionTypeMember, 'isExtensionTypeMember ');

      _writeElementName(e);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');
    //     if (e.variable2 case var variable?) {
    //       _sink.writelnWithIndent('variable: ${_idMap[variable]}');
    //     } else {
    //       _sink.writelnWithIndent('variable: <null>');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      if (e.hasEnclosingTypeParameterReference) {
        _sink.writelnWithIndent('hasEnclosingTypeParameterReference: true');
      }
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);

      expect(e.typeParameters, isEmpty);
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeReturnType(e.returnType);
      _writeElementReference('variable', e.variable);
      // _writeNonSyntheticElement(e);
      // writeLinking();
    });
  }

  void _writeGetterFragment(GetterFragmentImpl f) {
    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    //   expect(f.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(f);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');

      _writeFragmentName(f);
      // _writeBodyModifiers(e);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');
    //     if (e.variable2 case var variable?) {
    //       _sink.writelnWithIndent('variable: ${_idMap[variable]}');
    //     } else {
    //       _sink.writelnWithIndent('variable: <null>');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      // _writeCodeRange(f);

      // expect(f.typeParameters2, isEmpty);
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeNonSyntheticElement(f);
      // writeLinking();
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeImportElementPrefix(PrefixFragmentImpl? fragment) {
    if (fragment != null) {
      _sink.writeIf(fragment.isDeferred, ' deferred');
      _sink.write(' as ');
      _writeFragmentName(fragment);
    }
  }

  void _writeInstanceElement(InstanceElementImpl e) {
    expect(e.thisOrAncestorOfType<InstanceElement>(), same(e));
    expect(e.thisOrAncestorOfType<GetterElement>(), isNull);
    expect(e.thisOrAncestorMatching((_) => true), same(e));
    expect(e.thisOrAncestorMatching((_) => false), isNull);

    _sink.writeIndentedLine(() {
      switch (e) {
        case ClassElementImpl():
          _sink.writeIf(e.isAbstract, 'abstract ');
          _sink.writeIf(e.isSealed, 'sealed ');
          _sink.writeIf(e.isBase, 'base ');
          _sink.writeIf(e.isInterface, 'interface ');
          _sink.writeIf(e.isFinal, 'final ');
          _writeNotSimplyBounded(e);
          _sink.writeIf(e.hasNonFinalField, 'hasNonFinalField ');
          _sink.writeIf(e.isMixinClass, 'mixin ');
          _sink.write('class ');
          _sink.writeIf(e.isMixinApplication, 'alias ');
        case EnumElementImpl():
          _writeNotSimplyBounded(e);
          _sink.write('enum ');
        case ExtensionElementImpl():
          _sink.write('extension ');
        case ExtensionTypeElementImpl():
          _sink.writeIf(
            e.hasRepresentationSelfReference,
            'hasRepresentationSelfReference ',
          );
          _sink.writeIf(
            e.hasImplementsSelfReference,
            'hasImplementsSelfReference ',
          );
          _writeNotSimplyBounded(e);
          _sink.write('extension type ');
        case MixinElementImpl():
          _sink.writeIf(e.isBase, 'base ');
          _writeNotSimplyBounded(e);
          _sink.writeIf(e.hasNonFinalField, 'hasNonFinalField ');
          _sink.write('mixin ');
      }

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      // _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters,
        _writeTypeParameterElement,
      );

      void writeSupertype(InterfaceElement e) {
        if (e.supertype case var supertype?) {
          if (supertype.element.name != 'Object' || e.mixins.isNotEmpty) {
            _writeType('supertype', supertype);
          }
        }
      }

      switch (e) {
        case ClassElementImpl():
          writeSupertype(e);
          _elementPrinter.writeTypeList('mixins', e.mixins);
          _elementPrinter.writeTypeList('interfaces', e.interfaces);
        case EnumElementImpl():
          writeSupertype(e);
          _elementPrinter.writeTypeList('mixins', e.mixins);
          _elementPrinter.writeTypeList('interfaces', e.interfaces);
        case ExtensionElementImpl():
          _elementPrinter.writeNamedType('extendedType', e.extendedType);
        case ExtensionTypeElementImpl():
          expect(e.supertype, isNull);
          _elementPrinter.writeNamedElement2(
            'representation',
            e.representation,
          );
          _elementPrinter.writeNamedElement2(
            'primaryConstructor',
            e.primaryConstructor,
          );
          _elementPrinter.writeNamedType('typeErasure', e.typeErasure);
          _elementPrinter.writeTypeList('interfaces', e.interfaces);
        case MixinElementImpl():
          expect(e.supertype, isNull);
          _elementPrinter.writeTypeList(
            'superclassConstraints',
            e.superclassConstraints,
          );
          expect(e.mixins, isEmpty);
          _elementPrinter.writeTypeList('interfaces', e.interfaces);
        default:
          throw UnimplementedError('${e.runtimeType}');
      }

      if (configuration.withAllSupertypes && e is InterfaceElementImpl) {
        var sorted = e.allSupertypes.sortedBy((t) => t.element.name!);
        _elementPrinter.writeTypeList('allSupertypes', sorted);
      }

      _writeElementList('fields', e, e.fields, _writeFieldElement);
      if (e is InterfaceElementImpl) {
        var constructors = e.constructors;
        if (e is MixinElementImpl) {
          expect(constructors, isEmpty);
        } else if (configuration.withConstructors) {
          _writeElementList(
            'constructors',
            e,
            constructors,
            _writeConstructorElement,
          );
        }
      }
      _writeElementList('getters', e, e.getters, _writeGetterElement);
      _writeElementList('setters', e, e.setters, _writeSetterElement);
      _writeElementList('methods', e, e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeInstanceFragment(InstanceFragmentImpl f) {
    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      switch (f) {
        case ClassFragmentImpl():
          // TODO(brianwilkerson): Figure out why we can't ask the fragments
          //  these questions.
          // _sink.writeIf(f.isAbstract, 'abstract ');
          // _sink.writeIf(f.isSealed, 'sealed ');
          // _sink.writeIf(f.isBase, 'base ');
          // _sink.writeIf(f.isInterface, 'interface ');
          // _sink.writeIf(f.isFinal, 'final ');
          // _writeNotSimplyBounded(f);
          // _sink.writeIf(f.isMixinClass, 'mixin ');
          _sink.write('class ');
        // _sink.writeIf(f.isMixinApplication, 'alias ');
        case EnumFragment():
          // _writeNotSimplyBounded(f);
          _sink.write('enum ');
        case ExtensionFragment():
          _sink.write('extension ');
        case ExtensionTypeFragment():
          //   _sink.writeIf(
          //     e.hasRepresentationSelfReference,
          //     'hasRepresentationSelfReference ',
          //   );
          //   _sink.writeIf(
          //     e.hasImplementsSelfReference,
          //     'hasImplementsSelfReference ',
          //   );
          //   // _writeNotSimplyBounded(e);
          _sink.write('extension type ');
        case MixinFragment():
          // _sink.writeIf(f.isBase, 'base ');
          // _writeNotSimplyBounded(f);
          _sink.write('mixin ');
      }
      _writeFragmentName(f);
    });
    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);

      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters,
        _writeTypeParameterFragment,
      );
      _writeFragmentList('fields', f, f.fields, _writeFieldFragment);
      if (f is InterfaceFragmentImpl) {
        var constructors = f.constructors;
        if (f is MixinElement) {
          expect(constructors, isEmpty);
        } else if (configuration.withConstructors) {
          _writeFragmentList(
            'constructors',
            f,
            constructors,
            _writeConstructorFragment,
          );
        }
      }
      _writeFragmentList('getters', f, f.getters, _writeGetterFragment);
      _writeFragmentList('setters', f, f.setters, _writeSetterFragment);
      _writeFragmentList('methods', f, f.methods, _writeMethodFragment);
    });
  }

  void _writeLibraryExport(LibraryExportImpl e) {
    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _sink.withIndent(() {
      _writeMetadata(e.metadata);
      _writeNamespaceCombinators(e.combinators);
    });
  }

  void _writeLibraryFragment(LibraryFragmentImpl f) {
    _sink.writeIndentedLine(() {
      _writeObjectId(f);

      var uriStr = f.source.uri.toString();
      if (uriStr == 'package:test/test.dart') {
        _sink.write('<testLibraryFragment>');
      } else {
        _sink.write(uriStr);
      }

      _writeFragmentOffsets(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeFragmentReference('enclosingFragment', f.enclosingFragment);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);

      if (configuration.withImports) {
        var imports = f.libraryImports.where((import) {
          return configuration.withSyntheticDartCoreImport ||
              !import.isSynthetic;
        }).toList();
        _writeList('libraryImports', imports, _writeLibraryImport);
      }
      _writeList('prefixes', f.prefixes, _writePrefixElement);
      _writeList('libraryExports', f.libraryExports, _writeLibraryExport);
      _writeList('parts', f.parts, _writePartInclude);

      _writeFragmentList('classes', f, f.classes, _writeInstanceFragment);
      _writeFragmentList('enums', f, f.enums, _writeInstanceFragment);
      _writeFragmentList('extensions', f, f.extensions, _writeInstanceFragment);
      _writeFragmentList(
        'extensionTypes',
        f,
        f.extensionTypes,
        _writeInstanceFragment,
      );
      _writeFragmentList('mixins', f, f.mixins, _writeInstanceFragment);
      _writeFragmentList(
        'typeAliases',
        f,
        f.typeAliases,
        _writeTypeAliasFragment,
      );
      _writeFragmentList(
        'topLevelVariables',
        f,
        f.topLevelVariables,
        _writeTopLevelVariableFragment,
      );
      _writeFragmentList('getters', f, f.getters, _writeGetterFragment);
      _writeFragmentList('setters', f, f.setters, _writeSetterFragment);
      _writeFragmentList(
        'functions',
        f,
        f.functions,
        _writeTopLevelFunctionFragment,
      );
    });
  }

  void _writeLibraryImport(LibraryImportImpl e) {
    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
      _sink.writeIf(e.isSynthetic, ' synthetic');
      _writeImportElementPrefix(e.prefix);
    });

    _sink.withIndent(() {
      _writeMetadata(e.metadata);
      _writeNamespaceCombinators(e.combinators);
    });
  }

  void _writeList<E extends Object>(
    String name,
    List<E> elements,
    void Function(E) write,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var element in filtered) {
          write(element);
        }
      });
    }
  }

  void _writeMetadata(Metadata metadata) {
    if (configuration.withMetadata) {
      var annotations = metadata.annotations;
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
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isExtensionTypeMember, 'isExtensionTypeMember ');

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      // _writeElementReference(e.enclosingElement, label: 'enclosingElement');
      if (e.hasEnclosingTypeParameterReference) {
        _sink.writelnWithIndent('hasEnclosingTypeParameterReference: true');
      }
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeTypeInferenceError(e);

      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeReturnType(e.returnType);
      // _writeNonSyntheticElement(e);
    });

    // if (e.isSynthetic && e.enclosingElement is EnumElementImpl) {
    //   expect(e.name, 'toString');
    //   expect(e.nonSynthetic2, same(e.enclosingElement));
    // } else {
    //   _assertNonSyntheticElementSelf(e);
    // }
  }

  void _writeMethodFragment(MethodFragmentImpl f) {
    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      // _sink.writeIf(f.isSynthetic, 'synthetic ');
      // _sink.writeIf(f.isStatic, 'static ');
      // _sink.writeIf(f.isAbstract, 'abstract ');
      // _sink.writeIf(f.isExternal, 'external ');

      _writeFragmentName(f);
      _writeFragmentBodyModifiers(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeFragmentCodeRange(f);
      // _writeTypeInferenceError(f);

      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters,
        _writeTypeParameterFragment,
      );
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeReturnType(f.returnType);
      // _writeNonSyntheticElement(f);
      // _writeAugmentationTarget(f);
      // _writeAugmentation(f);
    });
  }

  void _writeNamespaceCombinator(NamespaceCombinator e) {
    _sink.writeIndentedLine(() {
      switch (e) {
        case ShowElementCombinator():
          _sink.write('show: ');
          _sink.write(e.shownNames.join(', '));
        case HideElementCombinator():
          _sink.write('hide: ');
          _sink.write(e.hiddenNames.join(', '));
      }
    });
  }

  void _writeNamespaceCombinators(List<NamespaceCombinator> elements) {
    _writeList('combinators', elements, _writeNamespaceCombinator);
  }

  void _writeNotSimplyBounded(InterfaceElementImpl e) {
    _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
  }

  void _writeObjectId(Object object) {
    _sink.write('${_idMap[object]} ');
  }

  void _writePartInclude(PartIncludeImpl e) {
    _sink.writelnWithIndent(_idMap[e]);

    _sink.withIndent(() {
      var uri = e.uri;
      _sink.writeIndentedLine(() {
        _sink.write('uri: ');
        _writeDirectiveUri(e.uri);
      });
      _sink.writelnWithIndent('partKeywordOffset: ${e.partKeywordOffset}');

      _writeMetadata(e.metadata);

      if (uri is DirectiveUriWithUnitImpl) {
        _elementPrinter.writeNamedFragment('unit', uri.libraryFragment);
      }
    });
  }

  void _writePrefixElement(PrefixElementImpl e) {
    _sink.writeIndent();
    _elementPrinter.writeElement2(e);

    _sink.withIndent(() {
      _sink.writeIndentedLine(() {
        _sink.write('fragments: ');
        _sink.write(
          e.fragments
              .map((f) {
                expect(f.element, same(e));
                expect(f.name, e.name);
                return '@${f.nameOffset}';
              })
              .join(' '),
        );
      });
    });
  }

  void _writeReturnType(DartType type) {
    if (configuration.withReturnType) {
      _writeType('returnType', type);
    }
  }

  void _writeSetterElement(SetterElementImpl e) {
    var variable = e.variable;
    var variableEnclosing = variable.enclosingElement;
    if (variableEnclosing is LibraryElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is InterfaceElement) {
      // TODO(augmentations): Remove the invocations of `field.baseElement`.
      //  There shouldn't be any members in the list of fields.
      expect(
        variableEnclosing.fields.map((field) => field.baseElement),
        contains(variable.baseElement),
      );
    }

    // if (e.isSynthetic) {
    //   expect(e.nameOffset, -1);
    // } else {
    //   expect(e.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(e);
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');
      _sink.writeIf(e.isExtensionTypeMember, 'isExtensionTypeMember ');

      _writeElementName(e);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');
    //     if (e.variable2 case var variable?) {
    //       _sink.writelnWithIndent('variable: ${_idMap[variable]}');
    //     } else {
    //       _sink.writelnWithIndent('variable: <null>');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      if (e.hasEnclosingTypeParameterReference) {
        _sink.writelnWithIndent('hasEnclosingTypeParameterReference: true');
      }
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);

      expect(e.typeParameters, isEmpty);
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeReturnType(e.returnType);
      _writeElementReference('variable', e.variable);
      // _writeNonSyntheticElement(e);
      // writeLinking();
    });
  }

  void _writeSetterFragment(SetterFragmentImpl f) {
    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    //   expect(f.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(f);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');

      _writeFragmentName(f);
      // _writeBodyModifiers(f);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');
    //     if (e.variable2 case var variable?) {
    //       _sink.writelnWithIndent('variable: ${_idMap[variable]}');
    //     } else {
    //       _sink.writelnWithIndent('variable: <null>');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      // _writeCodeRange(f);

      expect(f.typeParameters, isEmpty);
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeReturnType(f.returnType);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeSinceSdkVersion(Element element) {
    if (element.sinceSdkVersion case var sinceSdkVersion?) {
      _sink.writelnWithIndent('sinceSdkVersion: $sinceSdkVersion');
    }
  }

  void _writeTopLevelFunctionElement(TopLevelFunctionElementImpl e) {
    expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isExternal, 'external ');
      _writeElementName(e);
      // _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeCodeRange(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeType('returnType', e.returnType);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTopLevelFunctionFragment(TopLevelFunctionFragmentImpl f) {
    // expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isExternal, 'external ');
      _writeFragmentName(f);
      // _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
      // _writeCodeRange(e);
      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters,
        _writeTypeParameterFragment,
      );
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeType('returnType', e.returnType);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    // _assertNonSyntheticElementSelf(f);
  }

  void _writeTopLevelVariableElement(TopLevelVariableElementImpl e) {
    DartType type = e.type;
    expect(type, isNotNull);

    if (!e.isSynthetic) {
      // expect(e.getter2, isNotNull);
      _assertNonSyntheticElementSelf(e);
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isLate, 'late ');
      _sink.writeIf(e.isFinal, 'final ');
      _sink.writeIf(e.isConst, 'const ');
      _sink.writeIf(e.hasInitializer, 'hasInitializer ');

      _writeElementName(e);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');

    //     var getter = e.getter;
    //     if (getter != null) {
    //       _sink.writelnWithIndent('getter: ${_idMap[getter]}');
    //     }

    //     var setter = e.setter;
    //     if (setter != null) {
    //       _sink.writelnWithIndent('setter: ${_idMap[setter]}');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeTypeInferenceError(e);
      _writeType('type', e.type);
      // _writeShouldUseTypeForInitializerInference(e);
      _writeVariableElementConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeElementReference('getter', e.getter);
      _writeElementReference('setter', e.setter);
    });
  }

  void _writeTopLevelVariableFragment(TopLevelVariableFragmentImpl f) {
    // DartType type = f.type;
    // expect(type, isNotNull);

    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    //   if (!f.isAugmentation) {
    //     expect(f.getter, isNotNull);
    //   }

    //   expect(f.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(f);
    // }

    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');
      _sink.writeIf(f.hasInitializer, 'hasInitializer ');

      _writeFragmentName(f);
    });

    // void writeLinking() {
    //   if (configuration.withPropertyLinking) {
    //     _sink.writelnWithIndent('id: ${_idMap[e]}');

    //     var getter = e.getter;
    //     if (getter != null) {
    //       _sink.writelnWithIndent('getter: ${_idMap[getter]}');
    //     }

    //     var setter = e.setter;
    //     if (setter != null) {
    //       _sink.writelnWithIndent('setter: ${_idMap[setter]}');
    //     }
    //   }
    // }

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      // _writeCodeRange(f);
      // _writeTypeInferenceError(f);
      // _writeType('type', f.type);
      // _writeShouldUseTypeForInitializerInference(f);
      _writeVariableFragmentInitializer(f);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeType(String name, DartType type) {
    _elementPrinter.writeNamedType(name, type);

    // if (configuration.withFunctionTypeParameters) {
    //   if (type is FunctionType) {
    //     _sink.withIndent(() {
    //       // TODO(brianwilkerson): We need to define `parameters2` to return
    //       //  `List<ParmaeterElement2>`.
    //       _writeElements('parameters',  type, type.parameters2, _writeFormalParameterFragment);
    //     });
    //   }
    // }
  }

  void _writeTypeAliasElement(TypeAliasElementImpl e) {
    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e);
      // _writeCodeRange(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters,
        _writeTypeParameterElement,
      );

      var aliasedType = e.aliasedType;
      _writeType('aliasedType', aliasedType);

      // var aliasedElement = e.aliasedElement2;
      // if (aliasedElement is GenericFunctionTypeElementImpl) {
      //   _sink.writelnWithIndent('aliasedElement: GenericFunctionTypeElement');
      //   _sink.withIndent(() {
      //     _writeElementList('typeParameters', aliasedElement, aliasedElement.typeParameters2, _writeTypeParameterElement);
      //     _writeElementList('', aliasedElement, aliasedElement.parameters2, _writeFormalParameterElement);
      //     _writeType('returnType', aliasedElement.returnType);
      //   });
      // }

      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeAliasFragment(TypeAliasFragmentImpl f) {
    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      // _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      // _writeCodeRange(e);
      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters,
        _writeTypeParameterFragment,
      );

      // var aliasedType = e.aliasedType;
      // _writeType('aliasedType', aliasedType);

      // var aliasedElement = e.aliasedElement2;
      // if (aliasedElement is GenericFunctionTypeElementImpl) {
      //   _sink.writelnWithIndent('aliasedElement: GenericFunctionTypeElement');
      //   _sink.withIndent(() {
      //     _writeElementList('typeParameters', aliasedElement, aliasedElement.typeParameters2, _writeTypeParameterElement);
      //     _writeElementList('', aliasedElement, aliasedElement.parameters2, _writeFormalParameterElement);
      //     _writeType('returnType', aliasedElement.returnType);
      //   });
      // }

      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    // _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeParameterElement(TypeParameterElement e) {
    _sink.writeIndentedLine(() {
      _writeObjectId(e);
      // _sink.write('${e.variance.name} ');
      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      var bound = e.bound;
      if (bound != null) {
        _writeType('bound', bound);
      }

      // var defaultType = e.defaultType;
      // if (defaultType != null) {
      //   _writeType('defaultType', defaultType);
      // }

      _writeMetadata(e.metadata);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeParameterFragment(TypeParameterFragmentImpl f) {
    _sink.writeIndentedLine(() {
      _writeObjectId(f);
      // _sink.write('${e.variance.name} ');
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);

      // var bound = e.bound;
      // if (bound != null) {
      //   _writeType('bound', bound);
      // }

      // var defaultType = e.defaultType;
      // if (defaultType != null) {
      //   _writeType('defaultType', defaultType);
      // }

      _writeMetadata(f.metadata);
    });

    // _assertNonSyntheticElementSelf(f);
  }

  void _writeVariableElementConstantInitializer(VariableElementImpl e) {
    if (e.constantInitializer2 case var initializer?) {
      _sink.writelnWithIndent('constantInitializer');
      _sink.withIndent(() {
        _writeFragmentReference('fragment', initializer.fragment);
        _writeConstantInitializerExpression(
          'expression',
          initializer.expression,
        );
      });
    }
  }

  void _writeVariableFragmentInitializer(VariableFragment f) {
    f as VariableFragmentImpl;
    if (f.initializer case var initializer?) {
      _writeConstantInitializerExpression('initializer', initializer);
    }
  }
}
