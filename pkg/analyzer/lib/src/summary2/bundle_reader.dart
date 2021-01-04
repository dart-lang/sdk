// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/apply_resolution.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

Map<String, LibraryReader> createLibraryReadersWithAstBytes({
  @required LinkedElementFactory elementFactory,
  @required Uint8List resolutionBytes,
  @required Map<String, Map<String, Uint8List>> uriToLibrary_uriToUnitAstBytes,
}) {
  var _resolutionReader = SummaryDataReader(resolutionBytes);

  _resolutionReader.offset = _resolutionReader.bytes.length - 4 * 3;
  var resolutionLibrariesOffset = _resolutionReader.readUint32();
  var resolutionReferencesOffset = _resolutionReader.readUint32();
  var resolutionStringsOffset = _resolutionReader.readUint32();
  _resolutionReader.createStringTable(resolutionStringsOffset);

  var referenceReader = _ReferenceReader(
    elementFactory,
    _resolutionReader,
    resolutionReferencesOffset,
  );

  _resolutionReader.offset = resolutionLibrariesOffset;
  var resolutionLibraryOffsets = _resolutionReader.readUint30List();

  assert(
    uriToLibrary_uriToUnitAstBytes.length == resolutionLibraryOffsets.length,
  );

  // TODO(scheglov) Don't read anything, we know URIs.
  var libraryMap = <String, LibraryReader>{};
  for (var i = 0; i < resolutionLibraryOffsets.length; i++) {
    _resolutionReader.offset = resolutionLibraryOffsets[i];
    var libraryUriStr = _resolutionReader.readStringReference();
    var resolutionUnitOffsets = _resolutionReader.readUint30List();
    var exportsIndexList = _resolutionReader.readUint30List();

    var uriToUnitAstBytes = uriToLibrary_uriToUnitAstBytes[libraryUriStr];
    assert(uriToUnitAstBytes != null, libraryUriStr);

    var reference = elementFactory.rootReference.getChild(libraryUriStr);
    var libraryReader = LibraryReaderForAstBytes._(
      elementFactory,
      uriToUnitAstBytes,
      _resolutionReader,
      referenceReader,
      reference,
      resolutionUnitOffsets,
      exportsIndexList,
    );
    libraryMap[libraryUriStr] = libraryReader;
  }

  return libraryMap;
}

class BundleReader {
  final SummaryDataReader _astReader;
  final SummaryDataReader _resolutionReader;

  bool _withInformative = false;

  final Map<String, LibraryReader> libraryMap = {};

  BundleReader({
    @required LinkedElementFactory elementFactory,
    @required Uint8List astBytes,
    @required Uint8List resolutionBytes,
  })  : _astReader = SummaryDataReader(astBytes),
        _resolutionReader = SummaryDataReader(resolutionBytes) {
    _astReader.offset = 0;
    _withInformative = _astReader.readByte() == 1;

    _astReader.offset = _astReader.bytes.length - 4 * 2;
    var astLibrariesOffset = _astReader.readUint32();
    var astStringsOffset = _astReader.readUint32();
    _astReader.createStringTable(astStringsOffset);

    _resolutionReader.offset = _resolutionReader.bytes.length - 4 * 3;
    var resolutionLibrariesOffset = _resolutionReader.readUint32();
    var resolutionReferencesOffset = _resolutionReader.readUint32();
    var resolutionStringsOffset = _resolutionReader.readUint32();
    _resolutionReader.createStringTable(resolutionStringsOffset);

    var referenceReader = _ReferenceReader(
      elementFactory,
      _resolutionReader,
      resolutionReferencesOffset,
    );

    _astReader.offset = astLibrariesOffset;
    var astLibraryOffsets = _astReader.readUint30List();

    _resolutionReader.offset = resolutionLibrariesOffset;
    var resolutionLibraryOffsets = _resolutionReader.readUint30List();

    assert(astLibraryOffsets.length == resolutionLibraryOffsets.length);

    for (var i = 0; i < astLibraryOffsets.length; i++) {
      _astReader.offset = astLibraryOffsets[i];
      var name = _astReader.readStringReference();
      var nameOffset = _astReader.readUInt30() - 1;
      var nameLength = _astReader.readUInt30();
      var hasPartOfDirective = _astReader.readByte() != 0;
      var astUnitOffsets = _astReader.readUint30List();

      _resolutionReader.offset = resolutionLibraryOffsets[i];
      var libraryUriStr = _resolutionReader.readStringReference();
      var resolutionUnitOffsets = _resolutionReader.readUint30List();
      assert(astUnitOffsets.length == resolutionUnitOffsets.length);
      var exportsIndexList = _resolutionReader.readUint30List();

      var reference = elementFactory.rootReference.getChild(libraryUriStr);
      var libraryReader = LibraryReaderFromBundle._(
        elementFactory,
        _withInformative,
        _astReader,
        _resolutionReader,
        referenceReader,
        reference,
        name,
        nameOffset,
        nameLength,
        hasPartOfDirective,
        astUnitOffsets,
        resolutionUnitOffsets,
        exportsIndexList,
      );
      libraryMap[libraryUriStr] = libraryReader;
    }
  }

  LibraryReader getLibrary(String uriStr) {
    return libraryMap[uriStr];
  }
}

class ClassReader {
  final int membersOffset;

  ClassReader(this.membersOffset);
}

abstract class LibraryReader {
  final LinkedElementFactory _elementFactory;
  final SummaryDataReader _resolutionReader;
  final _ReferenceReader _referenceReader;
  final Reference reference;

  final Uint32List _resolutionUnitOffsets;
  final Uint32List _exportsIndexList;
  List<Reference> _exports;

  List<UnitReader> _units;

  LibraryReader._(
    this._elementFactory,
    this._resolutionReader,
    this._referenceReader,
    this.reference,
    this._resolutionUnitOffsets,
    this._exportsIndexList,
  );

  List<Reference> get exports {
    if (_exports == null) {
      var length = _exportsIndexList.length;
      _exports = List.filled(length, null, growable: false);
      for (var i = 0; i < length; i++) {
        var index = _exportsIndexList[i];
        var reference = _referenceReader.referenceOfIndex(index);
        _exports[i] = reference;
      }
    }
    return _exports;
  }

  /// Is `true` if the defining unit has [PartOfDirective].
  bool get hasPartOfDirective;

  String get name;

  int get nameLength;

  int get nameOffset;

  List<UnitReader> get units;

  bool get withInformative;
}

/// Implementation of [LibraryReader] that reads ASTs for units from separate
/// byte buffers.
class LibraryReaderForAstBytes extends LibraryReader {
  final Map<String, Uint8List> _uriToUnitAstBytes;

  bool _hasNameRead = false;
  bool _withInformative;
  String _name;
  int _nameOffset;
  int _nameLength;
  bool _hasPartOfDirective;

  LibraryReaderForAstBytes._(
    LinkedElementFactory elementFactory,
    Map<String, Uint8List> uriToUnitAstBytes,
    SummaryDataReader resolutionReader,
    _ReferenceReader referenceReader,
    Reference reference,
    Uint32List resolutionUnitOffsets,
    Uint32List exportsIndexList,
  )   : _uriToUnitAstBytes = uriToUnitAstBytes,
        super._(
          elementFactory,
          resolutionReader,
          referenceReader,
          reference,
          resolutionUnitOffsets,
          exportsIndexList,
        ) {
    // TODO(scheglov) This fails when there are invalid URIs.
    // assert(_uriToUnitAstBytes.length == _resolutionUnitOffsets.length);
  }

  @override
  bool get hasPartOfDirective {
    _readName();
    return _hasPartOfDirective;
  }

  @override
  String get name {
    _readName();
    return _name;
  }

  @override
  int get nameLength {
    _readName();
    return _nameLength;
  }

  @override
  int get nameOffset {
    _readName();
    return _nameOffset;
  }

  @override
  List<UnitReader> get units {
    if (_units != null) return _units;
    _units = [];

    for (var i = 0; i < _resolutionUnitOffsets.length; i++) {
      _resolutionReader.offset = _resolutionUnitOffsets[i];
      var unitUriStr = _resolutionReader.readStringReference();
      var isSynthetic = _resolutionReader.readByte() != 0;
      var isPart = _resolutionReader.readByte() != 0;
      var partUriStr = _resolutionReader.readStringReference();
      if (!isPart) {
        partUriStr = null;
      }
      var resolutionDirectivesOffset = _resolutionReader.readUInt30();
      var resolutionDeclarationOffsets = _resolutionReader.readUint30List();

      // TODO(scheglov) Is this right?
      if (unitUriStr.isEmpty) {
        unitUriStr = 'null';
      }

      var astBytes = _uriToUnitAstBytes[unitUriStr];
      var astReader = SummaryDataReader(astBytes);
      astReader.offset = astBytes.length - 4 * 4;
      var headerOffset = astReader.readUint32();
      var indexOffset = astReader.readUint32();
      astReader.readUint32(); // library data
      var astStringsOffset = astReader.readUint32();
      astReader.createStringTable(astStringsOffset);

      _units.add(
        UnitReader._(
          this,
          resolutionDirectivesOffset,
          resolutionDeclarationOffsets,
          reference.getChild('@unit').getChild(unitUriStr),
          isSynthetic,
          partUriStr,
          astReader,
          headerOffset,
          indexOffset,
        ),
      );
    }

    return _units;
  }

  @override
  bool get withInformative {
    _readName();
    return _withInformative;
  }

  void _readName() {
    if (_hasNameRead) return;
    _hasNameRead = true;

    var uriStr = reference.name;
    var definingUnitBytes = _uriToUnitAstBytes[uriStr];
    var reader = SummaryDataReader(definingUnitBytes);
    reader.offset = definingUnitBytes.length - 4 * 2;
    var libraryDataOffset = reader.readUint32();
    var astStringsOffset = reader.readUint32();
    reader.createStringTable(astStringsOffset);

    reader.offset = libraryDataOffset;
    _name = reader.readStringReference();
    _nameOffset = reader.readUInt30() - 1;
    _nameLength = reader.readUInt30();
    _hasPartOfDirective = reader.readByte() != 0;
    _withInformative = reader.readByte() != 0;
  }
}

class LibraryReaderFromBundle extends LibraryReader {
  final SummaryDataReader _astReader;
  final Uint32List _astUnitOffsets;

  @override
  final String name;

  @override
  final int nameOffset;

  @override
  final int nameLength;

  @override
  final bool hasPartOfDirective;

  @override
  final bool withInformative;

  LibraryReaderFromBundle._(
    LinkedElementFactory elementFactory,
    this.withInformative,
    SummaryDataReader astReader,
    SummaryDataReader resolutionReader,
    _ReferenceReader referenceReader,
    Reference reference,
    this.name,
    this.nameOffset,
    this.nameLength,
    this.hasPartOfDirective,
    Uint32List astUnitOffsets,
    Uint32List resolutionUnitOffsets,
    Uint32List exportsIndexList,
  )   : _astReader = astReader,
        _astUnitOffsets = astUnitOffsets,
        super._(
          elementFactory,
          resolutionReader,
          referenceReader,
          reference,
          resolutionUnitOffsets,
          exportsIndexList,
        ) {
    assert(_astUnitOffsets.length == _resolutionUnitOffsets.length);
  }

  @override
  List<UnitReader> get units {
    if (_units != null) return _units;
    _units = [];

    for (var i = 0; i < _astUnitOffsets.length; i++) {
      var astUnitOffset = _astUnitOffsets[i];
      var resolutionUnitOffset = _resolutionUnitOffsets[i];

      _astReader.offset = astUnitOffset;
      var headerOffset = _astReader.readUInt30();
      var indexOffset = _astReader.offset;

      _resolutionReader.offset = resolutionUnitOffset;
      var unitUriStr = _resolutionReader.readStringReference();
      var isSynthetic = _resolutionReader.readByte() != 0;
      var isPart = _resolutionReader.readByte() != 0;
      var partUriStr = _resolutionReader.readStringReference();
      if (!isPart) {
        partUriStr = null;
      }
      var resolutionDirectivesOffset = _resolutionReader.readUInt30();
      var resolutionDeclarationOffsets = _resolutionReader.readUint30List();

      _units.add(
        UnitReader._(
          this,
          resolutionDirectivesOffset,
          resolutionDeclarationOffsets,
          reference.getChild('@unit').getChild(unitUriStr),
          isSynthetic,
          partUriStr,
          _astReader,
          headerOffset,
          indexOffset,
        ),
      );
    }

    return _units;
  }
}

class LinkedContext implements AstLinkedContext {
  final UnitReader _unitReader;
  final AstNode _node;
  final int _resolutionIndex;
  final Uint32List _codeOffsetLengthList;
  final Uint32List _documentationTokenIndexList;

  @override
  final int codeOffset;

  @override
  final int codeLength;

  @override
  final bool isClassWithConstConstructor;

  bool _isApplied = false;

  bool _hasDocumentationComment = false;

  _UnitMemberReader _reader;

  LinkedContext(
    this._unitReader,
    this._node, {
    @required this.codeOffset,
    @required this.codeLength,
    this.isClassWithConstConstructor = false,
    Uint32List codeOffsetLengthList,
    @required int resolutionIndex,
    @required Uint32List documentationTokenIndexList,
  })  : _resolutionIndex = resolutionIndex,
        _codeOffsetLengthList = codeOffsetLengthList,
        _documentationTokenIndexList = documentationTokenIndexList;

  @override
  List<ClassMember> get classMembers {
    var reader = _reader;
    if (reader is _ClassReader) {
      return reader.classMembers;
    } else if (_node is ClassTypeAlias) {
      return const <ClassMember>[];
    } else {
      throw UnimplementedError();
    }
  }

  @override
  // TODO: implement unitDirectives
  List<Directive> get unitDirectives => throw UnimplementedError();

  @override
  void applyResolution(LinkedUnitContext unitContext) {
    if (_isApplied) {
      return;
    }
    _isApplied = true;

    // EnumConstantDeclaration has no separate resolution.
    // Its metadata is resolved during EnumDeclaration resolution.
    if (_resolutionIndex == -1) {
      return;
    }

    var localElements = <Element>[];
    var resolutionReader = LinkedResolutionReader(
      _unitReader,
      localElements,
      _unitReader._resolutionDeclarationsOffset[_resolutionIndex],
    );
    _node.accept(
      ApplyResolutionVisitor(
        unitContext,
        localElements,
        resolutionReader,
      ),
    );
  }

  @override
  int getVariableDeclarationCodeLength(VariableDeclaration node) {
    var variableList = node.parent as VariableDeclarationList;
    var variables = variableList.variables;
    for (var i = 0; i < variables.length; i++) {
      if (identical(variables[i], node)) {
        return _codeOffsetLengthList[2 * i + 1];
      }
    }
    throw StateError('No |$node| in: $variableList');
  }

  @override
  int getVariableDeclarationCodeOffset(VariableDeclaration node) {
    var variableList = node.parent as VariableDeclarationList;
    var variables = variableList.variables;
    for (var i = 0; i < variables.length; i++) {
      if (identical(variables[i], node)) {
        return _codeOffsetLengthList[2 * i + 0];
      }
    }
    throw StateError('No |$node| in: $variableList');
  }

  @override
  void readDocumentationComment() {
    if (_hasDocumentationComment) {
      return;
    }
    _hasDocumentationComment = true;

    if (_documentationTokenIndexList.isEmpty) {
      return;
    }

    var tokens = <Token>[];
    for (var lexemeIndex in _documentationTokenIndexList) {
      var lexeme = _unitReader.astReader.stringOfIndex(lexemeIndex);
      var token = TokenFactory.tokenFromString(lexeme);
      tokens.add(token);
    }

    var comment = astFactory.documentationComment(tokens);
    (_node as AnnotatedNodeImpl).documentationComment = comment;
  }
}

/// Helper for reading elements and types from their binary encoding.
class LinkedResolutionReader {
  final UnitReader _unitReader;

  /// The stack of [TypeParameterElement]s and [ParameterElement] that are
  /// available in the scope of [nextElement] and [nextType].
  ///
  /// This stack is shared with the client of the reader, and update mostly
  /// by the client. However it is also updated during [_readFunctionType].
  final List<Element> _localElements;

  /// The offset in [_Reader.bytes] from which we read resolution now.
  int _byteOffset = 0;

  LinkedResolutionReader(
    this._unitReader,
    this._localElements,
    this._byteOffset,
  );

  /// TODO(scheglov) Remove after fixing http://dartbug.com/44449
  int get byteOffset => _byteOffset;

  /// TODO(scheglov) Remove after fixing http://dartbug.com/44449
  Uint8List get bytes => _unitReader._resolutionReader.bytes;

  Element nextElement() {
    var memberFlags = readByte();
    var element = _readRawElement();

    if (memberFlags == Tag.RawElement) {
      return element;
    }

    if (memberFlags == Tag.MemberLegacyWithTypeArguments ||
        memberFlags == Tag.MemberWithTypeArguments) {
      var arguments = _readTypeList();
      // TODO(scheglov) why to check for empty? If we have this flags.
      if (arguments.isNotEmpty) {
        var typeParameters =
            (element.enclosingElement as TypeParameterizedElement)
                .typeParameters;
        var substitution = Substitution.fromPairs(typeParameters, arguments);
        element = ExecutableMember.from2(element, substitution);
      }
    }

    if (memberFlags == Tag.MemberLegacyWithTypeArguments) {
      return Member.legacy(element);
    }

    if (memberFlags == Tag.MemberWithTypeArguments) {
      return element;
    }

    throw UnimplementedError('memberFlags: $memberFlags');
  }

  String nextString() {
    var index = _readUInt30();
    return _unitReader._resolutionReader.stringOfIndex(index);
  }

  DartType nextType() {
    var tag = readByte();
    if (tag == Tag.NullType) {
      return null;
    } else if (tag == Tag.DynamicType) {
      return DynamicTypeImpl.instance;
    } else if (tag == Tag.FunctionType) {
      return _readFunctionType();
    } else if (tag == Tag.InterfaceType) {
      var element = nextElement();
      var length = _readUInt30();
      var typeArguments = List<DartType>.filled(length, null);
      for (var i = 0; i < length; i++) {
        typeArguments[i] = nextType();
      }
      var nullability = _readNullability();
      return InterfaceTypeImpl(
        element: element,
        typeArguments: typeArguments,
        nullabilitySuffix: nullability,
      );
    } else if (tag == Tag.InterfaceType_noTypeArguments_none) {
      var element = nextElement();
      return InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.none,
      );
    } else if (tag == Tag.InterfaceType_noTypeArguments_question) {
      var element = nextElement();
      return InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.question,
      );
    } else if (tag == Tag.InterfaceType_noTypeArguments_star) {
      var element = nextElement();
      return InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.star,
      );
    } else if (tag == Tag.NeverType) {
      var nullability = _readNullability();
      return NeverTypeImpl.instance.withNullability(nullability);
    } else if (tag == Tag.TypeParameterType) {
      var element = nextElement();
      var nullability = _readNullability();
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullability,
      );
    } else if (tag == Tag.VoidType) {
      return VoidTypeImpl.instance;
    } else {
      throw UnimplementedError('$tag');
    }
  }

  int readByte() {
    return _unitReader._resolutionReader.bytes[_byteOffset++];
  }

  List<String> readStringList() {
    var values = <String>[];
    var length = _readUInt30();
    for (var i = 0; i < length; i++) {
      var value = _readStringReference();
      values.add(value);
    }
    return values;
  }

  int readUInt30() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  /// TODO(scheglov) Optimize for write/read of types without type parameters.
  FunctionType _readFunctionType() {
    var typeParameters = <TypeParameterElement>[];
    var typeParametersLength = _readUInt30();
    for (var i = 0; i < typeParametersLength; i++) {
      var name = _readStringReference();
      var element = TypeParameterElementImpl.synthetic(name);
      typeParameters.add(element);
      _localElements.add(element);
    }
    for (var i = 0; i < typeParametersLength; i++) {
      var element = typeParameters[i] as TypeParameterElementImpl;
      var bound = nextType();
      element.bound = bound;
    }

    var typedefElement = nextElement();
    var typeArguments = _readTypeList();

    var returnType = nextType();

    var formalParameters = <ParameterElement>[];
    var formalParametersLength = _readUInt30();
    for (var i = 0; i < formalParametersLength; i++) {
      var kindIndex = readByte();
      var type = nextType();
      var name = nextString();
      formalParameters.add(
        ParameterElementImpl.synthetic(
          name,
          type,
          _formalParameterKind(kindIndex),
        ),
      );
    }

    var nullability = _readNullability();

    _localElements.length -= typeParametersLength;

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullability,
      element: typedefElement,
      typeArguments: typeArguments,
    );
  }

  NullabilitySuffix _readNullability() {
    var index = readByte();
    return NullabilitySuffix.values[index];
  }

  Element _readRawElement() {
    var index = _readUInt30();

    if ((index & 0x1) == 0x1) {
      return _localElements[index >> 1];
    }

    var referenceIndex = index >> 1;
    var referenceReader = _unitReader._referenceReader;
    var reference = referenceReader.referenceOfIndex(referenceIndex);

    var elementFactory = _unitReader.elementFactory;
    return elementFactory.elementOfReference(reference);
  }

  String _readStringReference() {
    var index = _readUInt30();
    return _unitReader._resolutionReader.stringOfIndex(index);
  }

  List<DartType> _readTypeList() {
    var types = <DartType>[];
    var length = _readUInt30();
    for (var i = 0; i < length; i++) {
      var argument = nextType();
      types.add(argument);
    }
    return types;
  }

  int _readUInt30() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  static ParameterKind _formalParameterKind(int encoding) {
    if (encoding == Tag.ParameterKindRequiredPositional) {
      return ParameterKind.REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (encoding == Tag.ParameterKindRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalNamed) {
      return ParameterKind.NAMED;
    } else {
      throw StateError('Unexpected parameter kind encoding: $encoding');
    }
  }
}

class SummaryDataForCompilationUnit {
  final int codeLength;

  SummaryDataForCompilationUnit(this.codeLength);
}

class SummaryDataForFormalParameter {
  final int codeOffset;
  final int codeLength;

  SummaryDataForFormalParameter({
    @required this.codeOffset,
    @required this.codeLength,
  });
}

class SummaryDataForLibraryDirective {
  final UnitReader _unitReader;
  final LibraryDirectiveImpl _node;
  final Uint32List _documentationTokenIndexList;
  bool _hasDocumentationComment = false;

  SummaryDataForLibraryDirective(
    this._unitReader,
    this._node, {
    @required Uint32List documentationTokenIndexList,
  }) : _documentationTokenIndexList = documentationTokenIndexList {
    _node.summaryData = this;
  }

  void readDocumentationComment() {
    if (_hasDocumentationComment) {
      return;
    }
    _hasDocumentationComment = true;

    if (_documentationTokenIndexList.isEmpty) {
      return;
    }

    var tokens = <Token>[];
    for (var lexemeIndex in _documentationTokenIndexList) {
      var lexeme = _unitReader.astReader.stringOfIndex(lexemeIndex);
      var token = TokenFactory.tokenFromString(lexeme);
      tokens.add(token);
    }

    var comment = astFactory.documentationComment(tokens);
    _node.documentationComment = comment;
  }
}

class SummaryDataForTypeParameter {
  final int codeOffset;
  final int codeLength;

  SummaryDataForTypeParameter({
    @required this.codeOffset,
    @required this.codeLength,
  });
}

class UnitReader implements ReferenceNodeAccessor {
  final LibraryReader libraryReader;

  final Reference reference;

  final bool isSynthetic;

  /// If a part, the URI that is used in the [PartDirective].
  /// Or `null` for the defining unit.
  final String partUriStr;

  final int _directivesResolutionOffset;
  bool _isDirectivesResolutionApplied = false;

  final Uint32List _resolutionDeclarationsOffset;

  final SummaryDataReader astReader;

  int _directivesOffset;
  final List<_UnitMemberReader> _memberReaders = [];

  CompilationUnitImpl _unit;
  bool _hasDirectives = false;
  bool _hasDeclarations = false;

  UnitReader._(
    this.libraryReader,
    this._directivesResolutionOffset,
    this._resolutionDeclarationsOffset,
    this.reference,
    this.isSynthetic,
    this.partUriStr,
    this.astReader,
    int headerOffset,
    int indexOffset,
  ) {
    reference.nodeAccessor = this;

    astReader.offset = headerOffset;
    var languageVersion = _readLanguageVersion();
    var featureSetEncoded = astReader.readUint8List();
    var lineInfo = _readLineInfo();
    var codeLength = astReader.readUInt30();
    var featureSet = ExperimentStatus.fromStorage(featureSetEncoded);
    _directivesOffset = astReader.offset;

    _unit = astFactory.compilationUnit(
      beginToken: null,
      // TODO(scheglov)
      // scriptTag: _readNode(data.compilationUnit_scriptTag),
      directives: [],
      declarations: [],
      endToken: null,
      featureSet: featureSet,
    );
    _unit.languageVersion = languageVersion;
    _unit.lineInfo = lineInfo;
    _unit.summaryData = SummaryDataForCompilationUnit(codeLength);

    astReader.offset = indexOffset;
    _readIndex2();
  }

  LinkedElementFactory get elementFactory => libraryReader._elementFactory;

  /// TODO(scheglov)
  /// This methods breaks lazy loading, and loads everything eagerly.
  /// We use it because of `unitElement.types` for example, when we are
  /// explicitly asked for all [ClassDeclaration]s and [ClassTypeAlias]s.
  @Deprecated('review it')
  @override
  CompilationUnit get node {
    readDirectives();
    readDeclarations();
    return _unit;
  }

  CompilationUnit get unit => _unit;

  String get uriStr => reference.name;

  bool get withInformative => libraryReader.withInformative;

  _ReferenceReader get _referenceReader => libraryReader._referenceReader;

  SummaryDataReader get _resolutionReader => libraryReader._resolutionReader;

  /// Apply resolution to directives.
  void applyDirectivesResolution(LinkedUnitContext unitContext) {
    if (_isDirectivesResolutionApplied) {
      return;
    }
    _isDirectivesResolutionApplied = true;

    var localElements = <Element>[];
    var resolutionReader = LinkedResolutionReader(
      this,
      localElements,
      _directivesResolutionOffset,
    );
    for (var directive in _unit.directives) {
      directive.accept(
        ApplyResolutionVisitor(
          unitContext,
          localElements,
          resolutionReader,
        ),
      );
    }
  }

  void readDeclarations() {
    if (!_hasDeclarations) {
      _hasDeclarations = true;
      for (var reader in _memberReaders) {
        reader.node;
      }
    }
  }

  /// Ensure that directives are read in this unit.
  void readDirectives() {
    if (!_hasDirectives) {
      _hasDirectives = true;
      astReader.offset = _directivesOffset;
      var length = astReader.readUInt30();
      for (var i = 0; i < length; i++) {
        var astReader = AstBinaryReader(
          reader: this,
        );
        var directive = astReader.readNode() as Directive;
        _unit.directives.add(directive);
      }
    }
  }

  @override
  void readIndex() {}

  /// Read the index of declarations in this unit, and add `null`s into
  /// [CompilationUnit.declarations] as placeholders.
  ///
  /// TODO(scheglov) we don't need both this method, and [readIndex].
  void _readIndex2() {
    var unitReference = reference;
    var length = astReader.readUInt30();
    for (var i = 0; i < length; i++) {
      var offset = astReader.readUInt30();
      var tag = astReader.readByte();
      if (tag == Tag.Class) {
        var name = astReader.readStringReference();
        var indexOffset = astReader.readUInt30();
        var reference = unitReference.getChild('@class').getChild(name);
        _memberReaders.add(
          _ClassReader(
            unitReader: this,
            reference: reference,
            offset: offset,
            unit: _unit,
            indexOffset: indexOffset,
          ),
        );
      } else if (tag == Tag.ClassTypeAlias) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        unitReference.getChild('@class').getChild(name).nodeAccessor = reader;
      } else if (tag == Tag.EnumDeclaration) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        unitReference.getChild('@enum').getChild(name).nodeAccessor = reader;
      } else if (tag == Tag.ExtensionDeclaration) {
        var name = astReader.readStringReference();
        var indexOffset = astReader.readUInt30();
        var reference = unitReference.getChild('@extension').getChild(name);
        _memberReaders.add(
          _ClassReader(
            unitReader: this,
            reference: reference,
            offset: offset,
            unit: _unit,
            indexOffset: indexOffset,
          ),
        );
      } else if (tag == Tag.FunctionDeclaration) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        var containerRef = unitReference.getChild('@function');
        containerRef.getChild(name).nodeAccessor = reader;
      } else if (tag == Tag.FunctionDeclaration_getter) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        var getterRef = unitReference.getChild('@getter');
        getterRef.getChild(name).nodeAccessor = reader;
        var variableRef = unitReference.getChild('@variable');
        variableRef.getChild(name).nodeAccessor ??= reader;
      } else if (tag == Tag.FunctionDeclaration_setter) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        var setterRef = unitReference.getChild('@setter');
        setterRef.getChild(name).nodeAccessor = reader;
        var variableRef = unitReference.getChild('@variable');
        variableRef.getChild(name).nodeAccessor ??= reader;
      } else if (tag == Tag.GenericTypeAlias) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        unitReference.getChild('@typeAlias').getChild(name).nodeAccessor =
            reader;
      } else if (tag == Tag.FunctionTypeAlias) {
        var name = astReader.readStringReference();
        var reader = _UnitMemberReader(this, offset, _unit);
        _memberReaders.add(reader);
        unitReference.getChild('@typeAlias').getChild(name).nodeAccessor =
            reader;
      } else if (tag == Tag.MixinDeclaration) {
        var name = astReader.readStringReference();
        var indexOffset = astReader.readUInt30();
        var reference = unitReference.getChild('@mixin').getChild(name);
        _memberReaders.add(
          _ClassReader(
            unitReader: this,
            reference: reference,
            offset: offset,
            unit: _unit,
            indexOffset: indexOffset,
          ),
        );
      } else if (tag == Tag.TopLevelVariableDeclaration) {
        var reader = _UnitMemberReader(this, offset, _unit);
        var length = astReader.readUInt30();
        for (var i = 0; i < length; i++) {
          var name = astReader.readStringReference();
          _memberReaders.add(reader);
          unitReference.getChild('@getter').getChild(name).nodeAccessor =
              reader;
          // TODO(scheglov) only if not final/const
          // Crash in language_2/export/local_export_test.dart
          unitReference.getChild('@setter').getChild(name).nodeAccessor =
              reader;
        }
      } else {
        // TODO(scheglov) implement
      }
    }
  }

  LibraryLanguageVersion _readLanguageVersion() {
    var packageMajor = astReader.readUInt30();
    var packageMinor = astReader.readUInt30();
    var overrideMajor = astReader.readUInt30();
    var overrideMinor = astReader.readUInt30();
    return LibraryLanguageVersion(
      package: Version(packageMajor, packageMinor, 0),
      override: overrideMajor > 0
          ? Version(overrideMajor - 1, overrideMinor - 1, 0)
          : null,
    );
  }

  LineInfo _readLineInfo() {
    var lineStarts = astReader.readUint30List();
    return LineInfo(lineStarts);
  }
}

class _ClassMemberReader implements ReferenceNodeAccessor {
  final UnitReader unitReader;
  final int offset;
  final NodeListImpl<ClassMember> _members;
  final int _membersIndex;
  ClassMemberImpl _node;

  _ClassMemberReader(this.unitReader, this.offset, this._members)
      : _membersIndex = _members.length {
    _members.add(null);
  }

  @override
  AstNode get node {
    if (_node == null) {
      var astReader = AstBinaryReader(
        reader: unitReader,
      );
      unitReader.astReader.offset = offset;
      _node = astReader.readNode() as ClassMemberImpl;
      _members[_membersIndex] = _node;
    }
    return _node;
  }

  @override
  void readIndex() {}
}

class _ClassReader extends _UnitMemberReader {
  final Reference reference;
  final int indexOffset;

  bool _hasIndex = false;
  final List<_ClassMemberReader> _classMemberReaders = [];
  List<ClassMember> _classMembers;

  _ClassReader({
    @required this.reference,
    @required UnitReader unitReader,
    @required int offset,
    @required CompilationUnit unit,
    @required this.indexOffset,
  }) : super(unitReader, offset, unit) {
    reference.nodeAccessor ??= this;
  }

  List<_ClassMemberReader> get classMemberReaders {
    readIndex();
    return _classMemberReaders;
  }

  List<ClassMember> get classMembers {
    return classMemberReaders.map((e) => e.node as ClassMember).toList();
  }

  @override
  void readIndex() {
    if (_hasIndex) return;
    _hasIndex = true;

    var node = _node;
    if (node == null) {
      throw StateError('The class node must be read before reading members.');
    }

    if (node is ClassDeclarationImpl) {
      _classMembers = node.members;
    } else if (node is ExtensionDeclarationImpl) {
      _classMembers = node.members;
    } else if (node is MixinDeclarationImpl) {
      _classMembers = node.members;
    } else {
      throw StateError('(${node.runtimeType}) $node');
    }

    unitReader.astReader.offset = indexOffset;

    var length = unitReader.astReader.readUInt30();
    for (var i = 0; i < length; i++) {
      var offset = unitReader.astReader.readUInt30();
      var tag = unitReader.astReader.readByte();
      if (tag == Tag.ConstructorDeclaration) {
        var reader = _ClassMemberReader(unitReader, offset, _classMembers);
        _classMemberReaders.add(reader);
        var name = unitReader.astReader.readStringReference();
        var reference = this.reference.getChild('@constructor').getChild(name);
        reference.nodeAccessor ??= reader;
      } else if (tag == Tag.MethodDeclaration) {
        var reader = _ClassMemberReader(unitReader, offset, _classMembers);
        _classMemberReaders.add(reader);
        var name = unitReader.astReader.readStringReference();
        var reference = this.reference.getChild('@method').getChild(name);
        reference.nodeAccessor ??= reader;
      } else if (tag == Tag.MethodDeclaration_getter) {
        var reader = _ClassMemberReader(unitReader, offset, _classMembers);
        _classMemberReaders.add(reader);
        var name = unitReader.astReader.readStringReference();
        var reference = this.reference.getChild('@getter').getChild(name);
        reference.nodeAccessor ??= reader;
      } else if (tag == Tag.MethodDeclaration_setter) {
        var reader = _ClassMemberReader(unitReader, offset, _classMembers);
        _classMemberReaders.add(reader);
        var name = unitReader.astReader.readStringReference();
        var reference = this.reference.getChild('@setter').getChild(name);
        reference.nodeAccessor ??= reader;
      } else if (tag == Tag.FieldDeclaration) {
        var reader = _ClassMemberReader(unitReader, offset, _classMembers);
        _classMemberReaders.add(reader);
        var length = unitReader.astReader.readUInt30();
        for (var i = 0; i < length; i++) {
          var name = unitReader.astReader.readStringReference();
          var fieldRef = reference.getChild('@field').getChild(name);
          fieldRef.nodeAccessor ??= reader;
          var getterRef = reference.getChild('@getter').getChild(name);
          getterRef.nodeAccessor ??= reader;
          var setterRef = reference.getChild('@setter').getChild(name);
          setterRef.nodeAccessor ??= reader;
        }
      } else {
        throw UnimplementedError('tag: $tag');
      }
    }
  }
}

class _ReferenceReader {
  final LinkedElementFactory elementFactory;
  final SummaryDataReader _reader;
  Uint32List _parents;
  Uint32List _names;
  List<Reference> _references;

  _ReferenceReader(this.elementFactory, this._reader, int offset) {
    _reader.offset = offset;
    _parents = _reader.readUint30List();
    _names = _reader.readUint30List();
    assert(_parents.length == _names.length);

    _references = List.filled(_names.length, null);
  }

  Reference referenceOfIndex(int index) {
    var reference = _references[index];
    if (reference != null) {
      return reference;
    }

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var nameIndex = _names[index];
    var name = _reader.stringOfIndex(nameIndex);

    var parentIndex = _parents[index];
    var parent = referenceOfIndex(parentIndex);

    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }
}

class _UnitMemberReader implements ReferenceNodeAccessor {
  final UnitReader unitReader;
  final int offset;
  final CompilationUnit _unit;
  final int _index;
  CompilationUnitMemberImpl _node;

  _UnitMemberReader(this.unitReader, this.offset, this._unit)
      : _index = _unit.declarations.length {
    _unit.declarations.add(null);
  }

  @override
  AstNode get node {
    if (_node == null) {
      var astReader = AstBinaryReader(
        reader: unitReader,
      );
      unitReader.astReader.offset = offset;
      _node = astReader.readNode() as CompilationUnitMember;
      _unit.declarations[_index] = _node;

      var hasLinkedContext = _node as HasAstLinkedContext;
      var linkedContext = hasLinkedContext.linkedContext as LinkedContext;
      linkedContext._reader = this;
    }
    return _node;
  }

  @override
  void readIndex() {}
}
