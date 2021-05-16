// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:collection/collection.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var byteSink = ByteSink();
  var sink = BufferedSink(byteSink);
  _InformativeDataWriter(sink).write(unit);
  return sink.flushAndTake();
}

class InformativeDataApplier {
  final LinkedElementFactory _elementFactory;
  final Map<Uri, Uint8List> _unitsInformativeBytes2;

  InformativeDataApplier(
    this._elementFactory,
    this._unitsInformativeBytes2,
  );

  void applyTo(LibraryElementImpl libraryElement) {
    if (_elementFactory.isApplyingInformativeData) {
      throw StateError('Unexpected recursion.');
    }
    _elementFactory.isApplyingInformativeData = true;

    var unitElements = libraryElement.units;
    for (var i = 0; i < unitElements.length; i++) {
      var unitElement = unitElements[i] as CompilationUnitElementImpl;
      var unitUri = unitElement.source.uri;
      var unitInfoBytes = _unitsInformativeBytes2[unitUri];
      if (unitInfoBytes != null) {
        var unitReader = SummaryDataReader(unitInfoBytes);
        var unitInfo = _InfoUnit(unitReader);

        if (i == 0) {
          _applyToLibrary(libraryElement, unitInfo);
        }

        unitElement.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
        unitElement.lineInfo = LineInfo(unitInfo.lineStarts);

        _applyToAccessors(unitElement.accessors, unitInfo.accessors);

        _forEach2(
          unitElement.types
              .where((element) => !element.isMixinApplication)
              .toList(),
          unitInfo.classDeclarations,
          _applyToClassDeclaration,
        );

        _forEach2(
          unitElement.types
              .where((element) => element.isMixinApplication)
              .toList(),
          unitInfo.classTypeAliases,
          _applyToClassTypeAlias,
        );

        _forEach2(unitElement.enums, unitInfo.enums, _applyToEnumDeclaration);

        _forEach2(unitElement.extensions, unitInfo.extensions,
            _applyToExtensionDeclaration);

        _forEach2(unitElement.functions, unitInfo.functions,
            _applyToFunctionDeclaration);

        _forEach2(unitElement.mixins, unitInfo.mixinDeclarations,
            _applyToMixinDeclaration);

        _forEach2(unitElement.topLevelVariables, unitInfo.topLevelVariable,
            _applyToTopLevelVariable);

        _forEach2(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.functionTypeAliases,
          _applyToFunctionTypeAlias,
        );

        _forEach2(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => !e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.genericTypeAliases,
          _applyToGenericTypeAlias,
        );
      }
    }

    _elementFactory.isApplyingInformativeData = false;
  }

  void _applyToAccessors(
    List<PropertyAccessorElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    _forEach2<PropertyAccessorElement, _InfoMethodDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as PropertyAccessorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );
      },
    );
  }

  void _applyToClassDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var linkedData = element.linkedData as ClassElementLinkedData;
    linkedData.applyInformativeDataToMembers = () {
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.accessors, info.accessors);
      _applyToMethods(element.methods, info.methods);
    };
  }

  void _applyToClassTypeAlias(
    ClassElement element,
    _InfoClassTypeAlias info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
  }

  void _applyToCombinators(
    List<NamespaceCombinator> elementList,
    List<_InfoCombinator> infoList,
  ) {
    _forEach2<NamespaceCombinator, _InfoCombinator>(
      elementList,
      infoList,
      (element, info) {
        if (element is ShowElementCombinatorImpl) {
          element.offset = info.offset;
          element.end = info.end;
        }
      },
    );
  }

  void _applyToConstructors(
    List<ConstructorElement> elementList,
    List<_InfoConstructorDeclaration> infoList,
  ) {
    _forEach2<ConstructorElement, _InfoConstructorDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as ConstructorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.periodOffset = info.periodOffset;
        element.nameOffset = info.nameOffset;
        element.nameEnd = info.nameEnd;
        element.documentationComment = info.documentationComment;
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );
      },
    );
  }

  void _applyToEnumDeclaration(
    ClassElement element,
    _InfoEnumDeclaration info,
  ) {
    element as EnumElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    _forEach2<FieldElement, _InfoEnumConstantDeclaration>(
      element.constants_unresolved,
      info.constants,
      (element, info) {
        element as FieldElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
      },
    );
  }

  void _applyToExtensionDeclaration(
    ExtensionElement element,
    _InfoClassDeclaration info,
  ) {
    element as ExtensionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);
  }

  void _applyToFields(
    List<FieldElement> elementList,
    List<_InfoFieldDeclaration> infoList,
  ) {
    _forEach2<FieldElement, _InfoFieldDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as FieldElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        (element.getter as PropertyAccessorElementImpl?)?.nameOffset =
            info.nameOffset;
        (element.setter as PropertyAccessorElementImpl?)?.nameOffset =
            info.nameOffset;
        element.documentationComment = info.documentationComment;
      },
    );
  }

  void _applyToFormalParameters(
    List<ParameterElement> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    _forEach2<ParameterElement, _InfoFormalParameter>(
      parameters,
      infoList,
      (element, info) {
        element as ParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        _applyToTypeParameters(element.typeParameters, info.typeParameters);
        _applyToFormalParameters(element.parameters, info.parameters);
      },
    );
  }

  void _applyToFunctionDeclaration(
    FunctionElement element,
    _InfoFunctionDeclaration info,
  ) {
    element as FunctionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFormalParameters(
      element.parameters_unresolved,
      info.parameters,
    );
  }

  void _applyToFunctionTypeAlias(
    TypeAliasElement element,
    _InfoFunctionTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
  }

  void _applyToGenericTypeAlias(
    TypeAliasElement element,
    _InfoGenericTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
  }

  void _applyToLibrary(LibraryElementImpl element, _InfoUnit info) {
    element.nameOffset = info.libraryName.offset;
    element.nameLength = info.libraryName.length;

    if (info.docComment.isNotEmpty) {
      element.documentationComment = info.docComment;
    }

    _forEach2<ImportElement, _InfoImport>(
      element.imports_unresolved,
      info.imports,
      (element, info) {
        element as ImportElementImpl;
        element.nameOffset = info.nameOffset;
        element.prefixOffset = info.prefixOffset;

        var prefix = element.prefix;
        if (prefix is PrefixElementImpl) {
          prefix.nameOffset = info.prefixOffset;
        }

        _applyToCombinators(element.combinators, info.combinators);
      },
    );

    _forEach2<ExportElement, _InfoExport>(
      element.exports_unresolved,
      info.exports,
      (element, info) {
        element as ExportElementImpl;
        element.nameOffset = info.nameOffset;
        _applyToCombinators(element.combinators, info.combinators);
      },
    );
  }

  void _applyToMethods(
    List<MethodElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    _forEach2<MethodElement, _InfoMethodDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as MethodElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToTypeParameters(
          element.typeParameters_unresolved,
          info.typeParameters,
        );
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );
      },
    );
  }

  void _applyToMixinDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as MixinElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToConstructors(element.constructors, info.constructors);
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);
  }

  void _applyToTopLevelVariable(
    TopLevelVariableElement element,
    _InfoTopLevelVariable info,
  ) {
    element as TopLevelVariableElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    (element.getter as PropertyAccessorElementImpl?)?.nameOffset =
        info.nameOffset;
    (element.setter as PropertyAccessorElementImpl?)?.nameOffset =
        info.nameOffset;
    element.documentationComment = info.documentationComment;
  }

  void _applyToTypeParameters(
    List<TypeParameterElement> elementList,
    List<_InfoTypeParameter> infoList,
  ) {
    _forEach2<TypeParameterElement, _InfoTypeParameter>(
      elementList,
      infoList,
      (element, info) {
        element as TypeParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
      },
    );
  }

  static void _forEach2<T1, T2>(
    List<T1> list1,
    List<T2> list2,
    void Function(T1, T2) f,
  ) {
    var i1 = list1.iterator;
    var i2 = list2.iterator;
    while (i1.moveNext() && i2.moveNext()) {
      f(i1.current, i2.current);
    }
  }
}

class _InfoClassDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoConstructorDeclaration> constructors;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoMethodDeclaration> methods;

  factory _InfoClassDeclaration(SummaryDataReader reader,
      {int nameOffsetDelta = 0}) {
    return _InfoClassDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - nameOffsetDelta,
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      constructors: reader.readTypedList(
        () => _InfoConstructorDeclaration(reader),
      ),
      fields: reader.readTypedList(
        () => _InfoFieldDeclaration(reader),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      methods: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
    );
  }

  _InfoClassDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.constructors,
    required this.fields,
    required this.accessors,
    required this.methods,
  });
}

class _InfoClassTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;

  factory _InfoClassTypeAlias(SummaryDataReader reader) {
    return _InfoClassTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
    );
  }

  _InfoClassTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
  });
}

class _InfoCombinator {
  final int offset;
  final int end;

  factory _InfoCombinator(SummaryDataReader reader) {
    return _InfoCombinator._(
      offset: reader.readUInt30(),
      end: reader.readUInt30(),
    );
  }

  _InfoCombinator._({
    required this.offset,
    required this.end,
  });
}

class _InfoConstructorDeclaration {
  final int codeOffset;
  final int codeLength;
  final int? periodOffset;
  final int nameOffset;
  final int nameEnd;
  final String? documentationComment;
  final List<_InfoFormalParameter> parameters;

  factory _InfoConstructorDeclaration(SummaryDataReader reader) {
    return _InfoConstructorDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      periodOffset: reader.readOptionalUInt30(),
      nameOffset: reader.readUInt30(),
      nameEnd: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoConstructorDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.periodOffset,
    required this.nameOffset,
    required this.nameEnd,
    required this.documentationComment,
    required this.parameters,
  });
}

class _InfoEnumConstantDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;

  factory _InfoEnumConstantDeclaration(SummaryDataReader reader) {
    return _InfoEnumConstantDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
    );
  }

  _InfoEnumConstantDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
  });
}

class _InfoEnumDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoEnumConstantDeclaration> constants;

  factory _InfoEnumDeclaration(SummaryDataReader reader) {
    return _InfoEnumDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constants: reader.readTypedList(
        () => _InfoEnumConstantDeclaration(reader),
      ),
    );
  }

  _InfoEnumDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constants,
  });
}

class _InfoExport {
  final int nameOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoExport(SummaryDataReader reader) {
    return _InfoExport._(
      nameOffset: reader.readUInt30(),
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoExport._({
    required this.nameOffset,
    required this.combinators,
  });
}

class _InfoFieldDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;

  factory _InfoFieldDeclaration(SummaryDataReader reader) {
    return _InfoFieldDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
    );
  }

  _InfoFieldDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
  });
}

class _InfoFormalParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFormalParameter(SummaryDataReader reader) {
    return _InfoFormalParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - 1,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFormalParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoFunctionDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFunctionDeclaration(SummaryDataReader reader) {
    return _InfoFunctionDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFunctionDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoFunctionTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFunctionTypeAlias(SummaryDataReader reader) {
    return _InfoFunctionTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFunctionTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoGenericTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;

  factory _InfoGenericTypeAlias(SummaryDataReader reader) {
    return _InfoGenericTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
    );
  }

  _InfoGenericTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
  });
}

class _InfoImport {
  final int nameOffset;
  final int prefixOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoImport(SummaryDataReader reader) {
    return _InfoImport._(
      nameOffset: reader.readUInt30(),
      prefixOffset: reader.readUInt30() - 1,
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoImport._({
    required this.nameOffset,
    required this.prefixOffset,
    required this.combinators,
  });
}

class _InfoLibraryName {
  final int offset;
  final int length;

  factory _InfoLibraryName(SummaryDataReader reader) {
    return _InfoLibraryName._(
      offset: reader.readUInt30() - 1,
      length: reader.readUInt30(),
    );
  }

  _InfoLibraryName._({
    required this.offset,
    required this.length,
  });
}

class _InfoMethodDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoMethodDeclaration(SummaryDataReader reader) {
    return _InfoMethodDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoMethodDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InformativeDataWriter {
  final BufferedSink sink;

  _InformativeDataWriter(this.sink);

  void write(CompilationUnit unit) {
    sink.writeUInt30(unit.offset);
    sink.writeUInt30(unit.length);

    sink.writeUint30List(unit.lineInfo?.lineStarts ?? [0]);

    _writeLibraryName(unit);

    var firstDirective = unit.directives.firstOrNull;
    _writeDocumentationCommentNode(firstDirective?.documentationComment);

    sink.writeList2<ImportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      sink.writeUInt30(1 + (directive.prefix?.offset ?? -1));
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ExportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ClassDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
    });

    sink.writeList2<ClassTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
    });

    sink.writeList2<EnumDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      sink.writeList2<EnumConstantDeclaration>(node.constants, (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
      });
    });

    sink.writeList2<ExtensionDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.name?.offset ?? -1));
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
    });

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
      },
    );

    sink.writeList2<FunctionDeclaration>(
        unit.declarations
            .whereType<FunctionDeclaration>()
            .where((e) => !(e.isGetter || e.isSetter))
            .toList(), (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.functionExpression.typeParameters);
      _writeFormalParameters(node.functionExpression.parameters);
    });

    sink.writeList2<FunctionTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeFormalParameters(node.parameters);
    });

    sink.writeList2<GenericTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
    });

    sink.writeList2<MixinDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
    });

    sink.writeList<VariableDeclaration>(
      unit.declarations
          .whereType<TopLevelVariableDeclaration>()
          .expand((declaration) => declaration.variables.variables)
          .toList(),
      (node) {
        var codeOffset = _codeOffsetForVariable(node);
        sink.writeUInt30(codeOffset);
        sink.writeUInt30(node.end - codeOffset);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
      },
    );
  }

  int _codeOffsetForVariable(VariableDeclaration node) {
    var codeOffset = node.offset;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.variables[0] == node) {
      codeOffset = variableList.parent!.offset;
    }
    return codeOffset;
  }

  void _writeCombinators(List<Combinator> combinators) {
    sink.writeList<Combinator>(combinators, (combinator) {
      sink.writeUInt30(combinator.offset);
      sink.writeUInt30(combinator.end);
    });
  }

  void _writeConstructors(List<ClassMember> members) {
    sink.writeList2<ConstructorDeclaration>(members, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeOptionalUInt30(node.period?.offset);
      var nameNode = node.name ?? node.returnType;
      sink.writeUInt30(nameNode.offset);
      sink.writeUInt30(nameNode.end);
      _writeDocumentationComment(node);
      _writeFormalParameters(node.parameters);
    });
  }

  void _writeDocumentationComment(AnnotatedNode node) {
    _writeDocumentationCommentNode(node.documentationComment);
  }

  void _writeDocumentationCommentNode(Comment? commentNode) {
    var commentText = getCommentNodeRawText(commentNode);
    sink.writeStringUtf8(commentText ?? '');
  }

  void _writeFields(List<ClassMember> members) {
    sink.writeList<VariableDeclaration>(
      members
          .whereType<FieldDeclaration>()
          .expand((declaration) => declaration.fields.variables)
          .toList(),
      (node) {
        var codeOffset = _codeOffsetForVariable(node);
        sink.writeUInt30(codeOffset);
        sink.writeUInt30(node.end - codeOffset);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
      },
    );
  }

  void _writeFormalParameters(FormalParameterList? parameterList) {
    var parameters = parameterList?.parameters ?? <FormalParameter>[];
    sink.writeList<FormalParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.identifier?.offset ?? -1));

      var notDefault = node.notDefault;
      if (notDefault is FunctionTypedFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
    });
  }

  void _writeGettersSetters(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
      },
    );
  }

  void _writeLibraryName(CompilationUnit unit) {
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }
    sink.writeUInt30(1 + nameOffset);
    sink.writeUInt30(nameLength);
  }

  void _writeMethods(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => !(e.isGetter || e.isSetter))
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
      },
    );
  }

  void _writeTypeParameters(TypeParameterList? parameterList) {
    var parameters = parameterList?.typeParameters ?? <TypeParameter>[];
    sink.writeList<TypeParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
    });
  }
}

class _InfoTopLevelVariable {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;

  factory _InfoTopLevelVariable(SummaryDataReader reader) {
    return _InfoTopLevelVariable._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
    );
  }

  _InfoTopLevelVariable._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
  });
}

class _InfoTypeParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;

  factory _InfoTypeParameter(SummaryDataReader reader) {
    return _InfoTypeParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
    );
  }

  _InfoTypeParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
  });
}

class _InfoUnit {
  final int codeOffset;
  final int codeLength;
  final List<int> lineStarts;
  final _InfoLibraryName libraryName;
  final String docComment;
  final List<_InfoImport> imports;
  final List<_InfoExport> exports;
  final List<_InfoClassDeclaration> classDeclarations;
  final List<_InfoClassTypeAlias> classTypeAliases;
  final List<_InfoEnumDeclaration> enums;
  final List<_InfoClassDeclaration> extensions;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoFunctionDeclaration> functions;
  final List<_InfoFunctionTypeAlias> functionTypeAliases;
  final List<_InfoGenericTypeAlias> genericTypeAliases;
  final List<_InfoClassDeclaration> mixinDeclarations;
  final List<_InfoTopLevelVariable> topLevelVariable;

  factory _InfoUnit(SummaryDataReader reader) {
    return _InfoUnit._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      lineStarts: reader.readUInt30List(),
      libraryName: _InfoLibraryName(reader),
      docComment: reader.readStringUtf8(),
      imports: reader.readTypedList(
        () => _InfoImport(reader),
      ),
      exports: reader.readTypedList(
        () => _InfoExport(reader),
      ),
      classDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      classTypeAliases: reader.readTypedList(
        () => _InfoClassTypeAlias(reader),
      ),
      enums: reader.readTypedList(
        () => _InfoEnumDeclaration(reader),
      ),
      extensions: reader.readTypedList(
        () => _InfoClassDeclaration(reader, nameOffsetDelta: 1),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      functions: reader.readTypedList(
        () => _InfoFunctionDeclaration(reader),
      ),
      functionTypeAliases: reader.readTypedList(
        () => _InfoFunctionTypeAlias(reader),
      ),
      genericTypeAliases: reader.readTypedList(
        () => _InfoGenericTypeAlias(reader),
      ),
      mixinDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      topLevelVariable: reader.readTypedList(
        () => _InfoTopLevelVariable(reader),
      ),
    );
  }

  _InfoUnit._({
    required this.codeOffset,
    required this.codeLength,
    required this.lineStarts,
    required this.libraryName,
    required this.docComment,
    required this.imports,
    required this.exports,
    required this.classDeclarations,
    required this.classTypeAliases,
    required this.enums,
    required this.extensions,
    required this.accessors,
    required this.functions,
    required this.functionTypeAliases,
    required this.genericTypeAliases,
    required this.mixinDeclarations,
    required this.topLevelVariable,
  });
}

extension on String {
  String? get nullIfEmpty {
    return isNotEmpty ? this : null;
  }
}

extension _ListOfElement<T extends Element> on List<T> {
  List<T> get notSynthetic {
    return where((e) => !e.isSynthetic).toList();
  }
}
