// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';

import 'tree_string_sink.dart';

class ElementPrinter {
  final TreeStringSink _sink;
  final ElementPrinterConfiguration _configuration;
  final String? _selfUriStr;

  ElementPrinter({
    required TreeStringSink sink,
    required ElementPrinterConfiguration configuration,
    required String? selfUriStr,
  })  : _sink = sink,
        _configuration = configuration,
        _selfUriStr = selfUriStr;

  void writeDirectiveUri(DirectiveUri? uri) {
    if (uri == null) {
      _sink.writeln('<null>');
    } else if (uri is DirectiveUriWithAugmentation) {
      _sink.writeln('DirectiveUriWithAugmentation');
      _sink.withIndent(() {
        final uriStr = _stringOfSource(uri.augmentation.source);
        _sink.writelnWithIndent('uri: $uriStr');
      });
    } else if (uri is DirectiveUriWithLibrary) {
      _sink.writeln('DirectiveUriWithLibrary');
      _sink.withIndent(() {
        final uriStr = _stringOfSource(uri.library.source);
        _sink.writelnWithIndent('uri: $uriStr');
      });
    } else if (uri is DirectiveUriWithUnit) {
      _sink.writeln('DirectiveUriWithUnit');
      _sink.withIndent(() {
        final uriStr = _stringOfSource(uri.unit.source);
        _sink.writelnWithIndent('uri: $uriStr');
      });
    } else if (uri is DirectiveUriWithSource) {
      _sink.writeln('DirectiveUriWithSource');
      _sink.withIndent(() {
        final uriStr = _stringOfSource(uri.source);
        _sink.writelnWithIndent('source: $uriStr');
      });
    } else if (uri is DirectiveUriWithRelativeUri) {
      _sink.writeln('DirectiveUriWithRelativeUri');
      _sink.withIndent(() {
        _sink.writelnWithIndent('relativeUri: ${uri.relativeUri}');
      });
    } else if (uri is DirectiveUriWithRelativeUriString) {
      _sink.writeln('DirectiveUriWithRelativeUriString');
      _sink.withIndent(() {
        _sink.writelnWithIndent('relativeUriString: ${uri.relativeUriString}');
      });
    } else {
      _sink.writeln('DirectiveUri');
    }
  }

  void writeElement(Element? element) {
    switch (element) {
      case null:
        _sink.writeln('<null>');
      case Member():
        _writeMember(element);
      case MultiplyDefinedElement():
        _sink.writeln('<null>');
      case AugmentationImportElement():
        _writeAugmentationImportElement(element);
      case LibraryExportElement():
        _writeLibraryExportElement(element);
      case LibraryImportElement():
        _writeLibraryImportElement(element);
      case PartElement():
        _writePartElement(element);
      default:
        final referenceStr = _elementToReferenceString(element);
        _sink.writeln(referenceStr);
    }
  }

  void writeElementList(String name, List<Element> elements) {
    _sink.writeElements(name, elements, (element) {
      _sink.writeIndent();
      writeElement(element);
    });
  }

  void writeNamedElement(String name, Element? element) {
    _sink.writeWithIndent('$name: ');
    writeElement(element);
  }

  void writeNamedType(String name, DartType? type) {
    _sink.writeWithIndent('$name: ');
    writeType(type);
  }

  void writeReference(Reference reference) {
    final str = _referenceToString(reference);
    _sink.write(str);
  }

  void writeType(DartType? type) {
    if (type != null) {
      var typeStr = _typeStr(type);
      _sink.writeln(typeStr);

      if (type is InterfaceType) {
        if (_configuration.withInterfaceTypeElements) {
          _sink.withIndent(() {
            writeNamedElement('element', type.element);
          });
        }
      }

      var alias = type.alias;
      if (alias != null) {
        _sink.withIndent(() {
          writeNamedElement('alias', alias.element);
          _sink.withIndent(() {
            writeTypeList('typeArguments', alias.typeArguments);
          });
        });
      }
    } else {
      _sink.writeln('null');
    }
  }

  void writeTypeList(String name, List<DartType>? types) {
    if (types != null && types.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (final type in types) {
          _sink.writeIndent();
          writeType(type);
        }
      });
    }
  }

  String _elementToReferenceString(Element element) {
    final enclosingElement = element.enclosingElement;
    final reference = (element as ElementImpl).reference;
    if (reference != null) {
      return _referenceToString(reference);
    } else if (element is ParameterElement &&
        enclosingElement is! GenericFunctionTypeElement) {
      // Positional parameters don't have actual references.
      // But we fabricate one to make the output better.
      final enclosingStr = enclosingElement != null
          ? _elementToReferenceString(enclosingElement)
          : 'root';
      return '$enclosingStr::@parameter::${element.name}';
    } else if (element is JoinPatternVariableElementImpl) {
      return [
        if (!element.isConsistent) 'notConsistent ',
        if (element.isFinal) 'final ',
        element.name,
        '[',
        element.variables.map(_elementToReferenceString).join(', '),
        ']',
      ].join('');
    } else {
      return '${element.name}@${element.nameOffset}';
    }
  }

  String _referenceToString(Reference reference) {
    var parent = reference.parent!;
    if (parent.parent == null) {
      var libraryUriStr = reference.name;
      if (libraryUriStr == _selfUriStr) {
        return 'self';
      }

      // TODO(scheglov): Make it precise again, after Windows.
      if (libraryUriStr.startsWith('file:')) {
        return libraryUriStr.substring(libraryUriStr.lastIndexOf('/') + 1);
      }

      return libraryUriStr;
    }

    // Ignore the unit, skip to the library.
    if (parent.name == '@unit') {
      return _referenceToString(parent.parent!);
    }

    var name = reference.name;
    if (name.isEmpty) {
      fail('Currently every reference must have a name');
    }
    return '${_referenceToString(parent)}::$name';
  }

  String _stringOfSource(Source source) {
    return '${source.uri}';
  }

  String _substitutionMapStr(Map<TypeParameterElement, DartType> map) {
    var entriesStr = map.entries.map((entry) {
      return '${entry.key.name}: ${_typeStr(entry.value)}';
    }).join(', ');
    return '{$entriesStr}';
  }

  String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: true);
  }

  void _writeAugmentationImportElement(AugmentationImportElement element) {
    _sink.writeln('AugmentationImportElement');
    _sink.withIndent(() {
      _sink.writeWithIndent('uri: ');
      writeDirectiveUri(element.uri);
    });
  }

  void _writeLibraryExportElement(LibraryExportElement element) {
    _sink.writeln('LibraryExportElement');
    _sink.withIndent(() {
      _sink.writeWithIndent('uri: ');
      writeDirectiveUri(element.uri);
    });
  }

  void _writeLibraryImportElement(LibraryImportElement element) {
    _sink.writeln('LibraryImportElement');
    _sink.withIndent(() {
      _sink.writeWithIndent('uri: ');
      writeDirectiveUri(element.uri);
    });
  }

  void _writeMember(Member element) {
    _sink.writeln(_nameOfMemberClass(element));
    _sink.withIndent(() {
      writeNamedElement('base', element.declaration);

      if (element.isLegacy) {
        _sink.writelnWithIndent('isLegacy: true');
      }

      void writeSubstitution(String name, MapSubstitution substitution) {
        var map = substitution.map;
        if (map.isNotEmpty) {
          var mapStr = _substitutionMapStr(map);
          _sink.writelnWithIndent('$name: $mapStr');
        }
      }

      writeSubstitution(
        'augmentationSubstitution',
        element.augmentationSubstitution,
      );

      writeSubstitution('substitution', element.substitution);

      if (_configuration.withRedirectedConstructors) {
        if (element is ConstructorMember) {
          final redirected = element.redirectedConstructor;
          writeNamedElement('redirectedConstructor', redirected);
        }
      }
    });
  }

  void _writePartElement(PartElement element) {
    writeDirectiveUri(element.uri);
  }

  static String _nameOfMemberClass(Member member) {
    return '${member.runtimeType}';
  }
}

class ElementPrinterConfiguration {
  bool withInterfaceTypeElements = false;
  bool withRedirectedConstructors = false;
}
