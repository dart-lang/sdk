// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/binary_format_doc.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

Uint8List writeUnitToBytes({@required CompilationUnit unit}) {
  var byteSink = ByteSink();
  var sink = BufferedSink(byteSink);
  var stringIndexer = StringIndexer();

  var headerOffset = sink.offset;
  var nextResolutionIndex = 0;
  var unitWriter = AstBinaryWriter(
    withInformative: true,
    sink: sink,
    stringIndexer: stringIndexer,
    getNextResolutionIndex: () => nextResolutionIndex++,
    resolutionSink: null,
  );
  unit.accept(unitWriter);

  void _writeStringReference(String string) {
    var index = stringIndexer[string];
    sink.writeUInt30(index);
  }

  var indexOffset = sink.offset;
  sink.writeUInt30(unitWriter.unitMemberIndexItems.length);
  for (var declaration in unitWriter.unitMemberIndexItems) {
    sink.writeUInt30(declaration.offset);
    sink.writeByte(declaration.tag);
    if (declaration.name != null) {
      _writeStringReference(declaration.name);
    } else {
      sink.writeList(declaration.variableNames, _writeStringReference);
    }
    if (declaration.classIndexOffset != 0) {
      sink.writeUInt30(declaration.classIndexOffset);
    }
  }

  var libraryDataOffset = sink.offset;
  {
    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        name = directive.name.components.map((e) => e.name).join('.');
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }

    var hasPartOfDirective = false;
    for (var directive in unit.directives) {
      if (directive is PartOfDirective) {
        hasPartOfDirective = true;
        break;
      }
    }
    _writeStringReference(name);
    sink.writeUInt30(nameOffset + 1);
    sink.writeUInt30(nameLength);
    sink.writeByte(hasPartOfDirective ? 1 : 0);
    sink.writeByte(1); // withInformative
  }

  var stringTableOffset = stringIndexer.write(sink);

  sink.writeUInt32(headerOffset);
  sink.writeUInt32(indexOffset);
  sink.writeUInt32(libraryDataOffset);
  sink.writeUInt32(stringTableOffset);

  sink.flushAndDestroy();
  return byteSink.builder.takeBytes();
}

class BundleWriter {
  final bool withInformative;
  BundleWriterAst _astWriter;
  BundleWriterResolution _resolutionWriter;

  BundleWriter(this.withInformative, Reference dynamicReference) {
    _astWriter = BundleWriterAst(withInformative);
    _resolutionWriter = BundleWriterResolution(dynamicReference);
  }

  void addLibraryAst(LibraryToWriteAst library) {
    var astUnitOffsets = <int>[];
    for (var unit in library.units) {
      var offset = _astWriter.writeUnit(unit.node);
      astUnitOffsets.add(offset);
    }
    _astWriter.writeLibrary(library.units[0].node, astUnitOffsets);
  }

  void addLibraryResolution(LibraryToWriteResolution library) {
    var resolutionLibrary = _resolutionWriter.enterLibrary(library);
    for (var unit in library.units) {
      var resolutionUnit = resolutionLibrary.enterUnit(unit);
      // TODO(scheglov) Is it better to have a throwaway Object, or null?
      var notUsedSink = BufferedSink(ByteSink());
      var notUsedStringIndexer = StringIndexer();
      var unitWriter = AstBinaryWriter(
        withInformative: withInformative,
        sink: notUsedSink,
        stringIndexer: notUsedStringIndexer,
        getNextResolutionIndex: resolutionUnit.enterDeclaration,
        resolutionSink: resolutionUnit.library.sink,
      );
      unit.node.accept(unitWriter);
    }
  }

  BundleWriterResult finish() {
    var astBytes = _astWriter.finish();
    var resolutionBytes = _resolutionWriter.finish();
    return BundleWriterResult(
      astBytes: astBytes,
      resolutionBytes: resolutionBytes,
    );
  }
}

class BundleWriterAst {
  final bool withInformative;
  final ByteSink _byteSink = ByteSink();
  BufferedSink sink;
  final StringIndexer stringIndexer = StringIndexer();

  final List<int> _libraryOffsets = [];

  BundleWriterAst(this.withInformative) {
    sink = BufferedSink(_byteSink);
    sink.writeByte(withInformative ? 1 : 0);
  }

  Uint8List finish() {
    var librariesOffset = sink.offset;
    sink.writeUint30List(_libraryOffsets);

    var stringTableOffset = stringIndexer.write(sink);

    sink.writeUInt32(librariesOffset);
    sink.writeUInt32(stringTableOffset);

    sink.flushAndDestroy();
    return _byteSink.builder.takeBytes();
  }

  /// Write the library name and offset, and pointers to [unitOffsets].
  void writeLibrary(CompilationUnit definingUnit, List<int> unitOffsets) {
    _libraryOffsets.add(sink.offset);

    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in definingUnit.directives) {
      if (directive is LibraryDirective) {
        name = directive.name.components.map((e) => e.name).join('.');
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }

    var hasPartOfDirective = false;
    for (var directive in definingUnit.directives) {
      if (directive is PartOfDirective) {
        hasPartOfDirective = true;
        break;
      }
    }

    _writeStringReference(name);
    sink.writeUInt30(1 + nameOffset);
    sink.writeUInt30(nameLength);
    sink.writeByte(hasPartOfDirective ? 1 : 0);
    sink.writeUint30List(unitOffsets);
  }

  /// Write the [node] into the [sink].
  ///
  /// Return the pointer at [AstUnitFormat.headerOffset].
  int writeUnit(CompilationUnit node) {
    var headerOffset = sink.offset;

    var nextResolutionIndex = 0;
    var unitWriter = AstBinaryWriter(
      withInformative: withInformative,
      sink: sink,
      stringIndexer: stringIndexer,
      getNextResolutionIndex: () => nextResolutionIndex++,
      resolutionSink: null,
    );
    node.accept(unitWriter);

    var indexOffset = sink.offset;
    sink.writeUInt30(headerOffset);

    sink.writeUInt30(unitWriter.unitMemberIndexItems.length);
    for (var declaration in unitWriter.unitMemberIndexItems) {
      sink.writeUInt30(declaration.offset);
      sink.writeByte(declaration.tag);
      if (declaration.name != null) {
        _writeStringReference(declaration.name);
      } else {
        sink.writeList(declaration.variableNames, _writeStringReference);
      }
      if (declaration.classIndexOffset != 0) {
        sink.writeUInt30(declaration.classIndexOffset);
      }
    }

    return indexOffset;
  }

  void _writeStringReference(String string) {
    var index = stringIndexer[string];
    sink.writeUInt30(index);
  }
}

class BundleWriterResolution {
  _BundleWriterReferences _references;
  final ByteSink _byteSink = ByteSink();
  BufferedSink _sink;
  ResolutionSink _resolutionSink;

  final StringIndexer _stringIndexer = StringIndexer();

  final List<_ResolutionLibrary> _libraries = [];

  BundleWriterResolution(Reference dynamicReference) {
    _references = _BundleWriterReferences(dynamicReference);

    _sink = BufferedSink(_byteSink);
    _resolutionSink = ResolutionSink(
      stringIndexer: _stringIndexer,
      sink: _sink,
      references: _references,
    );
  }

  _ResolutionLibrary enterLibrary(LibraryToWriteResolution libraryToWrite) {
    var library = _ResolutionLibrary(
      sink: _resolutionSink,
      library: libraryToWrite,
    );
    _libraries.add(library);
    return library;
  }

  Uint8List finish() {
    var libraryOffsets = <int>[];
    for (var library in _libraries) {
      var unitOffsets = <int>[];
      for (var unit in library.units) {
        unitOffsets.add(_sink.offset);
        _writeStringReference(unit.unit.uriStr);
        _sink.writeByte(unit.unit.isSynthetic ? 1 : 0);
        _sink.writeByte(unit.unit.partUriStr != null ? 1 : 0);
        _writeStringReference(unit.unit.partUriStr ?? '');
        _sink.writeUInt30(unit.directivesOffset);
        _sink.writeUint30List(unit.offsets);
      }
      libraryOffsets.add(_sink.offset);
      _writeStringReference(library.library.uriStr);
      _sink.writeUint30List(unitOffsets);
      _writeReferences(library.library.exports);
    }

    _references._clearIndexes();

    var librariesOffset = _sink.offset;
    _sink.writeUint30List(libraryOffsets);

    var referencesOffset = _sink.offset;
    _sink.writeUint30List(_references._referenceParents);
    _writeStringList(_references._referenceNames);

    var stringTableOffset = _stringIndexer.write(_sink);

    // Write as Uint32 so that we know where it is.
    _sink.writeUInt32(librariesOffset);
    _sink.writeUInt32(referencesOffset);
    _sink.writeUInt32(stringTableOffset);

    _sink.flushAndDestroy();
    return _byteSink.builder.takeBytes();
  }

  void _writeReferences(List<Reference> references) {
    var length = references.length;
    _sink.writeUInt30(length);

    for (var reference in references) {
      var index = _references._indexOfReference(reference);
      _sink.writeUInt30(index);
    }
  }

  void _writeStringList(List<String> values) {
    _sink.writeUInt30(values.length);
    for (var value in values) {
      _writeStringReference(value);
    }
  }

  void _writeStringReference(String string) {
    var index = _stringIndexer[string];
    _sink.writeUInt30(index);
  }
}

class BundleWriterResult {
  final Uint8List astBytes;
  final Uint8List resolutionBytes;

  BundleWriterResult({
    @required this.astBytes,
    @required this.resolutionBytes,
  });
}

class LibraryToWriteAst {
  final List<UnitToWriteAst> units;

  LibraryToWriteAst({
    @required this.units,
  });
}

class LibraryToWriteResolution {
  final String uriStr;
  final List<Reference> exports;
  final List<UnitToWriteResolution> units;

  LibraryToWriteResolution({
    @required this.uriStr,
    @required this.exports,
    @required this.units,
  });
}

class ResolutionSink {
  final StringIndexer _stringIndexer;
  final BufferedSink _sink;
  final _BundleWriterReferences _references2;
  final _LocalElementIndexer localElements = _LocalElementIndexer();

  ResolutionSink({
    @required StringIndexer stringIndexer,
    @required BufferedSink sink,
    @required _BundleWriterReferences references,
  })  : _stringIndexer = stringIndexer,
        _sink = sink,
        _references2 = references;

  int get offset => _sink.offset;

  void writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _sink.addByte(byte);
  }

  /// TODO(scheglov) Triage places where we write elements.
  /// Some of then cannot be members, e.g. type names.
  void writeElement(Element element) {
    if (element is Member) {
      var declaration = element.declaration;
      var isLegacy = element.isLegacy;

      var typeArguments = _enclosingClassTypeArguments(
        declaration,
        element.substitution.map,
      );

      writeByte(
        isLegacy
            ? Tag.MemberLegacyWithTypeArguments
            : Tag.MemberWithTypeArguments,
      );

      writeElement0(declaration);
      _writeTypeList(typeArguments);
    } else {
      writeByte(Tag.RawElement);
      writeElement0(element);
    }
  }

  void writeElement0(Element element) {
    assert(element is! Member, 'Use writeMemberOrElement()');
    var elementIndex = _indexOfElement(element);
    _sink.writeUInt30(elementIndex);
  }

  void writeStringList(List<String> values) {
    _sink.writeUInt30(values.length);
    for (var value in values) {
      _writeStringReference(value);
    }
  }

  void writeType(DartType type) {
    if (type == null) {
      writeByte(Tag.NullType);
    } else if (type is DynamicType) {
      writeByte(Tag.DynamicType);
    } else if (type is FunctionType) {
      _writeFunctionType(type);
    } else if (type is InterfaceType) {
      var typeArguments = type.typeArguments;
      var nullabilitySuffix = type.nullabilitySuffix;
      if (typeArguments.isEmpty) {
        if (nullabilitySuffix == NullabilitySuffix.none) {
          writeByte(Tag.InterfaceType_noTypeArguments_none);
        } else if (nullabilitySuffix == NullabilitySuffix.question) {
          writeByte(Tag.InterfaceType_noTypeArguments_question);
        } else if (nullabilitySuffix == NullabilitySuffix.star) {
          writeByte(Tag.InterfaceType_noTypeArguments_star);
        }
        // TODO(scheglov) Write raw
        writeElement(type.element);
      } else {
        writeByte(Tag.InterfaceType);
        // TODO(scheglov) Write raw
        writeElement(type.element);
        _sink.writeUInt30(typeArguments.length);
        for (var i = 0; i < typeArguments.length; ++i) {
          writeType(typeArguments[i]);
        }
        _writeNullabilitySuffix(nullabilitySuffix);
      }
    } else if (type is NeverType) {
      writeByte(Tag.NeverType);
      _writeNullabilitySuffix(type.nullabilitySuffix);
    } else if (type is TypeParameterType) {
      writeByte(Tag.TypeParameterType);
      writeElement(type.element);
      _writeNullabilitySuffix(type.nullabilitySuffix);
    } else if (type is VoidType) {
      writeByte(Tag.VoidType);
    } else {
      // TODO
      throw UnimplementedError('${type.runtimeType}');
    }
  }

  void writeUInt30(int value) {
    _sink.writeUInt30(value);
  }

  int _indexOfElement(Element element) {
    if (element == null) return 0;
    if (element is MultiplyDefinedElement) return 0;
    assert(element is! Member);

    // Positional parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is ParameterElementImpl && element.reference == null) {
      return localElements[element] << 1 | 0x1;
    }

    // Type parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is TypeParameterElement) {
      return localElements[element] << 1 | 0x1;
    }

    if (identical(element, DynamicElementImpl.instance)) {
      return _references2._indexOfReference(_references2.dynamicReference) << 1;
    }

    var reference = (element as ElementImpl).reference;
    return _references2._indexOfReference(reference) << 1;
  }

  void _writeFormalParameterKind(ParameterElement p) {
    if (p.isRequiredPositional) {
      writeByte(Tag.ParameterKindRequiredPositional);
    } else if (p.isOptionalPositional) {
      writeByte(Tag.ParameterKindOptionalPositional);
    } else if (p.isRequiredNamed) {
      writeByte(Tag.ParameterKindRequiredNamed);
    } else if (p.isOptionalNamed) {
      writeByte(Tag.ParameterKindOptionalNamed);
    } else {
      throw StateError('Unexpected parameter kind: $p');
    }
  }

  void _writeFunctionType(FunctionType type) {
    type = _toSyntheticFunctionType(type);

    writeByte(Tag.FunctionType);

    localElements.pushScope();

    var typeParameters = type.typeFormals;
    for (var typeParameter in type.typeFormals) {
      localElements.declare(typeParameter);
    }

    _sink.writeUInt30(typeParameters.length);
    for (var typeParameter in type.typeFormals) {
      _writeStringReference(typeParameter.name);
    }
    for (var typeParameter in type.typeFormals) {
      writeType(typeParameter.bound);
    }

    Element typedefElement;
    List<DartType> typedefTypeArguments = const <DartType>[];
    if (type.element is FunctionTypeAliasElement) {
      typedefElement = type.element;
      typedefTypeArguments = type.typeArguments;
    }
    // TODO(scheglov) Cleanup to always use FunctionTypeAliasElement.
    if (type.element is GenericFunctionTypeElement &&
        type.element.enclosingElement is FunctionTypeAliasElement) {
      typedefElement = type.element.enclosingElement;
      typedefTypeArguments = type.typeArguments;
    }

    writeElement(typedefElement);
    _writeTypeList(typedefTypeArguments);

    writeType(type.returnType);

    var parameters = type.parameters;
    _sink.writeUInt30(parameters.length);
    for (var parameter in parameters) {
      _writeFormalParameterKind(parameter);
      assert(parameter.type != null);
      writeType(parameter.type);
      // TODO(scheglov) Don't write names of positional parameters
      _writeStringReference(parameter.name);
    }

    _writeNullabilitySuffix(type.nullabilitySuffix);

    localElements.popScope();
  }

  void _writeNullabilitySuffix(NullabilitySuffix suffix) {
    writeByte(suffix.index);
  }

  void _writeStringReference(String string) {
    var index = _stringIndexer[string];
    _sink.writeUInt30(index);
  }

  void _writeTypeList(List<DartType> types) {
    _sink.writeUInt30(types.length);
    for (var type in types) {
      writeType(type);
    }
  }

  static List<DartType> _enclosingClassTypeArguments(
    Element declaration,
    Map<TypeParameterElement, DartType> substitution,
  ) {
    var enclosing = declaration.enclosingElement;
    if (enclosing is TypeParameterizedElement) {
      if (enclosing is! ClassElement && enclosing is! ExtensionElement) {
        return const <DartType>[];
      }

      var typeParameters = enclosing.typeParameters;
      if (typeParameters.isEmpty) {
        return const <DartType>[];
      }

      return typeParameters
          .map((typeParameter) => substitution[typeParameter])
          .toList(growable: false);
    }

    return const <DartType>[];
  }

  static FunctionType _toSyntheticFunctionType(FunctionType type) {
    var typeParameters = type.typeFormals;

    if (typeParameters.isEmpty) return type;

    var onlySyntheticTypeParameters = typeParameters.every((e) {
      return e is TypeParameterElementImpl && e.linkedNode == null;
    });
    if (onlySyntheticTypeParameters) return type;

    var parameters = getFreshTypeParameters(typeParameters);
    return parameters.applyToFunctionType(type);
  }
}

class ResolutionUnit {
  final _ResolutionLibrary library;
  final UnitToWriteResolution unit;

  /// The offset of the resolution data for directives.
  final int directivesOffset;

  /// The offsets of resolution data for each declaration - class, method, etc.
  final List<int> offsets = [];

  ResolutionUnit({
    @required this.library,
    @required this.unit,
    @required this.directivesOffset,
  });

  /// Should be called on enter into a new declaration on which level
  /// resolution is stored, e.g. [ClassDeclaration] (header), or
  /// [MethodDeclaration] (header), or [FieldDeclaration] (all).
  int enterDeclaration() {
    var index = offsets.length;
    offsets.add(library.sink.offset);
    return index;
  }
}

class StringIndexer {
  final Map<String, int> _index = {};

  int operator [](String string) {
    var result = _index[string];

    if (result == null) {
      result = _index.length;
      _index[string] = result;
    }

    return result;
  }

  int write(BufferedSink sink) {
    var bytesOffset = sink.offset;

    var length = _index.length;
    var lengths = Uint32List(length);
    var lengthsIndex = 0;
    for (var key in _index.keys) {
      var stringStart = sink.offset;
      _writeWtf8(sink, key);
      lengths[lengthsIndex++] = sink.offset - stringStart;
    }

    var resultOffset = sink.offset;

    var lengthOfBytes = sink.offset - bytesOffset;
    sink.writeUInt30(lengthOfBytes);
    sink.writeUint30List(lengths);

    return resultOffset;
  }

  /// Write [source] string into [sink].
  static void _writeWtf8(BufferedSink sink, String source) {
    var end = source.length;
    if (end == 0) {
      return;
    }

    int i = 0;
    do {
      var codeUnit = source.codeUnitAt(i++);
      if (codeUnit < 128) {
        // ASCII.
        sink.addByte(codeUnit);
      } else if (codeUnit < 0x800) {
        // Two-byte sequence (11-bit unicode value).
        sink.addByte(0xC0 | (codeUnit >> 6));
        sink.addByte(0x80 | (codeUnit & 0x3f));
      } else if ((codeUnit & 0xFC00) == 0xD800 &&
          i < end &&
          (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
        // Surrogate pair -> four-byte sequence (non-BMP unicode value).
        int codeUnit2 = source.codeUnitAt(i++);
        int unicode =
            0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
        sink.addByte(0xF0 | (unicode >> 18));
        sink.addByte(0x80 | ((unicode >> 12) & 0x3F));
        sink.addByte(0x80 | ((unicode >> 6) & 0x3F));
        sink.addByte(0x80 | (unicode & 0x3F));
      } else {
        // Three-byte sequence (16-bit unicode value), including lone
        // surrogates.
        sink.addByte(0xE0 | (codeUnit >> 12));
        sink.addByte(0x80 | ((codeUnit >> 6) & 0x3f));
        sink.addByte(0x80 | (codeUnit & 0x3f));
      }
    } while (i < end);
  }
}

class UnitToWriteAst {
  final CompilationUnit node;

  UnitToWriteAst({
    @required this.node,
  });
}

class UnitToWriteResolution {
  final String uriStr;
  final String partUriStr;
  final CompilationUnit node;
  final bool isSynthetic;

  UnitToWriteResolution({
    @required this.uriStr,
    @required this.partUriStr,
    @required this.node,
    @required this.isSynthetic,
  });
}

class _BundleWriterReferences {
  /// The `dynamic` class is declared in `dart:core`, but is not a class.
  /// Also, it is static, so we cannot set `reference` for it.
  /// So, we have to push it in a separate way.
  final Reference dynamicReference;

  /// References used in all libraries being linked.
  /// Element references in nodes are indexes in this list.
  final List<Reference> references = [null];

  final List<int> _referenceParents = [0];
  final List<String> _referenceNames = [''];

  _BundleWriterReferences(this.dynamicReference);

  /// We need indexes for references during linking, but once we are done,
  /// we must clear indexes to make references ready for linking a next bundle.
  void _clearIndexes() {
    for (var reference in references) {
      if (reference != null) {
        reference.index = null;
      }
    }
  }

  int _indexOfReference(Reference reference) {
    if (reference == null) return 0;
    if (reference.parent == null) return 0;
    if (reference.index != null) return reference.index;

    var parentIndex = _indexOfReference(reference.parent);
    _referenceParents.add(parentIndex);
    _referenceNames.add(reference.name);

    reference.index = references.length;
    references.add(reference);
    return reference.index;
  }
}

class _LocalElementIndexer {
  final Map<Element, int> _index = Map.identity();
  final List<int> _scopes = [];
  int _stackHeight = 0;

  int operator [](Element element) {
    return _index[element] ??
        (throw ArgumentError('Unexpectedly not indexed: $element'));
  }

  void declare(Element element) {
    _index[element] = _stackHeight++;
  }

  void popScope() {
    _stackHeight = _scopes.removeLast();
  }

  void pushScope() {
    _scopes.add(_stackHeight);
  }
}

class _ResolutionLibrary {
  final ResolutionSink sink;
  final LibraryToWriteResolution library;
  final List<ResolutionUnit> units = [];

  _ResolutionLibrary({
    @required this.sink,
    @required this.library,
  });

  ResolutionUnit enterUnit(UnitToWriteResolution unitToWrite) {
    var unit = ResolutionUnit(
      library: this,
      unit: unitToWrite,
      directivesOffset: sink.offset,
    );
    units.add(unit);
    return unit;
  }
}
