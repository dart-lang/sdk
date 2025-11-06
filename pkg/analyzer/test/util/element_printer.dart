// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

class ElementPrinter {
  final TreeStringSink _sink;
  final ElementPrinterConfiguration _configuration;
  final IdMap idMap = IdMap();

  ElementPrinter({
    required TreeStringSink sink,
    required ElementPrinterConfiguration configuration,
  }) : _sink = sink,
       _configuration = configuration;

  void writeDirectiveUri(DirectiveUri? uri) {
    if (uri == null) {
      _sink.writeln('<null>');
    } else if (uri is DirectiveUriWithLibrary) {
      _sink.writeln('DirectiveUriWithLibrary');
      _sink.withIndent(() {
        var uriStr = uri.library.uri;
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

  void writeElement2(Element? element) {
    switch (element) {
      case null:
        _sink.writeln('<null>');
      case GetterElementImpl element:
        writelnReference(element.reference);
      case SetterElementImpl element:
        writelnReference(element.reference);
      case FormalParameterElementImpl element:
        var refStr = _elementToReferenceString(element);
        _sink.writeln(refStr);
      case TypeParameterElementImpl element:
        var idStr = idMap[element];
        _sink.writeln('$idStr ${element.name ?? '<null-name>'}');
      case SubstitutedElementImpl member:
        _writeMember(member);
      case TypeAliasElementImpl element:
        writelnReference(element.reference);
      case TopLevelVariableElementImpl element:
        writelnReference(element.reference);
      case ConstructorElementImpl element:
        writelnReference(element.reference);
      case DynamicElementImpl():
        _sink.writeln('dynamic');
      case FieldElementImpl element:
        writelnReference(element.reference);
      case TopLevelFunctionElementImpl element:
        writelnReference(element.reference);
      case MethodElementImpl element:
        writelnReference(element.reference);
      case LabelFragmentImpl():
        _sink.writeln('${element.name}@${element.firstFragment.nameOffset}');
      case LabelElementImpl():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name}@${element.firstFragment.nameOffset}');
      case LibraryElementImpl e:
        writelnReference(e.reference!);
      case LocalFunctionElementImpl():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name}@${element.firstFragment.nameOffset}');
      case LocalVariableFragmentImpl():
        _sink.writeln('${element.name}@${element.firstFragment.nameOffset}');
      case LocalVariableElementImpl():
        // TODO(scheglov): nameOffset2 can be `null`
        _sink.writeln('${element.name}@${element.firstFragment.nameOffset}');
      case NeverElementImpl():
        _sink.writeln('Never');
      case ClassElementImpl element:
        writeReference(element.reference);
        _sink.writeln();
      case EnumElementImpl element:
        writelnReference(element.reference);
      case ExtensionElementImpl element:
        writelnReference(element.reference);
      case ExtensionTypeElementImpl element:
        writelnReference(element.reference);
      case MixinElementImpl element:
        writelnReference(element.reference);
      case MultiplyDefinedElementImpl multiElement:
        _sink.writeln('multiplyDefinedElement');
        _sink.withIndent(() {
          for (var element in multiElement.conflictingElements) {
            _sink.writeIndent();
            writeElement2(element);
          }
        });
      case NeverFragmentImpl():
        _sink.writeln('Never@-1');
      case PrefixElementImpl element:
        writelnReference(element.reference);
      default:
        throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  void writeElementList2(String name, List<Element> elements) {
    _sink.writeElements(name, elements, (element) {
      _sink.writeIndent();
      writeElement2(element);
    });
  }

  void writeFragmentReference(Fragment fragment) {
    var referenceStr = _fragmentToReferenceString(fragment);
    _sink.write(referenceStr);
  }

  void writeLibraryExport(String name, LibraryExport? element) {
    if (element != null) {
      _sink.writelnWithIndent('$name: LibraryExport');
      _sink.withIndent(() {
        _sink.writeWithIndent('uri: ');
        writeDirectiveUri(element.uri);
      });
    } else {
      _sink.writelnWithIndent('$name: <null>');
    }
  }

  void writeLibraryImport(String name, LibraryImport? element) {
    if (element != null) {
      _sink.writelnWithIndent('$name: LibraryImport');
      _sink.withIndent(() {
        _sink.writeWithIndent('uri: ');
        writeDirectiveUri(element.uri);
      });
    } else {
      _sink.writelnWithIndent('$name: <null>');
    }
  }

  void writelnFragmentReference(Fragment fragment) {
    writeFragmentReference(fragment);
    _sink.writeln();
  }

  void writelnReference(Reference reference) {
    writeReference(reference);
    _sink.writeln();
  }

  void writeNamedElement2(String name, Element? element) {
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

  void writePartInclude(String name, PartInclude? element) {
    if (element != null) {
      _sink.writelnWithIndent('$name: PartInclude');
      _sink.withIndent(() {
        _sink.writeWithIndent('uri: ');
        writeDirectiveUri(element.uri);
      });
    } else {
      _sink.writelnWithIndent('$name: <null>');
    }
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
            writeNamedElement2('element', type.element);
          });
        }
      }

      var alias = type.alias;
      if (alias != null) {
        _sink.withIndent(() {
          writeNamedElement2('alias', alias.element);
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
    element as ElementImpl;
    var enclosingElement = element.enclosingElement as ElementImpl?;

    // Positional parameters don't have actual references.
    // But we fabricate one to make the output better.
    if (element is FormalParameterElementImpl) {
      var nameStr = element.name ?? '<null-name>';
      if (enclosingElement is ConstructorElementImpl ||
          enclosingElement is MethodElementImpl ||
          enclosingElement is SetterElementImpl ||
          enclosingElement is TopLevelFunctionElementImpl) {
        var enclosingStr = _elementToReferenceString(enclosingElement!);
        return '$enclosingStr::@formalParameter::$nameStr';
      } else {
        return '$nameStr@${element.firstFragment.nameOffset}';
      }
    }

    var reference = element.reference;
    if (reference != null) {
      return _referenceToString(reference);
    } else if (element is JoinPatternVariableElementImpl) {
      return [
        if (!element.isConsistent) 'notConsistent ',
        if (element.isFinal) 'final ',
        element.name ?? '',
        '[',
        element.variables.map(_elementToReferenceString).join(', '),
        ']',
      ].join();
    } else {
      return '${element.name ?? ''}@${element.firstFragment.nameOffset}';
    }
  }

  String _fragmentToReferenceString(Fragment fragment) {
    if (fragment is LibraryFragmentImpl) {
      return idMap[fragment];
    }

    var libraryFragmentUri = fragment.libraryFragment?.source.uri;
    if (libraryFragmentUri != null) {
      var uriStr = _toPosixUriStr('$libraryFragmentUri');
      if (uriStr == 'package:test/test.dart') {
        uriStr = '<testLibraryFragment>';
      }
      return '$uriStr ${fragment.name}@${fragment.nameOffset}';
    }

    var enclosingFragment = fragment.enclosingFragment;
    if (fragment is FormalParameterFragment &&
        enclosingFragment is! GenericFunctionTypeFragment) {
      // Positional parameters don't have actual references.
      // But we fabricate one to make the output better.
      var enclosingStr = enclosingFragment != null
          ? _fragmentToReferenceString(enclosingFragment)
          : 'root';
      return '$enclosingStr::@formalParameter::${fragment.name}';
    } else if (fragment is JoinPatternVariableFragmentImpl) {
      return [
        if (!fragment.element.isConsistent) 'notConsistent ',
        if (fragment.isFinal) 'final ',
        fragment.name ?? '',
        '[',
        fragment.variables.map(_fragmentToReferenceString).join(', '),
        ']',
      ].join();
    } else {
      return '${fragment.name}@${fragment.nameOffset}';
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

  String _substitutionMapStr(Map<TypeParameterElement, DartType> map) {
    var entriesStr = map.entries
        .map((entry) {
          return '${entry.key.name}: ${_typeStr(entry.value)}';
        })
        .join(', ');
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

  void _writeMember(SubstitutedElementImpl element) {
    _sink.writeln(_nameOfMemberClass(element));
    _sink.withIndent(() {
      writeNamedElement2('baseElement', element.baseElement);

      void writeSubstitution(String name, MapSubstitution substitution) {
        var map = substitution.map;
        if (map.isNotEmpty) {
          var mapStr = _substitutionMapStr(map);
          _sink.writelnWithIndent('$name: $mapStr');
        }
      }

      writeSubstitution('substitution', element.substitution);

      if (element is SubstitutedConstructorElementImpl) {
        if (_configuration.withRedirectedConstructors) {
          writeNamedElement2(
            'redirectedConstructor',
            element.redirectedConstructor,
          );
        }
        if (_configuration.withSuperConstructors) {
          writeNamedElement2('superConstructor', element.superConstructor);
        }
      }
    });
  }

  static String _nameOfMemberClass(SubstitutedElementImpl member) {
    // TODO(scheglov): remove during updating expectations
    switch (member) {
      case SubstitutedConstructorElementImpl():
        return 'ConstructorMember';
      case SubstitutedFieldElementImpl():
        return 'FieldMember';
      case SubstitutedFieldFormalParameterElementImpl():
        return 'FieldFormalParameterMember';
      case SubstitutedSuperFormalParameterElementImpl():
        return 'SuperFormalParameterMember';
      case SubstitutedFormalParameterElementImpl():
        return 'ParameterMember';
      case SubstitutedGetterElementImpl():
        return 'GetterMember';
      case SubstitutedMethodElementImpl():
        return 'MethodMember';
      case SubstitutedSetterElementImpl():
        return 'SetterMember';
      default:
        throw UnimplementedError('(${member.runtimeType}) $member');
    }
    // return '${member.runtimeType}';
  }
}

class ElementPrinterConfiguration {
  bool withInterfaceTypeElements = false;
  bool withRedirectedConstructors = false;
  bool withSuperConstructors = false;
}

class IdMap {
  final Map<Expression, String> expressionMap = Map.identity();
  final Map<FragmentImpl, String> fragmentMap = Map.identity();
  final Map<ElementImpl, String> elementMap = Map.identity();
  final Map<FragmentImpl, String> fieldMap = Map.identity();
  final Map<FormalParameterFragmentImpl, String> formalParameterMap =
      Map.identity();
  final Map<TopLevelFunctionFragmentImpl, String> topLevelFunctionMap =
      Map.identity();
  final Map<FragmentImpl, String> getterMap = Map.identity();
  final Map<PartIncludeImpl, String> partMap = Map.identity();
  final Map<FragmentImpl, String> setterMap = Map.identity();
  final Map<TypeAliasFragmentImpl, String> typeAliasMap = Map.identity();

  String operator [](Object object) {
    if (object is Expression) {
      return expressionMap[object] ??= 'expression_${expressionMap.length}';
    } else if (object is FragmentImpl) {
      return fragmentMap[object] ??= '#F${fragmentMap.length}';
    } else if (object is ElementImpl) {
      return elementMap[object] ??= '#E${elementMap.length}';
    } else if (object is FieldFragmentImpl) {
      return fieldMap[object] ??= 'field_${fieldMap.length}';
    } else if (object is TopLevelFunctionFragmentImpl) {
      return topLevelFunctionMap[object] ??=
          'topLevelFunction_${topLevelFunctionMap.length}';
    } else if (object is TopLevelVariableFragmentImpl) {
      return fieldMap[object] ??= 'variable_${fieldMap.length}';
    } else if (object is GetterFragmentImpl) {
      return getterMap[object] ??= 'getter_${getterMap.length}';
    } else if (object is PartIncludeImpl) {
      return partMap[object] ??= 'part_${partMap.length}';
    } else if (object is SetterFragmentImpl) {
      return setterMap[object] ??= 'setter_${setterMap.length}';
    } else if (object is TypeAliasFragmentImpl) {
      return typeAliasMap[object] ??= 'typeAlias_${typeAliasMap.length}';
    } else {
      return '???';
    }
  }

  String? existingExpressionId(Expression object) {
    return expressionMap[object];
  }
}
