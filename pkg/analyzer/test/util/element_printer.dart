// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

class ElementPrinter {
  final TreeStringSink _sink;
  final ElementPrinterConfiguration _configuration;

  ElementPrinter({
    required TreeStringSink sink,
    required ElementPrinterConfiguration configuration,
  })  : _sink = sink,
        _configuration = configuration;

  void writeDirectiveUri(DirectiveUri? uri) {
    if (uri == null) {
      _sink.writeln('<null>');
    } else if (uri is DirectiveUriWithLibrary) {
      _sink.writeln('DirectiveUriWithLibrary');
      _sink.withIndent(() {
        var uriStr = _stringOfSource(uri.library.source);
        _sink.writelnWithIndent('uri: $uriStr');
      });
    } else if (uri is DirectiveUriWithUnit) {
      _sink.writeln('DirectiveUriWithUnit');
      _sink.withIndent(() {
        var uriStr = _stringOfSource(uri.libraryFragment.source);
        _sink.writelnWithIndent('uri: $uriStr');
      });
    } else if (uri is DirectiveUriWithSource) {
      _sink.writeln('DirectiveUriWithSource');
      _sink.withIndent(() {
        var uriStr = _stringOfSource(uri.source);
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
      case LibraryExportElement():
        _writeLibraryExportElement(element);
      case LibraryImportElement():
        _writeLibraryImportElement(element);
      case PartElement():
        _writePartElement(element);
      default:
        var referenceStr = _elementToReferenceString(element);
        _sink.writeln(referenceStr);
    }
  }

  void writeElement2(Element2? element) {
    switch (element) {
      case null:
        _sink.writeln('<null>');
      case TypeAliasElementImpl2 element:
        writelnReference(element.reference);
      case TopLevelVariableElementImpl2 element:
        writelnReference(element.reference);
      case TypeParameterElementImpl2():
        // TODO(scheglov): update when implemented
        _sink.writeln('<not-implemented>');
      case ConstructorElement2 element:
        var firstFragment = element.firstFragment as ElementImpl;
        var reference = firstFragment.reference;
        writeReference(reference!);
        _sink.writeln('#element');
      case DynamicElementImpl2():
        _sink.writeln('dynamic');
      case FormalParameterElementImpl():
        var firstFragment = element.firstFragment;
        var referenceStr = _elementToReferenceString(firstFragment as Element);
        _sink.write(referenceStr);
        _sink.writeln('#element');
      case TopLevelFunctionElementImpl element:
        writelnReference(element.reference);
      case FragmentedElementMixin element:
        var firstFragment = element.firstFragment as ElementImpl;
        var reference = firstFragment.reference!;
        writeReference(reference);
        _sink.writeln('#element');
      case GetterElement element:
        var firstFragment = element.firstFragment as ElementImpl;
        var reference = firstFragment.reference;
        writeReference(reference!);
        _sink.writeln('#element');
      case LabelElementImpl():
        _sink.write('${element.name3}@${element.firstFragment.nameOffset2}');
      case LabelElementImpl2():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name3}@${element.firstFragment.nameOffset2}');
      case LibraryElementImpl e:
        writelnReference(e.reference!);
      case LocalFunctionElementImpl():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name3}@${element.firstFragment.nameOffset2}');
      case LocalVariableElementImpl():
        _sink.writeln('${element.name3}@${element.firstFragment.nameOffset2}');
      case LocalVariableElementImpl2():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name3}@${element.firstFragment.nameOffset2}');
      case NeverElementImpl2():
        _sink.writeln('Never');
      case ClassElementImpl2 element:
        writeReference(element.reference);
        _sink.writeln();
      case EnumElementImpl2 element:
        writelnReference(element.reference);
      case ExtensionElementImpl2 element:
        writelnReference(element.reference);
      case ExtensionTypeElementImpl2 element:
        writelnReference(element.reference);
      case MixinElementImpl2 element:
        writelnReference(element.reference);
      case MethodElement2 element:
        var firstFragment = element.firstFragment as ElementImpl;
        var reference = firstFragment.reference;
        writeReference(reference!);
        _sink.writeln('#element');
      case MultiplyDefinedElementImpl2 multiElement:
        _sink.writeln('multiplyDefinedElement');
        _sink.withIndent(() {
          for (var element in multiElement.conflictingElements2) {
            _sink.writeIndent();
            writeElement2(element);
          }
        });
      case NeverElementImpl():
        _sink.writeln('Never@-1');
      case ParameterMember():
        var firstFragment = element.firstFragment;
        var referenceStr = _elementToReferenceString(firstFragment as Element);
        _sink.write(referenceStr);
        _sink.writeln('#element');
      case PrefixElementImpl2 element:
        writelnReference(element.reference);
      case SetterElement element:
        var firstFragment = element.firstFragment as ElementImpl;
        var reference = firstFragment.reference;
        writeReference(reference!);
        _sink.writeln('#element');
      default:
        throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  void writeElementList(String name, List<Element> elements) {
    _sink.writeElements(name, elements, (element) {
      _sink.writeIndent();
      writeElement(element);
    });
  }

  void writeElementList2(String name, List<Element2> elements) {
    _sink.writeElements(name, elements, (element) {
      _sink.writeIndent();
      writeElement2(element);
    });
  }

  void writelnFragmentReference(Fragment fragment) {
    var referenceStr = _fragmentToReferenceString(fragment);
    _sink.write(referenceStr);
    _sink.writeln();
  }

  void writelnReference(Reference reference) {
    writeReference(reference);
    _sink.writeln();
  }

  void writeNamedElement(String name, Element? element) {
    _sink.writeWithIndent('$name: ');
    writeElement(element);
  }

  void writeNamedElement2(String name, Element2? element) {
    _sink.writeIndent();
    _sink.write('$name: ');
    writeElement2(element);
  }

  void writeNamedFragment(String name, Fragment? fragment) {
    _sink.writeWithIndent('$name: ');
    if (fragment != null) {
      writelnFragmentReference(fragment);
    } else {
      _sink.writeln('<null>');
    }
  }

  void writeNamedType(String name, DartType? type) {
    _sink.writeWithIndent('$name: ');
    writeType(type);
  }

  void writeReference(Reference reference) {
    var str = _referenceToString(reference);
    _sink.write(str);
  }

  void writeType(DartType? type) {
    if (type != null) {
      var typeStr = _typeStr(type);
      _sink.writeln(typeStr);

      if (type is InterfaceType) {
        if (_configuration.withInterfaceTypeElements) {
          _sink.withIndent(() {
            writeNamedElement('element', type.element3.asElement);
            writeNamedElement2('element', type.element3);
          });
        }
      }

      var alias = type.alias;
      if (alias != null) {
        _sink.withIndent(() {
          writeNamedElement2('alias', alias.element2);
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
        for (var type in types) {
          _sink.writeIndent();
          writeType(type);
        }
      });
    }
  }

  String _elementToReferenceString(Element element) {
    // ignore:deprecated_member_use_from_same_package
    var enclosingElement = element.enclosingElement3;
    var reference = (element as ElementImpl).reference;
    if (reference != null) {
      return _referenceToString(reference);
    } else if (element is ParameterElement &&
        enclosingElement is! GenericFunctionTypeElement) {
      // Positional parameters don't have actual references.
      // But we fabricate one to make the output better.
      var enclosingStr = enclosingElement != null
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
      ].join();
    } else {
      return '${element.name}@${element.nameOffset}';
    }
  }

  String _fragmentToReferenceString(Fragment element) {
    var enclosingFragment = element.enclosingFragment;
    var reference = (element as ElementImpl).reference;
    if (reference != null) {
      return _referenceToString(reference);
    } else if (element is FormalParameterFragment &&
        enclosingFragment is! GenericFunctionTypeFragment) {
      // Positional parameters don't have actual references.
      // But we fabricate one to make the output better.
      var enclosingStr = enclosingFragment != null
          ? _fragmentToReferenceString(enclosingFragment)
          : 'root';
      return '$enclosingStr::@formalParameter::${element.name2}';
    } else if (element is JoinPatternVariableElementImpl) {
      return [
        if (!element.isConsistent) 'notConsistent ',
        if (element.isFinal) 'final ',
        element.name,
        '[',
        element.variables.map(_elementToReferenceString).join(', '),
        ']',
      ].join();
    } else {
      return '${element.name2}@${element.nameOffset2}';
    }
  }

  String _referenceToString(Reference reference) {
    var parent = reference.parent!;
    if (parent.parent == null) {
      var libraryUriStr = reference.name;

      // Very often we have just the test library.
      if (libraryUriStr == 'package:test/test.dart') {
        return '<testLibrary>';
      }

      return _toPosixUriStr(libraryUriStr);
    }

    // Compress often used library fragments.
    if (parent.name == '@fragment') {
      var libraryRef = parent.parent!;
      if (reference.name == libraryRef.name) {
        if (libraryRef.name == 'package:test/test.dart') {
          return '<testLibraryFragment>';
        }
        return '${_referenceToString(libraryRef)}::<fragment>';
      }
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

  String _substitutionMapStr(Map<TypeParameterElement2, DartType> map) {
    var entriesStr = map.entries.map((entry) {
      return '${entry.key.name3}: ${_typeStr(entry.value)}';
    }).join(', ');
    return '{$entriesStr}';
  }

  String _toPosixUriStr(String uriStr) {
    // TODO(scheglov): Make it precise again, after Windows.
    if (uriStr.startsWith('file:')) {
      return uriStr.substring(uriStr.lastIndexOf('/') + 1);
    }
    return uriStr;
  }

  String _typeStr(DartType type) {
    return type.getDisplayString();
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

      void writeSubstitution(String name, MapSubstitution substitution) {
        var map = substitution.map;
        if (map.isNotEmpty) {
          var mapStr = _substitutionMapStr(map);
          _sink.writelnWithIndent('$name: $mapStr');
        }
      }

      writeSubstitution('substitution', element.substitution);

      if (element is ConstructorMember) {
        if (_configuration.withRedirectedConstructors) {
          writeNamedElement(
            'redirectedConstructor',
            element.redirectedConstructor,
          );
        }
        if (_configuration.withSuperConstructors) {
          writeNamedElement(
            'superConstructor',
            element.superConstructor,
          );
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
  bool withSuperConstructors = false;
}
