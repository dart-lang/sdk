// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the SDK script
// "pkg/analyzer/tool/summary/generate.dart $IDL_FILE_PATH",
// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.

library analyzer.src.summary.format;

import 'dart:convert' as convert;

import 'package:analyzer/src/summary/api_signature.dart' as api_sig;
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;

import 'idl.dart' as idl;

class _AvailableDeclarationKindReader
    extends fb.Reader<idl.AvailableDeclarationKind> {
  const _AvailableDeclarationKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.AvailableDeclarationKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.AvailableDeclarationKind.values.length
        ? idl.AvailableDeclarationKind.values[index]
        : idl.AvailableDeclarationKind.CLASS;
  }
}

class _EntityRefKindReader extends fb.Reader<idl.EntityRefKind> {
  const _EntityRefKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.EntityRefKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.EntityRefKind.values.length
        ? idl.EntityRefKind.values[index]
        : idl.EntityRefKind.named;
  }
}

class _EntityRefNullabilitySuffixReader
    extends fb.Reader<idl.EntityRefNullabilitySuffix> {
  const _EntityRefNullabilitySuffixReader() : super();

  @override
  int get size => 1;

  @override
  idl.EntityRefNullabilitySuffix read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.EntityRefNullabilitySuffix.values.length
        ? idl.EntityRefNullabilitySuffix.values[index]
        : idl.EntityRefNullabilitySuffix.starOrIrrelevant;
  }
}

class _IndexNameKindReader extends fb.Reader<idl.IndexNameKind> {
  const _IndexNameKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.IndexNameKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.IndexNameKind.values.length
        ? idl.IndexNameKind.values[index]
        : idl.IndexNameKind.topLevel;
  }
}

class _IndexRelationKindReader extends fb.Reader<idl.IndexRelationKind> {
  const _IndexRelationKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.IndexRelationKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.IndexRelationKind.values.length
        ? idl.IndexRelationKind.values[index]
        : idl.IndexRelationKind.IS_ANCESTOR_OF;
  }
}

class _IndexSyntheticElementKindReader
    extends fb.Reader<idl.IndexSyntheticElementKind> {
  const _IndexSyntheticElementKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.IndexSyntheticElementKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.IndexSyntheticElementKind.values.length
        ? idl.IndexSyntheticElementKind.values[index]
        : idl.IndexSyntheticElementKind.notSynthetic;
  }
}

class _LinkedNodeCommentTypeReader
    extends fb.Reader<idl.LinkedNodeCommentType> {
  const _LinkedNodeCommentTypeReader() : super();

  @override
  int get size => 1;

  @override
  idl.LinkedNodeCommentType read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.LinkedNodeCommentType.values.length
        ? idl.LinkedNodeCommentType.values[index]
        : idl.LinkedNodeCommentType.block;
  }
}

class _LinkedNodeFormalParameterKindReader
    extends fb.Reader<idl.LinkedNodeFormalParameterKind> {
  const _LinkedNodeFormalParameterKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.LinkedNodeFormalParameterKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.LinkedNodeFormalParameterKind.values.length
        ? idl.LinkedNodeFormalParameterKind.values[index]
        : idl.LinkedNodeFormalParameterKind.requiredPositional;
  }
}

class _LinkedNodeKindReader extends fb.Reader<idl.LinkedNodeKind> {
  const _LinkedNodeKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.LinkedNodeKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.LinkedNodeKind.values.length
        ? idl.LinkedNodeKind.values[index]
        : idl.LinkedNodeKind.adjacentStrings;
  }
}

class _LinkedNodeTypeKindReader extends fb.Reader<idl.LinkedNodeTypeKind> {
  const _LinkedNodeTypeKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.LinkedNodeTypeKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.LinkedNodeTypeKind.values.length
        ? idl.LinkedNodeTypeKind.values[index]
        : idl.LinkedNodeTypeKind.bottom;
  }
}

class _ReferenceKindReader extends fb.Reader<idl.ReferenceKind> {
  const _ReferenceKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.ReferenceKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.ReferenceKind.values.length
        ? idl.ReferenceKind.values[index]
        : idl.ReferenceKind.classOrEnum;
  }
}

class _TopLevelInferenceErrorKindReader
    extends fb.Reader<idl.TopLevelInferenceErrorKind> {
  const _TopLevelInferenceErrorKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.TopLevelInferenceErrorKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.TopLevelInferenceErrorKind.values.length
        ? idl.TopLevelInferenceErrorKind.values[index]
        : idl.TopLevelInferenceErrorKind.assignment;
  }
}

class _TypedefStyleReader extends fb.Reader<idl.TypedefStyle> {
  const _TypedefStyleReader() : super();

  @override
  int get size => 1;

  @override
  idl.TypedefStyle read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.TypedefStyle.values.length
        ? idl.TypedefStyle.values[index]
        : idl.TypedefStyle.functionType;
  }
}

class _UnlinkedConstructorInitializerKindReader
    extends fb.Reader<idl.UnlinkedConstructorInitializerKind> {
  const _UnlinkedConstructorInitializerKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedConstructorInitializerKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedConstructorInitializerKind.values.length
        ? idl.UnlinkedConstructorInitializerKind.values[index]
        : idl.UnlinkedConstructorInitializerKind.field;
  }
}

class _UnlinkedExecutableKindReader
    extends fb.Reader<idl.UnlinkedExecutableKind> {
  const _UnlinkedExecutableKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedExecutableKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedExecutableKind.values.length
        ? idl.UnlinkedExecutableKind.values[index]
        : idl.UnlinkedExecutableKind.functionOrMethod;
  }
}

class _UnlinkedExprAssignOperatorReader
    extends fb.Reader<idl.UnlinkedExprAssignOperator> {
  const _UnlinkedExprAssignOperatorReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedExprAssignOperator read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedExprAssignOperator.values.length
        ? idl.UnlinkedExprAssignOperator.values[index]
        : idl.UnlinkedExprAssignOperator.assign;
  }
}

class _UnlinkedExprOperationReader
    extends fb.Reader<idl.UnlinkedExprOperation> {
  const _UnlinkedExprOperationReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedExprOperation read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedExprOperation.values.length
        ? idl.UnlinkedExprOperation.values[index]
        : idl.UnlinkedExprOperation.pushInt;
  }
}

class _UnlinkedParamKindReader extends fb.Reader<idl.UnlinkedParamKind> {
  const _UnlinkedParamKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedParamKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedParamKind.values.length
        ? idl.UnlinkedParamKind.values[index]
        : idl.UnlinkedParamKind.requiredPositional;
  }
}

class _UnlinkedTokenKindReader extends fb.Reader<idl.UnlinkedTokenKind> {
  const _UnlinkedTokenKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedTokenKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedTokenKind.values.length
        ? idl.UnlinkedTokenKind.values[index]
        : idl.UnlinkedTokenKind.nothing;
  }
}

class _UnlinkedTokenTypeReader extends fb.Reader<idl.UnlinkedTokenType> {
  const _UnlinkedTokenTypeReader() : super();

  @override
  int get size => 1;

  @override
  idl.UnlinkedTokenType read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.UnlinkedTokenType.values.length
        ? idl.UnlinkedTokenType.values[index]
        : idl.UnlinkedTokenType.NOTHING;
  }
}

class AnalysisDriverExceptionContextBuilder extends Object
    with _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  String _exception;
  List<AnalysisDriverExceptionFileBuilder> _files;
  String _path;
  String _stackTrace;

  @override
  String get exception => _exception ??= '';

  /// The exception string.
  set exception(String value) {
    this._exception = value;
  }

  @override
  List<AnalysisDriverExceptionFileBuilder> get files =>
      _files ??= <AnalysisDriverExceptionFileBuilder>[];

  /// The state of files when the exception happened.
  set files(List<AnalysisDriverExceptionFileBuilder> value) {
    this._files = value;
  }

  @override
  String get path => _path ??= '';

  /// The path of the file being analyzed when the exception happened.
  set path(String value) {
    this._path = value;
  }

  @override
  String get stackTrace => _stackTrace ??= '';

  /// The exception stack trace string.
  set stackTrace(String value) {
    this._stackTrace = value;
  }

  AnalysisDriverExceptionContextBuilder(
      {String exception,
      List<AnalysisDriverExceptionFileBuilder> files,
      String path,
      String stackTrace})
      : _exception = exception,
        _files = files,
        _path = path,
        _stackTrace = stackTrace;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _files?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._path ?? '');
    signature.addString(this._exception ?? '');
    signature.addString(this._stackTrace ?? '');
    if (this._files == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._files.length);
      for (var x in this._files) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADEC");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_exception;
    fb.Offset offset_files;
    fb.Offset offset_path;
    fb.Offset offset_stackTrace;
    if (_exception != null) {
      offset_exception = fbBuilder.writeString(_exception);
    }
    if (!(_files == null || _files.isEmpty)) {
      offset_files =
          fbBuilder.writeList(_files.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_path != null) {
      offset_path = fbBuilder.writeString(_path);
    }
    if (_stackTrace != null) {
      offset_stackTrace = fbBuilder.writeString(_stackTrace);
    }
    fbBuilder.startTable();
    if (offset_exception != null) {
      fbBuilder.addOffset(1, offset_exception);
    }
    if (offset_files != null) {
      fbBuilder.addOffset(3, offset_files);
    }
    if (offset_path != null) {
      fbBuilder.addOffset(0, offset_path);
    }
    if (offset_stackTrace != null) {
      fbBuilder.addOffset(2, offset_stackTrace);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverExceptionContext readAnalysisDriverExceptionContext(
    List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverExceptionContextReader().read(rootRef, 0);
}

class _AnalysisDriverExceptionContextReader
    extends fb.TableReader<_AnalysisDriverExceptionContextImpl> {
  const _AnalysisDriverExceptionContextReader();

  @override
  _AnalysisDriverExceptionContextImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _AnalysisDriverExceptionContextImpl(bc, offset);
}

class _AnalysisDriverExceptionContextImpl extends Object
    with _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionContextImpl(this._bc, this._bcOffset);

  String _exception;
  List<idl.AnalysisDriverExceptionFile> _files;
  String _path;
  String _stackTrace;

  @override
  String get exception {
    _exception ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _exception;
  }

  @override
  List<idl.AnalysisDriverExceptionFile> get files {
    _files ??= const fb.ListReader<idl.AnalysisDriverExceptionFile>(
            const _AnalysisDriverExceptionFileReader())
        .vTableGet(
            _bc, _bcOffset, 3, const <idl.AnalysisDriverExceptionFile>[]);
    return _files;
  }

  @override
  String get path {
    _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _path;
  }

  @override
  String get stackTrace {
    _stackTrace ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _stackTrace;
  }
}

abstract class _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (exception != '') _result["exception"] = exception;
    if (files.isNotEmpty)
      _result["files"] = files.map((_value) => _value.toJson()).toList();
    if (path != '') _result["path"] = path;
    if (stackTrace != '') _result["stackTrace"] = stackTrace;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "exception": exception,
        "files": files,
        "path": path,
        "stackTrace": stackTrace,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverExceptionFileBuilder extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  String _content;
  String _path;

  @override
  String get content => _content ??= '';

  /// The content of the file.
  set content(String value) {
    this._content = value;
  }

  @override
  String get path => _path ??= '';

  /// The path of the file.
  set path(String value) {
    this._path = value;
  }

  AnalysisDriverExceptionFileBuilder({String content, String path})
      : _content = content,
        _path = path;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._path ?? '');
    signature.addString(this._content ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_content;
    fb.Offset offset_path;
    if (_content != null) {
      offset_content = fbBuilder.writeString(_content);
    }
    if (_path != null) {
      offset_path = fbBuilder.writeString(_path);
    }
    fbBuilder.startTable();
    if (offset_content != null) {
      fbBuilder.addOffset(1, offset_content);
    }
    if (offset_path != null) {
      fbBuilder.addOffset(0, offset_path);
    }
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverExceptionFileReader
    extends fb.TableReader<_AnalysisDriverExceptionFileImpl> {
  const _AnalysisDriverExceptionFileReader();

  @override
  _AnalysisDriverExceptionFileImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _AnalysisDriverExceptionFileImpl(bc, offset);
}

class _AnalysisDriverExceptionFileImpl extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionFileImpl(this._bc, this._bcOffset);

  String _content;
  String _path;

  @override
  String get content {
    _content ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _content;
  }

  @override
  String get path {
    _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _path;
  }
}

abstract class _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (content != '') _result["content"] = content;
    if (path != '') _result["path"] = path;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "content": content,
        "path": path,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverResolvedUnitBuilder extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  List<AnalysisDriverUnitErrorBuilder> _errors;
  AnalysisDriverUnitIndexBuilder _index;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  /// The full list of analysis errors, both syntactic and semantic.
  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  @override
  AnalysisDriverUnitIndexBuilder get index => _index;

  /// The index of the unit.
  set index(AnalysisDriverUnitIndexBuilder value) {
    this._index = value;
  }

  AnalysisDriverResolvedUnitBuilder(
      {List<AnalysisDriverUnitErrorBuilder> errors,
      AnalysisDriverUnitIndexBuilder index})
      : _errors = errors,
        _index = index;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
    _index?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._errors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errors.length);
      for (var x in this._errors) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._index != null);
    this._index?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADRU");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_errors;
    fb.Offset offset_index;
    if (!(_errors == null || _errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(_errors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_index != null) {
      offset_index = _index.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
    }
    if (offset_index != null) {
      fbBuilder.addOffset(1, offset_index);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverResolvedUnit readAnalysisDriverResolvedUnit(
    List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverResolvedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverResolvedUnitReader
    extends fb.TableReader<_AnalysisDriverResolvedUnitImpl> {
  const _AnalysisDriverResolvedUnitReader();

  @override
  _AnalysisDriverResolvedUnitImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _AnalysisDriverResolvedUnitImpl(bc, offset);
}

class _AnalysisDriverResolvedUnitImpl extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverResolvedUnitImpl(this._bc, this._bcOffset);

  List<idl.AnalysisDriverUnitError> _errors;
  idl.AnalysisDriverUnitIndex _index;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
            const _AnalysisDriverUnitErrorReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AnalysisDriverUnitError>[]);
    return _errors;
  }

  @override
  idl.AnalysisDriverUnitIndex get index {
    _index ??= const _AnalysisDriverUnitIndexReader()
        .vTableGet(_bc, _bcOffset, 1, null);
    return _index;
  }
}

abstract class _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (errors.isNotEmpty)
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    if (index != null) _result["index"] = index.toJson();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "errors": errors,
        "index": index,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverSubtypeBuilder extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  List<int> _members;
  int _name;

  @override
  List<int> get members => _members ??= <int>[];

  /// The names of defined instance members.
  /// They are indexes into [AnalysisDriverUnitError.strings] list.
  /// The list is sorted in ascending order.
  set members(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._members = value;
  }

  @override
  int get name => _name ??= 0;

  /// The name of the class.
  /// It is an index into [AnalysisDriverUnitError.strings] list.
  set name(int value) {
    assert(value == null || value >= 0);
    this._name = value;
  }

  AnalysisDriverSubtypeBuilder({List<int> members, int name})
      : _members = members,
        _name = name;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._name ?? 0);
    if (this._members == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._members.length);
      for (var x in this._members) {
        signature.addInt(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_members;
    if (!(_members == null || _members.isEmpty)) {
      offset_members = fbBuilder.writeListUint32(_members);
    }
    fbBuilder.startTable();
    if (offset_members != null) {
      fbBuilder.addOffset(1, offset_members);
    }
    if (_name != null && _name != 0) {
      fbBuilder.addUint32(0, _name);
    }
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverSubtypeReader
    extends fb.TableReader<_AnalysisDriverSubtypeImpl> {
  const _AnalysisDriverSubtypeReader();

  @override
  _AnalysisDriverSubtypeImpl createObject(fb.BufferContext bc, int offset) =>
      new _AnalysisDriverSubtypeImpl(bc, offset);
}

class _AnalysisDriverSubtypeImpl extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverSubtypeImpl(this._bc, this._bcOffset);

  List<int> _members;
  int _name;

  @override
  List<int> get members {
    _members ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
    return _members;
  }

  @override
  int get name {
    _name ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _name;
  }
}

abstract class _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (members.isNotEmpty) _result["members"] = members;
    if (name != 0) _result["name"] = name;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "members": members,
        "name": name,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnitErrorBuilder extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  String _correction;
  int _length;
  String _message;
  int _offset;
  String _uniqueName;

  @override
  String get correction => _correction ??= '';

  /// The optional correction hint for the error.
  set correction(String value) {
    this._correction = value;
  }

  @override
  int get length => _length ??= 0;

  /// The length of the error in the file.
  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  /// The message of the error.
  set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// The offset from the beginning of the file.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  String get uniqueName => _uniqueName ??= '';

  /// The unique name of the error code.
  set uniqueName(String value) {
    this._uniqueName = value;
  }

  AnalysisDriverUnitErrorBuilder(
      {String correction,
      int length,
      String message,
      int offset,
      String uniqueName})
      : _correction = correction,
        _length = length,
        _message = message,
        _offset = offset,
        _uniqueName = uniqueName;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
    signature.addString(this._uniqueName ?? '');
    signature.addString(this._message ?? '');
    signature.addString(this._correction ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_correction;
    fb.Offset offset_message;
    fb.Offset offset_uniqueName;
    if (_correction != null) {
      offset_correction = fbBuilder.writeString(_correction);
    }
    if (_message != null) {
      offset_message = fbBuilder.writeString(_message);
    }
    if (_uniqueName != null) {
      offset_uniqueName = fbBuilder.writeString(_uniqueName);
    }
    fbBuilder.startTable();
    if (offset_correction != null) {
      fbBuilder.addOffset(4, offset_correction);
    }
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(1, _length);
    }
    if (offset_message != null) {
      fbBuilder.addOffset(3, offset_message);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    if (offset_uniqueName != null) {
      fbBuilder.addOffset(2, offset_uniqueName);
    }
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverUnitErrorReader
    extends fb.TableReader<_AnalysisDriverUnitErrorImpl> {
  const _AnalysisDriverUnitErrorReader();

  @override
  _AnalysisDriverUnitErrorImpl createObject(fb.BufferContext bc, int offset) =>
      new _AnalysisDriverUnitErrorImpl(bc, offset);
}

class _AnalysisDriverUnitErrorImpl extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnitErrorImpl(this._bc, this._bcOffset);

  String _correction;
  int _length;
  String _message;
  int _offset;
  String _uniqueName;

  @override
  String get correction {
    _correction ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
    return _correction;
  }

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _length;
  }

  @override
  String get message {
    _message ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _message;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _offset;
  }

  @override
  String get uniqueName {
    _uniqueName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _uniqueName;
  }
}

abstract class _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (correction != '') _result["correction"] = correction;
    if (length != 0) _result["length"] = length;
    if (message != '') _result["message"] = message;
    if (offset != 0) _result["offset"] = offset;
    if (uniqueName != '') _result["uniqueName"] = uniqueName;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "correction": correction,
        "length": length,
        "message": message,
        "offset": offset,
        "uniqueName": uniqueName,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnitIndexBuilder extends Object
    with _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  List<idl.IndexSyntheticElementKind> _elementKinds;
  List<int> _elementNameClassMemberIds;
  List<int> _elementNameParameterIds;
  List<int> _elementNameUnitMemberIds;
  List<int> _elementUnits;
  int _nullStringId;
  List<String> _strings;
  List<AnalysisDriverSubtypeBuilder> _subtypes;
  List<int> _supertypes;
  List<int> _unitLibraryUris;
  List<int> _unitUnitUris;
  List<bool> _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedElementKinds;
  List<int> _usedElementLengths;
  List<int> _usedElementOffsets;
  List<int> _usedElements;
  List<bool> _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedNameKinds;
  List<int> _usedNameOffsets;
  List<int> _usedNames;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds =>
      _elementKinds ??= <idl.IndexSyntheticElementKind>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  set elementKinds(List<idl.IndexSyntheticElementKind> value) {
    this._elementKinds = value;
  }

  @override
  List<int> get elementNameClassMemberIds =>
      _elementNameClassMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// index.
  set elementNameClassMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this index.
  set elementNameParameterIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameParameterIds = value;
  }

  @override
  List<int> get elementNameUnitMemberIds =>
      _elementNameUnitMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this index.
  set elementNameUnitMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  set elementUnits(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  int get nullStringId => _nullStringId ??= 0;

  /// Identifier of the null string in [strings].
  set nullStringId(int value) {
    assert(value == null || value >= 0);
    this._nullStringId = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /// List of unique element strings used in this index.  The list is sorted in
  /// ascending order, so that the client can quickly check the presence of a
  /// string in this index.
  set strings(List<String> value) {
    this._strings = value;
  }

  @override
  List<AnalysisDriverSubtypeBuilder> get subtypes =>
      _subtypes ??= <AnalysisDriverSubtypeBuilder>[];

  /// The list of classes declared in the unit.
  set subtypes(List<AnalysisDriverSubtypeBuilder> value) {
    this._subtypes = value;
  }

  @override
  List<int> get supertypes => _supertypes ??= <int>[];

  /// The identifiers of supertypes of elements at corresponding indexes
  /// in [subtypes].  They are indexes into [strings] list. The list is sorted
  /// in ascending order.  There might be more than one element with the same
  /// value if there is more than one subtype of this supertype.
  set supertypes(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._supertypes = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitLibraryUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitUnitUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitUnitUris = value;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags =>
      _usedElementIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  set usedElementIsQualifiedFlags(List<bool> value) {
    this._usedElementIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds =>
      _usedElementKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the element usage.
  set usedElementKinds(List<idl.IndexRelationKind> value) {
    this._usedElementKinds = value;
  }

  @override
  List<int> get usedElementLengths => _usedElementLengths ??= <int>[];

  /// Each item of this list is the length of the element usage.
  set usedElementLengths(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  set usedElementOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /// Each item of this list is the index into [elementUnits],
  /// [elementNameUnitMemberIds], [elementNameClassMemberIds] and
  /// [elementNameParameterIds].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this index.
  set usedElements(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElements = value;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags =>
      _usedNameIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  set usedNameIsQualifiedFlags(List<bool> value) {
    this._usedNameIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds =>
      _usedNameKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the name usage.
  set usedNameKinds(List<idl.IndexRelationKind> value) {
    this._usedNameKinds = value;
  }

  @override
  List<int> get usedNameOffsets => _usedNameOffsets ??= <int>[];

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  set usedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /// Each item of this list is the index into [strings] for a used name.  The
  /// list is sorted in ascending order, so that the client can quickly find
  /// whether a name is used in this index.
  set usedNames(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNames = value;
  }

  AnalysisDriverUnitIndexBuilder(
      {List<idl.IndexSyntheticElementKind> elementKinds,
      List<int> elementNameClassMemberIds,
      List<int> elementNameParameterIds,
      List<int> elementNameUnitMemberIds,
      List<int> elementUnits,
      int nullStringId,
      List<String> strings,
      List<AnalysisDriverSubtypeBuilder> subtypes,
      List<int> supertypes,
      List<int> unitLibraryUris,
      List<int> unitUnitUris,
      List<bool> usedElementIsQualifiedFlags,
      List<idl.IndexRelationKind> usedElementKinds,
      List<int> usedElementLengths,
      List<int> usedElementOffsets,
      List<int> usedElements,
      List<bool> usedNameIsQualifiedFlags,
      List<idl.IndexRelationKind> usedNameKinds,
      List<int> usedNameOffsets,
      List<int> usedNames})
      : _elementKinds = elementKinds,
        _elementNameClassMemberIds = elementNameClassMemberIds,
        _elementNameParameterIds = elementNameParameterIds,
        _elementNameUnitMemberIds = elementNameUnitMemberIds,
        _elementUnits = elementUnits,
        _nullStringId = nullStringId,
        _strings = strings,
        _subtypes = subtypes,
        _supertypes = supertypes,
        _unitLibraryUris = unitLibraryUris,
        _unitUnitUris = unitUnitUris,
        _usedElementIsQualifiedFlags = usedElementIsQualifiedFlags,
        _usedElementKinds = usedElementKinds,
        _usedElementLengths = usedElementLengths,
        _usedElementOffsets = usedElementOffsets,
        _usedElements = usedElements,
        _usedNameIsQualifiedFlags = usedNameIsQualifiedFlags,
        _usedNameKinds = usedNameKinds,
        _usedNameOffsets = usedNameOffsets,
        _usedNames = usedNames;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _subtypes?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._strings == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._strings.length);
      for (var x in this._strings) {
        signature.addString(x);
      }
    }
    signature.addInt(this._nullStringId ?? 0);
    if (this._unitLibraryUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unitLibraryUris.length);
      for (var x in this._unitLibraryUris) {
        signature.addInt(x);
      }
    }
    if (this._unitUnitUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unitUnitUris.length);
      for (var x in this._unitUnitUris) {
        signature.addInt(x);
      }
    }
    if (this._elementKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementKinds.length);
      for (var x in this._elementKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._elementUnits == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementUnits.length);
      for (var x in this._elementUnits) {
        signature.addInt(x);
      }
    }
    if (this._elementNameUnitMemberIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameUnitMemberIds.length);
      for (var x in this._elementNameUnitMemberIds) {
        signature.addInt(x);
      }
    }
    if (this._elementNameClassMemberIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameClassMemberIds.length);
      for (var x in this._elementNameClassMemberIds) {
        signature.addInt(x);
      }
    }
    if (this._elementNameParameterIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameParameterIds.length);
      for (var x in this._elementNameParameterIds) {
        signature.addInt(x);
      }
    }
    if (this._usedElements == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElements.length);
      for (var x in this._usedElements) {
        signature.addInt(x);
      }
    }
    if (this._usedElementKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementKinds.length);
      for (var x in this._usedElementKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._usedElementOffsets == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementOffsets.length);
      for (var x in this._usedElementOffsets) {
        signature.addInt(x);
      }
    }
    if (this._usedElementLengths == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementLengths.length);
      for (var x in this._usedElementLengths) {
        signature.addInt(x);
      }
    }
    if (this._usedElementIsQualifiedFlags == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementIsQualifiedFlags.length);
      for (var x in this._usedElementIsQualifiedFlags) {
        signature.addBool(x);
      }
    }
    if (this._usedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNames.length);
      for (var x in this._usedNames) {
        signature.addInt(x);
      }
    }
    if (this._usedNameKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameKinds.length);
      for (var x in this._usedNameKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._usedNameOffsets == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameOffsets.length);
      for (var x in this._usedNameOffsets) {
        signature.addInt(x);
      }
    }
    if (this._usedNameIsQualifiedFlags == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameIsQualifiedFlags.length);
      for (var x in this._usedNameIsQualifiedFlags) {
        signature.addBool(x);
      }
    }
    if (this._supertypes == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._supertypes.length);
      for (var x in this._supertypes) {
        signature.addInt(x);
      }
    }
    if (this._subtypes == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._subtypes.length);
      for (var x in this._subtypes) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADUI");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_elementKinds;
    fb.Offset offset_elementNameClassMemberIds;
    fb.Offset offset_elementNameParameterIds;
    fb.Offset offset_elementNameUnitMemberIds;
    fb.Offset offset_elementUnits;
    fb.Offset offset_strings;
    fb.Offset offset_subtypes;
    fb.Offset offset_supertypes;
    fb.Offset offset_unitLibraryUris;
    fb.Offset offset_unitUnitUris;
    fb.Offset offset_usedElementIsQualifiedFlags;
    fb.Offset offset_usedElementKinds;
    fb.Offset offset_usedElementLengths;
    fb.Offset offset_usedElementOffsets;
    fb.Offset offset_usedElements;
    fb.Offset offset_usedNameIsQualifiedFlags;
    fb.Offset offset_usedNameKinds;
    fb.Offset offset_usedNameOffsets;
    fb.Offset offset_usedNames;
    if (!(_elementKinds == null || _elementKinds.isEmpty)) {
      offset_elementKinds =
          fbBuilder.writeListUint8(_elementKinds.map((b) => b.index).toList());
    }
    if (!(_elementNameClassMemberIds == null ||
        _elementNameClassMemberIds.isEmpty)) {
      offset_elementNameClassMemberIds =
          fbBuilder.writeListUint32(_elementNameClassMemberIds);
    }
    if (!(_elementNameParameterIds == null ||
        _elementNameParameterIds.isEmpty)) {
      offset_elementNameParameterIds =
          fbBuilder.writeListUint32(_elementNameParameterIds);
    }
    if (!(_elementNameUnitMemberIds == null ||
        _elementNameUnitMemberIds.isEmpty)) {
      offset_elementNameUnitMemberIds =
          fbBuilder.writeListUint32(_elementNameUnitMemberIds);
    }
    if (!(_elementUnits == null || _elementUnits.isEmpty)) {
      offset_elementUnits = fbBuilder.writeListUint32(_elementUnits);
    }
    if (!(_strings == null || _strings.isEmpty)) {
      offset_strings = fbBuilder
          .writeList(_strings.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_subtypes == null || _subtypes.isEmpty)) {
      offset_subtypes = fbBuilder
          .writeList(_subtypes.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_supertypes == null || _supertypes.isEmpty)) {
      offset_supertypes = fbBuilder.writeListUint32(_supertypes);
    }
    if (!(_unitLibraryUris == null || _unitLibraryUris.isEmpty)) {
      offset_unitLibraryUris = fbBuilder.writeListUint32(_unitLibraryUris);
    }
    if (!(_unitUnitUris == null || _unitUnitUris.isEmpty)) {
      offset_unitUnitUris = fbBuilder.writeListUint32(_unitUnitUris);
    }
    if (!(_usedElementIsQualifiedFlags == null ||
        _usedElementIsQualifiedFlags.isEmpty)) {
      offset_usedElementIsQualifiedFlags =
          fbBuilder.writeListBool(_usedElementIsQualifiedFlags);
    }
    if (!(_usedElementKinds == null || _usedElementKinds.isEmpty)) {
      offset_usedElementKinds = fbBuilder
          .writeListUint8(_usedElementKinds.map((b) => b.index).toList());
    }
    if (!(_usedElementLengths == null || _usedElementLengths.isEmpty)) {
      offset_usedElementLengths =
          fbBuilder.writeListUint32(_usedElementLengths);
    }
    if (!(_usedElementOffsets == null || _usedElementOffsets.isEmpty)) {
      offset_usedElementOffsets =
          fbBuilder.writeListUint32(_usedElementOffsets);
    }
    if (!(_usedElements == null || _usedElements.isEmpty)) {
      offset_usedElements = fbBuilder.writeListUint32(_usedElements);
    }
    if (!(_usedNameIsQualifiedFlags == null ||
        _usedNameIsQualifiedFlags.isEmpty)) {
      offset_usedNameIsQualifiedFlags =
          fbBuilder.writeListBool(_usedNameIsQualifiedFlags);
    }
    if (!(_usedNameKinds == null || _usedNameKinds.isEmpty)) {
      offset_usedNameKinds =
          fbBuilder.writeListUint8(_usedNameKinds.map((b) => b.index).toList());
    }
    if (!(_usedNameOffsets == null || _usedNameOffsets.isEmpty)) {
      offset_usedNameOffsets = fbBuilder.writeListUint32(_usedNameOffsets);
    }
    if (!(_usedNames == null || _usedNames.isEmpty)) {
      offset_usedNames = fbBuilder.writeListUint32(_usedNames);
    }
    fbBuilder.startTable();
    if (offset_elementKinds != null) {
      fbBuilder.addOffset(4, offset_elementKinds);
    }
    if (offset_elementNameClassMemberIds != null) {
      fbBuilder.addOffset(7, offset_elementNameClassMemberIds);
    }
    if (offset_elementNameParameterIds != null) {
      fbBuilder.addOffset(8, offset_elementNameParameterIds);
    }
    if (offset_elementNameUnitMemberIds != null) {
      fbBuilder.addOffset(6, offset_elementNameUnitMemberIds);
    }
    if (offset_elementUnits != null) {
      fbBuilder.addOffset(5, offset_elementUnits);
    }
    if (_nullStringId != null && _nullStringId != 0) {
      fbBuilder.addUint32(1, _nullStringId);
    }
    if (offset_strings != null) {
      fbBuilder.addOffset(0, offset_strings);
    }
    if (offset_subtypes != null) {
      fbBuilder.addOffset(19, offset_subtypes);
    }
    if (offset_supertypes != null) {
      fbBuilder.addOffset(18, offset_supertypes);
    }
    if (offset_unitLibraryUris != null) {
      fbBuilder.addOffset(2, offset_unitLibraryUris);
    }
    if (offset_unitUnitUris != null) {
      fbBuilder.addOffset(3, offset_unitUnitUris);
    }
    if (offset_usedElementIsQualifiedFlags != null) {
      fbBuilder.addOffset(13, offset_usedElementIsQualifiedFlags);
    }
    if (offset_usedElementKinds != null) {
      fbBuilder.addOffset(10, offset_usedElementKinds);
    }
    if (offset_usedElementLengths != null) {
      fbBuilder.addOffset(12, offset_usedElementLengths);
    }
    if (offset_usedElementOffsets != null) {
      fbBuilder.addOffset(11, offset_usedElementOffsets);
    }
    if (offset_usedElements != null) {
      fbBuilder.addOffset(9, offset_usedElements);
    }
    if (offset_usedNameIsQualifiedFlags != null) {
      fbBuilder.addOffset(17, offset_usedNameIsQualifiedFlags);
    }
    if (offset_usedNameKinds != null) {
      fbBuilder.addOffset(15, offset_usedNameKinds);
    }
    if (offset_usedNameOffsets != null) {
      fbBuilder.addOffset(16, offset_usedNameOffsets);
    }
    if (offset_usedNames != null) {
      fbBuilder.addOffset(14, offset_usedNames);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverUnitIndex readAnalysisDriverUnitIndex(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverUnitIndexReader().read(rootRef, 0);
}

class _AnalysisDriverUnitIndexReader
    extends fb.TableReader<_AnalysisDriverUnitIndexImpl> {
  const _AnalysisDriverUnitIndexReader();

  @override
  _AnalysisDriverUnitIndexImpl createObject(fb.BufferContext bc, int offset) =>
      new _AnalysisDriverUnitIndexImpl(bc, offset);
}

class _AnalysisDriverUnitIndexImpl extends Object
    with _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnitIndexImpl(this._bc, this._bcOffset);

  List<idl.IndexSyntheticElementKind> _elementKinds;
  List<int> _elementNameClassMemberIds;
  List<int> _elementNameParameterIds;
  List<int> _elementNameUnitMemberIds;
  List<int> _elementUnits;
  int _nullStringId;
  List<String> _strings;
  List<idl.AnalysisDriverSubtype> _subtypes;
  List<int> _supertypes;
  List<int> _unitLibraryUris;
  List<int> _unitUnitUris;
  List<bool> _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedElementKinds;
  List<int> _usedElementLengths;
  List<int> _usedElementOffsets;
  List<int> _usedElements;
  List<bool> _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedNameKinds;
  List<int> _usedNameOffsets;
  List<int> _usedNames;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds {
    _elementKinds ??= const fb.ListReader<idl.IndexSyntheticElementKind>(
            const _IndexSyntheticElementKindReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.IndexSyntheticElementKind>[]);
    return _elementKinds;
  }

  @override
  List<int> get elementNameClassMemberIds {
    _elementNameClassMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
    return _elementNameClassMemberIds;
  }

  @override
  List<int> get elementNameParameterIds {
    _elementNameParameterIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 8, const <int>[]);
    return _elementNameParameterIds;
  }

  @override
  List<int> get elementNameUnitMemberIds {
    _elementNameUnitMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 6, const <int>[]);
    return _elementNameUnitMemberIds;
  }

  @override
  List<int> get elementUnits {
    _elementUnits ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _elementUnits;
  }

  @override
  int get nullStringId {
    _nullStringId ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nullStringId;
  }

  @override
  List<String> get strings {
    _strings ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _strings;
  }

  @override
  List<idl.AnalysisDriverSubtype> get subtypes {
    _subtypes ??= const fb.ListReader<idl.AnalysisDriverSubtype>(
            const _AnalysisDriverSubtypeReader())
        .vTableGet(_bc, _bcOffset, 19, const <idl.AnalysisDriverSubtype>[]);
    return _subtypes;
  }

  @override
  List<int> get supertypes {
    _supertypes ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 18, const <int>[]);
    return _supertypes;
  }

  @override
  List<int> get unitLibraryUris {
    _unitLibraryUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _unitLibraryUris;
  }

  @override
  List<int> get unitUnitUris {
    _unitUnitUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
    return _unitUnitUris;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags {
    _usedElementIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 13, const <bool>[]);
    return _usedElementIsQualifiedFlags;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds {
    _usedElementKinds ??= const fb.ListReader<idl.IndexRelationKind>(
            const _IndexRelationKindReader())
        .vTableGet(_bc, _bcOffset, 10, const <idl.IndexRelationKind>[]);
    return _usedElementKinds;
  }

  @override
  List<int> get usedElementLengths {
    _usedElementLengths ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 12, const <int>[]);
    return _usedElementLengths;
  }

  @override
  List<int> get usedElementOffsets {
    _usedElementOffsets ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 11, const <int>[]);
    return _usedElementOffsets;
  }

  @override
  List<int> get usedElements {
    _usedElements ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 9, const <int>[]);
    return _usedElements;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags {
    _usedNameIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 17, const <bool>[]);
    return _usedNameIsQualifiedFlags;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds {
    _usedNameKinds ??= const fb.ListReader<idl.IndexRelationKind>(
            const _IndexRelationKindReader())
        .vTableGet(_bc, _bcOffset, 15, const <idl.IndexRelationKind>[]);
    return _usedNameKinds;
  }

  @override
  List<int> get usedNameOffsets {
    _usedNameOffsets ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 16, const <int>[]);
    return _usedNameOffsets;
  }

  @override
  List<int> get usedNames {
    _usedNames ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 14, const <int>[]);
    return _usedNames;
  }
}

abstract class _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (elementKinds.isNotEmpty)
      _result["elementKinds"] = elementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (elementNameClassMemberIds.isNotEmpty)
      _result["elementNameClassMemberIds"] = elementNameClassMemberIds;
    if (elementNameParameterIds.isNotEmpty)
      _result["elementNameParameterIds"] = elementNameParameterIds;
    if (elementNameUnitMemberIds.isNotEmpty)
      _result["elementNameUnitMemberIds"] = elementNameUnitMemberIds;
    if (elementUnits.isNotEmpty) _result["elementUnits"] = elementUnits;
    if (nullStringId != 0) _result["nullStringId"] = nullStringId;
    if (strings.isNotEmpty) _result["strings"] = strings;
    if (subtypes.isNotEmpty)
      _result["subtypes"] = subtypes.map((_value) => _value.toJson()).toList();
    if (supertypes.isNotEmpty) _result["supertypes"] = supertypes;
    if (unitLibraryUris.isNotEmpty)
      _result["unitLibraryUris"] = unitLibraryUris;
    if (unitUnitUris.isNotEmpty) _result["unitUnitUris"] = unitUnitUris;
    if (usedElementIsQualifiedFlags.isNotEmpty)
      _result["usedElementIsQualifiedFlags"] = usedElementIsQualifiedFlags;
    if (usedElementKinds.isNotEmpty)
      _result["usedElementKinds"] = usedElementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (usedElementLengths.isNotEmpty)
      _result["usedElementLengths"] = usedElementLengths;
    if (usedElementOffsets.isNotEmpty)
      _result["usedElementOffsets"] = usedElementOffsets;
    if (usedElements.isNotEmpty) _result["usedElements"] = usedElements;
    if (usedNameIsQualifiedFlags.isNotEmpty)
      _result["usedNameIsQualifiedFlags"] = usedNameIsQualifiedFlags;
    if (usedNameKinds.isNotEmpty)
      _result["usedNameKinds"] = usedNameKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (usedNameOffsets.isNotEmpty)
      _result["usedNameOffsets"] = usedNameOffsets;
    if (usedNames.isNotEmpty) _result["usedNames"] = usedNames;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "elementKinds": elementKinds,
        "elementNameClassMemberIds": elementNameClassMemberIds,
        "elementNameParameterIds": elementNameParameterIds,
        "elementNameUnitMemberIds": elementNameUnitMemberIds,
        "elementUnits": elementUnits,
        "nullStringId": nullStringId,
        "strings": strings,
        "subtypes": subtypes,
        "supertypes": supertypes,
        "unitLibraryUris": unitLibraryUris,
        "unitUnitUris": unitUnitUris,
        "usedElementIsQualifiedFlags": usedElementIsQualifiedFlags,
        "usedElementKinds": usedElementKinds,
        "usedElementLengths": usedElementLengths,
        "usedElementOffsets": usedElementOffsets,
        "usedElements": usedElements,
        "usedNameIsQualifiedFlags": usedNameIsQualifiedFlags,
        "usedNameKinds": usedNameKinds,
        "usedNameOffsets": usedNameOffsets,
        "usedNames": usedNames,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnlinkedUnitBuilder extends Object
    with _AnalysisDriverUnlinkedUnitMixin
    implements idl.AnalysisDriverUnlinkedUnit {
  List<String> _definedClassMemberNames;
  List<String> _definedTopLevelNames;
  List<String> _referencedNames;
  List<String> _subtypedNames;
  UnlinkedUnitBuilder _unit;
  UnlinkedUnit2Builder _unit2;

  @override
  List<String> get definedClassMemberNames =>
      _definedClassMemberNames ??= <String>[];

  /// List of class member names defined by the unit.
  set definedClassMemberNames(List<String> value) {
    this._definedClassMemberNames = value;
  }

  @override
  List<String> get definedTopLevelNames => _definedTopLevelNames ??= <String>[];

  /// List of top-level names defined by the unit.
  set definedTopLevelNames(List<String> value) {
    this._definedTopLevelNames = value;
  }

  @override
  List<String> get referencedNames => _referencedNames ??= <String>[];

  /// List of external names referenced by the unit.
  set referencedNames(List<String> value) {
    this._referencedNames = value;
  }

  @override
  List<String> get subtypedNames => _subtypedNames ??= <String>[];

  /// List of names which are used in `extends`, `with` or `implements` clauses
  /// in the file. Import prefixes and type arguments are not included.
  set subtypedNames(List<String> value) {
    this._subtypedNames = value;
  }

  @override
  UnlinkedUnitBuilder get unit => _unit;

  /// Unlinked information for the unit.
  set unit(UnlinkedUnitBuilder value) {
    this._unit = value;
  }

  @override
  UnlinkedUnit2Builder get unit2 => _unit2;

  /// Unlinked information for the unit.
  set unit2(UnlinkedUnit2Builder value) {
    this._unit2 = value;
  }

  AnalysisDriverUnlinkedUnitBuilder(
      {List<String> definedClassMemberNames,
      List<String> definedTopLevelNames,
      List<String> referencedNames,
      List<String> subtypedNames,
      UnlinkedUnitBuilder unit,
      UnlinkedUnit2Builder unit2})
      : _definedClassMemberNames = definedClassMemberNames,
        _definedTopLevelNames = definedTopLevelNames,
        _referencedNames = referencedNames,
        _subtypedNames = subtypedNames,
        _unit = unit,
        _unit2 = unit2;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _unit?.flushInformative();
    _unit2?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._referencedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._referencedNames.length);
      for (var x in this._referencedNames) {
        signature.addString(x);
      }
    }
    signature.addBool(this._unit != null);
    this._unit?.collectApiSignature(signature);
    if (this._definedTopLevelNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._definedTopLevelNames.length);
      for (var x in this._definedTopLevelNames) {
        signature.addString(x);
      }
    }
    if (this._definedClassMemberNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._definedClassMemberNames.length);
      for (var x in this._definedClassMemberNames) {
        signature.addString(x);
      }
    }
    if (this._subtypedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._subtypedNames.length);
      for (var x in this._subtypedNames) {
        signature.addString(x);
      }
    }
    signature.addBool(this._unit2 != null);
    this._unit2?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADUU");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_definedClassMemberNames;
    fb.Offset offset_definedTopLevelNames;
    fb.Offset offset_referencedNames;
    fb.Offset offset_subtypedNames;
    fb.Offset offset_unit;
    fb.Offset offset_unit2;
    if (!(_definedClassMemberNames == null ||
        _definedClassMemberNames.isEmpty)) {
      offset_definedClassMemberNames = fbBuilder.writeList(
          _definedClassMemberNames
              .map((b) => fbBuilder.writeString(b))
              .toList());
    }
    if (!(_definedTopLevelNames == null || _definedTopLevelNames.isEmpty)) {
      offset_definedTopLevelNames = fbBuilder.writeList(
          _definedTopLevelNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_referencedNames == null || _referencedNames.isEmpty)) {
      offset_referencedNames = fbBuilder.writeList(
          _referencedNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_subtypedNames == null || _subtypedNames.isEmpty)) {
      offset_subtypedNames = fbBuilder.writeList(
          _subtypedNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_unit != null) {
      offset_unit = _unit.finish(fbBuilder);
    }
    if (_unit2 != null) {
      offset_unit2 = _unit2.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_definedClassMemberNames != null) {
      fbBuilder.addOffset(3, offset_definedClassMemberNames);
    }
    if (offset_definedTopLevelNames != null) {
      fbBuilder.addOffset(2, offset_definedTopLevelNames);
    }
    if (offset_referencedNames != null) {
      fbBuilder.addOffset(0, offset_referencedNames);
    }
    if (offset_subtypedNames != null) {
      fbBuilder.addOffset(4, offset_subtypedNames);
    }
    if (offset_unit != null) {
      fbBuilder.addOffset(1, offset_unit);
    }
    if (offset_unit2 != null) {
      fbBuilder.addOffset(5, offset_unit2);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverUnlinkedUnit readAnalysisDriverUnlinkedUnit(
    List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverUnlinkedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverUnlinkedUnitReader
    extends fb.TableReader<_AnalysisDriverUnlinkedUnitImpl> {
  const _AnalysisDriverUnlinkedUnitReader();

  @override
  _AnalysisDriverUnlinkedUnitImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _AnalysisDriverUnlinkedUnitImpl(bc, offset);
}

class _AnalysisDriverUnlinkedUnitImpl extends Object
    with _AnalysisDriverUnlinkedUnitMixin
    implements idl.AnalysisDriverUnlinkedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnlinkedUnitImpl(this._bc, this._bcOffset);

  List<String> _definedClassMemberNames;
  List<String> _definedTopLevelNames;
  List<String> _referencedNames;
  List<String> _subtypedNames;
  idl.UnlinkedUnit _unit;
  idl.UnlinkedUnit2 _unit2;

  @override
  List<String> get definedClassMemberNames {
    _definedClassMemberNames ??=
        const fb.ListReader<String>(const fb.StringReader())
            .vTableGet(_bc, _bcOffset, 3, const <String>[]);
    return _definedClassMemberNames;
  }

  @override
  List<String> get definedTopLevelNames {
    _definedTopLevelNames ??=
        const fb.ListReader<String>(const fb.StringReader())
            .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _definedTopLevelNames;
  }

  @override
  List<String> get referencedNames {
    _referencedNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _referencedNames;
  }

  @override
  List<String> get subtypedNames {
    _subtypedNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _subtypedNames;
  }

  @override
  idl.UnlinkedUnit get unit {
    _unit ??= const _UnlinkedUnitReader().vTableGet(_bc, _bcOffset, 1, null);
    return _unit;
  }

  @override
  idl.UnlinkedUnit2 get unit2 {
    _unit2 ??= const _UnlinkedUnit2Reader().vTableGet(_bc, _bcOffset, 5, null);
    return _unit2;
  }
}

abstract class _AnalysisDriverUnlinkedUnitMixin
    implements idl.AnalysisDriverUnlinkedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (definedClassMemberNames.isNotEmpty)
      _result["definedClassMemberNames"] = definedClassMemberNames;
    if (definedTopLevelNames.isNotEmpty)
      _result["definedTopLevelNames"] = definedTopLevelNames;
    if (referencedNames.isNotEmpty)
      _result["referencedNames"] = referencedNames;
    if (subtypedNames.isNotEmpty) _result["subtypedNames"] = subtypedNames;
    if (unit != null) _result["unit"] = unit.toJson();
    if (unit2 != null) _result["unit2"] = unit2.toJson();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "definedClassMemberNames": definedClassMemberNames,
        "definedTopLevelNames": definedTopLevelNames,
        "referencedNames": referencedNames,
        "subtypedNames": subtypedNames,
        "unit": unit,
        "unit2": unit2,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableDeclarationBuilder extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  List<AvailableDeclarationBuilder> _children;
  String _defaultArgumentListString;
  List<int> _defaultArgumentListTextRanges;
  String _docComplete;
  String _docSummary;
  int _fieldMask;
  bool _isAbstract;
  bool _isConst;
  bool _isDeprecated;
  bool _isFinal;
  idl.AvailableDeclarationKind _kind;
  int _locationOffset;
  int _locationStartColumn;
  int _locationStartLine;
  String _name;
  List<String> _parameterNames;
  String _parameters;
  List<String> _parameterTypes;
  List<String> _relevanceTags;
  int _requiredParameterCount;
  String _returnType;
  String _typeParameters;

  @override
  List<AvailableDeclarationBuilder> get children =>
      _children ??= <AvailableDeclarationBuilder>[];

  set children(List<AvailableDeclarationBuilder> value) {
    this._children = value;
  }

  @override
  String get defaultArgumentListString => _defaultArgumentListString ??= '';

  set defaultArgumentListString(String value) {
    this._defaultArgumentListString = value;
  }

  @override
  List<int> get defaultArgumentListTextRanges =>
      _defaultArgumentListTextRanges ??= <int>[];

  set defaultArgumentListTextRanges(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._defaultArgumentListTextRanges = value;
  }

  @override
  String get docComplete => _docComplete ??= '';

  set docComplete(String value) {
    this._docComplete = value;
  }

  @override
  String get docSummary => _docSummary ??= '';

  set docSummary(String value) {
    this._docSummary = value;
  }

  @override
  int get fieldMask => _fieldMask ??= 0;

  set fieldMask(int value) {
    assert(value == null || value >= 0);
    this._fieldMask = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isDeprecated => _isDeprecated ??= false;

  set isDeprecated(bool value) {
    this._isDeprecated = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  idl.AvailableDeclarationKind get kind =>
      _kind ??= idl.AvailableDeclarationKind.CLASS;

  /// The kind of the declaration.
  set kind(idl.AvailableDeclarationKind value) {
    this._kind = value;
  }

  @override
  int get locationOffset => _locationOffset ??= 0;

  set locationOffset(int value) {
    assert(value == null || value >= 0);
    this._locationOffset = value;
  }

  @override
  int get locationStartColumn => _locationStartColumn ??= 0;

  set locationStartColumn(int value) {
    assert(value == null || value >= 0);
    this._locationStartColumn = value;
  }

  @override
  int get locationStartLine => _locationStartLine ??= 0;

  set locationStartLine(int value) {
    assert(value == null || value >= 0);
    this._locationStartLine = value;
  }

  @override
  String get name => _name ??= '';

  /// The first part of the declaration name, usually the only one, for example
  /// the name of a class like `MyClass`, or a function like `myFunction`.
  set name(String value) {
    this._name = value;
  }

  @override
  List<String> get parameterNames => _parameterNames ??= <String>[];

  set parameterNames(List<String> value) {
    this._parameterNames = value;
  }

  @override
  String get parameters => _parameters ??= '';

  set parameters(String value) {
    this._parameters = value;
  }

  @override
  List<String> get parameterTypes => _parameterTypes ??= <String>[];

  set parameterTypes(List<String> value) {
    this._parameterTypes = value;
  }

  @override
  List<String> get relevanceTags => _relevanceTags ??= <String>[];

  /// The partial list of relevance tags.  Not every declaration has one (for
  /// example, function do not currently), and not every declaration has to
  /// store one (for classes it can be computed when we know the library that
  /// includes this file).
  set relevanceTags(List<String> value) {
    this._relevanceTags = value;
  }

  @override
  int get requiredParameterCount => _requiredParameterCount ??= 0;

  set requiredParameterCount(int value) {
    assert(value == null || value >= 0);
    this._requiredParameterCount = value;
  }

  @override
  String get returnType => _returnType ??= '';

  set returnType(String value) {
    this._returnType = value;
  }

  @override
  String get typeParameters => _typeParameters ??= '';

  set typeParameters(String value) {
    this._typeParameters = value;
  }

  AvailableDeclarationBuilder(
      {List<AvailableDeclarationBuilder> children,
      String defaultArgumentListString,
      List<int> defaultArgumentListTextRanges,
      String docComplete,
      String docSummary,
      int fieldMask,
      bool isAbstract,
      bool isConst,
      bool isDeprecated,
      bool isFinal,
      idl.AvailableDeclarationKind kind,
      int locationOffset,
      int locationStartColumn,
      int locationStartLine,
      String name,
      List<String> parameterNames,
      String parameters,
      List<String> parameterTypes,
      List<String> relevanceTags,
      int requiredParameterCount,
      String returnType,
      String typeParameters})
      : _children = children,
        _defaultArgumentListString = defaultArgumentListString,
        _defaultArgumentListTextRanges = defaultArgumentListTextRanges,
        _docComplete = docComplete,
        _docSummary = docSummary,
        _fieldMask = fieldMask,
        _isAbstract = isAbstract,
        _isConst = isConst,
        _isDeprecated = isDeprecated,
        _isFinal = isFinal,
        _kind = kind,
        _locationOffset = locationOffset,
        _locationStartColumn = locationStartColumn,
        _locationStartLine = locationStartLine,
        _name = name,
        _parameterNames = parameterNames,
        _parameters = parameters,
        _parameterTypes = parameterTypes,
        _relevanceTags = relevanceTags,
        _requiredParameterCount = requiredParameterCount,
        _returnType = returnType,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _children?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._children == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._children.length);
      for (var x in this._children) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addString(this._defaultArgumentListString ?? '');
    if (this._defaultArgumentListTextRanges == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._defaultArgumentListTextRanges.length);
      for (var x in this._defaultArgumentListTextRanges) {
        signature.addInt(x);
      }
    }
    signature.addString(this._docComplete ?? '');
    signature.addString(this._docSummary ?? '');
    signature.addInt(this._fieldMask ?? 0);
    signature.addBool(this._isAbstract == true);
    signature.addBool(this._isConst == true);
    signature.addBool(this._isDeprecated == true);
    signature.addBool(this._isFinal == true);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addInt(this._locationOffset ?? 0);
    signature.addInt(this._locationStartColumn ?? 0);
    signature.addInt(this._locationStartLine ?? 0);
    signature.addString(this._name ?? '');
    if (this._parameterNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parameterNames.length);
      for (var x in this._parameterNames) {
        signature.addString(x);
      }
    }
    signature.addString(this._parameters ?? '');
    if (this._parameterTypes == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parameterTypes.length);
      for (var x in this._parameterTypes) {
        signature.addString(x);
      }
    }
    if (this._relevanceTags == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._relevanceTags.length);
      for (var x in this._relevanceTags) {
        signature.addString(x);
      }
    }
    signature.addInt(this._requiredParameterCount ?? 0);
    signature.addString(this._returnType ?? '');
    signature.addString(this._typeParameters ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_children;
    fb.Offset offset_defaultArgumentListString;
    fb.Offset offset_defaultArgumentListTextRanges;
    fb.Offset offset_docComplete;
    fb.Offset offset_docSummary;
    fb.Offset offset_name;
    fb.Offset offset_parameterNames;
    fb.Offset offset_parameters;
    fb.Offset offset_parameterTypes;
    fb.Offset offset_relevanceTags;
    fb.Offset offset_returnType;
    fb.Offset offset_typeParameters;
    if (!(_children == null || _children.isEmpty)) {
      offset_children = fbBuilder
          .writeList(_children.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_defaultArgumentListString != null) {
      offset_defaultArgumentListString =
          fbBuilder.writeString(_defaultArgumentListString);
    }
    if (!(_defaultArgumentListTextRanges == null ||
        _defaultArgumentListTextRanges.isEmpty)) {
      offset_defaultArgumentListTextRanges =
          fbBuilder.writeListUint32(_defaultArgumentListTextRanges);
    }
    if (_docComplete != null) {
      offset_docComplete = fbBuilder.writeString(_docComplete);
    }
    if (_docSummary != null) {
      offset_docSummary = fbBuilder.writeString(_docSummary);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_parameterNames == null || _parameterNames.isEmpty)) {
      offset_parameterNames = fbBuilder.writeList(
          _parameterNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_parameters != null) {
      offset_parameters = fbBuilder.writeString(_parameters);
    }
    if (!(_parameterTypes == null || _parameterTypes.isEmpty)) {
      offset_parameterTypes = fbBuilder.writeList(
          _parameterTypes.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_relevanceTags == null || _relevanceTags.isEmpty)) {
      offset_relevanceTags = fbBuilder.writeList(
          _relevanceTags.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_returnType != null) {
      offset_returnType = fbBuilder.writeString(_returnType);
    }
    if (_typeParameters != null) {
      offset_typeParameters = fbBuilder.writeString(_typeParameters);
    }
    fbBuilder.startTable();
    if (offset_children != null) {
      fbBuilder.addOffset(0, offset_children);
    }
    if (offset_defaultArgumentListString != null) {
      fbBuilder.addOffset(1, offset_defaultArgumentListString);
    }
    if (offset_defaultArgumentListTextRanges != null) {
      fbBuilder.addOffset(2, offset_defaultArgumentListTextRanges);
    }
    if (offset_docComplete != null) {
      fbBuilder.addOffset(3, offset_docComplete);
    }
    if (offset_docSummary != null) {
      fbBuilder.addOffset(4, offset_docSummary);
    }
    if (_fieldMask != null && _fieldMask != 0) {
      fbBuilder.addUint32(5, _fieldMask);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(6, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(7, true);
    }
    if (_isDeprecated == true) {
      fbBuilder.addBool(8, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(9, true);
    }
    if (_kind != null && _kind != idl.AvailableDeclarationKind.CLASS) {
      fbBuilder.addUint8(10, _kind.index);
    }
    if (_locationOffset != null && _locationOffset != 0) {
      fbBuilder.addUint32(11, _locationOffset);
    }
    if (_locationStartColumn != null && _locationStartColumn != 0) {
      fbBuilder.addUint32(12, _locationStartColumn);
    }
    if (_locationStartLine != null && _locationStartLine != 0) {
      fbBuilder.addUint32(13, _locationStartLine);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(14, offset_name);
    }
    if (offset_parameterNames != null) {
      fbBuilder.addOffset(15, offset_parameterNames);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(16, offset_parameters);
    }
    if (offset_parameterTypes != null) {
      fbBuilder.addOffset(17, offset_parameterTypes);
    }
    if (offset_relevanceTags != null) {
      fbBuilder.addOffset(18, offset_relevanceTags);
    }
    if (_requiredParameterCount != null && _requiredParameterCount != 0) {
      fbBuilder.addUint32(19, _requiredParameterCount);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(20, offset_returnType);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(21, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableDeclarationReader
    extends fb.TableReader<_AvailableDeclarationImpl> {
  const _AvailableDeclarationReader();

  @override
  _AvailableDeclarationImpl createObject(fb.BufferContext bc, int offset) =>
      new _AvailableDeclarationImpl(bc, offset);
}

class _AvailableDeclarationImpl extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableDeclarationImpl(this._bc, this._bcOffset);

  List<idl.AvailableDeclaration> _children;
  String _defaultArgumentListString;
  List<int> _defaultArgumentListTextRanges;
  String _docComplete;
  String _docSummary;
  int _fieldMask;
  bool _isAbstract;
  bool _isConst;
  bool _isDeprecated;
  bool _isFinal;
  idl.AvailableDeclarationKind _kind;
  int _locationOffset;
  int _locationStartColumn;
  int _locationStartLine;
  String _name;
  List<String> _parameterNames;
  String _parameters;
  List<String> _parameterTypes;
  List<String> _relevanceTags;
  int _requiredParameterCount;
  String _returnType;
  String _typeParameters;

  @override
  List<idl.AvailableDeclaration> get children {
    _children ??= const fb.ListReader<idl.AvailableDeclaration>(
            const _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
    return _children;
  }

  @override
  String get defaultArgumentListString {
    _defaultArgumentListString ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _defaultArgumentListString;
  }

  @override
  List<int> get defaultArgumentListTextRanges {
    _defaultArgumentListTextRanges ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _defaultArgumentListTextRanges;
  }

  @override
  String get docComplete {
    _docComplete ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _docComplete;
  }

  @override
  String get docSummary {
    _docSummary ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
    return _docSummary;
  }

  @override
  int get fieldMask {
    _fieldMask ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _fieldMask;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 6, false);
    return _isAbstract;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 7, false);
    return _isConst;
  }

  @override
  bool get isDeprecated {
    _isDeprecated ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 8, false);
    return _isDeprecated;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 9, false);
    return _isFinal;
  }

  @override
  idl.AvailableDeclarationKind get kind {
    _kind ??= const _AvailableDeclarationKindReader()
        .vTableGet(_bc, _bcOffset, 10, idl.AvailableDeclarationKind.CLASS);
    return _kind;
  }

  @override
  int get locationOffset {
    _locationOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 11, 0);
    return _locationOffset;
  }

  @override
  int get locationStartColumn {
    _locationStartColumn ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 12, 0);
    return _locationStartColumn;
  }

  @override
  int get locationStartLine {
    _locationStartLine ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 13, 0);
    return _locationStartLine;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 14, '');
    return _name;
  }

  @override
  List<String> get parameterNames {
    _parameterNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 15, const <String>[]);
    return _parameterNames;
  }

  @override
  String get parameters {
    _parameters ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 16, '');
    return _parameters;
  }

  @override
  List<String> get parameterTypes {
    _parameterTypes ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 17, const <String>[]);
    return _parameterTypes;
  }

  @override
  List<String> get relevanceTags {
    _relevanceTags ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 18, const <String>[]);
    return _relevanceTags;
  }

  @override
  int get requiredParameterCount {
    _requiredParameterCount ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _requiredParameterCount;
  }

  @override
  String get returnType {
    _returnType ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 20, '');
    return _returnType;
  }

  @override
  String get typeParameters {
    _typeParameters ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 21, '');
    return _typeParameters;
  }
}

abstract class _AvailableDeclarationMixin implements idl.AvailableDeclaration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (children.isNotEmpty)
      _result["children"] = children.map((_value) => _value.toJson()).toList();
    if (defaultArgumentListString != '')
      _result["defaultArgumentListString"] = defaultArgumentListString;
    if (defaultArgumentListTextRanges.isNotEmpty)
      _result["defaultArgumentListTextRanges"] = defaultArgumentListTextRanges;
    if (docComplete != '') _result["docComplete"] = docComplete;
    if (docSummary != '') _result["docSummary"] = docSummary;
    if (fieldMask != 0) _result["fieldMask"] = fieldMask;
    if (isAbstract != false) _result["isAbstract"] = isAbstract;
    if (isConst != false) _result["isConst"] = isConst;
    if (isDeprecated != false) _result["isDeprecated"] = isDeprecated;
    if (isFinal != false) _result["isFinal"] = isFinal;
    if (kind != idl.AvailableDeclarationKind.CLASS)
      _result["kind"] = kind.toString().split('.')[1];
    if (locationOffset != 0) _result["locationOffset"] = locationOffset;
    if (locationStartColumn != 0)
      _result["locationStartColumn"] = locationStartColumn;
    if (locationStartLine != 0)
      _result["locationStartLine"] = locationStartLine;
    if (name != '') _result["name"] = name;
    if (parameterNames.isNotEmpty) _result["parameterNames"] = parameterNames;
    if (parameters != '') _result["parameters"] = parameters;
    if (parameterTypes.isNotEmpty) _result["parameterTypes"] = parameterTypes;
    if (relevanceTags.isNotEmpty) _result["relevanceTags"] = relevanceTags;
    if (requiredParameterCount != 0)
      _result["requiredParameterCount"] = requiredParameterCount;
    if (returnType != '') _result["returnType"] = returnType;
    if (typeParameters != '') _result["typeParameters"] = typeParameters;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "children": children,
        "defaultArgumentListString": defaultArgumentListString,
        "defaultArgumentListTextRanges": defaultArgumentListTextRanges,
        "docComplete": docComplete,
        "docSummary": docSummary,
        "fieldMask": fieldMask,
        "isAbstract": isAbstract,
        "isConst": isConst,
        "isDeprecated": isDeprecated,
        "isFinal": isFinal,
        "kind": kind,
        "locationOffset": locationOffset,
        "locationStartColumn": locationStartColumn,
        "locationStartLine": locationStartLine,
        "name": name,
        "parameterNames": parameterNames,
        "parameters": parameters,
        "parameterTypes": parameterTypes,
        "relevanceTags": relevanceTags,
        "requiredParameterCount": requiredParameterCount,
        "returnType": returnType,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileBuilder extends Object
    with _AvailableFileMixin
    implements idl.AvailableFile {
  List<AvailableDeclarationBuilder> _declarations;
  DirectiveInfoBuilder _directiveInfo;
  List<AvailableFileExportBuilder> _exports;
  bool _isLibrary;
  bool _isLibraryDeprecated;
  List<String> _parts;

  @override
  List<AvailableDeclarationBuilder> get declarations =>
      _declarations ??= <AvailableDeclarationBuilder>[];

  /// Declarations of the file.
  set declarations(List<AvailableDeclarationBuilder> value) {
    this._declarations = value;
  }

  @override
  DirectiveInfoBuilder get directiveInfo => _directiveInfo;

  /// The Dartdoc directives in the file.
  set directiveInfo(DirectiveInfoBuilder value) {
    this._directiveInfo = value;
  }

  @override
  List<AvailableFileExportBuilder> get exports =>
      _exports ??= <AvailableFileExportBuilder>[];

  /// Exports directives of the file.
  set exports(List<AvailableFileExportBuilder> value) {
    this._exports = value;
  }

  @override
  bool get isLibrary => _isLibrary ??= false;

  /// Is `true` if this file is a library.
  set isLibrary(bool value) {
    this._isLibrary = value;
  }

  @override
  bool get isLibraryDeprecated => _isLibraryDeprecated ??= false;

  /// Is `true` if this file is a library, and it is deprecated.
  set isLibraryDeprecated(bool value) {
    this._isLibraryDeprecated = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /// URIs of `part` directives.
  set parts(List<String> value) {
    this._parts = value;
  }

  AvailableFileBuilder(
      {List<AvailableDeclarationBuilder> declarations,
      DirectiveInfoBuilder directiveInfo,
      List<AvailableFileExportBuilder> exports,
      bool isLibrary,
      bool isLibraryDeprecated,
      List<String> parts})
      : _declarations = declarations,
        _directiveInfo = directiveInfo,
        _exports = exports,
        _isLibrary = isLibrary,
        _isLibraryDeprecated = isLibraryDeprecated,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _declarations?.forEach((b) => b.flushInformative());
    _directiveInfo?.flushInformative();
    _exports?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._declarations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._declarations.length);
      for (var x in this._declarations) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isLibrary == true);
    signature.addBool(this._isLibraryDeprecated == true);
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        signature.addString(x);
      }
    }
    signature.addBool(this._directiveInfo != null);
    this._directiveInfo?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UICF");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_declarations;
    fb.Offset offset_directiveInfo;
    fb.Offset offset_exports;
    fb.Offset offset_parts;
    if (!(_declarations == null || _declarations.isEmpty)) {
      offset_declarations = fbBuilder
          .writeList(_declarations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_directiveInfo != null) {
      offset_directiveInfo = _directiveInfo.finish(fbBuilder);
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder
          .writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_declarations != null) {
      fbBuilder.addOffset(0, offset_declarations);
    }
    if (offset_directiveInfo != null) {
      fbBuilder.addOffset(5, offset_directiveInfo);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(1, offset_exports);
    }
    if (_isLibrary == true) {
      fbBuilder.addBool(2, true);
    }
    if (_isLibraryDeprecated == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(4, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.AvailableFile readAvailableFile(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _AvailableFileReader().read(rootRef, 0);
}

class _AvailableFileReader extends fb.TableReader<_AvailableFileImpl> {
  const _AvailableFileReader();

  @override
  _AvailableFileImpl createObject(fb.BufferContext bc, int offset) =>
      new _AvailableFileImpl(bc, offset);
}

class _AvailableFileImpl extends Object
    with _AvailableFileMixin
    implements idl.AvailableFile {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileImpl(this._bc, this._bcOffset);

  List<idl.AvailableDeclaration> _declarations;
  idl.DirectiveInfo _directiveInfo;
  List<idl.AvailableFileExport> _exports;
  bool _isLibrary;
  bool _isLibraryDeprecated;
  List<String> _parts;

  @override
  List<idl.AvailableDeclaration> get declarations {
    _declarations ??= const fb.ListReader<idl.AvailableDeclaration>(
            const _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
    return _declarations;
  }

  @override
  idl.DirectiveInfo get directiveInfo {
    _directiveInfo ??=
        const _DirectiveInfoReader().vTableGet(_bc, _bcOffset, 5, null);
    return _directiveInfo;
  }

  @override
  List<idl.AvailableFileExport> get exports {
    _exports ??= const fb.ListReader<idl.AvailableFileExport>(
            const _AvailableFileExportReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.AvailableFileExport>[]);
    return _exports;
  }

  @override
  bool get isLibrary {
    _isLibrary ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isLibrary;
  }

  @override
  bool get isLibraryDeprecated {
    _isLibraryDeprecated ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isLibraryDeprecated;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _parts;
  }
}

abstract class _AvailableFileMixin implements idl.AvailableFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (declarations.isNotEmpty)
      _result["declarations"] =
          declarations.map((_value) => _value.toJson()).toList();
    if (directiveInfo != null)
      _result["directiveInfo"] = directiveInfo.toJson();
    if (exports.isNotEmpty)
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    if (isLibrary != false) _result["isLibrary"] = isLibrary;
    if (isLibraryDeprecated != false)
      _result["isLibraryDeprecated"] = isLibraryDeprecated;
    if (parts.isNotEmpty) _result["parts"] = parts;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "declarations": declarations,
        "directiveInfo": directiveInfo,
        "exports": exports,
        "isLibrary": isLibrary,
        "isLibraryDeprecated": isLibraryDeprecated,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileExportBuilder extends Object
    with _AvailableFileExportMixin
    implements idl.AvailableFileExport {
  List<AvailableFileExportCombinatorBuilder> _combinators;
  String _uri;

  @override
  List<AvailableFileExportCombinatorBuilder> get combinators =>
      _combinators ??= <AvailableFileExportCombinatorBuilder>[];

  /// Combinators contained in this export directive.
  set combinators(List<AvailableFileExportCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  String get uri => _uri ??= '';

  /// URI of the exported library.
  set uri(String value) {
    this._uri = value;
  }

  AvailableFileExportBuilder(
      {List<AvailableFileExportCombinatorBuilder> combinators, String uri})
      : _combinators = combinators,
        _uri = uri;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _combinators?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uri ?? '');
    if (this._combinators == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._combinators.length);
      for (var x in this._combinators) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_combinators;
    fb.Offset offset_uri;
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder
          .writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_combinators != null) {
      fbBuilder.addOffset(1, offset_combinators);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableFileExportReader
    extends fb.TableReader<_AvailableFileExportImpl> {
  const _AvailableFileExportReader();

  @override
  _AvailableFileExportImpl createObject(fb.BufferContext bc, int offset) =>
      new _AvailableFileExportImpl(bc, offset);
}

class _AvailableFileExportImpl extends Object
    with _AvailableFileExportMixin
    implements idl.AvailableFileExport {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileExportImpl(this._bc, this._bcOffset);

  List<idl.AvailableFileExportCombinator> _combinators;
  String _uri;

  @override
  List<idl.AvailableFileExportCombinator> get combinators {
    _combinators ??= const fb.ListReader<idl.AvailableFileExportCombinator>(
            const _AvailableFileExportCombinatorReader())
        .vTableGet(
            _bc, _bcOffset, 1, const <idl.AvailableFileExportCombinator>[]);
    return _combinators;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uri;
  }
}

abstract class _AvailableFileExportMixin implements idl.AvailableFileExport {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (combinators.isNotEmpty)
      _result["combinators"] =
          combinators.map((_value) => _value.toJson()).toList();
    if (uri != '') _result["uri"] = uri;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "combinators": combinators,
        "uri": uri,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileExportCombinatorBuilder extends Object
    with _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  List<String> _hides;
  List<String> _shows;

  @override
  List<String> get hides => _hides ??= <String>[];

  /// List of names which are hidden.  Empty if this is a `show` combinator.
  set hides(List<String> value) {
    this._hides = value;
  }

  @override
  List<String> get shows => _shows ??= <String>[];

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  set shows(List<String> value) {
    this._shows = value;
  }

  AvailableFileExportCombinatorBuilder({List<String> hides, List<String> shows})
      : _hides = hides,
        _shows = shows;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._shows == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._shows.length);
      for (var x in this._shows) {
        signature.addString(x);
      }
    }
    if (this._hides == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._hides.length);
      for (var x in this._hides) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_hides;
    fb.Offset offset_shows;
    if (!(_hides == null || _hides.isEmpty)) {
      offset_hides = fbBuilder
          .writeList(_hides.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_shows == null || _shows.isEmpty)) {
      offset_shows = fbBuilder
          .writeList(_shows.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_hides != null) {
      fbBuilder.addOffset(1, offset_hides);
    }
    if (offset_shows != null) {
      fbBuilder.addOffset(0, offset_shows);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableFileExportCombinatorReader
    extends fb.TableReader<_AvailableFileExportCombinatorImpl> {
  const _AvailableFileExportCombinatorReader();

  @override
  _AvailableFileExportCombinatorImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _AvailableFileExportCombinatorImpl(bc, offset);
}

class _AvailableFileExportCombinatorImpl extends Object
    with _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileExportCombinatorImpl(this._bc, this._bcOffset);

  List<String> _hides;
  List<String> _shows;

  @override
  List<String> get hides {
    _hides ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _hides;
  }

  @override
  List<String> get shows {
    _shows ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _shows;
  }
}

abstract class _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (hides.isNotEmpty) _result["hides"] = hides;
    if (shows.isNotEmpty) _result["shows"] = shows;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "hides": hides,
        "shows": shows,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class CodeRangeBuilder extends Object
    with _CodeRangeMixin
    implements idl.CodeRange {
  int _length;
  int _offset;

  @override
  int get length => _length ??= 0;

  /// Length of the element code.
  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// Offset of the element code relative to the beginning of the file.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  CodeRangeBuilder({int length, int offset})
      : _length = length,
        _offset = offset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fbBuilder.startTable();
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(1, _length);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    return fbBuilder.endTable();
  }
}

class _CodeRangeReader extends fb.TableReader<_CodeRangeImpl> {
  const _CodeRangeReader();

  @override
  _CodeRangeImpl createObject(fb.BufferContext bc, int offset) =>
      new _CodeRangeImpl(bc, offset);
}

class _CodeRangeImpl extends Object
    with _CodeRangeMixin
    implements idl.CodeRange {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _CodeRangeImpl(this._bc, this._bcOffset);

  int _length;
  int _offset;

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _length;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _offset;
  }
}

abstract class _CodeRangeMixin implements idl.CodeRange {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (length != 0) _result["length"] = length;
    if (offset != 0) _result["offset"] = offset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "length": length,
        "offset": offset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class DirectiveInfoBuilder extends Object
    with _DirectiveInfoMixin
    implements idl.DirectiveInfo {
  List<String> _templateNames;
  List<String> _templateValues;

  @override
  List<String> get templateNames => _templateNames ??= <String>[];

  /// The names of the defined templates.
  set templateNames(List<String> value) {
    this._templateNames = value;
  }

  @override
  List<String> get templateValues => _templateValues ??= <String>[];

  /// The values of the defined templates.
  set templateValues(List<String> value) {
    this._templateValues = value;
  }

  DirectiveInfoBuilder(
      {List<String> templateNames, List<String> templateValues})
      : _templateNames = templateNames,
        _templateValues = templateValues;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._templateNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._templateNames.length);
      for (var x in this._templateNames) {
        signature.addString(x);
      }
    }
    if (this._templateValues == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._templateValues.length);
      for (var x in this._templateValues) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_templateNames;
    fb.Offset offset_templateValues;
    if (!(_templateNames == null || _templateNames.isEmpty)) {
      offset_templateNames = fbBuilder.writeList(
          _templateNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_templateValues == null || _templateValues.isEmpty)) {
      offset_templateValues = fbBuilder.writeList(
          _templateValues.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_templateNames != null) {
      fbBuilder.addOffset(0, offset_templateNames);
    }
    if (offset_templateValues != null) {
      fbBuilder.addOffset(1, offset_templateValues);
    }
    return fbBuilder.endTable();
  }
}

class _DirectiveInfoReader extends fb.TableReader<_DirectiveInfoImpl> {
  const _DirectiveInfoReader();

  @override
  _DirectiveInfoImpl createObject(fb.BufferContext bc, int offset) =>
      new _DirectiveInfoImpl(bc, offset);
}

class _DirectiveInfoImpl extends Object
    with _DirectiveInfoMixin
    implements idl.DirectiveInfo {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _DirectiveInfoImpl(this._bc, this._bcOffset);

  List<String> _templateNames;
  List<String> _templateValues;

  @override
  List<String> get templateNames {
    _templateNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _templateNames;
  }

  @override
  List<String> get templateValues {
    _templateValues ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _templateValues;
  }
}

abstract class _DirectiveInfoMixin implements idl.DirectiveInfo {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (templateNames.isNotEmpty) _result["templateNames"] = templateNames;
    if (templateValues.isNotEmpty) _result["templateValues"] = templateValues;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "templateNames": templateNames,
        "templateValues": templateValues,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class EntityRefBuilder extends Object
    with _EntityRefMixin
    implements idl.EntityRef {
  idl.EntityRefKind _entityKind;
  List<int> _implicitFunctionTypeIndices;
  idl.EntityRefNullabilitySuffix _nullabilitySuffix;
  int _paramReference;
  int _reference;
  int _refinedSlot;
  int _slot;
  List<UnlinkedParamBuilder> _syntheticParams;
  EntityRefBuilder _syntheticReturnType;
  List<EntityRefBuilder> _typeArguments;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  idl.EntityRefKind get entityKind => _entityKind ??= idl.EntityRefKind.named;

  /// The kind of entity being represented.
  set entityKind(idl.EntityRefKind value) {
    this._entityKind = value;
  }

  @override
  List<int> get implicitFunctionTypeIndices =>
      _implicitFunctionTypeIndices ??= <int>[];

  /// Notice: This will be deprecated. However, its not deprecated yet, as we're
  /// keeping it for backwards compatibilty, and marking it deprecated makes it
  /// unreadable.
  ///
  /// TODO(mfairhurst) mark this deprecated, and remove its logic.
  ///
  /// If this is a reference to a function type implicitly defined by a
  /// function-typed parameter, a list of zero-based indices indicating the path
  /// from the entity referred to by [reference] to the appropriate type
  /// parameter.  Otherwise the empty list.
  ///
  /// If there are N indices in this list, then the entity being referred to is
  /// the function type implicitly defined by a function-typed parameter of a
  /// function-typed parameter, to N levels of nesting.  The first index in the
  /// list refers to the outermost level of nesting; for example if [reference]
  /// refers to the entity defined by:
  ///
  ///     void f(x, void g(y, z, int h(String w))) { ... }
  ///
  /// Then to refer to the function type implicitly defined by parameter `h`
  /// (which is parameter 2 of parameter 1 of `f`), then
  /// [implicitFunctionTypeIndices] should be [1, 2].
  ///
  /// Note that if the entity being referred to is a generic method inside a
  /// generic class, then the type arguments in [typeArguments] are applied
  /// first to the class and then to the method.
  set implicitFunctionTypeIndices(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._implicitFunctionTypeIndices = value;
  }

  @override
  idl.EntityRefNullabilitySuffix get nullabilitySuffix =>
      _nullabilitySuffix ??= idl.EntityRefNullabilitySuffix.starOrIrrelevant;

  /// If the reference represents a type, the nullability of the type.
  set nullabilitySuffix(idl.EntityRefNullabilitySuffix value) {
    this._nullabilitySuffix = value;
  }

  @override
  int get paramReference => _paramReference ??= 0;

  /// If this is a reference to a type parameter, one-based index into the list
  /// of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
  /// Bruijn index conventions; that is, innermost parameters come first, and
  /// if a class or method has multiple parameters, they are indexed from right
  /// to left.  So for instance, if the enclosing declaration is
  ///
  ///     class C<T,U> {
  ///       m<V,W> {
  ///         ...
  ///       }
  ///     }
  ///
  /// Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
  /// respectively.
  ///
  /// If the type being referred to is not a type parameter, [paramReference] is
  /// zero.
  set paramReference(int value) {
    assert(value == null || value >= 0);
    this._paramReference = value;
  }

  @override
  int get reference => _reference ??= 0;

  /// Index into [UnlinkedUnit.references] for the entity being referred to, or
  /// zero if this is a reference to a type parameter.
  set reference(int value) {
    assert(value == null || value >= 0);
    this._reference = value;
  }

  @override
  int get refinedSlot => _refinedSlot ??= 0;

  /// If this [EntityRef] appears in a syntactic context where its type
  /// arguments might need to be inferred by a method other than
  /// instantiate-to-bounds, and [typeArguments] is empty, a slot id (which is
  /// unique within the compilation unit).  If an entry appears in
  /// [LinkedUnit.types] whose [slot] matches this value, that entry will
  /// contain the complete inferred type.
  ///
  /// This is called `refinedSlot` to clarify that if it points to an inferred
  /// type, it points to a type that is a "refinement" of this one (one in which
  /// some type arguments have been inferred).
  set refinedSlot(int value) {
    assert(value == null || value >= 0);
    this._refinedSlot = value;
  }

  @override
  int get slot => _slot ??= 0;

  /// If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
  /// is unique within the compilation unit) identifying the target of type
  /// propagation or type inference with which this [EntityRef] is associated.
  ///
  /// Otherwise zero.
  set slot(int value) {
    assert(value == null || value >= 0);
    this._slot = value;
  }

  @override
  List<UnlinkedParamBuilder> get syntheticParams =>
      _syntheticParams ??= <UnlinkedParamBuilder>[];

  /// If this [EntityRef] is a reference to a function type whose
  /// [FunctionElement] is not in any library (e.g. a function type that was
  /// synthesized by a LUB computation), the function parameters.  Otherwise
  /// empty.
  set syntheticParams(List<UnlinkedParamBuilder> value) {
    this._syntheticParams = value;
  }

  @override
  EntityRefBuilder get syntheticReturnType => _syntheticReturnType;

  /// If this [EntityRef] is a reference to a function type whose
  /// [FunctionElement] is not in any library (e.g. a function type that was
  /// synthesized by a LUB computation), the return type of the function.
  /// Otherwise `null`.
  set syntheticReturnType(EntityRefBuilder value) {
    this._syntheticReturnType = value;
  }

  @override
  List<EntityRefBuilder> get typeArguments =>
      _typeArguments ??= <EntityRefBuilder>[];

  /// If this is an instantiation of a generic type or generic executable, the
  /// type arguments used to instantiate it (if any).
  set typeArguments(List<EntityRefBuilder> value) {
    this._typeArguments = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /// If this is a function type, the type parameters defined for the function
  /// type (if any).
  set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  EntityRefBuilder(
      {idl.EntityRefKind entityKind,
      List<int> implicitFunctionTypeIndices,
      idl.EntityRefNullabilitySuffix nullabilitySuffix,
      int paramReference,
      int reference,
      int refinedSlot,
      int slot,
      List<UnlinkedParamBuilder> syntheticParams,
      EntityRefBuilder syntheticReturnType,
      List<EntityRefBuilder> typeArguments,
      List<UnlinkedTypeParamBuilder> typeParameters})
      : _entityKind = entityKind,
        _implicitFunctionTypeIndices = implicitFunctionTypeIndices,
        _nullabilitySuffix = nullabilitySuffix,
        _paramReference = paramReference,
        _reference = reference,
        _refinedSlot = refinedSlot,
        _slot = slot,
        _syntheticParams = syntheticParams,
        _syntheticReturnType = syntheticReturnType,
        _typeArguments = typeArguments,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _syntheticParams?.forEach((b) => b.flushInformative());
    _syntheticReturnType?.flushInformative();
    _typeArguments?.forEach((b) => b.flushInformative());
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._reference ?? 0);
    if (this._typeArguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeArguments.length);
      for (var x in this._typeArguments) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._slot ?? 0);
    signature.addInt(this._paramReference ?? 0);
    if (this._implicitFunctionTypeIndices == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._implicitFunctionTypeIndices.length);
      for (var x in this._implicitFunctionTypeIndices) {
        signature.addInt(x);
      }
    }
    signature.addBool(this._syntheticReturnType != null);
    this._syntheticReturnType?.collectApiSignature(signature);
    if (this._syntheticParams == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._syntheticParams.length);
      for (var x in this._syntheticParams) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._typeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeParameters.length);
      for (var x in this._typeParameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._entityKind == null ? 0 : this._entityKind.index);
    signature.addInt(this._refinedSlot ?? 0);
    signature.addInt(
        this._nullabilitySuffix == null ? 0 : this._nullabilitySuffix.index);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_implicitFunctionTypeIndices;
    fb.Offset offset_syntheticParams;
    fb.Offset offset_syntheticReturnType;
    fb.Offset offset_typeArguments;
    fb.Offset offset_typeParameters;
    if (!(_implicitFunctionTypeIndices == null ||
        _implicitFunctionTypeIndices.isEmpty)) {
      offset_implicitFunctionTypeIndices =
          fbBuilder.writeListUint32(_implicitFunctionTypeIndices);
    }
    if (!(_syntheticParams == null || _syntheticParams.isEmpty)) {
      offset_syntheticParams = fbBuilder
          .writeList(_syntheticParams.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_syntheticReturnType != null) {
      offset_syntheticReturnType = _syntheticReturnType.finish(fbBuilder);
    }
    if (!(_typeArguments == null || _typeArguments.isEmpty)) {
      offset_typeArguments = fbBuilder
          .writeList(_typeArguments.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder
          .writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (_entityKind != null && _entityKind != idl.EntityRefKind.named) {
      fbBuilder.addUint8(8, _entityKind.index);
    }
    if (offset_implicitFunctionTypeIndices != null) {
      fbBuilder.addOffset(4, offset_implicitFunctionTypeIndices);
    }
    if (_nullabilitySuffix != null &&
        _nullabilitySuffix != idl.EntityRefNullabilitySuffix.starOrIrrelevant) {
      fbBuilder.addUint8(10, _nullabilitySuffix.index);
    }
    if (_paramReference != null && _paramReference != 0) {
      fbBuilder.addUint32(3, _paramReference);
    }
    if (_reference != null && _reference != 0) {
      fbBuilder.addUint32(0, _reference);
    }
    if (_refinedSlot != null && _refinedSlot != 0) {
      fbBuilder.addUint32(9, _refinedSlot);
    }
    if (_slot != null && _slot != 0) {
      fbBuilder.addUint32(2, _slot);
    }
    if (offset_syntheticParams != null) {
      fbBuilder.addOffset(6, offset_syntheticParams);
    }
    if (offset_syntheticReturnType != null) {
      fbBuilder.addOffset(5, offset_syntheticReturnType);
    }
    if (offset_typeArguments != null) {
      fbBuilder.addOffset(1, offset_typeArguments);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(7, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _EntityRefReader extends fb.TableReader<_EntityRefImpl> {
  const _EntityRefReader();

  @override
  _EntityRefImpl createObject(fb.BufferContext bc, int offset) =>
      new _EntityRefImpl(bc, offset);
}

class _EntityRefImpl extends Object
    with _EntityRefMixin
    implements idl.EntityRef {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _EntityRefImpl(this._bc, this._bcOffset);

  idl.EntityRefKind _entityKind;
  List<int> _implicitFunctionTypeIndices;
  idl.EntityRefNullabilitySuffix _nullabilitySuffix;
  int _paramReference;
  int _reference;
  int _refinedSlot;
  int _slot;
  List<idl.UnlinkedParam> _syntheticParams;
  idl.EntityRef _syntheticReturnType;
  List<idl.EntityRef> _typeArguments;
  List<idl.UnlinkedTypeParam> _typeParameters;

  @override
  idl.EntityRefKind get entityKind {
    _entityKind ??= const _EntityRefKindReader()
        .vTableGet(_bc, _bcOffset, 8, idl.EntityRefKind.named);
    return _entityKind;
  }

  @override
  List<int> get implicitFunctionTypeIndices {
    _implicitFunctionTypeIndices ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 4, const <int>[]);
    return _implicitFunctionTypeIndices;
  }

  @override
  idl.EntityRefNullabilitySuffix get nullabilitySuffix {
    _nullabilitySuffix ??= const _EntityRefNullabilitySuffixReader().vTableGet(
        _bc, _bcOffset, 10, idl.EntityRefNullabilitySuffix.starOrIrrelevant);
    return _nullabilitySuffix;
  }

  @override
  int get paramReference {
    _paramReference ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _paramReference;
  }

  @override
  int get reference {
    _reference ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _reference;
  }

  @override
  int get refinedSlot {
    _refinedSlot ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _refinedSlot;
  }

  @override
  int get slot {
    _slot ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _slot;
  }

  @override
  List<idl.UnlinkedParam> get syntheticParams {
    _syntheticParams ??=
        const fb.ListReader<idl.UnlinkedParam>(const _UnlinkedParamReader())
            .vTableGet(_bc, _bcOffset, 6, const <idl.UnlinkedParam>[]);
    return _syntheticParams;
  }

  @override
  idl.EntityRef get syntheticReturnType {
    _syntheticReturnType ??=
        const _EntityRefReader().vTableGet(_bc, _bcOffset, 5, null);
    return _syntheticReturnType;
  }

  @override
  List<idl.EntityRef> get typeArguments {
    _typeArguments ??=
        const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
            .vTableGet(_bc, _bcOffset, 1, const <idl.EntityRef>[]);
    return _typeArguments;
  }

  @override
  List<idl.UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<idl.UnlinkedTypeParam>(
            const _UnlinkedTypeParamReader())
        .vTableGet(_bc, _bcOffset, 7, const <idl.UnlinkedTypeParam>[]);
    return _typeParameters;
  }
}

abstract class _EntityRefMixin implements idl.EntityRef {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (entityKind != idl.EntityRefKind.named)
      _result["entityKind"] = entityKind.toString().split('.')[1];
    if (implicitFunctionTypeIndices.isNotEmpty)
      _result["implicitFunctionTypeIndices"] = implicitFunctionTypeIndices;
    if (nullabilitySuffix != idl.EntityRefNullabilitySuffix.starOrIrrelevant)
      _result["nullabilitySuffix"] = nullabilitySuffix.toString().split('.')[1];
    if (paramReference != 0) _result["paramReference"] = paramReference;
    if (reference != 0) _result["reference"] = reference;
    if (refinedSlot != 0) _result["refinedSlot"] = refinedSlot;
    if (slot != 0) _result["slot"] = slot;
    if (syntheticParams.isNotEmpty)
      _result["syntheticParams"] =
          syntheticParams.map((_value) => _value.toJson()).toList();
    if (syntheticReturnType != null)
      _result["syntheticReturnType"] = syntheticReturnType.toJson();
    if (typeArguments.isNotEmpty)
      _result["typeArguments"] =
          typeArguments.map((_value) => _value.toJson()).toList();
    if (typeParameters.isNotEmpty)
      _result["typeParameters"] =
          typeParameters.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "entityKind": entityKind,
        "implicitFunctionTypeIndices": implicitFunctionTypeIndices,
        "nullabilitySuffix": nullabilitySuffix,
        "paramReference": paramReference,
        "reference": reference,
        "refinedSlot": refinedSlot,
        "slot": slot,
        "syntheticParams": syntheticParams,
        "syntheticReturnType": syntheticReturnType,
        "typeArguments": typeArguments,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedDependencyBuilder extends Object
    with _LinkedDependencyMixin
    implements idl.LinkedDependency {
  List<String> _parts;
  String _uri;

  @override
  List<String> get parts => _parts ??= <String>[];

  /// Absolute URI for the compilation units listed in the library's `part`
  /// declarations, empty string for invalid URI.
  set parts(List<String> value) {
    this._parts = value;
  }

  @override
  String get uri => _uri ??= '';

  /// The absolute URI of the dependent library, e.g. `package:foo/bar.dart`.
  set uri(String value) {
    this._uri = value;
  }

  LinkedDependencyBuilder({List<String> parts, String uri})
      : _parts = parts,
        _uri = uri;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uri ?? '');
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_parts;
    fb.Offset offset_uri;
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder
          .writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_parts != null) {
      fbBuilder.addOffset(1, offset_parts);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedDependencyReader extends fb.TableReader<_LinkedDependencyImpl> {
  const _LinkedDependencyReader();

  @override
  _LinkedDependencyImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedDependencyImpl(bc, offset);
}

class _LinkedDependencyImpl extends Object
    with _LinkedDependencyMixin
    implements idl.LinkedDependency {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedDependencyImpl(this._bc, this._bcOffset);

  List<String> _parts;
  String _uri;

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _parts;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uri;
  }
}

abstract class _LinkedDependencyMixin implements idl.LinkedDependency {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (parts.isNotEmpty) _result["parts"] = parts;
    if (uri != '') _result["uri"] = uri;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "parts": parts,
        "uri": uri,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedExportNameBuilder extends Object
    with _LinkedExportNameMixin
    implements idl.LinkedExportName {
  int _dependency;
  idl.ReferenceKind _kind;
  String _name;
  int _unit;

  @override
  int get dependency => _dependency ??= 0;

  /// Index into [LinkedLibrary.dependencies] for the library in which the
  /// entity is defined.
  set dependency(int value) {
    assert(value == null || value >= 0);
    this._dependency = value;
  }

  @override
  idl.ReferenceKind get kind => _kind ??= idl.ReferenceKind.classOrEnum;

  /// The kind of the entity being referred to.
  set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the exported entity.  For an exported setter, this name includes
  /// the trailing '='.
  set name(String value) {
    this._name = value;
  }

  @override
  int get unit => _unit ??= 0;

  /// Integer index indicating which unit in the exported library contains the
  /// definition of the entity.  As with indices into [LinkedLibrary.units],
  /// zero represents the defining compilation unit, and nonzero values
  /// represent parts in the order of the corresponding `part` declarations.
  set unit(int value) {
    assert(value == null || value >= 0);
    this._unit = value;
  }

  LinkedExportNameBuilder(
      {int dependency, idl.ReferenceKind kind, String name, int unit})
      : _dependency = dependency,
        _kind = kind,
        _name = name,
        _unit = unit;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._dependency ?? 0);
    signature.addString(this._name ?? '');
    signature.addInt(this._unit ?? 0);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (_dependency != null && _dependency != 0) {
      fbBuilder.addUint32(0, _dependency);
    }
    if (_kind != null && _kind != idl.ReferenceKind.classOrEnum) {
      fbBuilder.addUint8(3, _kind.index);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(1, offset_name);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addUint32(2, _unit);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedExportNameReader extends fb.TableReader<_LinkedExportNameImpl> {
  const _LinkedExportNameReader();

  @override
  _LinkedExportNameImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedExportNameImpl(bc, offset);
}

class _LinkedExportNameImpl extends Object
    with _LinkedExportNameMixin
    implements idl.LinkedExportName {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedExportNameImpl(this._bc, this._bcOffset);

  int _dependency;
  idl.ReferenceKind _kind;
  String _name;
  int _unit;

  @override
  int get dependency {
    _dependency ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _dependency;
  }

  @override
  idl.ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader()
        .vTableGet(_bc, _bcOffset, 3, idl.ReferenceKind.classOrEnum);
    return _kind;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _name;
  }

  @override
  int get unit {
    _unit ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _unit;
  }
}

abstract class _LinkedExportNameMixin implements idl.LinkedExportName {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (dependency != 0) _result["dependency"] = dependency;
    if (kind != idl.ReferenceKind.classOrEnum)
      _result["kind"] = kind.toString().split('.')[1];
    if (name != '') _result["name"] = name;
    if (unit != 0) _result["unit"] = unit;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "dependency": dependency,
        "kind": kind,
        "name": name,
        "unit": unit,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedLibraryBuilder extends Object
    with _LinkedLibraryMixin
    implements idl.LinkedLibrary {
  List<LinkedDependencyBuilder> _dependencies;
  List<int> _exportDependencies;
  List<LinkedExportNameBuilder> _exportNames;
  List<int> _importDependencies;
  int _numPrelinkedDependencies;
  List<LinkedUnitBuilder> _units;

  @override
  List<LinkedDependencyBuilder> get dependencies =>
      _dependencies ??= <LinkedDependencyBuilder>[];

  /// The libraries that this library depends on (either via an explicit import
  /// statement or via the implicit dependencies on `dart:core` and
  /// `dart:async`).  The first element of this array is a pseudo-dependency
  /// representing the library itself (it is also used for `dynamic` and
  /// `void`).  This is followed by elements representing "prelinked"
  /// dependencies (direct imports and the transitive closure of exports).
  /// After the prelinked dependencies are elements representing "linked"
  /// dependencies.
  ///
  /// A library is only included as a "linked" dependency if it is a true
  /// dependency (e.g. a propagated or inferred type or constant value
  /// implicitly refers to an element declared in the library) or
  /// anti-dependency (e.g. the result of type propagation or type inference
  /// depends on the lack of a certain declaration in the library).
  set dependencies(List<LinkedDependencyBuilder> value) {
    this._dependencies = value;
  }

  @override
  List<int> get exportDependencies => _exportDependencies ??= <int>[];

  /// For each export in [UnlinkedUnit.exports], an index into [dependencies]
  /// of the library being exported.
  set exportDependencies(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._exportDependencies = value;
  }

  @override
  List<LinkedExportNameBuilder> get exportNames =>
      _exportNames ??= <LinkedExportNameBuilder>[];

  /// Information about entities in the export namespace of the library that are
  /// not in the public namespace of the library (that is, entities that are
  /// brought into the namespace via `export` directives).
  ///
  /// Sorted by name.
  set exportNames(List<LinkedExportNameBuilder> value) {
    this._exportNames = value;
  }

  @override
  Null get fallbackMode =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<int> get importDependencies => _importDependencies ??= <int>[];

  /// For each import in [UnlinkedUnit.imports], an index into [dependencies]
  /// of the library being imported.
  set importDependencies(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._importDependencies = value;
  }

  @override
  int get numPrelinkedDependencies => _numPrelinkedDependencies ??= 0;

  /// The number of elements in [dependencies] which are not "linked"
  /// dependencies (that is, the number of libraries in the direct imports plus
  /// the transitive closure of exports, plus the library itself).
  set numPrelinkedDependencies(int value) {
    assert(value == null || value >= 0);
    this._numPrelinkedDependencies = value;
  }

  @override
  List<LinkedUnitBuilder> get units => _units ??= <LinkedUnitBuilder>[];

  /// The linked summary of all the compilation units constituting the
  /// library.  The summary of the defining compilation unit is listed first,
  /// followed by the summary of each part, in the order of the `part`
  /// declarations in the defining compilation unit.
  set units(List<LinkedUnitBuilder> value) {
    this._units = value;
  }

  LinkedLibraryBuilder(
      {List<LinkedDependencyBuilder> dependencies,
      List<int> exportDependencies,
      List<LinkedExportNameBuilder> exportNames,
      List<int> importDependencies,
      int numPrelinkedDependencies,
      List<LinkedUnitBuilder> units})
      : _dependencies = dependencies,
        _exportDependencies = exportDependencies,
        _exportNames = exportNames,
        _importDependencies = importDependencies,
        _numPrelinkedDependencies = numPrelinkedDependencies,
        _units = units;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _dependencies?.forEach((b) => b.flushInformative());
    _exportNames?.forEach((b) => b.flushInformative());
    _units?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._dependencies == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._dependencies.length);
      for (var x in this._dependencies) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._importDependencies == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._importDependencies.length);
      for (var x in this._importDependencies) {
        signature.addInt(x);
      }
    }
    signature.addInt(this._numPrelinkedDependencies ?? 0);
    if (this._units == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._units.length);
      for (var x in this._units) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exportNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exportNames.length);
      for (var x in this._exportNames) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exportDependencies == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exportDependencies.length);
      for (var x in this._exportDependencies) {
        signature.addInt(x);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "LLib");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_dependencies;
    fb.Offset offset_exportDependencies;
    fb.Offset offset_exportNames;
    fb.Offset offset_importDependencies;
    fb.Offset offset_units;
    if (!(_dependencies == null || _dependencies.isEmpty)) {
      offset_dependencies = fbBuilder
          .writeList(_dependencies.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_exportDependencies == null || _exportDependencies.isEmpty)) {
      offset_exportDependencies =
          fbBuilder.writeListUint32(_exportDependencies);
    }
    if (!(_exportNames == null || _exportNames.isEmpty)) {
      offset_exportNames = fbBuilder
          .writeList(_exportNames.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_importDependencies == null || _importDependencies.isEmpty)) {
      offset_importDependencies =
          fbBuilder.writeListUint32(_importDependencies);
    }
    if (!(_units == null || _units.isEmpty)) {
      offset_units =
          fbBuilder.writeList(_units.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_dependencies != null) {
      fbBuilder.addOffset(0, offset_dependencies);
    }
    if (offset_exportDependencies != null) {
      fbBuilder.addOffset(6, offset_exportDependencies);
    }
    if (offset_exportNames != null) {
      fbBuilder.addOffset(4, offset_exportNames);
    }
    if (offset_importDependencies != null) {
      fbBuilder.addOffset(1, offset_importDependencies);
    }
    if (_numPrelinkedDependencies != null && _numPrelinkedDependencies != 0) {
      fbBuilder.addUint32(2, _numPrelinkedDependencies);
    }
    if (offset_units != null) {
      fbBuilder.addOffset(3, offset_units);
    }
    return fbBuilder.endTable();
  }
}

idl.LinkedLibrary readLinkedLibrary(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _LinkedLibraryReader().read(rootRef, 0);
}

class _LinkedLibraryReader extends fb.TableReader<_LinkedLibraryImpl> {
  const _LinkedLibraryReader();

  @override
  _LinkedLibraryImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedLibraryImpl(bc, offset);
}

class _LinkedLibraryImpl extends Object
    with _LinkedLibraryMixin
    implements idl.LinkedLibrary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedLibraryImpl(this._bc, this._bcOffset);

  List<idl.LinkedDependency> _dependencies;
  List<int> _exportDependencies;
  List<idl.LinkedExportName> _exportNames;
  List<int> _importDependencies;
  int _numPrelinkedDependencies;
  List<idl.LinkedUnit> _units;

  @override
  List<idl.LinkedDependency> get dependencies {
    _dependencies ??= const fb.ListReader<idl.LinkedDependency>(
            const _LinkedDependencyReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.LinkedDependency>[]);
    return _dependencies;
  }

  @override
  List<int> get exportDependencies {
    _exportDependencies ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 6, const <int>[]);
    return _exportDependencies;
  }

  @override
  List<idl.LinkedExportName> get exportNames {
    _exportNames ??= const fb.ListReader<idl.LinkedExportName>(
            const _LinkedExportNameReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedExportName>[]);
    return _exportNames;
  }

  @override
  Null get fallbackMode =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<int> get importDependencies {
    _importDependencies ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
    return _importDependencies;
  }

  @override
  int get numPrelinkedDependencies {
    _numPrelinkedDependencies ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _numPrelinkedDependencies;
  }

  @override
  List<idl.LinkedUnit> get units {
    _units ??= const fb.ListReader<idl.LinkedUnit>(const _LinkedUnitReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedUnit>[]);
    return _units;
  }
}

abstract class _LinkedLibraryMixin implements idl.LinkedLibrary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (dependencies.isNotEmpty)
      _result["dependencies"] =
          dependencies.map((_value) => _value.toJson()).toList();
    if (exportDependencies.isNotEmpty)
      _result["exportDependencies"] = exportDependencies;
    if (exportNames.isNotEmpty)
      _result["exportNames"] =
          exportNames.map((_value) => _value.toJson()).toList();
    if (importDependencies.isNotEmpty)
      _result["importDependencies"] = importDependencies;
    if (numPrelinkedDependencies != 0)
      _result["numPrelinkedDependencies"] = numPrelinkedDependencies;
    if (units.isNotEmpty)
      _result["units"] = units.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "dependencies": dependencies,
        "exportDependencies": exportDependencies,
        "exportNames": exportNames,
        "importDependencies": importDependencies,
        "numPrelinkedDependencies": numPrelinkedDependencies,
        "units": units,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeBuilder extends Object
    with _LinkedNodeMixin
    implements idl.LinkedNode {
  LinkedNodeTypeBuilder _variantField_24;
  List<LinkedNodeBuilder> _variantField_2;
  LinkedNodeBuilder _variantField_11;
  List<LinkedNodeBuilder> _variantField_4;
  LinkedNodeBuilder _variantField_6;
  int _variantField_15;
  LinkedNodeBuilder _variantField_7;
  int _variantField_17;
  LinkedNodeTypeBuilder _variantField_23;
  LinkedNodeBuilder _variantField_8;
  int _variantField_16;
  int _variantField_18;
  int _variantField_19;
  bool _variantField_27;
  LinkedNodeBuilder _variantField_9;
  LinkedNodeBuilder _variantField_12;
  List<LinkedNodeBuilder> _variantField_5;
  LinkedNodeBuilder _variantField_13;
  int _variantField_34;
  int _variantField_33;
  List<int> _variantField_28;
  idl.LinkedNodeCommentType _variantField_29;
  List<LinkedNodeBuilder> _variantField_3;
  LinkedNodeBuilder _variantField_10;
  idl.LinkedNodeFormalParameterKind _variantField_26;
  double _variantField_21;
  LinkedNodeTypeBuilder _variantField_25;
  String _variantField_30;
  LinkedNodeBuilder _variantField_14;
  bool _isSynthetic;
  idl.LinkedNodeKind _kind;
  List<String> _variantField_36;
  String _variantField_20;
  bool _variantField_31;
  TopLevelInferenceErrorBuilder _variantField_35;
  String _variantField_22;
  LinkedNodeVariablesDeclarationBuilder _variantField_32;

  @override
  LinkedNodeTypeBuilder get actualReturnType {
    assert(kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionExpression ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericFunctionType ||
        kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_24;
  }

  @override
  LinkedNodeTypeBuilder get actualType {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_24;
  }

  @override
  LinkedNodeTypeBuilder get binaryExpression_invokeType {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_24;
  }

  @override
  LinkedNodeTypeBuilder get invocationExpression_invokeType {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_24;
  }

  /// The explicit or inferred return type of a function typed node.
  set actualReturnType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionExpression ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericFunctionType ||
        kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_24 = value;
  }

  set actualType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_24 = value;
  }

  set binaryExpression_invokeType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_24 = value;
  }

  set invocationExpression_invokeType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_24 = value;
  }

  @override
  List<LinkedNodeBuilder> get adjacentStrings_strings {
    assert(kind == idl.LinkedNodeKind.adjacentStrings);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get argumentList_arguments {
    assert(kind == idl.LinkedNodeKind.argumentList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get block_statements {
    assert(kind == idl.LinkedNodeKind.block);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get cascadeExpression_sections {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get comment_references {
    assert(kind == idl.LinkedNodeKind.comment);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get compilationUnit_declarations {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get constructorDeclaration_initializers {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get dottedName_components {
    assert(kind == idl.LinkedNodeKind.dottedName);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get enumDeclaration_constants {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get formalParameterList_parameters {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get hideCombinator_hiddenNames {
    assert(kind == idl.LinkedNodeKind.hideCombinator);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get implementsClause_interfaces {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get labeledStatement_labels {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get libraryIdentifier_components {
    assert(kind == idl.LinkedNodeKind.libraryIdentifier);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get listLiteral_elements {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get namespaceDirective_combinators {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get onClause_superclassConstraints {
    assert(kind == idl.LinkedNodeKind.onClause);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get setOrMapLiteral_elements {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get showCombinator_shownNames {
    assert(kind == idl.LinkedNodeKind.showCombinator);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get stringInterpolation_elements {
    assert(kind == idl.LinkedNodeKind.stringInterpolation);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get switchStatement_members {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get tryStatement_catchClauses {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get typeArgumentList_arguments {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get typeParameterList_typeParameters {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get variableDeclarationList_variables {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get withClause_mixinTypes {
    assert(kind == idl.LinkedNodeKind.withClause);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  set adjacentStrings_strings(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.adjacentStrings);
    _variantField_2 = value;
  }

  set argumentList_arguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.argumentList);
    _variantField_2 = value;
  }

  set block_statements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.block);
    _variantField_2 = value;
  }

  set cascadeExpression_sections(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    _variantField_2 = value;
  }

  set comment_references(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_2 = value;
  }

  set compilationUnit_declarations(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_2 = value;
  }

  set constructorDeclaration_initializers(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_2 = value;
  }

  set dottedName_components(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.dottedName);
    _variantField_2 = value;
  }

  set enumDeclaration_constants(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_2 = value;
  }

  set formalParameterList_parameters(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_2 = value;
  }

  set hideCombinator_hiddenNames(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.hideCombinator);
    _variantField_2 = value;
  }

  set implementsClause_interfaces(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    _variantField_2 = value;
  }

  set labeledStatement_labels(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    _variantField_2 = value;
  }

  set libraryIdentifier_components(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.libraryIdentifier);
    _variantField_2 = value;
  }

  set listLiteral_elements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_2 = value;
  }

  set namespaceDirective_combinators(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_2 = value;
  }

  set onClause_superclassConstraints(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.onClause);
    _variantField_2 = value;
  }

  set setOrMapLiteral_elements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_2 = value;
  }

  set showCombinator_shownNames(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.showCombinator);
    _variantField_2 = value;
  }

  set stringInterpolation_elements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.stringInterpolation);
    _variantField_2 = value;
  }

  set switchStatement_members(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_2 = value;
  }

  set tryStatement_catchClauses(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_2 = value;
  }

  set typeArgumentList_arguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    _variantField_2 = value;
  }

  set typeParameterList_typeParameters(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    _variantField_2 = value;
  }

  set variableDeclarationList_variables(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_2 = value;
  }

  set withClause_mixinTypes(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.withClause);
    _variantField_2 = value;
  }

  @override
  LinkedNodeBuilder get annotatedNode_comment {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_11;
  }

  set annotatedNode_comment(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_11 = value;
  }

  @override
  List<LinkedNodeBuilder> get annotatedNode_metadata {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_4 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get normalFormalParameter_metadata {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_4 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get switchMember_statements {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    return _variantField_4 ??= <LinkedNodeBuilder>[];
  }

  set annotatedNode_metadata(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_4 = value;
  }

  set normalFormalParameter_metadata(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_4 = value;
  }

  set switchMember_statements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_4 = value;
  }

  @override
  LinkedNodeBuilder get annotation_arguments {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get asExpression_expression {
    assert(kind == idl.LinkedNodeKind.asExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get assertInitializer_condition {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get assertStatement_condition {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get assignmentExpression_leftHandSide {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get awaitExpression_expression {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get binaryExpression_leftOperand {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get blockFunctionBody_block {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get breakStatement_label {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get cascadeExpression_target {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get catchClause_body {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get classDeclaration_extendsClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get classTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get commentReference_identifier {
    assert(kind == idl.LinkedNodeKind.commentReference);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get compilationUnit_scriptTag {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get conditionalExpression_condition {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get configuration_name {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_body {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get constructorFieldInitializer_expression {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get constructorName_name {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get continueStatement_label {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get declaredIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get defaultFormalParameter_defaultValue {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get doStatement_body {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get enumConstantDeclaration_name {
    assert(kind == idl.LinkedNodeKind.enumConstantDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get expressionFunctionBody_expression {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get expressionStatement_expression {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get extendsClause_superclass {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get fieldDeclaration_fields {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get fieldFormalParameter_type {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get forEachParts_iterable {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get forMixin_forLoopParts {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get forParts_condition {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionDeclaration_functionExpression {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionDeclarationStatement_functionDeclaration {
    assert(kind == idl.LinkedNodeKind.functionDeclarationStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionExpression_body {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionExpressionInvocation_function {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionTypeAlias_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get functionTypedFormalParameter_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get genericFunctionType_typeParameters {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get genericTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get ifMixin_condition {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get importDirective_prefix {
    assert(kind == idl.LinkedNodeKind.importDirective);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get indexExpression_index {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get instanceCreationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get interpolationExpression_expression {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get isExpression_expression {
    assert(kind == idl.LinkedNodeKind.isExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get label_label {
    assert(kind == idl.LinkedNodeKind.label);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get labeledStatement_statement {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get libraryDirective_name {
    assert(kind == idl.LinkedNodeKind.libraryDirective);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get mapLiteralEntry_key {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get methodDeclaration_body {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get methodInvocation_methodName {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get mixinDeclaration_onClause {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get namedExpression_expression {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get nativeClause_name {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get nativeFunctionBody_stringLiteral {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get parenthesizedExpression_expression {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get partOfDirective_libraryName {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get postfixExpression_operand {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get prefixedIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get prefixExpression_operand {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get propertyAccess_propertyName {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get redirectingConstructorInvocation_arguments {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get returnStatement_expression {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get simpleFormalParameter_type {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get spreadElement_expression {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get superConstructorInvocation_arguments {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get switchCase_expression {
    assert(kind == idl.LinkedNodeKind.switchCase);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get throwExpression_expression {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get topLevelVariableDeclaration_variableList {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get tryStatement_body {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get typeName_name {
    assert(kind == idl.LinkedNodeKind.typeName);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get typeParameter_bound {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get variableDeclaration_initializer {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get variableDeclarationList_type {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get variableDeclarationStatement_variables {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get whileStatement_body {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    return _variantField_6;
  }

  @override
  LinkedNodeBuilder get yieldStatement_expression {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    return _variantField_6;
  }

  set annotation_arguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_6 = value;
  }

  set asExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.asExpression);
    _variantField_6 = value;
  }

  set assertInitializer_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_6 = value;
  }

  set assertStatement_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_6 = value;
  }

  set assignmentExpression_leftHandSide(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_6 = value;
  }

  set awaitExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    _variantField_6 = value;
  }

  set binaryExpression_leftOperand(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_6 = value;
  }

  set blockFunctionBody_block(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    _variantField_6 = value;
  }

  set breakStatement_label(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    _variantField_6 = value;
  }

  set cascadeExpression_target(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    _variantField_6 = value;
  }

  set catchClause_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_6 = value;
  }

  set classDeclaration_extendsClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_6 = value;
  }

  set classTypeAlias_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_6 = value;
  }

  set commentReference_identifier(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.commentReference);
    _variantField_6 = value;
  }

  set compilationUnit_scriptTag(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_6 = value;
  }

  set conditionalExpression_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_6 = value;
  }

  set configuration_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_6 = value;
  }

  set constructorDeclaration_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_6 = value;
  }

  set constructorFieldInitializer_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_6 = value;
  }

  set constructorName_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_6 = value;
  }

  set continueStatement_label(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    _variantField_6 = value;
  }

  set declaredIdentifier_identifier(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    _variantField_6 = value;
  }

  set defaultFormalParameter_defaultValue(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_6 = value;
  }

  set doStatement_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_6 = value;
  }

  set enumConstantDeclaration_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.enumConstantDeclaration);
    _variantField_6 = value;
  }

  set expressionFunctionBody_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    _variantField_6 = value;
  }

  set expressionStatement_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    _variantField_6 = value;
  }

  set extendsClause_superclass(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    _variantField_6 = value;
  }

  set fieldDeclaration_fields(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    _variantField_6 = value;
  }

  set fieldFormalParameter_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_6 = value;
  }

  set forEachParts_iterable(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    _variantField_6 = value;
  }

  set forMixin_forLoopParts(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_6 = value;
  }

  set forParts_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_6 = value;
  }

  set functionDeclaration_functionExpression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_6 = value;
  }

  set functionDeclarationStatement_functionDeclaration(
      LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionDeclarationStatement);
    _variantField_6 = value;
  }

  set functionExpression_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_6 = value;
  }

  set functionExpressionInvocation_function(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation);
    _variantField_6 = value;
  }

  set functionTypeAlias_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_6 = value;
  }

  set functionTypedFormalParameter_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_6 = value;
  }

  set genericFunctionType_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_6 = value;
  }

  set genericTypeAlias_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_6 = value;
  }

  set ifMixin_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_6 = value;
  }

  set importDirective_prefix(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_6 = value;
  }

  set indexExpression_index(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_6 = value;
  }

  set instanceCreationExpression_arguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_6 = value;
  }

  set interpolationExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    _variantField_6 = value;
  }

  set isExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_6 = value;
  }

  set label_label(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.label);
    _variantField_6 = value;
  }

  set labeledStatement_statement(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    _variantField_6 = value;
  }

  set libraryDirective_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.libraryDirective);
    _variantField_6 = value;
  }

  set mapLiteralEntry_key(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    _variantField_6 = value;
  }

  set methodDeclaration_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_6 = value;
  }

  set methodInvocation_methodName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_6 = value;
  }

  set mixinDeclaration_onClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_6 = value;
  }

  set namedExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    _variantField_6 = value;
  }

  set nativeClause_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    _variantField_6 = value;
  }

  set nativeFunctionBody_stringLiteral(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    _variantField_6 = value;
  }

  set parenthesizedExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    _variantField_6 = value;
  }

  set partOfDirective_libraryName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_6 = value;
  }

  set postfixExpression_operand(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_6 = value;
  }

  set prefixedIdentifier_identifier(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    _variantField_6 = value;
  }

  set prefixExpression_operand(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_6 = value;
  }

  set propertyAccess_propertyName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_6 = value;
  }

  set redirectingConstructorInvocation_arguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_6 = value;
  }

  set returnStatement_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    _variantField_6 = value;
  }

  set simpleFormalParameter_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_6 = value;
  }

  set spreadElement_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    _variantField_6 = value;
  }

  set superConstructorInvocation_arguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_6 = value;
  }

  set switchCase_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.switchCase);
    _variantField_6 = value;
  }

  set throwExpression_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    _variantField_6 = value;
  }

  set topLevelVariableDeclaration_variableList(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    _variantField_6 = value;
  }

  set tryStatement_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_6 = value;
  }

  set typeName_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_6 = value;
  }

  set typeParameter_bound(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_6 = value;
  }

  set variableDeclaration_initializer(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_6 = value;
  }

  set variableDeclarationList_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_6 = value;
  }

  set variableDeclarationStatement_variables(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    _variantField_6 = value;
  }

  set whileStatement_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_6 = value;
  }

  set yieldStatement_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    _variantField_6 = value;
  }

  @override
  int get annotation_atSign {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_15 ??= 0;
  }

  @override
  int get argumentList_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.argumentList);
    return _variantField_15 ??= 0;
  }

  @override
  int get asExpression_asOperator {
    assert(kind == idl.LinkedNodeKind.asExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get assertInitializer_assertKeyword {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_15 ??= 0;
  }

  @override
  int get assertStatement_assertKeyword {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get assignmentExpression_element {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get awaitExpression_awaitKeyword {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get binaryExpression_element {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get block_leftBracket {
    assert(kind == idl.LinkedNodeKind.block);
    return _variantField_15 ??= 0;
  }

  @override
  int get blockFunctionBody_keyword {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    return _variantField_15 ??= 0;
  }

  @override
  int get booleanLiteral_literal {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get breakStatement_breakKeyword {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get catchClause_catchKeyword {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get classDeclaration_abstractKeyword {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get classTypeAlias_abstractKeyword {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_15 ??= 0;
  }

  @override
  int get commentReference_newKeyword {
    assert(kind == idl.LinkedNodeKind.commentReference);
    return _variantField_15 ??= 0;
  }

  @override
  int get compilationUnit_beginToken {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_15 ??= 0;
  }

  @override
  int get conditionalExpression_colon {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get configuration_ifKeyword {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_15 ??= 0;
  }

  @override
  int get constructorDeclaration_constKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get constructorFieldInitializer_equals {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    return _variantField_15 ??= 0;
  }

  @override
  int get constructorName_element {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_15 ??= 0;
  }

  @override
  int get continueStatement_continueKeyword {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get declaredIdentifier_keyword {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    return _variantField_15 ??= 0;
  }

  @override
  int get defaultFormalParameter_separator {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    return _variantField_15 ??= 0;
  }

  @override
  int get doStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get doubleLiteral_literal {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get emptyFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    return _variantField_15 ??= 0;
  }

  @override
  int get emptyStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get enumDeclaration_enumKeyword {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get expressionFunctionBody_arrow {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    return _variantField_15 ??= 0;
  }

  @override
  int get expressionStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get extendsClause_extendsKeyword {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get fieldDeclaration_covariantKeyword {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get fieldFormalParameter_keyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_15 ??= 0;
  }

  @override
  int get forEachParts_inKeyword {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    return _variantField_15 ??= 0;
  }

  @override
  int get formalParameterList_leftDelimiter {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_15 ??= 0;
  }

  @override
  int get forMixin_awaitKeyword {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get forParts_leftSeparator {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get functionDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get genericFunctionType_functionKeyword {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_15 ??= 0;
  }

  @override
  int get ifMixin_elseKeyword {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get implementsClause_implementsKeyword {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get importDirective_asKeyword {
    assert(kind == idl.LinkedNodeKind.importDirective);
    return _variantField_15 ??= 0;
  }

  @override
  int get indexExpression_element {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get instanceCreationExpression_keyword {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get integerLiteral_literal {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get interpolationExpression_leftBracket {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get interpolationString_token {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    return _variantField_15 ??= 0;
  }

  @override
  int get isExpression_isOperator {
    assert(kind == idl.LinkedNodeKind.isExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get label_colon {
    assert(kind == idl.LinkedNodeKind.label);
    return _variantField_15 ??= 0;
  }

  @override
  int get listLiteral_leftBracket {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get mapLiteralEntry_separator {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    return _variantField_15 ??= 0;
  }

  @override
  int get methodDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get methodInvocation_operator {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_15 ??= 0;
  }

  @override
  int get mixinDeclaration_mixinKeyword {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get nativeClause_nativeKeyword {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get nativeFunctionBody_nativeKeyword {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    return _variantField_15 ??= 0;
  }

  @override
  int get nullLiteral_literal {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get onClause_onKeyword {
    assert(kind == idl.LinkedNodeKind.onClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get parenthesizedExpression_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get postfixExpression_element {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get prefixedIdentifier_period {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    return _variantField_15 ??= 0;
  }

  @override
  int get prefixExpression_element {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get propertyAccess_operator {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    return _variantField_15 ??= 0;
  }

  @override
  int get redirectingConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_15 ??= 0;
  }

  @override
  int get rethrowExpression_rethrowKeyword {
    assert(kind == idl.LinkedNodeKind.rethrowExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get returnStatement_returnKeyword {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get scriptTag_scriptTag {
    assert(kind == idl.LinkedNodeKind.scriptTag);
    return _variantField_15 ??= 0;
  }

  @override
  int get setOrMapLiteral_leftBracket {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get simpleFormalParameter_keyword {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_15 ??= 0;
  }

  @override
  int get simpleIdentifier_element {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_15 ??= 0;
  }

  @override
  int get simpleStringLiteral_token {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get spreadElement_spreadOperator {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    return _variantField_15 ??= 0;
  }

  @override
  int get superConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_15 ??= 0;
  }

  @override
  int get superExpression_superKeyword {
    assert(kind == idl.LinkedNodeKind.superExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get switchMember_keyword {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    return _variantField_15 ??= 0;
  }

  @override
  int get switchStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get symbolLiteral_poundSign {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get thisExpression_thisKeyword {
    assert(kind == idl.LinkedNodeKind.thisExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get throwExpression_throwKeyword {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get topLevelVariableDeclaration_semicolon {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get tryStatement_finallyKeyword {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get typeArgumentList_leftBracket {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    return _variantField_15 ??= 0;
  }

  @override
  int get typeName_question {
    assert(kind == idl.LinkedNodeKind.typeName);
    return _variantField_15 ??= 0;
  }

  @override
  int get typeParameter_extendsKeyword {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    return _variantField_15 ??= 0;
  }

  @override
  int get typeParameterList_leftBracket {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    return _variantField_15 ??= 0;
  }

  @override
  int get variableDeclaration_equals {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_15 ??= 0;
  }

  @override
  int get variableDeclarationList_keyword {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_15 ??= 0;
  }

  @override
  int get variableDeclarationStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get whileStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get withClause_withKeyword {
    assert(kind == idl.LinkedNodeKind.withClause);
    return _variantField_15 ??= 0;
  }

  @override
  int get yieldStatement_yieldKeyword {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    return _variantField_15 ??= 0;
  }

  set annotation_atSign(int value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set argumentList_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.argumentList);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set asExpression_asOperator(int value) {
    assert(kind == idl.LinkedNodeKind.asExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set assertInitializer_assertKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set assertStatement_assertKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set assignmentExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set awaitExpression_awaitKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set binaryExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set block_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.block);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set blockFunctionBody_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set booleanLiteral_literal(int value) {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set breakStatement_breakKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set catchClause_catchKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set classDeclaration_abstractKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set classTypeAlias_abstractKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set commentReference_newKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.commentReference);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set compilationUnit_beginToken(int value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set conditionalExpression_colon(int value) {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set configuration_ifKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set constructorDeclaration_constKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set constructorFieldInitializer_equals(int value) {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set constructorName_element(int value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set continueStatement_continueKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set declaredIdentifier_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set defaultFormalParameter_separator(int value) {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set doStatement_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set doubleLiteral_literal(int value) {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set emptyFunctionBody_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set emptyStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set enumDeclaration_enumKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set expressionFunctionBody_arrow(int value) {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set expressionStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set extendsClause_extendsKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set fieldDeclaration_covariantKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set fieldFormalParameter_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set forEachParts_inKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set formalParameterList_leftDelimiter(int value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set forMixin_awaitKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set forParts_leftSeparator(int value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set functionDeclaration_externalKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set genericFunctionType_functionKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set ifMixin_elseKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set implementsClause_implementsKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set importDirective_asKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.importDirective);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set indexExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set instanceCreationExpression_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set integerLiteral_literal(int value) {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set interpolationExpression_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set interpolationString_token(int value) {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set isExpression_isOperator(int value) {
    assert(kind == idl.LinkedNodeKind.isExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set label_colon(int value) {
    assert(kind == idl.LinkedNodeKind.label);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set listLiteral_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set mapLiteralEntry_separator(int value) {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set methodDeclaration_externalKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set methodInvocation_operator(int value) {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set mixinDeclaration_mixinKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set nativeClause_nativeKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set nativeFunctionBody_nativeKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set nullLiteral_literal(int value) {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set onClause_onKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.onClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set parenthesizedExpression_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set postfixExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set prefixedIdentifier_period(int value) {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set prefixExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set propertyAccess_operator(int value) {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set redirectingConstructorInvocation_element(int value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set rethrowExpression_rethrowKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.rethrowExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set returnStatement_returnKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set scriptTag_scriptTag(int value) {
    assert(kind == idl.LinkedNodeKind.scriptTag);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set setOrMapLiteral_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set simpleFormalParameter_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set simpleIdentifier_element(int value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set simpleStringLiteral_token(int value) {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set spreadElement_spreadOperator(int value) {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set superConstructorInvocation_element(int value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set superExpression_superKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.superExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set switchMember_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set switchStatement_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set symbolLiteral_poundSign(int value) {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set thisExpression_thisKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.thisExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set throwExpression_throwKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set topLevelVariableDeclaration_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set tryStatement_finallyKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set typeArgumentList_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set typeName_question(int value) {
    assert(kind == idl.LinkedNodeKind.typeName);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set typeParameter_extendsKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set typeParameterList_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set variableDeclaration_equals(int value) {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set variableDeclarationList_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set variableDeclarationStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set whileStatement_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set withClause_withKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.withClause);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set yieldStatement_yieldKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  @override
  LinkedNodeBuilder get annotation_constructorName {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get asExpression_type {
    assert(kind == idl.LinkedNodeKind.asExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get assertInitializer_message {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get assertStatement_message {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get assignmentExpression_rightHandSide {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get binaryExpression_rightOperand {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get catchClause_exceptionParameter {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get classDeclaration_withClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get classTypeAlias_superclass {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get conditionalExpression_elseExpression {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get configuration_value {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_name {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get constructorFieldInitializer_fieldName {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get constructorName_type {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get declaredIdentifier_type {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get defaultFormalParameter_parameter {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get doStatement_condition {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get fieldFormalParameter_typeParameters {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forEachPartsWithDeclaration_loopVariable {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forEachPartsWithIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forElement_body {
    assert(kind == idl.LinkedNodeKind.forElement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forPartsWithDeclarations_variables {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forPartsWithExpression_initialization {
    assert(kind == idl.LinkedNodeKind.forPartsWithExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get forStatement_body {
    assert(kind == idl.LinkedNodeKind.forStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get functionDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get functionExpression_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get functionTypeAlias_returnType {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get functionTypedFormalParameter_returnType {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get genericFunctionType_returnType {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get genericTypeAlias_functionType {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get ifStatement_elseStatement {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get indexExpression_target {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get instanceCreationExpression_constructorName {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get isExpression_type {
    assert(kind == idl.LinkedNodeKind.isExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get mapLiteralEntry_value {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get methodDeclaration_formalParameters {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get methodInvocation_target {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get namedExpression_name {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get partOfDirective_uri {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get prefixedIdentifier_prefix {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get propertyAccess_target {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get redirectingConstructorInvocation_constructorName {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get superConstructorInvocation_constructorName {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get switchStatement_expression {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get tryStatement_finallyBlock {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get typeName_typeArguments {
    assert(kind == idl.LinkedNodeKind.typeName);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get typeParameter_name {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get variableDeclaration_name {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get whileStatement_condition {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    return _variantField_7;
  }

  set annotation_constructorName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_7 = value;
  }

  set asExpression_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.asExpression);
    _variantField_7 = value;
  }

  set assertInitializer_message(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_7 = value;
  }

  set assertStatement_message(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_7 = value;
  }

  set assignmentExpression_rightHandSide(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_7 = value;
  }

  set binaryExpression_rightOperand(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_7 = value;
  }

  set catchClause_exceptionParameter(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_7 = value;
  }

  set classDeclaration_withClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_7 = value;
  }

  set classTypeAlias_superclass(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_7 = value;
  }

  set conditionalExpression_elseExpression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_7 = value;
  }

  set configuration_value(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_7 = value;
  }

  set constructorDeclaration_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_7 = value;
  }

  set constructorFieldInitializer_fieldName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_7 = value;
  }

  set constructorName_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_7 = value;
  }

  set declaredIdentifier_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    _variantField_7 = value;
  }

  set defaultFormalParameter_parameter(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_7 = value;
  }

  set doStatement_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_7 = value;
  }

  set fieldFormalParameter_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_7 = value;
  }

  set forEachPartsWithDeclaration_loopVariable(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration);
    _variantField_7 = value;
  }

  set forEachPartsWithIdentifier_identifier(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    _variantField_7 = value;
  }

  set forElement_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forElement);
    _variantField_7 = value;
  }

  set forPartsWithDeclarations_variables(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations);
    _variantField_7 = value;
  }

  set forPartsWithExpression_initialization(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_7 = value;
  }

  set forStatement_body(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.forStatement);
    _variantField_7 = value;
  }

  set functionDeclaration_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_7 = value;
  }

  set functionExpression_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_7 = value;
  }

  set functionTypeAlias_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_7 = value;
  }

  set functionTypedFormalParameter_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_7 = value;
  }

  set genericFunctionType_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_7 = value;
  }

  set genericTypeAlias_functionType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_7 = value;
  }

  set ifStatement_elseStatement(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    _variantField_7 = value;
  }

  set indexExpression_target(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_7 = value;
  }

  set instanceCreationExpression_constructorName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_7 = value;
  }

  set isExpression_type(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_7 = value;
  }

  set mapLiteralEntry_value(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    _variantField_7 = value;
  }

  set methodDeclaration_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_7 = value;
  }

  set methodInvocation_target(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_7 = value;
  }

  set namedExpression_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    _variantField_7 = value;
  }

  set partOfDirective_uri(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_7 = value;
  }

  set prefixedIdentifier_prefix(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    _variantField_7 = value;
  }

  set propertyAccess_target(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_7 = value;
  }

  set redirectingConstructorInvocation_constructorName(
      LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_7 = value;
  }

  set superConstructorInvocation_constructorName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_7 = value;
  }

  set switchStatement_expression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_7 = value;
  }

  set tryStatement_finallyBlock(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_7 = value;
  }

  set typeName_typeArguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_7 = value;
  }

  set typeParameter_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_7 = value;
  }

  set variableDeclaration_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_7 = value;
  }

  set whileStatement_condition(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_7 = value;
  }

  @override
  int get annotation_element {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_17 ??= 0;
  }

  @override
  int get assertInitializer_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_17 ??= 0;
  }

  @override
  int get assertStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get catchClause_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_17 ??= 0;
  }

  @override
  int get configuration_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_17 ??= 0;
  }

  @override
  int get constructorDeclaration_factoryKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_17 ??= 0;
  }

  @override
  int get constructorFieldInitializer_thisKeyword {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    return _variantField_17 ??= 0;
  }

  @override
  int get doStatement_doKeyword {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get enumDeclaration_rightBracket {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    return _variantField_17 ??= 0;
  }

  @override
  int get expressionFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    return _variantField_17 ??= 0;
  }

  @override
  int get fieldDeclaration_staticKeyword {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    return _variantField_17 ??= 0;
  }

  @override
  int get fieldFormalParameter_thisKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_17 ??= 0;
  }

  @override
  int get formalParameterList_rightDelimiter {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_17 ??= 0;
  }

  @override
  int get forMixin_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get genericFunctionType_id {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_17 ??= 0;
  }

  @override
  int get ifMixin_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get indexExpression_leftBracket {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_17 ??= 0;
  }

  @override
  int get methodDeclaration_operatorKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_17 ??= 0;
  }

  @override
  int get redirectingConstructorInvocation_thisKeyword {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_17 ??= 0;
  }

  @override
  int get superConstructorInvocation_superKeyword {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_17 ??= 0;
  }

  @override
  int get switchStatement_switchKeyword {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get whileStatement_whileKeyword {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    return _variantField_17 ??= 0;
  }

  @override
  int get yieldStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    return _variantField_17 ??= 0;
  }

  set annotation_element(int value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set assertInitializer_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set assertStatement_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set catchClause_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set configuration_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set constructorDeclaration_factoryKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set constructorFieldInitializer_thisKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set doStatement_doKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set enumDeclaration_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set expressionFunctionBody_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set fieldDeclaration_staticKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set fieldFormalParameter_thisKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set formalParameterList_rightDelimiter(int value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set forMixin_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set genericFunctionType_id(int value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set ifMixin_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set indexExpression_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set methodDeclaration_operatorKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set redirectingConstructorInvocation_thisKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set superConstructorInvocation_superKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set switchStatement_switchKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set whileStatement_whileKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set yieldStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  @override
  LinkedNodeTypeBuilder get annotation_elementType {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get assignmentExpression_elementType {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get binaryExpression_elementType {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get constructorName_elementType {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get indexExpression_elementType {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get postfixExpression_elementType {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get prefixExpression_elementType {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get redirectingConstructorInvocation_elementType {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get simpleIdentifier_elementType {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get superConstructorInvocation_elementType {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get typeName_type {
    assert(kind == idl.LinkedNodeKind.typeName);
    return _variantField_23;
  }

  @override
  LinkedNodeTypeBuilder get typeParameter_defaultType {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    return _variantField_23;
  }

  set annotation_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_23 = value;
  }

  set assignmentExpression_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_23 = value;
  }

  set binaryExpression_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_23 = value;
  }

  set constructorName_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_23 = value;
  }

  set indexExpression_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_23 = value;
  }

  set postfixExpression_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_23 = value;
  }

  set prefixExpression_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_23 = value;
  }

  set redirectingConstructorInvocation_elementType(
      LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_23 = value;
  }

  set simpleIdentifier_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_23 = value;
  }

  set superConstructorInvocation_elementType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_23 = value;
  }

  set typeName_type(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_23 = value;
  }

  set typeParameter_defaultType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_23 = value;
  }

  @override
  LinkedNodeBuilder get annotation_name {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get catchClause_exceptionType {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get classDeclaration_nativeClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get classTypeAlias_withClause {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get conditionalExpression_thenExpression {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get configuration_uri {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_parameters {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get fieldFormalParameter_formalParameters {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get functionExpression_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get functionTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get functionTypedFormalParameter_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get genericFunctionType_formalParameters {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get ifElement_thenElement {
    assert(kind == idl.LinkedNodeKind.ifElement);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get ifStatement_thenStatement {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get instanceCreationExpression_typeArguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    return _variantField_8;
  }

  @override
  LinkedNodeBuilder get methodDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_8;
  }

  set annotation_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_8 = value;
  }

  set catchClause_exceptionType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_8 = value;
  }

  set classDeclaration_nativeClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_8 = value;
  }

  set classTypeAlias_withClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_8 = value;
  }

  set conditionalExpression_thenExpression(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_8 = value;
  }

  set configuration_uri(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_8 = value;
  }

  set constructorDeclaration_parameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_8 = value;
  }

  set fieldFormalParameter_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_8 = value;
  }

  set functionExpression_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_8 = value;
  }

  set functionTypeAlias_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_8 = value;
  }

  set functionTypedFormalParameter_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_8 = value;
  }

  set genericFunctionType_formalParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_8 = value;
  }

  set ifElement_thenElement(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.ifElement);
    _variantField_8 = value;
  }

  set ifStatement_thenStatement(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    _variantField_8 = value;
  }

  set instanceCreationExpression_typeArguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_8 = value;
  }

  set methodDeclaration_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_8 = value;
  }

  @override
  int get annotation_period {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_16 ??= 0;
  }

  @override
  int get argumentList_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.argumentList);
    return _variantField_16 ??= 0;
  }

  @override
  int get assertInitializer_comma {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_16 ??= 0;
  }

  @override
  int get assertStatement_comma {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get assignmentExpression_operator {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get binaryExpression_operator {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get block_rightBracket {
    assert(kind == idl.LinkedNodeKind.block);
    return _variantField_16 ??= 0;
  }

  @override
  int get blockFunctionBody_star {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    return _variantField_16 ??= 0;
  }

  @override
  int get breakStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get catchClause_comma {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_16 ??= 0;
  }

  @override
  int get classDeclaration_classKeyword {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get classTypeAlias_equals {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_16 ??= 0;
  }

  @override
  int get compilationUnit_endToken {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_16 ??= 0;
  }

  @override
  int get conditionalExpression_question {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get configuration_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_16 ??= 0;
  }

  @override
  int get constructorDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get constructorFieldInitializer_period {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    return _variantField_16 ??= 0;
  }

  @override
  int get constructorName_period {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_16 ??= 0;
  }

  @override
  int get continueStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get doStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get enumDeclaration_leftBracket {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get expressionFunctionBody_keyword {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    return _variantField_16 ??= 0;
  }

  @override
  int get fieldDeclaration_semicolon {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get fieldFormalParameter_period {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    return _variantField_16 ??= 0;
  }

  @override
  int get formalParameterList_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_16 ??= 0;
  }

  @override
  int get forMixin_forKeyword {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get forParts_rightSeparator {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get functionDeclaration_propertyKeyword {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get genericFunctionType_question {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_16 ??= 0;
  }

  @override
  int get genericTypeAlias_equals {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_16 ??= 0;
  }

  @override
  int get ifMixin_ifKeyword {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get importDirective_deferredKeyword {
    assert(kind == idl.LinkedNodeKind.importDirective);
    return _variantField_16 ??= 0;
  }

  @override
  int get indexExpression_period {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get integerLiteral_value {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    return _variantField_16 ??= 0;
  }

  @override
  int get interpolationExpression_rightBracket {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get isExpression_notOperator {
    assert(kind == idl.LinkedNodeKind.isExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get listLiteral_rightBracket {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    return _variantField_16 ??= 0;
  }

  @override
  int get methodDeclaration_modifierKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_16 ??= 0;
  }

  @override
  int get nativeFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    return _variantField_16 ??= 0;
  }

  @override
  int get parenthesizedExpression_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get partOfDirective_ofKeyword {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_16 ??= 0;
  }

  @override
  int get postfixExpression_operator {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get prefixExpression_operator {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_16 ??= 0;
  }

  @override
  int get redirectingConstructorInvocation_period {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_16 ??= 0;
  }

  @override
  int get returnStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get setOrMapLiteral_rightBracket {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_16 ??= 0;
  }

  @override
  int get simpleIdentifier_token {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_16 ??= 0;
  }

  @override
  int get superConstructorInvocation_period {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_16 ??= 0;
  }

  @override
  int get switchMember_colon {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    return _variantField_16 ??= 0;
  }

  @override
  int get switchStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get tryStatement_tryKeyword {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get typeArgumentList_rightBracket {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    return _variantField_16 ??= 0;
  }

  @override
  int get typeParameterList_rightBracket {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    return _variantField_16 ??= 0;
  }

  @override
  int get variableDeclarationList_lateKeyword {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_16 ??= 0;
  }

  @override
  int get whileStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    return _variantField_16 ??= 0;
  }

  @override
  int get yieldStatement_star {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    return _variantField_16 ??= 0;
  }

  set annotation_period(int value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set argumentList_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.argumentList);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set assertInitializer_comma(int value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set assertStatement_comma(int value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set assignmentExpression_operator(int value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set binaryExpression_operator(int value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set block_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.block);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set blockFunctionBody_star(int value) {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set breakStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set catchClause_comma(int value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set classDeclaration_classKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set classTypeAlias_equals(int value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set compilationUnit_endToken(int value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set conditionalExpression_question(int value) {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set configuration_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set constructorDeclaration_externalKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set constructorFieldInitializer_period(int value) {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set constructorName_period(int value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set continueStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set doStatement_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set enumDeclaration_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set expressionFunctionBody_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set fieldDeclaration_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set fieldFormalParameter_period(int value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set formalParameterList_leftParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set forMixin_forKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set forParts_rightSeparator(int value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set functionDeclaration_propertyKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set genericFunctionType_question(int value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set genericTypeAlias_equals(int value) {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set ifMixin_ifKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set importDirective_deferredKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.importDirective);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set indexExpression_period(int value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set integerLiteral_value(int value) {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set interpolationExpression_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set isExpression_notOperator(int value) {
    assert(kind == idl.LinkedNodeKind.isExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set listLiteral_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set methodDeclaration_modifierKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set nativeFunctionBody_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set parenthesizedExpression_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set partOfDirective_ofKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set postfixExpression_operator(int value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set prefixExpression_operator(int value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set redirectingConstructorInvocation_period(int value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set returnStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set setOrMapLiteral_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set simpleIdentifier_token(int value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set superConstructorInvocation_period(int value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set switchMember_colon(int value) {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set switchStatement_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set tryStatement_tryKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set typeArgumentList_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set typeParameterList_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set variableDeclarationList_lateKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set whileStatement_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  set yieldStatement_star(int value) {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    assert(value == null || value >= 0);
    _variantField_16 = value;
  }

  @override
  int get assertInitializer_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    return _variantField_18 ??= 0;
  }

  @override
  int get assertStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_18 ??= 0;
  }

  @override
  int get catchClause_onKeyword {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_18 ??= 0;
  }

  @override
  int get classOrMixinDeclaration_rightBracket {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_18 ??= 0;
  }

  @override
  int get configuration_equalToken {
    assert(kind == idl.LinkedNodeKind.configuration);
    return _variantField_18 ??= 0;
  }

  @override
  int get constructorDeclaration_period {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_18 ??= 0;
  }

  @override
  int get directive_keyword {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_18 ??= 0;
  }

  @override
  int get doStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_18 ??= 0;
  }

  @override
  int get formalParameterList_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_18 ??= 0;
  }

  @override
  int get ifMixin_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    return _variantField_18 ??= 0;
  }

  @override
  int get indexExpression_rightBracket {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_18 ??= 0;
  }

  @override
  int get methodDeclaration_propertyKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_18 ??= 0;
  }

  @override
  int get normalFormalParameter_requiredKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_18 ??= 0;
  }

  @override
  int get switchStatement_leftBracket {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_18 ??= 0;
  }

  @override
  int get typeAlias_typedefKeyword {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_18 ??= 0;
  }

  set assertInitializer_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set assertStatement_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set catchClause_onKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set classOrMixinDeclaration_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set configuration_equalToken(int value) {
    assert(kind == idl.LinkedNodeKind.configuration);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set constructorDeclaration_period(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set directive_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set doStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set formalParameterList_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set ifMixin_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set indexExpression_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set methodDeclaration_propertyKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set normalFormalParameter_requiredKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set switchStatement_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  set typeAlias_typedefKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    assert(value == null || value >= 0);
    _variantField_18 = value;
  }

  @override
  int get assertStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    return _variantField_19 ??= 0;
  }

  @override
  int get catchClause_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_19 ??= 0;
  }

  @override
  int get classOrMixinDeclaration_leftBracket {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_19 ??= 0;
  }

  @override
  int get combinator_keyword {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    return _variantField_19 ??= 0;
  }

  @override
  int get constructorDeclaration_separator {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_19 ??= 0;
  }

  @override
  int get doStatement_whileKeyword {
    assert(kind == idl.LinkedNodeKind.doStatement);
    return _variantField_19 ??= 0;
  }

  @override
  int get forMixin_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    return _variantField_19 ??= 0;
  }

  @override
  int get methodDeclaration_actualProperty {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_19 ??= 0;
  }

  @override
  int get normalFormalParameter_covariantKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_19 ??= 0;
  }

  @override
  int get switchStatement_rightBracket {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    return _variantField_19 ??= 0;
  }

  @override
  int get typeAlias_semicolon {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_19 ??= 0;
  }

  @override
  int get typedLiteral_constKeyword {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_19 ??= 0;
  }

  @override
  int get uriBasedDirective_uriElement {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    return _variantField_19 ??= 0;
  }

  set assertStatement_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set catchClause_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set classOrMixinDeclaration_leftBracket(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set combinator_keyword(int value) {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set constructorDeclaration_separator(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set doStatement_whileKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.doStatement);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set forMixin_rightParenthesis(int value) {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set methodDeclaration_actualProperty(int value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set normalFormalParameter_covariantKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set switchStatement_rightBracket(int value) {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set typeAlias_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set typedLiteral_constKeyword(int value) {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  set uriBasedDirective_uriElement(int value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  @override
  bool get booleanLiteral_value {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    return _variantField_27 ??= false;
  }

  @override
  bool get classDeclaration_isDartObject {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_27 ??= false;
  }

  @override
  bool get inheritsCovariant {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_27 ??= false;
  }

  @override
  bool get setOrMapLiteral_isMap {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_27 ??= false;
  }

  @override
  bool get simpleIdentifier_isDeclaration {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_27 ??= false;
  }

  @override
  bool get typeAlias_hasSelfReference {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    return _variantField_27 ??= false;
  }

  set booleanLiteral_value(bool value) {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    _variantField_27 = value;
  }

  set classDeclaration_isDartObject(bool value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_27 = value;
  }

  set inheritsCovariant(bool value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_27 = value;
  }

  set setOrMapLiteral_isMap(bool value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_27 = value;
  }

  set simpleIdentifier_isDeclaration(bool value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_27 = value;
  }

  set typeAlias_hasSelfReference(bool value) {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_27 = value;
  }

  @override
  LinkedNodeBuilder get catchClause_stackTraceParameter {
    assert(kind == idl.LinkedNodeKind.catchClause);
    return _variantField_9;
  }

  @override
  LinkedNodeBuilder get classTypeAlias_implementsClause {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    return _variantField_9;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_redirectedConstructor {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_9;
  }

  @override
  LinkedNodeBuilder get ifElement_elseElement {
    assert(kind == idl.LinkedNodeKind.ifElement);
    return _variantField_9;
  }

  @override
  LinkedNodeBuilder get methodDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_9;
  }

  set catchClause_stackTraceParameter(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_9 = value;
  }

  set classTypeAlias_implementsClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_9 = value;
  }

  set constructorDeclaration_redirectedConstructor(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_9 = value;
  }

  set ifElement_elseElement(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.ifElement);
    _variantField_9 = value;
  }

  set methodDeclaration_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_9 = value;
  }

  @override
  LinkedNodeBuilder get classOrMixinDeclaration_implementsClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_12;
  }

  @override
  LinkedNodeBuilder get invocationExpression_typeArguments {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_12;
  }

  @override
  LinkedNodeBuilder get normalFormalParameter_identifier {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_12;
  }

  set classOrMixinDeclaration_implementsClause(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_12 = value;
  }

  set invocationExpression_typeArguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_12 = value;
  }

  set normalFormalParameter_identifier(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_12 = value;
  }

  @override
  List<LinkedNodeBuilder> get classOrMixinDeclaration_members {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_5 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get forParts_updaters {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    return _variantField_5 ??= <LinkedNodeBuilder>[];
  }

  set classOrMixinDeclaration_members(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_5 = value;
  }

  set forParts_updaters(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_5 = value;
  }

  @override
  LinkedNodeBuilder get classOrMixinDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_13;
  }

  set classOrMixinDeclaration_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_13 = value;
  }

  @override
  int get codeLength {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_34 ??= 0;
  }

  set codeLength(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    assert(value == null || value >= 0);
    _variantField_34 = value;
  }

  @override
  int get codeOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_33 ??= 0;
  }

  @override
  int get directive_semicolon {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_33 ??= 0;
  }

  set codeOffset(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    assert(value == null || value >= 0);
    _variantField_33 = value;
  }

  set directive_semicolon(int value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    assert(value == null || value >= 0);
    _variantField_33 = value;
  }

  @override
  List<int> get comment_tokens {
    assert(kind == idl.LinkedNodeKind.comment);
    return _variantField_28 ??= <int>[];
  }

  @override
  List<int> get symbolLiteral_components {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    return _variantField_28 ??= <int>[];
  }

  set comment_tokens(List<int> value) {
    assert(kind == idl.LinkedNodeKind.comment);
    assert(value == null || value.every((e) => e >= 0));
    _variantField_28 = value;
  }

  set symbolLiteral_components(List<int> value) {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    assert(value == null || value.every((e) => e >= 0));
    _variantField_28 = value;
  }

  @override
  idl.LinkedNodeCommentType get comment_type {
    assert(kind == idl.LinkedNodeKind.comment);
    return _variantField_29 ??= idl.LinkedNodeCommentType.block;
  }

  set comment_type(idl.LinkedNodeCommentType value) {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_29 = value;
  }

  @override
  List<LinkedNodeBuilder> get compilationUnit_directives {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_3 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get namespaceDirective_configurations {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    return _variantField_3 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get switchMember_labels {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    return _variantField_3 ??= <LinkedNodeBuilder>[];
  }

  set compilationUnit_directives(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_3 = value;
  }

  set namespaceDirective_configurations(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_3 = value;
  }

  set switchMember_labels(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_3 = value;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_10;
  }

  @override
  LinkedNodeBuilder get methodDeclaration_name {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    return _variantField_10;
  }

  set constructorDeclaration_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_10 = value;
  }

  set methodDeclaration_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_10 = value;
  }

  @override
  idl.LinkedNodeFormalParameterKind get defaultFormalParameter_kind {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    return _variantField_26 ??=
        idl.LinkedNodeFormalParameterKind.requiredPositional;
  }

  set defaultFormalParameter_kind(idl.LinkedNodeFormalParameterKind value) {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_26 = value;
  }

  @override
  double get doubleLiteral_value {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    return _variantField_21 ??= 0.0;
  }

  set doubleLiteral_value(double value) {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    _variantField_21 = value;
  }

  @override
  LinkedNodeTypeBuilder get expression_type {
    assert(kind == idl.LinkedNodeKind.adjacentStrings ||
        kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.booleanLiteral ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.doubleLiteral ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.isExpression ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.namedExpression ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
        kind == idl.LinkedNodeKind.simpleStringLiteral ||
        kind == idl.LinkedNodeKind.stringInterpolation ||
        kind == idl.LinkedNodeKind.superExpression ||
        kind == idl.LinkedNodeKind.symbolLiteral ||
        kind == idl.LinkedNodeKind.thisExpression ||
        kind == idl.LinkedNodeKind.throwExpression);
    return _variantField_25;
  }

  @override
  LinkedNodeTypeBuilder get genericFunctionType_type {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_25;
  }

  set expression_type(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.adjacentStrings ||
        kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.booleanLiteral ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.doubleLiteral ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.isExpression ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.namedExpression ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
        kind == idl.LinkedNodeKind.simpleStringLiteral ||
        kind == idl.LinkedNodeKind.stringInterpolation ||
        kind == idl.LinkedNodeKind.superExpression ||
        kind == idl.LinkedNodeKind.symbolLiteral ||
        kind == idl.LinkedNodeKind.thisExpression ||
        kind == idl.LinkedNodeKind.throwExpression);
    _variantField_25 = value;
  }

  set genericFunctionType_type(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_25 = value;
  }

  @override
  String get interpolationString_value {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    return _variantField_30 ??= '';
  }

  set interpolationString_value(String value) {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    _variantField_30 = value;
  }

  @override
  LinkedNodeBuilder get invocationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    return _variantField_14;
  }

  @override
  LinkedNodeBuilder get namedCompilationUnitMember_name {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_14;
  }

  @override
  LinkedNodeBuilder get normalFormalParameter_comment {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    return _variantField_14;
  }

  @override
  LinkedNodeBuilder get typedLiteral_typeArguments {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_14;
  }

  @override
  LinkedNodeBuilder get uriBasedDirective_uri {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    return _variantField_14;
  }

  set invocationExpression_arguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_14 = value;
  }

  set namedCompilationUnitMember_name(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_14 = value;
  }

  set normalFormalParameter_comment(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_14 = value;
  }

  set typedLiteral_typeArguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_14 = value;
  }

  set uriBasedDirective_uri(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_14 = value;
  }

  @override
  bool get isSynthetic => _isSynthetic ??= false;

  set isSynthetic(bool value) {
    this._isSynthetic = value;
  }

  @override
  idl.LinkedNodeKind get kind => _kind ??= idl.LinkedNodeKind.adjacentStrings;

  set kind(idl.LinkedNodeKind value) {
    this._kind = value;
  }

  @override
  List<String> get mixinDeclaration_superInvokedNames {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_36 ??= <String>[];
  }

  set mixinDeclaration_superInvokedNames(List<String> value) {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_36 = value;
  }

  @override
  String get namespaceDirective_selectedUri {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    return _variantField_20 ??= '';
  }

  @override
  String get simpleStringLiteral_value {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    return _variantField_20 ??= '';
  }

  set namespaceDirective_selectedUri(String value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_20 = value;
  }

  set simpleStringLiteral_value(String value) {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    _variantField_20 = value;
  }

  @override
  bool get setOrMapLiteral_isSet {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_31 ??= false;
  }

  @override
  bool get simplyBoundable_isSimplyBounded {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_31 ??= false;
  }

  set setOrMapLiteral_isSet(bool value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_31 = value;
  }

  set simplyBoundable_isSimplyBounded(bool value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_31 = value;
  }

  @override
  TopLevelInferenceErrorBuilder get topLevelTypeInferenceError {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_35;
  }

  set topLevelTypeInferenceError(TopLevelInferenceErrorBuilder value) {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_35 = value;
  }

  @override
  String get uriBasedDirective_uriContent {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    return _variantField_22 ??= '';
  }

  set uriBasedDirective_uriContent(String value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_22 = value;
  }

  @override
  LinkedNodeVariablesDeclarationBuilder get variableDeclaration_declaration {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_32;
  }

  set variableDeclaration_declaration(
      LinkedNodeVariablesDeclarationBuilder value) {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_32 = value;
  }

  LinkedNodeBuilder.functionDeclaration({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder functionDeclaration_functionExpression,
    int functionDeclaration_externalKeyword,
    LinkedNodeBuilder functionDeclaration_returnType,
    int functionDeclaration_propertyKeyword,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
  })  : _kind = idl.LinkedNodeKind.functionDeclaration,
        _variantField_24 = actualReturnType,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = functionDeclaration_functionExpression,
        _variantField_15 = functionDeclaration_externalKeyword,
        _variantField_7 = functionDeclaration_returnType,
        _variantField_16 = functionDeclaration_propertyKeyword,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name;

  LinkedNodeBuilder.functionExpression({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder functionExpression_body,
    LinkedNodeBuilder functionExpression_formalParameters,
    LinkedNodeBuilder functionExpression_typeParameters,
  })  : _kind = idl.LinkedNodeKind.functionExpression,
        _variantField_24 = actualReturnType,
        _variantField_6 = functionExpression_body,
        _variantField_7 = functionExpression_formalParameters,
        _variantField_8 = functionExpression_typeParameters;

  LinkedNodeBuilder.functionTypeAlias({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder functionTypeAlias_formalParameters,
    LinkedNodeBuilder functionTypeAlias_returnType,
    LinkedNodeBuilder functionTypeAlias_typeParameters,
    int typeAlias_typedefKeyword,
    int typeAlias_semicolon,
    bool typeAlias_hasSelfReference,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.functionTypeAlias,
        _variantField_24 = actualReturnType,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = functionTypeAlias_formalParameters,
        _variantField_7 = functionTypeAlias_returnType,
        _variantField_8 = functionTypeAlias_typeParameters,
        _variantField_18 = typeAlias_typedefKeyword,
        _variantField_19 = typeAlias_semicolon,
        _variantField_27 = typeAlias_hasSelfReference,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.genericFunctionType({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder genericFunctionType_typeParameters,
    int genericFunctionType_functionKeyword,
    LinkedNodeBuilder genericFunctionType_returnType,
    int genericFunctionType_id,
    LinkedNodeBuilder genericFunctionType_formalParameters,
    int genericFunctionType_question,
    LinkedNodeTypeBuilder genericFunctionType_type,
  })  : _kind = idl.LinkedNodeKind.genericFunctionType,
        _variantField_24 = actualReturnType,
        _variantField_6 = genericFunctionType_typeParameters,
        _variantField_15 = genericFunctionType_functionKeyword,
        _variantField_7 = genericFunctionType_returnType,
        _variantField_17 = genericFunctionType_id,
        _variantField_8 = genericFunctionType_formalParameters,
        _variantField_16 = genericFunctionType_question,
        _variantField_25 = genericFunctionType_type;

  LinkedNodeBuilder.methodDeclaration({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder methodDeclaration_body,
    int methodDeclaration_externalKeyword,
    LinkedNodeBuilder methodDeclaration_formalParameters,
    int methodDeclaration_operatorKeyword,
    LinkedNodeBuilder methodDeclaration_returnType,
    int methodDeclaration_modifierKeyword,
    int methodDeclaration_propertyKeyword,
    int methodDeclaration_actualProperty,
    LinkedNodeBuilder methodDeclaration_typeParameters,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder methodDeclaration_name,
  })  : _kind = idl.LinkedNodeKind.methodDeclaration,
        _variantField_24 = actualReturnType,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = methodDeclaration_body,
        _variantField_15 = methodDeclaration_externalKeyword,
        _variantField_7 = methodDeclaration_formalParameters,
        _variantField_17 = methodDeclaration_operatorKeyword,
        _variantField_8 = methodDeclaration_returnType,
        _variantField_16 = methodDeclaration_modifierKeyword,
        _variantField_18 = methodDeclaration_propertyKeyword,
        _variantField_19 = methodDeclaration_actualProperty,
        _variantField_9 = methodDeclaration_typeParameters,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_10 = methodDeclaration_name;

  LinkedNodeBuilder.fieldFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder fieldFormalParameter_type,
    int fieldFormalParameter_keyword,
    LinkedNodeBuilder fieldFormalParameter_typeParameters,
    int fieldFormalParameter_thisKeyword,
    LinkedNodeBuilder fieldFormalParameter_formalParameters,
    int fieldFormalParameter_period,
    int normalFormalParameter_requiredKeyword,
    int normalFormalParameter_covariantKeyword,
    bool inheritsCovariant,
    LinkedNodeBuilder normalFormalParameter_identifier,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder normalFormalParameter_comment,
  })  : _kind = idl.LinkedNodeKind.fieldFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = fieldFormalParameter_type,
        _variantField_15 = fieldFormalParameter_keyword,
        _variantField_7 = fieldFormalParameter_typeParameters,
        _variantField_17 = fieldFormalParameter_thisKeyword,
        _variantField_8 = fieldFormalParameter_formalParameters,
        _variantField_16 = fieldFormalParameter_period,
        _variantField_18 = normalFormalParameter_requiredKeyword,
        _variantField_19 = normalFormalParameter_covariantKeyword,
        _variantField_27 = inheritsCovariant,
        _variantField_12 = normalFormalParameter_identifier,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = normalFormalParameter_comment;

  LinkedNodeBuilder.functionTypedFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder functionTypedFormalParameter_formalParameters,
    LinkedNodeBuilder functionTypedFormalParameter_returnType,
    LinkedNodeBuilder functionTypedFormalParameter_typeParameters,
    int normalFormalParameter_requiredKeyword,
    int normalFormalParameter_covariantKeyword,
    bool inheritsCovariant,
    LinkedNodeBuilder normalFormalParameter_identifier,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder normalFormalParameter_comment,
  })  : _kind = idl.LinkedNodeKind.functionTypedFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = functionTypedFormalParameter_formalParameters,
        _variantField_7 = functionTypedFormalParameter_returnType,
        _variantField_8 = functionTypedFormalParameter_typeParameters,
        _variantField_18 = normalFormalParameter_requiredKeyword,
        _variantField_19 = normalFormalParameter_covariantKeyword,
        _variantField_27 = inheritsCovariant,
        _variantField_12 = normalFormalParameter_identifier,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = normalFormalParameter_comment;

  LinkedNodeBuilder.simpleFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder simpleFormalParameter_type,
    int simpleFormalParameter_keyword,
    int normalFormalParameter_requiredKeyword,
    int normalFormalParameter_covariantKeyword,
    bool inheritsCovariant,
    LinkedNodeBuilder normalFormalParameter_identifier,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder normalFormalParameter_comment,
    TopLevelInferenceErrorBuilder topLevelTypeInferenceError,
  })  : _kind = idl.LinkedNodeKind.simpleFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = simpleFormalParameter_type,
        _variantField_15 = simpleFormalParameter_keyword,
        _variantField_18 = normalFormalParameter_requiredKeyword,
        _variantField_19 = normalFormalParameter_covariantKeyword,
        _variantField_27 = inheritsCovariant,
        _variantField_12 = normalFormalParameter_identifier,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = normalFormalParameter_comment,
        _variantField_35 = topLevelTypeInferenceError;

  LinkedNodeBuilder.variableDeclaration({
    LinkedNodeTypeBuilder actualType,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder variableDeclaration_initializer,
    int variableDeclaration_equals,
    LinkedNodeBuilder variableDeclaration_name,
    bool inheritsCovariant,
    int codeLength,
    int codeOffset,
    TopLevelInferenceErrorBuilder topLevelTypeInferenceError,
    LinkedNodeVariablesDeclarationBuilder variableDeclaration_declaration,
  })  : _kind = idl.LinkedNodeKind.variableDeclaration,
        _variantField_24 = actualType,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = variableDeclaration_initializer,
        _variantField_15 = variableDeclaration_equals,
        _variantField_7 = variableDeclaration_name,
        _variantField_27 = inheritsCovariant,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_35 = topLevelTypeInferenceError,
        _variantField_32 = variableDeclaration_declaration;

  LinkedNodeBuilder.binaryExpression({
    LinkedNodeTypeBuilder binaryExpression_invokeType,
    LinkedNodeBuilder binaryExpression_leftOperand,
    int binaryExpression_element,
    LinkedNodeBuilder binaryExpression_rightOperand,
    LinkedNodeTypeBuilder binaryExpression_elementType,
    int binaryExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.binaryExpression,
        _variantField_24 = binaryExpression_invokeType,
        _variantField_6 = binaryExpression_leftOperand,
        _variantField_15 = binaryExpression_element,
        _variantField_7 = binaryExpression_rightOperand,
        _variantField_23 = binaryExpression_elementType,
        _variantField_16 = binaryExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.functionExpressionInvocation({
    LinkedNodeTypeBuilder invocationExpression_invokeType,
    LinkedNodeBuilder functionExpressionInvocation_function,
    LinkedNodeBuilder invocationExpression_typeArguments,
    LinkedNodeTypeBuilder expression_type,
    LinkedNodeBuilder invocationExpression_arguments,
  })  : _kind = idl.LinkedNodeKind.functionExpressionInvocation,
        _variantField_24 = invocationExpression_invokeType,
        _variantField_6 = functionExpressionInvocation_function,
        _variantField_12 = invocationExpression_typeArguments,
        _variantField_25 = expression_type,
        _variantField_14 = invocationExpression_arguments;

  LinkedNodeBuilder.methodInvocation({
    LinkedNodeTypeBuilder invocationExpression_invokeType,
    LinkedNodeBuilder methodInvocation_methodName,
    int methodInvocation_operator,
    LinkedNodeBuilder methodInvocation_target,
    LinkedNodeBuilder invocationExpression_typeArguments,
    LinkedNodeTypeBuilder expression_type,
    LinkedNodeBuilder invocationExpression_arguments,
  })  : _kind = idl.LinkedNodeKind.methodInvocation,
        _variantField_24 = invocationExpression_invokeType,
        _variantField_6 = methodInvocation_methodName,
        _variantField_15 = methodInvocation_operator,
        _variantField_7 = methodInvocation_target,
        _variantField_12 = invocationExpression_typeArguments,
        _variantField_25 = expression_type,
        _variantField_14 = invocationExpression_arguments;

  LinkedNodeBuilder.adjacentStrings({
    List<LinkedNodeBuilder> adjacentStrings_strings,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.adjacentStrings,
        _variantField_2 = adjacentStrings_strings,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.argumentList({
    List<LinkedNodeBuilder> argumentList_arguments,
    int argumentList_leftParenthesis,
    int argumentList_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.argumentList,
        _variantField_2 = argumentList_arguments,
        _variantField_15 = argumentList_leftParenthesis,
        _variantField_16 = argumentList_rightParenthesis;

  LinkedNodeBuilder.block({
    List<LinkedNodeBuilder> block_statements,
    int block_leftBracket,
    int block_rightBracket,
  })  : _kind = idl.LinkedNodeKind.block,
        _variantField_2 = block_statements,
        _variantField_15 = block_leftBracket,
        _variantField_16 = block_rightBracket;

  LinkedNodeBuilder.cascadeExpression({
    List<LinkedNodeBuilder> cascadeExpression_sections,
    LinkedNodeBuilder cascadeExpression_target,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.cascadeExpression,
        _variantField_2 = cascadeExpression_sections,
        _variantField_6 = cascadeExpression_target,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.comment({
    List<LinkedNodeBuilder> comment_references,
    List<int> comment_tokens,
    idl.LinkedNodeCommentType comment_type,
  })  : _kind = idl.LinkedNodeKind.comment,
        _variantField_2 = comment_references,
        _variantField_28 = comment_tokens,
        _variantField_29 = comment_type;

  LinkedNodeBuilder.compilationUnit({
    List<LinkedNodeBuilder> compilationUnit_declarations,
    LinkedNodeBuilder compilationUnit_scriptTag,
    int compilationUnit_beginToken,
    int compilationUnit_endToken,
    int codeLength,
    int codeOffset,
    List<LinkedNodeBuilder> compilationUnit_directives,
  })  : _kind = idl.LinkedNodeKind.compilationUnit,
        _variantField_2 = compilationUnit_declarations,
        _variantField_6 = compilationUnit_scriptTag,
        _variantField_15 = compilationUnit_beginToken,
        _variantField_16 = compilationUnit_endToken,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_3 = compilationUnit_directives;

  LinkedNodeBuilder.constructorDeclaration({
    List<LinkedNodeBuilder> constructorDeclaration_initializers,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder constructorDeclaration_body,
    int constructorDeclaration_constKeyword,
    LinkedNodeBuilder constructorDeclaration_name,
    int constructorDeclaration_factoryKeyword,
    LinkedNodeBuilder constructorDeclaration_parameters,
    int constructorDeclaration_externalKeyword,
    int constructorDeclaration_period,
    int constructorDeclaration_separator,
    LinkedNodeBuilder constructorDeclaration_redirectedConstructor,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder constructorDeclaration_returnType,
  })  : _kind = idl.LinkedNodeKind.constructorDeclaration,
        _variantField_2 = constructorDeclaration_initializers,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = constructorDeclaration_body,
        _variantField_15 = constructorDeclaration_constKeyword,
        _variantField_7 = constructorDeclaration_name,
        _variantField_17 = constructorDeclaration_factoryKeyword,
        _variantField_8 = constructorDeclaration_parameters,
        _variantField_16 = constructorDeclaration_externalKeyword,
        _variantField_18 = constructorDeclaration_period,
        _variantField_19 = constructorDeclaration_separator,
        _variantField_9 = constructorDeclaration_redirectedConstructor,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_10 = constructorDeclaration_returnType;

  LinkedNodeBuilder.dottedName({
    List<LinkedNodeBuilder> dottedName_components,
  })  : _kind = idl.LinkedNodeKind.dottedName,
        _variantField_2 = dottedName_components;

  LinkedNodeBuilder.enumDeclaration({
    List<LinkedNodeBuilder> enumDeclaration_constants,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int enumDeclaration_enumKeyword,
    int enumDeclaration_rightBracket,
    int enumDeclaration_leftBracket,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
  })  : _kind = idl.LinkedNodeKind.enumDeclaration,
        _variantField_2 = enumDeclaration_constants,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_15 = enumDeclaration_enumKeyword,
        _variantField_17 = enumDeclaration_rightBracket,
        _variantField_16 = enumDeclaration_leftBracket,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name;

  LinkedNodeBuilder.formalParameterList({
    List<LinkedNodeBuilder> formalParameterList_parameters,
    int formalParameterList_leftDelimiter,
    int formalParameterList_rightDelimiter,
    int formalParameterList_leftParenthesis,
    int formalParameterList_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.formalParameterList,
        _variantField_2 = formalParameterList_parameters,
        _variantField_15 = formalParameterList_leftDelimiter,
        _variantField_17 = formalParameterList_rightDelimiter,
        _variantField_16 = formalParameterList_leftParenthesis,
        _variantField_18 = formalParameterList_rightParenthesis;

  LinkedNodeBuilder.hideCombinator({
    List<LinkedNodeBuilder> hideCombinator_hiddenNames,
    int combinator_keyword,
  })  : _kind = idl.LinkedNodeKind.hideCombinator,
        _variantField_2 = hideCombinator_hiddenNames,
        _variantField_19 = combinator_keyword;

  LinkedNodeBuilder.implementsClause({
    List<LinkedNodeBuilder> implementsClause_interfaces,
    int implementsClause_implementsKeyword,
  })  : _kind = idl.LinkedNodeKind.implementsClause,
        _variantField_2 = implementsClause_interfaces,
        _variantField_15 = implementsClause_implementsKeyword;

  LinkedNodeBuilder.labeledStatement({
    List<LinkedNodeBuilder> labeledStatement_labels,
    LinkedNodeBuilder labeledStatement_statement,
  })  : _kind = idl.LinkedNodeKind.labeledStatement,
        _variantField_2 = labeledStatement_labels,
        _variantField_6 = labeledStatement_statement;

  LinkedNodeBuilder.libraryIdentifier({
    List<LinkedNodeBuilder> libraryIdentifier_components,
  })  : _kind = idl.LinkedNodeKind.libraryIdentifier,
        _variantField_2 = libraryIdentifier_components;

  LinkedNodeBuilder.listLiteral({
    List<LinkedNodeBuilder> listLiteral_elements,
    int listLiteral_leftBracket,
    int listLiteral_rightBracket,
    int typedLiteral_constKeyword,
    LinkedNodeTypeBuilder expression_type,
    LinkedNodeBuilder typedLiteral_typeArguments,
  })  : _kind = idl.LinkedNodeKind.listLiteral,
        _variantField_2 = listLiteral_elements,
        _variantField_15 = listLiteral_leftBracket,
        _variantField_16 = listLiteral_rightBracket,
        _variantField_19 = typedLiteral_constKeyword,
        _variantField_25 = expression_type,
        _variantField_14 = typedLiteral_typeArguments;

  LinkedNodeBuilder.exportDirective({
    List<LinkedNodeBuilder> namespaceDirective_combinators,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int directive_keyword,
    int uriBasedDirective_uriElement,
    int directive_semicolon,
    List<LinkedNodeBuilder> namespaceDirective_configurations,
    LinkedNodeBuilder uriBasedDirective_uri,
    String namespaceDirective_selectedUri,
    String uriBasedDirective_uriContent,
  })  : _kind = idl.LinkedNodeKind.exportDirective,
        _variantField_2 = namespaceDirective_combinators,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_18 = directive_keyword,
        _variantField_19 = uriBasedDirective_uriElement,
        _variantField_33 = directive_semicolon,
        _variantField_3 = namespaceDirective_configurations,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_20 = namespaceDirective_selectedUri,
        _variantField_22 = uriBasedDirective_uriContent;

  LinkedNodeBuilder.importDirective({
    List<LinkedNodeBuilder> namespaceDirective_combinators,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder importDirective_prefix,
    int importDirective_asKeyword,
    int importDirective_deferredKeyword,
    int directive_keyword,
    int uriBasedDirective_uriElement,
    int directive_semicolon,
    List<LinkedNodeBuilder> namespaceDirective_configurations,
    LinkedNodeBuilder uriBasedDirective_uri,
    String namespaceDirective_selectedUri,
    String uriBasedDirective_uriContent,
  })  : _kind = idl.LinkedNodeKind.importDirective,
        _variantField_2 = namespaceDirective_combinators,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = importDirective_prefix,
        _variantField_15 = importDirective_asKeyword,
        _variantField_16 = importDirective_deferredKeyword,
        _variantField_18 = directive_keyword,
        _variantField_19 = uriBasedDirective_uriElement,
        _variantField_33 = directive_semicolon,
        _variantField_3 = namespaceDirective_configurations,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_20 = namespaceDirective_selectedUri,
        _variantField_22 = uriBasedDirective_uriContent;

  LinkedNodeBuilder.onClause({
    List<LinkedNodeBuilder> onClause_superclassConstraints,
    int onClause_onKeyword,
  })  : _kind = idl.LinkedNodeKind.onClause,
        _variantField_2 = onClause_superclassConstraints,
        _variantField_15 = onClause_onKeyword;

  LinkedNodeBuilder.setOrMapLiteral({
    List<LinkedNodeBuilder> setOrMapLiteral_elements,
    int setOrMapLiteral_leftBracket,
    int setOrMapLiteral_rightBracket,
    int typedLiteral_constKeyword,
    bool setOrMapLiteral_isMap,
    LinkedNodeTypeBuilder expression_type,
    LinkedNodeBuilder typedLiteral_typeArguments,
    bool setOrMapLiteral_isSet,
  })  : _kind = idl.LinkedNodeKind.setOrMapLiteral,
        _variantField_2 = setOrMapLiteral_elements,
        _variantField_15 = setOrMapLiteral_leftBracket,
        _variantField_16 = setOrMapLiteral_rightBracket,
        _variantField_19 = typedLiteral_constKeyword,
        _variantField_27 = setOrMapLiteral_isMap,
        _variantField_25 = expression_type,
        _variantField_14 = typedLiteral_typeArguments,
        _variantField_31 = setOrMapLiteral_isSet;

  LinkedNodeBuilder.showCombinator({
    List<LinkedNodeBuilder> showCombinator_shownNames,
    int combinator_keyword,
  })  : _kind = idl.LinkedNodeKind.showCombinator,
        _variantField_2 = showCombinator_shownNames,
        _variantField_19 = combinator_keyword;

  LinkedNodeBuilder.stringInterpolation({
    List<LinkedNodeBuilder> stringInterpolation_elements,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.stringInterpolation,
        _variantField_2 = stringInterpolation_elements,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.switchStatement({
    List<LinkedNodeBuilder> switchStatement_members,
    int switchStatement_leftParenthesis,
    LinkedNodeBuilder switchStatement_expression,
    int switchStatement_switchKeyword,
    int switchStatement_rightParenthesis,
    int switchStatement_leftBracket,
    int switchStatement_rightBracket,
  })  : _kind = idl.LinkedNodeKind.switchStatement,
        _variantField_2 = switchStatement_members,
        _variantField_15 = switchStatement_leftParenthesis,
        _variantField_7 = switchStatement_expression,
        _variantField_17 = switchStatement_switchKeyword,
        _variantField_16 = switchStatement_rightParenthesis,
        _variantField_18 = switchStatement_leftBracket,
        _variantField_19 = switchStatement_rightBracket;

  LinkedNodeBuilder.tryStatement({
    List<LinkedNodeBuilder> tryStatement_catchClauses,
    LinkedNodeBuilder tryStatement_body,
    int tryStatement_finallyKeyword,
    LinkedNodeBuilder tryStatement_finallyBlock,
    int tryStatement_tryKeyword,
  })  : _kind = idl.LinkedNodeKind.tryStatement,
        _variantField_2 = tryStatement_catchClauses,
        _variantField_6 = tryStatement_body,
        _variantField_15 = tryStatement_finallyKeyword,
        _variantField_7 = tryStatement_finallyBlock,
        _variantField_16 = tryStatement_tryKeyword;

  LinkedNodeBuilder.typeArgumentList({
    List<LinkedNodeBuilder> typeArgumentList_arguments,
    int typeArgumentList_leftBracket,
    int typeArgumentList_rightBracket,
  })  : _kind = idl.LinkedNodeKind.typeArgumentList,
        _variantField_2 = typeArgumentList_arguments,
        _variantField_15 = typeArgumentList_leftBracket,
        _variantField_16 = typeArgumentList_rightBracket;

  LinkedNodeBuilder.typeParameterList({
    List<LinkedNodeBuilder> typeParameterList_typeParameters,
    int typeParameterList_leftBracket,
    int typeParameterList_rightBracket,
  })  : _kind = idl.LinkedNodeKind.typeParameterList,
        _variantField_2 = typeParameterList_typeParameters,
        _variantField_15 = typeParameterList_leftBracket,
        _variantField_16 = typeParameterList_rightBracket;

  LinkedNodeBuilder.variableDeclarationList({
    List<LinkedNodeBuilder> variableDeclarationList_variables,
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder variableDeclarationList_type,
    int variableDeclarationList_keyword,
    int variableDeclarationList_lateKeyword,
  })  : _kind = idl.LinkedNodeKind.variableDeclarationList,
        _variantField_2 = variableDeclarationList_variables,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = variableDeclarationList_type,
        _variantField_15 = variableDeclarationList_keyword,
        _variantField_16 = variableDeclarationList_lateKeyword;

  LinkedNodeBuilder.withClause({
    List<LinkedNodeBuilder> withClause_mixinTypes,
    int withClause_withKeyword,
  })  : _kind = idl.LinkedNodeKind.withClause,
        _variantField_2 = withClause_mixinTypes,
        _variantField_15 = withClause_withKeyword;

  LinkedNodeBuilder.classDeclaration({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder classDeclaration_extendsClause,
    int classDeclaration_abstractKeyword,
    LinkedNodeBuilder classDeclaration_withClause,
    LinkedNodeBuilder classDeclaration_nativeClause,
    int classDeclaration_classKeyword,
    int classOrMixinDeclaration_rightBracket,
    int classOrMixinDeclaration_leftBracket,
    bool classDeclaration_isDartObject,
    LinkedNodeBuilder classOrMixinDeclaration_implementsClause,
    List<LinkedNodeBuilder> classOrMixinDeclaration_members,
    LinkedNodeBuilder classOrMixinDeclaration_typeParameters,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.classDeclaration,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = classDeclaration_extendsClause,
        _variantField_15 = classDeclaration_abstractKeyword,
        _variantField_7 = classDeclaration_withClause,
        _variantField_8 = classDeclaration_nativeClause,
        _variantField_16 = classDeclaration_classKeyword,
        _variantField_18 = classOrMixinDeclaration_rightBracket,
        _variantField_19 = classOrMixinDeclaration_leftBracket,
        _variantField_27 = classDeclaration_isDartObject,
        _variantField_12 = classOrMixinDeclaration_implementsClause,
        _variantField_5 = classOrMixinDeclaration_members,
        _variantField_13 = classOrMixinDeclaration_typeParameters,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.classTypeAlias({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder classTypeAlias_typeParameters,
    int classTypeAlias_abstractKeyword,
    LinkedNodeBuilder classTypeAlias_superclass,
    LinkedNodeBuilder classTypeAlias_withClause,
    int classTypeAlias_equals,
    int typeAlias_typedefKeyword,
    int typeAlias_semicolon,
    LinkedNodeBuilder classTypeAlias_implementsClause,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.classTypeAlias,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = classTypeAlias_typeParameters,
        _variantField_15 = classTypeAlias_abstractKeyword,
        _variantField_7 = classTypeAlias_superclass,
        _variantField_8 = classTypeAlias_withClause,
        _variantField_16 = classTypeAlias_equals,
        _variantField_18 = typeAlias_typedefKeyword,
        _variantField_19 = typeAlias_semicolon,
        _variantField_9 = classTypeAlias_implementsClause,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.declaredIdentifier({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder declaredIdentifier_identifier,
    int declaredIdentifier_keyword,
    LinkedNodeBuilder declaredIdentifier_type,
  })  : _kind = idl.LinkedNodeKind.declaredIdentifier,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = declaredIdentifier_identifier,
        _variantField_15 = declaredIdentifier_keyword,
        _variantField_7 = declaredIdentifier_type;

  LinkedNodeBuilder.enumConstantDeclaration({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder enumConstantDeclaration_name,
  })  : _kind = idl.LinkedNodeKind.enumConstantDeclaration,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = enumConstantDeclaration_name;

  LinkedNodeBuilder.fieldDeclaration({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder fieldDeclaration_fields,
    int fieldDeclaration_covariantKeyword,
    int fieldDeclaration_staticKeyword,
    int fieldDeclaration_semicolon,
  })  : _kind = idl.LinkedNodeKind.fieldDeclaration,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = fieldDeclaration_fields,
        _variantField_15 = fieldDeclaration_covariantKeyword,
        _variantField_17 = fieldDeclaration_staticKeyword,
        _variantField_16 = fieldDeclaration_semicolon;

  LinkedNodeBuilder.genericTypeAlias({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder genericTypeAlias_typeParameters,
    LinkedNodeBuilder genericTypeAlias_functionType,
    int genericTypeAlias_equals,
    int typeAlias_typedefKeyword,
    int typeAlias_semicolon,
    bool typeAlias_hasSelfReference,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.genericTypeAlias,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = genericTypeAlias_typeParameters,
        _variantField_7 = genericTypeAlias_functionType,
        _variantField_16 = genericTypeAlias_equals,
        _variantField_18 = typeAlias_typedefKeyword,
        _variantField_19 = typeAlias_semicolon,
        _variantField_27 = typeAlias_hasSelfReference,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.libraryDirective({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder libraryDirective_name,
    int directive_keyword,
    int directive_semicolon,
  })  : _kind = idl.LinkedNodeKind.libraryDirective,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = libraryDirective_name,
        _variantField_18 = directive_keyword,
        _variantField_33 = directive_semicolon;

  LinkedNodeBuilder.mixinDeclaration({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder mixinDeclaration_onClause,
    int mixinDeclaration_mixinKeyword,
    int classOrMixinDeclaration_rightBracket,
    int classOrMixinDeclaration_leftBracket,
    LinkedNodeBuilder classOrMixinDeclaration_implementsClause,
    List<LinkedNodeBuilder> classOrMixinDeclaration_members,
    LinkedNodeBuilder classOrMixinDeclaration_typeParameters,
    int codeLength,
    int codeOffset,
    LinkedNodeBuilder namedCompilationUnitMember_name,
    List<String> mixinDeclaration_superInvokedNames,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.mixinDeclaration,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = mixinDeclaration_onClause,
        _variantField_15 = mixinDeclaration_mixinKeyword,
        _variantField_18 = classOrMixinDeclaration_rightBracket,
        _variantField_19 = classOrMixinDeclaration_leftBracket,
        _variantField_12 = classOrMixinDeclaration_implementsClause,
        _variantField_5 = classOrMixinDeclaration_members,
        _variantField_13 = classOrMixinDeclaration_typeParameters,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_14 = namedCompilationUnitMember_name,
        _variantField_36 = mixinDeclaration_superInvokedNames,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.partDirective({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int directive_keyword,
    int uriBasedDirective_uriElement,
    int directive_semicolon,
    LinkedNodeBuilder uriBasedDirective_uri,
    String uriBasedDirective_uriContent,
  })  : _kind = idl.LinkedNodeKind.partDirective,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_18 = directive_keyword,
        _variantField_19 = uriBasedDirective_uriElement,
        _variantField_33 = directive_semicolon,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_22 = uriBasedDirective_uriContent;

  LinkedNodeBuilder.partOfDirective({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder partOfDirective_libraryName,
    LinkedNodeBuilder partOfDirective_uri,
    int partOfDirective_ofKeyword,
    int directive_keyword,
    int directive_semicolon,
  })  : _kind = idl.LinkedNodeKind.partOfDirective,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = partOfDirective_libraryName,
        _variantField_7 = partOfDirective_uri,
        _variantField_16 = partOfDirective_ofKeyword,
        _variantField_18 = directive_keyword,
        _variantField_33 = directive_semicolon;

  LinkedNodeBuilder.topLevelVariableDeclaration({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder topLevelVariableDeclaration_variableList,
    int topLevelVariableDeclaration_semicolon,
  })  : _kind = idl.LinkedNodeKind.topLevelVariableDeclaration,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = topLevelVariableDeclaration_variableList,
        _variantField_15 = topLevelVariableDeclaration_semicolon;

  LinkedNodeBuilder.typeParameter({
    LinkedNodeBuilder annotatedNode_comment,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder typeParameter_bound,
    int typeParameter_extendsKeyword,
    LinkedNodeBuilder typeParameter_name,
    LinkedNodeTypeBuilder typeParameter_defaultType,
    int codeLength,
    int codeOffset,
  })  : _kind = idl.LinkedNodeKind.typeParameter,
        _variantField_11 = annotatedNode_comment,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = typeParameter_bound,
        _variantField_15 = typeParameter_extendsKeyword,
        _variantField_7 = typeParameter_name,
        _variantField_23 = typeParameter_defaultType,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset;

  LinkedNodeBuilder.switchCase({
    List<LinkedNodeBuilder> switchMember_statements,
    LinkedNodeBuilder switchCase_expression,
    int switchMember_keyword,
    int switchMember_colon,
    List<LinkedNodeBuilder> switchMember_labels,
  })  : _kind = idl.LinkedNodeKind.switchCase,
        _variantField_4 = switchMember_statements,
        _variantField_6 = switchCase_expression,
        _variantField_15 = switchMember_keyword,
        _variantField_16 = switchMember_colon,
        _variantField_3 = switchMember_labels;

  LinkedNodeBuilder.switchDefault({
    List<LinkedNodeBuilder> switchMember_statements,
    int switchMember_keyword,
    int switchMember_colon,
    List<LinkedNodeBuilder> switchMember_labels,
  })  : _kind = idl.LinkedNodeKind.switchDefault,
        _variantField_4 = switchMember_statements,
        _variantField_15 = switchMember_keyword,
        _variantField_16 = switchMember_colon,
        _variantField_3 = switchMember_labels;

  LinkedNodeBuilder.annotation({
    LinkedNodeBuilder annotation_arguments,
    int annotation_atSign,
    LinkedNodeBuilder annotation_constructorName,
    int annotation_element,
    LinkedNodeTypeBuilder annotation_elementType,
    LinkedNodeBuilder annotation_name,
    int annotation_period,
  })  : _kind = idl.LinkedNodeKind.annotation,
        _variantField_6 = annotation_arguments,
        _variantField_15 = annotation_atSign,
        _variantField_7 = annotation_constructorName,
        _variantField_17 = annotation_element,
        _variantField_23 = annotation_elementType,
        _variantField_8 = annotation_name,
        _variantField_16 = annotation_period;

  LinkedNodeBuilder.asExpression({
    LinkedNodeBuilder asExpression_expression,
    int asExpression_asOperator,
    LinkedNodeBuilder asExpression_type,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.asExpression,
        _variantField_6 = asExpression_expression,
        _variantField_15 = asExpression_asOperator,
        _variantField_7 = asExpression_type,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.assertInitializer({
    LinkedNodeBuilder assertInitializer_condition,
    int assertInitializer_assertKeyword,
    LinkedNodeBuilder assertInitializer_message,
    int assertInitializer_leftParenthesis,
    int assertInitializer_comma,
    int assertInitializer_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.assertInitializer,
        _variantField_6 = assertInitializer_condition,
        _variantField_15 = assertInitializer_assertKeyword,
        _variantField_7 = assertInitializer_message,
        _variantField_17 = assertInitializer_leftParenthesis,
        _variantField_16 = assertInitializer_comma,
        _variantField_18 = assertInitializer_rightParenthesis;

  LinkedNodeBuilder.assertStatement({
    LinkedNodeBuilder assertStatement_condition,
    int assertStatement_assertKeyword,
    LinkedNodeBuilder assertStatement_message,
    int assertStatement_leftParenthesis,
    int assertStatement_comma,
    int assertStatement_rightParenthesis,
    int assertStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.assertStatement,
        _variantField_6 = assertStatement_condition,
        _variantField_15 = assertStatement_assertKeyword,
        _variantField_7 = assertStatement_message,
        _variantField_17 = assertStatement_leftParenthesis,
        _variantField_16 = assertStatement_comma,
        _variantField_18 = assertStatement_rightParenthesis,
        _variantField_19 = assertStatement_semicolon;

  LinkedNodeBuilder.assignmentExpression({
    LinkedNodeBuilder assignmentExpression_leftHandSide,
    int assignmentExpression_element,
    LinkedNodeBuilder assignmentExpression_rightHandSide,
    LinkedNodeTypeBuilder assignmentExpression_elementType,
    int assignmentExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.assignmentExpression,
        _variantField_6 = assignmentExpression_leftHandSide,
        _variantField_15 = assignmentExpression_element,
        _variantField_7 = assignmentExpression_rightHandSide,
        _variantField_23 = assignmentExpression_elementType,
        _variantField_16 = assignmentExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.awaitExpression({
    LinkedNodeBuilder awaitExpression_expression,
    int awaitExpression_awaitKeyword,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.awaitExpression,
        _variantField_6 = awaitExpression_expression,
        _variantField_15 = awaitExpression_awaitKeyword,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.blockFunctionBody({
    LinkedNodeBuilder blockFunctionBody_block,
    int blockFunctionBody_keyword,
    int blockFunctionBody_star,
  })  : _kind = idl.LinkedNodeKind.blockFunctionBody,
        _variantField_6 = blockFunctionBody_block,
        _variantField_15 = blockFunctionBody_keyword,
        _variantField_16 = blockFunctionBody_star;

  LinkedNodeBuilder.breakStatement({
    LinkedNodeBuilder breakStatement_label,
    int breakStatement_breakKeyword,
    int breakStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.breakStatement,
        _variantField_6 = breakStatement_label,
        _variantField_15 = breakStatement_breakKeyword,
        _variantField_16 = breakStatement_semicolon;

  LinkedNodeBuilder.catchClause({
    LinkedNodeBuilder catchClause_body,
    int catchClause_catchKeyword,
    LinkedNodeBuilder catchClause_exceptionParameter,
    int catchClause_leftParenthesis,
    LinkedNodeBuilder catchClause_exceptionType,
    int catchClause_comma,
    int catchClause_onKeyword,
    int catchClause_rightParenthesis,
    LinkedNodeBuilder catchClause_stackTraceParameter,
  })  : _kind = idl.LinkedNodeKind.catchClause,
        _variantField_6 = catchClause_body,
        _variantField_15 = catchClause_catchKeyword,
        _variantField_7 = catchClause_exceptionParameter,
        _variantField_17 = catchClause_leftParenthesis,
        _variantField_8 = catchClause_exceptionType,
        _variantField_16 = catchClause_comma,
        _variantField_18 = catchClause_onKeyword,
        _variantField_19 = catchClause_rightParenthesis,
        _variantField_9 = catchClause_stackTraceParameter;

  LinkedNodeBuilder.commentReference({
    LinkedNodeBuilder commentReference_identifier,
    int commentReference_newKeyword,
  })  : _kind = idl.LinkedNodeKind.commentReference,
        _variantField_6 = commentReference_identifier,
        _variantField_15 = commentReference_newKeyword;

  LinkedNodeBuilder.conditionalExpression({
    LinkedNodeBuilder conditionalExpression_condition,
    int conditionalExpression_colon,
    LinkedNodeBuilder conditionalExpression_elseExpression,
    LinkedNodeBuilder conditionalExpression_thenExpression,
    int conditionalExpression_question,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.conditionalExpression,
        _variantField_6 = conditionalExpression_condition,
        _variantField_15 = conditionalExpression_colon,
        _variantField_7 = conditionalExpression_elseExpression,
        _variantField_8 = conditionalExpression_thenExpression,
        _variantField_16 = conditionalExpression_question,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.configuration({
    LinkedNodeBuilder configuration_name,
    int configuration_ifKeyword,
    LinkedNodeBuilder configuration_value,
    int configuration_rightParenthesis,
    LinkedNodeBuilder configuration_uri,
    int configuration_leftParenthesis,
    int configuration_equalToken,
  })  : _kind = idl.LinkedNodeKind.configuration,
        _variantField_6 = configuration_name,
        _variantField_15 = configuration_ifKeyword,
        _variantField_7 = configuration_value,
        _variantField_17 = configuration_rightParenthesis,
        _variantField_8 = configuration_uri,
        _variantField_16 = configuration_leftParenthesis,
        _variantField_18 = configuration_equalToken;

  LinkedNodeBuilder.constructorFieldInitializer({
    LinkedNodeBuilder constructorFieldInitializer_expression,
    int constructorFieldInitializer_equals,
    LinkedNodeBuilder constructorFieldInitializer_fieldName,
    int constructorFieldInitializer_thisKeyword,
    int constructorFieldInitializer_period,
  })  : _kind = idl.LinkedNodeKind.constructorFieldInitializer,
        _variantField_6 = constructorFieldInitializer_expression,
        _variantField_15 = constructorFieldInitializer_equals,
        _variantField_7 = constructorFieldInitializer_fieldName,
        _variantField_17 = constructorFieldInitializer_thisKeyword,
        _variantField_16 = constructorFieldInitializer_period;

  LinkedNodeBuilder.constructorName({
    LinkedNodeBuilder constructorName_name,
    int constructorName_element,
    LinkedNodeBuilder constructorName_type,
    LinkedNodeTypeBuilder constructorName_elementType,
    int constructorName_period,
  })  : _kind = idl.LinkedNodeKind.constructorName,
        _variantField_6 = constructorName_name,
        _variantField_15 = constructorName_element,
        _variantField_7 = constructorName_type,
        _variantField_23 = constructorName_elementType,
        _variantField_16 = constructorName_period;

  LinkedNodeBuilder.continueStatement({
    LinkedNodeBuilder continueStatement_label,
    int continueStatement_continueKeyword,
    int continueStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.continueStatement,
        _variantField_6 = continueStatement_label,
        _variantField_15 = continueStatement_continueKeyword,
        _variantField_16 = continueStatement_semicolon;

  LinkedNodeBuilder.defaultFormalParameter({
    LinkedNodeBuilder defaultFormalParameter_defaultValue,
    int defaultFormalParameter_separator,
    LinkedNodeBuilder defaultFormalParameter_parameter,
    int codeLength,
    int codeOffset,
    idl.LinkedNodeFormalParameterKind defaultFormalParameter_kind,
  })  : _kind = idl.LinkedNodeKind.defaultFormalParameter,
        _variantField_6 = defaultFormalParameter_defaultValue,
        _variantField_15 = defaultFormalParameter_separator,
        _variantField_7 = defaultFormalParameter_parameter,
        _variantField_34 = codeLength,
        _variantField_33 = codeOffset,
        _variantField_26 = defaultFormalParameter_kind;

  LinkedNodeBuilder.doStatement({
    LinkedNodeBuilder doStatement_body,
    int doStatement_leftParenthesis,
    LinkedNodeBuilder doStatement_condition,
    int doStatement_doKeyword,
    int doStatement_rightParenthesis,
    int doStatement_semicolon,
    int doStatement_whileKeyword,
  })  : _kind = idl.LinkedNodeKind.doStatement,
        _variantField_6 = doStatement_body,
        _variantField_15 = doStatement_leftParenthesis,
        _variantField_7 = doStatement_condition,
        _variantField_17 = doStatement_doKeyword,
        _variantField_16 = doStatement_rightParenthesis,
        _variantField_18 = doStatement_semicolon,
        _variantField_19 = doStatement_whileKeyword;

  LinkedNodeBuilder.expressionFunctionBody({
    LinkedNodeBuilder expressionFunctionBody_expression,
    int expressionFunctionBody_arrow,
    int expressionFunctionBody_semicolon,
    int expressionFunctionBody_keyword,
  })  : _kind = idl.LinkedNodeKind.expressionFunctionBody,
        _variantField_6 = expressionFunctionBody_expression,
        _variantField_15 = expressionFunctionBody_arrow,
        _variantField_17 = expressionFunctionBody_semicolon,
        _variantField_16 = expressionFunctionBody_keyword;

  LinkedNodeBuilder.expressionStatement({
    LinkedNodeBuilder expressionStatement_expression,
    int expressionStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.expressionStatement,
        _variantField_6 = expressionStatement_expression,
        _variantField_15 = expressionStatement_semicolon;

  LinkedNodeBuilder.extendsClause({
    LinkedNodeBuilder extendsClause_superclass,
    int extendsClause_extendsKeyword,
  })  : _kind = idl.LinkedNodeKind.extendsClause,
        _variantField_6 = extendsClause_superclass,
        _variantField_15 = extendsClause_extendsKeyword;

  LinkedNodeBuilder.forEachPartsWithDeclaration({
    LinkedNodeBuilder forEachParts_iterable,
    int forEachParts_inKeyword,
    LinkedNodeBuilder forEachPartsWithDeclaration_loopVariable,
  })  : _kind = idl.LinkedNodeKind.forEachPartsWithDeclaration,
        _variantField_6 = forEachParts_iterable,
        _variantField_15 = forEachParts_inKeyword,
        _variantField_7 = forEachPartsWithDeclaration_loopVariable;

  LinkedNodeBuilder.forEachPartsWithIdentifier({
    LinkedNodeBuilder forEachParts_iterable,
    int forEachParts_inKeyword,
    LinkedNodeBuilder forEachPartsWithIdentifier_identifier,
  })  : _kind = idl.LinkedNodeKind.forEachPartsWithIdentifier,
        _variantField_6 = forEachParts_iterable,
        _variantField_15 = forEachParts_inKeyword,
        _variantField_7 = forEachPartsWithIdentifier_identifier;

  LinkedNodeBuilder.forElement({
    LinkedNodeBuilder forMixin_forLoopParts,
    int forMixin_awaitKeyword,
    LinkedNodeBuilder forElement_body,
    int forMixin_leftParenthesis,
    int forMixin_forKeyword,
    int forMixin_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.forElement,
        _variantField_6 = forMixin_forLoopParts,
        _variantField_15 = forMixin_awaitKeyword,
        _variantField_7 = forElement_body,
        _variantField_17 = forMixin_leftParenthesis,
        _variantField_16 = forMixin_forKeyword,
        _variantField_19 = forMixin_rightParenthesis;

  LinkedNodeBuilder.forStatement({
    LinkedNodeBuilder forMixin_forLoopParts,
    int forMixin_awaitKeyword,
    LinkedNodeBuilder forStatement_body,
    int forMixin_leftParenthesis,
    int forMixin_forKeyword,
    int forMixin_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.forStatement,
        _variantField_6 = forMixin_forLoopParts,
        _variantField_15 = forMixin_awaitKeyword,
        _variantField_7 = forStatement_body,
        _variantField_17 = forMixin_leftParenthesis,
        _variantField_16 = forMixin_forKeyword,
        _variantField_19 = forMixin_rightParenthesis;

  LinkedNodeBuilder.forPartsWithDeclarations({
    LinkedNodeBuilder forParts_condition,
    int forParts_leftSeparator,
    LinkedNodeBuilder forPartsWithDeclarations_variables,
    int forParts_rightSeparator,
    List<LinkedNodeBuilder> forParts_updaters,
  })  : _kind = idl.LinkedNodeKind.forPartsWithDeclarations,
        _variantField_6 = forParts_condition,
        _variantField_15 = forParts_leftSeparator,
        _variantField_7 = forPartsWithDeclarations_variables,
        _variantField_16 = forParts_rightSeparator,
        _variantField_5 = forParts_updaters;

  LinkedNodeBuilder.forPartsWithExpression({
    LinkedNodeBuilder forParts_condition,
    int forParts_leftSeparator,
    LinkedNodeBuilder forPartsWithExpression_initialization,
    int forParts_rightSeparator,
    List<LinkedNodeBuilder> forParts_updaters,
  })  : _kind = idl.LinkedNodeKind.forPartsWithExpression,
        _variantField_6 = forParts_condition,
        _variantField_15 = forParts_leftSeparator,
        _variantField_7 = forPartsWithExpression_initialization,
        _variantField_16 = forParts_rightSeparator,
        _variantField_5 = forParts_updaters;

  LinkedNodeBuilder.functionDeclarationStatement({
    LinkedNodeBuilder functionDeclarationStatement_functionDeclaration,
  })  : _kind = idl.LinkedNodeKind.functionDeclarationStatement,
        _variantField_6 = functionDeclarationStatement_functionDeclaration;

  LinkedNodeBuilder.ifElement({
    LinkedNodeBuilder ifMixin_condition,
    int ifMixin_elseKeyword,
    int ifMixin_leftParenthesis,
    LinkedNodeBuilder ifElement_thenElement,
    int ifMixin_ifKeyword,
    int ifMixin_rightParenthesis,
    LinkedNodeBuilder ifElement_elseElement,
  })  : _kind = idl.LinkedNodeKind.ifElement,
        _variantField_6 = ifMixin_condition,
        _variantField_15 = ifMixin_elseKeyword,
        _variantField_17 = ifMixin_leftParenthesis,
        _variantField_8 = ifElement_thenElement,
        _variantField_16 = ifMixin_ifKeyword,
        _variantField_18 = ifMixin_rightParenthesis,
        _variantField_9 = ifElement_elseElement;

  LinkedNodeBuilder.ifStatement({
    LinkedNodeBuilder ifMixin_condition,
    int ifMixin_elseKeyword,
    LinkedNodeBuilder ifStatement_elseStatement,
    int ifMixin_leftParenthesis,
    LinkedNodeBuilder ifStatement_thenStatement,
    int ifMixin_ifKeyword,
    int ifMixin_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.ifStatement,
        _variantField_6 = ifMixin_condition,
        _variantField_15 = ifMixin_elseKeyword,
        _variantField_7 = ifStatement_elseStatement,
        _variantField_17 = ifMixin_leftParenthesis,
        _variantField_8 = ifStatement_thenStatement,
        _variantField_16 = ifMixin_ifKeyword,
        _variantField_18 = ifMixin_rightParenthesis;

  LinkedNodeBuilder.indexExpression({
    LinkedNodeBuilder indexExpression_index,
    int indexExpression_element,
    LinkedNodeBuilder indexExpression_target,
    int indexExpression_leftBracket,
    LinkedNodeTypeBuilder indexExpression_elementType,
    int indexExpression_period,
    int indexExpression_rightBracket,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.indexExpression,
        _variantField_6 = indexExpression_index,
        _variantField_15 = indexExpression_element,
        _variantField_7 = indexExpression_target,
        _variantField_17 = indexExpression_leftBracket,
        _variantField_23 = indexExpression_elementType,
        _variantField_16 = indexExpression_period,
        _variantField_18 = indexExpression_rightBracket,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.instanceCreationExpression({
    LinkedNodeBuilder instanceCreationExpression_arguments,
    int instanceCreationExpression_keyword,
    LinkedNodeBuilder instanceCreationExpression_constructorName,
    LinkedNodeBuilder instanceCreationExpression_typeArguments,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.instanceCreationExpression,
        _variantField_6 = instanceCreationExpression_arguments,
        _variantField_15 = instanceCreationExpression_keyword,
        _variantField_7 = instanceCreationExpression_constructorName,
        _variantField_8 = instanceCreationExpression_typeArguments,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.interpolationExpression({
    LinkedNodeBuilder interpolationExpression_expression,
    int interpolationExpression_leftBracket,
    int interpolationExpression_rightBracket,
  })  : _kind = idl.LinkedNodeKind.interpolationExpression,
        _variantField_6 = interpolationExpression_expression,
        _variantField_15 = interpolationExpression_leftBracket,
        _variantField_16 = interpolationExpression_rightBracket;

  LinkedNodeBuilder.isExpression({
    LinkedNodeBuilder isExpression_expression,
    int isExpression_isOperator,
    LinkedNodeBuilder isExpression_type,
    int isExpression_notOperator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.isExpression,
        _variantField_6 = isExpression_expression,
        _variantField_15 = isExpression_isOperator,
        _variantField_7 = isExpression_type,
        _variantField_16 = isExpression_notOperator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.label({
    LinkedNodeBuilder label_label,
    int label_colon,
  })  : _kind = idl.LinkedNodeKind.label,
        _variantField_6 = label_label,
        _variantField_15 = label_colon;

  LinkedNodeBuilder.mapLiteralEntry({
    LinkedNodeBuilder mapLiteralEntry_key,
    int mapLiteralEntry_separator,
    LinkedNodeBuilder mapLiteralEntry_value,
  })  : _kind = idl.LinkedNodeKind.mapLiteralEntry,
        _variantField_6 = mapLiteralEntry_key,
        _variantField_15 = mapLiteralEntry_separator,
        _variantField_7 = mapLiteralEntry_value;

  LinkedNodeBuilder.namedExpression({
    LinkedNodeBuilder namedExpression_expression,
    LinkedNodeBuilder namedExpression_name,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.namedExpression,
        _variantField_6 = namedExpression_expression,
        _variantField_7 = namedExpression_name,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.nativeClause({
    LinkedNodeBuilder nativeClause_name,
    int nativeClause_nativeKeyword,
  })  : _kind = idl.LinkedNodeKind.nativeClause,
        _variantField_6 = nativeClause_name,
        _variantField_15 = nativeClause_nativeKeyword;

  LinkedNodeBuilder.nativeFunctionBody({
    LinkedNodeBuilder nativeFunctionBody_stringLiteral,
    int nativeFunctionBody_nativeKeyword,
    int nativeFunctionBody_semicolon,
  })  : _kind = idl.LinkedNodeKind.nativeFunctionBody,
        _variantField_6 = nativeFunctionBody_stringLiteral,
        _variantField_15 = nativeFunctionBody_nativeKeyword,
        _variantField_16 = nativeFunctionBody_semicolon;

  LinkedNodeBuilder.parenthesizedExpression({
    LinkedNodeBuilder parenthesizedExpression_expression,
    int parenthesizedExpression_leftParenthesis,
    int parenthesizedExpression_rightParenthesis,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.parenthesizedExpression,
        _variantField_6 = parenthesizedExpression_expression,
        _variantField_15 = parenthesizedExpression_leftParenthesis,
        _variantField_16 = parenthesizedExpression_rightParenthesis,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.postfixExpression({
    LinkedNodeBuilder postfixExpression_operand,
    int postfixExpression_element,
    LinkedNodeTypeBuilder postfixExpression_elementType,
    int postfixExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.postfixExpression,
        _variantField_6 = postfixExpression_operand,
        _variantField_15 = postfixExpression_element,
        _variantField_23 = postfixExpression_elementType,
        _variantField_16 = postfixExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.prefixedIdentifier({
    LinkedNodeBuilder prefixedIdentifier_identifier,
    int prefixedIdentifier_period,
    LinkedNodeBuilder prefixedIdentifier_prefix,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.prefixedIdentifier,
        _variantField_6 = prefixedIdentifier_identifier,
        _variantField_15 = prefixedIdentifier_period,
        _variantField_7 = prefixedIdentifier_prefix,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.prefixExpression({
    LinkedNodeBuilder prefixExpression_operand,
    int prefixExpression_element,
    LinkedNodeTypeBuilder prefixExpression_elementType,
    int prefixExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.prefixExpression,
        _variantField_6 = prefixExpression_operand,
        _variantField_15 = prefixExpression_element,
        _variantField_23 = prefixExpression_elementType,
        _variantField_16 = prefixExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.propertyAccess({
    LinkedNodeBuilder propertyAccess_propertyName,
    int propertyAccess_operator,
    LinkedNodeBuilder propertyAccess_target,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.propertyAccess,
        _variantField_6 = propertyAccess_propertyName,
        _variantField_15 = propertyAccess_operator,
        _variantField_7 = propertyAccess_target,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.redirectingConstructorInvocation({
    LinkedNodeBuilder redirectingConstructorInvocation_arguments,
    int redirectingConstructorInvocation_element,
    LinkedNodeBuilder redirectingConstructorInvocation_constructorName,
    int redirectingConstructorInvocation_thisKeyword,
    LinkedNodeTypeBuilder redirectingConstructorInvocation_elementType,
    int redirectingConstructorInvocation_period,
  })  : _kind = idl.LinkedNodeKind.redirectingConstructorInvocation,
        _variantField_6 = redirectingConstructorInvocation_arguments,
        _variantField_15 = redirectingConstructorInvocation_element,
        _variantField_7 = redirectingConstructorInvocation_constructorName,
        _variantField_17 = redirectingConstructorInvocation_thisKeyword,
        _variantField_23 = redirectingConstructorInvocation_elementType,
        _variantField_16 = redirectingConstructorInvocation_period;

  LinkedNodeBuilder.returnStatement({
    LinkedNodeBuilder returnStatement_expression,
    int returnStatement_returnKeyword,
    int returnStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.returnStatement,
        _variantField_6 = returnStatement_expression,
        _variantField_15 = returnStatement_returnKeyword,
        _variantField_16 = returnStatement_semicolon;

  LinkedNodeBuilder.spreadElement({
    LinkedNodeBuilder spreadElement_expression,
    int spreadElement_spreadOperator,
  })  : _kind = idl.LinkedNodeKind.spreadElement,
        _variantField_6 = spreadElement_expression,
        _variantField_15 = spreadElement_spreadOperator;

  LinkedNodeBuilder.superConstructorInvocation({
    LinkedNodeBuilder superConstructorInvocation_arguments,
    int superConstructorInvocation_element,
    LinkedNodeBuilder superConstructorInvocation_constructorName,
    int superConstructorInvocation_superKeyword,
    LinkedNodeTypeBuilder superConstructorInvocation_elementType,
    int superConstructorInvocation_period,
  })  : _kind = idl.LinkedNodeKind.superConstructorInvocation,
        _variantField_6 = superConstructorInvocation_arguments,
        _variantField_15 = superConstructorInvocation_element,
        _variantField_7 = superConstructorInvocation_constructorName,
        _variantField_17 = superConstructorInvocation_superKeyword,
        _variantField_23 = superConstructorInvocation_elementType,
        _variantField_16 = superConstructorInvocation_period;

  LinkedNodeBuilder.throwExpression({
    LinkedNodeBuilder throwExpression_expression,
    int throwExpression_throwKeyword,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.throwExpression,
        _variantField_6 = throwExpression_expression,
        _variantField_15 = throwExpression_throwKeyword,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.typeName({
    LinkedNodeBuilder typeName_name,
    int typeName_question,
    LinkedNodeBuilder typeName_typeArguments,
    LinkedNodeTypeBuilder typeName_type,
  })  : _kind = idl.LinkedNodeKind.typeName,
        _variantField_6 = typeName_name,
        _variantField_15 = typeName_question,
        _variantField_7 = typeName_typeArguments,
        _variantField_23 = typeName_type;

  LinkedNodeBuilder.variableDeclarationStatement({
    LinkedNodeBuilder variableDeclarationStatement_variables,
    int variableDeclarationStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.variableDeclarationStatement,
        _variantField_6 = variableDeclarationStatement_variables,
        _variantField_15 = variableDeclarationStatement_semicolon;

  LinkedNodeBuilder.whileStatement({
    LinkedNodeBuilder whileStatement_body,
    int whileStatement_leftParenthesis,
    LinkedNodeBuilder whileStatement_condition,
    int whileStatement_whileKeyword,
    int whileStatement_rightParenthesis,
  })  : _kind = idl.LinkedNodeKind.whileStatement,
        _variantField_6 = whileStatement_body,
        _variantField_15 = whileStatement_leftParenthesis,
        _variantField_7 = whileStatement_condition,
        _variantField_17 = whileStatement_whileKeyword,
        _variantField_16 = whileStatement_rightParenthesis;

  LinkedNodeBuilder.yieldStatement({
    LinkedNodeBuilder yieldStatement_expression,
    int yieldStatement_yieldKeyword,
    int yieldStatement_semicolon,
    int yieldStatement_star,
  })  : _kind = idl.LinkedNodeKind.yieldStatement,
        _variantField_6 = yieldStatement_expression,
        _variantField_15 = yieldStatement_yieldKeyword,
        _variantField_17 = yieldStatement_semicolon,
        _variantField_16 = yieldStatement_star;

  LinkedNodeBuilder.booleanLiteral({
    int booleanLiteral_literal,
    bool booleanLiteral_value,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.booleanLiteral,
        _variantField_15 = booleanLiteral_literal,
        _variantField_27 = booleanLiteral_value,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.doubleLiteral({
    int doubleLiteral_literal,
    double doubleLiteral_value,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.doubleLiteral,
        _variantField_15 = doubleLiteral_literal,
        _variantField_21 = doubleLiteral_value,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.emptyFunctionBody({
    int emptyFunctionBody_semicolon,
  })  : _kind = idl.LinkedNodeKind.emptyFunctionBody,
        _variantField_15 = emptyFunctionBody_semicolon;

  LinkedNodeBuilder.emptyStatement({
    int emptyStatement_semicolon,
  })  : _kind = idl.LinkedNodeKind.emptyStatement,
        _variantField_15 = emptyStatement_semicolon;

  LinkedNodeBuilder.integerLiteral({
    int integerLiteral_literal,
    int integerLiteral_value,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.integerLiteral,
        _variantField_15 = integerLiteral_literal,
        _variantField_16 = integerLiteral_value,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.interpolationString({
    int interpolationString_token,
    String interpolationString_value,
  })  : _kind = idl.LinkedNodeKind.interpolationString,
        _variantField_15 = interpolationString_token,
        _variantField_30 = interpolationString_value;

  LinkedNodeBuilder.nullLiteral({
    int nullLiteral_literal,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.nullLiteral,
        _variantField_15 = nullLiteral_literal,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.rethrowExpression({
    int rethrowExpression_rethrowKeyword,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.rethrowExpression,
        _variantField_15 = rethrowExpression_rethrowKeyword,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.scriptTag({
    int scriptTag_scriptTag,
  })  : _kind = idl.LinkedNodeKind.scriptTag,
        _variantField_15 = scriptTag_scriptTag;

  LinkedNodeBuilder.simpleIdentifier({
    int simpleIdentifier_element,
    LinkedNodeTypeBuilder simpleIdentifier_elementType,
    int simpleIdentifier_token,
    bool simpleIdentifier_isDeclaration,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.simpleIdentifier,
        _variantField_15 = simpleIdentifier_element,
        _variantField_23 = simpleIdentifier_elementType,
        _variantField_16 = simpleIdentifier_token,
        _variantField_27 = simpleIdentifier_isDeclaration,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.simpleStringLiteral({
    int simpleStringLiteral_token,
    LinkedNodeTypeBuilder expression_type,
    String simpleStringLiteral_value,
  })  : _kind = idl.LinkedNodeKind.simpleStringLiteral,
        _variantField_15 = simpleStringLiteral_token,
        _variantField_25 = expression_type,
        _variantField_20 = simpleStringLiteral_value;

  LinkedNodeBuilder.superExpression({
    int superExpression_superKeyword,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.superExpression,
        _variantField_15 = superExpression_superKeyword,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.symbolLiteral({
    int symbolLiteral_poundSign,
    List<int> symbolLiteral_components,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.symbolLiteral,
        _variantField_15 = symbolLiteral_poundSign,
        _variantField_28 = symbolLiteral_components,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.thisExpression({
    int thisExpression_thisKeyword,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.thisExpression,
        _variantField_15 = thisExpression_thisKeyword,
        _variantField_25 = expression_type;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _variantField_24?.flushInformative();
    _variantField_2?.forEach((b) => b.flushInformative());
    _variantField_11?.flushInformative();
    _variantField_4?.forEach((b) => b.flushInformative());
    _variantField_6?.flushInformative();
    _variantField_7?.flushInformative();
    _variantField_23?.flushInformative();
    _variantField_8?.flushInformative();
    _variantField_9?.flushInformative();
    _variantField_12?.flushInformative();
    _variantField_5?.forEach((b) => b.flushInformative());
    _variantField_13?.flushInformative();
    _variantField_3?.forEach((b) => b.flushInformative());
    _variantField_10?.flushInformative();
    _variantField_25?.flushInformative();
    _variantField_14?.flushInformative();
    _variantField_35?.flushInformative();
    _variantField_32?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addBool(this._isSynthetic == true);
    if (this._variantField_2 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_2.length);
      for (var x in this._variantField_2) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._variantField_3 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_3.length);
      for (var x in this._variantField_3) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._variantField_4 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_4.length);
      for (var x in this._variantField_4) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._variantField_5 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_5.length);
      for (var x in this._variantField_5) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._variantField_6 != null);
    this._variantField_6?.collectApiSignature(signature);
    signature.addBool(this._variantField_7 != null);
    this._variantField_7?.collectApiSignature(signature);
    signature.addBool(this._variantField_8 != null);
    this._variantField_8?.collectApiSignature(signature);
    signature.addBool(this._variantField_9 != null);
    this._variantField_9?.collectApiSignature(signature);
    signature.addBool(this._variantField_10 != null);
    this._variantField_10?.collectApiSignature(signature);
    signature.addBool(this._variantField_11 != null);
    this._variantField_11?.collectApiSignature(signature);
    signature.addBool(this._variantField_12 != null);
    this._variantField_12?.collectApiSignature(signature);
    signature.addBool(this._variantField_13 != null);
    this._variantField_13?.collectApiSignature(signature);
    signature.addBool(this._variantField_14 != null);
    this._variantField_14?.collectApiSignature(signature);
    signature.addInt(this._variantField_15 ?? 0);
    signature.addInt(this._variantField_16 ?? 0);
    signature.addInt(this._variantField_17 ?? 0);
    signature.addInt(this._variantField_18 ?? 0);
    signature.addInt(this._variantField_19 ?? 0);
    signature.addString(this._variantField_20 ?? '');
    signature.addDouble(this._variantField_21 ?? 0.0);
    signature.addString(this._variantField_22 ?? '');
    signature.addBool(this._variantField_23 != null);
    this._variantField_23?.collectApiSignature(signature);
    signature.addBool(this._variantField_24 != null);
    this._variantField_24?.collectApiSignature(signature);
    signature.addBool(this._variantField_25 != null);
    this._variantField_25?.collectApiSignature(signature);
    signature.addInt(
        this._variantField_26 == null ? 0 : this._variantField_26.index);
    signature.addBool(this._variantField_27 == true);
    if (this._variantField_28 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_28.length);
      for (var x in this._variantField_28) {
        signature.addInt(x);
      }
    }
    signature.addInt(
        this._variantField_29 == null ? 0 : this._variantField_29.index);
    signature.addString(this._variantField_30 ?? '');
    signature.addBool(this._variantField_31 == true);
    signature.addBool(this._variantField_32 != null);
    this._variantField_32?.collectApiSignature(signature);
    signature.addInt(this._variantField_33 ?? 0);
    signature.addInt(this._variantField_34 ?? 0);
    signature.addBool(this._variantField_35 != null);
    this._variantField_35?.collectApiSignature(signature);
    if (this._variantField_36 == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variantField_36.length);
      for (var x in this._variantField_36) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_variantField_24;
    fb.Offset offset_variantField_2;
    fb.Offset offset_variantField_11;
    fb.Offset offset_variantField_4;
    fb.Offset offset_variantField_6;
    fb.Offset offset_variantField_7;
    fb.Offset offset_variantField_23;
    fb.Offset offset_variantField_8;
    fb.Offset offset_variantField_9;
    fb.Offset offset_variantField_12;
    fb.Offset offset_variantField_5;
    fb.Offset offset_variantField_13;
    fb.Offset offset_variantField_28;
    fb.Offset offset_variantField_3;
    fb.Offset offset_variantField_10;
    fb.Offset offset_variantField_25;
    fb.Offset offset_variantField_30;
    fb.Offset offset_variantField_14;
    fb.Offset offset_variantField_36;
    fb.Offset offset_variantField_20;
    fb.Offset offset_variantField_35;
    fb.Offset offset_variantField_22;
    fb.Offset offset_variantField_32;
    if (_variantField_24 != null) {
      offset_variantField_24 = _variantField_24.finish(fbBuilder);
    }
    if (!(_variantField_2 == null || _variantField_2.isEmpty)) {
      offset_variantField_2 = fbBuilder
          .writeList(_variantField_2.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_11 != null) {
      offset_variantField_11 = _variantField_11.finish(fbBuilder);
    }
    if (!(_variantField_4 == null || _variantField_4.isEmpty)) {
      offset_variantField_4 = fbBuilder
          .writeList(_variantField_4.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_6 != null) {
      offset_variantField_6 = _variantField_6.finish(fbBuilder);
    }
    if (_variantField_7 != null) {
      offset_variantField_7 = _variantField_7.finish(fbBuilder);
    }
    if (_variantField_23 != null) {
      offset_variantField_23 = _variantField_23.finish(fbBuilder);
    }
    if (_variantField_8 != null) {
      offset_variantField_8 = _variantField_8.finish(fbBuilder);
    }
    if (_variantField_9 != null) {
      offset_variantField_9 = _variantField_9.finish(fbBuilder);
    }
    if (_variantField_12 != null) {
      offset_variantField_12 = _variantField_12.finish(fbBuilder);
    }
    if (!(_variantField_5 == null || _variantField_5.isEmpty)) {
      offset_variantField_5 = fbBuilder
          .writeList(_variantField_5.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_13 != null) {
      offset_variantField_13 = _variantField_13.finish(fbBuilder);
    }
    if (!(_variantField_28 == null || _variantField_28.isEmpty)) {
      offset_variantField_28 = fbBuilder.writeListUint32(_variantField_28);
    }
    if (!(_variantField_3 == null || _variantField_3.isEmpty)) {
      offset_variantField_3 = fbBuilder
          .writeList(_variantField_3.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_10 != null) {
      offset_variantField_10 = _variantField_10.finish(fbBuilder);
    }
    if (_variantField_25 != null) {
      offset_variantField_25 = _variantField_25.finish(fbBuilder);
    }
    if (_variantField_30 != null) {
      offset_variantField_30 = fbBuilder.writeString(_variantField_30);
    }
    if (_variantField_14 != null) {
      offset_variantField_14 = _variantField_14.finish(fbBuilder);
    }
    if (!(_variantField_36 == null || _variantField_36.isEmpty)) {
      offset_variantField_36 = fbBuilder.writeList(
          _variantField_36.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_variantField_20 != null) {
      offset_variantField_20 = fbBuilder.writeString(_variantField_20);
    }
    if (_variantField_35 != null) {
      offset_variantField_35 = _variantField_35.finish(fbBuilder);
    }
    if (_variantField_22 != null) {
      offset_variantField_22 = fbBuilder.writeString(_variantField_22);
    }
    if (_variantField_32 != null) {
      offset_variantField_32 = _variantField_32.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_variantField_24 != null) {
      fbBuilder.addOffset(24, offset_variantField_24);
    }
    if (offset_variantField_2 != null) {
      fbBuilder.addOffset(2, offset_variantField_2);
    }
    if (offset_variantField_11 != null) {
      fbBuilder.addOffset(11, offset_variantField_11);
    }
    if (offset_variantField_4 != null) {
      fbBuilder.addOffset(4, offset_variantField_4);
    }
    if (offset_variantField_6 != null) {
      fbBuilder.addOffset(6, offset_variantField_6);
    }
    if (_variantField_15 != null && _variantField_15 != 0) {
      fbBuilder.addUint32(15, _variantField_15);
    }
    if (offset_variantField_7 != null) {
      fbBuilder.addOffset(7, offset_variantField_7);
    }
    if (_variantField_17 != null && _variantField_17 != 0) {
      fbBuilder.addUint32(17, _variantField_17);
    }
    if (offset_variantField_23 != null) {
      fbBuilder.addOffset(23, offset_variantField_23);
    }
    if (offset_variantField_8 != null) {
      fbBuilder.addOffset(8, offset_variantField_8);
    }
    if (_variantField_16 != null && _variantField_16 != 0) {
      fbBuilder.addUint32(16, _variantField_16);
    }
    if (_variantField_18 != null && _variantField_18 != 0) {
      fbBuilder.addUint32(18, _variantField_18);
    }
    if (_variantField_19 != null && _variantField_19 != 0) {
      fbBuilder.addUint32(19, _variantField_19);
    }
    if (_variantField_27 == true) {
      fbBuilder.addBool(27, true);
    }
    if (offset_variantField_9 != null) {
      fbBuilder.addOffset(9, offset_variantField_9);
    }
    if (offset_variantField_12 != null) {
      fbBuilder.addOffset(12, offset_variantField_12);
    }
    if (offset_variantField_5 != null) {
      fbBuilder.addOffset(5, offset_variantField_5);
    }
    if (offset_variantField_13 != null) {
      fbBuilder.addOffset(13, offset_variantField_13);
    }
    if (_variantField_34 != null && _variantField_34 != 0) {
      fbBuilder.addUint32(34, _variantField_34);
    }
    if (_variantField_33 != null && _variantField_33 != 0) {
      fbBuilder.addUint32(33, _variantField_33);
    }
    if (offset_variantField_28 != null) {
      fbBuilder.addOffset(28, offset_variantField_28);
    }
    if (_variantField_29 != null &&
        _variantField_29 != idl.LinkedNodeCommentType.block) {
      fbBuilder.addUint8(29, _variantField_29.index);
    }
    if (offset_variantField_3 != null) {
      fbBuilder.addOffset(3, offset_variantField_3);
    }
    if (offset_variantField_10 != null) {
      fbBuilder.addOffset(10, offset_variantField_10);
    }
    if (_variantField_26 != null &&
        _variantField_26 !=
            idl.LinkedNodeFormalParameterKind.requiredPositional) {
      fbBuilder.addUint8(26, _variantField_26.index);
    }
    if (_variantField_21 != null && _variantField_21 != 0.0) {
      fbBuilder.addFloat64(21, _variantField_21);
    }
    if (offset_variantField_25 != null) {
      fbBuilder.addOffset(25, offset_variantField_25);
    }
    if (offset_variantField_30 != null) {
      fbBuilder.addOffset(30, offset_variantField_30);
    }
    if (offset_variantField_14 != null) {
      fbBuilder.addOffset(14, offset_variantField_14);
    }
    if (_isSynthetic == true) {
      fbBuilder.addBool(1, true);
    }
    if (_kind != null && _kind != idl.LinkedNodeKind.adjacentStrings) {
      fbBuilder.addUint8(0, _kind.index);
    }
    if (offset_variantField_36 != null) {
      fbBuilder.addOffset(36, offset_variantField_36);
    }
    if (offset_variantField_20 != null) {
      fbBuilder.addOffset(20, offset_variantField_20);
    }
    if (_variantField_31 == true) {
      fbBuilder.addBool(31, true);
    }
    if (offset_variantField_35 != null) {
      fbBuilder.addOffset(35, offset_variantField_35);
    }
    if (offset_variantField_22 != null) {
      fbBuilder.addOffset(22, offset_variantField_22);
    }
    if (offset_variantField_32 != null) {
      fbBuilder.addOffset(32, offset_variantField_32);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeReader extends fb.TableReader<_LinkedNodeImpl> {
  const _LinkedNodeReader();

  @override
  _LinkedNodeImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeImpl(bc, offset);
}

class _LinkedNodeImpl extends Object
    with _LinkedNodeMixin
    implements idl.LinkedNode {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeImpl(this._bc, this._bcOffset);

  idl.LinkedNodeType _variantField_24;
  List<idl.LinkedNode> _variantField_2;
  idl.LinkedNode _variantField_11;
  List<idl.LinkedNode> _variantField_4;
  idl.LinkedNode _variantField_6;
  int _variantField_15;
  idl.LinkedNode _variantField_7;
  int _variantField_17;
  idl.LinkedNodeType _variantField_23;
  idl.LinkedNode _variantField_8;
  int _variantField_16;
  int _variantField_18;
  int _variantField_19;
  bool _variantField_27;
  idl.LinkedNode _variantField_9;
  idl.LinkedNode _variantField_12;
  List<idl.LinkedNode> _variantField_5;
  idl.LinkedNode _variantField_13;
  int _variantField_34;
  int _variantField_33;
  List<int> _variantField_28;
  idl.LinkedNodeCommentType _variantField_29;
  List<idl.LinkedNode> _variantField_3;
  idl.LinkedNode _variantField_10;
  idl.LinkedNodeFormalParameterKind _variantField_26;
  double _variantField_21;
  idl.LinkedNodeType _variantField_25;
  String _variantField_30;
  idl.LinkedNode _variantField_14;
  bool _isSynthetic;
  idl.LinkedNodeKind _kind;
  List<String> _variantField_36;
  String _variantField_20;
  bool _variantField_31;
  idl.TopLevelInferenceError _variantField_35;
  String _variantField_22;
  idl.LinkedNodeVariablesDeclaration _variantField_32;

  @override
  idl.LinkedNodeType get actualReturnType {
    assert(kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionExpression ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericFunctionType ||
        kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_24 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 24, null);
    return _variantField_24;
  }

  @override
  idl.LinkedNodeType get actualType {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_24 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 24, null);
    return _variantField_24;
  }

  @override
  idl.LinkedNodeType get binaryExpression_invokeType {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_24 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 24, null);
    return _variantField_24;
  }

  @override
  idl.LinkedNodeType get invocationExpression_invokeType {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_24 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 24, null);
    return _variantField_24;
  }

  @override
  List<idl.LinkedNode> get adjacentStrings_strings {
    assert(kind == idl.LinkedNodeKind.adjacentStrings);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get argumentList_arguments {
    assert(kind == idl.LinkedNodeKind.argumentList);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get block_statements {
    assert(kind == idl.LinkedNodeKind.block);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get cascadeExpression_sections {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get comment_references {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get compilationUnit_declarations {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get constructorDeclaration_initializers {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get dottedName_components {
    assert(kind == idl.LinkedNodeKind.dottedName);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get enumDeclaration_constants {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get formalParameterList_parameters {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get hideCombinator_hiddenNames {
    assert(kind == idl.LinkedNodeKind.hideCombinator);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get implementsClause_interfaces {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get labeledStatement_labels {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get libraryIdentifier_components {
    assert(kind == idl.LinkedNodeKind.libraryIdentifier);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get listLiteral_elements {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get namespaceDirective_combinators {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get onClause_superclassConstraints {
    assert(kind == idl.LinkedNodeKind.onClause);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get setOrMapLiteral_elements {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get showCombinator_shownNames {
    assert(kind == idl.LinkedNodeKind.showCombinator);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get stringInterpolation_elements {
    assert(kind == idl.LinkedNodeKind.stringInterpolation);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get switchStatement_members {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get tryStatement_catchClauses {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typeArgumentList_arguments {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typeParameterList_typeParameters {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get variableDeclarationList_variables {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get withClause_mixinTypes {
    assert(kind == idl.LinkedNodeKind.withClause);
    _variantField_2 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  idl.LinkedNode get annotatedNode_comment {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_11 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 11, null);
    return _variantField_11;
  }

  @override
  List<idl.LinkedNode> get annotatedNode_metadata {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_4 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNode>[]);
    return _variantField_4;
  }

  @override
  List<idl.LinkedNode> get normalFormalParameter_metadata {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_4 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNode>[]);
    return _variantField_4;
  }

  @override
  List<idl.LinkedNode> get switchMember_statements {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_4 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNode>[]);
    return _variantField_4;
  }

  @override
  idl.LinkedNode get annotation_arguments {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get asExpression_expression {
    assert(kind == idl.LinkedNodeKind.asExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get assertInitializer_condition {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get assertStatement_condition {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get assignmentExpression_leftHandSide {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get awaitExpression_expression {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get binaryExpression_leftOperand {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get blockFunctionBody_block {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get breakStatement_label {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get cascadeExpression_target {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get catchClause_body {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get classDeclaration_extendsClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get classTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get commentReference_identifier {
    assert(kind == idl.LinkedNodeKind.commentReference);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get compilationUnit_scriptTag {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get conditionalExpression_condition {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get configuration_name {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get constructorDeclaration_body {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get constructorFieldInitializer_expression {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get constructorName_name {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get continueStatement_label {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get declaredIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get defaultFormalParameter_defaultValue {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get doStatement_body {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get enumConstantDeclaration_name {
    assert(kind == idl.LinkedNodeKind.enumConstantDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get expressionFunctionBody_expression {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get expressionStatement_expression {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get extendsClause_superclass {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get fieldDeclaration_fields {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get fieldFormalParameter_type {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get forEachParts_iterable {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get forMixin_forLoopParts {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get forParts_condition {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionDeclaration_functionExpression {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionDeclarationStatement_functionDeclaration {
    assert(kind == idl.LinkedNodeKind.functionDeclarationStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionExpression_body {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionExpressionInvocation_function {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionTypeAlias_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get functionTypedFormalParameter_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get genericFunctionType_typeParameters {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get genericTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get ifMixin_condition {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get importDirective_prefix {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get indexExpression_index {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get instanceCreationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get interpolationExpression_expression {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get isExpression_expression {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get label_label {
    assert(kind == idl.LinkedNodeKind.label);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get labeledStatement_statement {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get libraryDirective_name {
    assert(kind == idl.LinkedNodeKind.libraryDirective);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get mapLiteralEntry_key {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get methodDeclaration_body {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get methodInvocation_methodName {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get mixinDeclaration_onClause {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get namedExpression_expression {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get nativeClause_name {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get nativeFunctionBody_stringLiteral {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get parenthesizedExpression_expression {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get partOfDirective_libraryName {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get postfixExpression_operand {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get prefixedIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get prefixExpression_operand {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get propertyAccess_propertyName {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get redirectingConstructorInvocation_arguments {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get returnStatement_expression {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get simpleFormalParameter_type {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get spreadElement_expression {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get superConstructorInvocation_arguments {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get switchCase_expression {
    assert(kind == idl.LinkedNodeKind.switchCase);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get throwExpression_expression {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get topLevelVariableDeclaration_variableList {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get tryStatement_body {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get typeName_name {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get typeParameter_bound {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get variableDeclaration_initializer {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get variableDeclarationList_type {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get variableDeclarationStatement_variables {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get whileStatement_body {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  idl.LinkedNode get yieldStatement_expression {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    _variantField_6 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 6, null);
    return _variantField_6;
  }

  @override
  int get annotation_atSign {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get argumentList_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.argumentList);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get asExpression_asOperator {
    assert(kind == idl.LinkedNodeKind.asExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get assertInitializer_assertKeyword {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get assertStatement_assertKeyword {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get assignmentExpression_element {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get awaitExpression_awaitKeyword {
    assert(kind == idl.LinkedNodeKind.awaitExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get binaryExpression_element {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get block_leftBracket {
    assert(kind == idl.LinkedNodeKind.block);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get blockFunctionBody_keyword {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get booleanLiteral_literal {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get breakStatement_breakKeyword {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get catchClause_catchKeyword {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get classDeclaration_abstractKeyword {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get classTypeAlias_abstractKeyword {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get commentReference_newKeyword {
    assert(kind == idl.LinkedNodeKind.commentReference);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get compilationUnit_beginToken {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get conditionalExpression_colon {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get configuration_ifKeyword {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get constructorDeclaration_constKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get constructorFieldInitializer_equals {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get constructorName_element {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get continueStatement_continueKeyword {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get declaredIdentifier_keyword {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get defaultFormalParameter_separator {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get doStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get doubleLiteral_literal {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get emptyFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get emptyStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get enumDeclaration_enumKeyword {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get expressionFunctionBody_arrow {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get expressionStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.expressionStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get extendsClause_extendsKeyword {
    assert(kind == idl.LinkedNodeKind.extendsClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get fieldDeclaration_covariantKeyword {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get fieldFormalParameter_keyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get forEachParts_inKeyword {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration ||
        kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get formalParameterList_leftDelimiter {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get forMixin_awaitKeyword {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get forParts_leftSeparator {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get functionDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get genericFunctionType_functionKeyword {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get ifMixin_elseKeyword {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get implementsClause_implementsKeyword {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get importDirective_asKeyword {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get indexExpression_element {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get instanceCreationExpression_keyword {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get integerLiteral_literal {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get interpolationExpression_leftBracket {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get interpolationString_token {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get isExpression_isOperator {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get label_colon {
    assert(kind == idl.LinkedNodeKind.label);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get listLiteral_leftBracket {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get mapLiteralEntry_separator {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get methodDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get methodInvocation_operator {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get mixinDeclaration_mixinKeyword {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get nativeClause_nativeKeyword {
    assert(kind == idl.LinkedNodeKind.nativeClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get nativeFunctionBody_nativeKeyword {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get nullLiteral_literal {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get onClause_onKeyword {
    assert(kind == idl.LinkedNodeKind.onClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get parenthesizedExpression_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get postfixExpression_element {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get prefixedIdentifier_period {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get prefixExpression_element {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get propertyAccess_operator {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get redirectingConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get rethrowExpression_rethrowKeyword {
    assert(kind == idl.LinkedNodeKind.rethrowExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get returnStatement_returnKeyword {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get scriptTag_scriptTag {
    assert(kind == idl.LinkedNodeKind.scriptTag);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get setOrMapLiteral_leftBracket {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get simpleFormalParameter_keyword {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get simpleIdentifier_element {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get simpleStringLiteral_token {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get spreadElement_spreadOperator {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get superConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get superExpression_superKeyword {
    assert(kind == idl.LinkedNodeKind.superExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get switchMember_keyword {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get switchStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get symbolLiteral_poundSign {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get thisExpression_thisKeyword {
    assert(kind == idl.LinkedNodeKind.thisExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get throwExpression_throwKeyword {
    assert(kind == idl.LinkedNodeKind.throwExpression);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get topLevelVariableDeclaration_semicolon {
    assert(kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get tryStatement_finallyKeyword {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get typeArgumentList_leftBracket {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get typeName_question {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get typeParameter_extendsKeyword {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get typeParameterList_leftBracket {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get variableDeclaration_equals {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get variableDeclarationList_keyword {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get variableDeclarationStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.variableDeclarationStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get whileStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get withClause_withKeyword {
    assert(kind == idl.LinkedNodeKind.withClause);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get yieldStatement_yieldKeyword {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  idl.LinkedNode get annotation_constructorName {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get asExpression_type {
    assert(kind == idl.LinkedNodeKind.asExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get assertInitializer_message {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get assertStatement_message {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get assignmentExpression_rightHandSide {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get binaryExpression_rightOperand {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get catchClause_exceptionParameter {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get classDeclaration_withClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get classTypeAlias_superclass {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get conditionalExpression_elseExpression {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get configuration_value {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get constructorDeclaration_name {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get constructorFieldInitializer_fieldName {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get constructorName_type {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get declaredIdentifier_type {
    assert(kind == idl.LinkedNodeKind.declaredIdentifier);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get defaultFormalParameter_parameter {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get doStatement_condition {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get fieldFormalParameter_typeParameters {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forEachPartsWithDeclaration_loopVariable {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forEachPartsWithIdentifier_identifier {
    assert(kind == idl.LinkedNodeKind.forEachPartsWithIdentifier);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forElement_body {
    assert(kind == idl.LinkedNodeKind.forElement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forPartsWithDeclarations_variables {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forPartsWithExpression_initialization {
    assert(kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get forStatement_body {
    assert(kind == idl.LinkedNodeKind.forStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get functionDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get functionExpression_formalParameters {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get functionTypeAlias_returnType {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get functionTypedFormalParameter_returnType {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get genericFunctionType_returnType {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get genericTypeAlias_functionType {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get ifStatement_elseStatement {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get indexExpression_target {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get instanceCreationExpression_constructorName {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get isExpression_type {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get mapLiteralEntry_value {
    assert(kind == idl.LinkedNodeKind.mapLiteralEntry);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get methodDeclaration_formalParameters {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get methodInvocation_target {
    assert(kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get namedExpression_name {
    assert(kind == idl.LinkedNodeKind.namedExpression);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get partOfDirective_uri {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get prefixedIdentifier_prefix {
    assert(kind == idl.LinkedNodeKind.prefixedIdentifier);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get propertyAccess_target {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get redirectingConstructorInvocation_constructorName {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get superConstructorInvocation_constructorName {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get switchStatement_expression {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get tryStatement_finallyBlock {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get typeName_typeArguments {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get typeParameter_name {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get variableDeclaration_name {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get whileStatement_condition {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  int get annotation_element {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get assertInitializer_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get assertStatement_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get catchClause_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get configuration_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get constructorDeclaration_factoryKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get constructorFieldInitializer_thisKeyword {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get doStatement_doKeyword {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get enumDeclaration_rightBracket {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get expressionFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get fieldDeclaration_staticKeyword {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get fieldFormalParameter_thisKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get formalParameterList_rightDelimiter {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get forMixin_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get genericFunctionType_id {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get ifMixin_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get indexExpression_leftBracket {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get methodDeclaration_operatorKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get redirectingConstructorInvocation_thisKeyword {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get superConstructorInvocation_superKeyword {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get switchStatement_switchKeyword {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get whileStatement_whileKeyword {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  int get yieldStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
  }

  @override
  idl.LinkedNodeType get annotation_elementType {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get assignmentExpression_elementType {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get binaryExpression_elementType {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get constructorName_elementType {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get indexExpression_elementType {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get postfixExpression_elementType {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get prefixExpression_elementType {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get redirectingConstructorInvocation_elementType {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get simpleIdentifier_elementType {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get superConstructorInvocation_elementType {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get typeName_type {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNodeType get typeParameter_defaultType {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_23 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 23, null);
    return _variantField_23;
  }

  @override
  idl.LinkedNode get annotation_name {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get catchClause_exceptionType {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get classDeclaration_nativeClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get classTypeAlias_withClause {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get conditionalExpression_thenExpression {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get configuration_uri {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get constructorDeclaration_parameters {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get fieldFormalParameter_formalParameters {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get functionExpression_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionExpression);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get functionTypeAlias_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get functionTypedFormalParameter_typeParameters {
    assert(kind == idl.LinkedNodeKind.functionTypedFormalParameter);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get genericFunctionType_formalParameters {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get ifElement_thenElement {
    assert(kind == idl.LinkedNodeKind.ifElement);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get ifStatement_thenStatement {
    assert(kind == idl.LinkedNodeKind.ifStatement);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get instanceCreationExpression_typeArguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  idl.LinkedNode get methodDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_8 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 8, null);
    return _variantField_8;
  }

  @override
  int get annotation_period {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get argumentList_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.argumentList);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get assertInitializer_comma {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get assertStatement_comma {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get assignmentExpression_operator {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get binaryExpression_operator {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get block_rightBracket {
    assert(kind == idl.LinkedNodeKind.block);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get blockFunctionBody_star {
    assert(kind == idl.LinkedNodeKind.blockFunctionBody);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get breakStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.breakStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get catchClause_comma {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get classDeclaration_classKeyword {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get classTypeAlias_equals {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get compilationUnit_endToken {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get conditionalExpression_question {
    assert(kind == idl.LinkedNodeKind.conditionalExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get configuration_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get constructorDeclaration_externalKeyword {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get constructorFieldInitializer_period {
    assert(kind == idl.LinkedNodeKind.constructorFieldInitializer);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get constructorName_period {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get continueStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.continueStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get doStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get enumDeclaration_leftBracket {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get expressionFunctionBody_keyword {
    assert(kind == idl.LinkedNodeKind.expressionFunctionBody);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get fieldDeclaration_semicolon {
    assert(kind == idl.LinkedNodeKind.fieldDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get fieldFormalParameter_period {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get formalParameterList_leftParenthesis {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get forMixin_forKeyword {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get forParts_rightSeparator {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get functionDeclaration_propertyKeyword {
    assert(kind == idl.LinkedNodeKind.functionDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get genericFunctionType_question {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get genericTypeAlias_equals {
    assert(kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get ifMixin_ifKeyword {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get importDirective_deferredKeyword {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get indexExpression_period {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get integerLiteral_value {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get interpolationExpression_rightBracket {
    assert(kind == idl.LinkedNodeKind.interpolationExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get isExpression_notOperator {
    assert(kind == idl.LinkedNodeKind.isExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get listLiteral_rightBracket {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get methodDeclaration_modifierKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get nativeFunctionBody_semicolon {
    assert(kind == idl.LinkedNodeKind.nativeFunctionBody);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get parenthesizedExpression_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.parenthesizedExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get partOfDirective_ofKeyword {
    assert(kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get postfixExpression_operator {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get prefixExpression_operator {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get redirectingConstructorInvocation_period {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get returnStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.returnStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get setOrMapLiteral_rightBracket {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get simpleIdentifier_token {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get superConstructorInvocation_period {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get switchMember_colon {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get switchStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get tryStatement_tryKeyword {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get typeArgumentList_rightBracket {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get typeParameterList_rightBracket {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get variableDeclarationList_lateKeyword {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get whileStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.whileStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get yieldStatement_star {
    assert(kind == idl.LinkedNodeKind.yieldStatement);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
  }

  @override
  int get assertInitializer_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.assertInitializer);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get assertStatement_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get catchClause_onKeyword {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get classOrMixinDeclaration_rightBracket {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get configuration_equalToken {
    assert(kind == idl.LinkedNodeKind.configuration);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get constructorDeclaration_period {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get directive_keyword {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get doStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get formalParameterList_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get ifMixin_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.ifElement ||
        kind == idl.LinkedNodeKind.ifStatement);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get indexExpression_rightBracket {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get methodDeclaration_propertyKeyword {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get normalFormalParameter_requiredKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get switchStatement_leftBracket {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get typeAlias_typedefKeyword {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_18 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _variantField_18;
  }

  @override
  int get assertStatement_semicolon {
    assert(kind == idl.LinkedNodeKind.assertStatement);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get catchClause_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get classOrMixinDeclaration_leftBracket {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get combinator_keyword {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get constructorDeclaration_separator {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get doStatement_whileKeyword {
    assert(kind == idl.LinkedNodeKind.doStatement);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get forMixin_rightParenthesis {
    assert(kind == idl.LinkedNodeKind.forElement ||
        kind == idl.LinkedNodeKind.forStatement);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get methodDeclaration_actualProperty {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get normalFormalParameter_covariantKeyword {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get switchStatement_rightBracket {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get typeAlias_semicolon {
    assert(kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get typedLiteral_constKeyword {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  int get uriBasedDirective_uriElement {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }

  @override
  bool get booleanLiteral_value {
    assert(kind == idl.LinkedNodeKind.booleanLiteral);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  bool get classDeclaration_isDartObject {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  bool get inheritsCovariant {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  bool get setOrMapLiteral_isMap {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  bool get simpleIdentifier_isDeclaration {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  bool get typeAlias_hasSelfReference {
    assert(kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias);
    _variantField_27 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _variantField_27;
  }

  @override
  idl.LinkedNode get catchClause_stackTraceParameter {
    assert(kind == idl.LinkedNodeKind.catchClause);
    _variantField_9 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 9, null);
    return _variantField_9;
  }

  @override
  idl.LinkedNode get classTypeAlias_implementsClause {
    assert(kind == idl.LinkedNodeKind.classTypeAlias);
    _variantField_9 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 9, null);
    return _variantField_9;
  }

  @override
  idl.LinkedNode get constructorDeclaration_redirectedConstructor {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_9 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 9, null);
    return _variantField_9;
  }

  @override
  idl.LinkedNode get ifElement_elseElement {
    assert(kind == idl.LinkedNodeKind.ifElement);
    _variantField_9 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 9, null);
    return _variantField_9;
  }

  @override
  idl.LinkedNode get methodDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_9 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 9, null);
    return _variantField_9;
  }

  @override
  idl.LinkedNode get classOrMixinDeclaration_implementsClause {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_12 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 12, null);
    return _variantField_12;
  }

  @override
  idl.LinkedNode get invocationExpression_typeArguments {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_12 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 12, null);
    return _variantField_12;
  }

  @override
  idl.LinkedNode get normalFormalParameter_identifier {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_12 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 12, null);
    return _variantField_12;
  }

  @override
  List<idl.LinkedNode> get classOrMixinDeclaration_members {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_5 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.LinkedNode>[]);
    return _variantField_5;
  }

  @override
  List<idl.LinkedNode> get forParts_updaters {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_5 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.LinkedNode>[]);
    return _variantField_5;
  }

  @override
  idl.LinkedNode get classOrMixinDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_13 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 13, null);
    return _variantField_13;
  }

  @override
  int get codeLength {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_34 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 34, 0);
    return _variantField_34;
  }

  @override
  int get codeOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_33 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 33, 0);
    return _variantField_33;
  }

  @override
  int get directive_semicolon {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_33 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 33, 0);
    return _variantField_33;
  }

  @override
  List<int> get comment_tokens {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_28 ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 28, const <int>[]);
    return _variantField_28;
  }

  @override
  List<int> get symbolLiteral_components {
    assert(kind == idl.LinkedNodeKind.symbolLiteral);
    _variantField_28 ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 28, const <int>[]);
    return _variantField_28;
  }

  @override
  idl.LinkedNodeCommentType get comment_type {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_29 ??= const _LinkedNodeCommentTypeReader()
        .vTableGet(_bc, _bcOffset, 29, idl.LinkedNodeCommentType.block);
    return _variantField_29;
  }

  @override
  List<idl.LinkedNode> get compilationUnit_directives {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_3 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get namespaceDirective_configurations {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_3 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get switchMember_labels {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_3 ??=
        const fb.ListReader<idl.LinkedNode>(const _LinkedNodeReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  idl.LinkedNode get constructorDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_10 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 10, null);
    return _variantField_10;
  }

  @override
  idl.LinkedNode get methodDeclaration_name {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
    _variantField_10 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 10, null);
    return _variantField_10;
  }

  @override
  idl.LinkedNodeFormalParameterKind get defaultFormalParameter_kind {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_26 ??= const _LinkedNodeFormalParameterKindReader().vTableGet(
        _bc,
        _bcOffset,
        26,
        idl.LinkedNodeFormalParameterKind.requiredPositional);
    return _variantField_26;
  }

  @override
  double get doubleLiteral_value {
    assert(kind == idl.LinkedNodeKind.doubleLiteral);
    _variantField_21 ??=
        const fb.Float64Reader().vTableGet(_bc, _bcOffset, 21, 0.0);
    return _variantField_21;
  }

  @override
  idl.LinkedNodeType get expression_type {
    assert(kind == idl.LinkedNodeKind.adjacentStrings ||
        kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.booleanLiteral ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.doubleLiteral ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.isExpression ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.namedExpression ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
        kind == idl.LinkedNodeKind.simpleStringLiteral ||
        kind == idl.LinkedNodeKind.stringInterpolation ||
        kind == idl.LinkedNodeKind.superExpression ||
        kind == idl.LinkedNodeKind.symbolLiteral ||
        kind == idl.LinkedNodeKind.thisExpression ||
        kind == idl.LinkedNodeKind.throwExpression);
    _variantField_25 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 25, null);
    return _variantField_25;
  }

  @override
  idl.LinkedNodeType get genericFunctionType_type {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_25 ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 25, null);
    return _variantField_25;
  }

  @override
  String get interpolationString_value {
    assert(kind == idl.LinkedNodeKind.interpolationString);
    _variantField_30 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 30, '');
    return _variantField_30;
  }

  @override
  idl.LinkedNode get invocationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.methodInvocation);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  idl.LinkedNode get namedCompilationUnitMember_name {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  idl.LinkedNode get normalFormalParameter_comment {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  idl.LinkedNode get typedLiteral_typeArguments {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  idl.LinkedNode get uriBasedDirective_uri {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  bool get isSynthetic {
    _isSynthetic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 1, false);
    return _isSynthetic;
  }

  @override
  idl.LinkedNodeKind get kind {
    _kind ??= const _LinkedNodeKindReader()
        .vTableGet(_bc, _bcOffset, 0, idl.LinkedNodeKind.adjacentStrings);
    return _kind;
  }

  @override
  List<String> get mixinDeclaration_superInvokedNames {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_36 ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 36, const <String>[]);
    return _variantField_36;
  }

  @override
  String get namespaceDirective_selectedUri {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_20 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 20, '');
    return _variantField_20;
  }

  @override
  String get simpleStringLiteral_value {
    assert(kind == idl.LinkedNodeKind.simpleStringLiteral);
    _variantField_20 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 20, '');
    return _variantField_20;
  }

  @override
  bool get setOrMapLiteral_isSet {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_31 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 31, false);
    return _variantField_31;
  }

  @override
  bool get simplyBoundable_isSimplyBounded {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_31 ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 31, false);
    return _variantField_31;
  }

  @override
  idl.TopLevelInferenceError get topLevelTypeInferenceError {
    assert(kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_35 ??= const _TopLevelInferenceErrorReader()
        .vTableGet(_bc, _bcOffset, 35, null);
    return _variantField_35;
  }

  @override
  String get uriBasedDirective_uriContent {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_22 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 22, '');
    return _variantField_22;
  }

  @override
  idl.LinkedNodeVariablesDeclaration get variableDeclaration_declaration {
    assert(kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_32 ??= const _LinkedNodeVariablesDeclarationReader()
        .vTableGet(_bc, _bcOffset, 32, null);
    return _variantField_32;
  }
}

abstract class _LinkedNodeMixin implements idl.LinkedNode {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (isSynthetic != false) _result["isSynthetic"] = isSynthetic;
    if (kind != idl.LinkedNodeKind.adjacentStrings)
      _result["kind"] = kind.toString().split('.')[1];
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      if (actualReturnType != null)
        _result["actualReturnType"] = actualReturnType.toJson();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (functionDeclaration_functionExpression != null)
        _result["functionDeclaration_functionExpression"] =
            functionDeclaration_functionExpression.toJson();
      if (functionDeclaration_externalKeyword != 0)
        _result["functionDeclaration_externalKeyword"] =
            functionDeclaration_externalKeyword;
      if (functionDeclaration_returnType != null)
        _result["functionDeclaration_returnType"] =
            functionDeclaration_returnType.toJson();
      if (functionDeclaration_propertyKeyword != 0)
        _result["functionDeclaration_propertyKeyword"] =
            functionDeclaration_propertyKeyword;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
    }
    if (kind == idl.LinkedNodeKind.functionExpression) {
      if (actualReturnType != null)
        _result["actualReturnType"] = actualReturnType.toJson();
      if (functionExpression_body != null)
        _result["functionExpression_body"] = functionExpression_body.toJson();
      if (functionExpression_formalParameters != null)
        _result["functionExpression_formalParameters"] =
            functionExpression_formalParameters.toJson();
      if (functionExpression_typeParameters != null)
        _result["functionExpression_typeParameters"] =
            functionExpression_typeParameters.toJson();
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      if (actualReturnType != null)
        _result["actualReturnType"] = actualReturnType.toJson();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (functionTypeAlias_formalParameters != null)
        _result["functionTypeAlias_formalParameters"] =
            functionTypeAlias_formalParameters.toJson();
      if (functionTypeAlias_returnType != null)
        _result["functionTypeAlias_returnType"] =
            functionTypeAlias_returnType.toJson();
      if (functionTypeAlias_typeParameters != null)
        _result["functionTypeAlias_typeParameters"] =
            functionTypeAlias_typeParameters.toJson();
      if (typeAlias_typedefKeyword != 0)
        _result["typeAlias_typedefKeyword"] = typeAlias_typedefKeyword;
      if (typeAlias_semicolon != 0)
        _result["typeAlias_semicolon"] = typeAlias_semicolon;
      if (typeAlias_hasSelfReference != false)
        _result["typeAlias_hasSelfReference"] = typeAlias_hasSelfReference;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
      if (simplyBoundable_isSimplyBounded != false)
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
    }
    if (kind == idl.LinkedNodeKind.genericFunctionType) {
      if (actualReturnType != null)
        _result["actualReturnType"] = actualReturnType.toJson();
      if (genericFunctionType_typeParameters != null)
        _result["genericFunctionType_typeParameters"] =
            genericFunctionType_typeParameters.toJson();
      if (genericFunctionType_functionKeyword != 0)
        _result["genericFunctionType_functionKeyword"] =
            genericFunctionType_functionKeyword;
      if (genericFunctionType_returnType != null)
        _result["genericFunctionType_returnType"] =
            genericFunctionType_returnType.toJson();
      if (genericFunctionType_id != 0)
        _result["genericFunctionType_id"] = genericFunctionType_id;
      if (genericFunctionType_formalParameters != null)
        _result["genericFunctionType_formalParameters"] =
            genericFunctionType_formalParameters.toJson();
      if (genericFunctionType_question != 0)
        _result["genericFunctionType_question"] = genericFunctionType_question;
      if (genericFunctionType_type != null)
        _result["genericFunctionType_type"] = genericFunctionType_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      if (actualReturnType != null)
        _result["actualReturnType"] = actualReturnType.toJson();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (methodDeclaration_body != null)
        _result["methodDeclaration_body"] = methodDeclaration_body.toJson();
      if (methodDeclaration_externalKeyword != 0)
        _result["methodDeclaration_externalKeyword"] =
            methodDeclaration_externalKeyword;
      if (methodDeclaration_formalParameters != null)
        _result["methodDeclaration_formalParameters"] =
            methodDeclaration_formalParameters.toJson();
      if (methodDeclaration_operatorKeyword != 0)
        _result["methodDeclaration_operatorKeyword"] =
            methodDeclaration_operatorKeyword;
      if (methodDeclaration_returnType != null)
        _result["methodDeclaration_returnType"] =
            methodDeclaration_returnType.toJson();
      if (methodDeclaration_modifierKeyword != 0)
        _result["methodDeclaration_modifierKeyword"] =
            methodDeclaration_modifierKeyword;
      if (methodDeclaration_propertyKeyword != 0)
        _result["methodDeclaration_propertyKeyword"] =
            methodDeclaration_propertyKeyword;
      if (methodDeclaration_actualProperty != 0)
        _result["methodDeclaration_actualProperty"] =
            methodDeclaration_actualProperty;
      if (methodDeclaration_typeParameters != null)
        _result["methodDeclaration_typeParameters"] =
            methodDeclaration_typeParameters.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (methodDeclaration_name != null)
        _result["methodDeclaration_name"] = methodDeclaration_name.toJson();
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      if (actualType != null) _result["actualType"] = actualType.toJson();
      if (normalFormalParameter_metadata.isNotEmpty)
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      if (fieldFormalParameter_type != null)
        _result["fieldFormalParameter_type"] =
            fieldFormalParameter_type.toJson();
      if (fieldFormalParameter_keyword != 0)
        _result["fieldFormalParameter_keyword"] = fieldFormalParameter_keyword;
      if (fieldFormalParameter_typeParameters != null)
        _result["fieldFormalParameter_typeParameters"] =
            fieldFormalParameter_typeParameters.toJson();
      if (fieldFormalParameter_thisKeyword != 0)
        _result["fieldFormalParameter_thisKeyword"] =
            fieldFormalParameter_thisKeyword;
      if (fieldFormalParameter_formalParameters != null)
        _result["fieldFormalParameter_formalParameters"] =
            fieldFormalParameter_formalParameters.toJson();
      if (fieldFormalParameter_period != 0)
        _result["fieldFormalParameter_period"] = fieldFormalParameter_period;
      if (normalFormalParameter_requiredKeyword != 0)
        _result["normalFormalParameter_requiredKeyword"] =
            normalFormalParameter_requiredKeyword;
      if (normalFormalParameter_covariantKeyword != 0)
        _result["normalFormalParameter_covariantKeyword"] =
            normalFormalParameter_covariantKeyword;
      if (inheritsCovariant != false)
        _result["inheritsCovariant"] = inheritsCovariant;
      if (normalFormalParameter_identifier != null)
        _result["normalFormalParameter_identifier"] =
            normalFormalParameter_identifier.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (normalFormalParameter_comment != null)
        _result["normalFormalParameter_comment"] =
            normalFormalParameter_comment.toJson();
    }
    if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      if (actualType != null) _result["actualType"] = actualType.toJson();
      if (normalFormalParameter_metadata.isNotEmpty)
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      if (functionTypedFormalParameter_formalParameters != null)
        _result["functionTypedFormalParameter_formalParameters"] =
            functionTypedFormalParameter_formalParameters.toJson();
      if (functionTypedFormalParameter_returnType != null)
        _result["functionTypedFormalParameter_returnType"] =
            functionTypedFormalParameter_returnType.toJson();
      if (functionTypedFormalParameter_typeParameters != null)
        _result["functionTypedFormalParameter_typeParameters"] =
            functionTypedFormalParameter_typeParameters.toJson();
      if (normalFormalParameter_requiredKeyword != 0)
        _result["normalFormalParameter_requiredKeyword"] =
            normalFormalParameter_requiredKeyword;
      if (normalFormalParameter_covariantKeyword != 0)
        _result["normalFormalParameter_covariantKeyword"] =
            normalFormalParameter_covariantKeyword;
      if (inheritsCovariant != false)
        _result["inheritsCovariant"] = inheritsCovariant;
      if (normalFormalParameter_identifier != null)
        _result["normalFormalParameter_identifier"] =
            normalFormalParameter_identifier.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (normalFormalParameter_comment != null)
        _result["normalFormalParameter_comment"] =
            normalFormalParameter_comment.toJson();
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      if (actualType != null) _result["actualType"] = actualType.toJson();
      if (normalFormalParameter_metadata.isNotEmpty)
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      if (simpleFormalParameter_type != null)
        _result["simpleFormalParameter_type"] =
            simpleFormalParameter_type.toJson();
      if (simpleFormalParameter_keyword != 0)
        _result["simpleFormalParameter_keyword"] =
            simpleFormalParameter_keyword;
      if (normalFormalParameter_requiredKeyword != 0)
        _result["normalFormalParameter_requiredKeyword"] =
            normalFormalParameter_requiredKeyword;
      if (normalFormalParameter_covariantKeyword != 0)
        _result["normalFormalParameter_covariantKeyword"] =
            normalFormalParameter_covariantKeyword;
      if (inheritsCovariant != false)
        _result["inheritsCovariant"] = inheritsCovariant;
      if (normalFormalParameter_identifier != null)
        _result["normalFormalParameter_identifier"] =
            normalFormalParameter_identifier.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (normalFormalParameter_comment != null)
        _result["normalFormalParameter_comment"] =
            normalFormalParameter_comment.toJson();
      if (topLevelTypeInferenceError != null)
        _result["topLevelTypeInferenceError"] =
            topLevelTypeInferenceError.toJson();
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      if (actualType != null) _result["actualType"] = actualType.toJson();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (variableDeclaration_initializer != null)
        _result["variableDeclaration_initializer"] =
            variableDeclaration_initializer.toJson();
      if (variableDeclaration_equals != 0)
        _result["variableDeclaration_equals"] = variableDeclaration_equals;
      if (variableDeclaration_name != null)
        _result["variableDeclaration_name"] = variableDeclaration_name.toJson();
      if (inheritsCovariant != false)
        _result["inheritsCovariant"] = inheritsCovariant;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (topLevelTypeInferenceError != null)
        _result["topLevelTypeInferenceError"] =
            topLevelTypeInferenceError.toJson();
      if (variableDeclaration_declaration != null)
        _result["variableDeclaration_declaration"] =
            variableDeclaration_declaration.toJson();
    }
    if (kind == idl.LinkedNodeKind.binaryExpression) {
      if (binaryExpression_invokeType != null)
        _result["binaryExpression_invokeType"] =
            binaryExpression_invokeType.toJson();
      if (binaryExpression_leftOperand != null)
        _result["binaryExpression_leftOperand"] =
            binaryExpression_leftOperand.toJson();
      if (binaryExpression_element != 0)
        _result["binaryExpression_element"] = binaryExpression_element;
      if (binaryExpression_rightOperand != null)
        _result["binaryExpression_rightOperand"] =
            binaryExpression_rightOperand.toJson();
      if (binaryExpression_elementType != null)
        _result["binaryExpression_elementType"] =
            binaryExpression_elementType.toJson();
      if (binaryExpression_operator != 0)
        _result["binaryExpression_operator"] = binaryExpression_operator;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.functionExpressionInvocation) {
      if (invocationExpression_invokeType != null)
        _result["invocationExpression_invokeType"] =
            invocationExpression_invokeType.toJson();
      if (functionExpressionInvocation_function != null)
        _result["functionExpressionInvocation_function"] =
            functionExpressionInvocation_function.toJson();
      if (invocationExpression_typeArguments != null)
        _result["invocationExpression_typeArguments"] =
            invocationExpression_typeArguments.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
      if (invocationExpression_arguments != null)
        _result["invocationExpression_arguments"] =
            invocationExpression_arguments.toJson();
    }
    if (kind == idl.LinkedNodeKind.methodInvocation) {
      if (invocationExpression_invokeType != null)
        _result["invocationExpression_invokeType"] =
            invocationExpression_invokeType.toJson();
      if (methodInvocation_methodName != null)
        _result["methodInvocation_methodName"] =
            methodInvocation_methodName.toJson();
      if (methodInvocation_operator != 0)
        _result["methodInvocation_operator"] = methodInvocation_operator;
      if (methodInvocation_target != null)
        _result["methodInvocation_target"] = methodInvocation_target.toJson();
      if (invocationExpression_typeArguments != null)
        _result["invocationExpression_typeArguments"] =
            invocationExpression_typeArguments.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
      if (invocationExpression_arguments != null)
        _result["invocationExpression_arguments"] =
            invocationExpression_arguments.toJson();
    }
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      if (adjacentStrings_strings.isNotEmpty)
        _result["adjacentStrings_strings"] =
            adjacentStrings_strings.map((_value) => _value.toJson()).toList();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.argumentList) {
      if (argumentList_arguments.isNotEmpty)
        _result["argumentList_arguments"] =
            argumentList_arguments.map((_value) => _value.toJson()).toList();
      if (argumentList_leftParenthesis != 0)
        _result["argumentList_leftParenthesis"] = argumentList_leftParenthesis;
      if (argumentList_rightParenthesis != 0)
        _result["argumentList_rightParenthesis"] =
            argumentList_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.block) {
      if (block_statements.isNotEmpty)
        _result["block_statements"] =
            block_statements.map((_value) => _value.toJson()).toList();
      if (block_leftBracket != 0)
        _result["block_leftBracket"] = block_leftBracket;
      if (block_rightBracket != 0)
        _result["block_rightBracket"] = block_rightBracket;
    }
    if (kind == idl.LinkedNodeKind.cascadeExpression) {
      if (cascadeExpression_sections.isNotEmpty)
        _result["cascadeExpression_sections"] = cascadeExpression_sections
            .map((_value) => _value.toJson())
            .toList();
      if (cascadeExpression_target != null)
        _result["cascadeExpression_target"] = cascadeExpression_target.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.comment) {
      if (comment_references.isNotEmpty)
        _result["comment_references"] =
            comment_references.map((_value) => _value.toJson()).toList();
      if (comment_tokens.isNotEmpty) _result["comment_tokens"] = comment_tokens;
      if (comment_type != idl.LinkedNodeCommentType.block)
        _result["comment_type"] = comment_type.toString().split('.')[1];
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      if (compilationUnit_declarations.isNotEmpty)
        _result["compilationUnit_declarations"] = compilationUnit_declarations
            .map((_value) => _value.toJson())
            .toList();
      if (compilationUnit_scriptTag != null)
        _result["compilationUnit_scriptTag"] =
            compilationUnit_scriptTag.toJson();
      if (compilationUnit_beginToken != 0)
        _result["compilationUnit_beginToken"] = compilationUnit_beginToken;
      if (compilationUnit_endToken != 0)
        _result["compilationUnit_endToken"] = compilationUnit_endToken;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (compilationUnit_directives.isNotEmpty)
        _result["compilationUnit_directives"] = compilationUnit_directives
            .map((_value) => _value.toJson())
            .toList();
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      if (constructorDeclaration_initializers.isNotEmpty)
        _result["constructorDeclaration_initializers"] =
            constructorDeclaration_initializers
                .map((_value) => _value.toJson())
                .toList();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (constructorDeclaration_body != null)
        _result["constructorDeclaration_body"] =
            constructorDeclaration_body.toJson();
      if (constructorDeclaration_constKeyword != 0)
        _result["constructorDeclaration_constKeyword"] =
            constructorDeclaration_constKeyword;
      if (constructorDeclaration_name != null)
        _result["constructorDeclaration_name"] =
            constructorDeclaration_name.toJson();
      if (constructorDeclaration_factoryKeyword != 0)
        _result["constructorDeclaration_factoryKeyword"] =
            constructorDeclaration_factoryKeyword;
      if (constructorDeclaration_parameters != null)
        _result["constructorDeclaration_parameters"] =
            constructorDeclaration_parameters.toJson();
      if (constructorDeclaration_externalKeyword != 0)
        _result["constructorDeclaration_externalKeyword"] =
            constructorDeclaration_externalKeyword;
      if (constructorDeclaration_period != 0)
        _result["constructorDeclaration_period"] =
            constructorDeclaration_period;
      if (constructorDeclaration_separator != 0)
        _result["constructorDeclaration_separator"] =
            constructorDeclaration_separator;
      if (constructorDeclaration_redirectedConstructor != null)
        _result["constructorDeclaration_redirectedConstructor"] =
            constructorDeclaration_redirectedConstructor.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (constructorDeclaration_returnType != null)
        _result["constructorDeclaration_returnType"] =
            constructorDeclaration_returnType.toJson();
    }
    if (kind == idl.LinkedNodeKind.dottedName) {
      if (dottedName_components.isNotEmpty)
        _result["dottedName_components"] =
            dottedName_components.map((_value) => _value.toJson()).toList();
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      if (enumDeclaration_constants.isNotEmpty)
        _result["enumDeclaration_constants"] =
            enumDeclaration_constants.map((_value) => _value.toJson()).toList();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (enumDeclaration_enumKeyword != 0)
        _result["enumDeclaration_enumKeyword"] = enumDeclaration_enumKeyword;
      if (enumDeclaration_rightBracket != 0)
        _result["enumDeclaration_rightBracket"] = enumDeclaration_rightBracket;
      if (enumDeclaration_leftBracket != 0)
        _result["enumDeclaration_leftBracket"] = enumDeclaration_leftBracket;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
    }
    if (kind == idl.LinkedNodeKind.formalParameterList) {
      if (formalParameterList_parameters.isNotEmpty)
        _result["formalParameterList_parameters"] =
            formalParameterList_parameters
                .map((_value) => _value.toJson())
                .toList();
      if (formalParameterList_leftDelimiter != 0)
        _result["formalParameterList_leftDelimiter"] =
            formalParameterList_leftDelimiter;
      if (formalParameterList_rightDelimiter != 0)
        _result["formalParameterList_rightDelimiter"] =
            formalParameterList_rightDelimiter;
      if (formalParameterList_leftParenthesis != 0)
        _result["formalParameterList_leftParenthesis"] =
            formalParameterList_leftParenthesis;
      if (formalParameterList_rightParenthesis != 0)
        _result["formalParameterList_rightParenthesis"] =
            formalParameterList_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      if (hideCombinator_hiddenNames.isNotEmpty)
        _result["hideCombinator_hiddenNames"] = hideCombinator_hiddenNames
            .map((_value) => _value.toJson())
            .toList();
      if (combinator_keyword != 0)
        _result["combinator_keyword"] = combinator_keyword;
    }
    if (kind == idl.LinkedNodeKind.implementsClause) {
      if (implementsClause_interfaces.isNotEmpty)
        _result["implementsClause_interfaces"] = implementsClause_interfaces
            .map((_value) => _value.toJson())
            .toList();
      if (implementsClause_implementsKeyword != 0)
        _result["implementsClause_implementsKeyword"] =
            implementsClause_implementsKeyword;
    }
    if (kind == idl.LinkedNodeKind.labeledStatement) {
      if (labeledStatement_labels.isNotEmpty)
        _result["labeledStatement_labels"] =
            labeledStatement_labels.map((_value) => _value.toJson()).toList();
      if (labeledStatement_statement != null)
        _result["labeledStatement_statement"] =
            labeledStatement_statement.toJson();
    }
    if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      if (libraryIdentifier_components.isNotEmpty)
        _result["libraryIdentifier_components"] = libraryIdentifier_components
            .map((_value) => _value.toJson())
            .toList();
    }
    if (kind == idl.LinkedNodeKind.listLiteral) {
      if (listLiteral_elements.isNotEmpty)
        _result["listLiteral_elements"] =
            listLiteral_elements.map((_value) => _value.toJson()).toList();
      if (listLiteral_leftBracket != 0)
        _result["listLiteral_leftBracket"] = listLiteral_leftBracket;
      if (listLiteral_rightBracket != 0)
        _result["listLiteral_rightBracket"] = listLiteral_rightBracket;
      if (typedLiteral_constKeyword != 0)
        _result["typedLiteral_constKeyword"] = typedLiteral_constKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
      if (typedLiteral_typeArguments != null)
        _result["typedLiteral_typeArguments"] =
            typedLiteral_typeArguments.toJson();
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      if (namespaceDirective_combinators.isNotEmpty)
        _result["namespaceDirective_combinators"] =
            namespaceDirective_combinators
                .map((_value) => _value.toJson())
                .toList();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (directive_keyword != 0)
        _result["directive_keyword"] = directive_keyword;
      if (uriBasedDirective_uriElement != 0)
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      if (directive_semicolon != 0)
        _result["directive_semicolon"] = directive_semicolon;
      if (namespaceDirective_configurations.isNotEmpty)
        _result["namespaceDirective_configurations"] =
            namespaceDirective_configurations
                .map((_value) => _value.toJson())
                .toList();
      if (uriBasedDirective_uri != null)
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      if (namespaceDirective_selectedUri != '')
        _result["namespaceDirective_selectedUri"] =
            namespaceDirective_selectedUri;
      if (uriBasedDirective_uriContent != '')
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      if (namespaceDirective_combinators.isNotEmpty)
        _result["namespaceDirective_combinators"] =
            namespaceDirective_combinators
                .map((_value) => _value.toJson())
                .toList();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (importDirective_prefix != null)
        _result["importDirective_prefix"] = importDirective_prefix.toJson();
      if (importDirective_asKeyword != 0)
        _result["importDirective_asKeyword"] = importDirective_asKeyword;
      if (importDirective_deferredKeyword != 0)
        _result["importDirective_deferredKeyword"] =
            importDirective_deferredKeyword;
      if (directive_keyword != 0)
        _result["directive_keyword"] = directive_keyword;
      if (uriBasedDirective_uriElement != 0)
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      if (directive_semicolon != 0)
        _result["directive_semicolon"] = directive_semicolon;
      if (namespaceDirective_configurations.isNotEmpty)
        _result["namespaceDirective_configurations"] =
            namespaceDirective_configurations
                .map((_value) => _value.toJson())
                .toList();
      if (uriBasedDirective_uri != null)
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      if (namespaceDirective_selectedUri != '')
        _result["namespaceDirective_selectedUri"] =
            namespaceDirective_selectedUri;
      if (uriBasedDirective_uriContent != '')
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
    }
    if (kind == idl.LinkedNodeKind.onClause) {
      if (onClause_superclassConstraints.isNotEmpty)
        _result["onClause_superclassConstraints"] =
            onClause_superclassConstraints
                .map((_value) => _value.toJson())
                .toList();
      if (onClause_onKeyword != 0)
        _result["onClause_onKeyword"] = onClause_onKeyword;
    }
    if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      if (setOrMapLiteral_elements.isNotEmpty)
        _result["setOrMapLiteral_elements"] =
            setOrMapLiteral_elements.map((_value) => _value.toJson()).toList();
      if (setOrMapLiteral_leftBracket != 0)
        _result["setOrMapLiteral_leftBracket"] = setOrMapLiteral_leftBracket;
      if (setOrMapLiteral_rightBracket != 0)
        _result["setOrMapLiteral_rightBracket"] = setOrMapLiteral_rightBracket;
      if (typedLiteral_constKeyword != 0)
        _result["typedLiteral_constKeyword"] = typedLiteral_constKeyword;
      if (setOrMapLiteral_isMap != false)
        _result["setOrMapLiteral_isMap"] = setOrMapLiteral_isMap;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
      if (typedLiteral_typeArguments != null)
        _result["typedLiteral_typeArguments"] =
            typedLiteral_typeArguments.toJson();
      if (setOrMapLiteral_isSet != false)
        _result["setOrMapLiteral_isSet"] = setOrMapLiteral_isSet;
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      if (showCombinator_shownNames.isNotEmpty)
        _result["showCombinator_shownNames"] =
            showCombinator_shownNames.map((_value) => _value.toJson()).toList();
      if (combinator_keyword != 0)
        _result["combinator_keyword"] = combinator_keyword;
    }
    if (kind == idl.LinkedNodeKind.stringInterpolation) {
      if (stringInterpolation_elements.isNotEmpty)
        _result["stringInterpolation_elements"] = stringInterpolation_elements
            .map((_value) => _value.toJson())
            .toList();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.switchStatement) {
      if (switchStatement_members.isNotEmpty)
        _result["switchStatement_members"] =
            switchStatement_members.map((_value) => _value.toJson()).toList();
      if (switchStatement_leftParenthesis != 0)
        _result["switchStatement_leftParenthesis"] =
            switchStatement_leftParenthesis;
      if (switchStatement_expression != null)
        _result["switchStatement_expression"] =
            switchStatement_expression.toJson();
      if (switchStatement_switchKeyword != 0)
        _result["switchStatement_switchKeyword"] =
            switchStatement_switchKeyword;
      if (switchStatement_rightParenthesis != 0)
        _result["switchStatement_rightParenthesis"] =
            switchStatement_rightParenthesis;
      if (switchStatement_leftBracket != 0)
        _result["switchStatement_leftBracket"] = switchStatement_leftBracket;
      if (switchStatement_rightBracket != 0)
        _result["switchStatement_rightBracket"] = switchStatement_rightBracket;
    }
    if (kind == idl.LinkedNodeKind.tryStatement) {
      if (tryStatement_catchClauses.isNotEmpty)
        _result["tryStatement_catchClauses"] =
            tryStatement_catchClauses.map((_value) => _value.toJson()).toList();
      if (tryStatement_body != null)
        _result["tryStatement_body"] = tryStatement_body.toJson();
      if (tryStatement_finallyKeyword != 0)
        _result["tryStatement_finallyKeyword"] = tryStatement_finallyKeyword;
      if (tryStatement_finallyBlock != null)
        _result["tryStatement_finallyBlock"] =
            tryStatement_finallyBlock.toJson();
      if (tryStatement_tryKeyword != 0)
        _result["tryStatement_tryKeyword"] = tryStatement_tryKeyword;
    }
    if (kind == idl.LinkedNodeKind.typeArgumentList) {
      if (typeArgumentList_arguments.isNotEmpty)
        _result["typeArgumentList_arguments"] = typeArgumentList_arguments
            .map((_value) => _value.toJson())
            .toList();
      if (typeArgumentList_leftBracket != 0)
        _result["typeArgumentList_leftBracket"] = typeArgumentList_leftBracket;
      if (typeArgumentList_rightBracket != 0)
        _result["typeArgumentList_rightBracket"] =
            typeArgumentList_rightBracket;
    }
    if (kind == idl.LinkedNodeKind.typeParameterList) {
      if (typeParameterList_typeParameters.isNotEmpty)
        _result["typeParameterList_typeParameters"] =
            typeParameterList_typeParameters
                .map((_value) => _value.toJson())
                .toList();
      if (typeParameterList_leftBracket != 0)
        _result["typeParameterList_leftBracket"] =
            typeParameterList_leftBracket;
      if (typeParameterList_rightBracket != 0)
        _result["typeParameterList_rightBracket"] =
            typeParameterList_rightBracket;
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      if (variableDeclarationList_variables.isNotEmpty)
        _result["variableDeclarationList_variables"] =
            variableDeclarationList_variables
                .map((_value) => _value.toJson())
                .toList();
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (variableDeclarationList_type != null)
        _result["variableDeclarationList_type"] =
            variableDeclarationList_type.toJson();
      if (variableDeclarationList_keyword != 0)
        _result["variableDeclarationList_keyword"] =
            variableDeclarationList_keyword;
      if (variableDeclarationList_lateKeyword != 0)
        _result["variableDeclarationList_lateKeyword"] =
            variableDeclarationList_lateKeyword;
    }
    if (kind == idl.LinkedNodeKind.withClause) {
      if (withClause_mixinTypes.isNotEmpty)
        _result["withClause_mixinTypes"] =
            withClause_mixinTypes.map((_value) => _value.toJson()).toList();
      if (withClause_withKeyword != 0)
        _result["withClause_withKeyword"] = withClause_withKeyword;
    }
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (classDeclaration_extendsClause != null)
        _result["classDeclaration_extendsClause"] =
            classDeclaration_extendsClause.toJson();
      if (classDeclaration_abstractKeyword != 0)
        _result["classDeclaration_abstractKeyword"] =
            classDeclaration_abstractKeyword;
      if (classDeclaration_withClause != null)
        _result["classDeclaration_withClause"] =
            classDeclaration_withClause.toJson();
      if (classDeclaration_nativeClause != null)
        _result["classDeclaration_nativeClause"] =
            classDeclaration_nativeClause.toJson();
      if (classDeclaration_classKeyword != 0)
        _result["classDeclaration_classKeyword"] =
            classDeclaration_classKeyword;
      if (classOrMixinDeclaration_rightBracket != 0)
        _result["classOrMixinDeclaration_rightBracket"] =
            classOrMixinDeclaration_rightBracket;
      if (classOrMixinDeclaration_leftBracket != 0)
        _result["classOrMixinDeclaration_leftBracket"] =
            classOrMixinDeclaration_leftBracket;
      if (classDeclaration_isDartObject != false)
        _result["classDeclaration_isDartObject"] =
            classDeclaration_isDartObject;
      if (classOrMixinDeclaration_implementsClause != null)
        _result["classOrMixinDeclaration_implementsClause"] =
            classOrMixinDeclaration_implementsClause.toJson();
      if (classOrMixinDeclaration_members.isNotEmpty)
        _result["classOrMixinDeclaration_members"] =
            classOrMixinDeclaration_members
                .map((_value) => _value.toJson())
                .toList();
      if (classOrMixinDeclaration_typeParameters != null)
        _result["classOrMixinDeclaration_typeParameters"] =
            classOrMixinDeclaration_typeParameters.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
      if (simplyBoundable_isSimplyBounded != false)
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (classTypeAlias_typeParameters != null)
        _result["classTypeAlias_typeParameters"] =
            classTypeAlias_typeParameters.toJson();
      if (classTypeAlias_abstractKeyword != 0)
        _result["classTypeAlias_abstractKeyword"] =
            classTypeAlias_abstractKeyword;
      if (classTypeAlias_superclass != null)
        _result["classTypeAlias_superclass"] =
            classTypeAlias_superclass.toJson();
      if (classTypeAlias_withClause != null)
        _result["classTypeAlias_withClause"] =
            classTypeAlias_withClause.toJson();
      if (classTypeAlias_equals != 0)
        _result["classTypeAlias_equals"] = classTypeAlias_equals;
      if (typeAlias_typedefKeyword != 0)
        _result["typeAlias_typedefKeyword"] = typeAlias_typedefKeyword;
      if (typeAlias_semicolon != 0)
        _result["typeAlias_semicolon"] = typeAlias_semicolon;
      if (classTypeAlias_implementsClause != null)
        _result["classTypeAlias_implementsClause"] =
            classTypeAlias_implementsClause.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
      if (simplyBoundable_isSimplyBounded != false)
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
    }
    if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (declaredIdentifier_identifier != null)
        _result["declaredIdentifier_identifier"] =
            declaredIdentifier_identifier.toJson();
      if (declaredIdentifier_keyword != 0)
        _result["declaredIdentifier_keyword"] = declaredIdentifier_keyword;
      if (declaredIdentifier_type != null)
        _result["declaredIdentifier_type"] = declaredIdentifier_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (enumConstantDeclaration_name != null)
        _result["enumConstantDeclaration_name"] =
            enumConstantDeclaration_name.toJson();
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (fieldDeclaration_fields != null)
        _result["fieldDeclaration_fields"] = fieldDeclaration_fields.toJson();
      if (fieldDeclaration_covariantKeyword != 0)
        _result["fieldDeclaration_covariantKeyword"] =
            fieldDeclaration_covariantKeyword;
      if (fieldDeclaration_staticKeyword != 0)
        _result["fieldDeclaration_staticKeyword"] =
            fieldDeclaration_staticKeyword;
      if (fieldDeclaration_semicolon != 0)
        _result["fieldDeclaration_semicolon"] = fieldDeclaration_semicolon;
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (genericTypeAlias_typeParameters != null)
        _result["genericTypeAlias_typeParameters"] =
            genericTypeAlias_typeParameters.toJson();
      if (genericTypeAlias_functionType != null)
        _result["genericTypeAlias_functionType"] =
            genericTypeAlias_functionType.toJson();
      if (genericTypeAlias_equals != 0)
        _result["genericTypeAlias_equals"] = genericTypeAlias_equals;
      if (typeAlias_typedefKeyword != 0)
        _result["typeAlias_typedefKeyword"] = typeAlias_typedefKeyword;
      if (typeAlias_semicolon != 0)
        _result["typeAlias_semicolon"] = typeAlias_semicolon;
      if (typeAlias_hasSelfReference != false)
        _result["typeAlias_hasSelfReference"] = typeAlias_hasSelfReference;
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
      if (simplyBoundable_isSimplyBounded != false)
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (libraryDirective_name != null)
        _result["libraryDirective_name"] = libraryDirective_name.toJson();
      if (directive_keyword != 0)
        _result["directive_keyword"] = directive_keyword;
      if (directive_semicolon != 0)
        _result["directive_semicolon"] = directive_semicolon;
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (mixinDeclaration_onClause != null)
        _result["mixinDeclaration_onClause"] =
            mixinDeclaration_onClause.toJson();
      if (mixinDeclaration_mixinKeyword != 0)
        _result["mixinDeclaration_mixinKeyword"] =
            mixinDeclaration_mixinKeyword;
      if (classOrMixinDeclaration_rightBracket != 0)
        _result["classOrMixinDeclaration_rightBracket"] =
            classOrMixinDeclaration_rightBracket;
      if (classOrMixinDeclaration_leftBracket != 0)
        _result["classOrMixinDeclaration_leftBracket"] =
            classOrMixinDeclaration_leftBracket;
      if (classOrMixinDeclaration_implementsClause != null)
        _result["classOrMixinDeclaration_implementsClause"] =
            classOrMixinDeclaration_implementsClause.toJson();
      if (classOrMixinDeclaration_members.isNotEmpty)
        _result["classOrMixinDeclaration_members"] =
            classOrMixinDeclaration_members
                .map((_value) => _value.toJson())
                .toList();
      if (classOrMixinDeclaration_typeParameters != null)
        _result["classOrMixinDeclaration_typeParameters"] =
            classOrMixinDeclaration_typeParameters.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (namedCompilationUnitMember_name != null)
        _result["namedCompilationUnitMember_name"] =
            namedCompilationUnitMember_name.toJson();
      if (mixinDeclaration_superInvokedNames.isNotEmpty)
        _result["mixinDeclaration_superInvokedNames"] =
            mixinDeclaration_superInvokedNames;
      if (simplyBoundable_isSimplyBounded != false)
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (directive_keyword != 0)
        _result["directive_keyword"] = directive_keyword;
      if (uriBasedDirective_uriElement != 0)
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      if (directive_semicolon != 0)
        _result["directive_semicolon"] = directive_semicolon;
      if (uriBasedDirective_uri != null)
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      if (uriBasedDirective_uriContent != '')
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (partOfDirective_libraryName != null)
        _result["partOfDirective_libraryName"] =
            partOfDirective_libraryName.toJson();
      if (partOfDirective_uri != null)
        _result["partOfDirective_uri"] = partOfDirective_uri.toJson();
      if (partOfDirective_ofKeyword != 0)
        _result["partOfDirective_ofKeyword"] = partOfDirective_ofKeyword;
      if (directive_keyword != 0)
        _result["directive_keyword"] = directive_keyword;
      if (directive_semicolon != 0)
        _result["directive_semicolon"] = directive_semicolon;
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (topLevelVariableDeclaration_variableList != null)
        _result["topLevelVariableDeclaration_variableList"] =
            topLevelVariableDeclaration_variableList.toJson();
      if (topLevelVariableDeclaration_semicolon != 0)
        _result["topLevelVariableDeclaration_semicolon"] =
            topLevelVariableDeclaration_semicolon;
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      if (annotatedNode_comment != null)
        _result["annotatedNode_comment"] = annotatedNode_comment.toJson();
      if (annotatedNode_metadata.isNotEmpty)
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      if (typeParameter_bound != null)
        _result["typeParameter_bound"] = typeParameter_bound.toJson();
      if (typeParameter_extendsKeyword != 0)
        _result["typeParameter_extendsKeyword"] = typeParameter_extendsKeyword;
      if (typeParameter_name != null)
        _result["typeParameter_name"] = typeParameter_name.toJson();
      if (typeParameter_defaultType != null)
        _result["typeParameter_defaultType"] =
            typeParameter_defaultType.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
    }
    if (kind == idl.LinkedNodeKind.switchCase) {
      if (switchMember_statements.isNotEmpty)
        _result["switchMember_statements"] =
            switchMember_statements.map((_value) => _value.toJson()).toList();
      if (switchCase_expression != null)
        _result["switchCase_expression"] = switchCase_expression.toJson();
      if (switchMember_keyword != 0)
        _result["switchMember_keyword"] = switchMember_keyword;
      if (switchMember_colon != 0)
        _result["switchMember_colon"] = switchMember_colon;
      if (switchMember_labels.isNotEmpty)
        _result["switchMember_labels"] =
            switchMember_labels.map((_value) => _value.toJson()).toList();
    }
    if (kind == idl.LinkedNodeKind.switchDefault) {
      if (switchMember_statements.isNotEmpty)
        _result["switchMember_statements"] =
            switchMember_statements.map((_value) => _value.toJson()).toList();
      if (switchMember_keyword != 0)
        _result["switchMember_keyword"] = switchMember_keyword;
      if (switchMember_colon != 0)
        _result["switchMember_colon"] = switchMember_colon;
      if (switchMember_labels.isNotEmpty)
        _result["switchMember_labels"] =
            switchMember_labels.map((_value) => _value.toJson()).toList();
    }
    if (kind == idl.LinkedNodeKind.annotation) {
      if (annotation_arguments != null)
        _result["annotation_arguments"] = annotation_arguments.toJson();
      if (annotation_atSign != 0)
        _result["annotation_atSign"] = annotation_atSign;
      if (annotation_constructorName != null)
        _result["annotation_constructorName"] =
            annotation_constructorName.toJson();
      if (annotation_element != 0)
        _result["annotation_element"] = annotation_element;
      if (annotation_elementType != null)
        _result["annotation_elementType"] = annotation_elementType.toJson();
      if (annotation_name != null)
        _result["annotation_name"] = annotation_name.toJson();
      if (annotation_period != 0)
        _result["annotation_period"] = annotation_period;
    }
    if (kind == idl.LinkedNodeKind.asExpression) {
      if (asExpression_expression != null)
        _result["asExpression_expression"] = asExpression_expression.toJson();
      if (asExpression_asOperator != 0)
        _result["asExpression_asOperator"] = asExpression_asOperator;
      if (asExpression_type != null)
        _result["asExpression_type"] = asExpression_type.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.assertInitializer) {
      if (assertInitializer_condition != null)
        _result["assertInitializer_condition"] =
            assertInitializer_condition.toJson();
      if (assertInitializer_assertKeyword != 0)
        _result["assertInitializer_assertKeyword"] =
            assertInitializer_assertKeyword;
      if (assertInitializer_message != null)
        _result["assertInitializer_message"] =
            assertInitializer_message.toJson();
      if (assertInitializer_leftParenthesis != 0)
        _result["assertInitializer_leftParenthesis"] =
            assertInitializer_leftParenthesis;
      if (assertInitializer_comma != 0)
        _result["assertInitializer_comma"] = assertInitializer_comma;
      if (assertInitializer_rightParenthesis != 0)
        _result["assertInitializer_rightParenthesis"] =
            assertInitializer_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.assertStatement) {
      if (assertStatement_condition != null)
        _result["assertStatement_condition"] =
            assertStatement_condition.toJson();
      if (assertStatement_assertKeyword != 0)
        _result["assertStatement_assertKeyword"] =
            assertStatement_assertKeyword;
      if (assertStatement_message != null)
        _result["assertStatement_message"] = assertStatement_message.toJson();
      if (assertStatement_leftParenthesis != 0)
        _result["assertStatement_leftParenthesis"] =
            assertStatement_leftParenthesis;
      if (assertStatement_comma != 0)
        _result["assertStatement_comma"] = assertStatement_comma;
      if (assertStatement_rightParenthesis != 0)
        _result["assertStatement_rightParenthesis"] =
            assertStatement_rightParenthesis;
      if (assertStatement_semicolon != 0)
        _result["assertStatement_semicolon"] = assertStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.assignmentExpression) {
      if (assignmentExpression_leftHandSide != null)
        _result["assignmentExpression_leftHandSide"] =
            assignmentExpression_leftHandSide.toJson();
      if (assignmentExpression_element != 0)
        _result["assignmentExpression_element"] = assignmentExpression_element;
      if (assignmentExpression_rightHandSide != null)
        _result["assignmentExpression_rightHandSide"] =
            assignmentExpression_rightHandSide.toJson();
      if (assignmentExpression_elementType != null)
        _result["assignmentExpression_elementType"] =
            assignmentExpression_elementType.toJson();
      if (assignmentExpression_operator != 0)
        _result["assignmentExpression_operator"] =
            assignmentExpression_operator;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.awaitExpression) {
      if (awaitExpression_expression != null)
        _result["awaitExpression_expression"] =
            awaitExpression_expression.toJson();
      if (awaitExpression_awaitKeyword != 0)
        _result["awaitExpression_awaitKeyword"] = awaitExpression_awaitKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      if (blockFunctionBody_block != null)
        _result["blockFunctionBody_block"] = blockFunctionBody_block.toJson();
      if (blockFunctionBody_keyword != 0)
        _result["blockFunctionBody_keyword"] = blockFunctionBody_keyword;
      if (blockFunctionBody_star != 0)
        _result["blockFunctionBody_star"] = blockFunctionBody_star;
    }
    if (kind == idl.LinkedNodeKind.breakStatement) {
      if (breakStatement_label != null)
        _result["breakStatement_label"] = breakStatement_label.toJson();
      if (breakStatement_breakKeyword != 0)
        _result["breakStatement_breakKeyword"] = breakStatement_breakKeyword;
      if (breakStatement_semicolon != 0)
        _result["breakStatement_semicolon"] = breakStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.catchClause) {
      if (catchClause_body != null)
        _result["catchClause_body"] = catchClause_body.toJson();
      if (catchClause_catchKeyword != 0)
        _result["catchClause_catchKeyword"] = catchClause_catchKeyword;
      if (catchClause_exceptionParameter != null)
        _result["catchClause_exceptionParameter"] =
            catchClause_exceptionParameter.toJson();
      if (catchClause_leftParenthesis != 0)
        _result["catchClause_leftParenthesis"] = catchClause_leftParenthesis;
      if (catchClause_exceptionType != null)
        _result["catchClause_exceptionType"] =
            catchClause_exceptionType.toJson();
      if (catchClause_comma != 0)
        _result["catchClause_comma"] = catchClause_comma;
      if (catchClause_onKeyword != 0)
        _result["catchClause_onKeyword"] = catchClause_onKeyword;
      if (catchClause_rightParenthesis != 0)
        _result["catchClause_rightParenthesis"] = catchClause_rightParenthesis;
      if (catchClause_stackTraceParameter != null)
        _result["catchClause_stackTraceParameter"] =
            catchClause_stackTraceParameter.toJson();
    }
    if (kind == idl.LinkedNodeKind.commentReference) {
      if (commentReference_identifier != null)
        _result["commentReference_identifier"] =
            commentReference_identifier.toJson();
      if (commentReference_newKeyword != 0)
        _result["commentReference_newKeyword"] = commentReference_newKeyword;
    }
    if (kind == idl.LinkedNodeKind.conditionalExpression) {
      if (conditionalExpression_condition != null)
        _result["conditionalExpression_condition"] =
            conditionalExpression_condition.toJson();
      if (conditionalExpression_colon != 0)
        _result["conditionalExpression_colon"] = conditionalExpression_colon;
      if (conditionalExpression_elseExpression != null)
        _result["conditionalExpression_elseExpression"] =
            conditionalExpression_elseExpression.toJson();
      if (conditionalExpression_thenExpression != null)
        _result["conditionalExpression_thenExpression"] =
            conditionalExpression_thenExpression.toJson();
      if (conditionalExpression_question != 0)
        _result["conditionalExpression_question"] =
            conditionalExpression_question;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.configuration) {
      if (configuration_name != null)
        _result["configuration_name"] = configuration_name.toJson();
      if (configuration_ifKeyword != 0)
        _result["configuration_ifKeyword"] = configuration_ifKeyword;
      if (configuration_value != null)
        _result["configuration_value"] = configuration_value.toJson();
      if (configuration_rightParenthesis != 0)
        _result["configuration_rightParenthesis"] =
            configuration_rightParenthesis;
      if (configuration_uri != null)
        _result["configuration_uri"] = configuration_uri.toJson();
      if (configuration_leftParenthesis != 0)
        _result["configuration_leftParenthesis"] =
            configuration_leftParenthesis;
      if (configuration_equalToken != 0)
        _result["configuration_equalToken"] = configuration_equalToken;
    }
    if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      if (constructorFieldInitializer_expression != null)
        _result["constructorFieldInitializer_expression"] =
            constructorFieldInitializer_expression.toJson();
      if (constructorFieldInitializer_equals != 0)
        _result["constructorFieldInitializer_equals"] =
            constructorFieldInitializer_equals;
      if (constructorFieldInitializer_fieldName != null)
        _result["constructorFieldInitializer_fieldName"] =
            constructorFieldInitializer_fieldName.toJson();
      if (constructorFieldInitializer_thisKeyword != 0)
        _result["constructorFieldInitializer_thisKeyword"] =
            constructorFieldInitializer_thisKeyword;
      if (constructorFieldInitializer_period != 0)
        _result["constructorFieldInitializer_period"] =
            constructorFieldInitializer_period;
    }
    if (kind == idl.LinkedNodeKind.constructorName) {
      if (constructorName_name != null)
        _result["constructorName_name"] = constructorName_name.toJson();
      if (constructorName_element != 0)
        _result["constructorName_element"] = constructorName_element;
      if (constructorName_type != null)
        _result["constructorName_type"] = constructorName_type.toJson();
      if (constructorName_elementType != null)
        _result["constructorName_elementType"] =
            constructorName_elementType.toJson();
      if (constructorName_period != 0)
        _result["constructorName_period"] = constructorName_period;
    }
    if (kind == idl.LinkedNodeKind.continueStatement) {
      if (continueStatement_label != null)
        _result["continueStatement_label"] = continueStatement_label.toJson();
      if (continueStatement_continueKeyword != 0)
        _result["continueStatement_continueKeyword"] =
            continueStatement_continueKeyword;
      if (continueStatement_semicolon != 0)
        _result["continueStatement_semicolon"] = continueStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      if (defaultFormalParameter_defaultValue != null)
        _result["defaultFormalParameter_defaultValue"] =
            defaultFormalParameter_defaultValue.toJson();
      if (defaultFormalParameter_separator != 0)
        _result["defaultFormalParameter_separator"] =
            defaultFormalParameter_separator;
      if (defaultFormalParameter_parameter != null)
        _result["defaultFormalParameter_parameter"] =
            defaultFormalParameter_parameter.toJson();
      if (codeLength != 0) _result["codeLength"] = codeLength;
      if (codeOffset != 0) _result["codeOffset"] = codeOffset;
      if (defaultFormalParameter_kind !=
          idl.LinkedNodeFormalParameterKind.requiredPositional)
        _result["defaultFormalParameter_kind"] =
            defaultFormalParameter_kind.toString().split('.')[1];
    }
    if (kind == idl.LinkedNodeKind.doStatement) {
      if (doStatement_body != null)
        _result["doStatement_body"] = doStatement_body.toJson();
      if (doStatement_leftParenthesis != 0)
        _result["doStatement_leftParenthesis"] = doStatement_leftParenthesis;
      if (doStatement_condition != null)
        _result["doStatement_condition"] = doStatement_condition.toJson();
      if (doStatement_doKeyword != 0)
        _result["doStatement_doKeyword"] = doStatement_doKeyword;
      if (doStatement_rightParenthesis != 0)
        _result["doStatement_rightParenthesis"] = doStatement_rightParenthesis;
      if (doStatement_semicolon != 0)
        _result["doStatement_semicolon"] = doStatement_semicolon;
      if (doStatement_whileKeyword != 0)
        _result["doStatement_whileKeyword"] = doStatement_whileKeyword;
    }
    if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      if (expressionFunctionBody_expression != null)
        _result["expressionFunctionBody_expression"] =
            expressionFunctionBody_expression.toJson();
      if (expressionFunctionBody_arrow != 0)
        _result["expressionFunctionBody_arrow"] = expressionFunctionBody_arrow;
      if (expressionFunctionBody_semicolon != 0)
        _result["expressionFunctionBody_semicolon"] =
            expressionFunctionBody_semicolon;
      if (expressionFunctionBody_keyword != 0)
        _result["expressionFunctionBody_keyword"] =
            expressionFunctionBody_keyword;
    }
    if (kind == idl.LinkedNodeKind.expressionStatement) {
      if (expressionStatement_expression != null)
        _result["expressionStatement_expression"] =
            expressionStatement_expression.toJson();
      if (expressionStatement_semicolon != 0)
        _result["expressionStatement_semicolon"] =
            expressionStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.extendsClause) {
      if (extendsClause_superclass != null)
        _result["extendsClause_superclass"] = extendsClause_superclass.toJson();
      if (extendsClause_extendsKeyword != 0)
        _result["extendsClause_extendsKeyword"] = extendsClause_extendsKeyword;
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      if (forEachParts_iterable != null)
        _result["forEachParts_iterable"] = forEachParts_iterable.toJson();
      if (forEachParts_inKeyword != 0)
        _result["forEachParts_inKeyword"] = forEachParts_inKeyword;
      if (forEachPartsWithDeclaration_loopVariable != null)
        _result["forEachPartsWithDeclaration_loopVariable"] =
            forEachPartsWithDeclaration_loopVariable.toJson();
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      if (forEachParts_iterable != null)
        _result["forEachParts_iterable"] = forEachParts_iterable.toJson();
      if (forEachParts_inKeyword != 0)
        _result["forEachParts_inKeyword"] = forEachParts_inKeyword;
      if (forEachPartsWithIdentifier_identifier != null)
        _result["forEachPartsWithIdentifier_identifier"] =
            forEachPartsWithIdentifier_identifier.toJson();
    }
    if (kind == idl.LinkedNodeKind.forElement) {
      if (forMixin_forLoopParts != null)
        _result["forMixin_forLoopParts"] = forMixin_forLoopParts.toJson();
      if (forMixin_awaitKeyword != 0)
        _result["forMixin_awaitKeyword"] = forMixin_awaitKeyword;
      if (forElement_body != null)
        _result["forElement_body"] = forElement_body.toJson();
      if (forMixin_leftParenthesis != 0)
        _result["forMixin_leftParenthesis"] = forMixin_leftParenthesis;
      if (forMixin_forKeyword != 0)
        _result["forMixin_forKeyword"] = forMixin_forKeyword;
      if (forMixin_rightParenthesis != 0)
        _result["forMixin_rightParenthesis"] = forMixin_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.forStatement) {
      if (forMixin_forLoopParts != null)
        _result["forMixin_forLoopParts"] = forMixin_forLoopParts.toJson();
      if (forMixin_awaitKeyword != 0)
        _result["forMixin_awaitKeyword"] = forMixin_awaitKeyword;
      if (forStatement_body != null)
        _result["forStatement_body"] = forStatement_body.toJson();
      if (forMixin_leftParenthesis != 0)
        _result["forMixin_leftParenthesis"] = forMixin_leftParenthesis;
      if (forMixin_forKeyword != 0)
        _result["forMixin_forKeyword"] = forMixin_forKeyword;
      if (forMixin_rightParenthesis != 0)
        _result["forMixin_rightParenthesis"] = forMixin_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      if (forParts_condition != null)
        _result["forParts_condition"] = forParts_condition.toJson();
      if (forParts_leftSeparator != 0)
        _result["forParts_leftSeparator"] = forParts_leftSeparator;
      if (forPartsWithDeclarations_variables != null)
        _result["forPartsWithDeclarations_variables"] =
            forPartsWithDeclarations_variables.toJson();
      if (forParts_rightSeparator != 0)
        _result["forParts_rightSeparator"] = forParts_rightSeparator;
      if (forParts_updaters.isNotEmpty)
        _result["forParts_updaters"] =
            forParts_updaters.map((_value) => _value.toJson()).toList();
    }
    if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      if (forParts_condition != null)
        _result["forParts_condition"] = forParts_condition.toJson();
      if (forParts_leftSeparator != 0)
        _result["forParts_leftSeparator"] = forParts_leftSeparator;
      if (forPartsWithExpression_initialization != null)
        _result["forPartsWithExpression_initialization"] =
            forPartsWithExpression_initialization.toJson();
      if (forParts_rightSeparator != 0)
        _result["forParts_rightSeparator"] = forParts_rightSeparator;
      if (forParts_updaters.isNotEmpty)
        _result["forParts_updaters"] =
            forParts_updaters.map((_value) => _value.toJson()).toList();
    }
    if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      if (functionDeclarationStatement_functionDeclaration != null)
        _result["functionDeclarationStatement_functionDeclaration"] =
            functionDeclarationStatement_functionDeclaration.toJson();
    }
    if (kind == idl.LinkedNodeKind.ifElement) {
      if (ifMixin_condition != null)
        _result["ifMixin_condition"] = ifMixin_condition.toJson();
      if (ifMixin_elseKeyword != 0)
        _result["ifMixin_elseKeyword"] = ifMixin_elseKeyword;
      if (ifMixin_leftParenthesis != 0)
        _result["ifMixin_leftParenthesis"] = ifMixin_leftParenthesis;
      if (ifElement_thenElement != null)
        _result["ifElement_thenElement"] = ifElement_thenElement.toJson();
      if (ifMixin_ifKeyword != 0)
        _result["ifMixin_ifKeyword"] = ifMixin_ifKeyword;
      if (ifMixin_rightParenthesis != 0)
        _result["ifMixin_rightParenthesis"] = ifMixin_rightParenthesis;
      if (ifElement_elseElement != null)
        _result["ifElement_elseElement"] = ifElement_elseElement.toJson();
    }
    if (kind == idl.LinkedNodeKind.ifStatement) {
      if (ifMixin_condition != null)
        _result["ifMixin_condition"] = ifMixin_condition.toJson();
      if (ifMixin_elseKeyword != 0)
        _result["ifMixin_elseKeyword"] = ifMixin_elseKeyword;
      if (ifStatement_elseStatement != null)
        _result["ifStatement_elseStatement"] =
            ifStatement_elseStatement.toJson();
      if (ifMixin_leftParenthesis != 0)
        _result["ifMixin_leftParenthesis"] = ifMixin_leftParenthesis;
      if (ifStatement_thenStatement != null)
        _result["ifStatement_thenStatement"] =
            ifStatement_thenStatement.toJson();
      if (ifMixin_ifKeyword != 0)
        _result["ifMixin_ifKeyword"] = ifMixin_ifKeyword;
      if (ifMixin_rightParenthesis != 0)
        _result["ifMixin_rightParenthesis"] = ifMixin_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.indexExpression) {
      if (indexExpression_index != null)
        _result["indexExpression_index"] = indexExpression_index.toJson();
      if (indexExpression_element != 0)
        _result["indexExpression_element"] = indexExpression_element;
      if (indexExpression_target != null)
        _result["indexExpression_target"] = indexExpression_target.toJson();
      if (indexExpression_leftBracket != 0)
        _result["indexExpression_leftBracket"] = indexExpression_leftBracket;
      if (indexExpression_elementType != null)
        _result["indexExpression_elementType"] =
            indexExpression_elementType.toJson();
      if (indexExpression_period != 0)
        _result["indexExpression_period"] = indexExpression_period;
      if (indexExpression_rightBracket != 0)
        _result["indexExpression_rightBracket"] = indexExpression_rightBracket;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      if (instanceCreationExpression_arguments != null)
        _result["instanceCreationExpression_arguments"] =
            instanceCreationExpression_arguments.toJson();
      if (instanceCreationExpression_keyword != 0)
        _result["instanceCreationExpression_keyword"] =
            instanceCreationExpression_keyword;
      if (instanceCreationExpression_constructorName != null)
        _result["instanceCreationExpression_constructorName"] =
            instanceCreationExpression_constructorName.toJson();
      if (instanceCreationExpression_typeArguments != null)
        _result["instanceCreationExpression_typeArguments"] =
            instanceCreationExpression_typeArguments.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.interpolationExpression) {
      if (interpolationExpression_expression != null)
        _result["interpolationExpression_expression"] =
            interpolationExpression_expression.toJson();
      if (interpolationExpression_leftBracket != 0)
        _result["interpolationExpression_leftBracket"] =
            interpolationExpression_leftBracket;
      if (interpolationExpression_rightBracket != 0)
        _result["interpolationExpression_rightBracket"] =
            interpolationExpression_rightBracket;
    }
    if (kind == idl.LinkedNodeKind.isExpression) {
      if (isExpression_expression != null)
        _result["isExpression_expression"] = isExpression_expression.toJson();
      if (isExpression_isOperator != 0)
        _result["isExpression_isOperator"] = isExpression_isOperator;
      if (isExpression_type != null)
        _result["isExpression_type"] = isExpression_type.toJson();
      if (isExpression_notOperator != 0)
        _result["isExpression_notOperator"] = isExpression_notOperator;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.label) {
      if (label_label != null) _result["label_label"] = label_label.toJson();
      if (label_colon != 0) _result["label_colon"] = label_colon;
    }
    if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      if (mapLiteralEntry_key != null)
        _result["mapLiteralEntry_key"] = mapLiteralEntry_key.toJson();
      if (mapLiteralEntry_separator != 0)
        _result["mapLiteralEntry_separator"] = mapLiteralEntry_separator;
      if (mapLiteralEntry_value != null)
        _result["mapLiteralEntry_value"] = mapLiteralEntry_value.toJson();
    }
    if (kind == idl.LinkedNodeKind.namedExpression) {
      if (namedExpression_expression != null)
        _result["namedExpression_expression"] =
            namedExpression_expression.toJson();
      if (namedExpression_name != null)
        _result["namedExpression_name"] = namedExpression_name.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.nativeClause) {
      if (nativeClause_name != null)
        _result["nativeClause_name"] = nativeClause_name.toJson();
      if (nativeClause_nativeKeyword != 0)
        _result["nativeClause_nativeKeyword"] = nativeClause_nativeKeyword;
    }
    if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      if (nativeFunctionBody_stringLiteral != null)
        _result["nativeFunctionBody_stringLiteral"] =
            nativeFunctionBody_stringLiteral.toJson();
      if (nativeFunctionBody_nativeKeyword != 0)
        _result["nativeFunctionBody_nativeKeyword"] =
            nativeFunctionBody_nativeKeyword;
      if (nativeFunctionBody_semicolon != 0)
        _result["nativeFunctionBody_semicolon"] = nativeFunctionBody_semicolon;
    }
    if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      if (parenthesizedExpression_expression != null)
        _result["parenthesizedExpression_expression"] =
            parenthesizedExpression_expression.toJson();
      if (parenthesizedExpression_leftParenthesis != 0)
        _result["parenthesizedExpression_leftParenthesis"] =
            parenthesizedExpression_leftParenthesis;
      if (parenthesizedExpression_rightParenthesis != 0)
        _result["parenthesizedExpression_rightParenthesis"] =
            parenthesizedExpression_rightParenthesis;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.postfixExpression) {
      if (postfixExpression_operand != null)
        _result["postfixExpression_operand"] =
            postfixExpression_operand.toJson();
      if (postfixExpression_element != 0)
        _result["postfixExpression_element"] = postfixExpression_element;
      if (postfixExpression_elementType != null)
        _result["postfixExpression_elementType"] =
            postfixExpression_elementType.toJson();
      if (postfixExpression_operator != 0)
        _result["postfixExpression_operator"] = postfixExpression_operator;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      if (prefixedIdentifier_identifier != null)
        _result["prefixedIdentifier_identifier"] =
            prefixedIdentifier_identifier.toJson();
      if (prefixedIdentifier_period != 0)
        _result["prefixedIdentifier_period"] = prefixedIdentifier_period;
      if (prefixedIdentifier_prefix != null)
        _result["prefixedIdentifier_prefix"] =
            prefixedIdentifier_prefix.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.prefixExpression) {
      if (prefixExpression_operand != null)
        _result["prefixExpression_operand"] = prefixExpression_operand.toJson();
      if (prefixExpression_element != 0)
        _result["prefixExpression_element"] = prefixExpression_element;
      if (prefixExpression_elementType != null)
        _result["prefixExpression_elementType"] =
            prefixExpression_elementType.toJson();
      if (prefixExpression_operator != 0)
        _result["prefixExpression_operator"] = prefixExpression_operator;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.propertyAccess) {
      if (propertyAccess_propertyName != null)
        _result["propertyAccess_propertyName"] =
            propertyAccess_propertyName.toJson();
      if (propertyAccess_operator != 0)
        _result["propertyAccess_operator"] = propertyAccess_operator;
      if (propertyAccess_target != null)
        _result["propertyAccess_target"] = propertyAccess_target.toJson();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      if (redirectingConstructorInvocation_arguments != null)
        _result["redirectingConstructorInvocation_arguments"] =
            redirectingConstructorInvocation_arguments.toJson();
      if (redirectingConstructorInvocation_element != 0)
        _result["redirectingConstructorInvocation_element"] =
            redirectingConstructorInvocation_element;
      if (redirectingConstructorInvocation_constructorName != null)
        _result["redirectingConstructorInvocation_constructorName"] =
            redirectingConstructorInvocation_constructorName.toJson();
      if (redirectingConstructorInvocation_thisKeyword != 0)
        _result["redirectingConstructorInvocation_thisKeyword"] =
            redirectingConstructorInvocation_thisKeyword;
      if (redirectingConstructorInvocation_elementType != null)
        _result["redirectingConstructorInvocation_elementType"] =
            redirectingConstructorInvocation_elementType.toJson();
      if (redirectingConstructorInvocation_period != 0)
        _result["redirectingConstructorInvocation_period"] =
            redirectingConstructorInvocation_period;
    }
    if (kind == idl.LinkedNodeKind.returnStatement) {
      if (returnStatement_expression != null)
        _result["returnStatement_expression"] =
            returnStatement_expression.toJson();
      if (returnStatement_returnKeyword != 0)
        _result["returnStatement_returnKeyword"] =
            returnStatement_returnKeyword;
      if (returnStatement_semicolon != 0)
        _result["returnStatement_semicolon"] = returnStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.spreadElement) {
      if (spreadElement_expression != null)
        _result["spreadElement_expression"] = spreadElement_expression.toJson();
      if (spreadElement_spreadOperator != 0)
        _result["spreadElement_spreadOperator"] = spreadElement_spreadOperator;
    }
    if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      if (superConstructorInvocation_arguments != null)
        _result["superConstructorInvocation_arguments"] =
            superConstructorInvocation_arguments.toJson();
      if (superConstructorInvocation_element != 0)
        _result["superConstructorInvocation_element"] =
            superConstructorInvocation_element;
      if (superConstructorInvocation_constructorName != null)
        _result["superConstructorInvocation_constructorName"] =
            superConstructorInvocation_constructorName.toJson();
      if (superConstructorInvocation_superKeyword != 0)
        _result["superConstructorInvocation_superKeyword"] =
            superConstructorInvocation_superKeyword;
      if (superConstructorInvocation_elementType != null)
        _result["superConstructorInvocation_elementType"] =
            superConstructorInvocation_elementType.toJson();
      if (superConstructorInvocation_period != 0)
        _result["superConstructorInvocation_period"] =
            superConstructorInvocation_period;
    }
    if (kind == idl.LinkedNodeKind.throwExpression) {
      if (throwExpression_expression != null)
        _result["throwExpression_expression"] =
            throwExpression_expression.toJson();
      if (throwExpression_throwKeyword != 0)
        _result["throwExpression_throwKeyword"] = throwExpression_throwKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.typeName) {
      if (typeName_name != null)
        _result["typeName_name"] = typeName_name.toJson();
      if (typeName_question != 0)
        _result["typeName_question"] = typeName_question;
      if (typeName_typeArguments != null)
        _result["typeName_typeArguments"] = typeName_typeArguments.toJson();
      if (typeName_type != null)
        _result["typeName_type"] = typeName_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      if (variableDeclarationStatement_variables != null)
        _result["variableDeclarationStatement_variables"] =
            variableDeclarationStatement_variables.toJson();
      if (variableDeclarationStatement_semicolon != 0)
        _result["variableDeclarationStatement_semicolon"] =
            variableDeclarationStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.whileStatement) {
      if (whileStatement_body != null)
        _result["whileStatement_body"] = whileStatement_body.toJson();
      if (whileStatement_leftParenthesis != 0)
        _result["whileStatement_leftParenthesis"] =
            whileStatement_leftParenthesis;
      if (whileStatement_condition != null)
        _result["whileStatement_condition"] = whileStatement_condition.toJson();
      if (whileStatement_whileKeyword != 0)
        _result["whileStatement_whileKeyword"] = whileStatement_whileKeyword;
      if (whileStatement_rightParenthesis != 0)
        _result["whileStatement_rightParenthesis"] =
            whileStatement_rightParenthesis;
    }
    if (kind == idl.LinkedNodeKind.yieldStatement) {
      if (yieldStatement_expression != null)
        _result["yieldStatement_expression"] =
            yieldStatement_expression.toJson();
      if (yieldStatement_yieldKeyword != 0)
        _result["yieldStatement_yieldKeyword"] = yieldStatement_yieldKeyword;
      if (yieldStatement_semicolon != 0)
        _result["yieldStatement_semicolon"] = yieldStatement_semicolon;
      if (yieldStatement_star != 0)
        _result["yieldStatement_star"] = yieldStatement_star;
    }
    if (kind == idl.LinkedNodeKind.booleanLiteral) {
      if (booleanLiteral_literal != 0)
        _result["booleanLiteral_literal"] = booleanLiteral_literal;
      if (booleanLiteral_value != false)
        _result["booleanLiteral_value"] = booleanLiteral_value;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.doubleLiteral) {
      if (doubleLiteral_literal != 0)
        _result["doubleLiteral_literal"] = doubleLiteral_literal;
      if (doubleLiteral_value != 0.0)
        _result["doubleLiteral_value"] = doubleLiteral_value.isFinite
            ? doubleLiteral_value
            : doubleLiteral_value.toString();
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
      if (emptyFunctionBody_semicolon != 0)
        _result["emptyFunctionBody_semicolon"] = emptyFunctionBody_semicolon;
    }
    if (kind == idl.LinkedNodeKind.emptyStatement) {
      if (emptyStatement_semicolon != 0)
        _result["emptyStatement_semicolon"] = emptyStatement_semicolon;
    }
    if (kind == idl.LinkedNodeKind.integerLiteral) {
      if (integerLiteral_literal != 0)
        _result["integerLiteral_literal"] = integerLiteral_literal;
      if (integerLiteral_value != 0)
        _result["integerLiteral_value"] = integerLiteral_value;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.interpolationString) {
      if (interpolationString_token != 0)
        _result["interpolationString_token"] = interpolationString_token;
      if (interpolationString_value != '')
        _result["interpolationString_value"] = interpolationString_value;
    }
    if (kind == idl.LinkedNodeKind.nullLiteral) {
      if (nullLiteral_literal != 0)
        _result["nullLiteral_literal"] = nullLiteral_literal;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.rethrowExpression) {
      if (rethrowExpression_rethrowKeyword != 0)
        _result["rethrowExpression_rethrowKeyword"] =
            rethrowExpression_rethrowKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.scriptTag) {
      if (scriptTag_scriptTag != 0)
        _result["scriptTag_scriptTag"] = scriptTag_scriptTag;
    }
    if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      if (simpleIdentifier_element != 0)
        _result["simpleIdentifier_element"] = simpleIdentifier_element;
      if (simpleIdentifier_elementType != null)
        _result["simpleIdentifier_elementType"] =
            simpleIdentifier_elementType.toJson();
      if (simpleIdentifier_token != 0)
        _result["simpleIdentifier_token"] = simpleIdentifier_token;
      if (simpleIdentifier_isDeclaration != false)
        _result["simpleIdentifier_isDeclaration"] =
            simpleIdentifier_isDeclaration;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
      if (simpleStringLiteral_token != 0)
        _result["simpleStringLiteral_token"] = simpleStringLiteral_token;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
      if (simpleStringLiteral_value != '')
        _result["simpleStringLiteral_value"] = simpleStringLiteral_value;
    }
    if (kind == idl.LinkedNodeKind.superExpression) {
      if (superExpression_superKeyword != 0)
        _result["superExpression_superKeyword"] = superExpression_superKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.symbolLiteral) {
      if (symbolLiteral_poundSign != 0)
        _result["symbolLiteral_poundSign"] = symbolLiteral_poundSign;
      if (symbolLiteral_components.isNotEmpty)
        _result["symbolLiteral_components"] = symbolLiteral_components;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    if (kind == idl.LinkedNodeKind.thisExpression) {
      if (thisExpression_thisKeyword != 0)
        _result["thisExpression_thisKeyword"] = thisExpression_thisKeyword;
      if (expression_type != null)
        _result["expression_type"] = expression_type.toJson();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() {
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "functionDeclaration_functionExpression":
            functionDeclaration_functionExpression,
        "functionDeclaration_externalKeyword":
            functionDeclaration_externalKeyword,
        "functionDeclaration_returnType": functionDeclaration_returnType,
        "functionDeclaration_propertyKeyword":
            functionDeclaration_propertyKeyword,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionExpression) {
      return {
        "actualReturnType": actualReturnType,
        "functionExpression_body": functionExpression_body,
        "functionExpression_formalParameters":
            functionExpression_formalParameters,
        "functionExpression_typeParameters": functionExpression_typeParameters,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "functionTypeAlias_formalParameters":
            functionTypeAlias_formalParameters,
        "functionTypeAlias_returnType": functionTypeAlias_returnType,
        "functionTypeAlias_typeParameters": functionTypeAlias_typeParameters,
        "typeAlias_typedefKeyword": typeAlias_typedefKeyword,
        "typeAlias_semicolon": typeAlias_semicolon,
        "typeAlias_hasSelfReference": typeAlias_hasSelfReference,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
      };
    }
    if (kind == idl.LinkedNodeKind.genericFunctionType) {
      return {
        "actualReturnType": actualReturnType,
        "genericFunctionType_typeParameters":
            genericFunctionType_typeParameters,
        "genericFunctionType_functionKeyword":
            genericFunctionType_functionKeyword,
        "genericFunctionType_returnType": genericFunctionType_returnType,
        "genericFunctionType_id": genericFunctionType_id,
        "genericFunctionType_formalParameters":
            genericFunctionType_formalParameters,
        "genericFunctionType_question": genericFunctionType_question,
        "genericFunctionType_type": genericFunctionType_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "methodDeclaration_body": methodDeclaration_body,
        "methodDeclaration_externalKeyword": methodDeclaration_externalKeyword,
        "methodDeclaration_formalParameters":
            methodDeclaration_formalParameters,
        "methodDeclaration_operatorKeyword": methodDeclaration_operatorKeyword,
        "methodDeclaration_returnType": methodDeclaration_returnType,
        "methodDeclaration_modifierKeyword": methodDeclaration_modifierKeyword,
        "methodDeclaration_propertyKeyword": methodDeclaration_propertyKeyword,
        "methodDeclaration_actualProperty": methodDeclaration_actualProperty,
        "methodDeclaration_typeParameters": methodDeclaration_typeParameters,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "methodDeclaration_name": methodDeclaration_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      return {
        "actualType": actualType,
        "normalFormalParameter_metadata": normalFormalParameter_metadata,
        "fieldFormalParameter_type": fieldFormalParameter_type,
        "fieldFormalParameter_keyword": fieldFormalParameter_keyword,
        "fieldFormalParameter_typeParameters":
            fieldFormalParameter_typeParameters,
        "fieldFormalParameter_thisKeyword": fieldFormalParameter_thisKeyword,
        "fieldFormalParameter_formalParameters":
            fieldFormalParameter_formalParameters,
        "fieldFormalParameter_period": fieldFormalParameter_period,
        "normalFormalParameter_requiredKeyword":
            normalFormalParameter_requiredKeyword,
        "normalFormalParameter_covariantKeyword":
            normalFormalParameter_covariantKeyword,
        "inheritsCovariant": inheritsCovariant,
        "normalFormalParameter_identifier": normalFormalParameter_identifier,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "normalFormalParameter_comment": normalFormalParameter_comment,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      return {
        "actualType": actualType,
        "normalFormalParameter_metadata": normalFormalParameter_metadata,
        "functionTypedFormalParameter_formalParameters":
            functionTypedFormalParameter_formalParameters,
        "functionTypedFormalParameter_returnType":
            functionTypedFormalParameter_returnType,
        "functionTypedFormalParameter_typeParameters":
            functionTypedFormalParameter_typeParameters,
        "normalFormalParameter_requiredKeyword":
            normalFormalParameter_requiredKeyword,
        "normalFormalParameter_covariantKeyword":
            normalFormalParameter_covariantKeyword,
        "inheritsCovariant": inheritsCovariant,
        "normalFormalParameter_identifier": normalFormalParameter_identifier,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "normalFormalParameter_comment": normalFormalParameter_comment,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      return {
        "actualType": actualType,
        "normalFormalParameter_metadata": normalFormalParameter_metadata,
        "simpleFormalParameter_type": simpleFormalParameter_type,
        "simpleFormalParameter_keyword": simpleFormalParameter_keyword,
        "normalFormalParameter_requiredKeyword":
            normalFormalParameter_requiredKeyword,
        "normalFormalParameter_covariantKeyword":
            normalFormalParameter_covariantKeyword,
        "inheritsCovariant": inheritsCovariant,
        "normalFormalParameter_identifier": normalFormalParameter_identifier,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "normalFormalParameter_comment": normalFormalParameter_comment,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "topLevelTypeInferenceError": topLevelTypeInferenceError,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      return {
        "actualType": actualType,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "variableDeclaration_initializer": variableDeclaration_initializer,
        "variableDeclaration_equals": variableDeclaration_equals,
        "variableDeclaration_name": variableDeclaration_name,
        "inheritsCovariant": inheritsCovariant,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "topLevelTypeInferenceError": topLevelTypeInferenceError,
        "variableDeclaration_declaration": variableDeclaration_declaration,
      };
    }
    if (kind == idl.LinkedNodeKind.binaryExpression) {
      return {
        "binaryExpression_invokeType": binaryExpression_invokeType,
        "binaryExpression_leftOperand": binaryExpression_leftOperand,
        "binaryExpression_element": binaryExpression_element,
        "binaryExpression_rightOperand": binaryExpression_rightOperand,
        "binaryExpression_elementType": binaryExpression_elementType,
        "binaryExpression_operator": binaryExpression_operator,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionExpressionInvocation) {
      return {
        "invocationExpression_invokeType": invocationExpression_invokeType,
        "functionExpressionInvocation_function":
            functionExpressionInvocation_function,
        "invocationExpression_typeArguments":
            invocationExpression_typeArguments,
        "expression_type": expression_type,
        "invocationExpression_arguments": invocationExpression_arguments,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.methodInvocation) {
      return {
        "invocationExpression_invokeType": invocationExpression_invokeType,
        "methodInvocation_methodName": methodInvocation_methodName,
        "methodInvocation_operator": methodInvocation_operator,
        "methodInvocation_target": methodInvocation_target,
        "invocationExpression_typeArguments":
            invocationExpression_typeArguments,
        "expression_type": expression_type,
        "invocationExpression_arguments": invocationExpression_arguments,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      return {
        "adjacentStrings_strings": adjacentStrings_strings,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.argumentList) {
      return {
        "argumentList_arguments": argumentList_arguments,
        "argumentList_leftParenthesis": argumentList_leftParenthesis,
        "argumentList_rightParenthesis": argumentList_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.block) {
      return {
        "block_statements": block_statements,
        "block_leftBracket": block_leftBracket,
        "block_rightBracket": block_rightBracket,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.cascadeExpression) {
      return {
        "cascadeExpression_sections": cascadeExpression_sections,
        "cascadeExpression_target": cascadeExpression_target,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.comment) {
      return {
        "comment_references": comment_references,
        "comment_tokens": comment_tokens,
        "comment_type": comment_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      return {
        "compilationUnit_declarations": compilationUnit_declarations,
        "compilationUnit_scriptTag": compilationUnit_scriptTag,
        "compilationUnit_beginToken": compilationUnit_beginToken,
        "compilationUnit_endToken": compilationUnit_endToken,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "compilationUnit_directives": compilationUnit_directives,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      return {
        "constructorDeclaration_initializers":
            constructorDeclaration_initializers,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "constructorDeclaration_body": constructorDeclaration_body,
        "constructorDeclaration_constKeyword":
            constructorDeclaration_constKeyword,
        "constructorDeclaration_name": constructorDeclaration_name,
        "constructorDeclaration_factoryKeyword":
            constructorDeclaration_factoryKeyword,
        "constructorDeclaration_parameters": constructorDeclaration_parameters,
        "constructorDeclaration_externalKeyword":
            constructorDeclaration_externalKeyword,
        "constructorDeclaration_period": constructorDeclaration_period,
        "constructorDeclaration_separator": constructorDeclaration_separator,
        "constructorDeclaration_redirectedConstructor":
            constructorDeclaration_redirectedConstructor,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "constructorDeclaration_returnType": constructorDeclaration_returnType,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.dottedName) {
      return {
        "dottedName_components": dottedName_components,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      return {
        "enumDeclaration_constants": enumDeclaration_constants,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "enumDeclaration_enumKeyword": enumDeclaration_enumKeyword,
        "enumDeclaration_rightBracket": enumDeclaration_rightBracket,
        "enumDeclaration_leftBracket": enumDeclaration_leftBracket,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.formalParameterList) {
      return {
        "formalParameterList_parameters": formalParameterList_parameters,
        "formalParameterList_leftDelimiter": formalParameterList_leftDelimiter,
        "formalParameterList_rightDelimiter":
            formalParameterList_rightDelimiter,
        "formalParameterList_leftParenthesis":
            formalParameterList_leftParenthesis,
        "formalParameterList_rightParenthesis":
            formalParameterList_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      return {
        "hideCombinator_hiddenNames": hideCombinator_hiddenNames,
        "combinator_keyword": combinator_keyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.implementsClause) {
      return {
        "implementsClause_interfaces": implementsClause_interfaces,
        "implementsClause_implementsKeyword":
            implementsClause_implementsKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.labeledStatement) {
      return {
        "labeledStatement_labels": labeledStatement_labels,
        "labeledStatement_statement": labeledStatement_statement,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      return {
        "libraryIdentifier_components": libraryIdentifier_components,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.listLiteral) {
      return {
        "listLiteral_elements": listLiteral_elements,
        "listLiteral_leftBracket": listLiteral_leftBracket,
        "listLiteral_rightBracket": listLiteral_rightBracket,
        "typedLiteral_constKeyword": typedLiteral_constKeyword,
        "expression_type": expression_type,
        "typedLiteral_typeArguments": typedLiteral_typeArguments,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      return {
        "namespaceDirective_combinators": namespaceDirective_combinators,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "directive_keyword": directive_keyword,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
        "directive_semicolon": directive_semicolon,
        "namespaceDirective_configurations": namespaceDirective_configurations,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "namespaceDirective_selectedUri": namespaceDirective_selectedUri,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
      };
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      return {
        "namespaceDirective_combinators": namespaceDirective_combinators,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "importDirective_prefix": importDirective_prefix,
        "importDirective_asKeyword": importDirective_asKeyword,
        "importDirective_deferredKeyword": importDirective_deferredKeyword,
        "directive_keyword": directive_keyword,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
        "directive_semicolon": directive_semicolon,
        "namespaceDirective_configurations": namespaceDirective_configurations,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "namespaceDirective_selectedUri": namespaceDirective_selectedUri,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
      };
    }
    if (kind == idl.LinkedNodeKind.onClause) {
      return {
        "onClause_superclassConstraints": onClause_superclassConstraints,
        "onClause_onKeyword": onClause_onKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      return {
        "setOrMapLiteral_elements": setOrMapLiteral_elements,
        "setOrMapLiteral_leftBracket": setOrMapLiteral_leftBracket,
        "setOrMapLiteral_rightBracket": setOrMapLiteral_rightBracket,
        "typedLiteral_constKeyword": typedLiteral_constKeyword,
        "setOrMapLiteral_isMap": setOrMapLiteral_isMap,
        "expression_type": expression_type,
        "typedLiteral_typeArguments": typedLiteral_typeArguments,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "setOrMapLiteral_isSet": setOrMapLiteral_isSet,
      };
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      return {
        "showCombinator_shownNames": showCombinator_shownNames,
        "combinator_keyword": combinator_keyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.stringInterpolation) {
      return {
        "stringInterpolation_elements": stringInterpolation_elements,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.switchStatement) {
      return {
        "switchStatement_members": switchStatement_members,
        "switchStatement_leftParenthesis": switchStatement_leftParenthesis,
        "switchStatement_expression": switchStatement_expression,
        "switchStatement_switchKeyword": switchStatement_switchKeyword,
        "switchStatement_rightParenthesis": switchStatement_rightParenthesis,
        "switchStatement_leftBracket": switchStatement_leftBracket,
        "switchStatement_rightBracket": switchStatement_rightBracket,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.tryStatement) {
      return {
        "tryStatement_catchClauses": tryStatement_catchClauses,
        "tryStatement_body": tryStatement_body,
        "tryStatement_finallyKeyword": tryStatement_finallyKeyword,
        "tryStatement_finallyBlock": tryStatement_finallyBlock,
        "tryStatement_tryKeyword": tryStatement_tryKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.typeArgumentList) {
      return {
        "typeArgumentList_arguments": typeArgumentList_arguments,
        "typeArgumentList_leftBracket": typeArgumentList_leftBracket,
        "typeArgumentList_rightBracket": typeArgumentList_rightBracket,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.typeParameterList) {
      return {
        "typeParameterList_typeParameters": typeParameterList_typeParameters,
        "typeParameterList_leftBracket": typeParameterList_leftBracket,
        "typeParameterList_rightBracket": typeParameterList_rightBracket,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      return {
        "variableDeclarationList_variables": variableDeclarationList_variables,
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "variableDeclarationList_type": variableDeclarationList_type,
        "variableDeclarationList_keyword": variableDeclarationList_keyword,
        "variableDeclarationList_lateKeyword":
            variableDeclarationList_lateKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.withClause) {
      return {
        "withClause_mixinTypes": withClause_mixinTypes,
        "withClause_withKeyword": withClause_withKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "classDeclaration_extendsClause": classDeclaration_extendsClause,
        "classDeclaration_abstractKeyword": classDeclaration_abstractKeyword,
        "classDeclaration_withClause": classDeclaration_withClause,
        "classDeclaration_nativeClause": classDeclaration_nativeClause,
        "classDeclaration_classKeyword": classDeclaration_classKeyword,
        "classOrMixinDeclaration_rightBracket":
            classOrMixinDeclaration_rightBracket,
        "classOrMixinDeclaration_leftBracket":
            classOrMixinDeclaration_leftBracket,
        "classDeclaration_isDartObject": classDeclaration_isDartObject,
        "classOrMixinDeclaration_implementsClause":
            classOrMixinDeclaration_implementsClause,
        "classOrMixinDeclaration_members": classOrMixinDeclaration_members,
        "classOrMixinDeclaration_typeParameters":
            classOrMixinDeclaration_typeParameters,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
      };
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "classTypeAlias_typeParameters": classTypeAlias_typeParameters,
        "classTypeAlias_abstractKeyword": classTypeAlias_abstractKeyword,
        "classTypeAlias_superclass": classTypeAlias_superclass,
        "classTypeAlias_withClause": classTypeAlias_withClause,
        "classTypeAlias_equals": classTypeAlias_equals,
        "typeAlias_typedefKeyword": typeAlias_typedefKeyword,
        "typeAlias_semicolon": typeAlias_semicolon,
        "classTypeAlias_implementsClause": classTypeAlias_implementsClause,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
      };
    }
    if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "declaredIdentifier_identifier": declaredIdentifier_identifier,
        "declaredIdentifier_keyword": declaredIdentifier_keyword,
        "declaredIdentifier_type": declaredIdentifier_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "enumConstantDeclaration_name": enumConstantDeclaration_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "fieldDeclaration_fields": fieldDeclaration_fields,
        "fieldDeclaration_covariantKeyword": fieldDeclaration_covariantKeyword,
        "fieldDeclaration_staticKeyword": fieldDeclaration_staticKeyword,
        "fieldDeclaration_semicolon": fieldDeclaration_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "genericTypeAlias_typeParameters": genericTypeAlias_typeParameters,
        "genericTypeAlias_functionType": genericTypeAlias_functionType,
        "genericTypeAlias_equals": genericTypeAlias_equals,
        "typeAlias_typedefKeyword": typeAlias_typedefKeyword,
        "typeAlias_semicolon": typeAlias_semicolon,
        "typeAlias_hasSelfReference": typeAlias_hasSelfReference,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
      };
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "libraryDirective_name": libraryDirective_name,
        "directive_keyword": directive_keyword,
        "directive_semicolon": directive_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "mixinDeclaration_onClause": mixinDeclaration_onClause,
        "mixinDeclaration_mixinKeyword": mixinDeclaration_mixinKeyword,
        "classOrMixinDeclaration_rightBracket":
            classOrMixinDeclaration_rightBracket,
        "classOrMixinDeclaration_leftBracket":
            classOrMixinDeclaration_leftBracket,
        "classOrMixinDeclaration_implementsClause":
            classOrMixinDeclaration_implementsClause,
        "classOrMixinDeclaration_members": classOrMixinDeclaration_members,
        "classOrMixinDeclaration_typeParameters":
            classOrMixinDeclaration_typeParameters,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "namedCompilationUnitMember_name": namedCompilationUnitMember_name,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "mixinDeclaration_superInvokedNames":
            mixinDeclaration_superInvokedNames,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
      };
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "directive_keyword": directive_keyword,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
        "directive_semicolon": directive_semicolon,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
      };
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "partOfDirective_libraryName": partOfDirective_libraryName,
        "partOfDirective_uri": partOfDirective_uri,
        "partOfDirective_ofKeyword": partOfDirective_ofKeyword,
        "directive_keyword": directive_keyword,
        "directive_semicolon": directive_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "topLevelVariableDeclaration_variableList":
            topLevelVariableDeclaration_variableList,
        "topLevelVariableDeclaration_semicolon":
            topLevelVariableDeclaration_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      return {
        "annotatedNode_comment": annotatedNode_comment,
        "annotatedNode_metadata": annotatedNode_metadata,
        "typeParameter_bound": typeParameter_bound,
        "typeParameter_extendsKeyword": typeParameter_extendsKeyword,
        "typeParameter_name": typeParameter_name,
        "typeParameter_defaultType": typeParameter_defaultType,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.switchCase) {
      return {
        "switchMember_statements": switchMember_statements,
        "switchCase_expression": switchCase_expression,
        "switchMember_keyword": switchMember_keyword,
        "switchMember_colon": switchMember_colon,
        "switchMember_labels": switchMember_labels,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.switchDefault) {
      return {
        "switchMember_statements": switchMember_statements,
        "switchMember_keyword": switchMember_keyword,
        "switchMember_colon": switchMember_colon,
        "switchMember_labels": switchMember_labels,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.annotation) {
      return {
        "annotation_arguments": annotation_arguments,
        "annotation_atSign": annotation_atSign,
        "annotation_constructorName": annotation_constructorName,
        "annotation_element": annotation_element,
        "annotation_elementType": annotation_elementType,
        "annotation_name": annotation_name,
        "annotation_period": annotation_period,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.asExpression) {
      return {
        "asExpression_expression": asExpression_expression,
        "asExpression_asOperator": asExpression_asOperator,
        "asExpression_type": asExpression_type,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.assertInitializer) {
      return {
        "assertInitializer_condition": assertInitializer_condition,
        "assertInitializer_assertKeyword": assertInitializer_assertKeyword,
        "assertInitializer_message": assertInitializer_message,
        "assertInitializer_leftParenthesis": assertInitializer_leftParenthesis,
        "assertInitializer_comma": assertInitializer_comma,
        "assertInitializer_rightParenthesis":
            assertInitializer_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.assertStatement) {
      return {
        "assertStatement_condition": assertStatement_condition,
        "assertStatement_assertKeyword": assertStatement_assertKeyword,
        "assertStatement_message": assertStatement_message,
        "assertStatement_leftParenthesis": assertStatement_leftParenthesis,
        "assertStatement_comma": assertStatement_comma,
        "assertStatement_rightParenthesis": assertStatement_rightParenthesis,
        "assertStatement_semicolon": assertStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.assignmentExpression) {
      return {
        "assignmentExpression_leftHandSide": assignmentExpression_leftHandSide,
        "assignmentExpression_element": assignmentExpression_element,
        "assignmentExpression_rightHandSide":
            assignmentExpression_rightHandSide,
        "assignmentExpression_elementType": assignmentExpression_elementType,
        "assignmentExpression_operator": assignmentExpression_operator,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.awaitExpression) {
      return {
        "awaitExpression_expression": awaitExpression_expression,
        "awaitExpression_awaitKeyword": awaitExpression_awaitKeyword,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      return {
        "blockFunctionBody_block": blockFunctionBody_block,
        "blockFunctionBody_keyword": blockFunctionBody_keyword,
        "blockFunctionBody_star": blockFunctionBody_star,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.breakStatement) {
      return {
        "breakStatement_label": breakStatement_label,
        "breakStatement_breakKeyword": breakStatement_breakKeyword,
        "breakStatement_semicolon": breakStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.catchClause) {
      return {
        "catchClause_body": catchClause_body,
        "catchClause_catchKeyword": catchClause_catchKeyword,
        "catchClause_exceptionParameter": catchClause_exceptionParameter,
        "catchClause_leftParenthesis": catchClause_leftParenthesis,
        "catchClause_exceptionType": catchClause_exceptionType,
        "catchClause_comma": catchClause_comma,
        "catchClause_onKeyword": catchClause_onKeyword,
        "catchClause_rightParenthesis": catchClause_rightParenthesis,
        "catchClause_stackTraceParameter": catchClause_stackTraceParameter,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.commentReference) {
      return {
        "commentReference_identifier": commentReference_identifier,
        "commentReference_newKeyword": commentReference_newKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.conditionalExpression) {
      return {
        "conditionalExpression_condition": conditionalExpression_condition,
        "conditionalExpression_colon": conditionalExpression_colon,
        "conditionalExpression_elseExpression":
            conditionalExpression_elseExpression,
        "conditionalExpression_thenExpression":
            conditionalExpression_thenExpression,
        "conditionalExpression_question": conditionalExpression_question,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.configuration) {
      return {
        "configuration_name": configuration_name,
        "configuration_ifKeyword": configuration_ifKeyword,
        "configuration_value": configuration_value,
        "configuration_rightParenthesis": configuration_rightParenthesis,
        "configuration_uri": configuration_uri,
        "configuration_leftParenthesis": configuration_leftParenthesis,
        "configuration_equalToken": configuration_equalToken,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      return {
        "constructorFieldInitializer_expression":
            constructorFieldInitializer_expression,
        "constructorFieldInitializer_equals":
            constructorFieldInitializer_equals,
        "constructorFieldInitializer_fieldName":
            constructorFieldInitializer_fieldName,
        "constructorFieldInitializer_thisKeyword":
            constructorFieldInitializer_thisKeyword,
        "constructorFieldInitializer_period":
            constructorFieldInitializer_period,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorName) {
      return {
        "constructorName_name": constructorName_name,
        "constructorName_element": constructorName_element,
        "constructorName_type": constructorName_type,
        "constructorName_elementType": constructorName_elementType,
        "constructorName_period": constructorName_period,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.continueStatement) {
      return {
        "continueStatement_label": continueStatement_label,
        "continueStatement_continueKeyword": continueStatement_continueKeyword,
        "continueStatement_semicolon": continueStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      return {
        "defaultFormalParameter_defaultValue":
            defaultFormalParameter_defaultValue,
        "defaultFormalParameter_separator": defaultFormalParameter_separator,
        "defaultFormalParameter_parameter": defaultFormalParameter_parameter,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "defaultFormalParameter_kind": defaultFormalParameter_kind,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.doStatement) {
      return {
        "doStatement_body": doStatement_body,
        "doStatement_leftParenthesis": doStatement_leftParenthesis,
        "doStatement_condition": doStatement_condition,
        "doStatement_doKeyword": doStatement_doKeyword,
        "doStatement_rightParenthesis": doStatement_rightParenthesis,
        "doStatement_semicolon": doStatement_semicolon,
        "doStatement_whileKeyword": doStatement_whileKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      return {
        "expressionFunctionBody_expression": expressionFunctionBody_expression,
        "expressionFunctionBody_arrow": expressionFunctionBody_arrow,
        "expressionFunctionBody_semicolon": expressionFunctionBody_semicolon,
        "expressionFunctionBody_keyword": expressionFunctionBody_keyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.expressionStatement) {
      return {
        "expressionStatement_expression": expressionStatement_expression,
        "expressionStatement_semicolon": expressionStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.extendsClause) {
      return {
        "extendsClause_superclass": extendsClause_superclass,
        "extendsClause_extendsKeyword": extendsClause_extendsKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      return {
        "forEachParts_iterable": forEachParts_iterable,
        "forEachParts_inKeyword": forEachParts_inKeyword,
        "forEachPartsWithDeclaration_loopVariable":
            forEachPartsWithDeclaration_loopVariable,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      return {
        "forEachParts_iterable": forEachParts_iterable,
        "forEachParts_inKeyword": forEachParts_inKeyword,
        "forEachPartsWithIdentifier_identifier":
            forEachPartsWithIdentifier_identifier,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forElement) {
      return {
        "forMixin_forLoopParts": forMixin_forLoopParts,
        "forMixin_awaitKeyword": forMixin_awaitKeyword,
        "forElement_body": forElement_body,
        "forMixin_leftParenthesis": forMixin_leftParenthesis,
        "forMixin_forKeyword": forMixin_forKeyword,
        "forMixin_rightParenthesis": forMixin_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forStatement) {
      return {
        "forMixin_forLoopParts": forMixin_forLoopParts,
        "forMixin_awaitKeyword": forMixin_awaitKeyword,
        "forStatement_body": forStatement_body,
        "forMixin_leftParenthesis": forMixin_leftParenthesis,
        "forMixin_forKeyword": forMixin_forKeyword,
        "forMixin_rightParenthesis": forMixin_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      return {
        "forParts_condition": forParts_condition,
        "forParts_leftSeparator": forParts_leftSeparator,
        "forPartsWithDeclarations_variables":
            forPartsWithDeclarations_variables,
        "forParts_rightSeparator": forParts_rightSeparator,
        "forParts_updaters": forParts_updaters,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      return {
        "forParts_condition": forParts_condition,
        "forParts_leftSeparator": forParts_leftSeparator,
        "forPartsWithExpression_initialization":
            forPartsWithExpression_initialization,
        "forParts_rightSeparator": forParts_rightSeparator,
        "forParts_updaters": forParts_updaters,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      return {
        "functionDeclarationStatement_functionDeclaration":
            functionDeclarationStatement_functionDeclaration,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.ifElement) {
      return {
        "ifMixin_condition": ifMixin_condition,
        "ifMixin_elseKeyword": ifMixin_elseKeyword,
        "ifMixin_leftParenthesis": ifMixin_leftParenthesis,
        "ifElement_thenElement": ifElement_thenElement,
        "ifMixin_ifKeyword": ifMixin_ifKeyword,
        "ifMixin_rightParenthesis": ifMixin_rightParenthesis,
        "ifElement_elseElement": ifElement_elseElement,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.ifStatement) {
      return {
        "ifMixin_condition": ifMixin_condition,
        "ifMixin_elseKeyword": ifMixin_elseKeyword,
        "ifStatement_elseStatement": ifStatement_elseStatement,
        "ifMixin_leftParenthesis": ifMixin_leftParenthesis,
        "ifStatement_thenStatement": ifStatement_thenStatement,
        "ifMixin_ifKeyword": ifMixin_ifKeyword,
        "ifMixin_rightParenthesis": ifMixin_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.indexExpression) {
      return {
        "indexExpression_index": indexExpression_index,
        "indexExpression_element": indexExpression_element,
        "indexExpression_target": indexExpression_target,
        "indexExpression_leftBracket": indexExpression_leftBracket,
        "indexExpression_elementType": indexExpression_elementType,
        "indexExpression_period": indexExpression_period,
        "indexExpression_rightBracket": indexExpression_rightBracket,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      return {
        "instanceCreationExpression_arguments":
            instanceCreationExpression_arguments,
        "instanceCreationExpression_keyword":
            instanceCreationExpression_keyword,
        "instanceCreationExpression_constructorName":
            instanceCreationExpression_constructorName,
        "instanceCreationExpression_typeArguments":
            instanceCreationExpression_typeArguments,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.interpolationExpression) {
      return {
        "interpolationExpression_expression":
            interpolationExpression_expression,
        "interpolationExpression_leftBracket":
            interpolationExpression_leftBracket,
        "interpolationExpression_rightBracket":
            interpolationExpression_rightBracket,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.isExpression) {
      return {
        "isExpression_expression": isExpression_expression,
        "isExpression_isOperator": isExpression_isOperator,
        "isExpression_type": isExpression_type,
        "isExpression_notOperator": isExpression_notOperator,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.label) {
      return {
        "label_label": label_label,
        "label_colon": label_colon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      return {
        "mapLiteralEntry_key": mapLiteralEntry_key,
        "mapLiteralEntry_separator": mapLiteralEntry_separator,
        "mapLiteralEntry_value": mapLiteralEntry_value,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.namedExpression) {
      return {
        "namedExpression_expression": namedExpression_expression,
        "namedExpression_name": namedExpression_name,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.nativeClause) {
      return {
        "nativeClause_name": nativeClause_name,
        "nativeClause_nativeKeyword": nativeClause_nativeKeyword,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      return {
        "nativeFunctionBody_stringLiteral": nativeFunctionBody_stringLiteral,
        "nativeFunctionBody_nativeKeyword": nativeFunctionBody_nativeKeyword,
        "nativeFunctionBody_semicolon": nativeFunctionBody_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      return {
        "parenthesizedExpression_expression":
            parenthesizedExpression_expression,
        "parenthesizedExpression_leftParenthesis":
            parenthesizedExpression_leftParenthesis,
        "parenthesizedExpression_rightParenthesis":
            parenthesizedExpression_rightParenthesis,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.postfixExpression) {
      return {
        "postfixExpression_operand": postfixExpression_operand,
        "postfixExpression_element": postfixExpression_element,
        "postfixExpression_elementType": postfixExpression_elementType,
        "postfixExpression_operator": postfixExpression_operator,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      return {
        "prefixedIdentifier_identifier": prefixedIdentifier_identifier,
        "prefixedIdentifier_period": prefixedIdentifier_period,
        "prefixedIdentifier_prefix": prefixedIdentifier_prefix,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.prefixExpression) {
      return {
        "prefixExpression_operand": prefixExpression_operand,
        "prefixExpression_element": prefixExpression_element,
        "prefixExpression_elementType": prefixExpression_elementType,
        "prefixExpression_operator": prefixExpression_operator,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.propertyAccess) {
      return {
        "propertyAccess_propertyName": propertyAccess_propertyName,
        "propertyAccess_operator": propertyAccess_operator,
        "propertyAccess_target": propertyAccess_target,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      return {
        "redirectingConstructorInvocation_arguments":
            redirectingConstructorInvocation_arguments,
        "redirectingConstructorInvocation_element":
            redirectingConstructorInvocation_element,
        "redirectingConstructorInvocation_constructorName":
            redirectingConstructorInvocation_constructorName,
        "redirectingConstructorInvocation_thisKeyword":
            redirectingConstructorInvocation_thisKeyword,
        "redirectingConstructorInvocation_elementType":
            redirectingConstructorInvocation_elementType,
        "redirectingConstructorInvocation_period":
            redirectingConstructorInvocation_period,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.returnStatement) {
      return {
        "returnStatement_expression": returnStatement_expression,
        "returnStatement_returnKeyword": returnStatement_returnKeyword,
        "returnStatement_semicolon": returnStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.spreadElement) {
      return {
        "spreadElement_expression": spreadElement_expression,
        "spreadElement_spreadOperator": spreadElement_spreadOperator,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      return {
        "superConstructorInvocation_arguments":
            superConstructorInvocation_arguments,
        "superConstructorInvocation_element":
            superConstructorInvocation_element,
        "superConstructorInvocation_constructorName":
            superConstructorInvocation_constructorName,
        "superConstructorInvocation_superKeyword":
            superConstructorInvocation_superKeyword,
        "superConstructorInvocation_elementType":
            superConstructorInvocation_elementType,
        "superConstructorInvocation_period": superConstructorInvocation_period,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.throwExpression) {
      return {
        "throwExpression_expression": throwExpression_expression,
        "throwExpression_throwKeyword": throwExpression_throwKeyword,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.typeName) {
      return {
        "typeName_name": typeName_name,
        "typeName_question": typeName_question,
        "typeName_typeArguments": typeName_typeArguments,
        "typeName_type": typeName_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      return {
        "variableDeclarationStatement_variables":
            variableDeclarationStatement_variables,
        "variableDeclarationStatement_semicolon":
            variableDeclarationStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.whileStatement) {
      return {
        "whileStatement_body": whileStatement_body,
        "whileStatement_leftParenthesis": whileStatement_leftParenthesis,
        "whileStatement_condition": whileStatement_condition,
        "whileStatement_whileKeyword": whileStatement_whileKeyword,
        "whileStatement_rightParenthesis": whileStatement_rightParenthesis,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.yieldStatement) {
      return {
        "yieldStatement_expression": yieldStatement_expression,
        "yieldStatement_yieldKeyword": yieldStatement_yieldKeyword,
        "yieldStatement_semicolon": yieldStatement_semicolon,
        "yieldStatement_star": yieldStatement_star,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.booleanLiteral) {
      return {
        "booleanLiteral_literal": booleanLiteral_literal,
        "booleanLiteral_value": booleanLiteral_value,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.doubleLiteral) {
      return {
        "doubleLiteral_literal": doubleLiteral_literal,
        "doubleLiteral_value": doubleLiteral_value,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
      return {
        "emptyFunctionBody_semicolon": emptyFunctionBody_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.emptyStatement) {
      return {
        "emptyStatement_semicolon": emptyStatement_semicolon,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.integerLiteral) {
      return {
        "integerLiteral_literal": integerLiteral_literal,
        "integerLiteral_value": integerLiteral_value,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.interpolationString) {
      return {
        "interpolationString_token": interpolationString_token,
        "interpolationString_value": interpolationString_value,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.nullLiteral) {
      return {
        "nullLiteral_literal": nullLiteral_literal,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.rethrowExpression) {
      return {
        "rethrowExpression_rethrowKeyword": rethrowExpression_rethrowKeyword,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.scriptTag) {
      return {
        "scriptTag_scriptTag": scriptTag_scriptTag,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      return {
        "simpleIdentifier_element": simpleIdentifier_element,
        "simpleIdentifier_elementType": simpleIdentifier_elementType,
        "simpleIdentifier_token": simpleIdentifier_token,
        "simpleIdentifier_isDeclaration": simpleIdentifier_isDeclaration,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
      return {
        "simpleStringLiteral_token": simpleStringLiteral_token,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "simpleStringLiteral_value": simpleStringLiteral_value,
      };
    }
    if (kind == idl.LinkedNodeKind.superExpression) {
      return {
        "superExpression_superKeyword": superExpression_superKeyword,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.symbolLiteral) {
      return {
        "symbolLiteral_poundSign": symbolLiteral_poundSign,
        "symbolLiteral_components": symbolLiteral_components,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.thisExpression) {
      return {
        "thisExpression_thisKeyword": thisExpression_thisKeyword,
        "expression_type": expression_type,
        "isSynthetic": isSynthetic,
        "kind": kind,
      };
    }
    throw StateError("Unexpected $kind");
  }

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeBundleBuilder extends Object
    with _LinkedNodeBundleMixin
    implements idl.LinkedNodeBundle {
  List<LinkedNodeLibraryBuilder> _libraries;
  LinkedNodeReferencesBuilder _references;

  @override
  List<LinkedNodeLibraryBuilder> get libraries =>
      _libraries ??= <LinkedNodeLibraryBuilder>[];

  set libraries(List<LinkedNodeLibraryBuilder> value) {
    this._libraries = value;
  }

  @override
  LinkedNodeReferencesBuilder get references => _references;

  /// The shared list of references used in the [libraries].
  set references(LinkedNodeReferencesBuilder value) {
    this._references = value;
  }

  LinkedNodeBundleBuilder(
      {List<LinkedNodeLibraryBuilder> libraries,
      LinkedNodeReferencesBuilder references})
      : _libraries = libraries,
        _references = references;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _libraries?.forEach((b) => b.flushInformative());
    _references?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._references != null);
    this._references?.collectApiSignature(signature);
    if (this._libraries == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._libraries.length);
      for (var x in this._libraries) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "LNBn");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_libraries;
    fb.Offset offset_references;
    if (!(_libraries == null || _libraries.isEmpty)) {
      offset_libraries = fbBuilder
          .writeList(_libraries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_references != null) {
      offset_references = _references.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_libraries != null) {
      fbBuilder.addOffset(1, offset_libraries);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(0, offset_references);
    }
    return fbBuilder.endTable();
  }
}

idl.LinkedNodeBundle readLinkedNodeBundle(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _LinkedNodeBundleReader().read(rootRef, 0);
}

class _LinkedNodeBundleReader extends fb.TableReader<_LinkedNodeBundleImpl> {
  const _LinkedNodeBundleReader();

  @override
  _LinkedNodeBundleImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeBundleImpl(bc, offset);
}

class _LinkedNodeBundleImpl extends Object
    with _LinkedNodeBundleMixin
    implements idl.LinkedNodeBundle {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeBundleImpl(this._bc, this._bcOffset);

  List<idl.LinkedNodeLibrary> _libraries;
  idl.LinkedNodeReferences _references;

  @override
  List<idl.LinkedNodeLibrary> get libraries {
    _libraries ??= const fb.ListReader<idl.LinkedNodeLibrary>(
            const _LinkedNodeLibraryReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.LinkedNodeLibrary>[]);
    return _libraries;
  }

  @override
  idl.LinkedNodeReferences get references {
    _references ??=
        const _LinkedNodeReferencesReader().vTableGet(_bc, _bcOffset, 0, null);
    return _references;
  }
}

abstract class _LinkedNodeBundleMixin implements idl.LinkedNodeBundle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (libraries.isNotEmpty)
      _result["libraries"] =
          libraries.map((_value) => _value.toJson()).toList();
    if (references != null) _result["references"] = references.toJson();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "libraries": libraries,
        "references": references,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeLibraryBuilder extends Object
    with _LinkedNodeLibraryMixin
    implements idl.LinkedNodeLibrary {
  List<int> _exports;
  String _name;
  int _nameLength;
  int _nameOffset;
  List<LinkedNodeUnitBuilder> _units;
  String _uriStr;

  @override
  List<int> get exports => _exports ??= <int>[];

  set exports(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._exports = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  int get nameLength => _nameLength ??= 0;

  set nameLength(int value) {
    assert(value == null || value >= 0);
    this._nameLength = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<LinkedNodeUnitBuilder> get units => _units ??= <LinkedNodeUnitBuilder>[];

  set units(List<LinkedNodeUnitBuilder> value) {
    this._units = value;
  }

  @override
  String get uriStr => _uriStr ??= '';

  set uriStr(String value) {
    this._uriStr = value;
  }

  LinkedNodeLibraryBuilder(
      {List<int> exports,
      String name,
      int nameLength,
      int nameOffset,
      List<LinkedNodeUnitBuilder> units,
      String uriStr})
      : _exports = exports,
        _name = name,
        _nameLength = nameLength,
        _nameOffset = nameOffset,
        _units = units,
        _uriStr = uriStr;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _units?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uriStr ?? '');
    if (this._units == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._units.length);
      for (var x in this._units) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        signature.addInt(x);
      }
    }
    signature.addString(this._name ?? '');
    signature.addInt(this._nameOffset ?? 0);
    signature.addInt(this._nameLength ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_exports;
    fb.Offset offset_name;
    fb.Offset offset_units;
    fb.Offset offset_uriStr;
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder.writeListUint32(_exports);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_units == null || _units.isEmpty)) {
      offset_units =
          fbBuilder.writeList(_units.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_uriStr != null) {
      offset_uriStr = fbBuilder.writeString(_uriStr);
    }
    fbBuilder.startTable();
    if (offset_exports != null) {
      fbBuilder.addOffset(2, offset_exports);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(3, offset_name);
    }
    if (_nameLength != null && _nameLength != 0) {
      fbBuilder.addUint32(5, _nameLength);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(4, _nameOffset);
    }
    if (offset_units != null) {
      fbBuilder.addOffset(1, offset_units);
    }
    if (offset_uriStr != null) {
      fbBuilder.addOffset(0, offset_uriStr);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeLibraryReader extends fb.TableReader<_LinkedNodeLibraryImpl> {
  const _LinkedNodeLibraryReader();

  @override
  _LinkedNodeLibraryImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeLibraryImpl(bc, offset);
}

class _LinkedNodeLibraryImpl extends Object
    with _LinkedNodeLibraryMixin
    implements idl.LinkedNodeLibrary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeLibraryImpl(this._bc, this._bcOffset);

  List<int> _exports;
  String _name;
  int _nameLength;
  int _nameOffset;
  List<idl.LinkedNodeUnit> _units;
  String _uriStr;

  @override
  List<int> get exports {
    _exports ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _exports;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _name;
  }

  @override
  int get nameLength {
    _nameLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _nameLength;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 4, 0);
    return _nameOffset;
  }

  @override
  List<idl.LinkedNodeUnit> get units {
    _units ??=
        const fb.ListReader<idl.LinkedNodeUnit>(const _LinkedNodeUnitReader())
            .vTableGet(_bc, _bcOffset, 1, const <idl.LinkedNodeUnit>[]);
    return _units;
  }

  @override
  String get uriStr {
    _uriStr ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uriStr;
  }
}

abstract class _LinkedNodeLibraryMixin implements idl.LinkedNodeLibrary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (exports.isNotEmpty) _result["exports"] = exports;
    if (name != '') _result["name"] = name;
    if (nameLength != 0) _result["nameLength"] = nameLength;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (units.isNotEmpty)
      _result["units"] = units.map((_value) => _value.toJson()).toList();
    if (uriStr != '') _result["uriStr"] = uriStr;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "exports": exports,
        "name": name,
        "nameLength": nameLength,
        "nameOffset": nameOffset,
        "units": units,
        "uriStr": uriStr,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeReferencesBuilder extends Object
    with _LinkedNodeReferencesMixin
    implements idl.LinkedNodeReferences {
  List<String> _name;
  List<int> _parent;

  @override
  List<String> get name => _name ??= <String>[];

  set name(List<String> value) {
    this._name = value;
  }

  @override
  List<int> get parent => _parent ??= <int>[];

  set parent(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._parent = value;
  }

  LinkedNodeReferencesBuilder({List<String> name, List<int> parent})
      : _name = name,
        _parent = parent;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._parent == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parent.length);
      for (var x in this._parent) {
        signature.addInt(x);
      }
    }
    if (this._name == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._name.length);
      for (var x in this._name) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_parent;
    if (!(_name == null || _name.isEmpty)) {
      offset_name = fbBuilder
          .writeList(_name.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_parent == null || _parent.isEmpty)) {
      offset_parent = fbBuilder.writeListUint32(_parent);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(1, offset_name);
    }
    if (offset_parent != null) {
      fbBuilder.addOffset(0, offset_parent);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeReferencesReader
    extends fb.TableReader<_LinkedNodeReferencesImpl> {
  const _LinkedNodeReferencesReader();

  @override
  _LinkedNodeReferencesImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeReferencesImpl(bc, offset);
}

class _LinkedNodeReferencesImpl extends Object
    with _LinkedNodeReferencesMixin
    implements idl.LinkedNodeReferences {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeReferencesImpl(this._bc, this._bcOffset);

  List<String> _name;
  List<int> _parent;

  @override
  List<String> get name {
    _name ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _name;
  }

  @override
  List<int> get parent {
    _parent ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _parent;
  }
}

abstract class _LinkedNodeReferencesMixin implements idl.LinkedNodeReferences {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (name.isNotEmpty) _result["name"] = name;
    if (parent.isNotEmpty) _result["parent"] = parent;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "name": name,
        "parent": parent,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeTypeBuilder extends Object
    with _LinkedNodeTypeMixin
    implements idl.LinkedNodeType {
  List<LinkedNodeTypeFormalParameterBuilder> _functionFormalParameters;
  LinkedNodeTypeBuilder _functionReturnType;
  List<LinkedNodeTypeTypeParameterBuilder> _functionTypeParameters;
  int _genericTypeAliasReference;
  List<LinkedNodeTypeBuilder> _genericTypeAliasTypeArguments;
  int _interfaceClass;
  List<LinkedNodeTypeBuilder> _interfaceTypeArguments;
  idl.LinkedNodeTypeKind _kind;
  idl.EntityRefNullabilitySuffix _nullabilitySuffix;
  int _typeParameterElement;
  int _typeParameterId;

  @override
  List<LinkedNodeTypeFormalParameterBuilder> get functionFormalParameters =>
      _functionFormalParameters ??= <LinkedNodeTypeFormalParameterBuilder>[];

  set functionFormalParameters(
      List<LinkedNodeTypeFormalParameterBuilder> value) {
    this._functionFormalParameters = value;
  }

  @override
  LinkedNodeTypeBuilder get functionReturnType => _functionReturnType;

  set functionReturnType(LinkedNodeTypeBuilder value) {
    this._functionReturnType = value;
  }

  @override
  List<LinkedNodeTypeTypeParameterBuilder> get functionTypeParameters =>
      _functionTypeParameters ??= <LinkedNodeTypeTypeParameterBuilder>[];

  set functionTypeParameters(List<LinkedNodeTypeTypeParameterBuilder> value) {
    this._functionTypeParameters = value;
  }

  @override
  int get genericTypeAliasReference => _genericTypeAliasReference ??= 0;

  set genericTypeAliasReference(int value) {
    assert(value == null || value >= 0);
    this._genericTypeAliasReference = value;
  }

  @override
  List<LinkedNodeTypeBuilder> get genericTypeAliasTypeArguments =>
      _genericTypeAliasTypeArguments ??= <LinkedNodeTypeBuilder>[];

  set genericTypeAliasTypeArguments(List<LinkedNodeTypeBuilder> value) {
    this._genericTypeAliasTypeArguments = value;
  }

  @override
  int get interfaceClass => _interfaceClass ??= 0;

  /// Reference to a [LinkedNodeReferences].
  set interfaceClass(int value) {
    assert(value == null || value >= 0);
    this._interfaceClass = value;
  }

  @override
  List<LinkedNodeTypeBuilder> get interfaceTypeArguments =>
      _interfaceTypeArguments ??= <LinkedNodeTypeBuilder>[];

  set interfaceTypeArguments(List<LinkedNodeTypeBuilder> value) {
    this._interfaceTypeArguments = value;
  }

  @override
  idl.LinkedNodeTypeKind get kind => _kind ??= idl.LinkedNodeTypeKind.bottom;

  set kind(idl.LinkedNodeTypeKind value) {
    this._kind = value;
  }

  @override
  idl.EntityRefNullabilitySuffix get nullabilitySuffix =>
      _nullabilitySuffix ??= idl.EntityRefNullabilitySuffix.starOrIrrelevant;

  set nullabilitySuffix(idl.EntityRefNullabilitySuffix value) {
    this._nullabilitySuffix = value;
  }

  @override
  int get typeParameterElement => _typeParameterElement ??= 0;

  set typeParameterElement(int value) {
    assert(value == null || value >= 0);
    this._typeParameterElement = value;
  }

  @override
  int get typeParameterId => _typeParameterId ??= 0;

  set typeParameterId(int value) {
    assert(value == null || value >= 0);
    this._typeParameterId = value;
  }

  LinkedNodeTypeBuilder(
      {List<LinkedNodeTypeFormalParameterBuilder> functionFormalParameters,
      LinkedNodeTypeBuilder functionReturnType,
      List<LinkedNodeTypeTypeParameterBuilder> functionTypeParameters,
      int genericTypeAliasReference,
      List<LinkedNodeTypeBuilder> genericTypeAliasTypeArguments,
      int interfaceClass,
      List<LinkedNodeTypeBuilder> interfaceTypeArguments,
      idl.LinkedNodeTypeKind kind,
      idl.EntityRefNullabilitySuffix nullabilitySuffix,
      int typeParameterElement,
      int typeParameterId})
      : _functionFormalParameters = functionFormalParameters,
        _functionReturnType = functionReturnType,
        _functionTypeParameters = functionTypeParameters,
        _genericTypeAliasReference = genericTypeAliasReference,
        _genericTypeAliasTypeArguments = genericTypeAliasTypeArguments,
        _interfaceClass = interfaceClass,
        _interfaceTypeArguments = interfaceTypeArguments,
        _kind = kind,
        _nullabilitySuffix = nullabilitySuffix,
        _typeParameterElement = typeParameterElement,
        _typeParameterId = typeParameterId;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _functionFormalParameters?.forEach((b) => b.flushInformative());
    _functionReturnType?.flushInformative();
    _functionTypeParameters?.forEach((b) => b.flushInformative());
    _genericTypeAliasTypeArguments?.forEach((b) => b.flushInformative());
    _interfaceTypeArguments?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._functionFormalParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._functionFormalParameters.length);
      for (var x in this._functionFormalParameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._functionReturnType != null);
    this._functionReturnType?.collectApiSignature(signature);
    if (this._functionTypeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._functionTypeParameters.length);
      for (var x in this._functionTypeParameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._interfaceClass ?? 0);
    if (this._interfaceTypeArguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._interfaceTypeArguments.length);
      for (var x in this._interfaceTypeArguments) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addInt(this._typeParameterElement ?? 0);
    signature.addInt(this._typeParameterId ?? 0);
    signature.addInt(this._genericTypeAliasReference ?? 0);
    if (this._genericTypeAliasTypeArguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._genericTypeAliasTypeArguments.length);
      for (var x in this._genericTypeAliasTypeArguments) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(
        this._nullabilitySuffix == null ? 0 : this._nullabilitySuffix.index);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_functionFormalParameters;
    fb.Offset offset_functionReturnType;
    fb.Offset offset_functionTypeParameters;
    fb.Offset offset_genericTypeAliasTypeArguments;
    fb.Offset offset_interfaceTypeArguments;
    if (!(_functionFormalParameters == null ||
        _functionFormalParameters.isEmpty)) {
      offset_functionFormalParameters = fbBuilder.writeList(
          _functionFormalParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_functionReturnType != null) {
      offset_functionReturnType = _functionReturnType.finish(fbBuilder);
    }
    if (!(_functionTypeParameters == null || _functionTypeParameters.isEmpty)) {
      offset_functionTypeParameters = fbBuilder.writeList(
          _functionTypeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_genericTypeAliasTypeArguments == null ||
        _genericTypeAliasTypeArguments.isEmpty)) {
      offset_genericTypeAliasTypeArguments = fbBuilder.writeList(
          _genericTypeAliasTypeArguments
              .map((b) => b.finish(fbBuilder))
              .toList());
    }
    if (!(_interfaceTypeArguments == null || _interfaceTypeArguments.isEmpty)) {
      offset_interfaceTypeArguments = fbBuilder.writeList(
          _interfaceTypeArguments.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_functionFormalParameters != null) {
      fbBuilder.addOffset(0, offset_functionFormalParameters);
    }
    if (offset_functionReturnType != null) {
      fbBuilder.addOffset(1, offset_functionReturnType);
    }
    if (offset_functionTypeParameters != null) {
      fbBuilder.addOffset(2, offset_functionTypeParameters);
    }
    if (_genericTypeAliasReference != null && _genericTypeAliasReference != 0) {
      fbBuilder.addUint32(8, _genericTypeAliasReference);
    }
    if (offset_genericTypeAliasTypeArguments != null) {
      fbBuilder.addOffset(9, offset_genericTypeAliasTypeArguments);
    }
    if (_interfaceClass != null && _interfaceClass != 0) {
      fbBuilder.addUint32(3, _interfaceClass);
    }
    if (offset_interfaceTypeArguments != null) {
      fbBuilder.addOffset(4, offset_interfaceTypeArguments);
    }
    if (_kind != null && _kind != idl.LinkedNodeTypeKind.bottom) {
      fbBuilder.addUint8(5, _kind.index);
    }
    if (_nullabilitySuffix != null &&
        _nullabilitySuffix != idl.EntityRefNullabilitySuffix.starOrIrrelevant) {
      fbBuilder.addUint8(10, _nullabilitySuffix.index);
    }
    if (_typeParameterElement != null && _typeParameterElement != 0) {
      fbBuilder.addUint32(6, _typeParameterElement);
    }
    if (_typeParameterId != null && _typeParameterId != 0) {
      fbBuilder.addUint32(7, _typeParameterId);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeTypeReader extends fb.TableReader<_LinkedNodeTypeImpl> {
  const _LinkedNodeTypeReader();

  @override
  _LinkedNodeTypeImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeTypeImpl(bc, offset);
}

class _LinkedNodeTypeImpl extends Object
    with _LinkedNodeTypeMixin
    implements idl.LinkedNodeType {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeTypeImpl(this._bc, this._bcOffset);

  List<idl.LinkedNodeTypeFormalParameter> _functionFormalParameters;
  idl.LinkedNodeType _functionReturnType;
  List<idl.LinkedNodeTypeTypeParameter> _functionTypeParameters;
  int _genericTypeAliasReference;
  List<idl.LinkedNodeType> _genericTypeAliasTypeArguments;
  int _interfaceClass;
  List<idl.LinkedNodeType> _interfaceTypeArguments;
  idl.LinkedNodeTypeKind _kind;
  idl.EntityRefNullabilitySuffix _nullabilitySuffix;
  int _typeParameterElement;
  int _typeParameterId;

  @override
  List<idl.LinkedNodeTypeFormalParameter> get functionFormalParameters {
    _functionFormalParameters ??=
        const fb.ListReader<idl.LinkedNodeTypeFormalParameter>(
                const _LinkedNodeTypeFormalParameterReader())
            .vTableGet(
                _bc, _bcOffset, 0, const <idl.LinkedNodeTypeFormalParameter>[]);
    return _functionFormalParameters;
  }

  @override
  idl.LinkedNodeType get functionReturnType {
    _functionReturnType ??=
        const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 1, null);
    return _functionReturnType;
  }

  @override
  List<idl.LinkedNodeTypeTypeParameter> get functionTypeParameters {
    _functionTypeParameters ??=
        const fb.ListReader<idl.LinkedNodeTypeTypeParameter>(
                const _LinkedNodeTypeTypeParameterReader())
            .vTableGet(
                _bc, _bcOffset, 2, const <idl.LinkedNodeTypeTypeParameter>[]);
    return _functionTypeParameters;
  }

  @override
  int get genericTypeAliasReference {
    _genericTypeAliasReference ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 8, 0);
    return _genericTypeAliasReference;
  }

  @override
  List<idl.LinkedNodeType> get genericTypeAliasTypeArguments {
    _genericTypeAliasTypeArguments ??=
        const fb.ListReader<idl.LinkedNodeType>(const _LinkedNodeTypeReader())
            .vTableGet(_bc, _bcOffset, 9, const <idl.LinkedNodeType>[]);
    return _genericTypeAliasTypeArguments;
  }

  @override
  int get interfaceClass {
    _interfaceClass ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _interfaceClass;
  }

  @override
  List<idl.LinkedNodeType> get interfaceTypeArguments {
    _interfaceTypeArguments ??=
        const fb.ListReader<idl.LinkedNodeType>(const _LinkedNodeTypeReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNodeType>[]);
    return _interfaceTypeArguments;
  }

  @override
  idl.LinkedNodeTypeKind get kind {
    _kind ??= const _LinkedNodeTypeKindReader()
        .vTableGet(_bc, _bcOffset, 5, idl.LinkedNodeTypeKind.bottom);
    return _kind;
  }

  @override
  idl.EntityRefNullabilitySuffix get nullabilitySuffix {
    _nullabilitySuffix ??= const _EntityRefNullabilitySuffixReader().vTableGet(
        _bc, _bcOffset, 10, idl.EntityRefNullabilitySuffix.starOrIrrelevant);
    return _nullabilitySuffix;
  }

  @override
  int get typeParameterElement {
    _typeParameterElement ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 6, 0);
    return _typeParameterElement;
  }

  @override
  int get typeParameterId {
    _typeParameterId ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 7, 0);
    return _typeParameterId;
  }
}

abstract class _LinkedNodeTypeMixin implements idl.LinkedNodeType {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (functionFormalParameters.isNotEmpty)
      _result["functionFormalParameters"] =
          functionFormalParameters.map((_value) => _value.toJson()).toList();
    if (functionReturnType != null)
      _result["functionReturnType"] = functionReturnType.toJson();
    if (functionTypeParameters.isNotEmpty)
      _result["functionTypeParameters"] =
          functionTypeParameters.map((_value) => _value.toJson()).toList();
    if (genericTypeAliasReference != 0)
      _result["genericTypeAliasReference"] = genericTypeAliasReference;
    if (genericTypeAliasTypeArguments.isNotEmpty)
      _result["genericTypeAliasTypeArguments"] = genericTypeAliasTypeArguments
          .map((_value) => _value.toJson())
          .toList();
    if (interfaceClass != 0) _result["interfaceClass"] = interfaceClass;
    if (interfaceTypeArguments.isNotEmpty)
      _result["interfaceTypeArguments"] =
          interfaceTypeArguments.map((_value) => _value.toJson()).toList();
    if (kind != idl.LinkedNodeTypeKind.bottom)
      _result["kind"] = kind.toString().split('.')[1];
    if (nullabilitySuffix != idl.EntityRefNullabilitySuffix.starOrIrrelevant)
      _result["nullabilitySuffix"] = nullabilitySuffix.toString().split('.')[1];
    if (typeParameterElement != 0)
      _result["typeParameterElement"] = typeParameterElement;
    if (typeParameterId != 0) _result["typeParameterId"] = typeParameterId;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "functionFormalParameters": functionFormalParameters,
        "functionReturnType": functionReturnType,
        "functionTypeParameters": functionTypeParameters,
        "genericTypeAliasReference": genericTypeAliasReference,
        "genericTypeAliasTypeArguments": genericTypeAliasTypeArguments,
        "interfaceClass": interfaceClass,
        "interfaceTypeArguments": interfaceTypeArguments,
        "kind": kind,
        "nullabilitySuffix": nullabilitySuffix,
        "typeParameterElement": typeParameterElement,
        "typeParameterId": typeParameterId,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeTypeFormalParameterBuilder extends Object
    with _LinkedNodeTypeFormalParameterMixin
    implements idl.LinkedNodeTypeFormalParameter {
  idl.LinkedNodeFormalParameterKind _kind;
  String _name;
  LinkedNodeTypeBuilder _type;

  @override
  idl.LinkedNodeFormalParameterKind get kind =>
      _kind ??= idl.LinkedNodeFormalParameterKind.requiredPositional;

  set kind(idl.LinkedNodeFormalParameterKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  LinkedNodeTypeBuilder get type => _type;

  set type(LinkedNodeTypeBuilder value) {
    this._type = value;
  }

  LinkedNodeTypeFormalParameterBuilder(
      {idl.LinkedNodeFormalParameterKind kind,
      String name,
      LinkedNodeTypeBuilder type})
      : _kind = kind,
        _name = name,
        _type = type;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _type?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addString(this._name ?? '');
    signature.addBool(this._type != null);
    this._type?.collectApiSignature(signature);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_type;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (_kind != null &&
        _kind != idl.LinkedNodeFormalParameterKind.requiredPositional) {
      fbBuilder.addUint8(0, _kind.index);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(1, offset_name);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(2, offset_type);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeTypeFormalParameterReader
    extends fb.TableReader<_LinkedNodeTypeFormalParameterImpl> {
  const _LinkedNodeTypeFormalParameterReader();

  @override
  _LinkedNodeTypeFormalParameterImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _LinkedNodeTypeFormalParameterImpl(bc, offset);
}

class _LinkedNodeTypeFormalParameterImpl extends Object
    with _LinkedNodeTypeFormalParameterMixin
    implements idl.LinkedNodeTypeFormalParameter {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeTypeFormalParameterImpl(this._bc, this._bcOffset);

  idl.LinkedNodeFormalParameterKind _kind;
  String _name;
  idl.LinkedNodeType _type;

  @override
  idl.LinkedNodeFormalParameterKind get kind {
    _kind ??= const _LinkedNodeFormalParameterKindReader().vTableGet(_bc,
        _bcOffset, 0, idl.LinkedNodeFormalParameterKind.requiredPositional);
    return _kind;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _name;
  }

  @override
  idl.LinkedNodeType get type {
    _type ??= const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 2, null);
    return _type;
  }
}

abstract class _LinkedNodeTypeFormalParameterMixin
    implements idl.LinkedNodeTypeFormalParameter {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (kind != idl.LinkedNodeFormalParameterKind.requiredPositional)
      _result["kind"] = kind.toString().split('.')[1];
    if (name != '') _result["name"] = name;
    if (type != null) _result["type"] = type.toJson();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "kind": kind,
        "name": name,
        "type": type,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeTypeTypeParameterBuilder extends Object
    with _LinkedNodeTypeTypeParameterMixin
    implements idl.LinkedNodeTypeTypeParameter {
  LinkedNodeTypeBuilder _bound;
  String _name;

  @override
  LinkedNodeTypeBuilder get bound => _bound;

  set bound(LinkedNodeTypeBuilder value) {
    this._bound = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  LinkedNodeTypeTypeParameterBuilder({LinkedNodeTypeBuilder bound, String name})
      : _bound = bound,
        _name = name;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _bound?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addBool(this._bound != null);
    this._bound?.collectApiSignature(signature);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_bound;
    fb.Offset offset_name;
    if (_bound != null) {
      offset_bound = _bound.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_bound != null) {
      fbBuilder.addOffset(1, offset_bound);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeTypeTypeParameterReader
    extends fb.TableReader<_LinkedNodeTypeTypeParameterImpl> {
  const _LinkedNodeTypeTypeParameterReader();

  @override
  _LinkedNodeTypeTypeParameterImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _LinkedNodeTypeTypeParameterImpl(bc, offset);
}

class _LinkedNodeTypeTypeParameterImpl extends Object
    with _LinkedNodeTypeTypeParameterMixin
    implements idl.LinkedNodeTypeTypeParameter {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeTypeTypeParameterImpl(this._bc, this._bcOffset);

  idl.LinkedNodeType _bound;
  String _name;

  @override
  idl.LinkedNodeType get bound {
    _bound ??= const _LinkedNodeTypeReader().vTableGet(_bc, _bcOffset, 1, null);
    return _bound;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }
}

abstract class _LinkedNodeTypeTypeParameterMixin
    implements idl.LinkedNodeTypeTypeParameter {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (bound != null) _result["bound"] = bound.toJson();
    if (name != '') _result["name"] = name;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "bound": bound,
        "name": name,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeUnitBuilder extends Object
    with _LinkedNodeUnitMixin
    implements idl.LinkedNodeUnit {
  bool _isSynthetic;
  List<int> _lineStarts;
  LinkedNodeBuilder _node;
  UnlinkedTokensBuilder _tokens;
  String _uriStr;

  @override
  bool get isSynthetic => _isSynthetic ??= false;

  set isSynthetic(bool value) {
    this._isSynthetic = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /// Offsets of the first character of each line in the source code.
  set lineStarts(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  LinkedNodeBuilder get node => _node;

  set node(LinkedNodeBuilder value) {
    this._node = value;
  }

  @override
  UnlinkedTokensBuilder get tokens => _tokens;

  set tokens(UnlinkedTokensBuilder value) {
    this._tokens = value;
  }

  @override
  String get uriStr => _uriStr ??= '';

  set uriStr(String value) {
    this._uriStr = value;
  }

  LinkedNodeUnitBuilder(
      {bool isSynthetic,
      List<int> lineStarts,
      LinkedNodeBuilder node,
      UnlinkedTokensBuilder tokens,
      String uriStr})
      : _isSynthetic = isSynthetic,
        _lineStarts = lineStarts,
        _node = node,
        _tokens = tokens,
        _uriStr = uriStr;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _lineStarts = null;
    _node?.flushInformative();
    _tokens?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uriStr ?? '');
    signature.addBool(this._tokens != null);
    this._tokens?.collectApiSignature(signature);
    signature.addBool(this._node != null);
    this._node?.collectApiSignature(signature);
    signature.addBool(this._isSynthetic == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_lineStarts;
    fb.Offset offset_node;
    fb.Offset offset_tokens;
    fb.Offset offset_uriStr;
    if (!(_lineStarts == null || _lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(_lineStarts);
    }
    if (_node != null) {
      offset_node = _node.finish(fbBuilder);
    }
    if (_tokens != null) {
      offset_tokens = _tokens.finish(fbBuilder);
    }
    if (_uriStr != null) {
      offset_uriStr = fbBuilder.writeString(_uriStr);
    }
    fbBuilder.startTable();
    if (_isSynthetic == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(4, offset_lineStarts);
    }
    if (offset_node != null) {
      fbBuilder.addOffset(2, offset_node);
    }
    if (offset_tokens != null) {
      fbBuilder.addOffset(1, offset_tokens);
    }
    if (offset_uriStr != null) {
      fbBuilder.addOffset(0, offset_uriStr);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeUnitReader extends fb.TableReader<_LinkedNodeUnitImpl> {
  const _LinkedNodeUnitReader();

  @override
  _LinkedNodeUnitImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedNodeUnitImpl(bc, offset);
}

class _LinkedNodeUnitImpl extends Object
    with _LinkedNodeUnitMixin
    implements idl.LinkedNodeUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeUnitImpl(this._bc, this._bcOffset);

  bool _isSynthetic;
  List<int> _lineStarts;
  idl.LinkedNode _node;
  idl.UnlinkedTokens _tokens;
  String _uriStr;

  @override
  bool get isSynthetic {
    _isSynthetic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isSynthetic;
  }

  @override
  List<int> get lineStarts {
    _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 4, const <int>[]);
    return _lineStarts;
  }

  @override
  idl.LinkedNode get node {
    _node ??= const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 2, null);
    return _node;
  }

  @override
  idl.UnlinkedTokens get tokens {
    _tokens ??=
        const _UnlinkedTokensReader().vTableGet(_bc, _bcOffset, 1, null);
    return _tokens;
  }

  @override
  String get uriStr {
    _uriStr ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uriStr;
  }
}

abstract class _LinkedNodeUnitMixin implements idl.LinkedNodeUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (isSynthetic != false) _result["isSynthetic"] = isSynthetic;
    if (lineStarts.isNotEmpty) _result["lineStarts"] = lineStarts;
    if (node != null) _result["node"] = node.toJson();
    if (tokens != null) _result["tokens"] = tokens.toJson();
    if (uriStr != '') _result["uriStr"] = uriStr;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "isSynthetic": isSynthetic,
        "lineStarts": lineStarts,
        "node": node,
        "tokens": tokens,
        "uriStr": uriStr,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeVariablesDeclarationBuilder extends Object
    with _LinkedNodeVariablesDeclarationMixin
    implements idl.LinkedNodeVariablesDeclaration {
  LinkedNodeBuilder _comment;
  bool _isConst;
  bool _isCovariant;
  bool _isFinal;
  bool _isStatic;

  @override
  LinkedNodeBuilder get comment => _comment;

  set comment(LinkedNodeBuilder value) {
    this._comment = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isCovariant => _isCovariant ??= false;

  set isCovariant(bool value) {
    this._isCovariant = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  set isStatic(bool value) {
    this._isStatic = value;
  }

  LinkedNodeVariablesDeclarationBuilder(
      {LinkedNodeBuilder comment,
      bool isConst,
      bool isCovariant,
      bool isFinal,
      bool isStatic})
      : _comment = comment,
        _isConst = isConst,
        _isCovariant = isCovariant,
        _isFinal = isFinal,
        _isStatic = isStatic;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _comment?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._comment != null);
    this._comment?.collectApiSignature(signature);
    signature.addBool(this._isConst == true);
    signature.addBool(this._isCovariant == true);
    signature.addBool(this._isFinal == true);
    signature.addBool(this._isStatic == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_comment;
    if (_comment != null) {
      offset_comment = _comment.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_comment != null) {
      fbBuilder.addOffset(0, offset_comment);
    }
    if (_isConst == true) {
      fbBuilder.addBool(1, true);
    }
    if (_isCovariant == true) {
      fbBuilder.addBool(2, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(3, true);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(4, true);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeVariablesDeclarationReader
    extends fb.TableReader<_LinkedNodeVariablesDeclarationImpl> {
  const _LinkedNodeVariablesDeclarationReader();

  @override
  _LinkedNodeVariablesDeclarationImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _LinkedNodeVariablesDeclarationImpl(bc, offset);
}

class _LinkedNodeVariablesDeclarationImpl extends Object
    with _LinkedNodeVariablesDeclarationMixin
    implements idl.LinkedNodeVariablesDeclaration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeVariablesDeclarationImpl(this._bc, this._bcOffset);

  idl.LinkedNode _comment;
  bool _isConst;
  bool _isCovariant;
  bool _isFinal;
  bool _isStatic;

  @override
  idl.LinkedNode get comment {
    _comment ??= const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 0, null);
    return _comment;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 1, false);
    return _isConst;
  }

  @override
  bool get isCovariant {
    _isCovariant ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isCovariant;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isFinal;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 4, false);
    return _isStatic;
  }
}

abstract class _LinkedNodeVariablesDeclarationMixin
    implements idl.LinkedNodeVariablesDeclaration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (comment != null) _result["comment"] = comment.toJson();
    if (isConst != false) _result["isConst"] = isConst;
    if (isCovariant != false) _result["isCovariant"] = isCovariant;
    if (isFinal != false) _result["isFinal"] = isFinal;
    if (isStatic != false) _result["isStatic"] = isStatic;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "comment": comment,
        "isConst": isConst,
        "isCovariant": isCovariant,
        "isFinal": isFinal,
        "isStatic": isStatic,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedReferenceBuilder extends Object
    with _LinkedReferenceMixin
    implements idl.LinkedReference {
  int _containingReference;
  int _dependency;
  idl.ReferenceKind _kind;
  String _name;
  int _numTypeParameters;
  int _unit;

  @override
  int get containingReference => _containingReference ??= 0;

  /// If this [LinkedReference] doesn't have an associated [UnlinkedReference],
  /// and the entity being referred to is contained within another entity, index
  /// of the containing entity.  This behaves similarly to
  /// [UnlinkedReference.prefixReference], however it is only used for class
  /// members, not for prefixed imports.
  ///
  /// Containing references must always point backward; that is, for all i, if
  /// LinkedUnit.references[i].containingReference != 0, then
  /// LinkedUnit.references[i].containingReference < i.
  set containingReference(int value) {
    assert(value == null || value >= 0);
    this._containingReference = value;
  }

  @override
  int get dependency => _dependency ??= 0;

  /// Index into [LinkedLibrary.dependencies] indicating which imported library
  /// declares the entity being referred to.
  ///
  /// Zero if this entity is contained within another entity (e.g. a class
  /// member), or if [kind] is [ReferenceKind.prefix].
  set dependency(int value) {
    assert(value == null || value >= 0);
    this._dependency = value;
  }

  @override
  idl.ReferenceKind get kind => _kind ??= idl.ReferenceKind.classOrEnum;

  /// The kind of the entity being referred to.  For the pseudo-types `dynamic`
  /// and `void`, the kind is [ReferenceKind.classOrEnum].
  set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  Null get localIndex =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name => _name ??= '';

  /// If this [LinkedReference] doesn't have an associated [UnlinkedReference],
  /// name of the entity being referred to.  For the pseudo-type `dynamic`, the
  /// string is "dynamic".  For the pseudo-type `void`, the string is "void".
  set name(String value) {
    this._name = value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /// If the entity being referred to is generic, the number of type parameters
  /// it declares (does not include type parameters of enclosing entities).
  /// Otherwise zero.
  set numTypeParameters(int value) {
    assert(value == null || value >= 0);
    this._numTypeParameters = value;
  }

  @override
  int get unit => _unit ??= 0;

  /// Integer index indicating which unit in the imported library contains the
  /// definition of the entity.  As with indices into [LinkedLibrary.units],
  /// zero represents the defining compilation unit, and nonzero values
  /// represent parts in the order of the corresponding `part` declarations.
  ///
  /// Zero if this entity is contained within another entity (e.g. a class
  /// member).
  set unit(int value) {
    assert(value == null || value >= 0);
    this._unit = value;
  }

  LinkedReferenceBuilder(
      {int containingReference,
      int dependency,
      idl.ReferenceKind kind,
      String name,
      int numTypeParameters,
      int unit})
      : _containingReference = containingReference,
        _dependency = dependency,
        _kind = kind,
        _name = name,
        _numTypeParameters = numTypeParameters,
        _unit = unit;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._unit ?? 0);
    signature.addInt(this._dependency ?? 0);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addString(this._name ?? '');
    signature.addInt(this._numTypeParameters ?? 0);
    signature.addInt(this._containingReference ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (_containingReference != null && _containingReference != 0) {
      fbBuilder.addUint32(5, _containingReference);
    }
    if (_dependency != null && _dependency != 0) {
      fbBuilder.addUint32(1, _dependency);
    }
    if (_kind != null && _kind != idl.ReferenceKind.classOrEnum) {
      fbBuilder.addUint8(2, _kind.index);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(3, offset_name);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addUint32(4, _numTypeParameters);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addUint32(0, _unit);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedReferenceReader extends fb.TableReader<_LinkedReferenceImpl> {
  const _LinkedReferenceReader();

  @override
  _LinkedReferenceImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedReferenceImpl(bc, offset);
}

class _LinkedReferenceImpl extends Object
    with _LinkedReferenceMixin
    implements idl.LinkedReference {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedReferenceImpl(this._bc, this._bcOffset);

  int _containingReference;
  int _dependency;
  idl.ReferenceKind _kind;
  String _name;
  int _numTypeParameters;
  int _unit;

  @override
  int get containingReference {
    _containingReference ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _containingReference;
  }

  @override
  int get dependency {
    _dependency ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _dependency;
  }

  @override
  idl.ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader()
        .vTableGet(_bc, _bcOffset, 2, idl.ReferenceKind.classOrEnum);
    return _kind;
  }

  @override
  Null get localIndex =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _name;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 4, 0);
    return _numTypeParameters;
  }

  @override
  int get unit {
    _unit ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _unit;
  }
}

abstract class _LinkedReferenceMixin implements idl.LinkedReference {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (containingReference != 0)
      _result["containingReference"] = containingReference;
    if (dependency != 0) _result["dependency"] = dependency;
    if (kind != idl.ReferenceKind.classOrEnum)
      _result["kind"] = kind.toString().split('.')[1];
    if (name != '') _result["name"] = name;
    if (numTypeParameters != 0)
      _result["numTypeParameters"] = numTypeParameters;
    if (unit != 0) _result["unit"] = unit;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "containingReference": containingReference,
        "dependency": dependency,
        "kind": kind,
        "name": name,
        "numTypeParameters": numTypeParameters,
        "unit": unit,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedUnitBuilder extends Object
    with _LinkedUnitMixin
    implements idl.LinkedUnit {
  List<int> _constCycles;
  List<int> _notSimplyBounded;
  List<int> _parametersInheritingCovariant;
  List<LinkedReferenceBuilder> _references;
  List<TopLevelInferenceErrorBuilder> _topLevelInferenceErrors;
  List<EntityRefBuilder> _types;

  @override
  List<int> get constCycles => _constCycles ??= <int>[];

  /// List of slot ids (referring to [UnlinkedExecutable.constCycleSlot])
  /// corresponding to const constructors that are part of cycles.
  set constCycles(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._constCycles = value;
  }

  @override
  List<int> get notSimplyBounded => _notSimplyBounded ??= <int>[];

  /// List of slot ids (referring to [UnlinkedClass.notSimplyBoundedSlot] or
  /// [UnlinkedTypedef.notSimplyBoundedSlot]) corresponding to classes and
  /// typedefs that are not simply bounded.
  set notSimplyBounded(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._notSimplyBounded = value;
  }

  @override
  List<int> get parametersInheritingCovariant =>
      _parametersInheritingCovariant ??= <int>[];

  /// List of slot ids (referring to [UnlinkedParam.inheritsCovariantSlot] or
  /// [UnlinkedVariable.inheritsCovariantSlot]) corresponding to parameters
  /// that inherit `@covariant` behavior from a base class.
  set parametersInheritingCovariant(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._parametersInheritingCovariant = value;
  }

  @override
  List<LinkedReferenceBuilder> get references =>
      _references ??= <LinkedReferenceBuilder>[];

  /// Information about the resolution of references within the compilation
  /// unit.  Each element of [UnlinkedUnit.references] has a corresponding
  /// element in this list (at the same index).  If this list has additional
  /// elements beyond the number of elements in [UnlinkedUnit.references], those
  /// additional elements are references that are only referred to implicitly
  /// (e.g. elements involved in inferred or propagated types).
  set references(List<LinkedReferenceBuilder> value) {
    this._references = value;
  }

  @override
  List<TopLevelInferenceErrorBuilder> get topLevelInferenceErrors =>
      _topLevelInferenceErrors ??= <TopLevelInferenceErrorBuilder>[];

  /// The list of type inference errors.
  set topLevelInferenceErrors(List<TopLevelInferenceErrorBuilder> value) {
    this._topLevelInferenceErrors = value;
  }

  @override
  List<EntityRefBuilder> get types => _types ??= <EntityRefBuilder>[];

  /// List associating slot ids found inside the unlinked summary for the
  /// compilation unit with propagated and inferred types.
  set types(List<EntityRefBuilder> value) {
    this._types = value;
  }

  LinkedUnitBuilder(
      {List<int> constCycles,
      List<int> notSimplyBounded,
      List<int> parametersInheritingCovariant,
      List<LinkedReferenceBuilder> references,
      List<TopLevelInferenceErrorBuilder> topLevelInferenceErrors,
      List<EntityRefBuilder> types})
      : _constCycles = constCycles,
        _notSimplyBounded = notSimplyBounded,
        _parametersInheritingCovariant = parametersInheritingCovariant,
        _references = references,
        _topLevelInferenceErrors = topLevelInferenceErrors,
        _types = types;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _references?.forEach((b) => b.flushInformative());
    _topLevelInferenceErrors?.forEach((b) => b.flushInformative());
    _types?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._references == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._references.length);
      for (var x in this._references) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._types == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._types.length);
      for (var x in this._types) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._constCycles == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._constCycles.length);
      for (var x in this._constCycles) {
        signature.addInt(x);
      }
    }
    if (this._parametersInheritingCovariant == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parametersInheritingCovariant.length);
      for (var x in this._parametersInheritingCovariant) {
        signature.addInt(x);
      }
    }
    if (this._topLevelInferenceErrors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._topLevelInferenceErrors.length);
      for (var x in this._topLevelInferenceErrors) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._notSimplyBounded == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._notSimplyBounded.length);
      for (var x in this._notSimplyBounded) {
        signature.addInt(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_constCycles;
    fb.Offset offset_notSimplyBounded;
    fb.Offset offset_parametersInheritingCovariant;
    fb.Offset offset_references;
    fb.Offset offset_topLevelInferenceErrors;
    fb.Offset offset_types;
    if (!(_constCycles == null || _constCycles.isEmpty)) {
      offset_constCycles = fbBuilder.writeListUint32(_constCycles);
    }
    if (!(_notSimplyBounded == null || _notSimplyBounded.isEmpty)) {
      offset_notSimplyBounded = fbBuilder.writeListUint32(_notSimplyBounded);
    }
    if (!(_parametersInheritingCovariant == null ||
        _parametersInheritingCovariant.isEmpty)) {
      offset_parametersInheritingCovariant =
          fbBuilder.writeListUint32(_parametersInheritingCovariant);
    }
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder
          .writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_topLevelInferenceErrors == null ||
        _topLevelInferenceErrors.isEmpty)) {
      offset_topLevelInferenceErrors = fbBuilder.writeList(
          _topLevelInferenceErrors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_types == null || _types.isEmpty)) {
      offset_types =
          fbBuilder.writeList(_types.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_constCycles != null) {
      fbBuilder.addOffset(2, offset_constCycles);
    }
    if (offset_notSimplyBounded != null) {
      fbBuilder.addOffset(5, offset_notSimplyBounded);
    }
    if (offset_parametersInheritingCovariant != null) {
      fbBuilder.addOffset(3, offset_parametersInheritingCovariant);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(0, offset_references);
    }
    if (offset_topLevelInferenceErrors != null) {
      fbBuilder.addOffset(4, offset_topLevelInferenceErrors);
    }
    if (offset_types != null) {
      fbBuilder.addOffset(1, offset_types);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedUnitReader extends fb.TableReader<_LinkedUnitImpl> {
  const _LinkedUnitReader();

  @override
  _LinkedUnitImpl createObject(fb.BufferContext bc, int offset) =>
      new _LinkedUnitImpl(bc, offset);
}

class _LinkedUnitImpl extends Object
    with _LinkedUnitMixin
    implements idl.LinkedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedUnitImpl(this._bc, this._bcOffset);

  List<int> _constCycles;
  List<int> _notSimplyBounded;
  List<int> _parametersInheritingCovariant;
  List<idl.LinkedReference> _references;
  List<idl.TopLevelInferenceError> _topLevelInferenceErrors;
  List<idl.EntityRef> _types;

  @override
  List<int> get constCycles {
    _constCycles ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _constCycles;
  }

  @override
  List<int> get notSimplyBounded {
    _notSimplyBounded ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _notSimplyBounded;
  }

  @override
  List<int> get parametersInheritingCovariant {
    _parametersInheritingCovariant ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
    return _parametersInheritingCovariant;
  }

  @override
  List<idl.LinkedReference> get references {
    _references ??=
        const fb.ListReader<idl.LinkedReference>(const _LinkedReferenceReader())
            .vTableGet(_bc, _bcOffset, 0, const <idl.LinkedReference>[]);
    return _references;
  }

  @override
  List<idl.TopLevelInferenceError> get topLevelInferenceErrors {
    _topLevelInferenceErrors ??=
        const fb.ListReader<idl.TopLevelInferenceError>(
                const _TopLevelInferenceErrorReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.TopLevelInferenceError>[]);
    return _topLevelInferenceErrors;
  }

  @override
  List<idl.EntityRef> get types {
    _types ??= const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.EntityRef>[]);
    return _types;
  }
}

abstract class _LinkedUnitMixin implements idl.LinkedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (constCycles.isNotEmpty) _result["constCycles"] = constCycles;
    if (notSimplyBounded.isNotEmpty)
      _result["notSimplyBounded"] = notSimplyBounded;
    if (parametersInheritingCovariant.isNotEmpty)
      _result["parametersInheritingCovariant"] = parametersInheritingCovariant;
    if (references.isNotEmpty)
      _result["references"] =
          references.map((_value) => _value.toJson()).toList();
    if (topLevelInferenceErrors.isNotEmpty)
      _result["topLevelInferenceErrors"] =
          topLevelInferenceErrors.map((_value) => _value.toJson()).toList();
    if (types.isNotEmpty)
      _result["types"] = types.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "constCycles": constCycles,
        "notSimplyBounded": notSimplyBounded,
        "parametersInheritingCovariant": parametersInheritingCovariant,
        "references": references,
        "topLevelInferenceErrors": topLevelInferenceErrors,
        "types": types,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class PackageBundleBuilder extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  List<LinkedLibraryBuilder> _linkedLibraries;
  List<String> _linkedLibraryUris;
  int _majorVersion;
  int _minorVersion;
  List<UnlinkedUnitBuilder> _unlinkedUnits;
  List<String> _unlinkedUnitUris;

  @override
  Null get apiSignature =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get dependencies =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<LinkedLibraryBuilder> get linkedLibraries =>
      _linkedLibraries ??= <LinkedLibraryBuilder>[];

  /// Linked libraries.
  set linkedLibraries(List<LinkedLibraryBuilder> value) {
    this._linkedLibraries = value;
  }

  @override
  List<String> get linkedLibraryUris => _linkedLibraryUris ??= <String>[];

  /// The list of URIs of items in [linkedLibraries], e.g. `dart:core` or
  /// `package:foo/bar.dart`.
  set linkedLibraryUris(List<String> value) {
    this._linkedLibraryUris = value;
  }

  @override
  int get majorVersion => _majorVersion ??= 0;

  /// Major version of the summary format.  See
  /// [PackageBundleAssembler.currentMajorVersion].
  set majorVersion(int value) {
    assert(value == null || value >= 0);
    this._majorVersion = value;
  }

  @override
  int get minorVersion => _minorVersion ??= 0;

  /// Minor version of the summary format.  See
  /// [PackageBundleAssembler.currentMinorVersion].
  set minorVersion(int value) {
    assert(value == null || value >= 0);
    this._minorVersion = value;
  }

  @override
  Null get unlinkedUnitHashes =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<UnlinkedUnitBuilder> get unlinkedUnits =>
      _unlinkedUnits ??= <UnlinkedUnitBuilder>[];

  /// Unlinked information for the compilation units constituting the package.
  set unlinkedUnits(List<UnlinkedUnitBuilder> value) {
    this._unlinkedUnits = value;
  }

  @override
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ??= <String>[];

  /// The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
  set unlinkedUnitUris(List<String> value) {
    this._unlinkedUnitUris = value;
  }

  PackageBundleBuilder(
      {List<LinkedLibraryBuilder> linkedLibraries,
      List<String> linkedLibraryUris,
      int majorVersion,
      int minorVersion,
      List<UnlinkedUnitBuilder> unlinkedUnits,
      List<String> unlinkedUnitUris})
      : _linkedLibraries = linkedLibraries,
        _linkedLibraryUris = linkedLibraryUris,
        _majorVersion = majorVersion,
        _minorVersion = minorVersion,
        _unlinkedUnits = unlinkedUnits,
        _unlinkedUnitUris = unlinkedUnitUris;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _linkedLibraries?.forEach((b) => b.flushInformative());
    _unlinkedUnits?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._linkedLibraries == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._linkedLibraries.length);
      for (var x in this._linkedLibraries) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._linkedLibraryUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._linkedLibraryUris.length);
      for (var x in this._linkedLibraryUris) {
        signature.addString(x);
      }
    }
    if (this._unlinkedUnits == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unlinkedUnits.length);
      for (var x in this._unlinkedUnits) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._unlinkedUnitUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unlinkedUnitUris.length);
      for (var x in this._unlinkedUnitUris) {
        signature.addString(x);
      }
    }
    signature.addInt(this._majorVersion ?? 0);
    signature.addInt(this._minorVersion ?? 0);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "PBdl");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_linkedLibraries;
    fb.Offset offset_linkedLibraryUris;
    fb.Offset offset_unlinkedUnits;
    fb.Offset offset_unlinkedUnitUris;
    if (!(_linkedLibraries == null || _linkedLibraries.isEmpty)) {
      offset_linkedLibraries = fbBuilder
          .writeList(_linkedLibraries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_linkedLibraryUris == null || _linkedLibraryUris.isEmpty)) {
      offset_linkedLibraryUris = fbBuilder.writeList(
          _linkedLibraryUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_unlinkedUnits == null || _unlinkedUnits.isEmpty)) {
      offset_unlinkedUnits = fbBuilder
          .writeList(_unlinkedUnits.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_unlinkedUnitUris == null || _unlinkedUnitUris.isEmpty)) {
      offset_unlinkedUnitUris = fbBuilder.writeList(
          _unlinkedUnitUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_linkedLibraries != null) {
      fbBuilder.addOffset(0, offset_linkedLibraries);
    }
    if (offset_linkedLibraryUris != null) {
      fbBuilder.addOffset(1, offset_linkedLibraryUris);
    }
    if (_majorVersion != null && _majorVersion != 0) {
      fbBuilder.addUint32(5, _majorVersion);
    }
    if (_minorVersion != null && _minorVersion != 0) {
      fbBuilder.addUint32(6, _minorVersion);
    }
    if (offset_unlinkedUnits != null) {
      fbBuilder.addOffset(2, offset_unlinkedUnits);
    }
    if (offset_unlinkedUnitUris != null) {
      fbBuilder.addOffset(3, offset_unlinkedUnitUris);
    }
    return fbBuilder.endTable();
  }
}

idl.PackageBundle readPackageBundle(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _PackageBundleReader().read(rootRef, 0);
}

class _PackageBundleReader extends fb.TableReader<_PackageBundleImpl> {
  const _PackageBundleReader();

  @override
  _PackageBundleImpl createObject(fb.BufferContext bc, int offset) =>
      new _PackageBundleImpl(bc, offset);
}

class _PackageBundleImpl extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageBundleImpl(this._bc, this._bcOffset);

  List<idl.LinkedLibrary> _linkedLibraries;
  List<String> _linkedLibraryUris;
  int _majorVersion;
  int _minorVersion;
  List<idl.UnlinkedUnit> _unlinkedUnits;
  List<String> _unlinkedUnitUris;

  @override
  Null get apiSignature =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get dependencies =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<idl.LinkedLibrary> get linkedLibraries {
    _linkedLibraries ??=
        const fb.ListReader<idl.LinkedLibrary>(const _LinkedLibraryReader())
            .vTableGet(_bc, _bcOffset, 0, const <idl.LinkedLibrary>[]);
    return _linkedLibraries;
  }

  @override
  List<String> get linkedLibraryUris {
    _linkedLibraryUris ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _linkedLibraryUris;
  }

  @override
  int get majorVersion {
    _majorVersion ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _majorVersion;
  }

  @override
  int get minorVersion {
    _minorVersion ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 6, 0);
    return _minorVersion;
  }

  @override
  Null get unlinkedUnitHashes =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<idl.UnlinkedUnit> get unlinkedUnits {
    _unlinkedUnits ??=
        const fb.ListReader<idl.UnlinkedUnit>(const _UnlinkedUnitReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedUnit>[]);
    return _unlinkedUnits;
  }

  @override
  List<String> get unlinkedUnitUris {
    _unlinkedUnitUris ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 3, const <String>[]);
    return _unlinkedUnitUris;
  }
}

abstract class _PackageBundleMixin implements idl.PackageBundle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (linkedLibraries.isNotEmpty)
      _result["linkedLibraries"] =
          linkedLibraries.map((_value) => _value.toJson()).toList();
    if (linkedLibraryUris.isNotEmpty)
      _result["linkedLibraryUris"] = linkedLibraryUris;
    if (majorVersion != 0) _result["majorVersion"] = majorVersion;
    if (minorVersion != 0) _result["minorVersion"] = minorVersion;
    if (unlinkedUnits.isNotEmpty)
      _result["unlinkedUnits"] =
          unlinkedUnits.map((_value) => _value.toJson()).toList();
    if (unlinkedUnitUris.isNotEmpty)
      _result["unlinkedUnitUris"] = unlinkedUnitUris;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "linkedLibraries": linkedLibraries,
        "linkedLibraryUris": linkedLibraryUris,
        "majorVersion": majorVersion,
        "minorVersion": minorVersion,
        "unlinkedUnits": unlinkedUnits,
        "unlinkedUnitUris": unlinkedUnitUris,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class PackageIndexBuilder extends Object
    with _PackageIndexMixin
    implements idl.PackageIndex {
  List<idl.IndexSyntheticElementKind> _elementKinds;
  List<int> _elementNameClassMemberIds;
  List<int> _elementNameParameterIds;
  List<int> _elementNameUnitMemberIds;
  List<int> _elementUnits;
  List<String> _strings;
  List<int> _unitLibraryUris;
  List<UnitIndexBuilder> _units;
  List<int> _unitUnitUris;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds =>
      _elementKinds ??= <idl.IndexSyntheticElementKind>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  set elementKinds(List<idl.IndexSyntheticElementKind> value) {
    this._elementKinds = value;
  }

  @override
  List<int> get elementNameClassMemberIds =>
      _elementNameClassMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// [PackageIndex].
  set elementNameClassMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this
  /// [PackageIndex].
  set elementNameParameterIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameParameterIds = value;
  }

  @override
  List<int> get elementNameUnitMemberIds =>
      _elementNameUnitMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this [PackageIndex].
  set elementNameUnitMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  set elementUnits(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /// List of unique element strings used in this [PackageIndex].  The list is
  /// sorted in ascending order, so that the client can quickly check the
  /// presence of a string in this [PackageIndex].
  set strings(List<String> value) {
    this._strings = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the [PackageIndex].  It is an index into
  /// [strings] list.
  set unitLibraryUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<UnitIndexBuilder> get units => _units ??= <UnitIndexBuilder>[];

  /// List of indexes of each unit in this [PackageIndex].
  set units(List<UnitIndexBuilder> value) {
    this._units = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the [PackageIndex].  It is an index into
  /// [strings] list.
  set unitUnitUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitUnitUris = value;
  }

  PackageIndexBuilder(
      {List<idl.IndexSyntheticElementKind> elementKinds,
      List<int> elementNameClassMemberIds,
      List<int> elementNameParameterIds,
      List<int> elementNameUnitMemberIds,
      List<int> elementUnits,
      List<String> strings,
      List<int> unitLibraryUris,
      List<UnitIndexBuilder> units,
      List<int> unitUnitUris})
      : _elementKinds = elementKinds,
        _elementNameClassMemberIds = elementNameClassMemberIds,
        _elementNameParameterIds = elementNameParameterIds,
        _elementNameUnitMemberIds = elementNameUnitMemberIds,
        _elementUnits = elementUnits,
        _strings = strings,
        _unitLibraryUris = unitLibraryUris,
        _units = units,
        _unitUnitUris = unitUnitUris;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _units?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._elementUnits == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementUnits.length);
      for (var x in this._elementUnits) {
        signature.addInt(x);
      }
    }
    if (this._elementNameUnitMemberIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameUnitMemberIds.length);
      for (var x in this._elementNameUnitMemberIds) {
        signature.addInt(x);
      }
    }
    if (this._unitLibraryUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unitLibraryUris.length);
      for (var x in this._unitLibraryUris) {
        signature.addInt(x);
      }
    }
    if (this._unitUnitUris == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unitUnitUris.length);
      for (var x in this._unitUnitUris) {
        signature.addInt(x);
      }
    }
    if (this._units == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._units.length);
      for (var x in this._units) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._elementKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementKinds.length);
      for (var x in this._elementKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._strings == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._strings.length);
      for (var x in this._strings) {
        signature.addString(x);
      }
    }
    if (this._elementNameClassMemberIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameClassMemberIds.length);
      for (var x in this._elementNameClassMemberIds) {
        signature.addInt(x);
      }
    }
    if (this._elementNameParameterIds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._elementNameParameterIds.length);
      for (var x in this._elementNameParameterIds) {
        signature.addInt(x);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "Indx");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_elementKinds;
    fb.Offset offset_elementNameClassMemberIds;
    fb.Offset offset_elementNameParameterIds;
    fb.Offset offset_elementNameUnitMemberIds;
    fb.Offset offset_elementUnits;
    fb.Offset offset_strings;
    fb.Offset offset_unitLibraryUris;
    fb.Offset offset_units;
    fb.Offset offset_unitUnitUris;
    if (!(_elementKinds == null || _elementKinds.isEmpty)) {
      offset_elementKinds =
          fbBuilder.writeListUint8(_elementKinds.map((b) => b.index).toList());
    }
    if (!(_elementNameClassMemberIds == null ||
        _elementNameClassMemberIds.isEmpty)) {
      offset_elementNameClassMemberIds =
          fbBuilder.writeListUint32(_elementNameClassMemberIds);
    }
    if (!(_elementNameParameterIds == null ||
        _elementNameParameterIds.isEmpty)) {
      offset_elementNameParameterIds =
          fbBuilder.writeListUint32(_elementNameParameterIds);
    }
    if (!(_elementNameUnitMemberIds == null ||
        _elementNameUnitMemberIds.isEmpty)) {
      offset_elementNameUnitMemberIds =
          fbBuilder.writeListUint32(_elementNameUnitMemberIds);
    }
    if (!(_elementUnits == null || _elementUnits.isEmpty)) {
      offset_elementUnits = fbBuilder.writeListUint32(_elementUnits);
    }
    if (!(_strings == null || _strings.isEmpty)) {
      offset_strings = fbBuilder
          .writeList(_strings.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_unitLibraryUris == null || _unitLibraryUris.isEmpty)) {
      offset_unitLibraryUris = fbBuilder.writeListUint32(_unitLibraryUris);
    }
    if (!(_units == null || _units.isEmpty)) {
      offset_units =
          fbBuilder.writeList(_units.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_unitUnitUris == null || _unitUnitUris.isEmpty)) {
      offset_unitUnitUris = fbBuilder.writeListUint32(_unitUnitUris);
    }
    fbBuilder.startTable();
    if (offset_elementKinds != null) {
      fbBuilder.addOffset(5, offset_elementKinds);
    }
    if (offset_elementNameClassMemberIds != null) {
      fbBuilder.addOffset(7, offset_elementNameClassMemberIds);
    }
    if (offset_elementNameParameterIds != null) {
      fbBuilder.addOffset(8, offset_elementNameParameterIds);
    }
    if (offset_elementNameUnitMemberIds != null) {
      fbBuilder.addOffset(1, offset_elementNameUnitMemberIds);
    }
    if (offset_elementUnits != null) {
      fbBuilder.addOffset(0, offset_elementUnits);
    }
    if (offset_strings != null) {
      fbBuilder.addOffset(6, offset_strings);
    }
    if (offset_unitLibraryUris != null) {
      fbBuilder.addOffset(2, offset_unitLibraryUris);
    }
    if (offset_units != null) {
      fbBuilder.addOffset(4, offset_units);
    }
    if (offset_unitUnitUris != null) {
      fbBuilder.addOffset(3, offset_unitUnitUris);
    }
    return fbBuilder.endTable();
  }
}

idl.PackageIndex readPackageIndex(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _PackageIndexReader().read(rootRef, 0);
}

class _PackageIndexReader extends fb.TableReader<_PackageIndexImpl> {
  const _PackageIndexReader();

  @override
  _PackageIndexImpl createObject(fb.BufferContext bc, int offset) =>
      new _PackageIndexImpl(bc, offset);
}

class _PackageIndexImpl extends Object
    with _PackageIndexMixin
    implements idl.PackageIndex {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageIndexImpl(this._bc, this._bcOffset);

  List<idl.IndexSyntheticElementKind> _elementKinds;
  List<int> _elementNameClassMemberIds;
  List<int> _elementNameParameterIds;
  List<int> _elementNameUnitMemberIds;
  List<int> _elementUnits;
  List<String> _strings;
  List<int> _unitLibraryUris;
  List<idl.UnitIndex> _units;
  List<int> _unitUnitUris;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds {
    _elementKinds ??= const fb.ListReader<idl.IndexSyntheticElementKind>(
            const _IndexSyntheticElementKindReader())
        .vTableGet(_bc, _bcOffset, 5, const <idl.IndexSyntheticElementKind>[]);
    return _elementKinds;
  }

  @override
  List<int> get elementNameClassMemberIds {
    _elementNameClassMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
    return _elementNameClassMemberIds;
  }

  @override
  List<int> get elementNameParameterIds {
    _elementNameParameterIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 8, const <int>[]);
    return _elementNameParameterIds;
  }

  @override
  List<int> get elementNameUnitMemberIds {
    _elementNameUnitMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
    return _elementNameUnitMemberIds;
  }

  @override
  List<int> get elementUnits {
    _elementUnits ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _elementUnits;
  }

  @override
  List<String> get strings {
    _strings ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 6, const <String>[]);
    return _strings;
  }

  @override
  List<int> get unitLibraryUris {
    _unitLibraryUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _unitLibraryUris;
  }

  @override
  List<idl.UnitIndex> get units {
    _units ??= const fb.ListReader<idl.UnitIndex>(const _UnitIndexReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.UnitIndex>[]);
    return _units;
  }

  @override
  List<int> get unitUnitUris {
    _unitUnitUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
    return _unitUnitUris;
  }
}

abstract class _PackageIndexMixin implements idl.PackageIndex {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (elementKinds.isNotEmpty)
      _result["elementKinds"] = elementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (elementNameClassMemberIds.isNotEmpty)
      _result["elementNameClassMemberIds"] = elementNameClassMemberIds;
    if (elementNameParameterIds.isNotEmpty)
      _result["elementNameParameterIds"] = elementNameParameterIds;
    if (elementNameUnitMemberIds.isNotEmpty)
      _result["elementNameUnitMemberIds"] = elementNameUnitMemberIds;
    if (elementUnits.isNotEmpty) _result["elementUnits"] = elementUnits;
    if (strings.isNotEmpty) _result["strings"] = strings;
    if (unitLibraryUris.isNotEmpty)
      _result["unitLibraryUris"] = unitLibraryUris;
    if (units.isNotEmpty)
      _result["units"] = units.map((_value) => _value.toJson()).toList();
    if (unitUnitUris.isNotEmpty) _result["unitUnitUris"] = unitUnitUris;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "elementKinds": elementKinds,
        "elementNameClassMemberIds": elementNameClassMemberIds,
        "elementNameParameterIds": elementNameParameterIds,
        "elementNameUnitMemberIds": elementNameUnitMemberIds,
        "elementUnits": elementUnits,
        "strings": strings,
        "unitLibraryUris": unitLibraryUris,
        "units": units,
        "unitUnitUris": unitUnitUris,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class TopLevelInferenceErrorBuilder extends Object
    with _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  List<String> _arguments;
  idl.TopLevelInferenceErrorKind _kind;
  int _slot;

  @override
  List<String> get arguments => _arguments ??= <String>[];

  /// The [kind] specific arguments.
  set arguments(List<String> value) {
    this._arguments = value;
  }

  @override
  idl.TopLevelInferenceErrorKind get kind =>
      _kind ??= idl.TopLevelInferenceErrorKind.assignment;

  /// The kind of the error.
  set kind(idl.TopLevelInferenceErrorKind value) {
    this._kind = value;
  }

  @override
  int get slot => _slot ??= 0;

  /// The slot id (which is unique within the compilation unit) identifying the
  /// target of type inference with which this [TopLevelInferenceError] is
  /// associated.
  set slot(int value) {
    assert(value == null || value >= 0);
    this._slot = value;
  }

  TopLevelInferenceErrorBuilder(
      {List<String> arguments, idl.TopLevelInferenceErrorKind kind, int slot})
      : _arguments = arguments,
        _kind = kind,
        _slot = slot;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._slot ?? 0);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    if (this._arguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._arguments.length);
      for (var x in this._arguments) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_arguments;
    if (!(_arguments == null || _arguments.isEmpty)) {
      offset_arguments = fbBuilder
          .writeList(_arguments.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_arguments != null) {
      fbBuilder.addOffset(2, offset_arguments);
    }
    if (_kind != null && _kind != idl.TopLevelInferenceErrorKind.assignment) {
      fbBuilder.addUint8(1, _kind.index);
    }
    if (_slot != null && _slot != 0) {
      fbBuilder.addUint32(0, _slot);
    }
    return fbBuilder.endTable();
  }
}

class _TopLevelInferenceErrorReader
    extends fb.TableReader<_TopLevelInferenceErrorImpl> {
  const _TopLevelInferenceErrorReader();

  @override
  _TopLevelInferenceErrorImpl createObject(fb.BufferContext bc, int offset) =>
      new _TopLevelInferenceErrorImpl(bc, offset);
}

class _TopLevelInferenceErrorImpl extends Object
    with _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _TopLevelInferenceErrorImpl(this._bc, this._bcOffset);

  List<String> _arguments;
  idl.TopLevelInferenceErrorKind _kind;
  int _slot;

  @override
  List<String> get arguments {
    _arguments ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _arguments;
  }

  @override
  idl.TopLevelInferenceErrorKind get kind {
    _kind ??= const _TopLevelInferenceErrorKindReader().vTableGet(
        _bc, _bcOffset, 1, idl.TopLevelInferenceErrorKind.assignment);
    return _kind;
  }

  @override
  int get slot {
    _slot ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _slot;
  }
}

abstract class _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (arguments.isNotEmpty) _result["arguments"] = arguments;
    if (kind != idl.TopLevelInferenceErrorKind.assignment)
      _result["kind"] = kind.toString().split('.')[1];
    if (slot != 0) _result["slot"] = slot;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "arguments": arguments,
        "kind": kind,
        "slot": slot,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnitIndexBuilder extends Object
    with _UnitIndexMixin
    implements idl.UnitIndex {
  List<idl.IndexNameKind> _definedNameKinds;
  List<int> _definedNameOffsets;
  List<int> _definedNames;
  int _unit;
  List<bool> _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedElementKinds;
  List<int> _usedElementLengths;
  List<int> _usedElementOffsets;
  List<int> _usedElements;
  List<bool> _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedNameKinds;
  List<int> _usedNameOffsets;
  List<int> _usedNames;

  @override
  List<idl.IndexNameKind> get definedNameKinds =>
      _definedNameKinds ??= <idl.IndexNameKind>[];

  /// Each item of this list is the kind of an element defined in this unit.
  set definedNameKinds(List<idl.IndexNameKind> value) {
    this._definedNameKinds = value;
  }

  @override
  List<int> get definedNameOffsets => _definedNameOffsets ??= <int>[];

  /// Each item of this list is the name offset of an element defined in this
  /// unit relative to the beginning of the file.
  set definedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._definedNameOffsets = value;
  }

  @override
  List<int> get definedNames => _definedNames ??= <int>[];

  /// Each item of this list corresponds to an element defined in this unit.  It
  /// is an index into [PackageIndex.strings] list.  The list is sorted in
  /// ascending order, so that the client can quickly find name definitions in
  /// this [UnitIndex].
  set definedNames(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._definedNames = value;
  }

  @override
  int get unit => _unit ??= 0;

  /// Index into [PackageIndex.unitLibraryUris] and [PackageIndex.unitUnitUris]
  /// for the library specific unit that corresponds to this [UnitIndex].
  set unit(int value) {
    assert(value == null || value >= 0);
    this._unit = value;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags =>
      _usedElementIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  set usedElementIsQualifiedFlags(List<bool> value) {
    this._usedElementIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds =>
      _usedElementKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the element usage.
  set usedElementKinds(List<idl.IndexRelationKind> value) {
    this._usedElementKinds = value;
  }

  @override
  List<int> get usedElementLengths => _usedElementLengths ??= <int>[];

  /// Each item of this list is the length of the element usage.
  set usedElementLengths(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  set usedElementOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /// Each item of this list is the index into [PackageIndex.elementUnits] and
  /// [PackageIndex.elementOffsets].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this [UnitIndex].
  set usedElements(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElements = value;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags =>
      _usedNameIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  set usedNameIsQualifiedFlags(List<bool> value) {
    this._usedNameIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds =>
      _usedNameKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the name usage.
  set usedNameKinds(List<idl.IndexRelationKind> value) {
    this._usedNameKinds = value;
  }

  @override
  List<int> get usedNameOffsets => _usedNameOffsets ??= <int>[];

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  set usedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /// Each item of this list is the index into [PackageIndex.strings] for a
  /// used name.  The list is sorted in ascending order, so that the client can
  /// quickly find name uses in this [UnitIndex].
  set usedNames(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNames = value;
  }

  UnitIndexBuilder(
      {List<idl.IndexNameKind> definedNameKinds,
      List<int> definedNameOffsets,
      List<int> definedNames,
      int unit,
      List<bool> usedElementIsQualifiedFlags,
      List<idl.IndexRelationKind> usedElementKinds,
      List<int> usedElementLengths,
      List<int> usedElementOffsets,
      List<int> usedElements,
      List<bool> usedNameIsQualifiedFlags,
      List<idl.IndexRelationKind> usedNameKinds,
      List<int> usedNameOffsets,
      List<int> usedNames})
      : _definedNameKinds = definedNameKinds,
        _definedNameOffsets = definedNameOffsets,
        _definedNames = definedNames,
        _unit = unit,
        _usedElementIsQualifiedFlags = usedElementIsQualifiedFlags,
        _usedElementKinds = usedElementKinds,
        _usedElementLengths = usedElementLengths,
        _usedElementOffsets = usedElementOffsets,
        _usedElements = usedElements,
        _usedNameIsQualifiedFlags = usedNameIsQualifiedFlags,
        _usedNameKinds = usedNameKinds,
        _usedNameOffsets = usedNameOffsets,
        _usedNames = usedNames;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._unit ?? 0);
    if (this._usedElementLengths == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementLengths.length);
      for (var x in this._usedElementLengths) {
        signature.addInt(x);
      }
    }
    if (this._usedElementOffsets == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementOffsets.length);
      for (var x in this._usedElementOffsets) {
        signature.addInt(x);
      }
    }
    if (this._usedElements == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElements.length);
      for (var x in this._usedElements) {
        signature.addInt(x);
      }
    }
    if (this._usedElementKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementKinds.length);
      for (var x in this._usedElementKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._definedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._definedNames.length);
      for (var x in this._definedNames) {
        signature.addInt(x);
      }
    }
    if (this._definedNameKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._definedNameKinds.length);
      for (var x in this._definedNameKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._definedNameOffsets == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._definedNameOffsets.length);
      for (var x in this._definedNameOffsets) {
        signature.addInt(x);
      }
    }
    if (this._usedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNames.length);
      for (var x in this._usedNames) {
        signature.addInt(x);
      }
    }
    if (this._usedNameOffsets == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameOffsets.length);
      for (var x in this._usedNameOffsets) {
        signature.addInt(x);
      }
    }
    if (this._usedNameKinds == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameKinds.length);
      for (var x in this._usedNameKinds) {
        signature.addInt(x.index);
      }
    }
    if (this._usedElementIsQualifiedFlags == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedElementIsQualifiedFlags.length);
      for (var x in this._usedElementIsQualifiedFlags) {
        signature.addBool(x);
      }
    }
    if (this._usedNameIsQualifiedFlags == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._usedNameIsQualifiedFlags.length);
      for (var x in this._usedNameIsQualifiedFlags) {
        signature.addBool(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_definedNameKinds;
    fb.Offset offset_definedNameOffsets;
    fb.Offset offset_definedNames;
    fb.Offset offset_usedElementIsQualifiedFlags;
    fb.Offset offset_usedElementKinds;
    fb.Offset offset_usedElementLengths;
    fb.Offset offset_usedElementOffsets;
    fb.Offset offset_usedElements;
    fb.Offset offset_usedNameIsQualifiedFlags;
    fb.Offset offset_usedNameKinds;
    fb.Offset offset_usedNameOffsets;
    fb.Offset offset_usedNames;
    if (!(_definedNameKinds == null || _definedNameKinds.isEmpty)) {
      offset_definedNameKinds = fbBuilder
          .writeListUint8(_definedNameKinds.map((b) => b.index).toList());
    }
    if (!(_definedNameOffsets == null || _definedNameOffsets.isEmpty)) {
      offset_definedNameOffsets =
          fbBuilder.writeListUint32(_definedNameOffsets);
    }
    if (!(_definedNames == null || _definedNames.isEmpty)) {
      offset_definedNames = fbBuilder.writeListUint32(_definedNames);
    }
    if (!(_usedElementIsQualifiedFlags == null ||
        _usedElementIsQualifiedFlags.isEmpty)) {
      offset_usedElementIsQualifiedFlags =
          fbBuilder.writeListBool(_usedElementIsQualifiedFlags);
    }
    if (!(_usedElementKinds == null || _usedElementKinds.isEmpty)) {
      offset_usedElementKinds = fbBuilder
          .writeListUint8(_usedElementKinds.map((b) => b.index).toList());
    }
    if (!(_usedElementLengths == null || _usedElementLengths.isEmpty)) {
      offset_usedElementLengths =
          fbBuilder.writeListUint32(_usedElementLengths);
    }
    if (!(_usedElementOffsets == null || _usedElementOffsets.isEmpty)) {
      offset_usedElementOffsets =
          fbBuilder.writeListUint32(_usedElementOffsets);
    }
    if (!(_usedElements == null || _usedElements.isEmpty)) {
      offset_usedElements = fbBuilder.writeListUint32(_usedElements);
    }
    if (!(_usedNameIsQualifiedFlags == null ||
        _usedNameIsQualifiedFlags.isEmpty)) {
      offset_usedNameIsQualifiedFlags =
          fbBuilder.writeListBool(_usedNameIsQualifiedFlags);
    }
    if (!(_usedNameKinds == null || _usedNameKinds.isEmpty)) {
      offset_usedNameKinds =
          fbBuilder.writeListUint8(_usedNameKinds.map((b) => b.index).toList());
    }
    if (!(_usedNameOffsets == null || _usedNameOffsets.isEmpty)) {
      offset_usedNameOffsets = fbBuilder.writeListUint32(_usedNameOffsets);
    }
    if (!(_usedNames == null || _usedNames.isEmpty)) {
      offset_usedNames = fbBuilder.writeListUint32(_usedNames);
    }
    fbBuilder.startTable();
    if (offset_definedNameKinds != null) {
      fbBuilder.addOffset(6, offset_definedNameKinds);
    }
    if (offset_definedNameOffsets != null) {
      fbBuilder.addOffset(7, offset_definedNameOffsets);
    }
    if (offset_definedNames != null) {
      fbBuilder.addOffset(5, offset_definedNames);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addUint32(0, _unit);
    }
    if (offset_usedElementIsQualifiedFlags != null) {
      fbBuilder.addOffset(11, offset_usedElementIsQualifiedFlags);
    }
    if (offset_usedElementKinds != null) {
      fbBuilder.addOffset(4, offset_usedElementKinds);
    }
    if (offset_usedElementLengths != null) {
      fbBuilder.addOffset(1, offset_usedElementLengths);
    }
    if (offset_usedElementOffsets != null) {
      fbBuilder.addOffset(2, offset_usedElementOffsets);
    }
    if (offset_usedElements != null) {
      fbBuilder.addOffset(3, offset_usedElements);
    }
    if (offset_usedNameIsQualifiedFlags != null) {
      fbBuilder.addOffset(12, offset_usedNameIsQualifiedFlags);
    }
    if (offset_usedNameKinds != null) {
      fbBuilder.addOffset(10, offset_usedNameKinds);
    }
    if (offset_usedNameOffsets != null) {
      fbBuilder.addOffset(9, offset_usedNameOffsets);
    }
    if (offset_usedNames != null) {
      fbBuilder.addOffset(8, offset_usedNames);
    }
    return fbBuilder.endTable();
  }
}

class _UnitIndexReader extends fb.TableReader<_UnitIndexImpl> {
  const _UnitIndexReader();

  @override
  _UnitIndexImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnitIndexImpl(bc, offset);
}

class _UnitIndexImpl extends Object
    with _UnitIndexMixin
    implements idl.UnitIndex {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnitIndexImpl(this._bc, this._bcOffset);

  List<idl.IndexNameKind> _definedNameKinds;
  List<int> _definedNameOffsets;
  List<int> _definedNames;
  int _unit;
  List<bool> _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedElementKinds;
  List<int> _usedElementLengths;
  List<int> _usedElementOffsets;
  List<int> _usedElements;
  List<bool> _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind> _usedNameKinds;
  List<int> _usedNameOffsets;
  List<int> _usedNames;

  @override
  List<idl.IndexNameKind> get definedNameKinds {
    _definedNameKinds ??=
        const fb.ListReader<idl.IndexNameKind>(const _IndexNameKindReader())
            .vTableGet(_bc, _bcOffset, 6, const <idl.IndexNameKind>[]);
    return _definedNameKinds;
  }

  @override
  List<int> get definedNameOffsets {
    _definedNameOffsets ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
    return _definedNameOffsets;
  }

  @override
  List<int> get definedNames {
    _definedNames ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _definedNames;
  }

  @override
  int get unit {
    _unit ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _unit;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags {
    _usedElementIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 11, const <bool>[]);
    return _usedElementIsQualifiedFlags;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds {
    _usedElementKinds ??= const fb.ListReader<idl.IndexRelationKind>(
            const _IndexRelationKindReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.IndexRelationKind>[]);
    return _usedElementKinds;
  }

  @override
  List<int> get usedElementLengths {
    _usedElementLengths ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
    return _usedElementLengths;
  }

  @override
  List<int> get usedElementOffsets {
    _usedElementOffsets ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
    return _usedElementOffsets;
  }

  @override
  List<int> get usedElements {
    _usedElements ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
    return _usedElements;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags {
    _usedNameIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 12, const <bool>[]);
    return _usedNameIsQualifiedFlags;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds {
    _usedNameKinds ??= const fb.ListReader<idl.IndexRelationKind>(
            const _IndexRelationKindReader())
        .vTableGet(_bc, _bcOffset, 10, const <idl.IndexRelationKind>[]);
    return _usedNameKinds;
  }

  @override
  List<int> get usedNameOffsets {
    _usedNameOffsets ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 9, const <int>[]);
    return _usedNameOffsets;
  }

  @override
  List<int> get usedNames {
    _usedNames ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 8, const <int>[]);
    return _usedNames;
  }
}

abstract class _UnitIndexMixin implements idl.UnitIndex {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (definedNameKinds.isNotEmpty)
      _result["definedNameKinds"] = definedNameKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (definedNameOffsets.isNotEmpty)
      _result["definedNameOffsets"] = definedNameOffsets;
    if (definedNames.isNotEmpty) _result["definedNames"] = definedNames;
    if (unit != 0) _result["unit"] = unit;
    if (usedElementIsQualifiedFlags.isNotEmpty)
      _result["usedElementIsQualifiedFlags"] = usedElementIsQualifiedFlags;
    if (usedElementKinds.isNotEmpty)
      _result["usedElementKinds"] = usedElementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (usedElementLengths.isNotEmpty)
      _result["usedElementLengths"] = usedElementLengths;
    if (usedElementOffsets.isNotEmpty)
      _result["usedElementOffsets"] = usedElementOffsets;
    if (usedElements.isNotEmpty) _result["usedElements"] = usedElements;
    if (usedNameIsQualifiedFlags.isNotEmpty)
      _result["usedNameIsQualifiedFlags"] = usedNameIsQualifiedFlags;
    if (usedNameKinds.isNotEmpty)
      _result["usedNameKinds"] = usedNameKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (usedNameOffsets.isNotEmpty)
      _result["usedNameOffsets"] = usedNameOffsets;
    if (usedNames.isNotEmpty) _result["usedNames"] = usedNames;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "definedNameKinds": definedNameKinds,
        "definedNameOffsets": definedNameOffsets,
        "definedNames": definedNames,
        "unit": unit,
        "usedElementIsQualifiedFlags": usedElementIsQualifiedFlags,
        "usedElementKinds": usedElementKinds,
        "usedElementLengths": usedElementLengths,
        "usedElementOffsets": usedElementOffsets,
        "usedElements": usedElements,
        "usedNameIsQualifiedFlags": usedNameIsQualifiedFlags,
        "usedNameKinds": usedNameKinds,
        "usedNameOffsets": usedNameOffsets,
        "usedNames": usedNames,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedClassBuilder extends Object
    with _UnlinkedClassMixin
    implements idl.UnlinkedClass {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedExecutableBuilder> _executables;
  List<UnlinkedVariableBuilder> _fields;
  bool _hasNoSupertype;
  List<EntityRefBuilder> _interfaces;
  bool _isAbstract;
  bool _isMixinApplication;
  List<EntityRefBuilder> _mixins;
  String _name;
  int _nameOffset;
  int _notSimplyBoundedSlot;
  List<EntityRefBuilder> _superclassConstraints;
  List<String> _superInvokedNames;
  EntityRefBuilder _supertype;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this class.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the class.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the class, or `null` if there is no
  /// documentation comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables =>
      _executables ??= <UnlinkedExecutableBuilder>[];

  /// Executable objects (methods, getters, and setters) contained in the class.
  set executables(List<UnlinkedExecutableBuilder> value) {
    this._executables = value;
  }

  @override
  List<UnlinkedVariableBuilder> get fields =>
      _fields ??= <UnlinkedVariableBuilder>[];

  /// Field declarations contained in the class.
  set fields(List<UnlinkedVariableBuilder> value) {
    this._fields = value;
  }

  @override
  bool get hasNoSupertype => _hasNoSupertype ??= false;

  /// Indicates whether this class is the core "Object" class (and hence has no
  /// supertype)
  set hasNoSupertype(bool value) {
    this._hasNoSupertype = value;
  }

  @override
  List<EntityRefBuilder> get interfaces => _interfaces ??= <EntityRefBuilder>[];

  /// Interfaces appearing in an `implements` clause, if any.
  set interfaces(List<EntityRefBuilder> value) {
    this._interfaces = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /// Indicates whether the class is declared with the `abstract` keyword.
  set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isMixinApplication => _isMixinApplication ??= false;

  /// Indicates whether the class is declared using mixin application syntax.
  set isMixinApplication(bool value) {
    this._isMixinApplication = value;
  }

  @override
  List<EntityRefBuilder> get mixins => _mixins ??= <EntityRefBuilder>[];

  /// Mixins appearing in a `with` clause, if any.
  set mixins(List<EntityRefBuilder> value) {
    this._mixins = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the class.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the class name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  int get notSimplyBoundedSlot => _notSimplyBoundedSlot ??= 0;

  /// If the class might not be simply bounded, a nonzero slot id which is unique
  /// within this compilation unit.  If this id is found in
  /// [LinkedUnit.notSimplyBounded], then at least one of this class's type
  /// parameters is not simply bounded, hence this class can't be used as a raw
  /// type when specifying the bound of a type parameter.
  ///
  /// Otherwise, zero.
  set notSimplyBoundedSlot(int value) {
    assert(value == null || value >= 0);
    this._notSimplyBoundedSlot = value;
  }

  @override
  List<EntityRefBuilder> get superclassConstraints =>
      _superclassConstraints ??= <EntityRefBuilder>[];

  /// Superclass constraints for this mixin declaration. The list will be empty
  /// if this class is not a mixin declaration, or if the declaration does not
  /// have an `on` clause (in which case the type `Object` is implied).
  set superclassConstraints(List<EntityRefBuilder> value) {
    this._superclassConstraints = value;
  }

  @override
  List<String> get superInvokedNames => _superInvokedNames ??= <String>[];

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  set superInvokedNames(List<String> value) {
    this._superInvokedNames = value;
  }

  @override
  EntityRefBuilder get supertype => _supertype;

  /// Supertype of the class, or `null` if either (a) the class doesn't
  /// explicitly declare a supertype (and hence has supertype `Object`), or (b)
  /// the class *is* `Object` (and hence has no supertype).
  set supertype(EntityRefBuilder value) {
    this._supertype = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /// Type parameters of the class, if any.
  set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  UnlinkedClassBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      UnlinkedDocumentationCommentBuilder documentationComment,
      List<UnlinkedExecutableBuilder> executables,
      List<UnlinkedVariableBuilder> fields,
      bool hasNoSupertype,
      List<EntityRefBuilder> interfaces,
      bool isAbstract,
      bool isMixinApplication,
      List<EntityRefBuilder> mixins,
      String name,
      int nameOffset,
      int notSimplyBoundedSlot,
      List<EntityRefBuilder> superclassConstraints,
      List<String> superInvokedNames,
      EntityRefBuilder supertype,
      List<UnlinkedTypeParamBuilder> typeParameters})
      : _annotations = annotations,
        _codeRange = codeRange,
        _documentationComment = documentationComment,
        _executables = executables,
        _fields = fields,
        _hasNoSupertype = hasNoSupertype,
        _interfaces = interfaces,
        _isAbstract = isAbstract,
        _isMixinApplication = isMixinApplication,
        _mixins = mixins,
        _name = name,
        _nameOffset = nameOffset,
        _notSimplyBoundedSlot = notSimplyBoundedSlot,
        _superclassConstraints = superclassConstraints,
        _superInvokedNames = superInvokedNames,
        _supertype = supertype,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _executables?.forEach((b) => b.flushInformative());
    _fields?.forEach((b) => b.flushInformative());
    _interfaces?.forEach((b) => b.flushInformative());
    _mixins?.forEach((b) => b.flushInformative());
    _nameOffset = null;
    _superclassConstraints?.forEach((b) => b.flushInformative());
    _supertype?.flushInformative();
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    if (this._executables == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._executables.length);
      for (var x in this._executables) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._supertype != null);
    this._supertype?.collectApiSignature(signature);
    if (this._fields == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._fields.length);
      for (var x in this._fields) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._interfaces == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._interfaces.length);
      for (var x in this._interfaces) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isAbstract == true);
    if (this._typeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeParameters.length);
      for (var x in this._typeParameters) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._mixins == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._mixins.length);
      for (var x in this._mixins) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isMixinApplication == true);
    signature.addBool(this._hasNoSupertype == true);
    if (this._superclassConstraints == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._superclassConstraints.length);
      for (var x in this._superclassConstraints) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._superInvokedNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._superInvokedNames.length);
      for (var x in this._superInvokedNames) {
        signature.addString(x);
      }
    }
    signature.addInt(this._notSimplyBoundedSlot ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_codeRange;
    fb.Offset offset_documentationComment;
    fb.Offset offset_executables;
    fb.Offset offset_fields;
    fb.Offset offset_interfaces;
    fb.Offset offset_mixins;
    fb.Offset offset_name;
    fb.Offset offset_superclassConstraints;
    fb.Offset offset_superInvokedNames;
    fb.Offset offset_supertype;
    fb.Offset offset_typeParameters;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_executables == null || _executables.isEmpty)) {
      offset_executables = fbBuilder
          .writeList(_executables.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_fields == null || _fields.isEmpty)) {
      offset_fields =
          fbBuilder.writeList(_fields.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_interfaces == null || _interfaces.isEmpty)) {
      offset_interfaces = fbBuilder
          .writeList(_interfaces.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_mixins == null || _mixins.isEmpty)) {
      offset_mixins =
          fbBuilder.writeList(_mixins.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_superclassConstraints == null || _superclassConstraints.isEmpty)) {
      offset_superclassConstraints = fbBuilder.writeList(
          _superclassConstraints.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_superInvokedNames == null || _superInvokedNames.isEmpty)) {
      offset_superInvokedNames = fbBuilder.writeList(
          _superInvokedNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_supertype != null) {
      offset_supertype = _supertype.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder
          .writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(5, offset_annotations);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(13, offset_codeRange);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(6, offset_documentationComment);
    }
    if (offset_executables != null) {
      fbBuilder.addOffset(2, offset_executables);
    }
    if (offset_fields != null) {
      fbBuilder.addOffset(4, offset_fields);
    }
    if (_hasNoSupertype == true) {
      fbBuilder.addBool(12, true);
    }
    if (offset_interfaces != null) {
      fbBuilder.addOffset(7, offset_interfaces);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(8, true);
    }
    if (_isMixinApplication == true) {
      fbBuilder.addBool(11, true);
    }
    if (offset_mixins != null) {
      fbBuilder.addOffset(10, offset_mixins);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (_notSimplyBoundedSlot != null && _notSimplyBoundedSlot != 0) {
      fbBuilder.addUint32(16, _notSimplyBoundedSlot);
    }
    if (offset_superclassConstraints != null) {
      fbBuilder.addOffset(14, offset_superclassConstraints);
    }
    if (offset_superInvokedNames != null) {
      fbBuilder.addOffset(15, offset_superInvokedNames);
    }
    if (offset_supertype != null) {
      fbBuilder.addOffset(3, offset_supertype);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(9, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedClassReader extends fb.TableReader<_UnlinkedClassImpl> {
  const _UnlinkedClassReader();

  @override
  _UnlinkedClassImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedClassImpl(bc, offset);
}

class _UnlinkedClassImpl extends Object
    with _UnlinkedClassMixin
    implements idl.UnlinkedClass {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedClassImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.CodeRange _codeRange;
  idl.UnlinkedDocumentationComment _documentationComment;
  List<idl.UnlinkedExecutable> _executables;
  List<idl.UnlinkedVariable> _fields;
  bool _hasNoSupertype;
  List<idl.EntityRef> _interfaces;
  bool _isAbstract;
  bool _isMixinApplication;
  List<idl.EntityRef> _mixins;
  String _name;
  int _nameOffset;
  int _notSimplyBoundedSlot;
  List<idl.EntityRef> _superclassConstraints;
  List<String> _superInvokedNames;
  idl.EntityRef _supertype;
  List<idl.UnlinkedTypeParam> _typeParameters;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 13, null);
    return _codeRange;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 6, null);
    return _documentationComment;
  }

  @override
  List<idl.UnlinkedExecutable> get executables {
    _executables ??= const fb.ListReader<idl.UnlinkedExecutable>(
            const _UnlinkedExecutableReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedExecutable>[]);
    return _executables;
  }

  @override
  List<idl.UnlinkedVariable> get fields {
    _fields ??= const fb.ListReader<idl.UnlinkedVariable>(
            const _UnlinkedVariableReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.UnlinkedVariable>[]);
    return _fields;
  }

  @override
  bool get hasNoSupertype {
    _hasNoSupertype ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 12, false);
    return _hasNoSupertype;
  }

  @override
  List<idl.EntityRef> get interfaces {
    _interfaces ??= const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
        .vTableGet(_bc, _bcOffset, 7, const <idl.EntityRef>[]);
    return _interfaces;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 8, false);
    return _isAbstract;
  }

  @override
  bool get isMixinApplication {
    _isMixinApplication ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 11, false);
    return _isMixinApplication;
  }

  @override
  List<idl.EntityRef> get mixins {
    _mixins ??= const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
        .vTableGet(_bc, _bcOffset, 10, const <idl.EntityRef>[]);
    return _mixins;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  int get notSimplyBoundedSlot {
    _notSimplyBoundedSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _notSimplyBoundedSlot;
  }

  @override
  List<idl.EntityRef> get superclassConstraints {
    _superclassConstraints ??=
        const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
            .vTableGet(_bc, _bcOffset, 14, const <idl.EntityRef>[]);
    return _superclassConstraints;
  }

  @override
  List<String> get superInvokedNames {
    _superInvokedNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 15, const <String>[]);
    return _superInvokedNames;
  }

  @override
  idl.EntityRef get supertype {
    _supertype ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 3, null);
    return _supertype;
  }

  @override
  List<idl.UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<idl.UnlinkedTypeParam>(
            const _UnlinkedTypeParamReader())
        .vTableGet(_bc, _bcOffset, 9, const <idl.UnlinkedTypeParam>[]);
    return _typeParameters;
  }
}

abstract class _UnlinkedClassMixin implements idl.UnlinkedClass {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (executables.isNotEmpty)
      _result["executables"] =
          executables.map((_value) => _value.toJson()).toList();
    if (fields.isNotEmpty)
      _result["fields"] = fields.map((_value) => _value.toJson()).toList();
    if (hasNoSupertype != false) _result["hasNoSupertype"] = hasNoSupertype;
    if (interfaces.isNotEmpty)
      _result["interfaces"] =
          interfaces.map((_value) => _value.toJson()).toList();
    if (isAbstract != false) _result["isAbstract"] = isAbstract;
    if (isMixinApplication != false)
      _result["isMixinApplication"] = isMixinApplication;
    if (mixins.isNotEmpty)
      _result["mixins"] = mixins.map((_value) => _value.toJson()).toList();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (notSimplyBoundedSlot != 0)
      _result["notSimplyBoundedSlot"] = notSimplyBoundedSlot;
    if (superclassConstraints.isNotEmpty)
      _result["superclassConstraints"] =
          superclassConstraints.map((_value) => _value.toJson()).toList();
    if (superInvokedNames.isNotEmpty)
      _result["superInvokedNames"] = superInvokedNames;
    if (supertype != null) _result["supertype"] = supertype.toJson();
    if (typeParameters.isNotEmpty)
      _result["typeParameters"] =
          typeParameters.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "codeRange": codeRange,
        "documentationComment": documentationComment,
        "executables": executables,
        "fields": fields,
        "hasNoSupertype": hasNoSupertype,
        "interfaces": interfaces,
        "isAbstract": isAbstract,
        "isMixinApplication": isMixinApplication,
        "mixins": mixins,
        "name": name,
        "nameOffset": nameOffset,
        "notSimplyBoundedSlot": notSimplyBoundedSlot,
        "superclassConstraints": superclassConstraints,
        "superInvokedNames": superInvokedNames,
        "supertype": supertype,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedCombinatorBuilder extends Object
    with _UnlinkedCombinatorMixin
    implements idl.UnlinkedCombinator {
  int _end;
  List<String> _hides;
  int _offset;
  List<String> _shows;

  @override
  int get end => _end ??= 0;

  /// If this is a `show` combinator, offset of the end of the list of shown
  /// names.  Otherwise zero.
  set end(int value) {
    assert(value == null || value >= 0);
    this._end = value;
  }

  @override
  List<String> get hides => _hides ??= <String>[];

  /// List of names which are hidden.  Empty if this is a `show` combinator.
  set hides(List<String> value) {
    this._hides = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// If this is a `show` combinator, offset of the `show` keyword.  Otherwise
  /// zero.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  List<String> get shows => _shows ??= <String>[];

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  set shows(List<String> value) {
    this._shows = value;
  }

  UnlinkedCombinatorBuilder(
      {int end, List<String> hides, int offset, List<String> shows})
      : _end = end,
        _hides = hides,
        _offset = offset,
        _shows = shows;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _end = null;
    _offset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._shows == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._shows.length);
      for (var x in this._shows) {
        signature.addString(x);
      }
    }
    if (this._hides == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._hides.length);
      for (var x in this._hides) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_hides;
    fb.Offset offset_shows;
    if (!(_hides == null || _hides.isEmpty)) {
      offset_hides = fbBuilder
          .writeList(_hides.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_shows == null || _shows.isEmpty)) {
      offset_shows = fbBuilder
          .writeList(_shows.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (_end != null && _end != 0) {
      fbBuilder.addUint32(3, _end);
    }
    if (offset_hides != null) {
      fbBuilder.addOffset(1, offset_hides);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(2, _offset);
    }
    if (offset_shows != null) {
      fbBuilder.addOffset(0, offset_shows);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedCombinatorReader
    extends fb.TableReader<_UnlinkedCombinatorImpl> {
  const _UnlinkedCombinatorReader();

  @override
  _UnlinkedCombinatorImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedCombinatorImpl(bc, offset);
}

class _UnlinkedCombinatorImpl extends Object
    with _UnlinkedCombinatorMixin
    implements idl.UnlinkedCombinator {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedCombinatorImpl(this._bc, this._bcOffset);

  int _end;
  List<String> _hides;
  int _offset;
  List<String> _shows;

  @override
  int get end {
    _end ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _end;
  }

  @override
  List<String> get hides {
    _hides ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _hides;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _offset;
  }

  @override
  List<String> get shows {
    _shows ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _shows;
  }
}

abstract class _UnlinkedCombinatorMixin implements idl.UnlinkedCombinator {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (end != 0) _result["end"] = end;
    if (hides.isNotEmpty) _result["hides"] = hides;
    if (offset != 0) _result["offset"] = offset;
    if (shows.isNotEmpty) _result["shows"] = shows;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "end": end,
        "hides": hides,
        "offset": offset,
        "shows": shows,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedConfigurationBuilder extends Object
    with _UnlinkedConfigurationMixin
    implements idl.UnlinkedConfiguration {
  String _name;
  String _uri;
  String _value;

  @override
  String get name => _name ??= '';

  /// The name of the declared variable whose value is being used in the
  /// condition.
  set name(String value) {
    this._name = value;
  }

  @override
  String get uri => _uri ??= '';

  /// The URI of the implementation library to be used if the condition is true.
  set uri(String value) {
    this._uri = value;
  }

  @override
  String get value => _value ??= '';

  /// The value to which the value of the declared variable will be compared,
  /// or `true` if the condition does not include an equality test.
  set value(String value) {
    this._value = value;
  }

  UnlinkedConfigurationBuilder({String name, String uri, String value})
      : _name = name,
        _uri = uri,
        _value = value;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addString(this._value ?? '');
    signature.addString(this._uri ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_uri;
    fb.Offset offset_value;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    if (_value != null) {
      offset_value = fbBuilder.writeString(_value);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(2, offset_uri);
    }
    if (offset_value != null) {
      fbBuilder.addOffset(1, offset_value);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedConfigurationReader
    extends fb.TableReader<_UnlinkedConfigurationImpl> {
  const _UnlinkedConfigurationReader();

  @override
  _UnlinkedConfigurationImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedConfigurationImpl(bc, offset);
}

class _UnlinkedConfigurationImpl extends Object
    with _UnlinkedConfigurationMixin
    implements idl.UnlinkedConfiguration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedConfigurationImpl(this._bc, this._bcOffset);

  String _name;
  String _uri;
  String _value;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _uri;
  }

  @override
  String get value {
    _value ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _value;
  }
}

abstract class _UnlinkedConfigurationMixin
    implements idl.UnlinkedConfiguration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (name != '') _result["name"] = name;
    if (uri != '') _result["uri"] = uri;
    if (value != '') _result["value"] = value;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "name": name,
        "uri": uri,
        "value": value,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedConstructorInitializerBuilder extends Object
    with _UnlinkedConstructorInitializerMixin
    implements idl.UnlinkedConstructorInitializer {
  List<String> _argumentNames;
  List<UnlinkedExprBuilder> _arguments;
  UnlinkedExprBuilder _expression;
  idl.UnlinkedConstructorInitializerKind _kind;
  String _name;

  @override
  List<String> get argumentNames => _argumentNames ??= <String>[];

  /// If there are `m` [arguments] and `n` [argumentNames], then each argument
  /// from [arguments] with index `i` such that `n + i - m >= 0`, should be used
  /// with the name at `n + i - m`.
  set argumentNames(List<String> value) {
    this._argumentNames = value;
  }

  @override
  List<UnlinkedExprBuilder> get arguments =>
      _arguments ??= <UnlinkedExprBuilder>[];

  /// If [kind] is `thisInvocation` or `superInvocation`, the arguments of the
  /// invocation.  Otherwise empty.
  set arguments(List<UnlinkedExprBuilder> value) {
    this._arguments = value;
  }

  @override
  UnlinkedExprBuilder get expression => _expression;

  /// If [kind] is `field`, the expression of the field initializer.
  /// Otherwise `null`.
  set expression(UnlinkedExprBuilder value) {
    this._expression = value;
  }

  @override
  idl.UnlinkedConstructorInitializerKind get kind =>
      _kind ??= idl.UnlinkedConstructorInitializerKind.field;

  /// The kind of the constructor initializer (field, redirect, super).
  set kind(idl.UnlinkedConstructorInitializerKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /// If [kind] is `field`, the name of the field declared in the class.  If
  /// [kind] is `thisInvocation`, the name of the constructor, declared in this
  /// class, to redirect to.  If [kind] is `superInvocation`, the name of the
  /// constructor, declared in the superclass, to invoke.
  set name(String value) {
    this._name = value;
  }

  UnlinkedConstructorInitializerBuilder(
      {List<String> argumentNames,
      List<UnlinkedExprBuilder> arguments,
      UnlinkedExprBuilder expression,
      idl.UnlinkedConstructorInitializerKind kind,
      String name})
      : _argumentNames = argumentNames,
        _arguments = arguments,
        _expression = expression,
        _kind = kind,
        _name = name;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _arguments?.forEach((b) => b.flushInformative());
    _expression?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addBool(this._expression != null);
    this._expression?.collectApiSignature(signature);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    if (this._arguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._arguments.length);
      for (var x in this._arguments) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._argumentNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._argumentNames.length);
      for (var x in this._argumentNames) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_argumentNames;
    fb.Offset offset_arguments;
    fb.Offset offset_expression;
    fb.Offset offset_name;
    if (!(_argumentNames == null || _argumentNames.isEmpty)) {
      offset_argumentNames = fbBuilder.writeList(
          _argumentNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_arguments == null || _arguments.isEmpty)) {
      offset_arguments = fbBuilder
          .writeList(_arguments.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_expression != null) {
      offset_expression = _expression.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_argumentNames != null) {
      fbBuilder.addOffset(4, offset_argumentNames);
    }
    if (offset_arguments != null) {
      fbBuilder.addOffset(3, offset_arguments);
    }
    if (offset_expression != null) {
      fbBuilder.addOffset(1, offset_expression);
    }
    if (_kind != null &&
        _kind != idl.UnlinkedConstructorInitializerKind.field) {
      fbBuilder.addUint8(2, _kind.index);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedConstructorInitializerReader
    extends fb.TableReader<_UnlinkedConstructorInitializerImpl> {
  const _UnlinkedConstructorInitializerReader();

  @override
  _UnlinkedConstructorInitializerImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _UnlinkedConstructorInitializerImpl(bc, offset);
}

class _UnlinkedConstructorInitializerImpl extends Object
    with _UnlinkedConstructorInitializerMixin
    implements idl.UnlinkedConstructorInitializer {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedConstructorInitializerImpl(this._bc, this._bcOffset);

  List<String> _argumentNames;
  List<idl.UnlinkedExpr> _arguments;
  idl.UnlinkedExpr _expression;
  idl.UnlinkedConstructorInitializerKind _kind;
  String _name;

  @override
  List<String> get argumentNames {
    _argumentNames ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _argumentNames;
  }

  @override
  List<idl.UnlinkedExpr> get arguments {
    _arguments ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedExpr>[]);
    return _arguments;
  }

  @override
  idl.UnlinkedExpr get expression {
    _expression ??=
        const _UnlinkedExprReader().vTableGet(_bc, _bcOffset, 1, null);
    return _expression;
  }

  @override
  idl.UnlinkedConstructorInitializerKind get kind {
    _kind ??= const _UnlinkedConstructorInitializerKindReader().vTableGet(
        _bc, _bcOffset, 2, idl.UnlinkedConstructorInitializerKind.field);
    return _kind;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }
}

abstract class _UnlinkedConstructorInitializerMixin
    implements idl.UnlinkedConstructorInitializer {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (argumentNames.isNotEmpty) _result["argumentNames"] = argumentNames;
    if (arguments.isNotEmpty)
      _result["arguments"] =
          arguments.map((_value) => _value.toJson()).toList();
    if (expression != null) _result["expression"] = expression.toJson();
    if (kind != idl.UnlinkedConstructorInitializerKind.field)
      _result["kind"] = kind.toString().split('.')[1];
    if (name != '') _result["name"] = name;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "argumentNames": argumentNames,
        "arguments": arguments,
        "expression": expression,
        "kind": kind,
        "name": name,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedDocumentationCommentBuilder extends Object
    with _UnlinkedDocumentationCommentMixin
    implements idl.UnlinkedDocumentationComment {
  String _text;

  @override
  Null get length =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get offset =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get text => _text ??= '';

  /// Text of the documentation comment, with '\r\n' replaced by '\n'.
  ///
  /// References appearing within the doc comment in square brackets are not
  /// specially encoded.
  set text(String value) {
    this._text = value;
  }

  UnlinkedDocumentationCommentBuilder({String text}) : _text = text;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._text ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_text;
    if (_text != null) {
      offset_text = fbBuilder.writeString(_text);
    }
    fbBuilder.startTable();
    if (offset_text != null) {
      fbBuilder.addOffset(1, offset_text);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedDocumentationCommentReader
    extends fb.TableReader<_UnlinkedDocumentationCommentImpl> {
  const _UnlinkedDocumentationCommentReader();

  @override
  _UnlinkedDocumentationCommentImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _UnlinkedDocumentationCommentImpl(bc, offset);
}

class _UnlinkedDocumentationCommentImpl extends Object
    with _UnlinkedDocumentationCommentMixin
    implements idl.UnlinkedDocumentationComment {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedDocumentationCommentImpl(this._bc, this._bcOffset);

  String _text;

  @override
  Null get length =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get offset =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get text {
    _text ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _text;
  }
}

abstract class _UnlinkedDocumentationCommentMixin
    implements idl.UnlinkedDocumentationComment {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (text != '') _result["text"] = text;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "text": text,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedEnumBuilder extends Object
    with _UnlinkedEnumMixin
    implements idl.UnlinkedEnum {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  String _name;
  int _nameOffset;
  List<UnlinkedEnumValueBuilder> _values;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this enum.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the enum.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the enum, or `null` if there is no documentation
  /// comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the enum type.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the enum name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedEnumValueBuilder> get values =>
      _values ??= <UnlinkedEnumValueBuilder>[];

  /// Values listed in the enum declaration, in declaration order.
  set values(List<UnlinkedEnumValueBuilder> value) {
    this._values = value;
  }

  UnlinkedEnumBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      UnlinkedDocumentationCommentBuilder documentationComment,
      String name,
      int nameOffset,
      List<UnlinkedEnumValueBuilder> values})
      : _annotations = annotations,
        _codeRange = codeRange,
        _documentationComment = documentationComment,
        _name = name,
        _nameOffset = nameOffset,
        _values = values;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _nameOffset = null;
    _values?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    if (this._values == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._values.length);
      for (var x in this._values) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_codeRange;
    fb.Offset offset_documentationComment;
    fb.Offset offset_name;
    fb.Offset offset_values;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_values == null || _values.isEmpty)) {
      offset_values =
          fbBuilder.writeList(_values.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(4, offset_annotations);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(5, offset_codeRange);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(3, offset_documentationComment);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_values != null) {
      fbBuilder.addOffset(2, offset_values);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedEnumReader extends fb.TableReader<_UnlinkedEnumImpl> {
  const _UnlinkedEnumReader();

  @override
  _UnlinkedEnumImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedEnumImpl(bc, offset);
}

class _UnlinkedEnumImpl extends Object
    with _UnlinkedEnumMixin
    implements idl.UnlinkedEnum {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedEnumImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.CodeRange _codeRange;
  idl.UnlinkedDocumentationComment _documentationComment;
  String _name;
  int _nameOffset;
  List<idl.UnlinkedEnumValue> _values;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 5, null);
    return _codeRange;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 3, null);
    return _documentationComment;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  List<idl.UnlinkedEnumValue> get values {
    _values ??= const fb.ListReader<idl.UnlinkedEnumValue>(
            const _UnlinkedEnumValueReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedEnumValue>[]);
    return _values;
  }
}

abstract class _UnlinkedEnumMixin implements idl.UnlinkedEnum {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (values.isNotEmpty)
      _result["values"] = values.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "codeRange": codeRange,
        "documentationComment": documentationComment,
        "name": name,
        "nameOffset": nameOffset,
        "values": values,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedEnumValueBuilder extends Object
    with _UnlinkedEnumValueMixin
    implements idl.UnlinkedEnumValue {
  List<UnlinkedExprBuilder> _annotations;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  String _name;
  int _nameOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this value.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the enum value, or `null` if there is no
  /// documentation comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the enumerated value.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the enum value name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  UnlinkedEnumValueBuilder(
      {List<UnlinkedExprBuilder> annotations,
      UnlinkedDocumentationCommentBuilder documentationComment,
      String name,
      int nameOffset})
      : _annotations = annotations,
        _documentationComment = documentationComment,
        _name = name,
        _nameOffset = nameOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _documentationComment = null;
    _nameOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_documentationComment;
    fb.Offset offset_name;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(3, offset_annotations);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedEnumValueReader extends fb.TableReader<_UnlinkedEnumValueImpl> {
  const _UnlinkedEnumValueReader();

  @override
  _UnlinkedEnumValueImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedEnumValueImpl(bc, offset);
}

class _UnlinkedEnumValueImpl extends Object
    with _UnlinkedEnumValueMixin
    implements idl.UnlinkedEnumValue {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedEnumValueImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.UnlinkedDocumentationComment _documentationComment;
  String _name;
  int _nameOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 2, null);
    return _documentationComment;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }
}

abstract class _UnlinkedEnumValueMixin implements idl.UnlinkedEnumValue {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "documentationComment": documentationComment,
        "name": name,
        "nameOffset": nameOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedExecutableBuilder extends Object
    with _UnlinkedExecutableMixin
    implements idl.UnlinkedExecutable {
  List<UnlinkedExprBuilder> _annotations;
  UnlinkedExprBuilder _bodyExpr;
  CodeRangeBuilder _codeRange;
  List<UnlinkedConstructorInitializerBuilder> _constantInitializers;
  int _constCycleSlot;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  int _inferredReturnTypeSlot;
  bool _isAbstract;
  bool _isAsynchronous;
  bool _isConst;
  bool _isExternal;
  bool _isFactory;
  bool _isGenerator;
  bool _isRedirectedConstructor;
  bool _isStatic;
  idl.UnlinkedExecutableKind _kind;
  List<UnlinkedExecutableBuilder> _localFunctions;
  String _name;
  int _nameEnd;
  int _nameOffset;
  List<UnlinkedParamBuilder> _parameters;
  int _periodOffset;
  EntityRefBuilder _redirectedConstructor;
  String _redirectedConstructorName;
  EntityRefBuilder _returnType;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  int _visibleLength;
  int _visibleOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this executable.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  UnlinkedExprBuilder get bodyExpr => _bodyExpr;

  /// If this executable's function body is declared using `=>`, the expression
  /// to the right of the `=>`.  May be omitted if neither type inference nor
  /// constant evaluation depends on the function body.
  set bodyExpr(UnlinkedExprBuilder value) {
    this._bodyExpr = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the executable.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  List<UnlinkedConstructorInitializerBuilder> get constantInitializers =>
      _constantInitializers ??= <UnlinkedConstructorInitializerBuilder>[];

  /// If a constant [UnlinkedExecutableKind.constructor], the constructor
  /// initializers.  Otherwise empty.
  set constantInitializers(List<UnlinkedConstructorInitializerBuilder> value) {
    this._constantInitializers = value;
  }

  @override
  int get constCycleSlot => _constCycleSlot ??= 0;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [isConst] is `true`,
  /// a nonzero slot id which is unique within this compilation unit.  If this
  /// id is found in [LinkedUnit.constCycles], then this constructor is part of
  /// a cycle.
  ///
  /// Otherwise, zero.
  set constCycleSlot(int value) {
    assert(value == null || value >= 0);
    this._constCycleSlot = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the executable, or `null` if there is no
  /// documentation comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  int get inferredReturnTypeSlot => _inferredReturnTypeSlot ??= 0;

  /// If this executable's return type is inferable, nonzero slot id
  /// identifying which entry in [LinkedUnit.types] contains the inferred
  /// return type.  If there is no matching entry in [LinkedUnit.types], then
  /// no return type was inferred for this variable, so its static type is
  /// `dynamic`.
  set inferredReturnTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredReturnTypeSlot = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /// Indicates whether the executable is declared using the `abstract` keyword.
  set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isAsynchronous => _isAsynchronous ??= false;

  /// Indicates whether the executable has body marked as being asynchronous.
  set isAsynchronous(bool value) {
    this._isAsynchronous = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /// Indicates whether the executable is declared using the `const` keyword.
  set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isExternal => _isExternal ??= false;

  /// Indicates whether the executable is declared using the `external` keyword.
  set isExternal(bool value) {
    this._isExternal = value;
  }

  @override
  bool get isFactory => _isFactory ??= false;

  /// Indicates whether the executable is declared using the `factory` keyword.
  set isFactory(bool value) {
    this._isFactory = value;
  }

  @override
  bool get isGenerator => _isGenerator ??= false;

  /// Indicates whether the executable has body marked as being a generator.
  set isGenerator(bool value) {
    this._isGenerator = value;
  }

  @override
  bool get isRedirectedConstructor => _isRedirectedConstructor ??= false;

  /// Indicates whether the executable is a redirected constructor.
  set isRedirectedConstructor(bool value) {
    this._isRedirectedConstructor = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /// Indicates whether the executable is declared using the `static` keyword.
  ///
  /// Note that for top level executables, this flag is false, since they are
  /// not declared using the `static` keyword (even though they are considered
  /// static for semantic purposes).
  set isStatic(bool value) {
    this._isStatic = value;
  }

  @override
  idl.UnlinkedExecutableKind get kind =>
      _kind ??= idl.UnlinkedExecutableKind.functionOrMethod;

  /// The kind of the executable (function/method, getter, setter, or
  /// constructor).
  set kind(idl.UnlinkedExecutableKind value) {
    this._kind = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get localFunctions =>
      _localFunctions ??= <UnlinkedExecutableBuilder>[];

  /// The list of local functions.
  set localFunctions(List<UnlinkedExecutableBuilder> value) {
    this._localFunctions = value;
  }

  @override
  Null get localLabels =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get localVariables =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name => _name ??= '';

  /// Name of the executable.  For setters, this includes the trailing "=".  For
  /// named constructors, this excludes the class name and excludes the ".".
  /// For unnamed constructors, this is the empty string.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameEnd => _nameEnd ??= 0;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
  /// the offset of the end of the constructor name.  Otherwise zero.
  set nameEnd(int value) {
    assert(value == null || value >= 0);
    this._nameEnd = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the executable name relative to the beginning of the file.  For
  /// named constructors, this excludes the class name and excludes the ".".
  /// For unnamed constructors, this is the offset of the class name (i.e. the
  /// offset of the second "C" in "class C { C(); }").
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /// Parameters of the executable, if any.  Note that getters have no
  /// parameters (hence this will be the empty list), and setters have a single
  /// parameter.
  set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  int get periodOffset => _periodOffset ??= 0;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
  /// the offset of the period before the constructor name.  Otherwise zero.
  set periodOffset(int value) {
    assert(value == null || value >= 0);
    this._periodOffset = value;
  }

  @override
  EntityRefBuilder get redirectedConstructor => _redirectedConstructor;

  /// If [isRedirectedConstructor] and [isFactory] are both `true`, the
  /// constructor to which this constructor redirects; otherwise empty.
  set redirectedConstructor(EntityRefBuilder value) {
    this._redirectedConstructor = value;
  }

  @override
  String get redirectedConstructorName => _redirectedConstructorName ??= '';

  /// If [isRedirectedConstructor] is `true` and [isFactory] is `false`, the
  /// name of the constructor that this constructor redirects to; otherwise
  /// empty.
  set redirectedConstructorName(String value) {
    this._redirectedConstructorName = value;
  }

  @override
  EntityRefBuilder get returnType => _returnType;

  /// Declared return type of the executable.  Absent if the executable is a
  /// constructor or the return type is implicit.  Absent for executables
  /// associated with variable initializers and closures, since these
  /// executables may have return types that are not accessible via direct
  /// imports.
  set returnType(EntityRefBuilder value) {
    this._returnType = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /// Type parameters of the executable, if any.  Empty if support for generic
  /// method syntax is disabled.
  set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  @override
  int get visibleLength => _visibleLength ??= 0;

  /// If a local function, the length of the visible range; zero otherwise.
  set visibleLength(int value) {
    assert(value == null || value >= 0);
    this._visibleLength = value;
  }

  @override
  int get visibleOffset => _visibleOffset ??= 0;

  /// If a local function, the beginning of the visible range; zero otherwise.
  set visibleOffset(int value) {
    assert(value == null || value >= 0);
    this._visibleOffset = value;
  }

  UnlinkedExecutableBuilder(
      {List<UnlinkedExprBuilder> annotations,
      UnlinkedExprBuilder bodyExpr,
      CodeRangeBuilder codeRange,
      List<UnlinkedConstructorInitializerBuilder> constantInitializers,
      int constCycleSlot,
      UnlinkedDocumentationCommentBuilder documentationComment,
      int inferredReturnTypeSlot,
      bool isAbstract,
      bool isAsynchronous,
      bool isConst,
      bool isExternal,
      bool isFactory,
      bool isGenerator,
      bool isRedirectedConstructor,
      bool isStatic,
      idl.UnlinkedExecutableKind kind,
      List<UnlinkedExecutableBuilder> localFunctions,
      String name,
      int nameEnd,
      int nameOffset,
      List<UnlinkedParamBuilder> parameters,
      int periodOffset,
      EntityRefBuilder redirectedConstructor,
      String redirectedConstructorName,
      EntityRefBuilder returnType,
      List<UnlinkedTypeParamBuilder> typeParameters,
      int visibleLength,
      int visibleOffset})
      : _annotations = annotations,
        _bodyExpr = bodyExpr,
        _codeRange = codeRange,
        _constantInitializers = constantInitializers,
        _constCycleSlot = constCycleSlot,
        _documentationComment = documentationComment,
        _inferredReturnTypeSlot = inferredReturnTypeSlot,
        _isAbstract = isAbstract,
        _isAsynchronous = isAsynchronous,
        _isConst = isConst,
        _isExternal = isExternal,
        _isFactory = isFactory,
        _isGenerator = isGenerator,
        _isRedirectedConstructor = isRedirectedConstructor,
        _isStatic = isStatic,
        _kind = kind,
        _localFunctions = localFunctions,
        _name = name,
        _nameEnd = nameEnd,
        _nameOffset = nameOffset,
        _parameters = parameters,
        _periodOffset = periodOffset,
        _redirectedConstructor = redirectedConstructor,
        _redirectedConstructorName = redirectedConstructorName,
        _returnType = returnType,
        _typeParameters = typeParameters,
        _visibleLength = visibleLength,
        _visibleOffset = visibleOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _bodyExpr?.flushInformative();
    _codeRange = null;
    _constantInitializers?.forEach((b) => b.flushInformative());
    _documentationComment = null;
    _isAsynchronous = null;
    _isGenerator = null;
    _localFunctions?.forEach((b) => b.flushInformative());
    _nameEnd = null;
    _nameOffset = null;
    _parameters?.forEach((b) => b.flushInformative());
    _periodOffset = null;
    _redirectedConstructor?.flushInformative();
    _returnType?.flushInformative();
    _typeParameters?.forEach((b) => b.flushInformative());
    _visibleLength = null;
    _visibleOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    if (this._parameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parameters.length);
      for (var x in this._parameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._returnType != null);
    this._returnType?.collectApiSignature(signature);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addInt(this._inferredReturnTypeSlot ?? 0);
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isFactory == true);
    signature.addBool(this._isStatic == true);
    signature.addBool(this._isAbstract == true);
    signature.addBool(this._isExternal == true);
    signature.addBool(this._isConst == true);
    signature.addBool(this._isRedirectedConstructor == true);
    if (this._constantInitializers == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._constantInitializers.length);
      for (var x in this._constantInitializers) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._redirectedConstructor != null);
    this._redirectedConstructor?.collectApiSignature(signature);
    if (this._typeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeParameters.length);
      for (var x in this._typeParameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addString(this._redirectedConstructorName ?? '');
    if (this._localFunctions == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._localFunctions.length);
      for (var x in this._localFunctions) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._constCycleSlot ?? 0);
    signature.addBool(this._bodyExpr != null);
    this._bodyExpr?.collectApiSignature(signature);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_bodyExpr;
    fb.Offset offset_codeRange;
    fb.Offset offset_constantInitializers;
    fb.Offset offset_documentationComment;
    fb.Offset offset_localFunctions;
    fb.Offset offset_name;
    fb.Offset offset_parameters;
    fb.Offset offset_redirectedConstructor;
    fb.Offset offset_redirectedConstructorName;
    fb.Offset offset_returnType;
    fb.Offset offset_typeParameters;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_bodyExpr != null) {
      offset_bodyExpr = _bodyExpr.finish(fbBuilder);
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (!(_constantInitializers == null || _constantInitializers.isEmpty)) {
      offset_constantInitializers = fbBuilder.writeList(
          _constantInitializers.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_localFunctions == null || _localFunctions.isEmpty)) {
      offset_localFunctions = fbBuilder
          .writeList(_localFunctions.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder
          .writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_redirectedConstructor != null) {
      offset_redirectedConstructor = _redirectedConstructor.finish(fbBuilder);
    }
    if (_redirectedConstructorName != null) {
      offset_redirectedConstructorName =
          fbBuilder.writeString(_redirectedConstructorName);
    }
    if (_returnType != null) {
      offset_returnType = _returnType.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder
          .writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(6, offset_annotations);
    }
    if (offset_bodyExpr != null) {
      fbBuilder.addOffset(29, offset_bodyExpr);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(26, offset_codeRange);
    }
    if (offset_constantInitializers != null) {
      fbBuilder.addOffset(14, offset_constantInitializers);
    }
    if (_constCycleSlot != null && _constCycleSlot != 0) {
      fbBuilder.addUint32(25, _constCycleSlot);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(7, offset_documentationComment);
    }
    if (_inferredReturnTypeSlot != null && _inferredReturnTypeSlot != 0) {
      fbBuilder.addUint32(5, _inferredReturnTypeSlot);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(10, true);
    }
    if (_isAsynchronous == true) {
      fbBuilder.addBool(27, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(12, true);
    }
    if (_isExternal == true) {
      fbBuilder.addBool(11, true);
    }
    if (_isFactory == true) {
      fbBuilder.addBool(8, true);
    }
    if (_isGenerator == true) {
      fbBuilder.addBool(28, true);
    }
    if (_isRedirectedConstructor == true) {
      fbBuilder.addBool(13, true);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(9, true);
    }
    if (_kind != null && _kind != idl.UnlinkedExecutableKind.functionOrMethod) {
      fbBuilder.addUint8(4, _kind.index);
    }
    if (offset_localFunctions != null) {
      fbBuilder.addOffset(18, offset_localFunctions);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(1, offset_name);
    }
    if (_nameEnd != null && _nameEnd != 0) {
      fbBuilder.addUint32(23, _nameEnd);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(0, _nameOffset);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(2, offset_parameters);
    }
    if (_periodOffset != null && _periodOffset != 0) {
      fbBuilder.addUint32(24, _periodOffset);
    }
    if (offset_redirectedConstructor != null) {
      fbBuilder.addOffset(15, offset_redirectedConstructor);
    }
    if (offset_redirectedConstructorName != null) {
      fbBuilder.addOffset(17, offset_redirectedConstructorName);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(3, offset_returnType);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(16, offset_typeParameters);
    }
    if (_visibleLength != null && _visibleLength != 0) {
      fbBuilder.addUint32(20, _visibleLength);
    }
    if (_visibleOffset != null && _visibleOffset != 0) {
      fbBuilder.addUint32(21, _visibleOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedExecutableReader
    extends fb.TableReader<_UnlinkedExecutableImpl> {
  const _UnlinkedExecutableReader();

  @override
  _UnlinkedExecutableImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedExecutableImpl(bc, offset);
}

class _UnlinkedExecutableImpl extends Object
    with _UnlinkedExecutableMixin
    implements idl.UnlinkedExecutable {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedExecutableImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.UnlinkedExpr _bodyExpr;
  idl.CodeRange _codeRange;
  List<idl.UnlinkedConstructorInitializer> _constantInitializers;
  int _constCycleSlot;
  idl.UnlinkedDocumentationComment _documentationComment;
  int _inferredReturnTypeSlot;
  bool _isAbstract;
  bool _isAsynchronous;
  bool _isConst;
  bool _isExternal;
  bool _isFactory;
  bool _isGenerator;
  bool _isRedirectedConstructor;
  bool _isStatic;
  idl.UnlinkedExecutableKind _kind;
  List<idl.UnlinkedExecutable> _localFunctions;
  String _name;
  int _nameEnd;
  int _nameOffset;
  List<idl.UnlinkedParam> _parameters;
  int _periodOffset;
  idl.EntityRef _redirectedConstructor;
  String _redirectedConstructorName;
  idl.EntityRef _returnType;
  List<idl.UnlinkedTypeParam> _typeParameters;
  int _visibleLength;
  int _visibleOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 6, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.UnlinkedExpr get bodyExpr {
    _bodyExpr ??=
        const _UnlinkedExprReader().vTableGet(_bc, _bcOffset, 29, null);
    return _bodyExpr;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 26, null);
    return _codeRange;
  }

  @override
  List<idl.UnlinkedConstructorInitializer> get constantInitializers {
    _constantInitializers ??=
        const fb.ListReader<idl.UnlinkedConstructorInitializer>(
                const _UnlinkedConstructorInitializerReader())
            .vTableGet(_bc, _bcOffset, 14,
                const <idl.UnlinkedConstructorInitializer>[]);
    return _constantInitializers;
  }

  @override
  int get constCycleSlot {
    _constCycleSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 25, 0);
    return _constCycleSlot;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 7, null);
    return _documentationComment;
  }

  @override
  int get inferredReturnTypeSlot {
    _inferredReturnTypeSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _inferredReturnTypeSlot;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 10, false);
    return _isAbstract;
  }

  @override
  bool get isAsynchronous {
    _isAsynchronous ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 27, false);
    return _isAsynchronous;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 12, false);
    return _isConst;
  }

  @override
  bool get isExternal {
    _isExternal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 11, false);
    return _isExternal;
  }

  @override
  bool get isFactory {
    _isFactory ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 8, false);
    return _isFactory;
  }

  @override
  bool get isGenerator {
    _isGenerator ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 28, false);
    return _isGenerator;
  }

  @override
  bool get isRedirectedConstructor {
    _isRedirectedConstructor ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 13, false);
    return _isRedirectedConstructor;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 9, false);
    return _isStatic;
  }

  @override
  idl.UnlinkedExecutableKind get kind {
    _kind ??= const _UnlinkedExecutableKindReader().vTableGet(
        _bc, _bcOffset, 4, idl.UnlinkedExecutableKind.functionOrMethod);
    return _kind;
  }

  @override
  List<idl.UnlinkedExecutable> get localFunctions {
    _localFunctions ??= const fb.ListReader<idl.UnlinkedExecutable>(
            const _UnlinkedExecutableReader())
        .vTableGet(_bc, _bcOffset, 18, const <idl.UnlinkedExecutable>[]);
    return _localFunctions;
  }

  @override
  Null get localLabels =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get localVariables =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _name;
  }

  @override
  int get nameEnd {
    _nameEnd ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 23, 0);
    return _nameEnd;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _nameOffset;
  }

  @override
  List<idl.UnlinkedParam> get parameters {
    _parameters ??=
        const fb.ListReader<idl.UnlinkedParam>(const _UnlinkedParamReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedParam>[]);
    return _parameters;
  }

  @override
  int get periodOffset {
    _periodOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 24, 0);
    return _periodOffset;
  }

  @override
  idl.EntityRef get redirectedConstructor {
    _redirectedConstructor ??=
        const _EntityRefReader().vTableGet(_bc, _bcOffset, 15, null);
    return _redirectedConstructor;
  }

  @override
  String get redirectedConstructorName {
    _redirectedConstructorName ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 17, '');
    return _redirectedConstructorName;
  }

  @override
  idl.EntityRef get returnType {
    _returnType ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 3, null);
    return _returnType;
  }

  @override
  List<idl.UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<idl.UnlinkedTypeParam>(
            const _UnlinkedTypeParamReader())
        .vTableGet(_bc, _bcOffset, 16, const <idl.UnlinkedTypeParam>[]);
    return _typeParameters;
  }

  @override
  int get visibleLength {
    _visibleLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 20, 0);
    return _visibleLength;
  }

  @override
  int get visibleOffset {
    _visibleOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 21, 0);
    return _visibleOffset;
  }
}

abstract class _UnlinkedExecutableMixin implements idl.UnlinkedExecutable {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (bodyExpr != null) _result["bodyExpr"] = bodyExpr.toJson();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (constantInitializers.isNotEmpty)
      _result["constantInitializers"] =
          constantInitializers.map((_value) => _value.toJson()).toList();
    if (constCycleSlot != 0) _result["constCycleSlot"] = constCycleSlot;
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (inferredReturnTypeSlot != 0)
      _result["inferredReturnTypeSlot"] = inferredReturnTypeSlot;
    if (isAbstract != false) _result["isAbstract"] = isAbstract;
    if (isAsynchronous != false) _result["isAsynchronous"] = isAsynchronous;
    if (isConst != false) _result["isConst"] = isConst;
    if (isExternal != false) _result["isExternal"] = isExternal;
    if (isFactory != false) _result["isFactory"] = isFactory;
    if (isGenerator != false) _result["isGenerator"] = isGenerator;
    if (isRedirectedConstructor != false)
      _result["isRedirectedConstructor"] = isRedirectedConstructor;
    if (isStatic != false) _result["isStatic"] = isStatic;
    if (kind != idl.UnlinkedExecutableKind.functionOrMethod)
      _result["kind"] = kind.toString().split('.')[1];
    if (localFunctions.isNotEmpty)
      _result["localFunctions"] =
          localFunctions.map((_value) => _value.toJson()).toList();
    if (name != '') _result["name"] = name;
    if (nameEnd != 0) _result["nameEnd"] = nameEnd;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (parameters.isNotEmpty)
      _result["parameters"] =
          parameters.map((_value) => _value.toJson()).toList();
    if (periodOffset != 0) _result["periodOffset"] = periodOffset;
    if (redirectedConstructor != null)
      _result["redirectedConstructor"] = redirectedConstructor.toJson();
    if (redirectedConstructorName != '')
      _result["redirectedConstructorName"] = redirectedConstructorName;
    if (returnType != null) _result["returnType"] = returnType.toJson();
    if (typeParameters.isNotEmpty)
      _result["typeParameters"] =
          typeParameters.map((_value) => _value.toJson()).toList();
    if (visibleLength != 0) _result["visibleLength"] = visibleLength;
    if (visibleOffset != 0) _result["visibleOffset"] = visibleOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "bodyExpr": bodyExpr,
        "codeRange": codeRange,
        "constantInitializers": constantInitializers,
        "constCycleSlot": constCycleSlot,
        "documentationComment": documentationComment,
        "inferredReturnTypeSlot": inferredReturnTypeSlot,
        "isAbstract": isAbstract,
        "isAsynchronous": isAsynchronous,
        "isConst": isConst,
        "isExternal": isExternal,
        "isFactory": isFactory,
        "isGenerator": isGenerator,
        "isRedirectedConstructor": isRedirectedConstructor,
        "isStatic": isStatic,
        "kind": kind,
        "localFunctions": localFunctions,
        "name": name,
        "nameEnd": nameEnd,
        "nameOffset": nameOffset,
        "parameters": parameters,
        "periodOffset": periodOffset,
        "redirectedConstructor": redirectedConstructor,
        "redirectedConstructorName": redirectedConstructorName,
        "returnType": returnType,
        "typeParameters": typeParameters,
        "visibleLength": visibleLength,
        "visibleOffset": visibleOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedExportNonPublicBuilder extends Object
    with _UnlinkedExportNonPublicMixin
    implements idl.UnlinkedExportNonPublic {
  List<UnlinkedExprBuilder> _annotations;
  int _offset;
  int _uriEnd;
  int _uriOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this export directive.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// Offset of the "export" keyword.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.
  set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.
  set uriOffset(int value) {
    assert(value == null || value >= 0);
    this._uriOffset = value;
  }

  UnlinkedExportNonPublicBuilder(
      {List<UnlinkedExprBuilder> annotations,
      int offset,
      int uriEnd,
      int uriOffset})
      : _annotations = annotations,
        _offset = offset,
        _uriEnd = uriEnd,
        _uriOffset = uriOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _offset = null;
    _uriEnd = null;
    _uriOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(3, offset_annotations);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(1, _uriEnd);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(2, _uriOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedExportNonPublicReader
    extends fb.TableReader<_UnlinkedExportNonPublicImpl> {
  const _UnlinkedExportNonPublicReader();

  @override
  _UnlinkedExportNonPublicImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedExportNonPublicImpl(bc, offset);
}

class _UnlinkedExportNonPublicImpl extends Object
    with _UnlinkedExportNonPublicMixin
    implements idl.UnlinkedExportNonPublic {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedExportNonPublicImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  int _offset;
  int _uriEnd;
  int _uriOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _offset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _uriEnd;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _uriOffset;
  }
}

abstract class _UnlinkedExportNonPublicMixin
    implements idl.UnlinkedExportNonPublic {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (offset != 0) _result["offset"] = offset;
    if (uriEnd != 0) _result["uriEnd"] = uriEnd;
    if (uriOffset != 0) _result["uriOffset"] = uriOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "offset": offset,
        "uriEnd": uriEnd,
        "uriOffset": uriOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedExportPublicBuilder extends Object
    with _UnlinkedExportPublicMixin
    implements idl.UnlinkedExportPublic {
  List<UnlinkedCombinatorBuilder> _combinators;
  List<UnlinkedConfigurationBuilder> _configurations;
  String _uri;

  @override
  List<UnlinkedCombinatorBuilder> get combinators =>
      _combinators ??= <UnlinkedCombinatorBuilder>[];

  /// Combinators contained in this export declaration.
  set combinators(List<UnlinkedCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  List<UnlinkedConfigurationBuilder> get configurations =>
      _configurations ??= <UnlinkedConfigurationBuilder>[];

  /// Configurations used to control which library will actually be loaded at
  /// run-time.
  set configurations(List<UnlinkedConfigurationBuilder> value) {
    this._configurations = value;
  }

  @override
  String get uri => _uri ??= '';

  /// URI used in the source code to reference the exported library.
  set uri(String value) {
    this._uri = value;
  }

  UnlinkedExportPublicBuilder(
      {List<UnlinkedCombinatorBuilder> combinators,
      List<UnlinkedConfigurationBuilder> configurations,
      String uri})
      : _combinators = combinators,
        _configurations = configurations,
        _uri = uri;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _combinators?.forEach((b) => b.flushInformative());
    _configurations?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uri ?? '');
    if (this._combinators == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._combinators.length);
      for (var x in this._combinators) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._configurations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._configurations.length);
      for (var x in this._configurations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_combinators;
    fb.Offset offset_configurations;
    fb.Offset offset_uri;
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder
          .writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_configurations == null || _configurations.isEmpty)) {
      offset_configurations = fbBuilder
          .writeList(_configurations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_combinators != null) {
      fbBuilder.addOffset(1, offset_combinators);
    }
    if (offset_configurations != null) {
      fbBuilder.addOffset(2, offset_configurations);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedExportPublicReader
    extends fb.TableReader<_UnlinkedExportPublicImpl> {
  const _UnlinkedExportPublicReader();

  @override
  _UnlinkedExportPublicImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedExportPublicImpl(bc, offset);
}

class _UnlinkedExportPublicImpl extends Object
    with _UnlinkedExportPublicMixin
    implements idl.UnlinkedExportPublic {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedExportPublicImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedCombinator> _combinators;
  List<idl.UnlinkedConfiguration> _configurations;
  String _uri;

  @override
  List<idl.UnlinkedCombinator> get combinators {
    _combinators ??= const fb.ListReader<idl.UnlinkedCombinator>(
            const _UnlinkedCombinatorReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.UnlinkedCombinator>[]);
    return _combinators;
  }

  @override
  List<idl.UnlinkedConfiguration> get configurations {
    _configurations ??= const fb.ListReader<idl.UnlinkedConfiguration>(
            const _UnlinkedConfigurationReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedConfiguration>[]);
    return _configurations;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uri;
  }
}

abstract class _UnlinkedExportPublicMixin implements idl.UnlinkedExportPublic {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (combinators.isNotEmpty)
      _result["combinators"] =
          combinators.map((_value) => _value.toJson()).toList();
    if (configurations.isNotEmpty)
      _result["configurations"] =
          configurations.map((_value) => _value.toJson()).toList();
    if (uri != '') _result["uri"] = uri;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "combinators": combinators,
        "configurations": configurations,
        "uri": uri,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedExprBuilder extends Object
    with _UnlinkedExprMixin
    implements idl.UnlinkedExpr {
  List<idl.UnlinkedExprAssignOperator> _assignmentOperators;
  List<double> _doubles;
  List<int> _ints;
  bool _isValidConst;
  List<idl.UnlinkedExprOperation> _operations;
  List<EntityRefBuilder> _references;
  String _sourceRepresentation;
  List<String> _strings;

  @override
  List<idl.UnlinkedExprAssignOperator> get assignmentOperators =>
      _assignmentOperators ??= <idl.UnlinkedExprAssignOperator>[];

  /// Sequence of operators used by assignment operations.
  set assignmentOperators(List<idl.UnlinkedExprAssignOperator> value) {
    this._assignmentOperators = value;
  }

  @override
  List<double> get doubles => _doubles ??= <double>[];

  /// Sequence of 64-bit doubles consumed by the operation `pushDouble`.
  set doubles(List<double> value) {
    this._doubles = value;
  }

  @override
  List<int> get ints => _ints ??= <int>[];

  /// Sequence of unsigned 32-bit integers consumed by the operations
  /// `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
  /// `makeList`, and `makeMap`.
  set ints(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._ints = value;
  }

  @override
  bool get isValidConst => _isValidConst ??= false;

  /// Indicates whether the expression is a valid potentially constant
  /// expression.
  set isValidConst(bool value) {
    this._isValidConst = value;
  }

  @override
  List<idl.UnlinkedExprOperation> get operations =>
      _operations ??= <idl.UnlinkedExprOperation>[];

  /// Sequence of operations to execute (starting with an empty stack) to form
  /// the constant value.
  set operations(List<idl.UnlinkedExprOperation> value) {
    this._operations = value;
  }

  @override
  List<EntityRefBuilder> get references => _references ??= <EntityRefBuilder>[];

  /// Sequence of language constructs consumed by the operations
  /// `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
  /// that in the case of `pushReference` (and sometimes `invokeConstructor` the
  /// actual entity being referred to may be something other than a type.
  set references(List<EntityRefBuilder> value) {
    this._references = value;
  }

  @override
  String get sourceRepresentation => _sourceRepresentation ??= '';

  /// String representation of the expression in a form suitable to be tokenized
  /// and parsed.
  set sourceRepresentation(String value) {
    this._sourceRepresentation = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /// Sequence of strings consumed by the operations `pushString` and
  /// `invokeConstructor`.
  set strings(List<String> value) {
    this._strings = value;
  }

  UnlinkedExprBuilder(
      {List<idl.UnlinkedExprAssignOperator> assignmentOperators,
      List<double> doubles,
      List<int> ints,
      bool isValidConst,
      List<idl.UnlinkedExprOperation> operations,
      List<EntityRefBuilder> references,
      String sourceRepresentation,
      List<String> strings})
      : _assignmentOperators = assignmentOperators,
        _doubles = doubles,
        _ints = ints,
        _isValidConst = isValidConst,
        _operations = operations,
        _references = references,
        _sourceRepresentation = sourceRepresentation,
        _strings = strings;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _references?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._operations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._operations.length);
      for (var x in this._operations) {
        signature.addInt(x.index);
      }
    }
    if (this._ints == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._ints.length);
      for (var x in this._ints) {
        signature.addInt(x);
      }
    }
    if (this._references == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._references.length);
      for (var x in this._references) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._strings == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._strings.length);
      for (var x in this._strings) {
        signature.addString(x);
      }
    }
    if (this._doubles == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._doubles.length);
      for (var x in this._doubles) {
        signature.addDouble(x);
      }
    }
    signature.addBool(this._isValidConst == true);
    if (this._assignmentOperators == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._assignmentOperators.length);
      for (var x in this._assignmentOperators) {
        signature.addInt(x.index);
      }
    }
    signature.addString(this._sourceRepresentation ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_assignmentOperators;
    fb.Offset offset_doubles;
    fb.Offset offset_ints;
    fb.Offset offset_operations;
    fb.Offset offset_references;
    fb.Offset offset_sourceRepresentation;
    fb.Offset offset_strings;
    if (!(_assignmentOperators == null || _assignmentOperators.isEmpty)) {
      offset_assignmentOperators = fbBuilder
          .writeListUint8(_assignmentOperators.map((b) => b.index).toList());
    }
    if (!(_doubles == null || _doubles.isEmpty)) {
      offset_doubles = fbBuilder.writeListFloat64(_doubles);
    }
    if (!(_ints == null || _ints.isEmpty)) {
      offset_ints = fbBuilder.writeListUint32(_ints);
    }
    if (!(_operations == null || _operations.isEmpty)) {
      offset_operations =
          fbBuilder.writeListUint8(_operations.map((b) => b.index).toList());
    }
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder
          .writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_sourceRepresentation != null) {
      offset_sourceRepresentation =
          fbBuilder.writeString(_sourceRepresentation);
    }
    if (!(_strings == null || _strings.isEmpty)) {
      offset_strings = fbBuilder
          .writeList(_strings.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_assignmentOperators != null) {
      fbBuilder.addOffset(6, offset_assignmentOperators);
    }
    if (offset_doubles != null) {
      fbBuilder.addOffset(4, offset_doubles);
    }
    if (offset_ints != null) {
      fbBuilder.addOffset(1, offset_ints);
    }
    if (_isValidConst == true) {
      fbBuilder.addBool(5, true);
    }
    if (offset_operations != null) {
      fbBuilder.addOffset(0, offset_operations);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(2, offset_references);
    }
    if (offset_sourceRepresentation != null) {
      fbBuilder.addOffset(7, offset_sourceRepresentation);
    }
    if (offset_strings != null) {
      fbBuilder.addOffset(3, offset_strings);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedExprReader extends fb.TableReader<_UnlinkedExprImpl> {
  const _UnlinkedExprReader();

  @override
  _UnlinkedExprImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedExprImpl(bc, offset);
}

class _UnlinkedExprImpl extends Object
    with _UnlinkedExprMixin
    implements idl.UnlinkedExpr {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedExprImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExprAssignOperator> _assignmentOperators;
  List<double> _doubles;
  List<int> _ints;
  bool _isValidConst;
  List<idl.UnlinkedExprOperation> _operations;
  List<idl.EntityRef> _references;
  String _sourceRepresentation;
  List<String> _strings;

  @override
  List<idl.UnlinkedExprAssignOperator> get assignmentOperators {
    _assignmentOperators ??=
        const fb.ListReader<idl.UnlinkedExprAssignOperator>(
                const _UnlinkedExprAssignOperatorReader())
            .vTableGet(
                _bc, _bcOffset, 6, const <idl.UnlinkedExprAssignOperator>[]);
    return _assignmentOperators;
  }

  @override
  List<double> get doubles {
    _doubles ??= const fb.Float64ListReader()
        .vTableGet(_bc, _bcOffset, 4, const <double>[]);
    return _doubles;
  }

  @override
  List<int> get ints {
    _ints ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
    return _ints;
  }

  @override
  bool get isValidConst {
    _isValidConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 5, false);
    return _isValidConst;
  }

  @override
  List<idl.UnlinkedExprOperation> get operations {
    _operations ??= const fb.ListReader<idl.UnlinkedExprOperation>(
            const _UnlinkedExprOperationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.UnlinkedExprOperation>[]);
    return _operations;
  }

  @override
  List<idl.EntityRef> get references {
    _references ??= const fb.ListReader<idl.EntityRef>(const _EntityRefReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.EntityRef>[]);
    return _references;
  }

  @override
  String get sourceRepresentation {
    _sourceRepresentation ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 7, '');
    return _sourceRepresentation;
  }

  @override
  List<String> get strings {
    _strings ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 3, const <String>[]);
    return _strings;
  }
}

abstract class _UnlinkedExprMixin implements idl.UnlinkedExpr {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (assignmentOperators.isNotEmpty)
      _result["assignmentOperators"] = assignmentOperators
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    if (doubles.isNotEmpty)
      _result["doubles"] = doubles
          .map((_value) => _value.isFinite ? _value : _value.toString())
          .toList();
    if (ints.isNotEmpty) _result["ints"] = ints;
    if (isValidConst != false) _result["isValidConst"] = isValidConst;
    if (operations.isNotEmpty)
      _result["operations"] =
          operations.map((_value) => _value.toString().split('.')[1]).toList();
    if (references.isNotEmpty)
      _result["references"] =
          references.map((_value) => _value.toJson()).toList();
    if (sourceRepresentation != '')
      _result["sourceRepresentation"] = sourceRepresentation;
    if (strings.isNotEmpty) _result["strings"] = strings;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "assignmentOperators": assignmentOperators,
        "doubles": doubles,
        "ints": ints,
        "isValidConst": isValidConst,
        "operations": operations,
        "references": references,
        "sourceRepresentation": sourceRepresentation,
        "strings": strings,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedImportBuilder extends Object
    with _UnlinkedImportMixin
    implements idl.UnlinkedImport {
  List<UnlinkedExprBuilder> _annotations;
  List<UnlinkedCombinatorBuilder> _combinators;
  List<UnlinkedConfigurationBuilder> _configurations;
  bool _isDeferred;
  bool _isImplicit;
  int _offset;
  int _prefixOffset;
  int _prefixReference;
  String _uri;
  int _uriEnd;
  int _uriOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this import declaration.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  List<UnlinkedCombinatorBuilder> get combinators =>
      _combinators ??= <UnlinkedCombinatorBuilder>[];

  /// Combinators contained in this import declaration.
  set combinators(List<UnlinkedCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  List<UnlinkedConfigurationBuilder> get configurations =>
      _configurations ??= <UnlinkedConfigurationBuilder>[];

  /// Configurations used to control which library will actually be loaded at
  /// run-time.
  set configurations(List<UnlinkedConfigurationBuilder> value) {
    this._configurations = value;
  }

  @override
  bool get isDeferred => _isDeferred ??= false;

  /// Indicates whether the import declaration uses the `deferred` keyword.
  set isDeferred(bool value) {
    this._isDeferred = value;
  }

  @override
  bool get isImplicit => _isImplicit ??= false;

  /// Indicates whether the import declaration is implicit.
  set isImplicit(bool value) {
    this._isImplicit = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
  /// is true, zero.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  int get prefixOffset => _prefixOffset ??= 0;

  /// Offset of the prefix name relative to the beginning of the file, or zero
  /// if there is no prefix.
  set prefixOffset(int value) {
    assert(value == null || value >= 0);
    this._prefixOffset = value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /// Index into [UnlinkedUnit.references] of the prefix declared by this
  /// import declaration, or zero if this import declaration declares no prefix.
  ///
  /// Note that multiple imports can declare the same prefix.
  set prefixReference(int value) {
    assert(value == null || value >= 0);
    this._prefixReference = value;
  }

  @override
  String get uri => _uri ??= '';

  /// URI used in the source code to reference the imported library.
  set uri(String value) {
    this._uri = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.  If [isImplicit] is true, zero.
  set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.  If [isImplicit] is true, zero.
  set uriOffset(int value) {
    assert(value == null || value >= 0);
    this._uriOffset = value;
  }

  UnlinkedImportBuilder(
      {List<UnlinkedExprBuilder> annotations,
      List<UnlinkedCombinatorBuilder> combinators,
      List<UnlinkedConfigurationBuilder> configurations,
      bool isDeferred,
      bool isImplicit,
      int offset,
      int prefixOffset,
      int prefixReference,
      String uri,
      int uriEnd,
      int uriOffset})
      : _annotations = annotations,
        _combinators = combinators,
        _configurations = configurations,
        _isDeferred = isDeferred,
        _isImplicit = isImplicit,
        _offset = offset,
        _prefixOffset = prefixOffset,
        _prefixReference = prefixReference,
        _uri = uri,
        _uriEnd = uriEnd,
        _uriOffset = uriOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _combinators?.forEach((b) => b.flushInformative());
    _configurations?.forEach((b) => b.flushInformative());
    _offset = null;
    _prefixOffset = null;
    _uriEnd = null;
    _uriOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uri ?? '');
    if (this._combinators == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._combinators.length);
      for (var x in this._combinators) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isImplicit == true);
    signature.addInt(this._prefixReference ?? 0);
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isDeferred == true);
    if (this._configurations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._configurations.length);
      for (var x in this._configurations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_combinators;
    fb.Offset offset_configurations;
    fb.Offset offset_uri;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder
          .writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_configurations == null || _configurations.isEmpty)) {
      offset_configurations = fbBuilder
          .writeList(_configurations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(8, offset_annotations);
    }
    if (offset_combinators != null) {
      fbBuilder.addOffset(4, offset_combinators);
    }
    if (offset_configurations != null) {
      fbBuilder.addOffset(10, offset_configurations);
    }
    if (_isDeferred == true) {
      fbBuilder.addBool(9, true);
    }
    if (_isImplicit == true) {
      fbBuilder.addBool(5, true);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    if (_prefixOffset != null && _prefixOffset != 0) {
      fbBuilder.addUint32(6, _prefixOffset);
    }
    if (_prefixReference != null && _prefixReference != 0) {
      fbBuilder.addUint32(7, _prefixReference);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(1, offset_uri);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(2, _uriEnd);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(3, _uriOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedImportReader extends fb.TableReader<_UnlinkedImportImpl> {
  const _UnlinkedImportReader();

  @override
  _UnlinkedImportImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedImportImpl(bc, offset);
}

class _UnlinkedImportImpl extends Object
    with _UnlinkedImportMixin
    implements idl.UnlinkedImport {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedImportImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  List<idl.UnlinkedCombinator> _combinators;
  List<idl.UnlinkedConfiguration> _configurations;
  bool _isDeferred;
  bool _isImplicit;
  int _offset;
  int _prefixOffset;
  int _prefixReference;
  String _uri;
  int _uriEnd;
  int _uriOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 8, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  List<idl.UnlinkedCombinator> get combinators {
    _combinators ??= const fb.ListReader<idl.UnlinkedCombinator>(
            const _UnlinkedCombinatorReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.UnlinkedCombinator>[]);
    return _combinators;
  }

  @override
  List<idl.UnlinkedConfiguration> get configurations {
    _configurations ??= const fb.ListReader<idl.UnlinkedConfiguration>(
            const _UnlinkedConfigurationReader())
        .vTableGet(_bc, _bcOffset, 10, const <idl.UnlinkedConfiguration>[]);
    return _configurations;
  }

  @override
  bool get isDeferred {
    _isDeferred ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 9, false);
    return _isDeferred;
  }

  @override
  bool get isImplicit {
    _isImplicit ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 5, false);
    return _isImplicit;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _offset;
  }

  @override
  int get prefixOffset {
    _prefixOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 6, 0);
    return _prefixOffset;
  }

  @override
  int get prefixReference {
    _prefixReference ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 7, 0);
    return _prefixReference;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _uri;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _uriEnd;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _uriOffset;
  }
}

abstract class _UnlinkedImportMixin implements idl.UnlinkedImport {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (combinators.isNotEmpty)
      _result["combinators"] =
          combinators.map((_value) => _value.toJson()).toList();
    if (configurations.isNotEmpty)
      _result["configurations"] =
          configurations.map((_value) => _value.toJson()).toList();
    if (isDeferred != false) _result["isDeferred"] = isDeferred;
    if (isImplicit != false) _result["isImplicit"] = isImplicit;
    if (offset != 0) _result["offset"] = offset;
    if (prefixOffset != 0) _result["prefixOffset"] = prefixOffset;
    if (prefixReference != 0) _result["prefixReference"] = prefixReference;
    if (uri != '') _result["uri"] = uri;
    if (uriEnd != 0) _result["uriEnd"] = uriEnd;
    if (uriOffset != 0) _result["uriOffset"] = uriOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "combinators": combinators,
        "configurations": configurations,
        "isDeferred": isDeferred,
        "isImplicit": isImplicit,
        "offset": offset,
        "prefixOffset": prefixOffset,
        "prefixReference": prefixReference,
        "uri": uri,
        "uriEnd": uriEnd,
        "uriOffset": uriOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedParamBuilder extends Object
    with _UnlinkedParamMixin
    implements idl.UnlinkedParam {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  String _defaultValueCode;
  int _inferredTypeSlot;
  int _inheritsCovariantSlot;
  UnlinkedExecutableBuilder _initializer;
  bool _isExplicitlyCovariant;
  bool _isFinal;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  idl.UnlinkedParamKind _kind;
  String _name;
  int _nameOffset;
  List<UnlinkedParamBuilder> _parameters;
  EntityRefBuilder _type;
  int _visibleLength;
  int _visibleOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this parameter.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the parameter.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  String get defaultValueCode => _defaultValueCode ??= '';

  /// If the parameter has a default value, the source text of the constant
  /// expression in the default value.  Otherwise the empty string.
  set defaultValueCode(String value) {
    this._defaultValueCode = value;
  }

  @override
  int get inferredTypeSlot => _inferredTypeSlot ??= 0;

  /// If this parameter's type is inferable, nonzero slot id identifying which
  /// entry in [LinkedLibrary.types] contains the inferred type.  If there is no
  /// matching entry in [LinkedLibrary.types], then no type was inferred for
  /// this variable, so its static type is `dynamic`.
  ///
  /// Note that although strong mode considers initializing formals to be
  /// inferable, they are not marked as such in the summary; if their type is
  /// not specified, they always inherit the static type of the corresponding
  /// field.
  set inferredTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredTypeSlot = value;
  }

  @override
  int get inheritsCovariantSlot => _inheritsCovariantSlot ??= 0;

  /// If this is a parameter of an instance method, a nonzero slot id which is
  /// unique within this compilation unit.  If this id is found in
  /// [LinkedUnit.parametersInheritingCovariant], then this parameter inherits
  /// `@covariant` behavior from a base class.
  ///
  /// Otherwise, zero.
  set inheritsCovariantSlot(int value) {
    assert(value == null || value >= 0);
    this._inheritsCovariantSlot = value;
  }

  @override
  UnlinkedExecutableBuilder get initializer => _initializer;

  /// The synthetic initializer function of the parameter.  Absent if the
  /// variable does not have an initializer.
  set initializer(UnlinkedExecutableBuilder value) {
    this._initializer = value;
  }

  @override
  bool get isExplicitlyCovariant => _isExplicitlyCovariant ??= false;

  /// Indicates whether this parameter is explicitly marked as being covariant.
  set isExplicitlyCovariant(bool value) {
    this._isExplicitlyCovariant = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  /// Indicates whether the parameter is declared using the `final` keyword.
  set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isFunctionTyped => _isFunctionTyped ??= false;

  /// Indicates whether this is a function-typed parameter. A parameter is
  /// function-typed if the declaration of the parameter has explicit formal
  /// parameters
  /// ```
  /// int functionTyped(int p)
  /// ```
  /// but is not function-typed if it does not, even if the type of the
  /// parameter is a function type.
  set isFunctionTyped(bool value) {
    this._isFunctionTyped = value;
  }

  @override
  bool get isInitializingFormal => _isInitializingFormal ??= false;

  /// Indicates whether this is an initializing formal parameter (i.e. it is
  /// declared using `this.` syntax).
  set isInitializingFormal(bool value) {
    this._isInitializingFormal = value;
  }

  @override
  idl.UnlinkedParamKind get kind =>
      _kind ??= idl.UnlinkedParamKind.requiredPositional;

  /// Kind of the parameter.
  set kind(idl.UnlinkedParamKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the parameter.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the parameter name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /// If [isFunctionTyped] is `true`, the parameters of the function type.
  set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  EntityRefBuilder get type => _type;

  /// If [isFunctionTyped] is `true`, the declared return type.  If
  /// [isFunctionTyped] is `false`, the declared type.  Absent if the type is
  /// implicit.
  set type(EntityRefBuilder value) {
    this._type = value;
  }

  @override
  int get visibleLength => _visibleLength ??= 0;

  /// The length of the visible range.
  set visibleLength(int value) {
    assert(value == null || value >= 0);
    this._visibleLength = value;
  }

  @override
  int get visibleOffset => _visibleOffset ??= 0;

  /// The beginning of the visible range.
  set visibleOffset(int value) {
    assert(value == null || value >= 0);
    this._visibleOffset = value;
  }

  UnlinkedParamBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      String defaultValueCode,
      int inferredTypeSlot,
      int inheritsCovariantSlot,
      UnlinkedExecutableBuilder initializer,
      bool isExplicitlyCovariant,
      bool isFinal,
      bool isFunctionTyped,
      bool isInitializingFormal,
      idl.UnlinkedParamKind kind,
      String name,
      int nameOffset,
      List<UnlinkedParamBuilder> parameters,
      EntityRefBuilder type,
      int visibleLength,
      int visibleOffset})
      : _annotations = annotations,
        _codeRange = codeRange,
        _defaultValueCode = defaultValueCode,
        _inferredTypeSlot = inferredTypeSlot,
        _inheritsCovariantSlot = inheritsCovariantSlot,
        _initializer = initializer,
        _isExplicitlyCovariant = isExplicitlyCovariant,
        _isFinal = isFinal,
        _isFunctionTyped = isFunctionTyped,
        _isInitializingFormal = isInitializingFormal,
        _kind = kind,
        _name = name,
        _nameOffset = nameOffset,
        _parameters = parameters,
        _type = type,
        _visibleLength = visibleLength,
        _visibleOffset = visibleOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _defaultValueCode = null;
    _initializer?.flushInformative();
    _nameOffset = null;
    _parameters?.forEach((b) => b.flushInformative());
    _type?.flushInformative();
    _visibleLength = null;
    _visibleOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addInt(this._inferredTypeSlot ?? 0);
    signature.addBool(this._type != null);
    this._type?.collectApiSignature(signature);
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    signature.addBool(this._isFunctionTyped == true);
    signature.addBool(this._isInitializingFormal == true);
    if (this._parameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parameters.length);
      for (var x in this._parameters) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._initializer != null);
    this._initializer?.collectApiSignature(signature);
    signature.addInt(this._inheritsCovariantSlot ?? 0);
    signature.addBool(this._isExplicitlyCovariant == true);
    signature.addBool(this._isFinal == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_codeRange;
    fb.Offset offset_defaultValueCode;
    fb.Offset offset_initializer;
    fb.Offset offset_name;
    fb.Offset offset_parameters;
    fb.Offset offset_type;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_defaultValueCode != null) {
      offset_defaultValueCode = fbBuilder.writeString(_defaultValueCode);
    }
    if (_initializer != null) {
      offset_initializer = _initializer.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder
          .writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(9, offset_annotations);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(7, offset_codeRange);
    }
    if (offset_defaultValueCode != null) {
      fbBuilder.addOffset(13, offset_defaultValueCode);
    }
    if (_inferredTypeSlot != null && _inferredTypeSlot != 0) {
      fbBuilder.addUint32(2, _inferredTypeSlot);
    }
    if (_inheritsCovariantSlot != null && _inheritsCovariantSlot != 0) {
      fbBuilder.addUint32(14, _inheritsCovariantSlot);
    }
    if (offset_initializer != null) {
      fbBuilder.addOffset(12, offset_initializer);
    }
    if (_isExplicitlyCovariant == true) {
      fbBuilder.addBool(15, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(16, true);
    }
    if (_isFunctionTyped == true) {
      fbBuilder.addBool(5, true);
    }
    if (_isInitializingFormal == true) {
      fbBuilder.addBool(6, true);
    }
    if (_kind != null && _kind != idl.UnlinkedParamKind.requiredPositional) {
      fbBuilder.addUint8(4, _kind.index);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(8, offset_parameters);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(3, offset_type);
    }
    if (_visibleLength != null && _visibleLength != 0) {
      fbBuilder.addUint32(10, _visibleLength);
    }
    if (_visibleOffset != null && _visibleOffset != 0) {
      fbBuilder.addUint32(11, _visibleOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedParamReader extends fb.TableReader<_UnlinkedParamImpl> {
  const _UnlinkedParamReader();

  @override
  _UnlinkedParamImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedParamImpl(bc, offset);
}

class _UnlinkedParamImpl extends Object
    with _UnlinkedParamMixin
    implements idl.UnlinkedParam {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedParamImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.CodeRange _codeRange;
  String _defaultValueCode;
  int _inferredTypeSlot;
  int _inheritsCovariantSlot;
  idl.UnlinkedExecutable _initializer;
  bool _isExplicitlyCovariant;
  bool _isFinal;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  idl.UnlinkedParamKind _kind;
  String _name;
  int _nameOffset;
  List<idl.UnlinkedParam> _parameters;
  idl.EntityRef _type;
  int _visibleLength;
  int _visibleOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 9, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _codeRange;
  }

  @override
  String get defaultValueCode {
    _defaultValueCode ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 13, '');
    return _defaultValueCode;
  }

  @override
  int get inferredTypeSlot {
    _inferredTypeSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _inferredTypeSlot;
  }

  @override
  int get inheritsCovariantSlot {
    _inheritsCovariantSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 14, 0);
    return _inheritsCovariantSlot;
  }

  @override
  idl.UnlinkedExecutable get initializer {
    _initializer ??=
        const _UnlinkedExecutableReader().vTableGet(_bc, _bcOffset, 12, null);
    return _initializer;
  }

  @override
  bool get isExplicitlyCovariant {
    _isExplicitlyCovariant ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 15, false);
    return _isExplicitlyCovariant;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 16, false);
    return _isFinal;
  }

  @override
  bool get isFunctionTyped {
    _isFunctionTyped ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 5, false);
    return _isFunctionTyped;
  }

  @override
  bool get isInitializingFormal {
    _isInitializingFormal ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 6, false);
    return _isInitializingFormal;
  }

  @override
  idl.UnlinkedParamKind get kind {
    _kind ??= const _UnlinkedParamKindReader()
        .vTableGet(_bc, _bcOffset, 4, idl.UnlinkedParamKind.requiredPositional);
    return _kind;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  List<idl.UnlinkedParam> get parameters {
    _parameters ??=
        const fb.ListReader<idl.UnlinkedParam>(const _UnlinkedParamReader())
            .vTableGet(_bc, _bcOffset, 8, const <idl.UnlinkedParam>[]);
    return _parameters;
  }

  @override
  idl.EntityRef get type {
    _type ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 3, null);
    return _type;
  }

  @override
  int get visibleLength {
    _visibleLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 10, 0);
    return _visibleLength;
  }

  @override
  int get visibleOffset {
    _visibleOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 11, 0);
    return _visibleOffset;
  }
}

abstract class _UnlinkedParamMixin implements idl.UnlinkedParam {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (defaultValueCode != '') _result["defaultValueCode"] = defaultValueCode;
    if (inferredTypeSlot != 0) _result["inferredTypeSlot"] = inferredTypeSlot;
    if (inheritsCovariantSlot != 0)
      _result["inheritsCovariantSlot"] = inheritsCovariantSlot;
    if (initializer != null) _result["initializer"] = initializer.toJson();
    if (isExplicitlyCovariant != false)
      _result["isExplicitlyCovariant"] = isExplicitlyCovariant;
    if (isFinal != false) _result["isFinal"] = isFinal;
    if (isFunctionTyped != false) _result["isFunctionTyped"] = isFunctionTyped;
    if (isInitializingFormal != false)
      _result["isInitializingFormal"] = isInitializingFormal;
    if (kind != idl.UnlinkedParamKind.requiredPositional)
      _result["kind"] = kind.toString().split('.')[1];
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (parameters.isNotEmpty)
      _result["parameters"] =
          parameters.map((_value) => _value.toJson()).toList();
    if (type != null) _result["type"] = type.toJson();
    if (visibleLength != 0) _result["visibleLength"] = visibleLength;
    if (visibleOffset != 0) _result["visibleOffset"] = visibleOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "codeRange": codeRange,
        "defaultValueCode": defaultValueCode,
        "inferredTypeSlot": inferredTypeSlot,
        "inheritsCovariantSlot": inheritsCovariantSlot,
        "initializer": initializer,
        "isExplicitlyCovariant": isExplicitlyCovariant,
        "isFinal": isFinal,
        "isFunctionTyped": isFunctionTyped,
        "isInitializingFormal": isInitializingFormal,
        "kind": kind,
        "name": name,
        "nameOffset": nameOffset,
        "parameters": parameters,
        "type": type,
        "visibleLength": visibleLength,
        "visibleOffset": visibleOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedPartBuilder extends Object
    with _UnlinkedPartMixin
    implements idl.UnlinkedPart {
  List<UnlinkedExprBuilder> _annotations;
  int _uriEnd;
  int _uriOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this part declaration.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.
  set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.
  set uriOffset(int value) {
    assert(value == null || value >= 0);
    this._uriOffset = value;
  }

  UnlinkedPartBuilder(
      {List<UnlinkedExprBuilder> annotations, int uriEnd, int uriOffset})
      : _annotations = annotations,
        _uriEnd = uriEnd,
        _uriOffset = uriOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _uriEnd = null;
    _uriOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(2, offset_annotations);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(0, _uriEnd);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(1, _uriOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedPartReader extends fb.TableReader<_UnlinkedPartImpl> {
  const _UnlinkedPartReader();

  @override
  _UnlinkedPartImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedPartImpl(bc, offset);
}

class _UnlinkedPartImpl extends Object
    with _UnlinkedPartMixin
    implements idl.UnlinkedPart {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedPartImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  int _uriEnd;
  int _uriOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _uriEnd;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _uriOffset;
  }
}

abstract class _UnlinkedPartMixin implements idl.UnlinkedPart {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (uriEnd != 0) _result["uriEnd"] = uriEnd;
    if (uriOffset != 0) _result["uriOffset"] = uriOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "uriEnd": uriEnd,
        "uriOffset": uriOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedPublicNameBuilder extends Object
    with _UnlinkedPublicNameMixin
    implements idl.UnlinkedPublicName {
  idl.ReferenceKind _kind;
  List<UnlinkedPublicNameBuilder> _members;
  String _name;
  int _numTypeParameters;

  @override
  idl.ReferenceKind get kind => _kind ??= idl.ReferenceKind.classOrEnum;

  /// The kind of object referred to by the name.
  set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  List<UnlinkedPublicNameBuilder> get members =>
      _members ??= <UnlinkedPublicNameBuilder>[];

  /// If this [UnlinkedPublicName] is a class, the list of members which can be
  /// referenced statically - static fields, static methods, and constructors.
  /// Otherwise empty.
  ///
  /// Unnamed constructors are not included since they do not constitute a
  /// separate name added to any namespace.
  set members(List<UnlinkedPublicNameBuilder> value) {
    this._members = value;
  }

  @override
  String get name => _name ??= '';

  /// The name itself.
  set name(String value) {
    this._name = value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /// If the entity being referred to is generic, the number of type parameters
  /// it accepts.  Otherwise zero.
  set numTypeParameters(int value) {
    assert(value == null || value >= 0);
    this._numTypeParameters = value;
  }

  UnlinkedPublicNameBuilder(
      {idl.ReferenceKind kind,
      List<UnlinkedPublicNameBuilder> members,
      String name,
      int numTypeParameters})
      : _kind = kind,
        _members = members,
        _name = name,
        _numTypeParameters = numTypeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _members?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addInt(this._kind == null ? 0 : this._kind.index);
    if (this._members == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._members.length);
      for (var x in this._members) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._numTypeParameters ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_members;
    fb.Offset offset_name;
    if (!(_members == null || _members.isEmpty)) {
      offset_members = fbBuilder
          .writeList(_members.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (_kind != null && _kind != idl.ReferenceKind.classOrEnum) {
      fbBuilder.addUint8(1, _kind.index);
    }
    if (offset_members != null) {
      fbBuilder.addOffset(2, offset_members);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addUint32(3, _numTypeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedPublicNameReader
    extends fb.TableReader<_UnlinkedPublicNameImpl> {
  const _UnlinkedPublicNameReader();

  @override
  _UnlinkedPublicNameImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedPublicNameImpl(bc, offset);
}

class _UnlinkedPublicNameImpl extends Object
    with _UnlinkedPublicNameMixin
    implements idl.UnlinkedPublicName {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedPublicNameImpl(this._bc, this._bcOffset);

  idl.ReferenceKind _kind;
  List<idl.UnlinkedPublicName> _members;
  String _name;
  int _numTypeParameters;

  @override
  idl.ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader()
        .vTableGet(_bc, _bcOffset, 1, idl.ReferenceKind.classOrEnum);
    return _kind;
  }

  @override
  List<idl.UnlinkedPublicName> get members {
    _members ??= const fb.ListReader<idl.UnlinkedPublicName>(
            const _UnlinkedPublicNameReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedPublicName>[]);
    return _members;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _numTypeParameters;
  }
}

abstract class _UnlinkedPublicNameMixin implements idl.UnlinkedPublicName {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (kind != idl.ReferenceKind.classOrEnum)
      _result["kind"] = kind.toString().split('.')[1];
    if (members.isNotEmpty)
      _result["members"] = members.map((_value) => _value.toJson()).toList();
    if (name != '') _result["name"] = name;
    if (numTypeParameters != 0)
      _result["numTypeParameters"] = numTypeParameters;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "kind": kind,
        "members": members,
        "name": name,
        "numTypeParameters": numTypeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedPublicNamespaceBuilder extends Object
    with _UnlinkedPublicNamespaceMixin
    implements idl.UnlinkedPublicNamespace {
  List<UnlinkedExportPublicBuilder> _exports;
  List<UnlinkedPublicNameBuilder> _names;
  List<String> _parts;

  @override
  List<UnlinkedExportPublicBuilder> get exports =>
      _exports ??= <UnlinkedExportPublicBuilder>[];

  /// Export declarations in the compilation unit.
  set exports(List<UnlinkedExportPublicBuilder> value) {
    this._exports = value;
  }

  @override
  List<UnlinkedPublicNameBuilder> get names =>
      _names ??= <UnlinkedPublicNameBuilder>[];

  /// Public names defined in the compilation unit.
  ///
  /// TODO(paulberry): consider sorting these names to reduce unnecessary
  /// relinking.
  set names(List<UnlinkedPublicNameBuilder> value) {
    this._names = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /// URIs referenced by part declarations in the compilation unit.
  set parts(List<String> value) {
    this._parts = value;
  }

  UnlinkedPublicNamespaceBuilder(
      {List<UnlinkedExportPublicBuilder> exports,
      List<UnlinkedPublicNameBuilder> names,
      List<String> parts})
      : _exports = exports,
        _names = names,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _exports?.forEach((b) => b.flushInformative());
    _names?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._names == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._names.length);
      for (var x in this._names) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        signature.addString(x);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UPNS");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_exports;
    fb.Offset offset_names;
    fb.Offset offset_parts;
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_names == null || _names.isEmpty)) {
      offset_names =
          fbBuilder.writeList(_names.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder
          .writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_exports != null) {
      fbBuilder.addOffset(2, offset_exports);
    }
    if (offset_names != null) {
      fbBuilder.addOffset(0, offset_names);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(1, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedPublicNamespace readUnlinkedPublicNamespace(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedPublicNamespaceReader().read(rootRef, 0);
}

class _UnlinkedPublicNamespaceReader
    extends fb.TableReader<_UnlinkedPublicNamespaceImpl> {
  const _UnlinkedPublicNamespaceReader();

  @override
  _UnlinkedPublicNamespaceImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedPublicNamespaceImpl(bc, offset);
}

class _UnlinkedPublicNamespaceImpl extends Object
    with _UnlinkedPublicNamespaceMixin
    implements idl.UnlinkedPublicNamespace {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedPublicNamespaceImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExportPublic> _exports;
  List<idl.UnlinkedPublicName> _names;
  List<String> _parts;

  @override
  List<idl.UnlinkedExportPublic> get exports {
    _exports ??= const fb.ListReader<idl.UnlinkedExportPublic>(
            const _UnlinkedExportPublicReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedExportPublic>[]);
    return _exports;
  }

  @override
  List<idl.UnlinkedPublicName> get names {
    _names ??= const fb.ListReader<idl.UnlinkedPublicName>(
            const _UnlinkedPublicNameReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.UnlinkedPublicName>[]);
    return _names;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _parts;
  }
}

abstract class _UnlinkedPublicNamespaceMixin
    implements idl.UnlinkedPublicNamespace {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (exports.isNotEmpty)
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    if (names.isNotEmpty)
      _result["names"] = names.map((_value) => _value.toJson()).toList();
    if (parts.isNotEmpty) _result["parts"] = parts;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "exports": exports,
        "names": names,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedReferenceBuilder extends Object
    with _UnlinkedReferenceMixin
    implements idl.UnlinkedReference {
  String _name;
  int _prefixReference;

  @override
  String get name => _name ??= '';

  /// Name of the entity being referred to.  For the pseudo-type `dynamic`, the
  /// string is "dynamic".  For the pseudo-type `void`, the string is "void".
  /// For the pseudo-type `bottom`, the string is "*bottom*".
  set name(String value) {
    this._name = value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /// Prefix used to refer to the entity, or zero if no prefix is used.  This is
  /// an index into [UnlinkedUnit.references].
  ///
  /// Prefix references must always point backward; that is, for all i, if
  /// UnlinkedUnit.references[i].prefixReference != 0, then
  /// UnlinkedUnit.references[i].prefixReference < i.
  set prefixReference(int value) {
    assert(value == null || value >= 0);
    this._prefixReference = value;
  }

  UnlinkedReferenceBuilder({String name, int prefixReference})
      : _name = name,
        _prefixReference = prefixReference;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addInt(this._prefixReference ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_prefixReference != null && _prefixReference != 0) {
      fbBuilder.addUint32(1, _prefixReference);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedReferenceReader extends fb.TableReader<_UnlinkedReferenceImpl> {
  const _UnlinkedReferenceReader();

  @override
  _UnlinkedReferenceImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedReferenceImpl(bc, offset);
}

class _UnlinkedReferenceImpl extends Object
    with _UnlinkedReferenceMixin
    implements idl.UnlinkedReference {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedReferenceImpl(this._bc, this._bcOffset);

  String _name;
  int _prefixReference;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get prefixReference {
    _prefixReference ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _prefixReference;
  }
}

abstract class _UnlinkedReferenceMixin implements idl.UnlinkedReference {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (name != '') _result["name"] = name;
    if (prefixReference != 0) _result["prefixReference"] = prefixReference;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "name": name,
        "prefixReference": prefixReference,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedTokensBuilder extends Object
    with _UnlinkedTokensMixin
    implements idl.UnlinkedTokens {
  List<int> _endGroup;
  List<bool> _isSynthetic;
  List<idl.UnlinkedTokenKind> _kind;
  List<int> _length;
  List<String> _lexeme;
  List<int> _next;
  List<int> _offset;
  List<int> _precedingComment;
  List<idl.UnlinkedTokenType> _type;

  @override
  List<int> get endGroup => _endGroup ??= <int>[];

  /// The token that corresponds to this token, or `0` if this token is not
  /// the first of a pair of matching tokens (such as parentheses).
  set endGroup(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._endGroup = value;
  }

  @override
  List<bool> get isSynthetic => _isSynthetic ??= <bool>[];

  /// Return `true` if this token is a synthetic token. A synthetic token is a
  /// token that was introduced by the parser in order to recover from an error
  /// in the code.
  set isSynthetic(List<bool> value) {
    this._isSynthetic = value;
  }

  @override
  List<idl.UnlinkedTokenKind> get kind => _kind ??= <idl.UnlinkedTokenKind>[];

  set kind(List<idl.UnlinkedTokenKind> value) {
    this._kind = value;
  }

  @override
  List<int> get length => _length ??= <int>[];

  set length(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._length = value;
  }

  @override
  List<String> get lexeme => _lexeme ??= <String>[];

  set lexeme(List<String> value) {
    this._lexeme = value;
  }

  @override
  List<int> get next => _next ??= <int>[];

  /// The next token in the token stream, `0` for [UnlinkedTokenType.EOF] or
  /// the last comment token.
  set next(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._next = value;
  }

  @override
  List<int> get offset => _offset ??= <int>[];

  set offset(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._offset = value;
  }

  @override
  List<int> get precedingComment => _precedingComment ??= <int>[];

  /// The first comment token in the list of comments that precede this token,
  /// or `0` if there are no comments preceding this token. Additional comments
  /// can be reached by following the token stream using [next] until `0` is
  /// reached.
  set precedingComment(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._precedingComment = value;
  }

  @override
  List<idl.UnlinkedTokenType> get type => _type ??= <idl.UnlinkedTokenType>[];

  set type(List<idl.UnlinkedTokenType> value) {
    this._type = value;
  }

  UnlinkedTokensBuilder(
      {List<int> endGroup,
      List<bool> isSynthetic,
      List<idl.UnlinkedTokenKind> kind,
      List<int> length,
      List<String> lexeme,
      List<int> next,
      List<int> offset,
      List<int> precedingComment,
      List<idl.UnlinkedTokenType> type})
      : _endGroup = endGroup,
        _isSynthetic = isSynthetic,
        _kind = kind,
        _length = length,
        _lexeme = lexeme,
        _next = next,
        _offset = offset,
        _precedingComment = precedingComment,
        _type = type;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._endGroup == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._endGroup.length);
      for (var x in this._endGroup) {
        signature.addInt(x);
      }
    }
    if (this._isSynthetic == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._isSynthetic.length);
      for (var x in this._isSynthetic) {
        signature.addBool(x);
      }
    }
    if (this._kind == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._kind.length);
      for (var x in this._kind) {
        signature.addInt(x.index);
      }
    }
    if (this._length == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._length.length);
      for (var x in this._length) {
        signature.addInt(x);
      }
    }
    if (this._lexeme == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._lexeme.length);
      for (var x in this._lexeme) {
        signature.addString(x);
      }
    }
    if (this._next == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._next.length);
      for (var x in this._next) {
        signature.addInt(x);
      }
    }
    if (this._offset == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._offset.length);
      for (var x in this._offset) {
        signature.addInt(x);
      }
    }
    if (this._precedingComment == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._precedingComment.length);
      for (var x in this._precedingComment) {
        signature.addInt(x);
      }
    }
    if (this._type == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._type.length);
      for (var x in this._type) {
        signature.addInt(x.index);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_endGroup;
    fb.Offset offset_isSynthetic;
    fb.Offset offset_kind;
    fb.Offset offset_length;
    fb.Offset offset_lexeme;
    fb.Offset offset_next;
    fb.Offset offset_offset;
    fb.Offset offset_precedingComment;
    fb.Offset offset_type;
    if (!(_endGroup == null || _endGroup.isEmpty)) {
      offset_endGroup = fbBuilder.writeListUint32(_endGroup);
    }
    if (!(_isSynthetic == null || _isSynthetic.isEmpty)) {
      offset_isSynthetic = fbBuilder.writeListBool(_isSynthetic);
    }
    if (!(_kind == null || _kind.isEmpty)) {
      offset_kind =
          fbBuilder.writeListUint8(_kind.map((b) => b.index).toList());
    }
    if (!(_length == null || _length.isEmpty)) {
      offset_length = fbBuilder.writeListUint32(_length);
    }
    if (!(_lexeme == null || _lexeme.isEmpty)) {
      offset_lexeme = fbBuilder
          .writeList(_lexeme.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_next == null || _next.isEmpty)) {
      offset_next = fbBuilder.writeListUint32(_next);
    }
    if (!(_offset == null || _offset.isEmpty)) {
      offset_offset = fbBuilder.writeListUint32(_offset);
    }
    if (!(_precedingComment == null || _precedingComment.isEmpty)) {
      offset_precedingComment = fbBuilder.writeListUint32(_precedingComment);
    }
    if (!(_type == null || _type.isEmpty)) {
      offset_type =
          fbBuilder.writeListUint8(_type.map((b) => b.index).toList());
    }
    fbBuilder.startTable();
    if (offset_endGroup != null) {
      fbBuilder.addOffset(0, offset_endGroup);
    }
    if (offset_isSynthetic != null) {
      fbBuilder.addOffset(1, offset_isSynthetic);
    }
    if (offset_kind != null) {
      fbBuilder.addOffset(2, offset_kind);
    }
    if (offset_length != null) {
      fbBuilder.addOffset(3, offset_length);
    }
    if (offset_lexeme != null) {
      fbBuilder.addOffset(4, offset_lexeme);
    }
    if (offset_next != null) {
      fbBuilder.addOffset(5, offset_next);
    }
    if (offset_offset != null) {
      fbBuilder.addOffset(6, offset_offset);
    }
    if (offset_precedingComment != null) {
      fbBuilder.addOffset(7, offset_precedingComment);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(8, offset_type);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedTokensReader extends fb.TableReader<_UnlinkedTokensImpl> {
  const _UnlinkedTokensReader();

  @override
  _UnlinkedTokensImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedTokensImpl(bc, offset);
}

class _UnlinkedTokensImpl extends Object
    with _UnlinkedTokensMixin
    implements idl.UnlinkedTokens {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedTokensImpl(this._bc, this._bcOffset);

  List<int> _endGroup;
  List<bool> _isSynthetic;
  List<idl.UnlinkedTokenKind> _kind;
  List<int> _length;
  List<String> _lexeme;
  List<int> _next;
  List<int> _offset;
  List<int> _precedingComment;
  List<idl.UnlinkedTokenType> _type;

  @override
  List<int> get endGroup {
    _endGroup ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _endGroup;
  }

  @override
  List<bool> get isSynthetic {
    _isSynthetic ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 1, const <bool>[]);
    return _isSynthetic;
  }

  @override
  List<idl.UnlinkedTokenKind> get kind {
    _kind ??= const fb.ListReader<idl.UnlinkedTokenKind>(
            const _UnlinkedTokenKindReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedTokenKind>[]);
    return _kind;
  }

  @override
  List<int> get length {
    _length ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
    return _length;
  }

  @override
  List<String> get lexeme {
    _lexeme ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _lexeme;
  }

  @override
  List<int> get next {
    _next ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _next;
  }

  @override
  List<int> get offset {
    _offset ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 6, const <int>[]);
    return _offset;
  }

  @override
  List<int> get precedingComment {
    _precedingComment ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
    return _precedingComment;
  }

  @override
  List<idl.UnlinkedTokenType> get type {
    _type ??= const fb.ListReader<idl.UnlinkedTokenType>(
            const _UnlinkedTokenTypeReader())
        .vTableGet(_bc, _bcOffset, 8, const <idl.UnlinkedTokenType>[]);
    return _type;
  }
}

abstract class _UnlinkedTokensMixin implements idl.UnlinkedTokens {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (endGroup.isNotEmpty) _result["endGroup"] = endGroup;
    if (isSynthetic.isNotEmpty) _result["isSynthetic"] = isSynthetic;
    if (kind.isNotEmpty)
      _result["kind"] =
          kind.map((_value) => _value.toString().split('.')[1]).toList();
    if (length.isNotEmpty) _result["length"] = length;
    if (lexeme.isNotEmpty) _result["lexeme"] = lexeme;
    if (next.isNotEmpty) _result["next"] = next;
    if (offset.isNotEmpty) _result["offset"] = offset;
    if (precedingComment.isNotEmpty)
      _result["precedingComment"] = precedingComment;
    if (type.isNotEmpty)
      _result["type"] =
          type.map((_value) => _value.toString().split('.')[1]).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "endGroup": endGroup,
        "isSynthetic": isSynthetic,
        "kind": kind,
        "length": length,
        "lexeme": lexeme,
        "next": next,
        "offset": offset,
        "precedingComment": precedingComment,
        "type": type,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedTypedefBuilder extends Object
    with _UnlinkedTypedefMixin
    implements idl.UnlinkedTypedef {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  String _name;
  int _nameOffset;
  int _notSimplyBoundedSlot;
  List<UnlinkedParamBuilder> _parameters;
  EntityRefBuilder _returnType;
  idl.TypedefStyle _style;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this typedef.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the typedef.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the typedef, or `null` if there is no
  /// documentation comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the typedef.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the typedef name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  int get notSimplyBoundedSlot => _notSimplyBoundedSlot ??= 0;

  /// If the typedef might not be simply bounded, a nonzero slot id which is
  /// unique within this compilation unit.  If this id is found in
  /// [LinkedUnit.notSimplyBounded], then at least one of this typedef's type
  /// parameters is not simply bounded, hence this typedef can't be used as a
  /// raw type when specifying the bound of a type parameter.
  ///
  /// Otherwise, zero.
  set notSimplyBoundedSlot(int value) {
    assert(value == null || value >= 0);
    this._notSimplyBoundedSlot = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /// Parameters of the executable, if any.
  set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  EntityRefBuilder get returnType => _returnType;

  /// If [style] is [TypedefStyle.functionType], the return type of the typedef.
  /// If [style] is [TypedefStyle.genericFunctionType], the function type being
  /// defined.
  set returnType(EntityRefBuilder value) {
    this._returnType = value;
  }

  @override
  idl.TypedefStyle get style => _style ??= idl.TypedefStyle.functionType;

  /// The style of the typedef.
  set style(idl.TypedefStyle value) {
    this._style = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /// Type parameters of the typedef, if any.
  set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  UnlinkedTypedefBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      UnlinkedDocumentationCommentBuilder documentationComment,
      String name,
      int nameOffset,
      int notSimplyBoundedSlot,
      List<UnlinkedParamBuilder> parameters,
      EntityRefBuilder returnType,
      idl.TypedefStyle style,
      List<UnlinkedTypeParamBuilder> typeParameters})
      : _annotations = annotations,
        _codeRange = codeRange,
        _documentationComment = documentationComment,
        _name = name,
        _nameOffset = nameOffset,
        _notSimplyBoundedSlot = notSimplyBoundedSlot,
        _parameters = parameters,
        _returnType = returnType,
        _style = style,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _nameOffset = null;
    _parameters?.forEach((b) => b.flushInformative());
    _returnType?.flushInformative();
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addBool(this._returnType != null);
    this._returnType?.collectApiSignature(signature);
    if (this._parameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parameters.length);
      for (var x in this._parameters) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._typeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeParameters.length);
      for (var x in this._typeParameters) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._style == null ? 0 : this._style.index);
    signature.addInt(this._notSimplyBoundedSlot ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_codeRange;
    fb.Offset offset_documentationComment;
    fb.Offset offset_name;
    fb.Offset offset_parameters;
    fb.Offset offset_returnType;
    fb.Offset offset_typeParameters;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder
          .writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_returnType != null) {
      offset_returnType = _returnType.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder
          .writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(4, offset_annotations);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(7, offset_codeRange);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(6, offset_documentationComment);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (_notSimplyBoundedSlot != null && _notSimplyBoundedSlot != 0) {
      fbBuilder.addUint32(9, _notSimplyBoundedSlot);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(3, offset_parameters);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(2, offset_returnType);
    }
    if (_style != null && _style != idl.TypedefStyle.functionType) {
      fbBuilder.addUint8(8, _style.index);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(5, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedTypedefReader extends fb.TableReader<_UnlinkedTypedefImpl> {
  const _UnlinkedTypedefReader();

  @override
  _UnlinkedTypedefImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedTypedefImpl(bc, offset);
}

class _UnlinkedTypedefImpl extends Object
    with _UnlinkedTypedefMixin
    implements idl.UnlinkedTypedef {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedTypedefImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.CodeRange _codeRange;
  idl.UnlinkedDocumentationComment _documentationComment;
  String _name;
  int _nameOffset;
  int _notSimplyBoundedSlot;
  List<idl.UnlinkedParam> _parameters;
  idl.EntityRef _returnType;
  idl.TypedefStyle _style;
  List<idl.UnlinkedTypeParam> _typeParameters;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 4, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _codeRange;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 6, null);
    return _documentationComment;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  int get notSimplyBoundedSlot {
    _notSimplyBoundedSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _notSimplyBoundedSlot;
  }

  @override
  List<idl.UnlinkedParam> get parameters {
    _parameters ??=
        const fb.ListReader<idl.UnlinkedParam>(const _UnlinkedParamReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedParam>[]);
    return _parameters;
  }

  @override
  idl.EntityRef get returnType {
    _returnType ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 2, null);
    return _returnType;
  }

  @override
  idl.TypedefStyle get style {
    _style ??= const _TypedefStyleReader()
        .vTableGet(_bc, _bcOffset, 8, idl.TypedefStyle.functionType);
    return _style;
  }

  @override
  List<idl.UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<idl.UnlinkedTypeParam>(
            const _UnlinkedTypeParamReader())
        .vTableGet(_bc, _bcOffset, 5, const <idl.UnlinkedTypeParam>[]);
    return _typeParameters;
  }
}

abstract class _UnlinkedTypedefMixin implements idl.UnlinkedTypedef {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (notSimplyBoundedSlot != 0)
      _result["notSimplyBoundedSlot"] = notSimplyBoundedSlot;
    if (parameters.isNotEmpty)
      _result["parameters"] =
          parameters.map((_value) => _value.toJson()).toList();
    if (returnType != null) _result["returnType"] = returnType.toJson();
    if (style != idl.TypedefStyle.functionType)
      _result["style"] = style.toString().split('.')[1];
    if (typeParameters.isNotEmpty)
      _result["typeParameters"] =
          typeParameters.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "codeRange": codeRange,
        "documentationComment": documentationComment,
        "name": name,
        "nameOffset": nameOffset,
        "notSimplyBoundedSlot": notSimplyBoundedSlot,
        "parameters": parameters,
        "returnType": returnType,
        "style": style,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedTypeParamBuilder extends Object
    with _UnlinkedTypeParamMixin
    implements idl.UnlinkedTypeParam {
  List<UnlinkedExprBuilder> _annotations;
  EntityRefBuilder _bound;
  CodeRangeBuilder _codeRange;
  String _name;
  int _nameOffset;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this type parameter.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  EntityRefBuilder get bound => _bound;

  /// Bound of the type parameter, if a bound is explicitly declared.  Otherwise
  /// null.
  set bound(EntityRefBuilder value) {
    this._bound = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the type parameter.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the type parameter.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the type parameter name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  UnlinkedTypeParamBuilder(
      {List<UnlinkedExprBuilder> annotations,
      EntityRefBuilder bound,
      CodeRangeBuilder codeRange,
      String name,
      int nameOffset})
      : _annotations = annotations,
        _bound = bound,
        _codeRange = codeRange,
        _name = name,
        _nameOffset = nameOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _bound?.flushInformative();
    _codeRange = null;
    _nameOffset = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addBool(this._bound != null);
    this._bound?.collectApiSignature(signature);
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_bound;
    fb.Offset offset_codeRange;
    fb.Offset offset_name;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_bound != null) {
      offset_bound = _bound.finish(fbBuilder);
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(3, offset_annotations);
    }
    if (offset_bound != null) {
      fbBuilder.addOffset(2, offset_bound);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(4, offset_codeRange);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedTypeParamReader extends fb.TableReader<_UnlinkedTypeParamImpl> {
  const _UnlinkedTypeParamReader();

  @override
  _UnlinkedTypeParamImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedTypeParamImpl(bc, offset);
}

class _UnlinkedTypeParamImpl extends Object
    with _UnlinkedTypeParamMixin
    implements idl.UnlinkedTypeParam {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedTypeParamImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.EntityRef _bound;
  idl.CodeRange _codeRange;
  String _name;
  int _nameOffset;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.EntityRef get bound {
    _bound ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 2, null);
    return _bound;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 4, null);
    return _codeRange;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }
}

abstract class _UnlinkedTypeParamMixin implements idl.UnlinkedTypeParam {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (bound != null) _result["bound"] = bound.toJson();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "bound": bound,
        "codeRange": codeRange,
        "name": name,
        "nameOffset": nameOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedUnitBuilder extends Object
    with _UnlinkedUnitMixin
    implements idl.UnlinkedUnit {
  List<int> _apiSignature;
  List<UnlinkedClassBuilder> _classes;
  CodeRangeBuilder _codeRange;
  List<UnlinkedEnumBuilder> _enums;
  List<UnlinkedExecutableBuilder> _executables;
  List<UnlinkedExportNonPublicBuilder> _exports;
  List<UnlinkedImportBuilder> _imports;
  bool _isPartOf;
  List<UnlinkedExprBuilder> _libraryAnnotations;
  UnlinkedDocumentationCommentBuilder _libraryDocumentationComment;
  String _libraryName;
  int _libraryNameLength;
  int _libraryNameOffset;
  List<int> _lineStarts;
  List<UnlinkedClassBuilder> _mixins;
  List<UnlinkedPartBuilder> _parts;
  UnlinkedPublicNamespaceBuilder _publicNamespace;
  List<UnlinkedReferenceBuilder> _references;
  List<UnlinkedTypedefBuilder> _typedefs;
  List<UnlinkedVariableBuilder> _variables;

  @override
  List<int> get apiSignature => _apiSignature ??= <int>[];

  /// MD5 hash of the non-informative fields of the [UnlinkedUnit] (not
  /// including this one) as 16 unsigned 8-bit integer values.  This can be used
  /// to identify when the API of a unit may have changed.
  set apiSignature(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._apiSignature = value;
  }

  @override
  List<UnlinkedClassBuilder> get classes =>
      _classes ??= <UnlinkedClassBuilder>[];

  /// Classes declared in the compilation unit.
  set classes(List<UnlinkedClassBuilder> value) {
    this._classes = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the unit.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  List<UnlinkedEnumBuilder> get enums => _enums ??= <UnlinkedEnumBuilder>[];

  /// Enums declared in the compilation unit.
  set enums(List<UnlinkedEnumBuilder> value) {
    this._enums = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables =>
      _executables ??= <UnlinkedExecutableBuilder>[];

  /// Top level executable objects (functions, getters, and setters) declared in
  /// the compilation unit.
  set executables(List<UnlinkedExecutableBuilder> value) {
    this._executables = value;
  }

  @override
  List<UnlinkedExportNonPublicBuilder> get exports =>
      _exports ??= <UnlinkedExportNonPublicBuilder>[];

  /// Export declarations in the compilation unit.
  set exports(List<UnlinkedExportNonPublicBuilder> value) {
    this._exports = value;
  }

  @override
  Null get fallbackModePath =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<UnlinkedImportBuilder> get imports =>
      _imports ??= <UnlinkedImportBuilder>[];

  /// Import declarations in the compilation unit.
  set imports(List<UnlinkedImportBuilder> value) {
    this._imports = value;
  }

  @override
  bool get isPartOf => _isPartOf ??= false;

  /// Indicates whether the unit contains a "part of" declaration.
  set isPartOf(bool value) {
    this._isPartOf = value;
  }

  @override
  List<UnlinkedExprBuilder> get libraryAnnotations =>
      _libraryAnnotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for the library declaration, or the empty list if there is no
  /// library declaration.
  set libraryAnnotations(List<UnlinkedExprBuilder> value) {
    this._libraryAnnotations = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get libraryDocumentationComment =>
      _libraryDocumentationComment;

  /// Documentation comment for the library, or `null` if there is no
  /// documentation comment.
  set libraryDocumentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._libraryDocumentationComment = value;
  }

  @override
  String get libraryName => _libraryName ??= '';

  /// Name of the library (from a "library" declaration, if present).
  set libraryName(String value) {
    this._libraryName = value;
  }

  @override
  int get libraryNameLength => _libraryNameLength ??= 0;

  /// Length of the library name as it appears in the source code (or 0 if the
  /// library has no name).
  set libraryNameLength(int value) {
    assert(value == null || value >= 0);
    this._libraryNameLength = value;
  }

  @override
  int get libraryNameOffset => _libraryNameOffset ??= 0;

  /// Offset of the library name relative to the beginning of the file (or 0 if
  /// the library has no name).
  set libraryNameOffset(int value) {
    assert(value == null || value >= 0);
    this._libraryNameOffset = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /// Offsets of the first character of each line in the source code.
  set lineStarts(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  List<UnlinkedClassBuilder> get mixins => _mixins ??= <UnlinkedClassBuilder>[];

  /// Mixins declared in the compilation unit.
  set mixins(List<UnlinkedClassBuilder> value) {
    this._mixins = value;
  }

  @override
  List<UnlinkedPartBuilder> get parts => _parts ??= <UnlinkedPartBuilder>[];

  /// Part declarations in the compilation unit.
  set parts(List<UnlinkedPartBuilder> value) {
    this._parts = value;
  }

  @override
  UnlinkedPublicNamespaceBuilder get publicNamespace => _publicNamespace;

  /// Unlinked public namespace of this compilation unit.
  set publicNamespace(UnlinkedPublicNamespaceBuilder value) {
    this._publicNamespace = value;
  }

  @override
  List<UnlinkedReferenceBuilder> get references =>
      _references ??= <UnlinkedReferenceBuilder>[];

  /// Top level and prefixed names referred to by this compilation unit.  The
  /// zeroth element of this array is always populated and is used to represent
  /// the absence of a reference in places where a reference is optional (for
  /// example [UnlinkedReference.prefixReference or
  /// UnlinkedImport.prefixReference]).
  set references(List<UnlinkedReferenceBuilder> value) {
    this._references = value;
  }

  @override
  List<UnlinkedTypedefBuilder> get typedefs =>
      _typedefs ??= <UnlinkedTypedefBuilder>[];

  /// Typedefs declared in the compilation unit.
  set typedefs(List<UnlinkedTypedefBuilder> value) {
    this._typedefs = value;
  }

  @override
  List<UnlinkedVariableBuilder> get variables =>
      _variables ??= <UnlinkedVariableBuilder>[];

  /// Top level variables declared in the compilation unit.
  set variables(List<UnlinkedVariableBuilder> value) {
    this._variables = value;
  }

  UnlinkedUnitBuilder(
      {List<int> apiSignature,
      List<UnlinkedClassBuilder> classes,
      CodeRangeBuilder codeRange,
      List<UnlinkedEnumBuilder> enums,
      List<UnlinkedExecutableBuilder> executables,
      List<UnlinkedExportNonPublicBuilder> exports,
      List<UnlinkedImportBuilder> imports,
      bool isPartOf,
      List<UnlinkedExprBuilder> libraryAnnotations,
      UnlinkedDocumentationCommentBuilder libraryDocumentationComment,
      String libraryName,
      int libraryNameLength,
      int libraryNameOffset,
      List<int> lineStarts,
      List<UnlinkedClassBuilder> mixins,
      List<UnlinkedPartBuilder> parts,
      UnlinkedPublicNamespaceBuilder publicNamespace,
      List<UnlinkedReferenceBuilder> references,
      List<UnlinkedTypedefBuilder> typedefs,
      List<UnlinkedVariableBuilder> variables})
      : _apiSignature = apiSignature,
        _classes = classes,
        _codeRange = codeRange,
        _enums = enums,
        _executables = executables,
        _exports = exports,
        _imports = imports,
        _isPartOf = isPartOf,
        _libraryAnnotations = libraryAnnotations,
        _libraryDocumentationComment = libraryDocumentationComment,
        _libraryName = libraryName,
        _libraryNameLength = libraryNameLength,
        _libraryNameOffset = libraryNameOffset,
        _lineStarts = lineStarts,
        _mixins = mixins,
        _parts = parts,
        _publicNamespace = publicNamespace,
        _references = references,
        _typedefs = typedefs,
        _variables = variables;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _classes?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _enums?.forEach((b) => b.flushInformative());
    _executables?.forEach((b) => b.flushInformative());
    _exports?.forEach((b) => b.flushInformative());
    _imports?.forEach((b) => b.flushInformative());
    _libraryAnnotations?.forEach((b) => b.flushInformative());
    _libraryDocumentationComment = null;
    _libraryNameLength = null;
    _libraryNameOffset = null;
    _lineStarts = null;
    _mixins?.forEach((b) => b.flushInformative());
    _parts?.forEach((b) => b.flushInformative());
    _publicNamespace?.flushInformative();
    _references?.forEach((b) => b.flushInformative());
    _typedefs?.forEach((b) => b.flushInformative());
    _variables?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._publicNamespace != null);
    this._publicNamespace?.collectApiSignature(signature);
    if (this._references == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._references.length);
      for (var x in this._references) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._classes == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._classes.length);
      for (var x in this._classes) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._variables == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._variables.length);
      for (var x in this._variables) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._executables == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._executables.length);
      for (var x in this._executables) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._imports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._imports.length);
      for (var x in this._imports) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addString(this._libraryName ?? '');
    if (this._typedefs == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typedefs.length);
      for (var x in this._typedefs) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._enums == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._enums.length);
      for (var x in this._enums) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._libraryAnnotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._libraryAnnotations.length);
      for (var x in this._libraryAnnotations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isPartOf == true);
    if (this._apiSignature == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._apiSignature.length);
      for (var x in this._apiSignature) {
        signature.addInt(x);
      }
    }
    if (this._mixins == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._mixins.length);
      for (var x in this._mixins) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UUnt");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_classes;
    fb.Offset offset_codeRange;
    fb.Offset offset_enums;
    fb.Offset offset_executables;
    fb.Offset offset_exports;
    fb.Offset offset_imports;
    fb.Offset offset_libraryAnnotations;
    fb.Offset offset_libraryDocumentationComment;
    fb.Offset offset_libraryName;
    fb.Offset offset_lineStarts;
    fb.Offset offset_mixins;
    fb.Offset offset_parts;
    fb.Offset offset_publicNamespace;
    fb.Offset offset_references;
    fb.Offset offset_typedefs;
    fb.Offset offset_variables;
    if (!(_apiSignature == null || _apiSignature.isEmpty)) {
      offset_apiSignature = fbBuilder.writeListUint32(_apiSignature);
    }
    if (!(_classes == null || _classes.isEmpty)) {
      offset_classes = fbBuilder
          .writeList(_classes.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (!(_enums == null || _enums.isEmpty)) {
      offset_enums =
          fbBuilder.writeList(_enums.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_executables == null || _executables.isEmpty)) {
      offset_executables = fbBuilder
          .writeList(_executables.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_imports == null || _imports.isEmpty)) {
      offset_imports = fbBuilder
          .writeList(_imports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_libraryAnnotations == null || _libraryAnnotations.isEmpty)) {
      offset_libraryAnnotations = fbBuilder.writeList(
          _libraryAnnotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_libraryDocumentationComment != null) {
      offset_libraryDocumentationComment =
          _libraryDocumentationComment.finish(fbBuilder);
    }
    if (_libraryName != null) {
      offset_libraryName = fbBuilder.writeString(_libraryName);
    }
    if (!(_lineStarts == null || _lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(_lineStarts);
    }
    if (!(_mixins == null || _mixins.isEmpty)) {
      offset_mixins =
          fbBuilder.writeList(_mixins.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts =
          fbBuilder.writeList(_parts.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_publicNamespace != null) {
      offset_publicNamespace = _publicNamespace.finish(fbBuilder);
    }
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder
          .writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_typedefs == null || _typedefs.isEmpty)) {
      offset_typedefs = fbBuilder
          .writeList(_typedefs.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_variables == null || _variables.isEmpty)) {
      offset_variables = fbBuilder
          .writeList(_variables.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_apiSignature != null) {
      fbBuilder.addOffset(19, offset_apiSignature);
    }
    if (offset_classes != null) {
      fbBuilder.addOffset(2, offset_classes);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(15, offset_codeRange);
    }
    if (offset_enums != null) {
      fbBuilder.addOffset(12, offset_enums);
    }
    if (offset_executables != null) {
      fbBuilder.addOffset(4, offset_executables);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(13, offset_exports);
    }
    if (offset_imports != null) {
      fbBuilder.addOffset(5, offset_imports);
    }
    if (_isPartOf == true) {
      fbBuilder.addBool(18, true);
    }
    if (offset_libraryAnnotations != null) {
      fbBuilder.addOffset(14, offset_libraryAnnotations);
    }
    if (offset_libraryDocumentationComment != null) {
      fbBuilder.addOffset(9, offset_libraryDocumentationComment);
    }
    if (offset_libraryName != null) {
      fbBuilder.addOffset(6, offset_libraryName);
    }
    if (_libraryNameLength != null && _libraryNameLength != 0) {
      fbBuilder.addUint32(7, _libraryNameLength);
    }
    if (_libraryNameOffset != null && _libraryNameOffset != 0) {
      fbBuilder.addUint32(8, _libraryNameOffset);
    }
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(17, offset_lineStarts);
    }
    if (offset_mixins != null) {
      fbBuilder.addOffset(20, offset_mixins);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(11, offset_parts);
    }
    if (offset_publicNamespace != null) {
      fbBuilder.addOffset(0, offset_publicNamespace);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(1, offset_references);
    }
    if (offset_typedefs != null) {
      fbBuilder.addOffset(10, offset_typedefs);
    }
    if (offset_variables != null) {
      fbBuilder.addOffset(3, offset_variables);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedUnit readUnlinkedUnit(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedUnitReader().read(rootRef, 0);
}

class _UnlinkedUnitReader extends fb.TableReader<_UnlinkedUnitImpl> {
  const _UnlinkedUnitReader();

  @override
  _UnlinkedUnitImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedUnitImpl(bc, offset);
}

class _UnlinkedUnitImpl extends Object
    with _UnlinkedUnitMixin
    implements idl.UnlinkedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedUnitImpl(this._bc, this._bcOffset);

  List<int> _apiSignature;
  List<idl.UnlinkedClass> _classes;
  idl.CodeRange _codeRange;
  List<idl.UnlinkedEnum> _enums;
  List<idl.UnlinkedExecutable> _executables;
  List<idl.UnlinkedExportNonPublic> _exports;
  List<idl.UnlinkedImport> _imports;
  bool _isPartOf;
  List<idl.UnlinkedExpr> _libraryAnnotations;
  idl.UnlinkedDocumentationComment _libraryDocumentationComment;
  String _libraryName;
  int _libraryNameLength;
  int _libraryNameOffset;
  List<int> _lineStarts;
  List<idl.UnlinkedClass> _mixins;
  List<idl.UnlinkedPart> _parts;
  idl.UnlinkedPublicNamespace _publicNamespace;
  List<idl.UnlinkedReference> _references;
  List<idl.UnlinkedTypedef> _typedefs;
  List<idl.UnlinkedVariable> _variables;

  @override
  List<int> get apiSignature {
    _apiSignature ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 19, const <int>[]);
    return _apiSignature;
  }

  @override
  List<idl.UnlinkedClass> get classes {
    _classes ??=
        const fb.ListReader<idl.UnlinkedClass>(const _UnlinkedClassReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedClass>[]);
    return _classes;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 15, null);
    return _codeRange;
  }

  @override
  List<idl.UnlinkedEnum> get enums {
    _enums ??=
        const fb.ListReader<idl.UnlinkedEnum>(const _UnlinkedEnumReader())
            .vTableGet(_bc, _bcOffset, 12, const <idl.UnlinkedEnum>[]);
    return _enums;
  }

  @override
  List<idl.UnlinkedExecutable> get executables {
    _executables ??= const fb.ListReader<idl.UnlinkedExecutable>(
            const _UnlinkedExecutableReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.UnlinkedExecutable>[]);
    return _executables;
  }

  @override
  List<idl.UnlinkedExportNonPublic> get exports {
    _exports ??= const fb.ListReader<idl.UnlinkedExportNonPublic>(
            const _UnlinkedExportNonPublicReader())
        .vTableGet(_bc, _bcOffset, 13, const <idl.UnlinkedExportNonPublic>[]);
    return _exports;
  }

  @override
  Null get fallbackModePath =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<idl.UnlinkedImport> get imports {
    _imports ??=
        const fb.ListReader<idl.UnlinkedImport>(const _UnlinkedImportReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.UnlinkedImport>[]);
    return _imports;
  }

  @override
  bool get isPartOf {
    _isPartOf ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 18, false);
    return _isPartOf;
  }

  @override
  List<idl.UnlinkedExpr> get libraryAnnotations {
    _libraryAnnotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 14, const <idl.UnlinkedExpr>[]);
    return _libraryAnnotations;
  }

  @override
  idl.UnlinkedDocumentationComment get libraryDocumentationComment {
    _libraryDocumentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 9, null);
    return _libraryDocumentationComment;
  }

  @override
  String get libraryName {
    _libraryName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 6, '');
    return _libraryName;
  }

  @override
  int get libraryNameLength {
    _libraryNameLength ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 7, 0);
    return _libraryNameLength;
  }

  @override
  int get libraryNameOffset {
    _libraryNameOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 8, 0);
    return _libraryNameOffset;
  }

  @override
  List<int> get lineStarts {
    _lineStarts ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 17, const <int>[]);
    return _lineStarts;
  }

  @override
  List<idl.UnlinkedClass> get mixins {
    _mixins ??=
        const fb.ListReader<idl.UnlinkedClass>(const _UnlinkedClassReader())
            .vTableGet(_bc, _bcOffset, 20, const <idl.UnlinkedClass>[]);
    return _mixins;
  }

  @override
  List<idl.UnlinkedPart> get parts {
    _parts ??=
        const fb.ListReader<idl.UnlinkedPart>(const _UnlinkedPartReader())
            .vTableGet(_bc, _bcOffset, 11, const <idl.UnlinkedPart>[]);
    return _parts;
  }

  @override
  idl.UnlinkedPublicNamespace get publicNamespace {
    _publicNamespace ??= const _UnlinkedPublicNamespaceReader()
        .vTableGet(_bc, _bcOffset, 0, null);
    return _publicNamespace;
  }

  @override
  List<idl.UnlinkedReference> get references {
    _references ??= const fb.ListReader<idl.UnlinkedReference>(
            const _UnlinkedReferenceReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.UnlinkedReference>[]);
    return _references;
  }

  @override
  List<idl.UnlinkedTypedef> get typedefs {
    _typedefs ??=
        const fb.ListReader<idl.UnlinkedTypedef>(const _UnlinkedTypedefReader())
            .vTableGet(_bc, _bcOffset, 10, const <idl.UnlinkedTypedef>[]);
    return _typedefs;
  }

  @override
  List<idl.UnlinkedVariable> get variables {
    _variables ??= const fb.ListReader<idl.UnlinkedVariable>(
            const _UnlinkedVariableReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.UnlinkedVariable>[]);
    return _variables;
  }
}

abstract class _UnlinkedUnitMixin implements idl.UnlinkedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (apiSignature.isNotEmpty) _result["apiSignature"] = apiSignature;
    if (classes.isNotEmpty)
      _result["classes"] = classes.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (enums.isNotEmpty)
      _result["enums"] = enums.map((_value) => _value.toJson()).toList();
    if (executables.isNotEmpty)
      _result["executables"] =
          executables.map((_value) => _value.toJson()).toList();
    if (exports.isNotEmpty)
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    if (imports.isNotEmpty)
      _result["imports"] = imports.map((_value) => _value.toJson()).toList();
    if (isPartOf != false) _result["isPartOf"] = isPartOf;
    if (libraryAnnotations.isNotEmpty)
      _result["libraryAnnotations"] =
          libraryAnnotations.map((_value) => _value.toJson()).toList();
    if (libraryDocumentationComment != null)
      _result["libraryDocumentationComment"] =
          libraryDocumentationComment.toJson();
    if (libraryName != '') _result["libraryName"] = libraryName;
    if (libraryNameLength != 0)
      _result["libraryNameLength"] = libraryNameLength;
    if (libraryNameOffset != 0)
      _result["libraryNameOffset"] = libraryNameOffset;
    if (lineStarts.isNotEmpty) _result["lineStarts"] = lineStarts;
    if (mixins.isNotEmpty)
      _result["mixins"] = mixins.map((_value) => _value.toJson()).toList();
    if (parts.isNotEmpty)
      _result["parts"] = parts.map((_value) => _value.toJson()).toList();
    if (publicNamespace != null)
      _result["publicNamespace"] = publicNamespace.toJson();
    if (references.isNotEmpty)
      _result["references"] =
          references.map((_value) => _value.toJson()).toList();
    if (typedefs.isNotEmpty)
      _result["typedefs"] = typedefs.map((_value) => _value.toJson()).toList();
    if (variables.isNotEmpty)
      _result["variables"] =
          variables.map((_value) => _value.toJson()).toList();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "apiSignature": apiSignature,
        "classes": classes,
        "codeRange": codeRange,
        "enums": enums,
        "executables": executables,
        "exports": exports,
        "imports": imports,
        "isPartOf": isPartOf,
        "libraryAnnotations": libraryAnnotations,
        "libraryDocumentationComment": libraryDocumentationComment,
        "libraryName": libraryName,
        "libraryNameLength": libraryNameLength,
        "libraryNameOffset": libraryNameOffset,
        "lineStarts": lineStarts,
        "mixins": mixins,
        "parts": parts,
        "publicNamespace": publicNamespace,
        "references": references,
        "typedefs": typedefs,
        "variables": variables,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedUnit2Builder extends Object
    with _UnlinkedUnit2Mixin
    implements idl.UnlinkedUnit2 {
  List<int> _apiSignature;
  List<String> _exports;
  List<String> _imports;
  bool _isPartOf;
  List<int> _lineStarts;
  List<String> _parts;

  @override
  List<int> get apiSignature => _apiSignature ??= <int>[];

  /// The MD5 hash signature of the API portion of this unit. It depends on all
  /// tokens that might affect APIs of declarations in the unit.
  set apiSignature(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._apiSignature = value;
  }

  @override
  List<String> get exports => _exports ??= <String>[];

  /// URIs of `export` directives.
  set exports(List<String> value) {
    this._exports = value;
  }

  @override
  List<String> get imports => _imports ??= <String>[];

  /// URIs of `import` directives.
  set imports(List<String> value) {
    this._imports = value;
  }

  @override
  bool get isPartOf => _isPartOf ??= false;

  /// Is `true` if the unit contains a `part of` directive.
  set isPartOf(bool value) {
    this._isPartOf = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /// Offsets of the first character of each line in the source code.
  set lineStarts(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /// URIs of `part` directives.
  set parts(List<String> value) {
    this._parts = value;
  }

  UnlinkedUnit2Builder(
      {List<int> apiSignature,
      List<String> exports,
      List<String> imports,
      bool isPartOf,
      List<int> lineStarts,
      List<String> parts})
      : _apiSignature = apiSignature,
        _exports = exports,
        _imports = imports,
        _isPartOf = isPartOf,
        _lineStarts = lineStarts,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _lineStarts = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._apiSignature == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._apiSignature.length);
      for (var x in this._apiSignature) {
        signature.addInt(x);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        signature.addString(x);
      }
    }
    if (this._imports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._imports.length);
      for (var x in this._imports) {
        signature.addString(x);
      }
    }
    signature.addBool(this._isPartOf == true);
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        signature.addString(x);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UUN2");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_exports;
    fb.Offset offset_imports;
    fb.Offset offset_lineStarts;
    fb.Offset offset_parts;
    if (!(_apiSignature == null || _apiSignature.isEmpty)) {
      offset_apiSignature = fbBuilder.writeListUint32(_apiSignature);
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_imports == null || _imports.isEmpty)) {
      offset_imports = fbBuilder
          .writeList(_imports.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_lineStarts == null || _lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(_lineStarts);
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder
          .writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_apiSignature != null) {
      fbBuilder.addOffset(0, offset_apiSignature);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(1, offset_exports);
    }
    if (offset_imports != null) {
      fbBuilder.addOffset(2, offset_imports);
    }
    if (_isPartOf == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(5, offset_lineStarts);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(4, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedUnit2 readUnlinkedUnit2(List<int> buffer) {
  fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedUnit2Reader().read(rootRef, 0);
}

class _UnlinkedUnit2Reader extends fb.TableReader<_UnlinkedUnit2Impl> {
  const _UnlinkedUnit2Reader();

  @override
  _UnlinkedUnit2Impl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedUnit2Impl(bc, offset);
}

class _UnlinkedUnit2Impl extends Object
    with _UnlinkedUnit2Mixin
    implements idl.UnlinkedUnit2 {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedUnit2Impl(this._bc, this._bcOffset);

  List<int> _apiSignature;
  List<String> _exports;
  List<String> _imports;
  bool _isPartOf;
  List<int> _lineStarts;
  List<String> _parts;

  @override
  List<int> get apiSignature {
    _apiSignature ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _apiSignature;
  }

  @override
  List<String> get exports {
    _exports ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _exports;
  }

  @override
  List<String> get imports {
    _imports ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _imports;
  }

  @override
  bool get isPartOf {
    _isPartOf ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isPartOf;
  }

  @override
  List<int> get lineStarts {
    _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _lineStarts;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _parts;
  }
}

abstract class _UnlinkedUnit2Mixin implements idl.UnlinkedUnit2 {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (apiSignature.isNotEmpty) _result["apiSignature"] = apiSignature;
    if (exports.isNotEmpty) _result["exports"] = exports;
    if (imports.isNotEmpty) _result["imports"] = imports;
    if (isPartOf != false) _result["isPartOf"] = isPartOf;
    if (lineStarts.isNotEmpty) _result["lineStarts"] = lineStarts;
    if (parts.isNotEmpty) _result["parts"] = parts;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "apiSignature": apiSignature,
        "exports": exports,
        "imports": imports,
        "isPartOf": isPartOf,
        "lineStarts": lineStarts,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedVariableBuilder extends Object
    with _UnlinkedVariableMixin
    implements idl.UnlinkedVariable {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  int _inferredTypeSlot;
  int _inheritsCovariantSlot;
  UnlinkedExecutableBuilder _initializer;
  bool _isConst;
  bool _isCovariant;
  bool _isFinal;
  bool _isLate;
  bool _isStatic;
  String _name;
  int _nameOffset;
  int _propagatedTypeSlot;
  EntityRefBuilder _type;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /// Annotations for this variable.
  set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /// Code range of the variable.
  set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /// Documentation comment for the variable, or `null` if there is no
  /// documentation comment.
  set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  int get inferredTypeSlot => _inferredTypeSlot ??= 0;

  /// If this variable is inferable, nonzero slot id identifying which entry in
  /// [LinkedLibrary.types] contains the inferred type for this variable.  If
  /// there is no matching entry in [LinkedLibrary.types], then no type was
  /// inferred for this variable, so its static type is `dynamic`.
  set inferredTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredTypeSlot = value;
  }

  @override
  int get inheritsCovariantSlot => _inheritsCovariantSlot ??= 0;

  /// If this is an instance non-final field, a nonzero slot id which is unique
  /// within this compilation unit.  If this id is found in
  /// [LinkedUnit.parametersInheritingCovariant], then the parameter of the
  /// synthetic setter inherits `@covariant` behavior from a base class.
  ///
  /// Otherwise, zero.
  set inheritsCovariantSlot(int value) {
    assert(value == null || value >= 0);
    this._inheritsCovariantSlot = value;
  }

  @override
  UnlinkedExecutableBuilder get initializer => _initializer;

  /// The synthetic initializer function of the variable.  Absent if the
  /// variable does not have an initializer.
  set initializer(UnlinkedExecutableBuilder value) {
    this._initializer = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /// Indicates whether the variable is declared using the `const` keyword.
  set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isCovariant => _isCovariant ??= false;

  /// Indicates whether this variable is declared using the `covariant` keyword.
  /// This should be false for everything except instance fields.
  set isCovariant(bool value) {
    this._isCovariant = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  /// Indicates whether the variable is declared using the `final` keyword.
  set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isLate => _isLate ??= false;

  /// Indicates whether the variable is declared using the `late` keyword.
  set isLate(bool value) {
    this._isLate = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /// Indicates whether the variable is declared using the `static` keyword.
  ///
  /// Note that for top level variables, this flag is false, since they are not
  /// declared using the `static` keyword (even though they are considered
  /// static for semantic purposes).
  set isStatic(bool value) {
    this._isStatic = value;
  }

  @override
  String get name => _name ??= '';

  /// Name of the variable.
  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /// Offset of the variable name relative to the beginning of the file.
  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  int get propagatedTypeSlot => _propagatedTypeSlot ??= 0;

  /// If this variable is propagable, nonzero slot id identifying which entry in
  /// [LinkedLibrary.types] contains the propagated type for this variable.  If
  /// there is no matching entry in [LinkedLibrary.types], then this variable's
  /// propagated type is the same as its declared type.
  ///
  /// Non-propagable variables have a [propagatedTypeSlot] of zero.
  set propagatedTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._propagatedTypeSlot = value;
  }

  @override
  EntityRefBuilder get type => _type;

  /// Declared type of the variable.  Absent if the type is implicit.
  set type(EntityRefBuilder value) {
    this._type = value;
  }

  @override
  Null get visibleLength =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get visibleOffset =>
      throw new UnimplementedError('attempt to access deprecated field');

  UnlinkedVariableBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      UnlinkedDocumentationCommentBuilder documentationComment,
      int inferredTypeSlot,
      int inheritsCovariantSlot,
      UnlinkedExecutableBuilder initializer,
      bool isConst,
      bool isCovariant,
      bool isFinal,
      bool isLate,
      bool isStatic,
      String name,
      int nameOffset,
      int propagatedTypeSlot,
      EntityRefBuilder type})
      : _annotations = annotations,
        _codeRange = codeRange,
        _documentationComment = documentationComment,
        _inferredTypeSlot = inferredTypeSlot,
        _inheritsCovariantSlot = inheritsCovariantSlot,
        _initializer = initializer,
        _isConst = isConst,
        _isCovariant = isCovariant,
        _isFinal = isFinal,
        _isLate = isLate,
        _isStatic = isStatic,
        _name = name,
        _nameOffset = nameOffset,
        _propagatedTypeSlot = propagatedTypeSlot,
        _type = type;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _initializer?.flushInformative();
    _nameOffset = null;
    _type?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addInt(this._propagatedTypeSlot ?? 0);
    signature.addBool(this._type != null);
    this._type?.collectApiSignature(signature);
    signature.addBool(this._isStatic == true);
    signature.addBool(this._isConst == true);
    signature.addBool(this._isFinal == true);
    if (this._annotations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotations.length);
      for (var x in this._annotations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._inferredTypeSlot ?? 0);
    signature.addBool(this._initializer != null);
    this._initializer?.collectApiSignature(signature);
    signature.addBool(this._isCovariant == true);
    signature.addInt(this._inheritsCovariantSlot ?? 0);
    signature.addBool(this._isLate == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotations;
    fb.Offset offset_codeRange;
    fb.Offset offset_documentationComment;
    fb.Offset offset_initializer;
    fb.Offset offset_name;
    fb.Offset offset_type;
    if (!(_annotations == null || _annotations.isEmpty)) {
      offset_annotations = fbBuilder
          .writeList(_annotations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_codeRange != null) {
      offset_codeRange = _codeRange.finish(fbBuilder);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_initializer != null) {
      offset_initializer = _initializer.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_annotations != null) {
      fbBuilder.addOffset(8, offset_annotations);
    }
    if (offset_codeRange != null) {
      fbBuilder.addOffset(5, offset_codeRange);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(10, offset_documentationComment);
    }
    if (_inferredTypeSlot != null && _inferredTypeSlot != 0) {
      fbBuilder.addUint32(9, _inferredTypeSlot);
    }
    if (_inheritsCovariantSlot != null && _inheritsCovariantSlot != 0) {
      fbBuilder.addUint32(15, _inheritsCovariantSlot);
    }
    if (offset_initializer != null) {
      fbBuilder.addOffset(13, offset_initializer);
    }
    if (_isConst == true) {
      fbBuilder.addBool(6, true);
    }
    if (_isCovariant == true) {
      fbBuilder.addBool(14, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(7, true);
    }
    if (_isLate == true) {
      fbBuilder.addBool(16, true);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(4, true);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (_propagatedTypeSlot != null && _propagatedTypeSlot != 0) {
      fbBuilder.addUint32(2, _propagatedTypeSlot);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(3, offset_type);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedVariableReader extends fb.TableReader<_UnlinkedVariableImpl> {
  const _UnlinkedVariableReader();

  @override
  _UnlinkedVariableImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedVariableImpl(bc, offset);
}

class _UnlinkedVariableImpl extends Object
    with _UnlinkedVariableMixin
    implements idl.UnlinkedVariable {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedVariableImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedExpr> _annotations;
  idl.CodeRange _codeRange;
  idl.UnlinkedDocumentationComment _documentationComment;
  int _inferredTypeSlot;
  int _inheritsCovariantSlot;
  idl.UnlinkedExecutable _initializer;
  bool _isConst;
  bool _isCovariant;
  bool _isFinal;
  bool _isLate;
  bool _isStatic;
  String _name;
  int _nameOffset;
  int _propagatedTypeSlot;
  idl.EntityRef _type;

  @override
  List<idl.UnlinkedExpr> get annotations {
    _annotations ??=
        const fb.ListReader<idl.UnlinkedExpr>(const _UnlinkedExprReader())
            .vTableGet(_bc, _bcOffset, 8, const <idl.UnlinkedExpr>[]);
    return _annotations;
  }

  @override
  idl.CodeRange get codeRange {
    _codeRange ??= const _CodeRangeReader().vTableGet(_bc, _bcOffset, 5, null);
    return _codeRange;
  }

  @override
  idl.UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader()
        .vTableGet(_bc, _bcOffset, 10, null);
    return _documentationComment;
  }

  @override
  int get inferredTypeSlot {
    _inferredTypeSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _inferredTypeSlot;
  }

  @override
  int get inheritsCovariantSlot {
    _inheritsCovariantSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _inheritsCovariantSlot;
  }

  @override
  idl.UnlinkedExecutable get initializer {
    _initializer ??=
        const _UnlinkedExecutableReader().vTableGet(_bc, _bcOffset, 13, null);
    return _initializer;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 6, false);
    return _isConst;
  }

  @override
  bool get isCovariant {
    _isCovariant ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 14, false);
    return _isCovariant;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 7, false);
    return _isFinal;
  }

  @override
  bool get isLate {
    _isLate ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 16, false);
    return _isLate;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 4, false);
    return _isStatic;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  int get propagatedTypeSlot {
    _propagatedTypeSlot ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _propagatedTypeSlot;
  }

  @override
  idl.EntityRef get type {
    _type ??= const _EntityRefReader().vTableGet(_bc, _bcOffset, 3, null);
    return _type;
  }

  @override
  Null get visibleLength =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  Null get visibleOffset =>
      throw new UnimplementedError('attempt to access deprecated field');
}

abstract class _UnlinkedVariableMixin implements idl.UnlinkedVariable {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotations.isNotEmpty)
      _result["annotations"] =
          annotations.map((_value) => _value.toJson()).toList();
    if (codeRange != null) _result["codeRange"] = codeRange.toJson();
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (inferredTypeSlot != 0) _result["inferredTypeSlot"] = inferredTypeSlot;
    if (inheritsCovariantSlot != 0)
      _result["inheritsCovariantSlot"] = inheritsCovariantSlot;
    if (initializer != null) _result["initializer"] = initializer.toJson();
    if (isConst != false) _result["isConst"] = isConst;
    if (isCovariant != false) _result["isCovariant"] = isCovariant;
    if (isFinal != false) _result["isFinal"] = isFinal;
    if (isLate != false) _result["isLate"] = isLate;
    if (isStatic != false) _result["isStatic"] = isStatic;
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (propagatedTypeSlot != 0)
      _result["propagatedTypeSlot"] = propagatedTypeSlot;
    if (type != null) _result["type"] = type.toJson();
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotations": annotations,
        "codeRange": codeRange,
        "documentationComment": documentationComment,
        "inferredTypeSlot": inferredTypeSlot,
        "inheritsCovariantSlot": inheritsCovariantSlot,
        "initializer": initializer,
        "isConst": isConst,
        "isCovariant": isCovariant,
        "isFinal": isFinal,
        "isLate": isLate,
        "isStatic": isStatic,
        "name": name,
        "nameOffset": nameOffset,
        "propagatedTypeSlot": propagatedTypeSlot,
        "type": type,
      };

  @override
  String toString() => convert.json.encode(toJson());
}
