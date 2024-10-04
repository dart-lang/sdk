// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_type_location.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../util/element_printer.dart';
import 'resolved_ast_printer.dart';

String getLibraryText({
  required LibraryElementImpl library,
  required ElementTextConfiguration configuration,
}) {
  var buffer = StringBuffer();
  var sink = TreeStringSink(
    sink: buffer,
    indent: '',
  );
  var elementPrinter = ElementPrinter(
    sink: sink,
    configuration: configuration.elementPrinterConfiguration,
  );
  var writer = _ElementWriter(
    sink: sink,
    elementPrinter: elementPrinter,
    configuration: configuration,
  );
  writer.writeLibraryElement(library);

  sink.writeln('-' * 40);
  var writer2 = _Element2Writer(
    sink: sink,
    elementPrinter: elementPrinter,
    configuration: configuration,
  );
  writer2.writeLibraryElement(library);
  return buffer.toString();
}

class ElementTextConfiguration {
  ElementPrinterConfiguration elementPrinterConfiguration =
      ElementPrinterConfiguration();
  bool Function(Object) filter;
  List<Pattern>? macroDiagnosticMessagePatterns;
  bool withAllSupertypes = false;
  bool withAugmentedWithoutAugmentation = false;
  bool withCodeRanges = false;
  bool withConstantInitializers = true;
  bool withConstructors = true;
  bool withDisplayName = false;
  bool withExportScope = false;
  bool withFunctionTypeParameters = false;
  bool withImports = true;
  bool withLibraryAugmentations = false;
  bool withMacroStackTraces = false;
  bool withMetadata = true;
  bool withNonSynthetic = false;
  bool withPropertyLinking = false;
  bool withRedirectedConstructors = false;
  bool withReturnType = true;
  bool withSyntheticDartCoreImport = false;

  ElementTextConfiguration({
    this.filter = _filterTrue,
  });

  static bool _filterTrue(Object element) => true;
}

/// Writes the canonical text presentation of elements.
abstract class _AbstractElementWriter {
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;
  final ElementTextConfiguration configuration;
  final _IdMap _idMap = _IdMap();

  _AbstractElementWriter({
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
    required this.configuration,
  })  : _sink = sink,
        _elementPrinter = elementPrinter;

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
          _elementPrinter.writeElementList(
            'conflictingFields',
            entry.value.conflictingFields,
          );
          _elementPrinter.writeElementList(
            'conflictingGetters',
            entry.value.conflictingGetters,
          );
          _elementPrinter.writeElementList(
            'conflictingNsmClasses',
            entry.value.conflictingNsmClasses,
          );
        });
      }
    });
  }

  void _writeNode(AstNode node) {
    _sink.writeIndent();
    node.accept(
      _createAstPrinter(),
    );
  }

  void _writeReference(ElementImpl e) {
    if (e.reference case var reference?) {
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
    expect(e.enclosingElement2, isNull);

    _sink.writelnWithIndent('library');
    _sink.withIndent(() {
      _writeReference(e as ElementImpl);

      var name = e.name;
      if (name.isNotEmpty) {
        _sink.writelnWithIndent('name: $name');
      }

      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);

      // _writeList(
      //   'libraryExports',
      //   e.libraryExports,
      //   _writeLibraryExportElement,
      // );

      _writeFragmentList('fragments', null, e.fragments, _writeLibraryFragment);

      _writeElementList('classes', e, e.classes, _writeInstanceElement);
      _writeElementList('enums', e, e.enums, _writeInstanceElement);
      _writeElementList('extensions', e, e.extensions, _writeInstanceElement);
      _writeElementList(
          'extensionTypes', e, e.extensionTypes, _writeInstanceElement);
      _writeElementList('mixins', e, e.mixins, _writeInstanceElement);
      _writeElementList(
          'typeAliases', e, e.typeAliases, _writeTypeAliasElement);

      _writeElementList('topLevelVariables', e, e.topLevelVariables,
          _writeTopLevelVariableElement);
      _writeElementList('getters', e, e.getters, _writeGetterElement);
      _writeElementList('setters', e, e.setters, _writeSetterElement);
      _writeElementList(
          'functions', e, e.functions, _writeTopLevelFunctionElement);

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
      _writeMacroDiagnostics(e);
    });
  }

  void _assertNonSyntheticElementSelf(Element2 element) {
    expect(element.isSynthetic, isFalse);
    expect(element.nonSynthetic2, same(element));
  }

  String _elementName(Element2 e) {
    var name = e.name ?? '<null>';
    if (e is SetterElement) {
      expect(name, endsWith('='));
    }
    if (name.isEmpty && e is ConstructorElement2) {
      return 'new';
    }
    return name;
  }

  String _fragmentName(Fragment f) {
    var name = f.name ?? '<null>';
    if (f is PropertyAccessorElementImpl && f.isSetter) {
      expect(name, endsWith('='));
    }
    if (name.isEmpty && f is ConstructorFragment) {
      return 'new';
    }
    return name;
  }

  void _writeConstructorElement(ConstructorElement2 e) {
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
      expect(e.isAbstract, isFalse);
      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeDisplayName(e);

      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );

      // _writeList(
      //   'constantInitializers',
      //   e.constantInitializers,
      //   _writeNode,
      // );

      var superConstructor = e.superConstructor2;
      if (superConstructor != null) {
        var enclosingElement = superConstructor.enclosingElement2;
        if (enclosingElement is ClassElement2 &&
            !enclosingElement.isDartCoreObject) {
          _writeElementReference('superConstructor', superConstructor);
        }
      }

      var redirectedConstructor = e.redirectedConstructor2;
      if (redirectedConstructor != null) {
        _writeElementReference('redirectedConstructor', redirectedConstructor);
      }

      // _writeNonSyntheticElement(e);
      _writeMacroDiagnostics(e);
    });

    // if (e.isSynthetic) {
    //   expect(e.nameOffset, -1);
    //   expect(e.nonSynthetic, same(e.enclosingElement));
    // } else {
    //   expect(e.nameOffset, isPositive);
    // }
  }

  void _writeConstructorFragment(ConstructorFragment f) {
    // Check that the reference exists, and filled with the element.
    var reference = (f as ConstructorElementImpl).reference;
    if (reference == null) {
      fail('Every constructor must have a reference.');
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');
      _sink.writeIf(f.isExternal, 'external ');
      _sink.writeIf(f.isConst, 'const ');
      _sink.writeIf(f.isFactory, 'factory ');
      expect(f.isAbstract, isFalse);
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      _writeFragmentCodeRange(f);
      // _writeDisplayName(f);

      var periodOffset = f.periodOffset;
      var nameEnd = f.nameEnd;
      if (periodOffset != null && nameEnd != null) {
        _sink.writelnWithIndent('periodOffset: $periodOffset');
        _sink.writelnWithIndent('nameEnd: $nameEnd');
      }

      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );

      _writeList(
        'constantInitializers',
        f.constantInitializers,
        _writeNode,
      );

      var superConstructor = f.superConstructor;
      if (superConstructor != null) {
        var enclosingElement = superConstructor.enclosingElement3;
        if (enclosingElement is ClassElement &&
            !enclosingElement.isDartCoreObject) {
          _elementPrinter.writeNamedElement(
            'superConstructor',
            superConstructor,
          );
        }
      }

      var redirectedConstructor = f.redirectedConstructor;
      if (redirectedConstructor != null) {
        _elementPrinter.writeNamedElement(
          'redirectedConstructor',
          redirectedConstructor,
        );
      }

      // _writeNonSyntheticElement(f);
      _writeMacroDiagnostics(f);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeFragmentReference('previousFragment', f.previousFragment);
    });

    expect(f.isAsynchronous, isFalse);
    expect(f.isGenerator, isFalse);

    if (f.isSynthetic) {
      expect(f.nameOffset, -1);
      expect(f.nonSynthetic, same(f.enclosingElement3));
    } else {
      expect(f.nameOffset, isPositive);
    }
  }

  void _writeDocumentation(String? documentation) {
    if (documentation != null) {
      var str = documentation;
      str = str.replaceAll('\n', r'\n');
      str = str.replaceAll('\r', r'\r');
      _sink.writelnWithIndent('documentationComment: $str');
    }
  }

  void _writeElementList<E extends Element2>(
    String name,
    Element2 expectedEnclosingElement,
    List<E> elements,
    void Function(E) write,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var element in filtered) {
          if (element is LibraryImport || element is LibraryExport) {
            // These are only accidentally subtypes of `Element2` and don't have
            // an enclosing element.
          } else if (element is PrefixElement2) {
            // Asking a `PrefixElement2` for it's enclosing element currently
            // throws an exception (because it doesn't have an enclosing
            // element, only an enclosing fragment).
          } else {
            if (expectedEnclosingElement is Member) {
              expectedEnclosingElement = expectedEnclosingElement.baseElement!;
            }
            expect(element.enclosingElement2, expectedEnclosingElement);
          }
          write(element);
        }
      });
    }
  }

  void _writeElementName(Element2 e) {
    _sink.write(_elementName(e));
  }

  void _writeElementReference(String name, Element2? e) {
    if (e == null) {
      return;
    }

    _elementPrinter.writelnNamedElement2(name, e);
  }

  void _writeExportNamespace(LibraryElement2 e) {
    var map = e.exportNamespace.definedNames;
    var sortedEntries = map.entries.sortedBy((entry) => entry.key);
    for (var entry in sortedEntries) {
      _elementPrinter.writeNamedElement(entry.key, entry.value);
    }
  }

  void _writeFieldElement(FieldElement2 e) {
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
      _writeFragmentReference('firstFragment', e.firstFragment);
      // _writeDocumentation(e.documentationComment);
      // _writeMetadata(e.metadata);
      // _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeCodeRange(e);
      // _writeTypeInferenceError(e);
      _writeType('type', e.type);
      // _writeShouldUseTypeForInitializerInference(e);
      // _writeConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeMacroDiagnostics(e);
      _writeElementReference('getter', e.getter2);
      _writeElementReference('setter', e.setter2);
    });
  }

  void _writeFieldFragment(FieldFragment f) {
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
      // _sink.writeIf(f.isAugmentation, 'augment ');
      // _sink.writeIf(f.isSynthetic, 'synthetic ');
      // _sink.writeIf(f.isStatic, 'static ');
      _sink.writeIf(f is FieldElementImpl && f.isAbstract, 'abstract ');
      _sink.writeIf(f is FieldElementImpl && f.isCovariant, 'covariant ');
      _sink.writeIf(f is FieldElementImpl && f.isExternal, 'external ');
      // _sink.writeIf(f.isLate, 'late ');
      // _sink.writeIf(f.isFinal, 'final ');
      // _sink.writeIf(f.isConst, 'const ');
      if (f is FieldElementImpl) {
        _sink.writeIf(f.isEnumConstant, 'enumConstant ');
        _sink.writeIf(f.isPromotable, 'promotable ');
      }

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
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      // _writeDocumentation(f.documentationComment);
      // _writeMetadata(f.metadata);
      // _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);
      // _writeTypeInferenceError(f);
      // _writeType('type', f.type);
      // _writeShouldUseTypeForInitializerInference(f);
      // _writeConstantInitializer(f);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      // _writeMacroDiagnostics(f);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeFragmentReference('getter2', f.getter2);
      _writeFragmentReference('setter2', f.setter2);
    });
  }

  void _writeFormalParameterElement(FormalParameterElement e) {
    // if (e.isNamed && e.enclosingElement2 is ExecutableElement) {
    //   expect(e.reference, isNotNull);
    // } else {
    //   expect(e.reference, isNull);
    // }

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
        _sink.writeIf(e.hasDefaultValue, 'hasDefaultValue ');
        _sink.write('super.');
      }

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeType('type', e.type);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeCodeRange(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters2,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      // _writeConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // _writeFieldFormalParameterField(e);
      // _writeSuperConstructorParameter(e);
    });
  }

  void _writeFormalParameterFragment(FormalParameterFragment f) {
    // if (f.isNamed && f.enclosingFragment is ExecutableFragment) {
    //   expect(f.reference, isNotNull);
    // } else {
    //   expect(f.reference, isNull);
    // }

    _sink.writeIndentedLine(() {
      // if (f.isRequiredPositional) {
      //   _sink.write('requiredPositional ');
      // } else if (f.isOptionalPositional) {
      //   _sink.write('optionalPositional ');
      // } else if (f.isRequiredNamed) {
      //   _sink.write('requiredNamed ');
      // } else if (f.isOptionalNamed) {
      //   _sink.write('optionalNamed ');
      // }

      if (f is ConstVariableElement) {
        _sink.write('default ');
      }

      // _sink.writeIf(f.isConst, 'const ');
      // _sink.writeIf(f.isCovariant, 'covariant ');
      // _sink.writeIf(f.isFinal, 'final ');

      if (f is FieldFormalParameterElement) {
        _sink.write('this.');
      } else if (f is SuperFormalParameterElement) {
        // _sink.writeIf(f.hasDefaultValue, 'hasDefaultValue ');
        _sink.write('super.');
      }

      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      // _writeType('type', f.type);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);
      // _writeTypeParameterElements(e.typeParameters);
      // _writeFragmentList('parameters', f, f.parameters2, _writeFormalParameterFragments);
      // _writeConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // _writeFieldFormalParameterField(e);
      // _writeSuperConstructorParameter(e);
    });
  }

  void _writeFragentBodyModifiers(ExecutableFragment f) {
    if (f.isAsynchronous) {
      expect(f.isSynchronous, isFalse);
      _sink.write(' async');
    }

    if (f.isSynchronous && f.isGenerator) {
      expect(f.isAsynchronous, isFalse);
      _sink.write(' sync');
    }

    _sink.writeIf(f.isGenerator, '*');

    if (f is ExecutableElementImpl && f.invokesSuperSelf) {
      _sink.write(' invokesSuperSelf');
    }
  }

  void _writeFragmentCodeRange(Fragment f) {
    if (configuration.withCodeRanges) {
      if (f is ElementImpl) {
        var e = f as ElementImpl;
        if (!e.isSynthetic) {
          _sink.writelnWithIndent('codeOffset: ${e.codeOffset}');
          _sink.writelnWithIndent('codeLength: ${e.codeLength}');
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
          expect(element.enclosingFragment, expectedEnclosingFragment);
          // TODO(brianwilkerson): Explicitly check the next/previous fragment
          //  attributes and stop writing them to the dump.
          write(element);
        }
      });
    }
  }

  void _writeFragmentName(Fragment f) {
    var name = _fragmentName(f);
    _sink.write(name);
    var offset = f.nameOffset;
    if (offset != null) {
      _sink.write(name.isNotEmpty ? ' @' : '@');
      _sink.write(offset);
    }
  }

  void _writeFragmentReference(String name, Fragment? f) {
    if (f == null) {
      return;
    }
    if (f is CompilationUnitElementImpl) {
      _sink.writeIndentedLine(() {
        _sink.write(name);
        _sink.write(': ');
        _elementPrinter.writeReference(f.reference!);
      });
      return;
    }
    Element2? element;
    if (f is ElementImpl) {
      element = f as ElementImpl;
    } else {
      element = f.element;
      if (element is! ElementImpl) {
        if (element is NotAugmentedInstanceElementImpl) {
          element = element.baseElement;
        } else if (element is MaybeAugmentedInstanceElementMixin) {
          element = element.declaration;
        }
      }
    }
    if (element is! ElementImpl) {
      _sink.writeIndentedLine(() {
        _sink.write(name);
        _sink.write(': <none>');
      });
      return;
    }
    if (element.reference case var reference?) {
      _sink.writeIndentedLine(() {
        _sink.write(name);
        _sink.write(': ');
        _elementPrinter.writeReference(reference);
      });
    }
  }

  void _writeGetterElement(GetterElement e) {
    var variable = e.variable3;
    if (variable != null) {
      var variableEnclosing = variable.enclosingElement2;
      if (variableEnclosing is LibraryElement2) {
        expect(variableEnclosing.topLevelVariables, contains(variable));
      } else if (variableEnclosing is InterfaceElement2) {
        // TODO(augmentations): Remove the invocations of `field.baseElement`.
        //  There shouldn't be any members in the list of fields.
        expect(variableEnclosing.fields2.map((field) => field.baseElement),
            contains(variable.baseElement));
      }
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

      _sink.write('get ');
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
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);

      expect(e.typeParameters2, isEmpty);
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      // _writeReturnType(e.returnType);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeMacroDiagnostics(e);
    });
  }

  void _writeGetterFragment(GetterFragment f) {
    var variable = f.variable3;
    if (variable != null) {
      var variableEnclosing = variable.enclosingFragment;
      if (variableEnclosing is LibraryFragment) {
        expect(variableEnclosing.topLevelVariables2, contains(variable));
      } else if (variableEnclosing is InterfaceFragment) {
        expect(variableEnclosing.fields2, contains(variable));
      }
    } else {
      expect(f.isAugmentation, isTrue);
      expect(f.previousFragment, isNull);
    }

    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    //   expect(f.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(f);
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(f.isAugmentation, 'augment ');
      // _sink.writeIf(e.isSynthetic, 'synthetic ');
      // _sink.writeIf(e.isStatic, 'static ');
      // _sink.writeIf(e.isAbstract, 'abstract ');
      // _sink.writeIf(e.isExternal, 'external ');

      _sink.write('get ');

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
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);

      // expect(f.typeParameters2, isEmpty);
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeReturnType(f.returnType);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      // _writeMacroDiagnostics(f);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeImportElementPrefix(PrefixFragmentImpl? fragment) {
    if (fragment != null) {
      _sink.writeIf(fragment.isDeferred, ' deferred');
      _sink.write(' as ');
      _sink.write(fragment.name);
      _sink.write(' @${fragment.nameOffset}');
    }
  }

  void _writeInstanceElement(InstanceElement2 e) {
    _sink.writeIndentedLine(() {
      switch (e) {
        case ClassElement2():
          _sink.writeIf(e.isAbstract, 'abstract ');
          // _sink.writeIf(e.isMacro, 'macro ');
          _sink.writeIf(e.isSealed, 'sealed ');
          _sink.writeIf(e.isBase, 'base ');
          _sink.writeIf(e.isInterface, 'interface ');
          _sink.writeIf(e.isFinal, 'final ');
          // _writeNotSimplyBounded(e);
          _sink.writeIf(e.isMixinClass, 'mixin ');
          _sink.write('class ');
          _sink.writeIf(e.isMixinApplication, 'alias ');
        case EnumElement2():
          // _writeNotSimplyBounded(e);
          _sink.write('enum ');
        case ExtensionElement2():
          _sink.write('extension ');
        case ExtensionTypeElement2():
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
        case MixinElement2():
          _sink.writeIf(e.isBase, 'base ');
          // _writeNotSimplyBounded(e);
          _sink.write('mixin ');
      }

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      // _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      _writeElementList(
          'typeParameters', e, e.typeParameters2, _writeTypeParameterElement);
      _writeMacroDiagnostics(e);

      if (e is InterfaceElement2) {
        var supertype = e.supertype;
        if (supertype != null &&
            (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
          _writeType('supertype', supertype);
        }
      }

      if (e is ExtensionTypeElement2) {
        // _elementPrinter.writeNamedElement('representation', e.representation2);
        // _elementPrinter.writeNamedElement(
        //     'primaryConstructor', e.primaryConstructor2);
        _elementPrinter.writeNamedType('typeErasure', e.typeErasure);
      }

      if (e is MixinElement2) {
        _elementPrinter.writeTypeList(
          'superclassConstraints',
          e.superclassConstraints,
        );
      }

      // TODO(brianwilkerson): Add a `writeTypeList2` that will use the new API
      //  version of the elements of type parameters.
      // _elementPrinter.writeTypeList('mixins', e.mixins);
      // _elementPrinter.writeTypeList('interfaces', e.interfaces);

      if (configuration.withAllSupertypes && e is InterfaceElement2) {
        var sorted = e.allSupertypes.sortedBy((t) => t.element.name);
        _elementPrinter.writeTypeList('allSupertypes', sorted);
      }

      _writeElementList('fields', e, e.fields2, _writeFieldElement);
      if (e is InterfaceElement2) {
        var constructors = e.constructors2;
        if (e is MixinElement2) {
          expect(constructors, isEmpty);
        } else if (configuration.withConstructors) {
          _writeElementList(
              'constructors', e, constructors, _writeConstructorElement);
        }
      }
      _writeElementList('getters', e, e.getters2, _writeGetterElement);
      _writeElementList('setters', e, e.setters2, _writeSetterElement);
      _writeElementList('methods', e, e.methods2, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeInstanceFragment(InstanceFragment f) {
    _sink.writeIndentedLine(() {
      switch (f) {
        case ClassFragment():
          // TODO(brianwilkerson): Figure out why we can't ask the fragments
          //  these questions.
          // _sink.writeIf(f.isAbstract, 'abstract ');
          // _sink.writeIf(f.isMacro, 'macro ');
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
      var name = f.element.name;
      if (name != null) {
        _sink.write(name);
      }
      var offset = f.nameOffset;
      if (offset != null) {
        _sink.write(' @');
        _sink.write(offset);
      }
    });
    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);

      _writeFragmentList(
          'typeParameters', f, f.typeParameters2, _writeTypeParameterFragment);
      _writeFragmentList('fields', f, f.fields2, _writeFieldFragment);
      if (f is InterfaceFragment) {
        var constructors = f.constructors2;
        if (f is MixinElement2) {
          expect(constructors, isEmpty);
        } else if (configuration.withConstructors) {
          _writeFragmentList(
              'constructors', f, constructors, _writeConstructorFragment);
        }
      }
      _writeFragmentList('getters', f, f.getters, _writeGetterFragment);
      _writeFragmentList('setters', f, f.setters, _writeSetterFragment);
      _writeFragmentList('methods', f, f.methods2, _writeMethodFragment);
    });
  }

  void _writeLibraryFragment(CompilationUnitElementImpl f) {
    var reference = f.reference!;
    _sink.writeIndentedLine(() {
      _elementPrinter.writeReference(reference);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);

      _writeMetadata(f.metadata);

      if (configuration.withImports) {
        var imports = f.libraryImports2.where((import) {
          return configuration.withSyntheticDartCoreImport ||
              !import.isSynthetic;
        }).toList();
        _writeList(
          'libraryImports',
          imports,
          _writeLibraryImport,
        );
      }
      _writeElementList('prefixes', f, f.prefixes, _writePrefixElement);
      // _writeList(
      //     'libraryExports', f.libraryExports, _writeLibraryExportElement);
      // _writeList('parts', f.parts, _writePartElement);

      _writeFragmentList('classes', f, f.classes2, _writeInstanceFragment);
      _writeFragmentList('enums', f, f.enums2, _writeInstanceFragment);
      _writeFragmentList(
          'extensions', f, f.extensions2, _writeInstanceFragment);
      _writeFragmentList(
        'extensionTypes',
        f,
        f.extensionTypes2,
        _writeInstanceFragment,
      );
      _writeFragmentList('mixins', f, f.mixins2, _writeInstanceFragment);
      _writeFragmentList(
          'typeAliases', f, f.typeAliases, _writeTypeAliasFragment);
      _writeFragmentList(
        'topLevelVariables',
        f,
        f.topLevelVariables2,
        _writeTopLevelVariableFragment,
      );
      _writeFragmentList(
        'getters',
        f,
        f.getters,
        _writeGetterFragment,
      );
      _writeFragmentList(
        'setters',
        f,
        f.setters,
        _writeSetterFragment,
      );
      _writeFragmentList(
          'functions', f, f.functions, _writeTopLevelFunctionFragment);
    });
  }

  void _writeLibraryImport(LibraryImport e) {
    (e as LibraryImportElementImpl).location;

    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
      _sink.writeIf(e.isSynthetic, ' synthetic');
      _writeImportElementPrefix(e.prefix2);
    });

    _sink.withIndent(() {
      _writeMetadata(e.metadata);
      // _writeNamespaceCombinators(e.combinators);
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

  void _writeMacroDiagnostics(Element2 e) {
    void writeTypeAnnotationLocation(TypeAnnotationLocation location) {
      switch (location) {
        case AliasedTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('AliasedTypeLocation');
        case ElementTypeLocation():
          _sink.writelnWithIndent('ElementTypeLocation');
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', location.element);
          });
        case ExtendsClauseTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ExtendsClauseTypeLocation');
        case FormalParameterTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('FormalParameterTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case ListIndexTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ListIndexTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case RecordNamedFieldTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('RecordNamedFieldTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case RecordPositionalFieldTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('RecordPositionalFieldTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case ReturnTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ReturnTypeLocation');
        case VariableTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('VariableTypeLocation');
        default:
          // TODO(scheglov): Handle this case.
          throw UnimplementedError('${location.runtimeType}');
      }
    }

    /// Returns `true` if patterns were printed.
    /// Returns `false` if no patterns configured.
    bool printMessagePatterns(String message) {
      var patterns = configuration.macroDiagnosticMessagePatterns;
      if (patterns == null) {
        return false;
      }

      _sink.writelnWithIndent('contains');
      _sink.withIndent(() {
        for (var pattern in patterns) {
          if (message.contains(pattern)) {
            _sink.writelnWithIndent(pattern);
          }
        }
      });
      return true;
    }

    void writeMessage(MacroDiagnosticMessage object) {
      // Write the message.
      if (!printMessagePatterns(object.message)) {
        var message = object.message;
        const stackTraceText = '#0';
        var stackTraceIndex = message.indexOf(stackTraceText);
        if (stackTraceIndex >= 0) {
          var end = stackTraceIndex + stackTraceText.length;
          var withoutStackTrace = message.substring(0, end);
          if (configuration.withMacroStackTraces) {
            _sink.writelnWithIndent('message:\n$message');
          } else {
            _sink.writelnWithIndent('message:\n$withoutStackTrace <cut>');
          }
        } else {
          _sink.writelnWithIndent('message: $message');
        }
      }
      // Write the target.
      var target = object.target;
      switch (target) {
        case ApplicationMacroDiagnosticTarget():
          _sink.writelnWithIndent('target: ApplicationMacroDiagnosticTarget');
          _sink.withIndent(() {
            _sink.writelnWithIndent(
              'annotationIndex: ${target.annotationIndex}',
            );
          });
        case ElementMacroDiagnosticTarget():
          _sink.writelnWithIndent('target: ElementMacroDiagnosticTarget');
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', target.element);
          });
        case ElementAnnotationMacroDiagnosticTarget():
          _sink.writelnWithIndent(
            'target: ElementAnnotationMacroDiagnosticTarget',
          );
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', target.element);
            _sink.writelnWithIndent(
              'annotationIndex: ${target.annotationIndex}',
            );
          });
        case TypeAnnotationMacroDiagnosticTarget():
          _sink.writelnWithIndent(
            'target: TypeAnnotationMacroDiagnosticTarget',
          );
          _sink.withIndent(() {
            writeTypeAnnotationLocation(target.location);
          });
      }
    }

    if (e case MacroTargetElement macroTarget) {
      _sink.writeElements(
        'macroDiagnostics',
        macroTarget.macroDiagnostics,
        (diagnostic) {
          switch (diagnostic) {
            case ArgumentMacroDiagnostic():
              _sink.writelnWithIndent('ArgumentMacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writelnWithIndent(
                  'argumentIndex: ${diagnostic.argumentIndex}',
                );
                _sink.writelnWithIndent('message: ${diagnostic.message}');
              });
            case DeclarationsIntrospectionCycleDiagnostic():
              _sink.writelnWithIndent(
                'DeclarationsIntrospectionCycleDiagnostic',
              );
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _elementPrinter.writeNamedElement(
                  'introspectedElement',
                  diagnostic.introspectedElement,
                );
                _sink.writeElements(
                  'components',
                  diagnostic.components,
                  (component) {
                    _sink.writelnWithIndent(
                      'DeclarationsIntrospectionCycleComponent',
                    );
                    _sink.withIndent(() {
                      _elementPrinter.writeNamedElement(
                        'element',
                        component.element,
                      );
                      _sink.writelnWithIndent(
                        'annotationIndex: ${component.annotationIndex}',
                      );
                      _elementPrinter.writeNamedElement(
                        'introspectedElement',
                        component.introspectedElement,
                      );
                    });
                  },
                );
              });
            case ExceptionMacroDiagnostic():
              _sink.writelnWithIndent('ExceptionMacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                if (!printMessagePatterns(diagnostic.message)) {
                  _sink.writelnWithIndent(
                    'message: ${diagnostic.message}',
                  );
                }
                if (configuration.withMacroStackTraces) {
                  _sink.writelnWithIndent(
                    'stackTrace:\n${diagnostic.stackTrace}',
                  );
                }
              });
            case InvalidMacroTargetDiagnostic():
              _sink.writelnWithIndent('InvalidMacroTargetDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writeElements(
                  'supportedKinds',
                  diagnostic.supportedKinds,
                  (kindName) {
                    _sink.writelnWithIndent(kindName);
                  },
                );
              });
            case MacroDiagnostic():
              _sink.writelnWithIndent('MacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent('message: MacroDiagnosticMessage');
                _sink.withIndent(() {
                  writeMessage(diagnostic.message);
                });
                _sink.writeElements(
                  'contextMessages',
                  diagnostic.contextMessages,
                  (message) {
                    _sink.writelnWithIndent('MacroDiagnosticMessage');
                    _sink.withIndent(() {
                      writeMessage(message);
                    });
                  },
                );
                _sink.writelnWithIndent(
                  'severity: ${diagnostic.severity.name}',
                );
                if (diagnostic.correctionMessage case var correctionMessage?) {
                  _sink.writelnWithIndent(
                    'correctionMessage: $correctionMessage',
                  );
                }
              });
            case NotAllowedDeclarationDiagnostic():
              _sink.writelnWithIndent('NotAllowedDeclarationDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writelnWithIndent(
                  'phase: ${diagnostic.phase.name}',
                );
                var nodeRangesStr = diagnostic.nodeRanges
                    .map((r) => '(${r.offset}, ${r.length})')
                    .join(' ');
                _sink.writelnWithIndent('nodeRanges: $nodeRangesStr');
                _sink.writeln('---');
                _sink.write(diagnostic.code);
                _sink.writeln('---');
              });
          }
        },
      );
    }
  }

  void _writeMetadata(List<ElementAnnotation> annotations) {
    if (configuration.withMetadata) {
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

  void _writeMethodElement(MethodElement2 e) {
    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isStatic, 'static ');
      _sink.writeIf(e.isAbstract, 'abstract ');
      _sink.writeIf(e.isExternal, 'external ');

      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      // _writeElementReference(e.enclosingElement2, label: 'enclosingElement2');
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeTypeInferenceError(e);

      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters2,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      // _writeReturnType(e.returnType);
      // _writeNonSyntheticElement(e);
      _writeMacroDiagnostics(e);
    });

    // if (e.isSynthetic && e.enclosingElement2 is EnumElementImpl) {
    //   expect(e.name, 'toString');
    //   expect(e.nonSynthetic2, same(e.enclosingElement2));
    // } else {
    //   _assertNonSyntheticElementSelf(e);
    // }
  }

  void _writeMethodFragment(MethodFragment f) {
    _sink.writeIndentedLine(() {
      _sink.writeIf(f.isAugmentation, 'augment ');
      // _sink.writeIf(f.isSynthetic, 'synthetic ');
      // _sink.writeIf(f.isStatic, 'static ');
      // _sink.writeIf(f.isAbstract, 'abstract ');
      // _sink.writeIf(f.isExternal, 'external ');

      _writeFragmentName(f);
      _writeFragentBodyModifiers(f);
    });

    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      _writeFragmentCodeRange(f);
      // _writeTypeInferenceError(f);

      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters2,
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
      // _writeMacroDiagnostics(f);
      // _writeAugmentationTarget(f);
      // _writeAugmentation(f);
    });
  }

  void _writePrefixElement(PrefixElementImpl2 e) {
    _sink.writeIndentedLine(() {
      _elementPrinter.writeElement2(e);
    });

    _sink.withIndent(() {
      _sink.writeIndentedLine(() {
        _sink.write('fragments: ');
        _sink.write(e.fragments.map((f) {
          expect(f.element, same(e));
          return '@${f.nameOffset}';
        }).join(' '));
      });
    });
  }

  void _writeSetterElement(SetterElement e) {
    var variable = e.variable3;
    if (variable != null) {
      var variableEnclosing = variable.enclosingElement2;
      if (variableEnclosing is LibraryElement2) {
        expect(variableEnclosing.topLevelVariables, contains(variable));
      } else if (variableEnclosing is InterfaceElement2) {
        // TODO(augmentations): Remove the invocations of `field.baseElement`.
        //  There shouldn't be any members in the list of fields.
        expect(variableEnclosing.fields2.map((field) => field.baseElement),
            contains(variable.baseElement));
      }
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

      _sink.write('set ');
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
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);

      expect(e.typeParameters2, isEmpty);
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      // _writeReturnType(e.returnType);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeMacroDiagnostics(e);
    });
  }

  void _writeSetterFragment(SetterFragment f) {
    var variable = f.variable3;
    if (variable != null) {
      var variableEnclosing = variable.enclosingFragment;
      if (variableEnclosing is LibraryFragment) {
        expect(variableEnclosing.topLevelVariables2, contains(variable));
      } else if (variableEnclosing is InterfaceFragment) {
        expect(variableEnclosing.fields2, contains(variable));
      }
    } else {
      expect(f.isAugmentation, isTrue);
      expect(f.previousFragment, isNull);
    }

    // if (f.isSynthetic) {
    //   expect(f.nameOffset, -1);
    // } else {
    //   expect(f.nameOffset, isPositive);
    //   _assertNonSyntheticElementSelf(f);
    // }

    _sink.writeIndentedLine(() {
      _sink.writeIf(f.isAugmentation, 'augment ');
      // _sink.writeIf(f.isSynthetic, 'synthetic ');
      // _sink.writeIf(f.isStatic, 'static ');
      // _sink.writeIf(f.isAbstract, 'abstract ');
      // _sink.writeIf(f.isExternal, 'external ');

      _sink.write('set ');
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
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);

      expect(f.typeParameters2, isEmpty);
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeReturnType(f.returnType);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      // _writeMacroDiagnostics(f);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
    });
  }

  void _writeSinceSdkVersion(Version? version) {
    if (version != null) {
      _sink.writelnWithIndent('sinceSdkVersion: $version');
    }
  }

  void _writeTopLevelFunctionElement(TopLevelFunctionElement e) {
    expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      _sink.writeIf(e.isExternal, 'external ');
      _writeElementName(e);
      // _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeCodeRange(e);
      _writeElementList(
        'typeParameters',
        e,
        e.typeParameters2,
        _writeTypeParameterElement,
      );
      _writeElementList(
        'formalParameters',
        e,
        e.formalParameters,
        _writeFormalParameterElement,
      );
      _writeType('returnType', e.returnType);
      _writeMacroDiagnostics(e);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTopLevelFunctionFragment(TopLevelFunctionFragment f) {
    // expect(e.isStatic, isTrue);

    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isExternal, 'external ');
      _writeFragmentName(f);
      // _writeBodyModifiers(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(e);
      _writeFragmentList(
        'typeParameters',
        f,
        f.typeParameters2,
        _writeTypeParameterFragment,
      );
      _writeFragmentList(
        'formalParameters',
        f,
        f.formalParameters,
        _writeFormalParameterFragment,
      );
      // _writeType('returnType', e.returnType);
      // _writeMacroDiagnostics(e);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    // _assertNonSyntheticElementSelf(f);
  }

  void _writeTopLevelVariableElement(TopLevelVariableElement2 e) {
    DartType type = e.type;
    expect(type, isNotNull);

    if (!e.isSynthetic) {
      expect(e.getter2, isNotNull);
      _assertNonSyntheticElementSelf(e);
    }

    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isSynthetic, 'synthetic ');
      _sink.writeIf(e.isLate, 'late ');
      _sink.writeIf(e.isFinal, 'final ');
      _sink.writeIf(e.isConst, 'const ');

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
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeTypeInferenceError(e);
      _writeType('type', e.type);
      // _writeShouldUseTypeForInitializerInference(e);
      // _writeConstantInitializer(e);
      // _writeNonSyntheticElement(e);
      // writeLinking();
      _writeMacroDiagnostics(e);
      _writeElementReference('getter', e.getter2);
      _writeElementReference('setter', e.setter2);
    });
  }

  void _writeTopLevelVariableFragment(TopLevelVariableFragment f) {
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
      _sink.writeIf(f.isAugmentation, 'augment ');
      _sink.writeIf(f.isSynthetic, 'synthetic ');
      // _sink.writeIf(f.isLate, 'late ');
      _sink.writeIf(f.isFinal, 'final ');
      _sink.writeIf(f.isConst, 'const ');
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
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(f);
      // _writeTypeInferenceError(f);
      // _writeType('type', f.type);
      // _writeShouldUseTypeForInitializerInference(f);
      // _writeConstantInitializer(f);
      // _writeNonSyntheticElement(f);
      // writeLinking();
      // _writeMacroDiagnostics(f);
      _writeFragmentReference('previousFragment', f.previousFragment);
      _writeFragmentReference('nextFragment', f.nextFragment);
      _writeFragmentReference('getter2', f.getter2);
      _writeFragmentReference('setter2', f.setter2);
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

  void _writeTypeAliasElement(TypeAliasElement2 e) {
    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeElementName(e);
    });

    _sink.withIndent(() {
      _writeFragmentReference('firstFragment', e.firstFragment);
      _writeDocumentation(e.documentationComment);
      _writeMetadata(e.metadata);
      _writeSinceSdkVersion(e.sinceSdkVersion);
      // _writeCodeRange(e);
      _writeElementList(
          'typeParameters', e, e.typeParameters2, _writeTypeParameterElement);

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

      _writeMacroDiagnostics(e);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeAliasFragment(TypeAliasFragment f) {
    _sink.writeIndentedLine(() {
      // _sink.writeIf(e.isAugmentation, 'augment ');
      // _sink.writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      // _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeFragmentReference('reference', f);
      _writeElementReference('element', f.element);
      _writeDocumentation(f.documentationComment);
      _writeMetadata(f.metadata);
      _writeSinceSdkVersion(f.sinceSdkVersion);
      // _writeCodeRange(e);
      _writeFragmentList(
          'typeParameters', f, f.typeParameters2, _writeTypeParameterFragment);

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

      // _writeMacroDiagnostics(e);
      // _writeAugmentationTarget(e);
      // _writeAugmentation(e);
    });

    // _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeParameterElement(TypeParameterElement2 e) {
    _sink.writeIndentedLine(() {
      // _sink.write('${e.variance.name} ');
      _writeElementName(e);
    });

    _sink.withIndent(() {
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

  void _writeTypeParameterFragment(TypeParameterFragment f) {
    _sink.writeIndentedLine(() {
      // _sink.write('${e.variance.name} ');
      _writeFragmentName(f);
    });

    _sink.withIndent(() {
      _writeElementReference('element', f.element);
      // _writeCodeRange(e);

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
}

/// Writes the canonical text presentation of elements.
class _ElementWriter extends _AbstractElementWriter {
  _ElementWriter({
    required super.sink,
    required super.elementPrinter,
    required super.configuration,
  });

  void writeLibraryElement(LibraryElementImpl e) {
    expect(e.enclosingElement3, isNull);

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

      // ignore:deprecated_member_use_from_same_package
      for (var part in e.parts) {
        if (part.uri case DirectiveUriWithUnitImpl uri) {
          expect(uri.unit.libraryOrAugmentationElement, same(e));
        }
      }

      // ignore:deprecated_member_use_from_same_package
      _writeElements('parts', e.parts, (part) {
        _sink.writelnWithIndent(_idMap[part]);
      });

      _writeElements('units', e.units, (unit) {
        _sink.writeIndent();
        _elementPrinter.writeElement(unit);
        _sink.withIndent(() {
          _writeUnitElement(unit);
        });
      });

      // All fragments have this library.
      for (var unit in e.units) {
        expect(unit.library, same(e));
      }

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
      _writeMacroDiagnostics(e);
    });
  }

  void _assertNonSyntheticElementSelf(Element element) {
    expect(element.isSynthetic, isFalse);
    expect(element.nonSynthetic, same(element));
  }

  void _validateAugmentedInstanceElement(InstanceElementImpl e) {
    InstanceElementImpl? current = e;
    while (current != null) {
      expect(current.augmented, same(e.augmented));
      expect(current.thisType, same(e.thisType));
      switch (e) {
        case ExtensionElementImpl():
          current as ExtensionElementImpl;
          expect(current.extendedType, same(e.extendedType));
        case ExtensionTypeElementImpl():
          current as ExtensionTypeElementImpl;
          expect(current.primaryConstructor, same(e.primaryConstructor));
          expect(current.representation, same(e.representation));
          expect(current.typeErasure, same(e.typeErasure));
      }
      current = current.augmentationTarget;
    }
  }

  void _writeAugmentation(ElementImpl e) {
    if (e case AugmentableElement(:var augmentation?)) {
      _elementPrinter.writeNamedElement('augmentation', augmentation);
    }
  }

  void _writeAugmentationTarget(ElementImpl e) {
    if (e is AugmentableElement && e.isAugmentation) {
      if (e.augmentationTarget case var target?) {
        _elementPrinter.writeNamedElement(
          'augmentationTarget',
          target,
        );
      } else if (e.augmentationTargetAny case var targetAny?) {
        _elementPrinter.writeNamedElement(
          'augmentationTargetAny',
          targetAny,
        );
      }
    }
  }

  void _writeAugmented(InstanceElementImpl e) {
    if (e.augmentationTarget != null) {
      return;
    }

    // No augmentation, not interesting.
    if (e.augmentation == null) {
      expect(e.augmented, TypeMatcher<NotAugmentedInstanceElementImpl>());
      if (!configuration.withAugmentedWithoutAugmentation) {
        return;
      }
    }

    var augmented = e.augmented;

    void writeFields() {
      var sorted = augmented.fields.sortedBy((e) => e.name);
      _elementPrinter.writeElementList('fields', sorted);
    }

    void writeConstructors() {
      if (!configuration.withConstructors) {
        return;
      }
      if (augmented is AugmentedInterfaceElementImpl) {
        var sorted = augmented.constructors.sortedBy((e) => e.name);
        expect(sorted, isNotEmpty);
        _elementPrinter.writeElementList('constructors', sorted);
      }
    }

    void writeAccessors() {
      var sorted = augmented.accessors.sortedBy((e) => e.name);
      _elementPrinter.writeElementList('accessors', sorted);
    }

    void writeMethods() {
      var sorted = augmented.methods.sortedBy((e) => e.name);
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
        case AugmentedEnumElement():
          _elementPrinter.writeTypeList('mixins', augmented.mixins);
          _elementPrinter.writeTypeList('interfaces', augmented.interfaces);
          writeFields();
          _elementPrinter.writeElementList(
            'constants',
            augmented.constants.sortedBy((e) => e.name),
          );
          writeConstructors();
          writeAccessors();
          writeMethods();
        case AugmentedExtensionElement():
          writeFields();
          writeAccessors();
          writeMethods();
        case AugmentedExtensionTypeElement():
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
        default:
          // TODO(scheglov): Add other types and properties
          throw UnimplementedError('${e.runtimeType}');
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

  void _writeCodeRange(Element e) {
    if (configuration.withCodeRanges && !e.isSynthetic) {
      if (e is MaybeAugmentedInstanceElementMixin) {
        e = e.declaration!;
      }
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
      _writeEnclosingElement(e);
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
        var enclosingElement = superConstructor.enclosingElement3;
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
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });

    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
      expect(e.nonSynthetic, same(e.enclosingElement3));
    } else {
      expect(e.nameOffset, isPositive);
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
    void Function(T) write,
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

  void _writeEnclosingElement(ElementImpl e) {
    _elementPrinter.writeNamedElement(
      'enclosingElement3',
      e.enclosingElement3,
    );
  }

  void _writeExportNamespace(LibraryElement e) {
    var map = e.exportNamespace.definedNames;
    var sortedEntries = map.entries.sortedBy((entry) => entry.key);
    for (var entry in sortedEntries) {
      _elementPrinter.writeNamedElement(entry.key, entry.value);
    }
  }

  void _writeExtensionElement(ExtensionElementImpl e) {
    _sink.writeIndentedLine(() {
      _sink.writeIf(e.isAugmentation, 'augment ');
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      if (e.augmentationTarget == null) {
        _writeType('extendedType', e.extendedType);
      }
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
      _writeElements('fields', e.fields, _writePropertyInducingElement);
      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeMethods(e.methods);
      _validateAugmentedInstanceElement(e);
      _writeAugmented(e);
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
      _writeEnclosingElement(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeReturnType(e.returnType);
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeImportElementPrefix(ImportElementPrefixImpl? prefix) {
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
          _writeNotSimplyBounded(e);
          _sink.writeIf(e.isMixinClass, 'mixin ');
          _sink.write('class ');
          _sink.writeIf(e.isMixinApplication, 'alias ');
        case EnumElementImpl():
          _writeNotSimplyBounded(e);
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
          _writeNotSimplyBounded(e);
        case MixinElementImpl():
          _sink.writeIf(e.isBase, 'base ');
          _writeNotSimplyBounded(e);
          _sink.write('mixin ');
      }

      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);

      if (!e.isAugmentation) {
        var supertype = e.supertype;
        if (supertype != null &&
            (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
          _writeType('supertype', supertype);
        }
      }

      if (e is ExtensionTypeElementImpl) {
        if (e.augmentationTarget == null) {
          _elementPrinter.writeNamedElement('representation', e.representation);
          _elementPrinter.writeNamedElement(
              'primaryConstructor', e.primaryConstructor);
          _elementPrinter.writeNamedType('typeErasure', e.typeErasure);
        }
      }

      if (e is MixinElementImpl) {
        _elementPrinter.writeTypeList(
          'superclassConstraints',
          e.superclassConstraints,
        );
      }

      _elementPrinter.writeTypeList('mixins', e.mixins);
      _elementPrinter.writeTypeList('interfaces', e.interfaces);

      if (configuration.withAllSupertypes) {
        var sorted = e.allSupertypes.sortedBy((t) => t.element.name);
        _elementPrinter.writeTypeList('allSupertypes', sorted);
      }

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

  void _writeLibraryExportElement(LibraryExportElementImpl e) {
    e.location;

    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeLibraryImportElement(LibraryImportElementImpl e) {
    e.location;

    _sink.writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
      _sink.writeIf(e.isSynthetic, ' synthetic');
      _writeImportElementPrefix(e.prefix);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });
  }

  void _writeLibraryOrAugmentationElement(LibraryOrAugmentationElementImpl e) {
    _writeReference(e);

    _writeDocumentation(e);
    _writeMetadata(e);
    _writeSinceSdkVersion(e);

    if (configuration.withImports) {
      // ignore:deprecated_member_use_from_same_package
      var imports = e.libraryImports.where((import) {
        return configuration.withSyntheticDartCoreImport || !import.isSynthetic;
      }).toList();
      _writeElements(
        'libraryImports',
        imports,
        _writeLibraryImportElement,
      );
      // ignore:deprecated_member_use_from_same_package
      _writeElements('prefixes', e.prefixes, _writePrefixElement);
    }

    _writeElements(
      'libraryExports',
      // ignore:deprecated_member_use_from_same_package
      e.libraryExports,
      _writeLibraryExportElement,
    );

    var definingUnit = e.definingCompilationUnit;
    expect(definingUnit.libraryOrAugmentationElement, same(e));
    if (configuration.filter(definingUnit)) {
      _elementPrinter.writeNamedElement('definingUnit', definingUnit);
    }
  }

  void _writeMacroDiagnostics(Element e) {
    void writeTypeAnnotationLocation(TypeAnnotationLocation location) {
      switch (location) {
        case AliasedTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('AliasedTypeLocation');
        case ElementTypeLocation():
          _sink.writelnWithIndent('ElementTypeLocation');
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', location.element);
          });
        case ExtendsClauseTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ExtendsClauseTypeLocation');
        case FormalParameterTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('FormalParameterTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case ListIndexTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ListIndexTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case RecordNamedFieldTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('RecordNamedFieldTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case RecordPositionalFieldTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('RecordPositionalFieldTypeLocation');
          _sink.withIndent(() {
            _sink.writelnWithIndent('index: ${location.index}');
          });
        case ReturnTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('ReturnTypeLocation');
        case VariableTypeLocation():
          writeTypeAnnotationLocation(location.parent);
          _sink.writelnWithIndent('VariableTypeLocation');
        default:
          // TODO(scheglov): Handle this case.
          throw UnimplementedError('${location.runtimeType}');
      }
    }

    /// Returns `true` if patterns were printed.
    /// Returns `false` if no patterns configured.
    bool printMessagePatterns(String message) {
      var patterns = configuration.macroDiagnosticMessagePatterns;
      if (patterns == null) {
        return false;
      }

      _sink.writelnWithIndent('contains');
      _sink.withIndent(() {
        for (var pattern in patterns) {
          if (message.contains(pattern)) {
            _sink.writelnWithIndent(pattern);
          }
        }
      });
      return true;
    }

    void writeMessage(MacroDiagnosticMessage object) {
      // Write the message.
      if (!printMessagePatterns(object.message)) {
        var message = object.message;
        const stackTraceText = '#0';
        var stackTraceIndex = message.indexOf(stackTraceText);
        if (stackTraceIndex >= 0) {
          var end = stackTraceIndex + stackTraceText.length;
          var withoutStackTrace = message.substring(0, end);
          if (configuration.withMacroStackTraces) {
            _sink.writelnWithIndent('message:\n$message');
          } else {
            _sink.writelnWithIndent('message:\n$withoutStackTrace <cut>');
          }
        } else {
          _sink.writelnWithIndent('message: $message');
        }
      }
      // Write the target.
      var target = object.target;
      switch (target) {
        case ApplicationMacroDiagnosticTarget():
          _sink.writelnWithIndent('target: ApplicationMacroDiagnosticTarget');
          _sink.withIndent(() {
            _sink.writelnWithIndent(
              'annotationIndex: ${target.annotationIndex}',
            );
          });
        case ElementMacroDiagnosticTarget():
          _sink.writelnWithIndent('target: ElementMacroDiagnosticTarget');
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', target.element);
          });
        case ElementAnnotationMacroDiagnosticTarget():
          _sink.writelnWithIndent(
            'target: ElementAnnotationMacroDiagnosticTarget',
          );
          _sink.withIndent(() {
            _elementPrinter.writeNamedElement('element', target.element);
            _sink.writelnWithIndent(
              'annotationIndex: ${target.annotationIndex}',
            );
          });
        case TypeAnnotationMacroDiagnosticTarget():
          _sink.writelnWithIndent(
            'target: TypeAnnotationMacroDiagnosticTarget',
          );
          _sink.withIndent(() {
            writeTypeAnnotationLocation(target.location);
          });
      }
    }

    if (e case MacroTargetElement macroTarget) {
      _sink.writeElements(
        'macroDiagnostics',
        macroTarget.macroDiagnostics,
        (diagnostic) {
          switch (diagnostic) {
            case ArgumentMacroDiagnostic():
              _sink.writelnWithIndent('ArgumentMacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writelnWithIndent(
                  'argumentIndex: ${diagnostic.argumentIndex}',
                );
                _sink.writelnWithIndent('message: ${diagnostic.message}');
              });
            case DeclarationsIntrospectionCycleDiagnostic():
              _sink.writelnWithIndent(
                'DeclarationsIntrospectionCycleDiagnostic',
              );
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _elementPrinter.writeNamedElement(
                  'introspectedElement',
                  diagnostic.introspectedElement,
                );
                _sink.writeElements(
                  'components',
                  diagnostic.components,
                  (component) {
                    _sink.writelnWithIndent(
                      'DeclarationsIntrospectionCycleComponent',
                    );
                    _sink.withIndent(() {
                      _elementPrinter.writeNamedElement(
                        'element',
                        component.element,
                      );
                      _sink.writelnWithIndent(
                        'annotationIndex: ${component.annotationIndex}',
                      );
                      _elementPrinter.writeNamedElement(
                        'introspectedElement',
                        component.introspectedElement,
                      );
                    });
                  },
                );
              });
            case ExceptionMacroDiagnostic():
              _sink.writelnWithIndent('ExceptionMacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                if (!printMessagePatterns(diagnostic.message)) {
                  _sink.writelnWithIndent(
                    'message: ${diagnostic.message}',
                  );
                }
                if (configuration.withMacroStackTraces) {
                  _sink.writelnWithIndent(
                    'stackTrace:\n${diagnostic.stackTrace}',
                  );
                }
              });
            case InvalidMacroTargetDiagnostic():
              _sink.writelnWithIndent('InvalidMacroTargetDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writeElements(
                  'supportedKinds',
                  diagnostic.supportedKinds,
                  (kindName) {
                    _sink.writelnWithIndent(kindName);
                  },
                );
              });
            case MacroDiagnostic():
              _sink.writelnWithIndent('MacroDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent('message: MacroDiagnosticMessage');
                _sink.withIndent(() {
                  writeMessage(diagnostic.message);
                });
                _sink.writeElements(
                  'contextMessages',
                  diagnostic.contextMessages,
                  (message) {
                    _sink.writelnWithIndent('MacroDiagnosticMessage');
                    _sink.withIndent(() {
                      writeMessage(message);
                    });
                  },
                );
                _sink.writelnWithIndent(
                  'severity: ${diagnostic.severity.name}',
                );
                if (diagnostic.correctionMessage case var correctionMessage?) {
                  _sink.writelnWithIndent(
                    'correctionMessage: $correctionMessage',
                  );
                }
              });
            case NotAllowedDeclarationDiagnostic():
              _sink.writelnWithIndent('NotAllowedDeclarationDiagnostic');
              _sink.withIndent(() {
                _sink.writelnWithIndent(
                  'annotationIndex: ${diagnostic.annotationIndex}',
                );
                _sink.writelnWithIndent(
                  'phase: ${diagnostic.phase.name}',
                );
                var nodeRangesStr = diagnostic.nodeRanges
                    .map((r) => '(${r.offset}, ${r.length})')
                    .join(' ');
                _sink.writelnWithIndent('nodeRanges: $nodeRangesStr');
                _sink.writeln('---');
                _sink.write(diagnostic.code);
                _sink.writeln('---');
              });
          }
        },
      );
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
      _writeEnclosingElement(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);

      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeReturnType(e.returnType);
      _writeNonSyntheticElement(e);
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });

    if (e.isSynthetic && e.enclosingElement3 is EnumElementImpl) {
      expect(e.name, 'toString');
      expect(e.nonSynthetic, same(e.enclosingElement3));
    } else {
      _assertNonSyntheticElementSelf(e);
    }
  }

  void _writeMethods(List<MethodElementImpl> elements) {
    _writeElements('methods', elements, _writeMethodElement);
  }

  void _writeName(Element e) {
    String name;
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
    _writeElements('combinators', elements, _writeNamespaceCombinator);
  }

  void _writeNonSyntheticElement(Element e) {
    if (configuration.withNonSynthetic) {
      _elementPrinter.writeNamedElement('nonSynthetic', e.nonSynthetic);
    }
  }

  void _writeNotSimplyBounded(InterfaceElementImpl e) {
    if (e.isAugmentation) {
      return;
    }
    _sink.writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
  }

  void _writeParameterElement(ParameterElement e) {
    e as ParameterElementImpl;

    if (e.isNamed && e.enclosingElement3 is ExecutableElement) {
      expect(e.reference, isNotNull);
    } else {
      expect(e.reference, isNull);
    }

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
        _sink.writeIf(e.hasDefaultValue, 'hasDefaultValue ');
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

  void _writePartElement(PartElementImpl e) {
    _sink.writelnWithIndent(_idMap[e]);

    _sink.withIndent(() {
      var uri = e.uri;
      _sink.writeIndentedLine(() {
        _sink.write('uri: ');
        _writeDirectiveUri(e.uri);
      });

      _writeEnclosingElement(e);
      _writeMetadata(e);

      if (uri is DirectiveUriWithUnitImpl) {
        _elementPrinter.writeNamedElement('unit', uri.unit);
      }
    });
  }

  void _writePrefixElement(PrefixElementImpl e) {
    _sink.writeIndentedLine(() {
      _writeName(e);
    });

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
    });
  }

  void _writePropertyAccessorElement(PropertyAccessorElement e) {
    e as PropertyAccessorElementImpl;

    var variable = e.variable2;
    if (variable != null) {
      var variableEnclosing = variable.enclosingElement3;
      if (variableEnclosing is CompilationUnitElement) {
        expect(variableEnclosing.topLevelVariables, contains(variable));
      } else if (variableEnclosing is InterfaceElement) {
        expect(variableEnclosing.fields, contains(variable));
      }
    } else {
      expect(e.isAugmentation, isTrue);
      expect(e.augmentationTarget, isNull);
    }

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      expect(e.nameOffset, isPositive);
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
        if (e.variable2 case var variable?) {
          _sink.writelnWithIndent('variable: ${_idMap[variable]}');
        } else {
          _sink.writelnWithIndent('variable: <null>');
        }
      }
    }

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeSinceSdkVersion(e);
      _writeCodeRange(e);

      expect(e.typeParameters, isEmpty);
      _writeParameterElements(e.parameters);
      _writeReturnType(e.returnType);
      _writeNonSyntheticElement(e);
      writeLinking();
      _writeMacroDiagnostics(e);
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

      expect(e.nameOffset, isPositive);
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

        var getter = e.getter;
        if (getter != null) {
          _sink.writelnWithIndent('getter: ${_idMap[getter]}');
        }

        var setter = e.setter;
        if (setter != null) {
          _sink.writelnWithIndent('setter: ${_idMap[setter]}');
        }
      }
    }

    _sink.withIndent(() {
      _writeReference(e);
      _writeEnclosingElement(e);
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
      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
    });
  }

  void _writeReturnType(DartType type) {
    if (configuration.withReturnType) {
      _writeType('returnType', type);
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
    var sinceSdkVersion = e.sinceSdkVersion;
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
      _sink.writeIf(e.isAugmentation, 'augment ');
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
          _writeReturnType(aliasedElement.returnType);
        });
      }

      _writeMacroDiagnostics(e);
      _writeAugmentationTarget(e);
      _writeAugmentation(e);
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
      _sink.write('${e.variance.name} ');
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
    _writeEnclosingElement(e);

    if (e.macroGenerated case var macroGenerated?) {
      _sink.writelnWithIndent('macroGeneratedCode');
      _sink.writeln('---');
      _sink.write(macroGenerated.code);
      _sink.writeln('---');
    }

    if (configuration.withImports) {
      var imports = e.libraryImports.where((import) {
        return configuration.withSyntheticDartCoreImport || !import.isSynthetic;
      }).toList();
      _writeElements('libraryImports', imports, _writeLibraryImportElement);
    }
    _writeElements(
      'libraryImportPrefixes',
      e.libraryImportPrefixes,
      _writePrefixElement,
    );
    _writeElements(
        'libraryExports', e.libraryExports, _writeLibraryExportElement);
    _writeElements('parts', e.parts, _writePartElement);

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
  final Map<Element, String> partMap = Map.identity();
  final Map<Element, String> setterMap = Map.identity();

  String operator [](Element element) {
    if (element is FieldElement) {
      return fieldMap[element] ??= 'field_${fieldMap.length}';
    } else if (element is TopLevelVariableElement) {
      return fieldMap[element] ??= 'variable_${fieldMap.length}';
    } else if (element is PropertyAccessorElement && element.isGetter) {
      return getterMap[element] ??= 'getter_${getterMap.length}';
    } else if (element is PartElementImpl) {
      return partMap[element] ??= 'part_${partMap.length}';
    } else if (element is PropertyAccessorElement && element.isSetter) {
      return setterMap[element] ??= 'setter_${setterMap.length}';
    } else {
      return '???';
    }
  }
}
