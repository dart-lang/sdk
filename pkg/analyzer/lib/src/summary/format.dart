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
    fb.Builder fbBuilder = fb.Builder();
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
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverExceptionContextReader().read(rootRef, 0);
}

class _AnalysisDriverExceptionContextReader
    extends fb.TableReader<_AnalysisDriverExceptionContextImpl> {
  const _AnalysisDriverExceptionContextReader();

  @override
  _AnalysisDriverExceptionContextImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverExceptionContextImpl(bc, offset);
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
            _AnalysisDriverExceptionFileReader())
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
    if (exception != '') {
      _result["exception"] = exception;
    }
    if (files.isNotEmpty) {
      _result["files"] = files.map((_value) => _value.toJson()).toList();
    }
    if (path != '') {
      _result["path"] = path;
    }
    if (stackTrace != '') {
      _result["stackTrace"] = stackTrace;
    }
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
      _AnalysisDriverExceptionFileImpl(bc, offset);
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
    if (content != '') {
      _result["content"] = content;
    }
    if (path != '') {
      _result["path"] = path;
    }
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
    fb.Builder fbBuilder = fb.Builder();
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
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverResolvedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverResolvedUnitReader
    extends fb.TableReader<_AnalysisDriverResolvedUnitImpl> {
  const _AnalysisDriverResolvedUnitReader();

  @override
  _AnalysisDriverResolvedUnitImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverResolvedUnitImpl(bc, offset);
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
            _AnalysisDriverUnitErrorReader())
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
    if (errors.isNotEmpty) {
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    }
    if (index != null) {
      _result["index"] = index.toJson();
    }
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
      _AnalysisDriverSubtypeImpl(bc, offset);
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
    if (members.isNotEmpty) {
      _result["members"] = members;
    }
    if (name != 0) {
      _result["name"] = name;
    }
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
  List<DiagnosticMessageBuilder> _contextMessages;
  String _correction;
  int _length;
  String _message;
  int _offset;
  String _uniqueName;

  @override
  List<DiagnosticMessageBuilder> get contextMessages =>
      _contextMessages ??= <DiagnosticMessageBuilder>[];

  /// The context messages associated with the error.
  set contextMessages(List<DiagnosticMessageBuilder> value) {
    this._contextMessages = value;
  }

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
      {List<DiagnosticMessageBuilder> contextMessages,
      String correction,
      int length,
      String message,
      int offset,
      String uniqueName})
      : _contextMessages = contextMessages,
        _correction = correction,
        _length = length,
        _message = message,
        _offset = offset,
        _uniqueName = uniqueName;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _contextMessages?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
    signature.addString(this._uniqueName ?? '');
    signature.addString(this._message ?? '');
    signature.addString(this._correction ?? '');
    if (this._contextMessages == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._contextMessages.length);
      for (var x in this._contextMessages) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_contextMessages;
    fb.Offset offset_correction;
    fb.Offset offset_message;
    fb.Offset offset_uniqueName;
    if (!(_contextMessages == null || _contextMessages.isEmpty)) {
      offset_contextMessages = fbBuilder
          .writeList(_contextMessages.map((b) => b.finish(fbBuilder)).toList());
    }
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
    if (offset_contextMessages != null) {
      fbBuilder.addOffset(5, offset_contextMessages);
    }
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
      _AnalysisDriverUnitErrorImpl(bc, offset);
}

class _AnalysisDriverUnitErrorImpl extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnitErrorImpl(this._bc, this._bcOffset);

  List<idl.DiagnosticMessage> _contextMessages;
  String _correction;
  int _length;
  String _message;
  int _offset;
  String _uniqueName;

  @override
  List<idl.DiagnosticMessage> get contextMessages {
    _contextMessages ??=
        const fb.ListReader<idl.DiagnosticMessage>(_DiagnosticMessageReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.DiagnosticMessage>[]);
    return _contextMessages;
  }

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
    if (contextMessages.isNotEmpty) {
      _result["contextMessages"] =
          contextMessages.map((_value) => _value.toJson()).toList();
    }
    if (correction != '') {
      _result["correction"] = correction;
    }
    if (length != 0) {
      _result["length"] = length;
    }
    if (message != '') {
      _result["message"] = message;
    }
    if (offset != 0) {
      _result["offset"] = offset;
    }
    if (uniqueName != '') {
      _result["uniqueName"] = uniqueName;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "contextMessages": contextMessages,
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
    fb.Builder fbBuilder = fb.Builder();
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
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverUnitIndexReader().read(rootRef, 0);
}

class _AnalysisDriverUnitIndexReader
    extends fb.TableReader<_AnalysisDriverUnitIndexImpl> {
  const _AnalysisDriverUnitIndexReader();

  @override
  _AnalysisDriverUnitIndexImpl createObject(fb.BufferContext bc, int offset) =>
      _AnalysisDriverUnitIndexImpl(bc, offset);
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
            _IndexSyntheticElementKindReader())
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
    _strings ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _strings;
  }

  @override
  List<idl.AnalysisDriverSubtype> get subtypes {
    _subtypes ??= const fb.ListReader<idl.AnalysisDriverSubtype>(
            _AnalysisDriverSubtypeReader())
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
    _usedElementKinds ??=
        const fb.ListReader<idl.IndexRelationKind>(_IndexRelationKindReader())
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
    _usedNameKinds ??=
        const fb.ListReader<idl.IndexRelationKind>(_IndexRelationKindReader())
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
    if (elementKinds.isNotEmpty) {
      _result["elementKinds"] = elementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    }
    if (elementNameClassMemberIds.isNotEmpty) {
      _result["elementNameClassMemberIds"] = elementNameClassMemberIds;
    }
    if (elementNameParameterIds.isNotEmpty) {
      _result["elementNameParameterIds"] = elementNameParameterIds;
    }
    if (elementNameUnitMemberIds.isNotEmpty) {
      _result["elementNameUnitMemberIds"] = elementNameUnitMemberIds;
    }
    if (elementUnits.isNotEmpty) {
      _result["elementUnits"] = elementUnits;
    }
    if (nullStringId != 0) {
      _result["nullStringId"] = nullStringId;
    }
    if (strings.isNotEmpty) {
      _result["strings"] = strings;
    }
    if (subtypes.isNotEmpty) {
      _result["subtypes"] = subtypes.map((_value) => _value.toJson()).toList();
    }
    if (supertypes.isNotEmpty) {
      _result["supertypes"] = supertypes;
    }
    if (unitLibraryUris.isNotEmpty) {
      _result["unitLibraryUris"] = unitLibraryUris;
    }
    if (unitUnitUris.isNotEmpty) {
      _result["unitUnitUris"] = unitUnitUris;
    }
    if (usedElementIsQualifiedFlags.isNotEmpty) {
      _result["usedElementIsQualifiedFlags"] = usedElementIsQualifiedFlags;
    }
    if (usedElementKinds.isNotEmpty) {
      _result["usedElementKinds"] = usedElementKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    }
    if (usedElementLengths.isNotEmpty) {
      _result["usedElementLengths"] = usedElementLengths;
    }
    if (usedElementOffsets.isNotEmpty) {
      _result["usedElementOffsets"] = usedElementOffsets;
    }
    if (usedElements.isNotEmpty) {
      _result["usedElements"] = usedElements;
    }
    if (usedNameIsQualifiedFlags.isNotEmpty) {
      _result["usedNameIsQualifiedFlags"] = usedNameIsQualifiedFlags;
    }
    if (usedNameKinds.isNotEmpty) {
      _result["usedNameKinds"] = usedNameKinds
          .map((_value) => _value.toString().split('.')[1])
          .toList();
    }
    if (usedNameOffsets.isNotEmpty) {
      _result["usedNameOffsets"] = usedNameOffsets;
    }
    if (usedNames.isNotEmpty) {
      _result["usedNames"] = usedNames;
    }
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
      UnlinkedUnit2Builder unit2})
      : _definedClassMemberNames = definedClassMemberNames,
        _definedTopLevelNames = definedTopLevelNames,
        _referencedNames = referencedNames,
        _subtypedNames = subtypedNames,
        _unit2 = unit2;

  /// Flush [informative] data recursively.
  void flushInformative() {
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
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADUU");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_definedClassMemberNames;
    fb.Offset offset_definedTopLevelNames;
    fb.Offset offset_referencedNames;
    fb.Offset offset_subtypedNames;
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
    if (_unit2 != null) {
      offset_unit2 = _unit2.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_definedClassMemberNames != null) {
      fbBuilder.addOffset(2, offset_definedClassMemberNames);
    }
    if (offset_definedTopLevelNames != null) {
      fbBuilder.addOffset(1, offset_definedTopLevelNames);
    }
    if (offset_referencedNames != null) {
      fbBuilder.addOffset(0, offset_referencedNames);
    }
    if (offset_subtypedNames != null) {
      fbBuilder.addOffset(3, offset_subtypedNames);
    }
    if (offset_unit2 != null) {
      fbBuilder.addOffset(4, offset_unit2);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverUnlinkedUnit readAnalysisDriverUnlinkedUnit(
    List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverUnlinkedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverUnlinkedUnitReader
    extends fb.TableReader<_AnalysisDriverUnlinkedUnitImpl> {
  const _AnalysisDriverUnlinkedUnitReader();

  @override
  _AnalysisDriverUnlinkedUnitImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverUnlinkedUnitImpl(bc, offset);
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
  idl.UnlinkedUnit2 _unit2;

  @override
  List<String> get definedClassMemberNames {
    _definedClassMemberNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _definedClassMemberNames;
  }

  @override
  List<String> get definedTopLevelNames {
    _definedTopLevelNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _definedTopLevelNames;
  }

  @override
  List<String> get referencedNames {
    _referencedNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _referencedNames;
  }

  @override
  List<String> get subtypedNames {
    _subtypedNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 3, const <String>[]);
    return _subtypedNames;
  }

  @override
  idl.UnlinkedUnit2 get unit2 {
    _unit2 ??= const _UnlinkedUnit2Reader().vTableGet(_bc, _bcOffset, 4, null);
    return _unit2;
  }
}

abstract class _AnalysisDriverUnlinkedUnitMixin
    implements idl.AnalysisDriverUnlinkedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (definedClassMemberNames.isNotEmpty) {
      _result["definedClassMemberNames"] = definedClassMemberNames;
    }
    if (definedTopLevelNames.isNotEmpty) {
      _result["definedTopLevelNames"] = definedTopLevelNames;
    }
    if (referencedNames.isNotEmpty) {
      _result["referencedNames"] = referencedNames;
    }
    if (subtypedNames.isNotEmpty) {
      _result["subtypedNames"] = subtypedNames;
    }
    if (unit2 != null) {
      _result["unit2"] = unit2.toJson();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "definedClassMemberNames": definedClassMemberNames,
        "definedTopLevelNames": definedTopLevelNames,
        "referencedNames": referencedNames,
        "subtypedNames": subtypedNames,
        "unit2": unit2,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableDeclarationBuilder extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  List<AvailableDeclarationBuilder> _children;
  int _codeLength;
  int _codeOffset;
  String _defaultArgumentListString;
  List<int> _defaultArgumentListTextRanges;
  String _docComplete;
  String _docSummary;
  int _fieldMask;
  bool _isAbstract;
  bool _isConst;
  bool _isDeprecated;
  bool _isFinal;
  bool _isStatic;
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
  int get codeLength => _codeLength ??= 0;

  set codeLength(int value) {
    assert(value == null || value >= 0);
    this._codeLength = value;
  }

  @override
  int get codeOffset => _codeOffset ??= 0;

  set codeOffset(int value) {
    assert(value == null || value >= 0);
    this._codeOffset = value;
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
  bool get isStatic => _isStatic ??= false;

  set isStatic(bool value) {
    this._isStatic = value;
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
      int codeLength,
      int codeOffset,
      String defaultArgumentListString,
      List<int> defaultArgumentListTextRanges,
      String docComplete,
      String docSummary,
      int fieldMask,
      bool isAbstract,
      bool isConst,
      bool isDeprecated,
      bool isFinal,
      bool isStatic,
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
        _codeLength = codeLength,
        _codeOffset = codeOffset,
        _defaultArgumentListString = defaultArgumentListString,
        _defaultArgumentListTextRanges = defaultArgumentListTextRanges,
        _docComplete = docComplete,
        _docSummary = docSummary,
        _fieldMask = fieldMask,
        _isAbstract = isAbstract,
        _isConst = isConst,
        _isDeprecated = isDeprecated,
        _isFinal = isFinal,
        _isStatic = isStatic,
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
    signature.addInt(this._codeLength ?? 0);
    signature.addInt(this._codeOffset ?? 0);
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
    signature.addBool(this._isStatic == true);
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
    if (_codeLength != null && _codeLength != 0) {
      fbBuilder.addUint32(1, _codeLength);
    }
    if (_codeOffset != null && _codeOffset != 0) {
      fbBuilder.addUint32(2, _codeOffset);
    }
    if (offset_defaultArgumentListString != null) {
      fbBuilder.addOffset(3, offset_defaultArgumentListString);
    }
    if (offset_defaultArgumentListTextRanges != null) {
      fbBuilder.addOffset(4, offset_defaultArgumentListTextRanges);
    }
    if (offset_docComplete != null) {
      fbBuilder.addOffset(5, offset_docComplete);
    }
    if (offset_docSummary != null) {
      fbBuilder.addOffset(6, offset_docSummary);
    }
    if (_fieldMask != null && _fieldMask != 0) {
      fbBuilder.addUint32(7, _fieldMask);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(8, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(9, true);
    }
    if (_isDeprecated == true) {
      fbBuilder.addBool(10, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(11, true);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(12, true);
    }
    if (_kind != null && _kind != idl.AvailableDeclarationKind.CLASS) {
      fbBuilder.addUint8(13, _kind.index);
    }
    if (_locationOffset != null && _locationOffset != 0) {
      fbBuilder.addUint32(14, _locationOffset);
    }
    if (_locationStartColumn != null && _locationStartColumn != 0) {
      fbBuilder.addUint32(15, _locationStartColumn);
    }
    if (_locationStartLine != null && _locationStartLine != 0) {
      fbBuilder.addUint32(16, _locationStartLine);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(17, offset_name);
    }
    if (offset_parameterNames != null) {
      fbBuilder.addOffset(18, offset_parameterNames);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(19, offset_parameters);
    }
    if (offset_parameterTypes != null) {
      fbBuilder.addOffset(20, offset_parameterTypes);
    }
    if (offset_relevanceTags != null) {
      fbBuilder.addOffset(21, offset_relevanceTags);
    }
    if (_requiredParameterCount != null && _requiredParameterCount != 0) {
      fbBuilder.addUint32(22, _requiredParameterCount);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(23, offset_returnType);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(24, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableDeclarationReader
    extends fb.TableReader<_AvailableDeclarationImpl> {
  const _AvailableDeclarationReader();

  @override
  _AvailableDeclarationImpl createObject(fb.BufferContext bc, int offset) =>
      _AvailableDeclarationImpl(bc, offset);
}

class _AvailableDeclarationImpl extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableDeclarationImpl(this._bc, this._bcOffset);

  List<idl.AvailableDeclaration> _children;
  int _codeLength;
  int _codeOffset;
  String _defaultArgumentListString;
  List<int> _defaultArgumentListTextRanges;
  String _docComplete;
  String _docSummary;
  int _fieldMask;
  bool _isAbstract;
  bool _isConst;
  bool _isDeprecated;
  bool _isFinal;
  bool _isStatic;
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
            _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
    return _children;
  }

  @override
  int get codeLength {
    _codeLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _codeLength;
  }

  @override
  int get codeOffset {
    _codeOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _codeOffset;
  }

  @override
  String get defaultArgumentListString {
    _defaultArgumentListString ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _defaultArgumentListString;
  }

  @override
  List<int> get defaultArgumentListTextRanges {
    _defaultArgumentListTextRanges ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 4, const <int>[]);
    return _defaultArgumentListTextRanges;
  }

  @override
  String get docComplete {
    _docComplete ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 5, '');
    return _docComplete;
  }

  @override
  String get docSummary {
    _docSummary ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 6, '');
    return _docSummary;
  }

  @override
  int get fieldMask {
    _fieldMask ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 7, 0);
    return _fieldMask;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 8, false);
    return _isAbstract;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 9, false);
    return _isConst;
  }

  @override
  bool get isDeprecated {
    _isDeprecated ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 10, false);
    return _isDeprecated;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 11, false);
    return _isFinal;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 12, false);
    return _isStatic;
  }

  @override
  idl.AvailableDeclarationKind get kind {
    _kind ??= const _AvailableDeclarationKindReader()
        .vTableGet(_bc, _bcOffset, 13, idl.AvailableDeclarationKind.CLASS);
    return _kind;
  }

  @override
  int get locationOffset {
    _locationOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 14, 0);
    return _locationOffset;
  }

  @override
  int get locationStartColumn {
    _locationStartColumn ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _locationStartColumn;
  }

  @override
  int get locationStartLine {
    _locationStartLine ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _locationStartLine;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 17, '');
    return _name;
  }

  @override
  List<String> get parameterNames {
    _parameterNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 18, const <String>[]);
    return _parameterNames;
  }

  @override
  String get parameters {
    _parameters ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 19, '');
    return _parameters;
  }

  @override
  List<String> get parameterTypes {
    _parameterTypes ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 20, const <String>[]);
    return _parameterTypes;
  }

  @override
  List<String> get relevanceTags {
    _relevanceTags ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 21, const <String>[]);
    return _relevanceTags;
  }

  @override
  int get requiredParameterCount {
    _requiredParameterCount ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 22, 0);
    return _requiredParameterCount;
  }

  @override
  String get returnType {
    _returnType ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 23, '');
    return _returnType;
  }

  @override
  String get typeParameters {
    _typeParameters ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 24, '');
    return _typeParameters;
  }
}

abstract class _AvailableDeclarationMixin implements idl.AvailableDeclaration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (children.isNotEmpty) {
      _result["children"] = children.map((_value) => _value.toJson()).toList();
    }
    if (codeLength != 0) {
      _result["codeLength"] = codeLength;
    }
    if (codeOffset != 0) {
      _result["codeOffset"] = codeOffset;
    }
    if (defaultArgumentListString != '') {
      _result["defaultArgumentListString"] = defaultArgumentListString;
    }
    if (defaultArgumentListTextRanges.isNotEmpty) {
      _result["defaultArgumentListTextRanges"] = defaultArgumentListTextRanges;
    }
    if (docComplete != '') {
      _result["docComplete"] = docComplete;
    }
    if (docSummary != '') {
      _result["docSummary"] = docSummary;
    }
    if (fieldMask != 0) {
      _result["fieldMask"] = fieldMask;
    }
    if (isAbstract != false) {
      _result["isAbstract"] = isAbstract;
    }
    if (isConst != false) {
      _result["isConst"] = isConst;
    }
    if (isDeprecated != false) {
      _result["isDeprecated"] = isDeprecated;
    }
    if (isFinal != false) {
      _result["isFinal"] = isFinal;
    }
    if (isStatic != false) {
      _result["isStatic"] = isStatic;
    }
    if (kind != idl.AvailableDeclarationKind.CLASS) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    if (locationOffset != 0) {
      _result["locationOffset"] = locationOffset;
    }
    if (locationStartColumn != 0) {
      _result["locationStartColumn"] = locationStartColumn;
    }
    if (locationStartLine != 0) {
      _result["locationStartLine"] = locationStartLine;
    }
    if (name != '') {
      _result["name"] = name;
    }
    if (parameterNames.isNotEmpty) {
      _result["parameterNames"] = parameterNames;
    }
    if (parameters != '') {
      _result["parameters"] = parameters;
    }
    if (parameterTypes.isNotEmpty) {
      _result["parameterTypes"] = parameterTypes;
    }
    if (relevanceTags.isNotEmpty) {
      _result["relevanceTags"] = relevanceTags;
    }
    if (requiredParameterCount != 0) {
      _result["requiredParameterCount"] = requiredParameterCount;
    }
    if (returnType != '') {
      _result["returnType"] = returnType;
    }
    if (typeParameters != '') {
      _result["typeParameters"] = typeParameters;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "children": children,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "defaultArgumentListString": defaultArgumentListString,
        "defaultArgumentListTextRanges": defaultArgumentListTextRanges,
        "docComplete": docComplete,
        "docSummary": docSummary,
        "fieldMask": fieldMask,
        "isAbstract": isAbstract,
        "isConst": isConst,
        "isDeprecated": isDeprecated,
        "isFinal": isFinal,
        "isStatic": isStatic,
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
  List<int> _lineStarts;
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

  AvailableFileBuilder(
      {List<AvailableDeclarationBuilder> declarations,
      DirectiveInfoBuilder directiveInfo,
      List<AvailableFileExportBuilder> exports,
      bool isLibrary,
      bool isLibraryDeprecated,
      List<int> lineStarts,
      List<String> parts})
      : _declarations = declarations,
        _directiveInfo = directiveInfo,
        _exports = exports,
        _isLibrary = isLibrary,
        _isLibraryDeprecated = isLibraryDeprecated,
        _lineStarts = lineStarts,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _declarations?.forEach((b) => b.flushInformative());
    _directiveInfo?.flushInformative();
    _exports?.forEach((b) => b.flushInformative());
    _lineStarts = null;
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
    signature.addBool(this._directiveInfo != null);
    this._directiveInfo?.collectApiSignature(signature);
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
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UICF");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_declarations;
    fb.Offset offset_directiveInfo;
    fb.Offset offset_exports;
    fb.Offset offset_lineStarts;
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
    if (!(_lineStarts == null || _lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(_lineStarts);
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
      fbBuilder.addOffset(1, offset_directiveInfo);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(2, offset_exports);
    }
    if (_isLibrary == true) {
      fbBuilder.addBool(3, true);
    }
    if (_isLibraryDeprecated == true) {
      fbBuilder.addBool(4, true);
    }
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(5, offset_lineStarts);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(6, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.AvailableFile readAvailableFile(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AvailableFileReader().read(rootRef, 0);
}

class _AvailableFileReader extends fb.TableReader<_AvailableFileImpl> {
  const _AvailableFileReader();

  @override
  _AvailableFileImpl createObject(fb.BufferContext bc, int offset) =>
      _AvailableFileImpl(bc, offset);
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
  List<int> _lineStarts;
  List<String> _parts;

  @override
  List<idl.AvailableDeclaration> get declarations {
    _declarations ??= const fb.ListReader<idl.AvailableDeclaration>(
            _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
    return _declarations;
  }

  @override
  idl.DirectiveInfo get directiveInfo {
    _directiveInfo ??=
        const _DirectiveInfoReader().vTableGet(_bc, _bcOffset, 1, null);
    return _directiveInfo;
  }

  @override
  List<idl.AvailableFileExport> get exports {
    _exports ??= const fb.ListReader<idl.AvailableFileExport>(
            _AvailableFileExportReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.AvailableFileExport>[]);
    return _exports;
  }

  @override
  bool get isLibrary {
    _isLibrary ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isLibrary;
  }

  @override
  bool get isLibraryDeprecated {
    _isLibraryDeprecated ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 4, false);
    return _isLibraryDeprecated;
  }

  @override
  List<int> get lineStarts {
    _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _lineStarts;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 6, const <String>[]);
    return _parts;
  }
}

abstract class _AvailableFileMixin implements idl.AvailableFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (declarations.isNotEmpty) {
      _result["declarations"] =
          declarations.map((_value) => _value.toJson()).toList();
    }
    if (directiveInfo != null) {
      _result["directiveInfo"] = directiveInfo.toJson();
    }
    if (exports.isNotEmpty) {
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    }
    if (isLibrary != false) {
      _result["isLibrary"] = isLibrary;
    }
    if (isLibraryDeprecated != false) {
      _result["isLibraryDeprecated"] = isLibraryDeprecated;
    }
    if (lineStarts.isNotEmpty) {
      _result["lineStarts"] = lineStarts;
    }
    if (parts.isNotEmpty) {
      _result["parts"] = parts;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "declarations": declarations,
        "directiveInfo": directiveInfo,
        "exports": exports,
        "isLibrary": isLibrary,
        "isLibraryDeprecated": isLibraryDeprecated,
        "lineStarts": lineStarts,
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
      _AvailableFileExportImpl(bc, offset);
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
            _AvailableFileExportCombinatorReader())
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
    if (combinators.isNotEmpty) {
      _result["combinators"] =
          combinators.map((_value) => _value.toJson()).toList();
    }
    if (uri != '') {
      _result["uri"] = uri;
    }
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
      _AvailableFileExportCombinatorImpl(bc, offset);
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
    _hides ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _hides;
  }

  @override
  List<String> get shows {
    _shows ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _shows;
  }
}

abstract class _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (hides.isNotEmpty) {
      _result["hides"] = hides;
    }
    if (shows.isNotEmpty) {
      _result["shows"] = shows;
    }
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

class CiderLinkedLibraryCycleBuilder extends Object
    with _CiderLinkedLibraryCycleMixin
    implements idl.CiderLinkedLibraryCycle {
  LinkedNodeBundleBuilder _bundle;
  List<int> _signature;

  @override
  LinkedNodeBundleBuilder get bundle => _bundle;

  set bundle(LinkedNodeBundleBuilder value) {
    this._bundle = value;
  }

  @override
  List<int> get signature => _signature ??= <int>[];

  /// The hash signature for this linked cycle. It depends of API signatures
  /// of all files in the cycle, and on the signatures of the transitive
  /// closure of the cycle dependencies.
  set signature(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._signature = value;
  }

  CiderLinkedLibraryCycleBuilder(
      {LinkedNodeBundleBuilder bundle, List<int> signature})
      : _bundle = bundle,
        _signature = signature;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _bundle?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._signature == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._signature.length);
      for (var x in this._signature) {
        signature.addInt(x);
      }
    }
    signature.addBool(this._bundle != null);
    this._bundle?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "CLNB");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_bundle;
    fb.Offset offset_signature;
    if (_bundle != null) {
      offset_bundle = _bundle.finish(fbBuilder);
    }
    if (!(_signature == null || _signature.isEmpty)) {
      offset_signature = fbBuilder.writeListUint32(_signature);
    }
    fbBuilder.startTable();
    if (offset_bundle != null) {
      fbBuilder.addOffset(1, offset_bundle);
    }
    if (offset_signature != null) {
      fbBuilder.addOffset(0, offset_signature);
    }
    return fbBuilder.endTable();
  }
}

idl.CiderLinkedLibraryCycle readCiderLinkedLibraryCycle(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _CiderLinkedLibraryCycleReader().read(rootRef, 0);
}

class _CiderLinkedLibraryCycleReader
    extends fb.TableReader<_CiderLinkedLibraryCycleImpl> {
  const _CiderLinkedLibraryCycleReader();

  @override
  _CiderLinkedLibraryCycleImpl createObject(fb.BufferContext bc, int offset) =>
      _CiderLinkedLibraryCycleImpl(bc, offset);
}

class _CiderLinkedLibraryCycleImpl extends Object
    with _CiderLinkedLibraryCycleMixin
    implements idl.CiderLinkedLibraryCycle {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _CiderLinkedLibraryCycleImpl(this._bc, this._bcOffset);

  idl.LinkedNodeBundle _bundle;
  List<int> _signature;

  @override
  idl.LinkedNodeBundle get bundle {
    _bundle ??=
        const _LinkedNodeBundleReader().vTableGet(_bc, _bcOffset, 1, null);
    return _bundle;
  }

  @override
  List<int> get signature {
    _signature ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _signature;
  }
}

abstract class _CiderLinkedLibraryCycleMixin
    implements idl.CiderLinkedLibraryCycle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (bundle != null) {
      _result["bundle"] = bundle.toJson();
    }
    if (signature.isNotEmpty) {
      _result["signature"] = signature;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "bundle": bundle,
        "signature": signature,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class CiderUnitErrorsBuilder extends Object
    with _CiderUnitErrorsMixin
    implements idl.CiderUnitErrors {
  List<AnalysisDriverUnitErrorBuilder> _errors;
  List<int> _signature;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  @override
  List<int> get signature => _signature ??= <int>[];

  /// The hash signature of this data.
  set signature(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._signature = value;
  }

  CiderUnitErrorsBuilder(
      {List<AnalysisDriverUnitErrorBuilder> errors, List<int> signature})
      : _errors = errors,
        _signature = signature;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._signature == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._signature.length);
      for (var x in this._signature) {
        signature.addInt(x);
      }
    }
    if (this._errors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errors.length);
      for (var x in this._errors) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "CUEr");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_errors;
    fb.Offset offset_signature;
    if (!(_errors == null || _errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(_errors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_signature == null || _signature.isEmpty)) {
      offset_signature = fbBuilder.writeListUint32(_signature);
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(1, offset_errors);
    }
    if (offset_signature != null) {
      fbBuilder.addOffset(0, offset_signature);
    }
    return fbBuilder.endTable();
  }
}

idl.CiderUnitErrors readCiderUnitErrors(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _CiderUnitErrorsReader().read(rootRef, 0);
}

class _CiderUnitErrorsReader extends fb.TableReader<_CiderUnitErrorsImpl> {
  const _CiderUnitErrorsReader();

  @override
  _CiderUnitErrorsImpl createObject(fb.BufferContext bc, int offset) =>
      _CiderUnitErrorsImpl(bc, offset);
}

class _CiderUnitErrorsImpl extends Object
    with _CiderUnitErrorsMixin
    implements idl.CiderUnitErrors {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _CiderUnitErrorsImpl(this._bc, this._bcOffset);

  List<idl.AnalysisDriverUnitError> _errors;
  List<int> _signature;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
            _AnalysisDriverUnitErrorReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.AnalysisDriverUnitError>[]);
    return _errors;
  }

  @override
  List<int> get signature {
    _signature ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _signature;
  }
}

abstract class _CiderUnitErrorsMixin implements idl.CiderUnitErrors {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (errors.isNotEmpty) {
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    }
    if (signature.isNotEmpty) {
      _result["signature"] = signature;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "errors": errors,
        "signature": signature,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class CiderUnlinkedUnitBuilder extends Object
    with _CiderUnlinkedUnitMixin
    implements idl.CiderUnlinkedUnit {
  List<int> _contentDigest;
  UnlinkedUnit2Builder _unlinkedUnit;

  @override
  List<int> get contentDigest => _contentDigest ??= <int>[];

  /// The hash signature of the contents of the file.
  set contentDigest(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._contentDigest = value;
  }

  @override
  UnlinkedUnit2Builder get unlinkedUnit => _unlinkedUnit;

  /// Unlinked summary of the compilation unit.
  set unlinkedUnit(UnlinkedUnit2Builder value) {
    this._unlinkedUnit = value;
  }

  CiderUnlinkedUnitBuilder(
      {List<int> contentDigest, UnlinkedUnit2Builder unlinkedUnit})
      : _contentDigest = contentDigest,
        _unlinkedUnit = unlinkedUnit;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _unlinkedUnit?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._contentDigest == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._contentDigest.length);
      for (var x in this._contentDigest) {
        signature.addInt(x);
      }
    }
    signature.addBool(this._unlinkedUnit != null);
    this._unlinkedUnit?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "CUUN");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_contentDigest;
    fb.Offset offset_unlinkedUnit;
    if (!(_contentDigest == null || _contentDigest.isEmpty)) {
      offset_contentDigest = fbBuilder.writeListUint32(_contentDigest);
    }
    if (_unlinkedUnit != null) {
      offset_unlinkedUnit = _unlinkedUnit.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_contentDigest != null) {
      fbBuilder.addOffset(0, offset_contentDigest);
    }
    if (offset_unlinkedUnit != null) {
      fbBuilder.addOffset(1, offset_unlinkedUnit);
    }
    return fbBuilder.endTable();
  }
}

idl.CiderUnlinkedUnit readCiderUnlinkedUnit(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _CiderUnlinkedUnitReader().read(rootRef, 0);
}

class _CiderUnlinkedUnitReader extends fb.TableReader<_CiderUnlinkedUnitImpl> {
  const _CiderUnlinkedUnitReader();

  @override
  _CiderUnlinkedUnitImpl createObject(fb.BufferContext bc, int offset) =>
      _CiderUnlinkedUnitImpl(bc, offset);
}

class _CiderUnlinkedUnitImpl extends Object
    with _CiderUnlinkedUnitMixin
    implements idl.CiderUnlinkedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _CiderUnlinkedUnitImpl(this._bc, this._bcOffset);

  List<int> _contentDigest;
  idl.UnlinkedUnit2 _unlinkedUnit;

  @override
  List<int> get contentDigest {
    _contentDigest ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _contentDigest;
  }

  @override
  idl.UnlinkedUnit2 get unlinkedUnit {
    _unlinkedUnit ??=
        const _UnlinkedUnit2Reader().vTableGet(_bc, _bcOffset, 1, null);
    return _unlinkedUnit;
  }
}

abstract class _CiderUnlinkedUnitMixin implements idl.CiderUnlinkedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (contentDigest.isNotEmpty) {
      _result["contentDigest"] = contentDigest;
    }
    if (unlinkedUnit != null) {
      _result["unlinkedUnit"] = unlinkedUnit.toJson();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "contentDigest": contentDigest,
        "unlinkedUnit": unlinkedUnit,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class DiagnosticMessageBuilder extends Object
    with _DiagnosticMessageMixin
    implements idl.DiagnosticMessage {
  String _filePath;
  int _length;
  String _message;
  int _offset;

  @override
  String get filePath => _filePath ??= '';

  /// The absolute and normalized path of the file associated with this message.
  set filePath(String value) {
    this._filePath = value;
  }

  @override
  int get length => _length ??= 0;

  /// The length of the source range associated with this message.
  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  /// The text of the message.
  set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  DiagnosticMessageBuilder(
      {String filePath, int length, String message, int offset})
      : _filePath = filePath,
        _length = length,
        _message = message,
        _offset = offset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._filePath ?? '');
    signature.addInt(this._length ?? 0);
    signature.addString(this._message ?? '');
    signature.addInt(this._offset ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_filePath;
    fb.Offset offset_message;
    if (_filePath != null) {
      offset_filePath = fbBuilder.writeString(_filePath);
    }
    if (_message != null) {
      offset_message = fbBuilder.writeString(_message);
    }
    fbBuilder.startTable();
    if (offset_filePath != null) {
      fbBuilder.addOffset(0, offset_filePath);
    }
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(1, _length);
    }
    if (offset_message != null) {
      fbBuilder.addOffset(2, offset_message);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(3, _offset);
    }
    return fbBuilder.endTable();
  }
}

class _DiagnosticMessageReader extends fb.TableReader<_DiagnosticMessageImpl> {
  const _DiagnosticMessageReader();

  @override
  _DiagnosticMessageImpl createObject(fb.BufferContext bc, int offset) =>
      _DiagnosticMessageImpl(bc, offset);
}

class _DiagnosticMessageImpl extends Object
    with _DiagnosticMessageMixin
    implements idl.DiagnosticMessage {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _DiagnosticMessageImpl(this._bc, this._bcOffset);

  String _filePath;
  int _length;
  String _message;
  int _offset;

  @override
  String get filePath {
    _filePath ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _filePath;
  }

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _length;
  }

  @override
  String get message {
    _message ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _message;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _offset;
  }
}

abstract class _DiagnosticMessageMixin implements idl.DiagnosticMessage {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (filePath != '') {
      _result["filePath"] = filePath;
    }
    if (length != 0) {
      _result["length"] = length;
    }
    if (message != '') {
      _result["message"] = message;
    }
    if (offset != 0) {
      _result["offset"] = offset;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "filePath": filePath,
        "length": length,
        "message": message,
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
      _DirectiveInfoImpl(bc, offset);
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
    _templateNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _templateNames;
  }

  @override
  List<String> get templateValues {
    _templateValues ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _templateValues;
  }
}

abstract class _DirectiveInfoMixin implements idl.DirectiveInfo {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (templateNames.isNotEmpty) {
      _result["templateNames"] = templateNames;
    }
    if (templateValues.isNotEmpty) {
      _result["templateValues"] = templateValues;
    }
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

class LinkedLanguageVersionBuilder extends Object
    with _LinkedLanguageVersionMixin
    implements idl.LinkedLanguageVersion {
  int _major;
  int _minor;

  @override
  int get major => _major ??= 0;

  set major(int value) {
    assert(value == null || value >= 0);
    this._major = value;
  }

  @override
  int get minor => _minor ??= 0;

  set minor(int value) {
    assert(value == null || value >= 0);
    this._minor = value;
  }

  LinkedLanguageVersionBuilder({int major, int minor})
      : _major = major,
        _minor = minor;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._major ?? 0);
    signature.addInt(this._minor ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fbBuilder.startTable();
    if (_major != null && _major != 0) {
      fbBuilder.addUint32(0, _major);
    }
    if (_minor != null && _minor != 0) {
      fbBuilder.addUint32(1, _minor);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedLanguageVersionReader
    extends fb.TableReader<_LinkedLanguageVersionImpl> {
  const _LinkedLanguageVersionReader();

  @override
  _LinkedLanguageVersionImpl createObject(fb.BufferContext bc, int offset) =>
      _LinkedLanguageVersionImpl(bc, offset);
}

class _LinkedLanguageVersionImpl extends Object
    with _LinkedLanguageVersionMixin
    implements idl.LinkedLanguageVersion {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedLanguageVersionImpl(this._bc, this._bcOffset);

  int _major;
  int _minor;

  @override
  int get major {
    _major ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _major;
  }

  @override
  int get minor {
    _minor ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _minor;
  }
}

abstract class _LinkedLanguageVersionMixin
    implements idl.LinkedLanguageVersion {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (major != 0) {
      _result["major"] = major;
    }
    if (minor != 0) {
      _result["minor"] = minor;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "major": major,
        "minor": minor,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedLibraryLanguageVersionBuilder extends Object
    with _LinkedLibraryLanguageVersionMixin
    implements idl.LinkedLibraryLanguageVersion {
  LinkedLanguageVersionBuilder _override2;
  LinkedLanguageVersionBuilder _package;

  @override
  LinkedLanguageVersionBuilder get override2 => _override2;

  set override2(LinkedLanguageVersionBuilder value) {
    this._override2 = value;
  }

  @override
  LinkedLanguageVersionBuilder get package => _package;

  set package(LinkedLanguageVersionBuilder value) {
    this._package = value;
  }

  LinkedLibraryLanguageVersionBuilder(
      {LinkedLanguageVersionBuilder override2,
      LinkedLanguageVersionBuilder package})
      : _override2 = override2,
        _package = package;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _override2?.flushInformative();
    _package?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._package != null);
    this._package?.collectApiSignature(signature);
    signature.addBool(this._override2 != null);
    this._override2?.collectApiSignature(signature);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_override2;
    fb.Offset offset_package;
    if (_override2 != null) {
      offset_override2 = _override2.finish(fbBuilder);
    }
    if (_package != null) {
      offset_package = _package.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_override2 != null) {
      fbBuilder.addOffset(1, offset_override2);
    }
    if (offset_package != null) {
      fbBuilder.addOffset(0, offset_package);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedLibraryLanguageVersionReader
    extends fb.TableReader<_LinkedLibraryLanguageVersionImpl> {
  const _LinkedLibraryLanguageVersionReader();

  @override
  _LinkedLibraryLanguageVersionImpl createObject(
          fb.BufferContext bc, int offset) =>
      _LinkedLibraryLanguageVersionImpl(bc, offset);
}

class _LinkedLibraryLanguageVersionImpl extends Object
    with _LinkedLibraryLanguageVersionMixin
    implements idl.LinkedLibraryLanguageVersion {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedLibraryLanguageVersionImpl(this._bc, this._bcOffset);

  idl.LinkedLanguageVersion _override2;
  idl.LinkedLanguageVersion _package;

  @override
  idl.LinkedLanguageVersion get override2 {
    _override2 ??=
        const _LinkedLanguageVersionReader().vTableGet(_bc, _bcOffset, 1, null);
    return _override2;
  }

  @override
  idl.LinkedLanguageVersion get package {
    _package ??=
        const _LinkedLanguageVersionReader().vTableGet(_bc, _bcOffset, 0, null);
    return _package;
  }
}

abstract class _LinkedLibraryLanguageVersionMixin
    implements idl.LinkedLibraryLanguageVersion {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (override2 != null) {
      _result["override2"] = override2.toJson();
    }
    if (package != null) {
      _result["package"] = package.toJson();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "override2": override2,
        "package": package,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedNodeBuilder extends Object
    with _LinkedNodeMixin
    implements idl.LinkedNode {
  LinkedNodeTypeBuilder _variantField_24;
  List<LinkedNodeBuilder> _variantField_2;
  List<LinkedNodeBuilder> _variantField_4;
  LinkedNodeBuilder _variantField_6;
  LinkedNodeBuilder _variantField_7;
  int _variantField_17;
  LinkedNodeBuilder _variantField_8;
  LinkedNodeTypeSubstitutionBuilder _variantField_38;
  int _variantField_15;
  idl.UnlinkedTokenType _variantField_28;
  bool _variantField_27;
  LinkedNodeBuilder _variantField_9;
  LinkedNodeBuilder _variantField_12;
  List<LinkedNodeBuilder> _variantField_5;
  LinkedNodeBuilder _variantField_13;
  List<String> _variantField_33;
  idl.LinkedNodeCommentType _variantField_29;
  List<LinkedNodeBuilder> _variantField_3;
  LinkedLibraryLanguageVersionBuilder _variantField_40;
  LinkedNodeBuilder _variantField_10;
  idl.LinkedNodeFormalParameterKind _variantField_26;
  double _variantField_21;
  LinkedNodeTypeBuilder _variantField_25;
  String _variantField_20;
  List<LinkedNodeTypeBuilder> _variantField_39;
  int _flags;
  String _variantField_1;
  int _variantField_36;
  int _variantField_16;
  String _variantField_30;
  LinkedNodeBuilder _variantField_14;
  idl.LinkedNodeKind _kind;
  bool _variantField_31;
  List<String> _variantField_34;
  String _name;
  idl.UnlinkedTokenType _variantField_35;
  TopLevelInferenceErrorBuilder _variantField_32;
  LinkedNodeTypeBuilder _variantField_23;
  LinkedNodeBuilder _variantField_11;
  String _variantField_22;
  int _variantField_19;

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
  LinkedNodeTypeBuilder get extensionOverride_extendedType {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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

  set extensionOverride_extendedType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
  List<LinkedNodeBuilder> get extensionOverride_arguments {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get formalParameterList_parameters {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get implementsClause_interfaces {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get instanceCreationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
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
  List<LinkedNodeBuilder> get typedLiteral_typeArguments {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    return _variantField_2 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get typeName_typeArguments {
    assert(kind == idl.LinkedNodeKind.typeName);
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

  set extensionOverride_arguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    _variantField_2 = value;
  }

  set formalParameterList_parameters(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_2 = value;
  }

  set implementsClause_interfaces(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    _variantField_2 = value;
  }

  set instanceCreationExpression_arguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
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

  set namespaceDirective_combinators(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_2 = value;
  }

  set onClause_superclassConstraints(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.onClause);
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

  set typedLiteral_typeArguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_2 = value;
  }

  set typeName_typeArguments(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.typeName);
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
  List<LinkedNodeBuilder> get annotatedNode_metadata {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.declaredIdentifier ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
  LinkedNodeBuilder get extensionDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
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
  LinkedNodeBuilder get indexExpression_index {
    assert(kind == idl.LinkedNodeKind.indexExpression);
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

  set extensionDeclaration_typeParameters(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
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

  set indexExpression_index(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
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
  LinkedNodeBuilder get extensionDeclaration_extendedType {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    return _variantField_7;
  }

  @override
  LinkedNodeBuilder get extensionOverride_extensionName {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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

  set extensionDeclaration_extendedType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    _variantField_7 = value;
  }

  set extensionOverride_extensionName(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
  int get genericFunctionType_id {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    return _variantField_17 ??= 0;
  }

  set annotation_element(int value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    assert(value == null || value >= 0);
    _variantField_17 = value;
  }

  set genericFunctionType_id(int value) {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    assert(value == null || value >= 0);
    _variantField_17 = value;
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
  LinkedNodeBuilder get extensionOverride_typeArguments {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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

  set extensionOverride_typeArguments(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
  LinkedNodeTypeSubstitutionBuilder get annotation_substitution {
    assert(kind == idl.LinkedNodeKind.annotation);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get assignmentExpression_substitution {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get binaryExpression_substitution {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get constructorName_substitution {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get indexExpression_substitution {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get postfixExpression_substitution {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get prefixExpression_substitution {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder
      get redirectingConstructorInvocation_substitution {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder get simpleIdentifier_substitution {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_38;
  }

  @override
  LinkedNodeTypeSubstitutionBuilder
      get superConstructorInvocation_substitution {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_38;
  }

  set annotation_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_38 = value;
  }

  set assignmentExpression_substitution(
      LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_38 = value;
  }

  set binaryExpression_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_38 = value;
  }

  set constructorName_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_38 = value;
  }

  set indexExpression_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_38 = value;
  }

  set postfixExpression_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_38 = value;
  }

  set prefixExpression_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_38 = value;
  }

  set redirectingConstructorInvocation_substitution(
      LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_38 = value;
  }

  set simpleIdentifier_substitution(LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_38 = value;
  }

  set superConstructorInvocation_substitution(
      LinkedNodeTypeSubstitutionBuilder value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_38 = value;
  }

  @override
  int get assignmentExpression_element {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get binaryExpression_element {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get constructorName_element {
    assert(kind == idl.LinkedNodeKind.constructorName);
    return _variantField_15 ??= 0;
  }

  @override
  int get emptyFunctionBody_fake {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    return _variantField_15 ??= 0;
  }

  @override
  int get emptyStatement_fake {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
    return _variantField_15 ??= 0;
  }

  @override
  int get indexExpression_element {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get nullLiteral_fake {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
    return _variantField_15 ??= 0;
  }

  @override
  int get postfixExpression_element {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get prefixExpression_element {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_15 ??= 0;
  }

  @override
  int get redirectingConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    return _variantField_15 ??= 0;
  }

  @override
  int get simpleIdentifier_element {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    return _variantField_15 ??= 0;
  }

  @override
  int get superConstructorInvocation_element {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    return _variantField_15 ??= 0;
  }

  set assignmentExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set binaryExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set constructorName_element(int value) {
    assert(kind == idl.LinkedNodeKind.constructorName);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set emptyFunctionBody_fake(int value) {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set emptyStatement_fake(int value) {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set indexExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set nullLiteral_fake(int value) {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set postfixExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set prefixExpression_element(int value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set redirectingConstructorInvocation_element(int value) {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set simpleIdentifier_element(int value) {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  set superConstructorInvocation_element(int value) {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    assert(value == null || value >= 0);
    _variantField_15 = value;
  }

  @override
  idl.UnlinkedTokenType get assignmentExpression_operator {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  @override
  idl.UnlinkedTokenType get binaryExpression_operator {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  @override
  idl.UnlinkedTokenType get postfixExpression_operator {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  @override
  idl.UnlinkedTokenType get prefixExpression_operator {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  @override
  idl.UnlinkedTokenType get propertyAccess_operator {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  @override
  idl.UnlinkedTokenType get typeParameter_variance {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    return _variantField_28 ??= idl.UnlinkedTokenType.NOTHING;
  }

  set assignmentExpression_operator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_28 = value;
  }

  set binaryExpression_operator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_28 = value;
  }

  set postfixExpression_operator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_28 = value;
  }

  set prefixExpression_operator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_28 = value;
  }

  set propertyAccess_operator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_28 = value;
  }

  set typeParameter_variance(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_28 = value;
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

  @override
  List<LinkedNodeBuilder> get classOrMixinDeclaration_members {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_5 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get extensionDeclaration_members {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
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

  set extensionDeclaration_members(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
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
  List<String> get comment_tokens {
    assert(kind == idl.LinkedNodeKind.comment);
    return _variantField_33 ??= <String>[];
  }

  set comment_tokens(List<String> value) {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_33 = value;
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
  List<LinkedNodeBuilder> get listLiteral_elements {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    return _variantField_3 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get namespaceDirective_configurations {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    return _variantField_3 ??= <LinkedNodeBuilder>[];
  }

  @override
  List<LinkedNodeBuilder> get setOrMapLiteral_elements {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
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

  set listLiteral_elements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_3 = value;
  }

  set namespaceDirective_configurations(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_3 = value;
  }

  set setOrMapLiteral_elements(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_3 = value;
  }

  set switchMember_labels(List<LinkedNodeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_3 = value;
  }

  @override
  LinkedLibraryLanguageVersionBuilder get compilationUnit_languageVersion {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_40;
  }

  /// The language version information.
  set compilationUnit_languageVersion(
      LinkedLibraryLanguageVersionBuilder value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_40 = value;
  }

  @override
  LinkedNodeBuilder get constructorDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_10;
  }

  set constructorDeclaration_returnType(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
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
    assert(kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
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
    assert(kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
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
  String get extensionDeclaration_refName {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    return _variantField_20 ??= '';
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

  set extensionDeclaration_refName(String value) {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    _variantField_20 = value;
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
  List<LinkedNodeTypeBuilder> get extensionOverride_typeArgumentTypes {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    return _variantField_39 ??= <LinkedNodeTypeBuilder>[];
  }

  set extensionOverride_typeArgumentTypes(List<LinkedNodeTypeBuilder> value) {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    _variantField_39 = value;
  }

  @override
  int get flags => _flags ??= 0;

  set flags(int value) {
    assert(value == null || value >= 0);
    this._flags = value;
  }

  @override
  String get importDirective_prefix {
    assert(kind == idl.LinkedNodeKind.importDirective);
    return _variantField_1 ??= '';
  }

  set importDirective_prefix(String value) {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_1 = value;
  }

  @override
  int get informativeId {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    return _variantField_36 ??= 0;
  }

  set informativeId(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    assert(value == null || value >= 0);
    _variantField_36 = value;
  }

  @override
  int get integerLiteral_value {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    return _variantField_16 ??= 0;
  }

  set integerLiteral_value(int value) {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    assert(value == null || value >= 0);
    _variantField_16 = value;
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

  set uriBasedDirective_uri(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_14 = value;
  }

  @override
  idl.LinkedNodeKind get kind => _kind ??= idl.LinkedNodeKind.adjacentStrings;

  set kind(idl.LinkedNodeKind value) {
    this._kind = value;
  }

  @override
  bool get methodDeclaration_hasOperatorEqualWithParameterTypeFromObject {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
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

  set methodDeclaration_hasOperatorEqualWithParameterTypeFromObject(
      bool value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
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
  List<String> get mixinDeclaration_superInvokedNames {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    return _variantField_34 ??= <String>[];
  }

  @override
  List<String> get names {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.symbolLiteral);
    return _variantField_34 ??= <String>[];
  }

  set mixinDeclaration_superInvokedNames(List<String> value) {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_34 = value;
  }

  set names(List<String> value) {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.symbolLiteral);
    _variantField_34 = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  idl.UnlinkedTokenType get spreadElement_spreadOperator {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    return _variantField_35 ??= idl.UnlinkedTokenType.NOTHING;
  }

  set spreadElement_spreadOperator(idl.UnlinkedTokenType value) {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    _variantField_35 = value;
  }

  @override
  TopLevelInferenceErrorBuilder get topLevelTypeInferenceError {
    assert(kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_32;
  }

  set topLevelTypeInferenceError(TopLevelInferenceErrorBuilder value) {
    assert(kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_32 = value;
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

  set typeName_type(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_23 = value;
  }

  set typeParameter_defaultType(LinkedNodeTypeBuilder value) {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_23 = value;
  }

  @override
  LinkedNodeBuilder get unused11 {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    return _variantField_11;
  }

  set unused11(LinkedNodeBuilder value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_11 = value;
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
  int get uriBasedDirective_uriElement {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    return _variantField_19 ??= 0;
  }

  set uriBasedDirective_uriElement(int value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    assert(value == null || value >= 0);
    _variantField_19 = value;
  }

  LinkedNodeBuilder.adjacentStrings({
    List<LinkedNodeBuilder> adjacentStrings_strings,
  })  : _kind = idl.LinkedNodeKind.adjacentStrings,
        _variantField_2 = adjacentStrings_strings;

  LinkedNodeBuilder.annotation({
    LinkedNodeBuilder annotation_arguments,
    LinkedNodeBuilder annotation_constructorName,
    int annotation_element,
    LinkedNodeBuilder annotation_name,
    LinkedNodeTypeSubstitutionBuilder annotation_substitution,
  })  : _kind = idl.LinkedNodeKind.annotation,
        _variantField_6 = annotation_arguments,
        _variantField_7 = annotation_constructorName,
        _variantField_17 = annotation_element,
        _variantField_8 = annotation_name,
        _variantField_38 = annotation_substitution;

  LinkedNodeBuilder.argumentList({
    List<LinkedNodeBuilder> argumentList_arguments,
  })  : _kind = idl.LinkedNodeKind.argumentList,
        _variantField_2 = argumentList_arguments;

  LinkedNodeBuilder.asExpression({
    LinkedNodeBuilder asExpression_expression,
    LinkedNodeBuilder asExpression_type,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.asExpression,
        _variantField_6 = asExpression_expression,
        _variantField_7 = asExpression_type,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.assertInitializer({
    LinkedNodeBuilder assertInitializer_condition,
    LinkedNodeBuilder assertInitializer_message,
  })  : _kind = idl.LinkedNodeKind.assertInitializer,
        _variantField_6 = assertInitializer_condition,
        _variantField_7 = assertInitializer_message;

  LinkedNodeBuilder.assertStatement({
    LinkedNodeBuilder assertStatement_condition,
    LinkedNodeBuilder assertStatement_message,
  })  : _kind = idl.LinkedNodeKind.assertStatement,
        _variantField_6 = assertStatement_condition,
        _variantField_7 = assertStatement_message;

  LinkedNodeBuilder.assignmentExpression({
    LinkedNodeBuilder assignmentExpression_leftHandSide,
    LinkedNodeBuilder assignmentExpression_rightHandSide,
    LinkedNodeTypeSubstitutionBuilder assignmentExpression_substitution,
    int assignmentExpression_element,
    idl.UnlinkedTokenType assignmentExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.assignmentExpression,
        _variantField_6 = assignmentExpression_leftHandSide,
        _variantField_7 = assignmentExpression_rightHandSide,
        _variantField_38 = assignmentExpression_substitution,
        _variantField_15 = assignmentExpression_element,
        _variantField_28 = assignmentExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.awaitExpression({
    LinkedNodeBuilder awaitExpression_expression,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.awaitExpression,
        _variantField_6 = awaitExpression_expression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.binaryExpression({
    LinkedNodeTypeBuilder binaryExpression_invokeType,
    LinkedNodeBuilder binaryExpression_leftOperand,
    LinkedNodeBuilder binaryExpression_rightOperand,
    LinkedNodeTypeSubstitutionBuilder binaryExpression_substitution,
    int binaryExpression_element,
    idl.UnlinkedTokenType binaryExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.binaryExpression,
        _variantField_24 = binaryExpression_invokeType,
        _variantField_6 = binaryExpression_leftOperand,
        _variantField_7 = binaryExpression_rightOperand,
        _variantField_38 = binaryExpression_substitution,
        _variantField_15 = binaryExpression_element,
        _variantField_28 = binaryExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.block({
    List<LinkedNodeBuilder> block_statements,
  })  : _kind = idl.LinkedNodeKind.block,
        _variantField_2 = block_statements;

  LinkedNodeBuilder.blockFunctionBody({
    LinkedNodeBuilder blockFunctionBody_block,
  })  : _kind = idl.LinkedNodeKind.blockFunctionBody,
        _variantField_6 = blockFunctionBody_block;

  LinkedNodeBuilder.booleanLiteral({
    bool booleanLiteral_value,
  })  : _kind = idl.LinkedNodeKind.booleanLiteral,
        _variantField_27 = booleanLiteral_value;

  LinkedNodeBuilder.breakStatement({
    LinkedNodeBuilder breakStatement_label,
  })  : _kind = idl.LinkedNodeKind.breakStatement,
        _variantField_6 = breakStatement_label;

  LinkedNodeBuilder.cascadeExpression({
    List<LinkedNodeBuilder> cascadeExpression_sections,
    LinkedNodeBuilder cascadeExpression_target,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.cascadeExpression,
        _variantField_2 = cascadeExpression_sections,
        _variantField_6 = cascadeExpression_target,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.catchClause({
    LinkedNodeBuilder catchClause_body,
    LinkedNodeBuilder catchClause_exceptionParameter,
    LinkedNodeBuilder catchClause_exceptionType,
    LinkedNodeBuilder catchClause_stackTraceParameter,
  })  : _kind = idl.LinkedNodeKind.catchClause,
        _variantField_6 = catchClause_body,
        _variantField_7 = catchClause_exceptionParameter,
        _variantField_8 = catchClause_exceptionType,
        _variantField_9 = catchClause_stackTraceParameter;

  LinkedNodeBuilder.classDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder classDeclaration_extendsClause,
    LinkedNodeBuilder classDeclaration_withClause,
    LinkedNodeBuilder classDeclaration_nativeClause,
    bool classDeclaration_isDartObject,
    LinkedNodeBuilder classOrMixinDeclaration_implementsClause,
    List<LinkedNodeBuilder> classOrMixinDeclaration_members,
    LinkedNodeBuilder classOrMixinDeclaration_typeParameters,
    int informativeId,
    bool simplyBoundable_isSimplyBounded,
    LinkedNodeBuilder unused11,
  })  : _kind = idl.LinkedNodeKind.classDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = classDeclaration_extendsClause,
        _variantField_7 = classDeclaration_withClause,
        _variantField_8 = classDeclaration_nativeClause,
        _variantField_27 = classDeclaration_isDartObject,
        _variantField_12 = classOrMixinDeclaration_implementsClause,
        _variantField_5 = classOrMixinDeclaration_members,
        _variantField_13 = classOrMixinDeclaration_typeParameters,
        _variantField_36 = informativeId,
        _variantField_31 = simplyBoundable_isSimplyBounded,
        _variantField_11 = unused11;

  LinkedNodeBuilder.classTypeAlias({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder classTypeAlias_typeParameters,
    LinkedNodeBuilder classTypeAlias_superclass,
    LinkedNodeBuilder classTypeAlias_withClause,
    LinkedNodeBuilder classTypeAlias_implementsClause,
    int informativeId,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.classTypeAlias,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = classTypeAlias_typeParameters,
        _variantField_7 = classTypeAlias_superclass,
        _variantField_8 = classTypeAlias_withClause,
        _variantField_9 = classTypeAlias_implementsClause,
        _variantField_36 = informativeId,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.comment({
    List<LinkedNodeBuilder> comment_references,
    List<String> comment_tokens,
    idl.LinkedNodeCommentType comment_type,
  })  : _kind = idl.LinkedNodeKind.comment,
        _variantField_2 = comment_references,
        _variantField_33 = comment_tokens,
        _variantField_29 = comment_type;

  LinkedNodeBuilder.commentReference({
    LinkedNodeBuilder commentReference_identifier,
  })  : _kind = idl.LinkedNodeKind.commentReference,
        _variantField_6 = commentReference_identifier;

  LinkedNodeBuilder.compilationUnit({
    List<LinkedNodeBuilder> compilationUnit_declarations,
    LinkedNodeBuilder compilationUnit_scriptTag,
    List<LinkedNodeBuilder> compilationUnit_directives,
    LinkedLibraryLanguageVersionBuilder compilationUnit_languageVersion,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.compilationUnit,
        _variantField_2 = compilationUnit_declarations,
        _variantField_6 = compilationUnit_scriptTag,
        _variantField_3 = compilationUnit_directives,
        _variantField_40 = compilationUnit_languageVersion,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.conditionalExpression({
    LinkedNodeBuilder conditionalExpression_condition,
    LinkedNodeBuilder conditionalExpression_elseExpression,
    LinkedNodeBuilder conditionalExpression_thenExpression,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.conditionalExpression,
        _variantField_6 = conditionalExpression_condition,
        _variantField_7 = conditionalExpression_elseExpression,
        _variantField_8 = conditionalExpression_thenExpression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.configuration({
    LinkedNodeBuilder configuration_name,
    LinkedNodeBuilder configuration_value,
    LinkedNodeBuilder configuration_uri,
  })  : _kind = idl.LinkedNodeKind.configuration,
        _variantField_6 = configuration_name,
        _variantField_7 = configuration_value,
        _variantField_8 = configuration_uri;

  LinkedNodeBuilder.constructorDeclaration({
    List<LinkedNodeBuilder> constructorDeclaration_initializers,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder constructorDeclaration_body,
    LinkedNodeBuilder constructorDeclaration_parameters,
    LinkedNodeBuilder constructorDeclaration_redirectedConstructor,
    LinkedNodeBuilder constructorDeclaration_returnType,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.constructorDeclaration,
        _variantField_2 = constructorDeclaration_initializers,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = constructorDeclaration_body,
        _variantField_8 = constructorDeclaration_parameters,
        _variantField_9 = constructorDeclaration_redirectedConstructor,
        _variantField_10 = constructorDeclaration_returnType,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.constructorFieldInitializer({
    LinkedNodeBuilder constructorFieldInitializer_expression,
    LinkedNodeBuilder constructorFieldInitializer_fieldName,
  })  : _kind = idl.LinkedNodeKind.constructorFieldInitializer,
        _variantField_6 = constructorFieldInitializer_expression,
        _variantField_7 = constructorFieldInitializer_fieldName;

  LinkedNodeBuilder.constructorName({
    LinkedNodeBuilder constructorName_name,
    LinkedNodeBuilder constructorName_type,
    LinkedNodeTypeSubstitutionBuilder constructorName_substitution,
    int constructorName_element,
  })  : _kind = idl.LinkedNodeKind.constructorName,
        _variantField_6 = constructorName_name,
        _variantField_7 = constructorName_type,
        _variantField_38 = constructorName_substitution,
        _variantField_15 = constructorName_element;

  LinkedNodeBuilder.continueStatement({
    LinkedNodeBuilder continueStatement_label,
  })  : _kind = idl.LinkedNodeKind.continueStatement,
        _variantField_6 = continueStatement_label;

  LinkedNodeBuilder.declaredIdentifier({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder declaredIdentifier_identifier,
    LinkedNodeBuilder declaredIdentifier_type,
  })  : _kind = idl.LinkedNodeKind.declaredIdentifier,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = declaredIdentifier_identifier,
        _variantField_7 = declaredIdentifier_type;

  LinkedNodeBuilder.defaultFormalParameter({
    LinkedNodeBuilder defaultFormalParameter_defaultValue,
    LinkedNodeBuilder defaultFormalParameter_parameter,
    idl.LinkedNodeFormalParameterKind defaultFormalParameter_kind,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.defaultFormalParameter,
        _variantField_6 = defaultFormalParameter_defaultValue,
        _variantField_7 = defaultFormalParameter_parameter,
        _variantField_26 = defaultFormalParameter_kind,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.doStatement({
    LinkedNodeBuilder doStatement_body,
    LinkedNodeBuilder doStatement_condition,
  })  : _kind = idl.LinkedNodeKind.doStatement,
        _variantField_6 = doStatement_body,
        _variantField_7 = doStatement_condition;

  LinkedNodeBuilder.dottedName({
    List<LinkedNodeBuilder> dottedName_components,
  })  : _kind = idl.LinkedNodeKind.dottedName,
        _variantField_2 = dottedName_components;

  LinkedNodeBuilder.doubleLiteral({
    double doubleLiteral_value,
  })  : _kind = idl.LinkedNodeKind.doubleLiteral,
        _variantField_21 = doubleLiteral_value;

  LinkedNodeBuilder.emptyFunctionBody({
    int emptyFunctionBody_fake,
  })  : _kind = idl.LinkedNodeKind.emptyFunctionBody,
        _variantField_15 = emptyFunctionBody_fake;

  LinkedNodeBuilder.emptyStatement({
    int emptyStatement_fake,
  })  : _kind = idl.LinkedNodeKind.emptyStatement,
        _variantField_15 = emptyStatement_fake;

  LinkedNodeBuilder.enumConstantDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.enumConstantDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.enumDeclaration({
    List<LinkedNodeBuilder> enumDeclaration_constants,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.enumDeclaration,
        _variantField_2 = enumDeclaration_constants,
        _variantField_4 = annotatedNode_metadata,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.exportDirective({
    List<LinkedNodeBuilder> namespaceDirective_combinators,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    List<LinkedNodeBuilder> namespaceDirective_configurations,
    String namespaceDirective_selectedUri,
    int informativeId,
    LinkedNodeBuilder uriBasedDirective_uri,
    String uriBasedDirective_uriContent,
    int uriBasedDirective_uriElement,
  })  : _kind = idl.LinkedNodeKind.exportDirective,
        _variantField_2 = namespaceDirective_combinators,
        _variantField_4 = annotatedNode_metadata,
        _variantField_3 = namespaceDirective_configurations,
        _variantField_20 = namespaceDirective_selectedUri,
        _variantField_36 = informativeId,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_22 = uriBasedDirective_uriContent,
        _variantField_19 = uriBasedDirective_uriElement;

  LinkedNodeBuilder.expressionFunctionBody({
    LinkedNodeBuilder expressionFunctionBody_expression,
  })  : _kind = idl.LinkedNodeKind.expressionFunctionBody,
        _variantField_6 = expressionFunctionBody_expression;

  LinkedNodeBuilder.expressionStatement({
    LinkedNodeBuilder expressionStatement_expression,
  })  : _kind = idl.LinkedNodeKind.expressionStatement,
        _variantField_6 = expressionStatement_expression;

  LinkedNodeBuilder.extendsClause({
    LinkedNodeBuilder extendsClause_superclass,
  })  : _kind = idl.LinkedNodeKind.extendsClause,
        _variantField_6 = extendsClause_superclass;

  LinkedNodeBuilder.extensionDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder extensionDeclaration_typeParameters,
    LinkedNodeBuilder extensionDeclaration_extendedType,
    List<LinkedNodeBuilder> extensionDeclaration_members,
    String extensionDeclaration_refName,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.extensionDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = extensionDeclaration_typeParameters,
        _variantField_7 = extensionDeclaration_extendedType,
        _variantField_5 = extensionDeclaration_members,
        _variantField_20 = extensionDeclaration_refName,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.extensionOverride({
    LinkedNodeTypeBuilder extensionOverride_extendedType,
    List<LinkedNodeBuilder> extensionOverride_arguments,
    LinkedNodeBuilder extensionOverride_extensionName,
    LinkedNodeBuilder extensionOverride_typeArguments,
    List<LinkedNodeTypeBuilder> extensionOverride_typeArgumentTypes,
  })  : _kind = idl.LinkedNodeKind.extensionOverride,
        _variantField_24 = extensionOverride_extendedType,
        _variantField_2 = extensionOverride_arguments,
        _variantField_7 = extensionOverride_extensionName,
        _variantField_8 = extensionOverride_typeArguments,
        _variantField_39 = extensionOverride_typeArgumentTypes;

  LinkedNodeBuilder.fieldDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder fieldDeclaration_fields,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.fieldDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = fieldDeclaration_fields,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.fieldFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder fieldFormalParameter_type,
    LinkedNodeBuilder fieldFormalParameter_typeParameters,
    LinkedNodeBuilder fieldFormalParameter_formalParameters,
    bool inheritsCovariant,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.fieldFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = fieldFormalParameter_type,
        _variantField_7 = fieldFormalParameter_typeParameters,
        _variantField_8 = fieldFormalParameter_formalParameters,
        _variantField_27 = inheritsCovariant,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.forEachPartsWithDeclaration({
    LinkedNodeBuilder forEachParts_iterable,
    LinkedNodeBuilder forEachPartsWithDeclaration_loopVariable,
  })  : _kind = idl.LinkedNodeKind.forEachPartsWithDeclaration,
        _variantField_6 = forEachParts_iterable,
        _variantField_7 = forEachPartsWithDeclaration_loopVariable;

  LinkedNodeBuilder.forEachPartsWithIdentifier({
    LinkedNodeBuilder forEachParts_iterable,
    LinkedNodeBuilder forEachPartsWithIdentifier_identifier,
  })  : _kind = idl.LinkedNodeKind.forEachPartsWithIdentifier,
        _variantField_6 = forEachParts_iterable,
        _variantField_7 = forEachPartsWithIdentifier_identifier;

  LinkedNodeBuilder.forElement({
    LinkedNodeBuilder forMixin_forLoopParts,
    LinkedNodeBuilder forElement_body,
  })  : _kind = idl.LinkedNodeKind.forElement,
        _variantField_6 = forMixin_forLoopParts,
        _variantField_7 = forElement_body;

  LinkedNodeBuilder.forPartsWithDeclarations({
    LinkedNodeBuilder forParts_condition,
    LinkedNodeBuilder forPartsWithDeclarations_variables,
    List<LinkedNodeBuilder> forParts_updaters,
  })  : _kind = idl.LinkedNodeKind.forPartsWithDeclarations,
        _variantField_6 = forParts_condition,
        _variantField_7 = forPartsWithDeclarations_variables,
        _variantField_5 = forParts_updaters;

  LinkedNodeBuilder.forPartsWithExpression({
    LinkedNodeBuilder forParts_condition,
    LinkedNodeBuilder forPartsWithExpression_initialization,
    List<LinkedNodeBuilder> forParts_updaters,
  })  : _kind = idl.LinkedNodeKind.forPartsWithExpression,
        _variantField_6 = forParts_condition,
        _variantField_7 = forPartsWithExpression_initialization,
        _variantField_5 = forParts_updaters;

  LinkedNodeBuilder.forStatement({
    LinkedNodeBuilder forMixin_forLoopParts,
    LinkedNodeBuilder forStatement_body,
  })  : _kind = idl.LinkedNodeKind.forStatement,
        _variantField_6 = forMixin_forLoopParts,
        _variantField_7 = forStatement_body;

  LinkedNodeBuilder.formalParameterList({
    List<LinkedNodeBuilder> formalParameterList_parameters,
  })  : _kind = idl.LinkedNodeKind.formalParameterList,
        _variantField_2 = formalParameterList_parameters;

  LinkedNodeBuilder.functionDeclaration({
    LinkedNodeTypeBuilder actualReturnType,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder functionDeclaration_functionExpression,
    LinkedNodeBuilder functionDeclaration_returnType,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.functionDeclaration,
        _variantField_24 = actualReturnType,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = functionDeclaration_functionExpression,
        _variantField_7 = functionDeclaration_returnType,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.functionDeclarationStatement({
    LinkedNodeBuilder functionDeclarationStatement_functionDeclaration,
  })  : _kind = idl.LinkedNodeKind.functionDeclarationStatement,
        _variantField_6 = functionDeclarationStatement_functionDeclaration;

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

  LinkedNodeBuilder.functionTypeAlias({
    LinkedNodeTypeBuilder actualReturnType,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder functionTypeAlias_formalParameters,
    LinkedNodeBuilder functionTypeAlias_returnType,
    LinkedNodeBuilder functionTypeAlias_typeParameters,
    bool typeAlias_hasSelfReference,
    int informativeId,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.functionTypeAlias,
        _variantField_24 = actualReturnType,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = functionTypeAlias_formalParameters,
        _variantField_7 = functionTypeAlias_returnType,
        _variantField_8 = functionTypeAlias_typeParameters,
        _variantField_27 = typeAlias_hasSelfReference,
        _variantField_36 = informativeId,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.functionTypedFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder functionTypedFormalParameter_formalParameters,
    LinkedNodeBuilder functionTypedFormalParameter_returnType,
    LinkedNodeBuilder functionTypedFormalParameter_typeParameters,
    bool inheritsCovariant,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.functionTypedFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = functionTypedFormalParameter_formalParameters,
        _variantField_7 = functionTypedFormalParameter_returnType,
        _variantField_8 = functionTypedFormalParameter_typeParameters,
        _variantField_27 = inheritsCovariant,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.genericFunctionType({
    LinkedNodeTypeBuilder actualReturnType,
    LinkedNodeBuilder genericFunctionType_typeParameters,
    LinkedNodeBuilder genericFunctionType_returnType,
    int genericFunctionType_id,
    LinkedNodeBuilder genericFunctionType_formalParameters,
    LinkedNodeTypeBuilder genericFunctionType_type,
  })  : _kind = idl.LinkedNodeKind.genericFunctionType,
        _variantField_24 = actualReturnType,
        _variantField_6 = genericFunctionType_typeParameters,
        _variantField_7 = genericFunctionType_returnType,
        _variantField_17 = genericFunctionType_id,
        _variantField_8 = genericFunctionType_formalParameters,
        _variantField_25 = genericFunctionType_type;

  LinkedNodeBuilder.genericTypeAlias({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder genericTypeAlias_typeParameters,
    LinkedNodeBuilder genericTypeAlias_functionType,
    bool typeAlias_hasSelfReference,
    int informativeId,
    bool simplyBoundable_isSimplyBounded,
  })  : _kind = idl.LinkedNodeKind.genericTypeAlias,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = genericTypeAlias_typeParameters,
        _variantField_7 = genericTypeAlias_functionType,
        _variantField_27 = typeAlias_hasSelfReference,
        _variantField_36 = informativeId,
        _variantField_31 = simplyBoundable_isSimplyBounded;

  LinkedNodeBuilder.hideCombinator({
    int informativeId,
    List<String> names,
  })  : _kind = idl.LinkedNodeKind.hideCombinator,
        _variantField_36 = informativeId,
        _variantField_34 = names;

  LinkedNodeBuilder.ifElement({
    LinkedNodeBuilder ifMixin_condition,
    LinkedNodeBuilder ifElement_thenElement,
    LinkedNodeBuilder ifElement_elseElement,
  })  : _kind = idl.LinkedNodeKind.ifElement,
        _variantField_6 = ifMixin_condition,
        _variantField_8 = ifElement_thenElement,
        _variantField_9 = ifElement_elseElement;

  LinkedNodeBuilder.ifStatement({
    LinkedNodeBuilder ifMixin_condition,
    LinkedNodeBuilder ifStatement_elseStatement,
    LinkedNodeBuilder ifStatement_thenStatement,
  })  : _kind = idl.LinkedNodeKind.ifStatement,
        _variantField_6 = ifMixin_condition,
        _variantField_7 = ifStatement_elseStatement,
        _variantField_8 = ifStatement_thenStatement;

  LinkedNodeBuilder.implementsClause({
    List<LinkedNodeBuilder> implementsClause_interfaces,
  })  : _kind = idl.LinkedNodeKind.implementsClause,
        _variantField_2 = implementsClause_interfaces;

  LinkedNodeBuilder.importDirective({
    List<LinkedNodeBuilder> namespaceDirective_combinators,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    List<LinkedNodeBuilder> namespaceDirective_configurations,
    String namespaceDirective_selectedUri,
    String importDirective_prefix,
    int informativeId,
    LinkedNodeBuilder uriBasedDirective_uri,
    String uriBasedDirective_uriContent,
    int uriBasedDirective_uriElement,
  })  : _kind = idl.LinkedNodeKind.importDirective,
        _variantField_2 = namespaceDirective_combinators,
        _variantField_4 = annotatedNode_metadata,
        _variantField_3 = namespaceDirective_configurations,
        _variantField_20 = namespaceDirective_selectedUri,
        _variantField_1 = importDirective_prefix,
        _variantField_36 = informativeId,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_22 = uriBasedDirective_uriContent,
        _variantField_19 = uriBasedDirective_uriElement;

  LinkedNodeBuilder.indexExpression({
    LinkedNodeBuilder indexExpression_index,
    LinkedNodeBuilder indexExpression_target,
    LinkedNodeTypeSubstitutionBuilder indexExpression_substitution,
    int indexExpression_element,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.indexExpression,
        _variantField_6 = indexExpression_index,
        _variantField_7 = indexExpression_target,
        _variantField_38 = indexExpression_substitution,
        _variantField_15 = indexExpression_element,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.instanceCreationExpression({
    List<LinkedNodeBuilder> instanceCreationExpression_arguments,
    LinkedNodeBuilder instanceCreationExpression_constructorName,
    LinkedNodeBuilder instanceCreationExpression_typeArguments,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.instanceCreationExpression,
        _variantField_2 = instanceCreationExpression_arguments,
        _variantField_7 = instanceCreationExpression_constructorName,
        _variantField_8 = instanceCreationExpression_typeArguments,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.integerLiteral({
    LinkedNodeTypeBuilder expression_type,
    int integerLiteral_value,
  })  : _kind = idl.LinkedNodeKind.integerLiteral,
        _variantField_25 = expression_type,
        _variantField_16 = integerLiteral_value;

  LinkedNodeBuilder.interpolationExpression({
    LinkedNodeBuilder interpolationExpression_expression,
  })  : _kind = idl.LinkedNodeKind.interpolationExpression,
        _variantField_6 = interpolationExpression_expression;

  LinkedNodeBuilder.interpolationString({
    String interpolationString_value,
  })  : _kind = idl.LinkedNodeKind.interpolationString,
        _variantField_30 = interpolationString_value;

  LinkedNodeBuilder.isExpression({
    LinkedNodeBuilder isExpression_expression,
    LinkedNodeBuilder isExpression_type,
  })  : _kind = idl.LinkedNodeKind.isExpression,
        _variantField_6 = isExpression_expression,
        _variantField_7 = isExpression_type;

  LinkedNodeBuilder.label({
    LinkedNodeBuilder label_label,
  })  : _kind = idl.LinkedNodeKind.label,
        _variantField_6 = label_label;

  LinkedNodeBuilder.labeledStatement({
    List<LinkedNodeBuilder> labeledStatement_labels,
    LinkedNodeBuilder labeledStatement_statement,
  })  : _kind = idl.LinkedNodeKind.labeledStatement,
        _variantField_2 = labeledStatement_labels,
        _variantField_6 = labeledStatement_statement;

  LinkedNodeBuilder.libraryDirective({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder libraryDirective_name,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.libraryDirective,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = libraryDirective_name,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.libraryIdentifier({
    List<LinkedNodeBuilder> libraryIdentifier_components,
  })  : _kind = idl.LinkedNodeKind.libraryIdentifier,
        _variantField_2 = libraryIdentifier_components;

  LinkedNodeBuilder.listLiteral({
    List<LinkedNodeBuilder> typedLiteral_typeArguments,
    List<LinkedNodeBuilder> listLiteral_elements,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.listLiteral,
        _variantField_2 = typedLiteral_typeArguments,
        _variantField_3 = listLiteral_elements,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.mapLiteralEntry({
    LinkedNodeBuilder mapLiteralEntry_key,
    LinkedNodeBuilder mapLiteralEntry_value,
  })  : _kind = idl.LinkedNodeKind.mapLiteralEntry,
        _variantField_6 = mapLiteralEntry_key,
        _variantField_7 = mapLiteralEntry_value;

  LinkedNodeBuilder.methodDeclaration({
    LinkedNodeTypeBuilder actualReturnType,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder methodDeclaration_body,
    LinkedNodeBuilder methodDeclaration_formalParameters,
    LinkedNodeBuilder methodDeclaration_returnType,
    LinkedNodeBuilder methodDeclaration_typeParameters,
    int informativeId,
    bool methodDeclaration_hasOperatorEqualWithParameterTypeFromObject,
    TopLevelInferenceErrorBuilder topLevelTypeInferenceError,
  })  : _kind = idl.LinkedNodeKind.methodDeclaration,
        _variantField_24 = actualReturnType,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = methodDeclaration_body,
        _variantField_7 = methodDeclaration_formalParameters,
        _variantField_8 = methodDeclaration_returnType,
        _variantField_9 = methodDeclaration_typeParameters,
        _variantField_36 = informativeId,
        _variantField_31 =
            methodDeclaration_hasOperatorEqualWithParameterTypeFromObject,
        _variantField_32 = topLevelTypeInferenceError;

  LinkedNodeBuilder.methodInvocation({
    LinkedNodeTypeBuilder invocationExpression_invokeType,
    LinkedNodeBuilder methodInvocation_methodName,
    LinkedNodeBuilder methodInvocation_target,
    LinkedNodeBuilder invocationExpression_typeArguments,
    LinkedNodeTypeBuilder expression_type,
    LinkedNodeBuilder invocationExpression_arguments,
  })  : _kind = idl.LinkedNodeKind.methodInvocation,
        _variantField_24 = invocationExpression_invokeType,
        _variantField_6 = methodInvocation_methodName,
        _variantField_7 = methodInvocation_target,
        _variantField_12 = invocationExpression_typeArguments,
        _variantField_25 = expression_type,
        _variantField_14 = invocationExpression_arguments;

  LinkedNodeBuilder.mixinDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder mixinDeclaration_onClause,
    LinkedNodeBuilder classOrMixinDeclaration_implementsClause,
    List<LinkedNodeBuilder> classOrMixinDeclaration_members,
    LinkedNodeBuilder classOrMixinDeclaration_typeParameters,
    int informativeId,
    bool simplyBoundable_isSimplyBounded,
    List<String> mixinDeclaration_superInvokedNames,
  })  : _kind = idl.LinkedNodeKind.mixinDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = mixinDeclaration_onClause,
        _variantField_12 = classOrMixinDeclaration_implementsClause,
        _variantField_5 = classOrMixinDeclaration_members,
        _variantField_13 = classOrMixinDeclaration_typeParameters,
        _variantField_36 = informativeId,
        _variantField_31 = simplyBoundable_isSimplyBounded,
        _variantField_34 = mixinDeclaration_superInvokedNames;

  LinkedNodeBuilder.namedExpression({
    LinkedNodeBuilder namedExpression_expression,
    LinkedNodeBuilder namedExpression_name,
  })  : _kind = idl.LinkedNodeKind.namedExpression,
        _variantField_6 = namedExpression_expression,
        _variantField_7 = namedExpression_name;

  LinkedNodeBuilder.nativeClause({
    LinkedNodeBuilder nativeClause_name,
  })  : _kind = idl.LinkedNodeKind.nativeClause,
        _variantField_6 = nativeClause_name;

  LinkedNodeBuilder.nativeFunctionBody({
    LinkedNodeBuilder nativeFunctionBody_stringLiteral,
  })  : _kind = idl.LinkedNodeKind.nativeFunctionBody,
        _variantField_6 = nativeFunctionBody_stringLiteral;

  LinkedNodeBuilder.nullLiteral({
    int nullLiteral_fake,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.nullLiteral,
        _variantField_15 = nullLiteral_fake,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.onClause({
    List<LinkedNodeBuilder> onClause_superclassConstraints,
  })  : _kind = idl.LinkedNodeKind.onClause,
        _variantField_2 = onClause_superclassConstraints;

  LinkedNodeBuilder.parenthesizedExpression({
    LinkedNodeBuilder parenthesizedExpression_expression,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.parenthesizedExpression,
        _variantField_6 = parenthesizedExpression_expression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.partDirective({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    int informativeId,
    LinkedNodeBuilder uriBasedDirective_uri,
    String uriBasedDirective_uriContent,
    int uriBasedDirective_uriElement,
  })  : _kind = idl.LinkedNodeKind.partDirective,
        _variantField_4 = annotatedNode_metadata,
        _variantField_36 = informativeId,
        _variantField_14 = uriBasedDirective_uri,
        _variantField_22 = uriBasedDirective_uriContent,
        _variantField_19 = uriBasedDirective_uriElement;

  LinkedNodeBuilder.partOfDirective({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder partOfDirective_libraryName,
    LinkedNodeBuilder partOfDirective_uri,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.partOfDirective,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = partOfDirective_libraryName,
        _variantField_7 = partOfDirective_uri,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.postfixExpression({
    LinkedNodeBuilder postfixExpression_operand,
    LinkedNodeTypeSubstitutionBuilder postfixExpression_substitution,
    int postfixExpression_element,
    idl.UnlinkedTokenType postfixExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.postfixExpression,
        _variantField_6 = postfixExpression_operand,
        _variantField_38 = postfixExpression_substitution,
        _variantField_15 = postfixExpression_element,
        _variantField_28 = postfixExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.prefixExpression({
    LinkedNodeBuilder prefixExpression_operand,
    LinkedNodeTypeSubstitutionBuilder prefixExpression_substitution,
    int prefixExpression_element,
    idl.UnlinkedTokenType prefixExpression_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.prefixExpression,
        _variantField_6 = prefixExpression_operand,
        _variantField_38 = prefixExpression_substitution,
        _variantField_15 = prefixExpression_element,
        _variantField_28 = prefixExpression_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.prefixedIdentifier({
    LinkedNodeBuilder prefixedIdentifier_identifier,
    LinkedNodeBuilder prefixedIdentifier_prefix,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.prefixedIdentifier,
        _variantField_6 = prefixedIdentifier_identifier,
        _variantField_7 = prefixedIdentifier_prefix,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.propertyAccess({
    LinkedNodeBuilder propertyAccess_propertyName,
    LinkedNodeBuilder propertyAccess_target,
    idl.UnlinkedTokenType propertyAccess_operator,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.propertyAccess,
        _variantField_6 = propertyAccess_propertyName,
        _variantField_7 = propertyAccess_target,
        _variantField_28 = propertyAccess_operator,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.redirectingConstructorInvocation({
    LinkedNodeBuilder redirectingConstructorInvocation_arguments,
    LinkedNodeBuilder redirectingConstructorInvocation_constructorName,
    LinkedNodeTypeSubstitutionBuilder
        redirectingConstructorInvocation_substitution,
    int redirectingConstructorInvocation_element,
  })  : _kind = idl.LinkedNodeKind.redirectingConstructorInvocation,
        _variantField_6 = redirectingConstructorInvocation_arguments,
        _variantField_7 = redirectingConstructorInvocation_constructorName,
        _variantField_38 = redirectingConstructorInvocation_substitution,
        _variantField_15 = redirectingConstructorInvocation_element;

  LinkedNodeBuilder.rethrowExpression({
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.rethrowExpression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.returnStatement({
    LinkedNodeBuilder returnStatement_expression,
  })  : _kind = idl.LinkedNodeKind.returnStatement,
        _variantField_6 = returnStatement_expression;

  LinkedNodeBuilder.setOrMapLiteral({
    List<LinkedNodeBuilder> typedLiteral_typeArguments,
    List<LinkedNodeBuilder> setOrMapLiteral_elements,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.setOrMapLiteral,
        _variantField_2 = typedLiteral_typeArguments,
        _variantField_3 = setOrMapLiteral_elements,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.showCombinator({
    int informativeId,
    List<String> names,
  })  : _kind = idl.LinkedNodeKind.showCombinator,
        _variantField_36 = informativeId,
        _variantField_34 = names;

  LinkedNodeBuilder.simpleFormalParameter({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> normalFormalParameter_metadata,
    LinkedNodeBuilder simpleFormalParameter_type,
    bool inheritsCovariant,
    int informativeId,
    TopLevelInferenceErrorBuilder topLevelTypeInferenceError,
  })  : _kind = idl.LinkedNodeKind.simpleFormalParameter,
        _variantField_24 = actualType,
        _variantField_4 = normalFormalParameter_metadata,
        _variantField_6 = simpleFormalParameter_type,
        _variantField_27 = inheritsCovariant,
        _variantField_36 = informativeId,
        _variantField_32 = topLevelTypeInferenceError;

  LinkedNodeBuilder.simpleIdentifier({
    LinkedNodeTypeSubstitutionBuilder simpleIdentifier_substitution,
    int simpleIdentifier_element,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.simpleIdentifier,
        _variantField_38 = simpleIdentifier_substitution,
        _variantField_15 = simpleIdentifier_element,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.simpleStringLiteral({
    String simpleStringLiteral_value,
  })  : _kind = idl.LinkedNodeKind.simpleStringLiteral,
        _variantField_20 = simpleStringLiteral_value;

  LinkedNodeBuilder.spreadElement({
    LinkedNodeBuilder spreadElement_expression,
    idl.UnlinkedTokenType spreadElement_spreadOperator,
  })  : _kind = idl.LinkedNodeKind.spreadElement,
        _variantField_6 = spreadElement_expression,
        _variantField_35 = spreadElement_spreadOperator;

  LinkedNodeBuilder.stringInterpolation({
    List<LinkedNodeBuilder> stringInterpolation_elements,
  })  : _kind = idl.LinkedNodeKind.stringInterpolation,
        _variantField_2 = stringInterpolation_elements;

  LinkedNodeBuilder.superConstructorInvocation({
    LinkedNodeBuilder superConstructorInvocation_arguments,
    LinkedNodeBuilder superConstructorInvocation_constructorName,
    LinkedNodeTypeSubstitutionBuilder superConstructorInvocation_substitution,
    int superConstructorInvocation_element,
  })  : _kind = idl.LinkedNodeKind.superConstructorInvocation,
        _variantField_6 = superConstructorInvocation_arguments,
        _variantField_7 = superConstructorInvocation_constructorName,
        _variantField_38 = superConstructorInvocation_substitution,
        _variantField_15 = superConstructorInvocation_element;

  LinkedNodeBuilder.superExpression({
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.superExpression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.switchCase({
    List<LinkedNodeBuilder> switchMember_statements,
    LinkedNodeBuilder switchCase_expression,
    List<LinkedNodeBuilder> switchMember_labels,
  })  : _kind = idl.LinkedNodeKind.switchCase,
        _variantField_4 = switchMember_statements,
        _variantField_6 = switchCase_expression,
        _variantField_3 = switchMember_labels;

  LinkedNodeBuilder.switchDefault({
    List<LinkedNodeBuilder> switchMember_statements,
    List<LinkedNodeBuilder> switchMember_labels,
  })  : _kind = idl.LinkedNodeKind.switchDefault,
        _variantField_4 = switchMember_statements,
        _variantField_3 = switchMember_labels;

  LinkedNodeBuilder.switchStatement({
    List<LinkedNodeBuilder> switchStatement_members,
    LinkedNodeBuilder switchStatement_expression,
  })  : _kind = idl.LinkedNodeKind.switchStatement,
        _variantField_2 = switchStatement_members,
        _variantField_7 = switchStatement_expression;

  LinkedNodeBuilder.symbolLiteral({
    LinkedNodeTypeBuilder expression_type,
    List<String> names,
  })  : _kind = idl.LinkedNodeKind.symbolLiteral,
        _variantField_25 = expression_type,
        _variantField_34 = names;

  LinkedNodeBuilder.thisExpression({
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.thisExpression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.throwExpression({
    LinkedNodeBuilder throwExpression_expression,
    LinkedNodeTypeBuilder expression_type,
  })  : _kind = idl.LinkedNodeKind.throwExpression,
        _variantField_6 = throwExpression_expression,
        _variantField_25 = expression_type;

  LinkedNodeBuilder.topLevelVariableDeclaration({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder topLevelVariableDeclaration_variableList,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.topLevelVariableDeclaration,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = topLevelVariableDeclaration_variableList,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.tryStatement({
    List<LinkedNodeBuilder> tryStatement_catchClauses,
    LinkedNodeBuilder tryStatement_body,
    LinkedNodeBuilder tryStatement_finallyBlock,
  })  : _kind = idl.LinkedNodeKind.tryStatement,
        _variantField_2 = tryStatement_catchClauses,
        _variantField_6 = tryStatement_body,
        _variantField_7 = tryStatement_finallyBlock;

  LinkedNodeBuilder.typeArgumentList({
    List<LinkedNodeBuilder> typeArgumentList_arguments,
  })  : _kind = idl.LinkedNodeKind.typeArgumentList,
        _variantField_2 = typeArgumentList_arguments;

  LinkedNodeBuilder.typeName({
    List<LinkedNodeBuilder> typeName_typeArguments,
    LinkedNodeBuilder typeName_name,
    LinkedNodeTypeBuilder typeName_type,
  })  : _kind = idl.LinkedNodeKind.typeName,
        _variantField_2 = typeName_typeArguments,
        _variantField_6 = typeName_name,
        _variantField_23 = typeName_type;

  LinkedNodeBuilder.typeParameter({
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder typeParameter_bound,
    idl.UnlinkedTokenType typeParameter_variance,
    int informativeId,
    LinkedNodeTypeBuilder typeParameter_defaultType,
  })  : _kind = idl.LinkedNodeKind.typeParameter,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = typeParameter_bound,
        _variantField_28 = typeParameter_variance,
        _variantField_36 = informativeId,
        _variantField_23 = typeParameter_defaultType;

  LinkedNodeBuilder.typeParameterList({
    List<LinkedNodeBuilder> typeParameterList_typeParameters,
  })  : _kind = idl.LinkedNodeKind.typeParameterList,
        _variantField_2 = typeParameterList_typeParameters;

  LinkedNodeBuilder.variableDeclaration({
    LinkedNodeTypeBuilder actualType,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder variableDeclaration_initializer,
    bool inheritsCovariant,
    int informativeId,
    TopLevelInferenceErrorBuilder topLevelTypeInferenceError,
  })  : _kind = idl.LinkedNodeKind.variableDeclaration,
        _variantField_24 = actualType,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = variableDeclaration_initializer,
        _variantField_27 = inheritsCovariant,
        _variantField_36 = informativeId,
        _variantField_32 = topLevelTypeInferenceError;

  LinkedNodeBuilder.variableDeclarationList({
    List<LinkedNodeBuilder> variableDeclarationList_variables,
    List<LinkedNodeBuilder> annotatedNode_metadata,
    LinkedNodeBuilder variableDeclarationList_type,
    int informativeId,
  })  : _kind = idl.LinkedNodeKind.variableDeclarationList,
        _variantField_2 = variableDeclarationList_variables,
        _variantField_4 = annotatedNode_metadata,
        _variantField_6 = variableDeclarationList_type,
        _variantField_36 = informativeId;

  LinkedNodeBuilder.variableDeclarationStatement({
    LinkedNodeBuilder variableDeclarationStatement_variables,
  })  : _kind = idl.LinkedNodeKind.variableDeclarationStatement,
        _variantField_6 = variableDeclarationStatement_variables;

  LinkedNodeBuilder.whileStatement({
    LinkedNodeBuilder whileStatement_body,
    LinkedNodeBuilder whileStatement_condition,
  })  : _kind = idl.LinkedNodeKind.whileStatement,
        _variantField_6 = whileStatement_body,
        _variantField_7 = whileStatement_condition;

  LinkedNodeBuilder.withClause({
    List<LinkedNodeBuilder> withClause_mixinTypes,
  })  : _kind = idl.LinkedNodeKind.withClause,
        _variantField_2 = withClause_mixinTypes;

  LinkedNodeBuilder.yieldStatement({
    LinkedNodeBuilder yieldStatement_expression,
  })  : _kind = idl.LinkedNodeKind.yieldStatement,
        _variantField_6 = yieldStatement_expression;

  /// Flush [informative] data recursively.
  void flushInformative() {
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      adjacentStrings_strings?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.annotation) {
      annotation_arguments?.flushInformative();
      annotation_constructorName?.flushInformative();
      annotation_name?.flushInformative();
      annotation_substitution?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.argumentList) {
      argumentList_arguments?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.asExpression) {
      asExpression_expression?.flushInformative();
      asExpression_type?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.assertInitializer) {
      assertInitializer_condition?.flushInformative();
      assertInitializer_message?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.assertStatement) {
      assertStatement_condition?.flushInformative();
      assertStatement_message?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.assignmentExpression) {
      assignmentExpression_leftHandSide?.flushInformative();
      assignmentExpression_rightHandSide?.flushInformative();
      assignmentExpression_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.awaitExpression) {
      awaitExpression_expression?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.binaryExpression) {
      binaryExpression_invokeType?.flushInformative();
      binaryExpression_leftOperand?.flushInformative();
      binaryExpression_rightOperand?.flushInformative();
      binaryExpression_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.block) {
      block_statements?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      blockFunctionBody_block?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.booleanLiteral) {
    } else if (kind == idl.LinkedNodeKind.breakStatement) {
      breakStatement_label?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.cascadeExpression) {
      cascadeExpression_sections?.forEach((b) => b.flushInformative());
      cascadeExpression_target?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.catchClause) {
      catchClause_body?.flushInformative();
      catchClause_exceptionParameter?.flushInformative();
      catchClause_exceptionType?.flushInformative();
      catchClause_stackTraceParameter?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.classDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      classDeclaration_extendsClause?.flushInformative();
      classDeclaration_withClause?.flushInformative();
      classDeclaration_nativeClause?.flushInformative();
      classOrMixinDeclaration_implementsClause?.flushInformative();
      classOrMixinDeclaration_members?.forEach((b) => b.flushInformative());
      classOrMixinDeclaration_typeParameters?.flushInformative();
      informativeId = null;
      unused11?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.classTypeAlias) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      classTypeAlias_typeParameters?.flushInformative();
      classTypeAlias_superclass?.flushInformative();
      classTypeAlias_withClause?.flushInformative();
      classTypeAlias_implementsClause?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.comment) {
      comment_references?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.commentReference) {
      commentReference_identifier?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.compilationUnit) {
      compilationUnit_declarations?.forEach((b) => b.flushInformative());
      compilationUnit_scriptTag?.flushInformative();
      compilationUnit_directives?.forEach((b) => b.flushInformative());
      compilationUnit_languageVersion?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.conditionalExpression) {
      conditionalExpression_condition?.flushInformative();
      conditionalExpression_elseExpression?.flushInformative();
      conditionalExpression_thenExpression?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.configuration) {
      configuration_name?.flushInformative();
      configuration_value?.flushInformative();
      configuration_uri?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      constructorDeclaration_initializers?.forEach((b) => b.flushInformative());
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      constructorDeclaration_body?.flushInformative();
      constructorDeclaration_parameters?.flushInformative();
      constructorDeclaration_redirectedConstructor?.flushInformative();
      constructorDeclaration_returnType?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      constructorFieldInitializer_expression?.flushInformative();
      constructorFieldInitializer_fieldName?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.constructorName) {
      constructorName_name?.flushInformative();
      constructorName_type?.flushInformative();
      constructorName_substitution?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.continueStatement) {
      continueStatement_label?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      declaredIdentifier_identifier?.flushInformative();
      declaredIdentifier_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      defaultFormalParameter_defaultValue?.flushInformative();
      defaultFormalParameter_parameter?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.doStatement) {
      doStatement_body?.flushInformative();
      doStatement_condition?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.dottedName) {
      dottedName_components?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.doubleLiteral) {
    } else if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
    } else if (kind == idl.LinkedNodeKind.emptyStatement) {
    } else if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.enumDeclaration) {
      enumDeclaration_constants?.forEach((b) => b.flushInformative());
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.exportDirective) {
      namespaceDirective_combinators?.forEach((b) => b.flushInformative());
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      namespaceDirective_configurations?.forEach((b) => b.flushInformative());
      informativeId = null;
      uriBasedDirective_uri?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      expressionFunctionBody_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.expressionStatement) {
      expressionStatement_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.extendsClause) {
      extendsClause_superclass?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      extensionDeclaration_typeParameters?.flushInformative();
      extensionDeclaration_extendedType?.flushInformative();
      extensionDeclaration_members?.forEach((b) => b.flushInformative());
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.extensionOverride) {
      extensionOverride_extendedType?.flushInformative();
      extensionOverride_arguments?.forEach((b) => b.flushInformative());
      extensionOverride_extensionName?.flushInformative();
      extensionOverride_typeArguments?.flushInformative();
      extensionOverride_typeArgumentTypes?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      fieldDeclaration_fields?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      actualType?.flushInformative();
      normalFormalParameter_metadata?.forEach((b) => b.flushInformative());
      fieldFormalParameter_type?.flushInformative();
      fieldFormalParameter_typeParameters?.flushInformative();
      fieldFormalParameter_formalParameters?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      forEachParts_iterable?.flushInformative();
      forEachPartsWithDeclaration_loopVariable?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      forEachParts_iterable?.flushInformative();
      forEachPartsWithIdentifier_identifier?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.forElement) {
      forMixin_forLoopParts?.flushInformative();
      forElement_body?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      forParts_condition?.flushInformative();
      forPartsWithDeclarations_variables?.flushInformative();
      forParts_updaters?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      forParts_condition?.flushInformative();
      forPartsWithExpression_initialization?.flushInformative();
      forParts_updaters?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.forStatement) {
      forMixin_forLoopParts?.flushInformative();
      forStatement_body?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.formalParameterList) {
      formalParameterList_parameters?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.functionDeclaration) {
      actualReturnType?.flushInformative();
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      functionDeclaration_functionExpression?.flushInformative();
      functionDeclaration_returnType?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      functionDeclarationStatement_functionDeclaration?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.functionExpression) {
      actualReturnType?.flushInformative();
      functionExpression_body?.flushInformative();
      functionExpression_formalParameters?.flushInformative();
      functionExpression_typeParameters?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.functionExpressionInvocation) {
      invocationExpression_invokeType?.flushInformative();
      functionExpressionInvocation_function?.flushInformative();
      invocationExpression_typeArguments?.flushInformative();
      expression_type?.flushInformative();
      invocationExpression_arguments?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      actualReturnType?.flushInformative();
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      functionTypeAlias_formalParameters?.flushInformative();
      functionTypeAlias_returnType?.flushInformative();
      functionTypeAlias_typeParameters?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      actualType?.flushInformative();
      normalFormalParameter_metadata?.forEach((b) => b.flushInformative());
      functionTypedFormalParameter_formalParameters?.flushInformative();
      functionTypedFormalParameter_returnType?.flushInformative();
      functionTypedFormalParameter_typeParameters?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.genericFunctionType) {
      actualReturnType?.flushInformative();
      genericFunctionType_typeParameters?.flushInformative();
      genericFunctionType_returnType?.flushInformative();
      genericFunctionType_formalParameters?.flushInformative();
      genericFunctionType_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      genericTypeAlias_typeParameters?.flushInformative();
      genericTypeAlias_functionType?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.hideCombinator) {
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.ifElement) {
      ifMixin_condition?.flushInformative();
      ifElement_thenElement?.flushInformative();
      ifElement_elseElement?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.ifStatement) {
      ifMixin_condition?.flushInformative();
      ifStatement_elseStatement?.flushInformative();
      ifStatement_thenStatement?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.implementsClause) {
      implementsClause_interfaces?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.importDirective) {
      namespaceDirective_combinators?.forEach((b) => b.flushInformative());
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      namespaceDirective_configurations?.forEach((b) => b.flushInformative());
      informativeId = null;
      uriBasedDirective_uri?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.indexExpression) {
      indexExpression_index?.flushInformative();
      indexExpression_target?.flushInformative();
      indexExpression_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      instanceCreationExpression_arguments
          ?.forEach((b) => b.flushInformative());
      instanceCreationExpression_constructorName?.flushInformative();
      instanceCreationExpression_typeArguments?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.integerLiteral) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.interpolationExpression) {
      interpolationExpression_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.interpolationString) {
    } else if (kind == idl.LinkedNodeKind.isExpression) {
      isExpression_expression?.flushInformative();
      isExpression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.label) {
      label_label?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.labeledStatement) {
      labeledStatement_labels?.forEach((b) => b.flushInformative());
      labeledStatement_statement?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.libraryDirective) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      libraryDirective_name?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      libraryIdentifier_components?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.listLiteral) {
      typedLiteral_typeArguments?.forEach((b) => b.flushInformative());
      listLiteral_elements?.forEach((b) => b.flushInformative());
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      mapLiteralEntry_key?.flushInformative();
      mapLiteralEntry_value?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.methodDeclaration) {
      actualReturnType?.flushInformative();
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      methodDeclaration_body?.flushInformative();
      methodDeclaration_formalParameters?.flushInformative();
      methodDeclaration_returnType?.flushInformative();
      methodDeclaration_typeParameters?.flushInformative();
      informativeId = null;
      topLevelTypeInferenceError?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.methodInvocation) {
      invocationExpression_invokeType?.flushInformative();
      methodInvocation_methodName?.flushInformative();
      methodInvocation_target?.flushInformative();
      invocationExpression_typeArguments?.flushInformative();
      expression_type?.flushInformative();
      invocationExpression_arguments?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      mixinDeclaration_onClause?.flushInformative();
      classOrMixinDeclaration_implementsClause?.flushInformative();
      classOrMixinDeclaration_members?.forEach((b) => b.flushInformative());
      classOrMixinDeclaration_typeParameters?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.namedExpression) {
      namedExpression_expression?.flushInformative();
      namedExpression_name?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.nativeClause) {
      nativeClause_name?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      nativeFunctionBody_stringLiteral?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.nullLiteral) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.onClause) {
      onClause_superclassConstraints?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      parenthesizedExpression_expression?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.partDirective) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      informativeId = null;
      uriBasedDirective_uri?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.partOfDirective) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      partOfDirective_libraryName?.flushInformative();
      partOfDirective_uri?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.postfixExpression) {
      postfixExpression_operand?.flushInformative();
      postfixExpression_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.prefixExpression) {
      prefixExpression_operand?.flushInformative();
      prefixExpression_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      prefixedIdentifier_identifier?.flushInformative();
      prefixedIdentifier_prefix?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.propertyAccess) {
      propertyAccess_propertyName?.flushInformative();
      propertyAccess_target?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      redirectingConstructorInvocation_arguments?.flushInformative();
      redirectingConstructorInvocation_constructorName?.flushInformative();
      redirectingConstructorInvocation_substitution?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.rethrowExpression) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.returnStatement) {
      returnStatement_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      typedLiteral_typeArguments?.forEach((b) => b.flushInformative());
      setOrMapLiteral_elements?.forEach((b) => b.flushInformative());
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.showCombinator) {
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      actualType?.flushInformative();
      normalFormalParameter_metadata?.forEach((b) => b.flushInformative());
      simpleFormalParameter_type?.flushInformative();
      informativeId = null;
      topLevelTypeInferenceError?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      simpleIdentifier_substitution?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
    } else if (kind == idl.LinkedNodeKind.spreadElement) {
      spreadElement_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.stringInterpolation) {
      stringInterpolation_elements?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      superConstructorInvocation_arguments?.flushInformative();
      superConstructorInvocation_constructorName?.flushInformative();
      superConstructorInvocation_substitution?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.superExpression) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.switchCase) {
      switchMember_statements?.forEach((b) => b.flushInformative());
      switchCase_expression?.flushInformative();
      switchMember_labels?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.switchDefault) {
      switchMember_statements?.forEach((b) => b.flushInformative());
      switchMember_labels?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.switchStatement) {
      switchStatement_members?.forEach((b) => b.flushInformative());
      switchStatement_expression?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.symbolLiteral) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.thisExpression) {
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.throwExpression) {
      throwExpression_expression?.flushInformative();
      expression_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      topLevelVariableDeclaration_variableList?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.tryStatement) {
      tryStatement_catchClauses?.forEach((b) => b.flushInformative());
      tryStatement_body?.flushInformative();
      tryStatement_finallyBlock?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.typeArgumentList) {
      typeArgumentList_arguments?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.typeName) {
      typeName_typeArguments?.forEach((b) => b.flushInformative());
      typeName_name?.flushInformative();
      typeName_type?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.typeParameter) {
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      typeParameter_bound?.flushInformative();
      informativeId = null;
      typeParameter_defaultType?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.typeParameterList) {
      typeParameterList_typeParameters?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.variableDeclaration) {
      actualType?.flushInformative();
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      variableDeclaration_initializer?.flushInformative();
      informativeId = null;
      topLevelTypeInferenceError?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      variableDeclarationList_variables?.forEach((b) => b.flushInformative());
      annotatedNode_metadata?.forEach((b) => b.flushInformative());
      variableDeclarationList_type?.flushInformative();
      informativeId = null;
    } else if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      variableDeclarationStatement_variables?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.whileStatement) {
      whileStatement_body?.flushInformative();
      whileStatement_condition?.flushInformative();
    } else if (kind == idl.LinkedNodeKind.withClause) {
      withClause_mixinTypes?.forEach((b) => b.flushInformative());
    } else if (kind == idl.LinkedNodeKind.yieldStatement) {
      yieldStatement_expression?.flushInformative();
    }
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.adjacentStrings_strings == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.adjacentStrings_strings.length);
        for (var x in this.adjacentStrings_strings) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.annotation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.annotation_arguments != null);
      this.annotation_arguments?.collectApiSignature(signature);
      signature.addBool(this.annotation_constructorName != null);
      this.annotation_constructorName?.collectApiSignature(signature);
      signature.addBool(this.annotation_name != null);
      this.annotation_name?.collectApiSignature(signature);
      signature.addInt(this.annotation_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
      signature.addBool(this.annotation_substitution != null);
      this.annotation_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.argumentList) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.argumentList_arguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.argumentList_arguments.length);
        for (var x in this.argumentList_arguments) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.asExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.asExpression_expression != null);
      this.asExpression_expression?.collectApiSignature(signature);
      signature.addBool(this.asExpression_type != null);
      this.asExpression_type?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.assertInitializer) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.assertInitializer_condition != null);
      this.assertInitializer_condition?.collectApiSignature(signature);
      signature.addBool(this.assertInitializer_message != null);
      this.assertInitializer_message?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.assertStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.assertStatement_condition != null);
      this.assertStatement_condition?.collectApiSignature(signature);
      signature.addBool(this.assertStatement_message != null);
      this.assertStatement_message?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.assignmentExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.assignmentExpression_leftHandSide != null);
      this.assignmentExpression_leftHandSide?.collectApiSignature(signature);
      signature.addBool(this.assignmentExpression_rightHandSide != null);
      this.assignmentExpression_rightHandSide?.collectApiSignature(signature);
      signature.addInt(this.assignmentExpression_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addInt(this.assignmentExpression_operator == null
          ? 0
          : this.assignmentExpression_operator.index);
      signature.addString(this.name ?? '');
      signature.addBool(this.assignmentExpression_substitution != null);
      this.assignmentExpression_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.awaitExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.awaitExpression_expression != null);
      this.awaitExpression_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.binaryExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.binaryExpression_leftOperand != null);
      this.binaryExpression_leftOperand?.collectApiSignature(signature);
      signature.addBool(this.binaryExpression_rightOperand != null);
      this.binaryExpression_rightOperand?.collectApiSignature(signature);
      signature.addInt(this.binaryExpression_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.binaryExpression_invokeType != null);
      this.binaryExpression_invokeType?.collectApiSignature(signature);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addInt(this.binaryExpression_operator == null
          ? 0
          : this.binaryExpression_operator.index);
      signature.addString(this.name ?? '');
      signature.addBool(this.binaryExpression_substitution != null);
      this.binaryExpression_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.block) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.block_statements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.block_statements.length);
        for (var x in this.block_statements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.blockFunctionBody_block != null);
      this.blockFunctionBody_block?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.booleanLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.booleanLiteral_value == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.breakStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.breakStatement_label != null);
      this.breakStatement_label?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.cascadeExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.cascadeExpression_sections == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.cascadeExpression_sections.length);
        for (var x in this.cascadeExpression_sections) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.cascadeExpression_target != null);
      this.cascadeExpression_target?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.catchClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.catchClause_body != null);
      this.catchClause_body?.collectApiSignature(signature);
      signature.addBool(this.catchClause_exceptionParameter != null);
      this.catchClause_exceptionParameter?.collectApiSignature(signature);
      signature.addBool(this.catchClause_exceptionType != null);
      this.catchClause_exceptionType?.collectApiSignature(signature);
      signature.addBool(this.catchClause_stackTraceParameter != null);
      this.catchClause_stackTraceParameter?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.classDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.classOrMixinDeclaration_members == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.classOrMixinDeclaration_members.length);
        for (var x in this.classOrMixinDeclaration_members) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.classDeclaration_extendsClause != null);
      this.classDeclaration_extendsClause?.collectApiSignature(signature);
      signature.addBool(this.classDeclaration_withClause != null);
      this.classDeclaration_withClause?.collectApiSignature(signature);
      signature.addBool(this.classDeclaration_nativeClause != null);
      this.classDeclaration_nativeClause?.collectApiSignature(signature);
      signature.addBool(this.unused11 != null);
      this.unused11?.collectApiSignature(signature);
      signature.addBool(this.classOrMixinDeclaration_implementsClause != null);
      this
          .classOrMixinDeclaration_implementsClause
          ?.collectApiSignature(signature);
      signature.addBool(this.classOrMixinDeclaration_typeParameters != null);
      this
          .classOrMixinDeclaration_typeParameters
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.classDeclaration_isDartObject == true);
      signature.addBool(this.simplyBoundable_isSimplyBounded == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.classTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.classTypeAlias_typeParameters != null);
      this.classTypeAlias_typeParameters?.collectApiSignature(signature);
      signature.addBool(this.classTypeAlias_superclass != null);
      this.classTypeAlias_superclass?.collectApiSignature(signature);
      signature.addBool(this.classTypeAlias_withClause != null);
      this.classTypeAlias_withClause?.collectApiSignature(signature);
      signature.addBool(this.classTypeAlias_implementsClause != null);
      this.classTypeAlias_implementsClause?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.simplyBoundable_isSimplyBounded == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.comment) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.comment_references == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.comment_references.length);
        for (var x in this.comment_references) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.comment_type == null ? 0 : this.comment_type.index);
      if (this.comment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.comment_tokens.length);
        for (var x in this.comment_tokens) {
          signature.addString(x);
        }
      }
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.commentReference) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.commentReference_identifier != null);
      this.commentReference_identifier?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.compilationUnit) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.compilationUnit_declarations == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.compilationUnit_declarations.length);
        for (var x in this.compilationUnit_declarations) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.compilationUnit_directives == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.compilationUnit_directives.length);
        for (var x in this.compilationUnit_directives) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.compilationUnit_scriptTag != null);
      this.compilationUnit_scriptTag?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
      signature.addBool(this.compilationUnit_languageVersion != null);
      this.compilationUnit_languageVersion?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.conditionalExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.conditionalExpression_condition != null);
      this.conditionalExpression_condition?.collectApiSignature(signature);
      signature.addBool(this.conditionalExpression_elseExpression != null);
      this.conditionalExpression_elseExpression?.collectApiSignature(signature);
      signature.addBool(this.conditionalExpression_thenExpression != null);
      this.conditionalExpression_thenExpression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.configuration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.configuration_name != null);
      this.configuration_name?.collectApiSignature(signature);
      signature.addBool(this.configuration_value != null);
      this.configuration_value?.collectApiSignature(signature);
      signature.addBool(this.configuration_uri != null);
      this.configuration_uri?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.constructorDeclaration_initializers == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.constructorDeclaration_initializers.length);
        for (var x in this.constructorDeclaration_initializers) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.constructorDeclaration_body != null);
      this.constructorDeclaration_body?.collectApiSignature(signature);
      signature.addBool(this.constructorDeclaration_parameters != null);
      this.constructorDeclaration_parameters?.collectApiSignature(signature);
      signature
          .addBool(this.constructorDeclaration_redirectedConstructor != null);
      this
          .constructorDeclaration_redirectedConstructor
          ?.collectApiSignature(signature);
      signature.addBool(this.constructorDeclaration_returnType != null);
      this.constructorDeclaration_returnType?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.constructorFieldInitializer_expression != null);
      this
          .constructorFieldInitializer_expression
          ?.collectApiSignature(signature);
      signature.addBool(this.constructorFieldInitializer_fieldName != null);
      this
          .constructorFieldInitializer_fieldName
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.constructorName) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.constructorName_name != null);
      this.constructorName_name?.collectApiSignature(signature);
      signature.addBool(this.constructorName_type != null);
      this.constructorName_type?.collectApiSignature(signature);
      signature.addInt(this.constructorName_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
      signature.addBool(this.constructorName_substitution != null);
      this.constructorName_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.continueStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.continueStatement_label != null);
      this.continueStatement_label?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.declaredIdentifier_identifier != null);
      this.declaredIdentifier_identifier?.collectApiSignature(signature);
      signature.addBool(this.declaredIdentifier_type != null);
      this.declaredIdentifier_type?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.defaultFormalParameter_defaultValue != null);
      this.defaultFormalParameter_defaultValue?.collectApiSignature(signature);
      signature.addBool(this.defaultFormalParameter_parameter != null);
      this.defaultFormalParameter_parameter?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.defaultFormalParameter_kind == null
          ? 0
          : this.defaultFormalParameter_kind.index);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.doStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.doStatement_body != null);
      this.doStatement_body?.collectApiSignature(signature);
      signature.addBool(this.doStatement_condition != null);
      this.doStatement_condition?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.dottedName) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.dottedName_components == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.dottedName_components.length);
        for (var x in this.dottedName_components) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.doubleLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addDouble(this.doubleLiteral_value ?? 0.0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.emptyFunctionBody_fake ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.emptyStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.emptyStatement_fake ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.enumDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.enumDeclaration_constants == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.enumDeclaration_constants.length);
        for (var x in this.enumDeclaration_constants) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.exportDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.namespaceDirective_combinators == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.namespaceDirective_combinators.length);
        for (var x in this.namespaceDirective_combinators) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.namespaceDirective_configurations == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.namespaceDirective_configurations.length);
        for (var x in this.namespaceDirective_configurations) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.uriBasedDirective_uri != null);
      this.uriBasedDirective_uri?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.uriBasedDirective_uriElement ?? 0);
      signature.addString(this.namespaceDirective_selectedUri ?? '');
      signature.addString(this.uriBasedDirective_uriContent ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.expressionFunctionBody_expression != null);
      this.expressionFunctionBody_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.expressionStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.expressionStatement_expression != null);
      this.expressionStatement_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.extendsClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.extendsClause_superclass != null);
      this.extendsClause_superclass?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.extensionDeclaration_members == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.extensionDeclaration_members.length);
        for (var x in this.extensionDeclaration_members) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.extensionDeclaration_typeParameters != null);
      this.extensionDeclaration_typeParameters?.collectApiSignature(signature);
      signature.addBool(this.extensionDeclaration_extendedType != null);
      this.extensionDeclaration_extendedType?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.extensionDeclaration_refName ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.extensionOverride) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.extensionOverride_arguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.extensionOverride_arguments.length);
        for (var x in this.extensionOverride_arguments) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.extensionOverride_extensionName != null);
      this.extensionOverride_extensionName?.collectApiSignature(signature);
      signature.addBool(this.extensionOverride_typeArguments != null);
      this.extensionOverride_typeArguments?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.extensionOverride_extendedType != null);
      this.extensionOverride_extendedType?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
      if (this.extensionOverride_typeArgumentTypes == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.extensionOverride_typeArgumentTypes.length);
        for (var x in this.extensionOverride_typeArgumentTypes) {
          x?.collectApiSignature(signature);
        }
      }
    } else if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.fieldDeclaration_fields != null);
      this.fieldDeclaration_fields?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.normalFormalParameter_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.normalFormalParameter_metadata.length);
        for (var x in this.normalFormalParameter_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.fieldFormalParameter_type != null);
      this.fieldFormalParameter_type?.collectApiSignature(signature);
      signature.addBool(this.fieldFormalParameter_typeParameters != null);
      this.fieldFormalParameter_typeParameters?.collectApiSignature(signature);
      signature.addBool(this.fieldFormalParameter_formalParameters != null);
      this
          .fieldFormalParameter_formalParameters
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualType != null);
      this.actualType?.collectApiSignature(signature);
      signature.addBool(this.inheritsCovariant == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.forEachParts_iterable != null);
      this.forEachParts_iterable?.collectApiSignature(signature);
      signature.addBool(this.forEachPartsWithDeclaration_loopVariable != null);
      this
          .forEachPartsWithDeclaration_loopVariable
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.forEachParts_iterable != null);
      this.forEachParts_iterable?.collectApiSignature(signature);
      signature.addBool(this.forEachPartsWithIdentifier_identifier != null);
      this
          .forEachPartsWithIdentifier_identifier
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forElement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.forMixin_forLoopParts != null);
      this.forMixin_forLoopParts?.collectApiSignature(signature);
      signature.addBool(this.forElement_body != null);
      this.forElement_body?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.forParts_updaters == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.forParts_updaters.length);
        for (var x in this.forParts_updaters) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.forParts_condition != null);
      this.forParts_condition?.collectApiSignature(signature);
      signature.addBool(this.forPartsWithDeclarations_variables != null);
      this.forPartsWithDeclarations_variables?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.forParts_updaters == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.forParts_updaters.length);
        for (var x in this.forParts_updaters) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.forParts_condition != null);
      this.forParts_condition?.collectApiSignature(signature);
      signature.addBool(this.forPartsWithExpression_initialization != null);
      this
          .forPartsWithExpression_initialization
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.forStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.forMixin_forLoopParts != null);
      this.forMixin_forLoopParts?.collectApiSignature(signature);
      signature.addBool(this.forStatement_body != null);
      this.forStatement_body?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.formalParameterList) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.formalParameterList_parameters == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.formalParameterList_parameters.length);
        for (var x in this.formalParameterList_parameters) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.functionDeclaration_functionExpression != null);
      this
          .functionDeclaration_functionExpression
          ?.collectApiSignature(signature);
      signature.addBool(this.functionDeclaration_returnType != null);
      this.functionDeclaration_returnType?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualReturnType != null);
      this.actualReturnType?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(
          this.functionDeclarationStatement_functionDeclaration != null);
      this
          .functionDeclarationStatement_functionDeclaration
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.functionExpression_body != null);
      this.functionExpression_body?.collectApiSignature(signature);
      signature.addBool(this.functionExpression_formalParameters != null);
      this.functionExpression_formalParameters?.collectApiSignature(signature);
      signature.addBool(this.functionExpression_typeParameters != null);
      this.functionExpression_typeParameters?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualReturnType != null);
      this.actualReturnType?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionExpressionInvocation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.functionExpressionInvocation_function != null);
      this
          .functionExpressionInvocation_function
          ?.collectApiSignature(signature);
      signature.addBool(this.invocationExpression_typeArguments != null);
      this.invocationExpression_typeArguments?.collectApiSignature(signature);
      signature.addBool(this.invocationExpression_arguments != null);
      this.invocationExpression_arguments?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.invocationExpression_invokeType != null);
      this.invocationExpression_invokeType?.collectApiSignature(signature);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.functionTypeAlias_formalParameters != null);
      this.functionTypeAlias_formalParameters?.collectApiSignature(signature);
      signature.addBool(this.functionTypeAlias_returnType != null);
      this.functionTypeAlias_returnType?.collectApiSignature(signature);
      signature.addBool(this.functionTypeAlias_typeParameters != null);
      this.functionTypeAlias_typeParameters?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualReturnType != null);
      this.actualReturnType?.collectApiSignature(signature);
      signature.addBool(this.typeAlias_hasSelfReference == true);
      signature.addBool(this.simplyBoundable_isSimplyBounded == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.normalFormalParameter_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.normalFormalParameter_metadata.length);
        for (var x in this.normalFormalParameter_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature
          .addBool(this.functionTypedFormalParameter_formalParameters != null);
      this
          .functionTypedFormalParameter_formalParameters
          ?.collectApiSignature(signature);
      signature.addBool(this.functionTypedFormalParameter_returnType != null);
      this
          .functionTypedFormalParameter_returnType
          ?.collectApiSignature(signature);
      signature
          .addBool(this.functionTypedFormalParameter_typeParameters != null);
      this
          .functionTypedFormalParameter_typeParameters
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualType != null);
      this.actualType?.collectApiSignature(signature);
      signature.addBool(this.inheritsCovariant == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.genericFunctionType) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.genericFunctionType_typeParameters != null);
      this.genericFunctionType_typeParameters?.collectApiSignature(signature);
      signature.addBool(this.genericFunctionType_returnType != null);
      this.genericFunctionType_returnType?.collectApiSignature(signature);
      signature.addBool(this.genericFunctionType_formalParameters != null);
      this.genericFunctionType_formalParameters?.collectApiSignature(signature);
      signature.addInt(this.genericFunctionType_id ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualReturnType != null);
      this.actualReturnType?.collectApiSignature(signature);
      signature.addBool(this.genericFunctionType_type != null);
      this.genericFunctionType_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.genericTypeAlias_typeParameters != null);
      this.genericTypeAlias_typeParameters?.collectApiSignature(signature);
      signature.addBool(this.genericTypeAlias_functionType != null);
      this.genericTypeAlias_functionType?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.typeAlias_hasSelfReference == true);
      signature.addBool(this.simplyBoundable_isSimplyBounded == true);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.hideCombinator) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      if (this.names == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.names.length);
        for (var x in this.names) {
          signature.addString(x);
        }
      }
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.ifElement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.ifMixin_condition != null);
      this.ifMixin_condition?.collectApiSignature(signature);
      signature.addBool(this.ifElement_thenElement != null);
      this.ifElement_thenElement?.collectApiSignature(signature);
      signature.addBool(this.ifElement_elseElement != null);
      this.ifElement_elseElement?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.ifStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.ifMixin_condition != null);
      this.ifMixin_condition?.collectApiSignature(signature);
      signature.addBool(this.ifStatement_elseStatement != null);
      this.ifStatement_elseStatement?.collectApiSignature(signature);
      signature.addBool(this.ifStatement_thenStatement != null);
      this.ifStatement_thenStatement?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.implementsClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.implementsClause_interfaces == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.implementsClause_interfaces.length);
        for (var x in this.implementsClause_interfaces) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.importDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addString(this.importDirective_prefix ?? '');
      if (this.namespaceDirective_combinators == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.namespaceDirective_combinators.length);
        for (var x in this.namespaceDirective_combinators) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.namespaceDirective_configurations == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.namespaceDirective_configurations.length);
        for (var x in this.namespaceDirective_configurations) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.uriBasedDirective_uri != null);
      this.uriBasedDirective_uri?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.uriBasedDirective_uriElement ?? 0);
      signature.addString(this.namespaceDirective_selectedUri ?? '');
      signature.addString(this.uriBasedDirective_uriContent ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.indexExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.indexExpression_index != null);
      this.indexExpression_index?.collectApiSignature(signature);
      signature.addBool(this.indexExpression_target != null);
      this.indexExpression_target?.collectApiSignature(signature);
      signature.addInt(this.indexExpression_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
      signature.addBool(this.indexExpression_substitution != null);
      this.indexExpression_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.instanceCreationExpression_arguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.instanceCreationExpression_arguments.length);
        for (var x in this.instanceCreationExpression_arguments) {
          x?.collectApiSignature(signature);
        }
      }
      signature
          .addBool(this.instanceCreationExpression_constructorName != null);
      this
          .instanceCreationExpression_constructorName
          ?.collectApiSignature(signature);
      signature.addBool(this.instanceCreationExpression_typeArguments != null);
      this
          .instanceCreationExpression_typeArguments
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.integerLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.integerLiteral_value ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.interpolationExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.interpolationExpression_expression != null);
      this.interpolationExpression_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.interpolationString) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.interpolationString_value ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.isExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.isExpression_expression != null);
      this.isExpression_expression?.collectApiSignature(signature);
      signature.addBool(this.isExpression_type != null);
      this.isExpression_type?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.label) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.label_label != null);
      this.label_label?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.labeledStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.labeledStatement_labels == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.labeledStatement_labels.length);
        for (var x in this.labeledStatement_labels) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.labeledStatement_statement != null);
      this.labeledStatement_statement?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.libraryDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.libraryDirective_name != null);
      this.libraryDirective_name?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.libraryIdentifier_components == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.libraryIdentifier_components.length);
        for (var x in this.libraryIdentifier_components) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.listLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.typedLiteral_typeArguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.typedLiteral_typeArguments.length);
        for (var x in this.typedLiteral_typeArguments) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.listLiteral_elements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.listLiteral_elements.length);
        for (var x in this.listLiteral_elements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.mapLiteralEntry_key != null);
      this.mapLiteralEntry_key?.collectApiSignature(signature);
      signature.addBool(this.mapLiteralEntry_value != null);
      this.mapLiteralEntry_value?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.methodDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.methodDeclaration_body != null);
      this.methodDeclaration_body?.collectApiSignature(signature);
      signature.addBool(this.methodDeclaration_formalParameters != null);
      this.methodDeclaration_formalParameters?.collectApiSignature(signature);
      signature.addBool(this.methodDeclaration_returnType != null);
      this.methodDeclaration_returnType?.collectApiSignature(signature);
      signature.addBool(this.methodDeclaration_typeParameters != null);
      this.methodDeclaration_typeParameters?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualReturnType != null);
      this.actualReturnType?.collectApiSignature(signature);
      signature.addBool(
          this.methodDeclaration_hasOperatorEqualWithParameterTypeFromObject ==
              true);
      signature.addBool(this.topLevelTypeInferenceError != null);
      this.topLevelTypeInferenceError?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.methodInvocation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.methodInvocation_methodName != null);
      this.methodInvocation_methodName?.collectApiSignature(signature);
      signature.addBool(this.methodInvocation_target != null);
      this.methodInvocation_target?.collectApiSignature(signature);
      signature.addBool(this.invocationExpression_typeArguments != null);
      this.invocationExpression_typeArguments?.collectApiSignature(signature);
      signature.addBool(this.invocationExpression_arguments != null);
      this.invocationExpression_arguments?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.invocationExpression_invokeType != null);
      this.invocationExpression_invokeType?.collectApiSignature(signature);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.classOrMixinDeclaration_members == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.classOrMixinDeclaration_members.length);
        for (var x in this.classOrMixinDeclaration_members) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.mixinDeclaration_onClause != null);
      this.mixinDeclaration_onClause?.collectApiSignature(signature);
      signature.addBool(this.classOrMixinDeclaration_implementsClause != null);
      this
          .classOrMixinDeclaration_implementsClause
          ?.collectApiSignature(signature);
      signature.addBool(this.classOrMixinDeclaration_typeParameters != null);
      this
          .classOrMixinDeclaration_typeParameters
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.simplyBoundable_isSimplyBounded == true);
      if (this.mixinDeclaration_superInvokedNames == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.mixinDeclaration_superInvokedNames.length);
        for (var x in this.mixinDeclaration_superInvokedNames) {
          signature.addString(x);
        }
      }
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.namedExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.namedExpression_expression != null);
      this.namedExpression_expression?.collectApiSignature(signature);
      signature.addBool(this.namedExpression_name != null);
      this.namedExpression_name?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.nativeClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.nativeClause_name != null);
      this.nativeClause_name?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.nativeFunctionBody_stringLiteral != null);
      this.nativeFunctionBody_stringLiteral?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.nullLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nullLiteral_fake ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.onClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.onClause_superclassConstraints == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.onClause_superclassConstraints.length);
        for (var x in this.onClause_superclassConstraints) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.parenthesizedExpression_expression != null);
      this.parenthesizedExpression_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.partDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.uriBasedDirective_uri != null);
      this.uriBasedDirective_uri?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.uriBasedDirective_uriElement ?? 0);
      signature.addString(this.uriBasedDirective_uriContent ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.partOfDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.partOfDirective_libraryName != null);
      this.partOfDirective_libraryName?.collectApiSignature(signature);
      signature.addBool(this.partOfDirective_uri != null);
      this.partOfDirective_uri?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.postfixExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.postfixExpression_operand != null);
      this.postfixExpression_operand?.collectApiSignature(signature);
      signature.addInt(this.postfixExpression_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addInt(this.postfixExpression_operator == null
          ? 0
          : this.postfixExpression_operator.index);
      signature.addString(this.name ?? '');
      signature.addBool(this.postfixExpression_substitution != null);
      this.postfixExpression_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.prefixExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.prefixExpression_operand != null);
      this.prefixExpression_operand?.collectApiSignature(signature);
      signature.addInt(this.prefixExpression_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addInt(this.prefixExpression_operator == null
          ? 0
          : this.prefixExpression_operator.index);
      signature.addString(this.name ?? '');
      signature.addBool(this.prefixExpression_substitution != null);
      this.prefixExpression_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.prefixedIdentifier_identifier != null);
      this.prefixedIdentifier_identifier?.collectApiSignature(signature);
      signature.addBool(this.prefixedIdentifier_prefix != null);
      this.prefixedIdentifier_prefix?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.propertyAccess) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.propertyAccess_propertyName != null);
      this.propertyAccess_propertyName?.collectApiSignature(signature);
      signature.addBool(this.propertyAccess_target != null);
      this.propertyAccess_target?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addInt(this.propertyAccess_operator == null
          ? 0
          : this.propertyAccess_operator.index);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature
          .addBool(this.redirectingConstructorInvocation_arguments != null);
      this
          .redirectingConstructorInvocation_arguments
          ?.collectApiSignature(signature);
      signature.addBool(
          this.redirectingConstructorInvocation_constructorName != null);
      this
          .redirectingConstructorInvocation_constructorName
          ?.collectApiSignature(signature);
      signature.addInt(this.redirectingConstructorInvocation_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
      signature
          .addBool(this.redirectingConstructorInvocation_substitution != null);
      this
          .redirectingConstructorInvocation_substitution
          ?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.rethrowExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.returnStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.returnStatement_expression != null);
      this.returnStatement_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.typedLiteral_typeArguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.typedLiteral_typeArguments.length);
        for (var x in this.typedLiteral_typeArguments) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.setOrMapLiteral_elements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.setOrMapLiteral_elements.length);
        for (var x in this.setOrMapLiteral_elements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.showCombinator) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      if (this.names == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.names.length);
        for (var x in this.names) {
          signature.addString(x);
        }
      }
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.normalFormalParameter_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.normalFormalParameter_metadata.length);
        for (var x in this.normalFormalParameter_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.simpleFormalParameter_type != null);
      this.simpleFormalParameter_type?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualType != null);
      this.actualType?.collectApiSignature(signature);
      signature.addBool(this.inheritsCovariant == true);
      signature.addBool(this.topLevelTypeInferenceError != null);
      this.topLevelTypeInferenceError?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.simpleIdentifier_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
      signature.addBool(this.simpleIdentifier_substitution != null);
      this.simpleIdentifier_substitution?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.simpleStringLiteral_value ?? '');
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.spreadElement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.spreadElement_expression != null);
      this.spreadElement_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addInt(this.spreadElement_spreadOperator == null
          ? 0
          : this.spreadElement_spreadOperator.index);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.stringInterpolation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.stringInterpolation_elements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.stringInterpolation_elements.length);
        for (var x in this.stringInterpolation_elements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.superConstructorInvocation_arguments != null);
      this.superConstructorInvocation_arguments?.collectApiSignature(signature);
      signature
          .addBool(this.superConstructorInvocation_constructorName != null);
      this
          .superConstructorInvocation_constructorName
          ?.collectApiSignature(signature);
      signature.addInt(this.superConstructorInvocation_element ?? 0);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
      signature.addBool(this.superConstructorInvocation_substitution != null);
      this
          .superConstructorInvocation_substitution
          ?.collectApiSignature(signature);
    } else if (kind == idl.LinkedNodeKind.superExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.switchCase) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.switchMember_labels == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.switchMember_labels.length);
        for (var x in this.switchMember_labels) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.switchMember_statements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.switchMember_statements.length);
        for (var x in this.switchMember_statements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.switchCase_expression != null);
      this.switchCase_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.switchDefault) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.switchMember_labels == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.switchMember_labels.length);
        for (var x in this.switchMember_labels) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.switchMember_statements == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.switchMember_statements.length);
        for (var x in this.switchMember_statements) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.switchStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.switchStatement_members == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.switchStatement_members.length);
        for (var x in this.switchStatement_members) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.switchStatement_expression != null);
      this.switchStatement_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.symbolLiteral) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      if (this.names == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.names.length);
        for (var x in this.names) {
          signature.addString(x);
        }
      }
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.thisExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.throwExpression) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.throwExpression_expression != null);
      this.throwExpression_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.expression_type != null);
      this.expression_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.topLevelVariableDeclaration_variableList != null);
      this
          .topLevelVariableDeclaration_variableList
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.tryStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.tryStatement_catchClauses == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.tryStatement_catchClauses.length);
        for (var x in this.tryStatement_catchClauses) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.tryStatement_body != null);
      this.tryStatement_body?.collectApiSignature(signature);
      signature.addBool(this.tryStatement_finallyBlock != null);
      this.tryStatement_finallyBlock?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.typeArgumentList) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.typeArgumentList_arguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.typeArgumentList_arguments.length);
        for (var x in this.typeArgumentList_arguments) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.typeName) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.typeName_typeArguments == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.typeName_typeArguments.length);
        for (var x in this.typeName_typeArguments) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.typeName_name != null);
      this.typeName_name?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.typeName_type != null);
      this.typeName_type?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.typeParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.typeParameter_bound != null);
      this.typeParameter_bound?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.typeParameter_defaultType != null);
      this.typeParameter_defaultType?.collectApiSignature(signature);
      signature.addInt(this.typeParameter_variance == null
          ? 0
          : this.typeParameter_variance.index);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.typeParameterList) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.typeParameterList_typeParameters == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.typeParameterList_typeParameters.length);
        for (var x in this.typeParameterList_typeParameters) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.variableDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.variableDeclaration_initializer != null);
      this.variableDeclaration_initializer?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addBool(this.actualType != null);
      this.actualType?.collectApiSignature(signature);
      signature.addBool(this.inheritsCovariant == true);
      signature.addBool(this.topLevelTypeInferenceError != null);
      this.topLevelTypeInferenceError?.collectApiSignature(signature);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.variableDeclarationList_variables == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.variableDeclarationList_variables.length);
        for (var x in this.variableDeclarationList_variables) {
          x?.collectApiSignature(signature);
        }
      }
      if (this.annotatedNode_metadata == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.annotatedNode_metadata.length);
        for (var x in this.annotatedNode_metadata) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addBool(this.variableDeclarationList_type != null);
      this.variableDeclarationList_type?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.variableDeclarationStatement_variables != null);
      this
          .variableDeclarationStatement_variables
          ?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.whileStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.whileStatement_body != null);
      this.whileStatement_body?.collectApiSignature(signature);
      signature.addBool(this.whileStatement_condition != null);
      this.whileStatement_condition?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.withClause) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.withClause_mixinTypes == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.withClause_mixinTypes.length);
        for (var x in this.withClause_mixinTypes) {
          x?.collectApiSignature(signature);
        }
      }
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    } else if (kind == idl.LinkedNodeKind.yieldStatement) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addBool(this.yieldStatement_expression != null);
      this.yieldStatement_expression?.collectApiSignature(signature);
      signature.addInt(this.flags ?? 0);
      signature.addString(this.name ?? '');
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_variantField_24;
    fb.Offset offset_variantField_2;
    fb.Offset offset_variantField_4;
    fb.Offset offset_variantField_6;
    fb.Offset offset_variantField_7;
    fb.Offset offset_variantField_8;
    fb.Offset offset_variantField_38;
    fb.Offset offset_variantField_9;
    fb.Offset offset_variantField_12;
    fb.Offset offset_variantField_5;
    fb.Offset offset_variantField_13;
    fb.Offset offset_variantField_33;
    fb.Offset offset_variantField_3;
    fb.Offset offset_variantField_40;
    fb.Offset offset_variantField_10;
    fb.Offset offset_variantField_25;
    fb.Offset offset_variantField_20;
    fb.Offset offset_variantField_39;
    fb.Offset offset_variantField_1;
    fb.Offset offset_variantField_30;
    fb.Offset offset_variantField_14;
    fb.Offset offset_variantField_34;
    fb.Offset offset_name;
    fb.Offset offset_variantField_32;
    fb.Offset offset_variantField_23;
    fb.Offset offset_variantField_11;
    fb.Offset offset_variantField_22;
    if (_variantField_24 != null) {
      offset_variantField_24 = _variantField_24.finish(fbBuilder);
    }
    if (!(_variantField_2 == null || _variantField_2.isEmpty)) {
      offset_variantField_2 = fbBuilder
          .writeList(_variantField_2.map((b) => b.finish(fbBuilder)).toList());
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
    if (_variantField_8 != null) {
      offset_variantField_8 = _variantField_8.finish(fbBuilder);
    }
    if (_variantField_38 != null) {
      offset_variantField_38 = _variantField_38.finish(fbBuilder);
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
    if (!(_variantField_33 == null || _variantField_33.isEmpty)) {
      offset_variantField_33 = fbBuilder.writeList(
          _variantField_33.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_variantField_3 == null || _variantField_3.isEmpty)) {
      offset_variantField_3 = fbBuilder
          .writeList(_variantField_3.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_40 != null) {
      offset_variantField_40 = _variantField_40.finish(fbBuilder);
    }
    if (_variantField_10 != null) {
      offset_variantField_10 = _variantField_10.finish(fbBuilder);
    }
    if (_variantField_25 != null) {
      offset_variantField_25 = _variantField_25.finish(fbBuilder);
    }
    if (_variantField_20 != null) {
      offset_variantField_20 = fbBuilder.writeString(_variantField_20);
    }
    if (!(_variantField_39 == null || _variantField_39.isEmpty)) {
      offset_variantField_39 = fbBuilder
          .writeList(_variantField_39.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_variantField_1 != null) {
      offset_variantField_1 = fbBuilder.writeString(_variantField_1);
    }
    if (_variantField_30 != null) {
      offset_variantField_30 = fbBuilder.writeString(_variantField_30);
    }
    if (_variantField_14 != null) {
      offset_variantField_14 = _variantField_14.finish(fbBuilder);
    }
    if (!(_variantField_34 == null || _variantField_34.isEmpty)) {
      offset_variantField_34 = fbBuilder.writeList(
          _variantField_34.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_variantField_32 != null) {
      offset_variantField_32 = _variantField_32.finish(fbBuilder);
    }
    if (_variantField_23 != null) {
      offset_variantField_23 = _variantField_23.finish(fbBuilder);
    }
    if (_variantField_11 != null) {
      offset_variantField_11 = _variantField_11.finish(fbBuilder);
    }
    if (_variantField_22 != null) {
      offset_variantField_22 = fbBuilder.writeString(_variantField_22);
    }
    fbBuilder.startTable();
    if (offset_variantField_24 != null) {
      fbBuilder.addOffset(24, offset_variantField_24);
    }
    if (offset_variantField_2 != null) {
      fbBuilder.addOffset(2, offset_variantField_2);
    }
    if (offset_variantField_4 != null) {
      fbBuilder.addOffset(4, offset_variantField_4);
    }
    if (offset_variantField_6 != null) {
      fbBuilder.addOffset(6, offset_variantField_6);
    }
    if (offset_variantField_7 != null) {
      fbBuilder.addOffset(7, offset_variantField_7);
    }
    if (_variantField_17 != null && _variantField_17 != 0) {
      fbBuilder.addUint32(17, _variantField_17);
    }
    if (offset_variantField_8 != null) {
      fbBuilder.addOffset(8, offset_variantField_8);
    }
    if (offset_variantField_38 != null) {
      fbBuilder.addOffset(38, offset_variantField_38);
    }
    if (_variantField_15 != null && _variantField_15 != 0) {
      fbBuilder.addUint32(15, _variantField_15);
    }
    if (_variantField_28 != null &&
        _variantField_28 != idl.UnlinkedTokenType.NOTHING) {
      fbBuilder.addUint8(28, _variantField_28.index);
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
    if (offset_variantField_33 != null) {
      fbBuilder.addOffset(33, offset_variantField_33);
    }
    if (_variantField_29 != null &&
        _variantField_29 != idl.LinkedNodeCommentType.block) {
      fbBuilder.addUint8(29, _variantField_29.index);
    }
    if (offset_variantField_3 != null) {
      fbBuilder.addOffset(3, offset_variantField_3);
    }
    if (offset_variantField_40 != null) {
      fbBuilder.addOffset(40, offset_variantField_40);
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
    if (offset_variantField_20 != null) {
      fbBuilder.addOffset(20, offset_variantField_20);
    }
    if (offset_variantField_39 != null) {
      fbBuilder.addOffset(39, offset_variantField_39);
    }
    if (_flags != null && _flags != 0) {
      fbBuilder.addUint32(18, _flags);
    }
    if (offset_variantField_1 != null) {
      fbBuilder.addOffset(1, offset_variantField_1);
    }
    if (_variantField_36 != null && _variantField_36 != 0) {
      fbBuilder.addUint32(36, _variantField_36);
    }
    if (_variantField_16 != null && _variantField_16 != 0) {
      fbBuilder.addUint32(16, _variantField_16);
    }
    if (offset_variantField_30 != null) {
      fbBuilder.addOffset(30, offset_variantField_30);
    }
    if (offset_variantField_14 != null) {
      fbBuilder.addOffset(14, offset_variantField_14);
    }
    if (_kind != null && _kind != idl.LinkedNodeKind.adjacentStrings) {
      fbBuilder.addUint8(0, _kind.index);
    }
    if (_variantField_31 == true) {
      fbBuilder.addBool(31, true);
    }
    if (offset_variantField_34 != null) {
      fbBuilder.addOffset(34, offset_variantField_34);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(37, offset_name);
    }
    if (_variantField_35 != null &&
        _variantField_35 != idl.UnlinkedTokenType.NOTHING) {
      fbBuilder.addUint8(35, _variantField_35.index);
    }
    if (offset_variantField_32 != null) {
      fbBuilder.addOffset(32, offset_variantField_32);
    }
    if (offset_variantField_23 != null) {
      fbBuilder.addOffset(23, offset_variantField_23);
    }
    if (offset_variantField_11 != null) {
      fbBuilder.addOffset(11, offset_variantField_11);
    }
    if (offset_variantField_22 != null) {
      fbBuilder.addOffset(22, offset_variantField_22);
    }
    if (_variantField_19 != null && _variantField_19 != 0) {
      fbBuilder.addUint32(19, _variantField_19);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeReader extends fb.TableReader<_LinkedNodeImpl> {
  const _LinkedNodeReader();

  @override
  _LinkedNodeImpl createObject(fb.BufferContext bc, int offset) =>
      _LinkedNodeImpl(bc, offset);
}

class _LinkedNodeImpl extends Object
    with _LinkedNodeMixin
    implements idl.LinkedNode {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeImpl(this._bc, this._bcOffset);

  idl.LinkedNodeType _variantField_24;
  List<idl.LinkedNode> _variantField_2;
  List<idl.LinkedNode> _variantField_4;
  idl.LinkedNode _variantField_6;
  idl.LinkedNode _variantField_7;
  int _variantField_17;
  idl.LinkedNode _variantField_8;
  idl.LinkedNodeTypeSubstitution _variantField_38;
  int _variantField_15;
  idl.UnlinkedTokenType _variantField_28;
  bool _variantField_27;
  idl.LinkedNode _variantField_9;
  idl.LinkedNode _variantField_12;
  List<idl.LinkedNode> _variantField_5;
  idl.LinkedNode _variantField_13;
  List<String> _variantField_33;
  idl.LinkedNodeCommentType _variantField_29;
  List<idl.LinkedNode> _variantField_3;
  idl.LinkedLibraryLanguageVersion _variantField_40;
  idl.LinkedNode _variantField_10;
  idl.LinkedNodeFormalParameterKind _variantField_26;
  double _variantField_21;
  idl.LinkedNodeType _variantField_25;
  String _variantField_20;
  List<idl.LinkedNodeType> _variantField_39;
  int _flags;
  String _variantField_1;
  int _variantField_36;
  int _variantField_16;
  String _variantField_30;
  idl.LinkedNode _variantField_14;
  idl.LinkedNodeKind _kind;
  bool _variantField_31;
  List<String> _variantField_34;
  String _name;
  idl.UnlinkedTokenType _variantField_35;
  idl.TopLevelInferenceError _variantField_32;
  idl.LinkedNodeType _variantField_23;
  idl.LinkedNode _variantField_11;
  String _variantField_22;
  int _variantField_19;

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
  idl.LinkedNodeType get extensionOverride_extendedType {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get argumentList_arguments {
    assert(kind == idl.LinkedNodeKind.argumentList);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get block_statements {
    assert(kind == idl.LinkedNodeKind.block);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get cascadeExpression_sections {
    assert(kind == idl.LinkedNodeKind.cascadeExpression);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get comment_references {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get compilationUnit_declarations {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get constructorDeclaration_initializers {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get dottedName_components {
    assert(kind == idl.LinkedNodeKind.dottedName);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get enumDeclaration_constants {
    assert(kind == idl.LinkedNodeKind.enumDeclaration);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get extensionOverride_arguments {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get formalParameterList_parameters {
    assert(kind == idl.LinkedNodeKind.formalParameterList);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get implementsClause_interfaces {
    assert(kind == idl.LinkedNodeKind.implementsClause);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get instanceCreationExpression_arguments {
    assert(kind == idl.LinkedNodeKind.instanceCreationExpression);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get labeledStatement_labels {
    assert(kind == idl.LinkedNodeKind.labeledStatement);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get libraryIdentifier_components {
    assert(kind == idl.LinkedNodeKind.libraryIdentifier);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get namespaceDirective_combinators {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get onClause_superclassConstraints {
    assert(kind == idl.LinkedNodeKind.onClause);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get stringInterpolation_elements {
    assert(kind == idl.LinkedNodeKind.stringInterpolation);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get switchStatement_members {
    assert(kind == idl.LinkedNodeKind.switchStatement);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get tryStatement_catchClauses {
    assert(kind == idl.LinkedNodeKind.tryStatement);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typeArgumentList_arguments {
    assert(kind == idl.LinkedNodeKind.typeArgumentList);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typedLiteral_typeArguments {
    assert(kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typeName_typeArguments {
    assert(kind == idl.LinkedNodeKind.typeName);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get typeParameterList_typeParameters {
    assert(kind == idl.LinkedNodeKind.typeParameterList);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get variableDeclarationList_variables {
    assert(kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
  }

  @override
  List<idl.LinkedNode> get withClause_mixinTypes {
    assert(kind == idl.LinkedNodeKind.withClause);
    _variantField_2 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.LinkedNode>[]);
    return _variantField_2;
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
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    _variantField_4 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNode>[]);
    return _variantField_4;
  }

  @override
  List<idl.LinkedNode> get normalFormalParameter_metadata {
    assert(kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.simpleFormalParameter);
    _variantField_4 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.LinkedNode>[]);
    return _variantField_4;
  }

  @override
  List<idl.LinkedNode> get switchMember_statements {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_4 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
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
  idl.LinkedNode get extensionDeclaration_typeParameters {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
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
  idl.LinkedNode get indexExpression_index {
    assert(kind == idl.LinkedNodeKind.indexExpression);
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
  idl.LinkedNode get extensionDeclaration_extendedType {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    _variantField_7 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 7, null);
    return _variantField_7;
  }

  @override
  idl.LinkedNode get extensionOverride_extensionName {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
  int get genericFunctionType_id {
    assert(kind == idl.LinkedNodeKind.genericFunctionType);
    _variantField_17 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _variantField_17;
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
  idl.LinkedNode get extensionOverride_typeArguments {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
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
  idl.LinkedNodeTypeSubstitution get annotation_substitution {
    assert(kind == idl.LinkedNodeKind.annotation);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get assignmentExpression_substitution {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get binaryExpression_substitution {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get constructorName_substitution {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get indexExpression_substitution {
    assert(kind == idl.LinkedNodeKind.indexExpression);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get postfixExpression_substitution {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get prefixExpression_substitution {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution
      get redirectingConstructorInvocation_substitution {
    assert(kind == idl.LinkedNodeKind.redirectingConstructorInvocation);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get simpleIdentifier_substitution {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  idl.LinkedNodeTypeSubstitution get superConstructorInvocation_substitution {
    assert(kind == idl.LinkedNodeKind.superConstructorInvocation);
    _variantField_38 ??= const _LinkedNodeTypeSubstitutionReader()
        .vTableGet(_bc, _bcOffset, 38, null);
    return _variantField_38;
  }

  @override
  int get assignmentExpression_element {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
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
  int get constructorName_element {
    assert(kind == idl.LinkedNodeKind.constructorName);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get emptyFunctionBody_fake {
    assert(kind == idl.LinkedNodeKind.emptyFunctionBody);
    _variantField_15 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
    return _variantField_15;
  }

  @override
  int get emptyStatement_fake {
    assert(kind == idl.LinkedNodeKind.emptyStatement);
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
  int get nullLiteral_fake {
    assert(kind == idl.LinkedNodeKind.nullLiteral);
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
  int get prefixExpression_element {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
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
  int get simpleIdentifier_element {
    assert(kind == idl.LinkedNodeKind.simpleIdentifier);
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
  idl.UnlinkedTokenType get assignmentExpression_operator {
    assert(kind == idl.LinkedNodeKind.assignmentExpression);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
  }

  @override
  idl.UnlinkedTokenType get binaryExpression_operator {
    assert(kind == idl.LinkedNodeKind.binaryExpression);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
  }

  @override
  idl.UnlinkedTokenType get postfixExpression_operator {
    assert(kind == idl.LinkedNodeKind.postfixExpression);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
  }

  @override
  idl.UnlinkedTokenType get prefixExpression_operator {
    assert(kind == idl.LinkedNodeKind.prefixExpression);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
  }

  @override
  idl.UnlinkedTokenType get propertyAccess_operator {
    assert(kind == idl.LinkedNodeKind.propertyAccess);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
  }

  @override
  idl.UnlinkedTokenType get typeParameter_variance {
    assert(kind == idl.LinkedNodeKind.typeParameter);
    _variantField_28 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 28, idl.UnlinkedTokenType.NOTHING);
    return _variantField_28;
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
  List<idl.LinkedNode> get classOrMixinDeclaration_members {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_5 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 5, const <idl.LinkedNode>[]);
    return _variantField_5;
  }

  @override
  List<idl.LinkedNode> get extensionDeclaration_members {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    _variantField_5 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 5, const <idl.LinkedNode>[]);
    return _variantField_5;
  }

  @override
  List<idl.LinkedNode> get forParts_updaters {
    assert(kind == idl.LinkedNodeKind.forPartsWithDeclarations ||
        kind == idl.LinkedNodeKind.forPartsWithExpression);
    _variantField_5 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
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
  List<String> get comment_tokens {
    assert(kind == idl.LinkedNodeKind.comment);
    _variantField_33 ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 33, const <String>[]);
    return _variantField_33;
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
    _variantField_3 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get listLiteral_elements {
    assert(kind == idl.LinkedNodeKind.listLiteral);
    _variantField_3 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get namespaceDirective_configurations {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective);
    _variantField_3 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get setOrMapLiteral_elements {
    assert(kind == idl.LinkedNodeKind.setOrMapLiteral);
    _variantField_3 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  List<idl.LinkedNode> get switchMember_labels {
    assert(kind == idl.LinkedNodeKind.switchCase ||
        kind == idl.LinkedNodeKind.switchDefault);
    _variantField_3 ??= const fb.ListReader<idl.LinkedNode>(_LinkedNodeReader())
        .vTableGet(_bc, _bcOffset, 3, const <idl.LinkedNode>[]);
    return _variantField_3;
  }

  @override
  idl.LinkedLibraryLanguageVersion get compilationUnit_languageVersion {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_40 ??= const _LinkedLibraryLanguageVersionReader()
        .vTableGet(_bc, _bcOffset, 40, null);
    return _variantField_40;
  }

  @override
  idl.LinkedNode get constructorDeclaration_returnType {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
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
    assert(kind == idl.LinkedNodeKind.assignmentExpression ||
        kind == idl.LinkedNodeKind.asExpression ||
        kind == idl.LinkedNodeKind.awaitExpression ||
        kind == idl.LinkedNodeKind.binaryExpression ||
        kind == idl.LinkedNodeKind.cascadeExpression ||
        kind == idl.LinkedNodeKind.conditionalExpression ||
        kind == idl.LinkedNodeKind.functionExpressionInvocation ||
        kind == idl.LinkedNodeKind.indexExpression ||
        kind == idl.LinkedNodeKind.instanceCreationExpression ||
        kind == idl.LinkedNodeKind.integerLiteral ||
        kind == idl.LinkedNodeKind.listLiteral ||
        kind == idl.LinkedNodeKind.methodInvocation ||
        kind == idl.LinkedNodeKind.nullLiteral ||
        kind == idl.LinkedNodeKind.parenthesizedExpression ||
        kind == idl.LinkedNodeKind.prefixExpression ||
        kind == idl.LinkedNodeKind.prefixedIdentifier ||
        kind == idl.LinkedNodeKind.propertyAccess ||
        kind == idl.LinkedNodeKind.postfixExpression ||
        kind == idl.LinkedNodeKind.rethrowExpression ||
        kind == idl.LinkedNodeKind.setOrMapLiteral ||
        kind == idl.LinkedNodeKind.simpleIdentifier ||
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
  String get extensionDeclaration_refName {
    assert(kind == idl.LinkedNodeKind.extensionDeclaration);
    _variantField_20 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 20, '');
    return _variantField_20;
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
  List<idl.LinkedNodeType> get extensionOverride_typeArgumentTypes {
    assert(kind == idl.LinkedNodeKind.extensionOverride);
    _variantField_39 ??=
        const fb.ListReader<idl.LinkedNodeType>(_LinkedNodeTypeReader())
            .vTableGet(_bc, _bcOffset, 39, const <idl.LinkedNodeType>[]);
    return _variantField_39;
  }

  @override
  int get flags {
    _flags ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _flags;
  }

  @override
  String get importDirective_prefix {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_1 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _variantField_1;
  }

  @override
  int get informativeId {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration ||
        kind == idl.LinkedNodeKind.variableDeclarationList);
    _variantField_36 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 36, 0);
    return _variantField_36;
  }

  @override
  int get integerLiteral_value {
    assert(kind == idl.LinkedNodeKind.integerLiteral);
    _variantField_16 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
    return _variantField_16;
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
  idl.LinkedNode get uriBasedDirective_uri {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_14 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 14, null);
    return _variantField_14;
  }

  @override
  idl.LinkedNodeKind get kind {
    _kind ??= const _LinkedNodeKindReader()
        .vTableGet(_bc, _bcOffset, 0, idl.LinkedNodeKind.adjacentStrings);
    return _kind;
  }

  @override
  bool get methodDeclaration_hasOperatorEqualWithParameterTypeFromObject {
    assert(kind == idl.LinkedNodeKind.methodDeclaration);
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
  List<String> get mixinDeclaration_superInvokedNames {
    assert(kind == idl.LinkedNodeKind.mixinDeclaration);
    _variantField_34 ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 34, const <String>[]);
    return _variantField_34;
  }

  @override
  List<String> get names {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator ||
        kind == idl.LinkedNodeKind.symbolLiteral);
    _variantField_34 ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 34, const <String>[]);
    return _variantField_34;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 37, '');
    return _name;
  }

  @override
  idl.UnlinkedTokenType get spreadElement_spreadOperator {
    assert(kind == idl.LinkedNodeKind.spreadElement);
    _variantField_35 ??= const _UnlinkedTokenTypeReader()
        .vTableGet(_bc, _bcOffset, 35, idl.UnlinkedTokenType.NOTHING);
    return _variantField_35;
  }

  @override
  idl.TopLevelInferenceError get topLevelTypeInferenceError {
    assert(kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_32 ??= const _TopLevelInferenceErrorReader()
        .vTableGet(_bc, _bcOffset, 32, null);
    return _variantField_32;
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
  idl.LinkedNode get unused11 {
    assert(kind == idl.LinkedNodeKind.classDeclaration);
    _variantField_11 ??=
        const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 11, null);
    return _variantField_11;
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
  int get uriBasedDirective_uriElement {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.partDirective);
    _variantField_19 ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 19, 0);
    return _variantField_19;
  }
}

abstract class _LinkedNodeMixin implements idl.LinkedNode {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (flags != 0) {
      _result["flags"] = flags;
    }
    if (kind != idl.LinkedNodeKind.adjacentStrings) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    if (name != '') {
      _result["name"] = name;
    }
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      if (adjacentStrings_strings.isNotEmpty) {
        _result["adjacentStrings_strings"] =
            adjacentStrings_strings.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.annotation) {
      if (annotation_arguments != null) {
        _result["annotation_arguments"] = annotation_arguments.toJson();
      }
      if (annotation_constructorName != null) {
        _result["annotation_constructorName"] =
            annotation_constructorName.toJson();
      }
      if (annotation_element != 0) {
        _result["annotation_element"] = annotation_element;
      }
      if (annotation_name != null) {
        _result["annotation_name"] = annotation_name.toJson();
      }
      if (annotation_substitution != null) {
        _result["annotation_substitution"] = annotation_substitution.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.argumentList) {
      if (argumentList_arguments.isNotEmpty) {
        _result["argumentList_arguments"] =
            argumentList_arguments.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.asExpression) {
      if (asExpression_expression != null) {
        _result["asExpression_expression"] = asExpression_expression.toJson();
      }
      if (asExpression_type != null) {
        _result["asExpression_type"] = asExpression_type.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.assertInitializer) {
      if (assertInitializer_condition != null) {
        _result["assertInitializer_condition"] =
            assertInitializer_condition.toJson();
      }
      if (assertInitializer_message != null) {
        _result["assertInitializer_message"] =
            assertInitializer_message.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.assertStatement) {
      if (assertStatement_condition != null) {
        _result["assertStatement_condition"] =
            assertStatement_condition.toJson();
      }
      if (assertStatement_message != null) {
        _result["assertStatement_message"] = assertStatement_message.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.assignmentExpression) {
      if (assignmentExpression_leftHandSide != null) {
        _result["assignmentExpression_leftHandSide"] =
            assignmentExpression_leftHandSide.toJson();
      }
      if (assignmentExpression_rightHandSide != null) {
        _result["assignmentExpression_rightHandSide"] =
            assignmentExpression_rightHandSide.toJson();
      }
      if (assignmentExpression_substitution != null) {
        _result["assignmentExpression_substitution"] =
            assignmentExpression_substitution.toJson();
      }
      if (assignmentExpression_element != 0) {
        _result["assignmentExpression_element"] = assignmentExpression_element;
      }
      if (assignmentExpression_operator != idl.UnlinkedTokenType.NOTHING) {
        _result["assignmentExpression_operator"] =
            assignmentExpression_operator.toString().split('.')[1];
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.awaitExpression) {
      if (awaitExpression_expression != null) {
        _result["awaitExpression_expression"] =
            awaitExpression_expression.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.binaryExpression) {
      if (binaryExpression_invokeType != null) {
        _result["binaryExpression_invokeType"] =
            binaryExpression_invokeType.toJson();
      }
      if (binaryExpression_leftOperand != null) {
        _result["binaryExpression_leftOperand"] =
            binaryExpression_leftOperand.toJson();
      }
      if (binaryExpression_rightOperand != null) {
        _result["binaryExpression_rightOperand"] =
            binaryExpression_rightOperand.toJson();
      }
      if (binaryExpression_substitution != null) {
        _result["binaryExpression_substitution"] =
            binaryExpression_substitution.toJson();
      }
      if (binaryExpression_element != 0) {
        _result["binaryExpression_element"] = binaryExpression_element;
      }
      if (binaryExpression_operator != idl.UnlinkedTokenType.NOTHING) {
        _result["binaryExpression_operator"] =
            binaryExpression_operator.toString().split('.')[1];
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.block) {
      if (block_statements.isNotEmpty) {
        _result["block_statements"] =
            block_statements.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      if (blockFunctionBody_block != null) {
        _result["blockFunctionBody_block"] = blockFunctionBody_block.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.booleanLiteral) {
      if (booleanLiteral_value != false) {
        _result["booleanLiteral_value"] = booleanLiteral_value;
      }
    }
    if (kind == idl.LinkedNodeKind.breakStatement) {
      if (breakStatement_label != null) {
        _result["breakStatement_label"] = breakStatement_label.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.cascadeExpression) {
      if (cascadeExpression_sections.isNotEmpty) {
        _result["cascadeExpression_sections"] = cascadeExpression_sections
            .map((_value) => _value.toJson())
            .toList();
      }
      if (cascadeExpression_target != null) {
        _result["cascadeExpression_target"] = cascadeExpression_target.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.catchClause) {
      if (catchClause_body != null) {
        _result["catchClause_body"] = catchClause_body.toJson();
      }
      if (catchClause_exceptionParameter != null) {
        _result["catchClause_exceptionParameter"] =
            catchClause_exceptionParameter.toJson();
      }
      if (catchClause_exceptionType != null) {
        _result["catchClause_exceptionType"] =
            catchClause_exceptionType.toJson();
      }
      if (catchClause_stackTraceParameter != null) {
        _result["catchClause_stackTraceParameter"] =
            catchClause_stackTraceParameter.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (classDeclaration_extendsClause != null) {
        _result["classDeclaration_extendsClause"] =
            classDeclaration_extendsClause.toJson();
      }
      if (classDeclaration_withClause != null) {
        _result["classDeclaration_withClause"] =
            classDeclaration_withClause.toJson();
      }
      if (classDeclaration_nativeClause != null) {
        _result["classDeclaration_nativeClause"] =
            classDeclaration_nativeClause.toJson();
      }
      if (classDeclaration_isDartObject != false) {
        _result["classDeclaration_isDartObject"] =
            classDeclaration_isDartObject;
      }
      if (classOrMixinDeclaration_implementsClause != null) {
        _result["classOrMixinDeclaration_implementsClause"] =
            classOrMixinDeclaration_implementsClause.toJson();
      }
      if (classOrMixinDeclaration_members.isNotEmpty) {
        _result["classOrMixinDeclaration_members"] =
            classOrMixinDeclaration_members
                .map((_value) => _value.toJson())
                .toList();
      }
      if (classOrMixinDeclaration_typeParameters != null) {
        _result["classOrMixinDeclaration_typeParameters"] =
            classOrMixinDeclaration_typeParameters.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (simplyBoundable_isSimplyBounded != false) {
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
      }
      if (unused11 != null) {
        _result["unused11"] = unused11.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (classTypeAlias_typeParameters != null) {
        _result["classTypeAlias_typeParameters"] =
            classTypeAlias_typeParameters.toJson();
      }
      if (classTypeAlias_superclass != null) {
        _result["classTypeAlias_superclass"] =
            classTypeAlias_superclass.toJson();
      }
      if (classTypeAlias_withClause != null) {
        _result["classTypeAlias_withClause"] =
            classTypeAlias_withClause.toJson();
      }
      if (classTypeAlias_implementsClause != null) {
        _result["classTypeAlias_implementsClause"] =
            classTypeAlias_implementsClause.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (simplyBoundable_isSimplyBounded != false) {
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
      }
    }
    if (kind == idl.LinkedNodeKind.comment) {
      if (comment_references.isNotEmpty) {
        _result["comment_references"] =
            comment_references.map((_value) => _value.toJson()).toList();
      }
      if (comment_tokens.isNotEmpty) {
        _result["comment_tokens"] = comment_tokens;
      }
      if (comment_type != idl.LinkedNodeCommentType.block) {
        _result["comment_type"] = comment_type.toString().split('.')[1];
      }
    }
    if (kind == idl.LinkedNodeKind.commentReference) {
      if (commentReference_identifier != null) {
        _result["commentReference_identifier"] =
            commentReference_identifier.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      if (compilationUnit_declarations.isNotEmpty) {
        _result["compilationUnit_declarations"] = compilationUnit_declarations
            .map((_value) => _value.toJson())
            .toList();
      }
      if (compilationUnit_scriptTag != null) {
        _result["compilationUnit_scriptTag"] =
            compilationUnit_scriptTag.toJson();
      }
      if (compilationUnit_directives.isNotEmpty) {
        _result["compilationUnit_directives"] = compilationUnit_directives
            .map((_value) => _value.toJson())
            .toList();
      }
      if (compilationUnit_languageVersion != null) {
        _result["compilationUnit_languageVersion"] =
            compilationUnit_languageVersion.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.conditionalExpression) {
      if (conditionalExpression_condition != null) {
        _result["conditionalExpression_condition"] =
            conditionalExpression_condition.toJson();
      }
      if (conditionalExpression_elseExpression != null) {
        _result["conditionalExpression_elseExpression"] =
            conditionalExpression_elseExpression.toJson();
      }
      if (conditionalExpression_thenExpression != null) {
        _result["conditionalExpression_thenExpression"] =
            conditionalExpression_thenExpression.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.configuration) {
      if (configuration_name != null) {
        _result["configuration_name"] = configuration_name.toJson();
      }
      if (configuration_value != null) {
        _result["configuration_value"] = configuration_value.toJson();
      }
      if (configuration_uri != null) {
        _result["configuration_uri"] = configuration_uri.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      if (constructorDeclaration_initializers.isNotEmpty) {
        _result["constructorDeclaration_initializers"] =
            constructorDeclaration_initializers
                .map((_value) => _value.toJson())
                .toList();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (constructorDeclaration_body != null) {
        _result["constructorDeclaration_body"] =
            constructorDeclaration_body.toJson();
      }
      if (constructorDeclaration_parameters != null) {
        _result["constructorDeclaration_parameters"] =
            constructorDeclaration_parameters.toJson();
      }
      if (constructorDeclaration_redirectedConstructor != null) {
        _result["constructorDeclaration_redirectedConstructor"] =
            constructorDeclaration_redirectedConstructor.toJson();
      }
      if (constructorDeclaration_returnType != null) {
        _result["constructorDeclaration_returnType"] =
            constructorDeclaration_returnType.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      if (constructorFieldInitializer_expression != null) {
        _result["constructorFieldInitializer_expression"] =
            constructorFieldInitializer_expression.toJson();
      }
      if (constructorFieldInitializer_fieldName != null) {
        _result["constructorFieldInitializer_fieldName"] =
            constructorFieldInitializer_fieldName.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.constructorName) {
      if (constructorName_name != null) {
        _result["constructorName_name"] = constructorName_name.toJson();
      }
      if (constructorName_type != null) {
        _result["constructorName_type"] = constructorName_type.toJson();
      }
      if (constructorName_substitution != null) {
        _result["constructorName_substitution"] =
            constructorName_substitution.toJson();
      }
      if (constructorName_element != 0) {
        _result["constructorName_element"] = constructorName_element;
      }
    }
    if (kind == idl.LinkedNodeKind.continueStatement) {
      if (continueStatement_label != null) {
        _result["continueStatement_label"] = continueStatement_label.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (declaredIdentifier_identifier != null) {
        _result["declaredIdentifier_identifier"] =
            declaredIdentifier_identifier.toJson();
      }
      if (declaredIdentifier_type != null) {
        _result["declaredIdentifier_type"] = declaredIdentifier_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      if (defaultFormalParameter_defaultValue != null) {
        _result["defaultFormalParameter_defaultValue"] =
            defaultFormalParameter_defaultValue.toJson();
      }
      if (defaultFormalParameter_parameter != null) {
        _result["defaultFormalParameter_parameter"] =
            defaultFormalParameter_parameter.toJson();
      }
      if (defaultFormalParameter_kind !=
          idl.LinkedNodeFormalParameterKind.requiredPositional) {
        _result["defaultFormalParameter_kind"] =
            defaultFormalParameter_kind.toString().split('.')[1];
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.doStatement) {
      if (doStatement_body != null) {
        _result["doStatement_body"] = doStatement_body.toJson();
      }
      if (doStatement_condition != null) {
        _result["doStatement_condition"] = doStatement_condition.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.dottedName) {
      if (dottedName_components.isNotEmpty) {
        _result["dottedName_components"] =
            dottedName_components.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.doubleLiteral) {
      if (doubleLiteral_value != 0.0) {
        _result["doubleLiteral_value"] = doubleLiteral_value.isFinite
            ? doubleLiteral_value
            : doubleLiteral_value.toString();
      }
    }
    if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
      if (emptyFunctionBody_fake != 0) {
        _result["emptyFunctionBody_fake"] = emptyFunctionBody_fake;
      }
    }
    if (kind == idl.LinkedNodeKind.emptyStatement) {
      if (emptyStatement_fake != 0) {
        _result["emptyStatement_fake"] = emptyStatement_fake;
      }
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      if (enumDeclaration_constants.isNotEmpty) {
        _result["enumDeclaration_constants"] =
            enumDeclaration_constants.map((_value) => _value.toJson()).toList();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      if (namespaceDirective_combinators.isNotEmpty) {
        _result["namespaceDirective_combinators"] =
            namespaceDirective_combinators
                .map((_value) => _value.toJson())
                .toList();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (namespaceDirective_configurations.isNotEmpty) {
        _result["namespaceDirective_configurations"] =
            namespaceDirective_configurations
                .map((_value) => _value.toJson())
                .toList();
      }
      if (namespaceDirective_selectedUri != '') {
        _result["namespaceDirective_selectedUri"] =
            namespaceDirective_selectedUri;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (uriBasedDirective_uri != null) {
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      }
      if (uriBasedDirective_uriContent != '') {
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
      }
      if (uriBasedDirective_uriElement != 0) {
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      }
    }
    if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      if (expressionFunctionBody_expression != null) {
        _result["expressionFunctionBody_expression"] =
            expressionFunctionBody_expression.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.expressionStatement) {
      if (expressionStatement_expression != null) {
        _result["expressionStatement_expression"] =
            expressionStatement_expression.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.extendsClause) {
      if (extendsClause_superclass != null) {
        _result["extendsClause_superclass"] = extendsClause_superclass.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (extensionDeclaration_typeParameters != null) {
        _result["extensionDeclaration_typeParameters"] =
            extensionDeclaration_typeParameters.toJson();
      }
      if (extensionDeclaration_extendedType != null) {
        _result["extensionDeclaration_extendedType"] =
            extensionDeclaration_extendedType.toJson();
      }
      if (extensionDeclaration_members.isNotEmpty) {
        _result["extensionDeclaration_members"] = extensionDeclaration_members
            .map((_value) => _value.toJson())
            .toList();
      }
      if (extensionDeclaration_refName != '') {
        _result["extensionDeclaration_refName"] = extensionDeclaration_refName;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.extensionOverride) {
      if (extensionOverride_extendedType != null) {
        _result["extensionOverride_extendedType"] =
            extensionOverride_extendedType.toJson();
      }
      if (extensionOverride_arguments.isNotEmpty) {
        _result["extensionOverride_arguments"] = extensionOverride_arguments
            .map((_value) => _value.toJson())
            .toList();
      }
      if (extensionOverride_extensionName != null) {
        _result["extensionOverride_extensionName"] =
            extensionOverride_extensionName.toJson();
      }
      if (extensionOverride_typeArguments != null) {
        _result["extensionOverride_typeArguments"] =
            extensionOverride_typeArguments.toJson();
      }
      if (extensionOverride_typeArgumentTypes.isNotEmpty) {
        _result["extensionOverride_typeArgumentTypes"] =
            extensionOverride_typeArgumentTypes
                .map((_value) => _value.toJson())
                .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (fieldDeclaration_fields != null) {
        _result["fieldDeclaration_fields"] = fieldDeclaration_fields.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      if (actualType != null) {
        _result["actualType"] = actualType.toJson();
      }
      if (normalFormalParameter_metadata.isNotEmpty) {
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      }
      if (fieldFormalParameter_type != null) {
        _result["fieldFormalParameter_type"] =
            fieldFormalParameter_type.toJson();
      }
      if (fieldFormalParameter_typeParameters != null) {
        _result["fieldFormalParameter_typeParameters"] =
            fieldFormalParameter_typeParameters.toJson();
      }
      if (fieldFormalParameter_formalParameters != null) {
        _result["fieldFormalParameter_formalParameters"] =
            fieldFormalParameter_formalParameters.toJson();
      }
      if (inheritsCovariant != false) {
        _result["inheritsCovariant"] = inheritsCovariant;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      if (forEachParts_iterable != null) {
        _result["forEachParts_iterable"] = forEachParts_iterable.toJson();
      }
      if (forEachPartsWithDeclaration_loopVariable != null) {
        _result["forEachPartsWithDeclaration_loopVariable"] =
            forEachPartsWithDeclaration_loopVariable.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      if (forEachParts_iterable != null) {
        _result["forEachParts_iterable"] = forEachParts_iterable.toJson();
      }
      if (forEachPartsWithIdentifier_identifier != null) {
        _result["forEachPartsWithIdentifier_identifier"] =
            forEachPartsWithIdentifier_identifier.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.forElement) {
      if (forMixin_forLoopParts != null) {
        _result["forMixin_forLoopParts"] = forMixin_forLoopParts.toJson();
      }
      if (forElement_body != null) {
        _result["forElement_body"] = forElement_body.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      if (forParts_condition != null) {
        _result["forParts_condition"] = forParts_condition.toJson();
      }
      if (forPartsWithDeclarations_variables != null) {
        _result["forPartsWithDeclarations_variables"] =
            forPartsWithDeclarations_variables.toJson();
      }
      if (forParts_updaters.isNotEmpty) {
        _result["forParts_updaters"] =
            forParts_updaters.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      if (forParts_condition != null) {
        _result["forParts_condition"] = forParts_condition.toJson();
      }
      if (forPartsWithExpression_initialization != null) {
        _result["forPartsWithExpression_initialization"] =
            forPartsWithExpression_initialization.toJson();
      }
      if (forParts_updaters.isNotEmpty) {
        _result["forParts_updaters"] =
            forParts_updaters.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.forStatement) {
      if (forMixin_forLoopParts != null) {
        _result["forMixin_forLoopParts"] = forMixin_forLoopParts.toJson();
      }
      if (forStatement_body != null) {
        _result["forStatement_body"] = forStatement_body.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.formalParameterList) {
      if (formalParameterList_parameters.isNotEmpty) {
        _result["formalParameterList_parameters"] =
            formalParameterList_parameters
                .map((_value) => _value.toJson())
                .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      if (actualReturnType != null) {
        _result["actualReturnType"] = actualReturnType.toJson();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (functionDeclaration_functionExpression != null) {
        _result["functionDeclaration_functionExpression"] =
            functionDeclaration_functionExpression.toJson();
      }
      if (functionDeclaration_returnType != null) {
        _result["functionDeclaration_returnType"] =
            functionDeclaration_returnType.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      if (functionDeclarationStatement_functionDeclaration != null) {
        _result["functionDeclarationStatement_functionDeclaration"] =
            functionDeclarationStatement_functionDeclaration.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.functionExpression) {
      if (actualReturnType != null) {
        _result["actualReturnType"] = actualReturnType.toJson();
      }
      if (functionExpression_body != null) {
        _result["functionExpression_body"] = functionExpression_body.toJson();
      }
      if (functionExpression_formalParameters != null) {
        _result["functionExpression_formalParameters"] =
            functionExpression_formalParameters.toJson();
      }
      if (functionExpression_typeParameters != null) {
        _result["functionExpression_typeParameters"] =
            functionExpression_typeParameters.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.functionExpressionInvocation) {
      if (invocationExpression_invokeType != null) {
        _result["invocationExpression_invokeType"] =
            invocationExpression_invokeType.toJson();
      }
      if (functionExpressionInvocation_function != null) {
        _result["functionExpressionInvocation_function"] =
            functionExpressionInvocation_function.toJson();
      }
      if (invocationExpression_typeArguments != null) {
        _result["invocationExpression_typeArguments"] =
            invocationExpression_typeArguments.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
      if (invocationExpression_arguments != null) {
        _result["invocationExpression_arguments"] =
            invocationExpression_arguments.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      if (actualReturnType != null) {
        _result["actualReturnType"] = actualReturnType.toJson();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (functionTypeAlias_formalParameters != null) {
        _result["functionTypeAlias_formalParameters"] =
            functionTypeAlias_formalParameters.toJson();
      }
      if (functionTypeAlias_returnType != null) {
        _result["functionTypeAlias_returnType"] =
            functionTypeAlias_returnType.toJson();
      }
      if (functionTypeAlias_typeParameters != null) {
        _result["functionTypeAlias_typeParameters"] =
            functionTypeAlias_typeParameters.toJson();
      }
      if (typeAlias_hasSelfReference != false) {
        _result["typeAlias_hasSelfReference"] = typeAlias_hasSelfReference;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (simplyBoundable_isSimplyBounded != false) {
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
      }
    }
    if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      if (actualType != null) {
        _result["actualType"] = actualType.toJson();
      }
      if (normalFormalParameter_metadata.isNotEmpty) {
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      }
      if (functionTypedFormalParameter_formalParameters != null) {
        _result["functionTypedFormalParameter_formalParameters"] =
            functionTypedFormalParameter_formalParameters.toJson();
      }
      if (functionTypedFormalParameter_returnType != null) {
        _result["functionTypedFormalParameter_returnType"] =
            functionTypedFormalParameter_returnType.toJson();
      }
      if (functionTypedFormalParameter_typeParameters != null) {
        _result["functionTypedFormalParameter_typeParameters"] =
            functionTypedFormalParameter_typeParameters.toJson();
      }
      if (inheritsCovariant != false) {
        _result["inheritsCovariant"] = inheritsCovariant;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.genericFunctionType) {
      if (actualReturnType != null) {
        _result["actualReturnType"] = actualReturnType.toJson();
      }
      if (genericFunctionType_typeParameters != null) {
        _result["genericFunctionType_typeParameters"] =
            genericFunctionType_typeParameters.toJson();
      }
      if (genericFunctionType_returnType != null) {
        _result["genericFunctionType_returnType"] =
            genericFunctionType_returnType.toJson();
      }
      if (genericFunctionType_id != 0) {
        _result["genericFunctionType_id"] = genericFunctionType_id;
      }
      if (genericFunctionType_formalParameters != null) {
        _result["genericFunctionType_formalParameters"] =
            genericFunctionType_formalParameters.toJson();
      }
      if (genericFunctionType_type != null) {
        _result["genericFunctionType_type"] = genericFunctionType_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (genericTypeAlias_typeParameters != null) {
        _result["genericTypeAlias_typeParameters"] =
            genericTypeAlias_typeParameters.toJson();
      }
      if (genericTypeAlias_functionType != null) {
        _result["genericTypeAlias_functionType"] =
            genericTypeAlias_functionType.toJson();
      }
      if (typeAlias_hasSelfReference != false) {
        _result["typeAlias_hasSelfReference"] = typeAlias_hasSelfReference;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (simplyBoundable_isSimplyBounded != false) {
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
      }
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (names.isNotEmpty) {
        _result["names"] = names;
      }
    }
    if (kind == idl.LinkedNodeKind.ifElement) {
      if (ifMixin_condition != null) {
        _result["ifMixin_condition"] = ifMixin_condition.toJson();
      }
      if (ifElement_thenElement != null) {
        _result["ifElement_thenElement"] = ifElement_thenElement.toJson();
      }
      if (ifElement_elseElement != null) {
        _result["ifElement_elseElement"] = ifElement_elseElement.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.ifStatement) {
      if (ifMixin_condition != null) {
        _result["ifMixin_condition"] = ifMixin_condition.toJson();
      }
      if (ifStatement_elseStatement != null) {
        _result["ifStatement_elseStatement"] =
            ifStatement_elseStatement.toJson();
      }
      if (ifStatement_thenStatement != null) {
        _result["ifStatement_thenStatement"] =
            ifStatement_thenStatement.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.implementsClause) {
      if (implementsClause_interfaces.isNotEmpty) {
        _result["implementsClause_interfaces"] = implementsClause_interfaces
            .map((_value) => _value.toJson())
            .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      if (namespaceDirective_combinators.isNotEmpty) {
        _result["namespaceDirective_combinators"] =
            namespaceDirective_combinators
                .map((_value) => _value.toJson())
                .toList();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (namespaceDirective_configurations.isNotEmpty) {
        _result["namespaceDirective_configurations"] =
            namespaceDirective_configurations
                .map((_value) => _value.toJson())
                .toList();
      }
      if (namespaceDirective_selectedUri != '') {
        _result["namespaceDirective_selectedUri"] =
            namespaceDirective_selectedUri;
      }
      if (importDirective_prefix != '') {
        _result["importDirective_prefix"] = importDirective_prefix;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (uriBasedDirective_uri != null) {
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      }
      if (uriBasedDirective_uriContent != '') {
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
      }
      if (uriBasedDirective_uriElement != 0) {
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      }
    }
    if (kind == idl.LinkedNodeKind.indexExpression) {
      if (indexExpression_index != null) {
        _result["indexExpression_index"] = indexExpression_index.toJson();
      }
      if (indexExpression_target != null) {
        _result["indexExpression_target"] = indexExpression_target.toJson();
      }
      if (indexExpression_substitution != null) {
        _result["indexExpression_substitution"] =
            indexExpression_substitution.toJson();
      }
      if (indexExpression_element != 0) {
        _result["indexExpression_element"] = indexExpression_element;
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      if (instanceCreationExpression_arguments.isNotEmpty) {
        _result["instanceCreationExpression_arguments"] =
            instanceCreationExpression_arguments
                .map((_value) => _value.toJson())
                .toList();
      }
      if (instanceCreationExpression_constructorName != null) {
        _result["instanceCreationExpression_constructorName"] =
            instanceCreationExpression_constructorName.toJson();
      }
      if (instanceCreationExpression_typeArguments != null) {
        _result["instanceCreationExpression_typeArguments"] =
            instanceCreationExpression_typeArguments.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.integerLiteral) {
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
      if (integerLiteral_value != 0) {
        _result["integerLiteral_value"] = integerLiteral_value;
      }
    }
    if (kind == idl.LinkedNodeKind.interpolationExpression) {
      if (interpolationExpression_expression != null) {
        _result["interpolationExpression_expression"] =
            interpolationExpression_expression.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.interpolationString) {
      if (interpolationString_value != '') {
        _result["interpolationString_value"] = interpolationString_value;
      }
    }
    if (kind == idl.LinkedNodeKind.isExpression) {
      if (isExpression_expression != null) {
        _result["isExpression_expression"] = isExpression_expression.toJson();
      }
      if (isExpression_type != null) {
        _result["isExpression_type"] = isExpression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.label) {
      if (label_label != null) {
        _result["label_label"] = label_label.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.labeledStatement) {
      if (labeledStatement_labels.isNotEmpty) {
        _result["labeledStatement_labels"] =
            labeledStatement_labels.map((_value) => _value.toJson()).toList();
      }
      if (labeledStatement_statement != null) {
        _result["labeledStatement_statement"] =
            labeledStatement_statement.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (libraryDirective_name != null) {
        _result["libraryDirective_name"] = libraryDirective_name.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      if (libraryIdentifier_components.isNotEmpty) {
        _result["libraryIdentifier_components"] = libraryIdentifier_components
            .map((_value) => _value.toJson())
            .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.listLiteral) {
      if (typedLiteral_typeArguments.isNotEmpty) {
        _result["typedLiteral_typeArguments"] = typedLiteral_typeArguments
            .map((_value) => _value.toJson())
            .toList();
      }
      if (listLiteral_elements.isNotEmpty) {
        _result["listLiteral_elements"] =
            listLiteral_elements.map((_value) => _value.toJson()).toList();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      if (mapLiteralEntry_key != null) {
        _result["mapLiteralEntry_key"] = mapLiteralEntry_key.toJson();
      }
      if (mapLiteralEntry_value != null) {
        _result["mapLiteralEntry_value"] = mapLiteralEntry_value.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      if (actualReturnType != null) {
        _result["actualReturnType"] = actualReturnType.toJson();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (methodDeclaration_body != null) {
        _result["methodDeclaration_body"] = methodDeclaration_body.toJson();
      }
      if (methodDeclaration_formalParameters != null) {
        _result["methodDeclaration_formalParameters"] =
            methodDeclaration_formalParameters.toJson();
      }
      if (methodDeclaration_returnType != null) {
        _result["methodDeclaration_returnType"] =
            methodDeclaration_returnType.toJson();
      }
      if (methodDeclaration_typeParameters != null) {
        _result["methodDeclaration_typeParameters"] =
            methodDeclaration_typeParameters.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (methodDeclaration_hasOperatorEqualWithParameterTypeFromObject !=
          false) {
        _result["methodDeclaration_hasOperatorEqualWithParameterTypeFromObject"] =
            methodDeclaration_hasOperatorEqualWithParameterTypeFromObject;
      }
      if (topLevelTypeInferenceError != null) {
        _result["topLevelTypeInferenceError"] =
            topLevelTypeInferenceError.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.methodInvocation) {
      if (invocationExpression_invokeType != null) {
        _result["invocationExpression_invokeType"] =
            invocationExpression_invokeType.toJson();
      }
      if (methodInvocation_methodName != null) {
        _result["methodInvocation_methodName"] =
            methodInvocation_methodName.toJson();
      }
      if (methodInvocation_target != null) {
        _result["methodInvocation_target"] = methodInvocation_target.toJson();
      }
      if (invocationExpression_typeArguments != null) {
        _result["invocationExpression_typeArguments"] =
            invocationExpression_typeArguments.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
      if (invocationExpression_arguments != null) {
        _result["invocationExpression_arguments"] =
            invocationExpression_arguments.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (mixinDeclaration_onClause != null) {
        _result["mixinDeclaration_onClause"] =
            mixinDeclaration_onClause.toJson();
      }
      if (classOrMixinDeclaration_implementsClause != null) {
        _result["classOrMixinDeclaration_implementsClause"] =
            classOrMixinDeclaration_implementsClause.toJson();
      }
      if (classOrMixinDeclaration_members.isNotEmpty) {
        _result["classOrMixinDeclaration_members"] =
            classOrMixinDeclaration_members
                .map((_value) => _value.toJson())
                .toList();
      }
      if (classOrMixinDeclaration_typeParameters != null) {
        _result["classOrMixinDeclaration_typeParameters"] =
            classOrMixinDeclaration_typeParameters.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (simplyBoundable_isSimplyBounded != false) {
        _result["simplyBoundable_isSimplyBounded"] =
            simplyBoundable_isSimplyBounded;
      }
      if (mixinDeclaration_superInvokedNames.isNotEmpty) {
        _result["mixinDeclaration_superInvokedNames"] =
            mixinDeclaration_superInvokedNames;
      }
    }
    if (kind == idl.LinkedNodeKind.namedExpression) {
      if (namedExpression_expression != null) {
        _result["namedExpression_expression"] =
            namedExpression_expression.toJson();
      }
      if (namedExpression_name != null) {
        _result["namedExpression_name"] = namedExpression_name.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.nativeClause) {
      if (nativeClause_name != null) {
        _result["nativeClause_name"] = nativeClause_name.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      if (nativeFunctionBody_stringLiteral != null) {
        _result["nativeFunctionBody_stringLiteral"] =
            nativeFunctionBody_stringLiteral.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.nullLiteral) {
      if (nullLiteral_fake != 0) {
        _result["nullLiteral_fake"] = nullLiteral_fake;
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.onClause) {
      if (onClause_superclassConstraints.isNotEmpty) {
        _result["onClause_superclassConstraints"] =
            onClause_superclassConstraints
                .map((_value) => _value.toJson())
                .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      if (parenthesizedExpression_expression != null) {
        _result["parenthesizedExpression_expression"] =
            parenthesizedExpression_expression.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (uriBasedDirective_uri != null) {
        _result["uriBasedDirective_uri"] = uriBasedDirective_uri.toJson();
      }
      if (uriBasedDirective_uriContent != '') {
        _result["uriBasedDirective_uriContent"] = uriBasedDirective_uriContent;
      }
      if (uriBasedDirective_uriElement != 0) {
        _result["uriBasedDirective_uriElement"] = uriBasedDirective_uriElement;
      }
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (partOfDirective_libraryName != null) {
        _result["partOfDirective_libraryName"] =
            partOfDirective_libraryName.toJson();
      }
      if (partOfDirective_uri != null) {
        _result["partOfDirective_uri"] = partOfDirective_uri.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.postfixExpression) {
      if (postfixExpression_operand != null) {
        _result["postfixExpression_operand"] =
            postfixExpression_operand.toJson();
      }
      if (postfixExpression_substitution != null) {
        _result["postfixExpression_substitution"] =
            postfixExpression_substitution.toJson();
      }
      if (postfixExpression_element != 0) {
        _result["postfixExpression_element"] = postfixExpression_element;
      }
      if (postfixExpression_operator != idl.UnlinkedTokenType.NOTHING) {
        _result["postfixExpression_operator"] =
            postfixExpression_operator.toString().split('.')[1];
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.prefixExpression) {
      if (prefixExpression_operand != null) {
        _result["prefixExpression_operand"] = prefixExpression_operand.toJson();
      }
      if (prefixExpression_substitution != null) {
        _result["prefixExpression_substitution"] =
            prefixExpression_substitution.toJson();
      }
      if (prefixExpression_element != 0) {
        _result["prefixExpression_element"] = prefixExpression_element;
      }
      if (prefixExpression_operator != idl.UnlinkedTokenType.NOTHING) {
        _result["prefixExpression_operator"] =
            prefixExpression_operator.toString().split('.')[1];
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      if (prefixedIdentifier_identifier != null) {
        _result["prefixedIdentifier_identifier"] =
            prefixedIdentifier_identifier.toJson();
      }
      if (prefixedIdentifier_prefix != null) {
        _result["prefixedIdentifier_prefix"] =
            prefixedIdentifier_prefix.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.propertyAccess) {
      if (propertyAccess_propertyName != null) {
        _result["propertyAccess_propertyName"] =
            propertyAccess_propertyName.toJson();
      }
      if (propertyAccess_target != null) {
        _result["propertyAccess_target"] = propertyAccess_target.toJson();
      }
      if (propertyAccess_operator != idl.UnlinkedTokenType.NOTHING) {
        _result["propertyAccess_operator"] =
            propertyAccess_operator.toString().split('.')[1];
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      if (redirectingConstructorInvocation_arguments != null) {
        _result["redirectingConstructorInvocation_arguments"] =
            redirectingConstructorInvocation_arguments.toJson();
      }
      if (redirectingConstructorInvocation_constructorName != null) {
        _result["redirectingConstructorInvocation_constructorName"] =
            redirectingConstructorInvocation_constructorName.toJson();
      }
      if (redirectingConstructorInvocation_substitution != null) {
        _result["redirectingConstructorInvocation_substitution"] =
            redirectingConstructorInvocation_substitution.toJson();
      }
      if (redirectingConstructorInvocation_element != 0) {
        _result["redirectingConstructorInvocation_element"] =
            redirectingConstructorInvocation_element;
      }
    }
    if (kind == idl.LinkedNodeKind.rethrowExpression) {
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.returnStatement) {
      if (returnStatement_expression != null) {
        _result["returnStatement_expression"] =
            returnStatement_expression.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      if (typedLiteral_typeArguments.isNotEmpty) {
        _result["typedLiteral_typeArguments"] = typedLiteral_typeArguments
            .map((_value) => _value.toJson())
            .toList();
      }
      if (setOrMapLiteral_elements.isNotEmpty) {
        _result["setOrMapLiteral_elements"] =
            setOrMapLiteral_elements.map((_value) => _value.toJson()).toList();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (names.isNotEmpty) {
        _result["names"] = names;
      }
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      if (actualType != null) {
        _result["actualType"] = actualType.toJson();
      }
      if (normalFormalParameter_metadata.isNotEmpty) {
        _result["normalFormalParameter_metadata"] =
            normalFormalParameter_metadata
                .map((_value) => _value.toJson())
                .toList();
      }
      if (simpleFormalParameter_type != null) {
        _result["simpleFormalParameter_type"] =
            simpleFormalParameter_type.toJson();
      }
      if (inheritsCovariant != false) {
        _result["inheritsCovariant"] = inheritsCovariant;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (topLevelTypeInferenceError != null) {
        _result["topLevelTypeInferenceError"] =
            topLevelTypeInferenceError.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      if (simpleIdentifier_substitution != null) {
        _result["simpleIdentifier_substitution"] =
            simpleIdentifier_substitution.toJson();
      }
      if (simpleIdentifier_element != 0) {
        _result["simpleIdentifier_element"] = simpleIdentifier_element;
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
      if (simpleStringLiteral_value != '') {
        _result["simpleStringLiteral_value"] = simpleStringLiteral_value;
      }
    }
    if (kind == idl.LinkedNodeKind.spreadElement) {
      if (spreadElement_expression != null) {
        _result["spreadElement_expression"] = spreadElement_expression.toJson();
      }
      if (spreadElement_spreadOperator != idl.UnlinkedTokenType.NOTHING) {
        _result["spreadElement_spreadOperator"] =
            spreadElement_spreadOperator.toString().split('.')[1];
      }
    }
    if (kind == idl.LinkedNodeKind.stringInterpolation) {
      if (stringInterpolation_elements.isNotEmpty) {
        _result["stringInterpolation_elements"] = stringInterpolation_elements
            .map((_value) => _value.toJson())
            .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      if (superConstructorInvocation_arguments != null) {
        _result["superConstructorInvocation_arguments"] =
            superConstructorInvocation_arguments.toJson();
      }
      if (superConstructorInvocation_constructorName != null) {
        _result["superConstructorInvocation_constructorName"] =
            superConstructorInvocation_constructorName.toJson();
      }
      if (superConstructorInvocation_substitution != null) {
        _result["superConstructorInvocation_substitution"] =
            superConstructorInvocation_substitution.toJson();
      }
      if (superConstructorInvocation_element != 0) {
        _result["superConstructorInvocation_element"] =
            superConstructorInvocation_element;
      }
    }
    if (kind == idl.LinkedNodeKind.superExpression) {
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.switchCase) {
      if (switchMember_statements.isNotEmpty) {
        _result["switchMember_statements"] =
            switchMember_statements.map((_value) => _value.toJson()).toList();
      }
      if (switchCase_expression != null) {
        _result["switchCase_expression"] = switchCase_expression.toJson();
      }
      if (switchMember_labels.isNotEmpty) {
        _result["switchMember_labels"] =
            switchMember_labels.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.switchDefault) {
      if (switchMember_statements.isNotEmpty) {
        _result["switchMember_statements"] =
            switchMember_statements.map((_value) => _value.toJson()).toList();
      }
      if (switchMember_labels.isNotEmpty) {
        _result["switchMember_labels"] =
            switchMember_labels.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.switchStatement) {
      if (switchStatement_members.isNotEmpty) {
        _result["switchStatement_members"] =
            switchStatement_members.map((_value) => _value.toJson()).toList();
      }
      if (switchStatement_expression != null) {
        _result["switchStatement_expression"] =
            switchStatement_expression.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.symbolLiteral) {
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
      if (names.isNotEmpty) {
        _result["names"] = names;
      }
    }
    if (kind == idl.LinkedNodeKind.thisExpression) {
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.throwExpression) {
      if (throwExpression_expression != null) {
        _result["throwExpression_expression"] =
            throwExpression_expression.toJson();
      }
      if (expression_type != null) {
        _result["expression_type"] = expression_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (topLevelVariableDeclaration_variableList != null) {
        _result["topLevelVariableDeclaration_variableList"] =
            topLevelVariableDeclaration_variableList.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.tryStatement) {
      if (tryStatement_catchClauses.isNotEmpty) {
        _result["tryStatement_catchClauses"] =
            tryStatement_catchClauses.map((_value) => _value.toJson()).toList();
      }
      if (tryStatement_body != null) {
        _result["tryStatement_body"] = tryStatement_body.toJson();
      }
      if (tryStatement_finallyBlock != null) {
        _result["tryStatement_finallyBlock"] =
            tryStatement_finallyBlock.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.typeArgumentList) {
      if (typeArgumentList_arguments.isNotEmpty) {
        _result["typeArgumentList_arguments"] = typeArgumentList_arguments
            .map((_value) => _value.toJson())
            .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.typeName) {
      if (typeName_typeArguments.isNotEmpty) {
        _result["typeName_typeArguments"] =
            typeName_typeArguments.map((_value) => _value.toJson()).toList();
      }
      if (typeName_name != null) {
        _result["typeName_name"] = typeName_name.toJson();
      }
      if (typeName_type != null) {
        _result["typeName_type"] = typeName_type.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (typeParameter_bound != null) {
        _result["typeParameter_bound"] = typeParameter_bound.toJson();
      }
      if (typeParameter_variance != idl.UnlinkedTokenType.NOTHING) {
        _result["typeParameter_variance"] =
            typeParameter_variance.toString().split('.')[1];
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (typeParameter_defaultType != null) {
        _result["typeParameter_defaultType"] =
            typeParameter_defaultType.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.typeParameterList) {
      if (typeParameterList_typeParameters.isNotEmpty) {
        _result["typeParameterList_typeParameters"] =
            typeParameterList_typeParameters
                .map((_value) => _value.toJson())
                .toList();
      }
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      if (actualType != null) {
        _result["actualType"] = actualType.toJson();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (variableDeclaration_initializer != null) {
        _result["variableDeclaration_initializer"] =
            variableDeclaration_initializer.toJson();
      }
      if (inheritsCovariant != false) {
        _result["inheritsCovariant"] = inheritsCovariant;
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
      if (topLevelTypeInferenceError != null) {
        _result["topLevelTypeInferenceError"] =
            topLevelTypeInferenceError.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      if (variableDeclarationList_variables.isNotEmpty) {
        _result["variableDeclarationList_variables"] =
            variableDeclarationList_variables
                .map((_value) => _value.toJson())
                .toList();
      }
      if (annotatedNode_metadata.isNotEmpty) {
        _result["annotatedNode_metadata"] =
            annotatedNode_metadata.map((_value) => _value.toJson()).toList();
      }
      if (variableDeclarationList_type != null) {
        _result["variableDeclarationList_type"] =
            variableDeclarationList_type.toJson();
      }
      if (informativeId != 0) {
        _result["informativeId"] = informativeId;
      }
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      if (variableDeclarationStatement_variables != null) {
        _result["variableDeclarationStatement_variables"] =
            variableDeclarationStatement_variables.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.whileStatement) {
      if (whileStatement_body != null) {
        _result["whileStatement_body"] = whileStatement_body.toJson();
      }
      if (whileStatement_condition != null) {
        _result["whileStatement_condition"] = whileStatement_condition.toJson();
      }
    }
    if (kind == idl.LinkedNodeKind.withClause) {
      if (withClause_mixinTypes.isNotEmpty) {
        _result["withClause_mixinTypes"] =
            withClause_mixinTypes.map((_value) => _value.toJson()).toList();
      }
    }
    if (kind == idl.LinkedNodeKind.yieldStatement) {
      if (yieldStatement_expression != null) {
        _result["yieldStatement_expression"] =
            yieldStatement_expression.toJson();
      }
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() {
    if (kind == idl.LinkedNodeKind.adjacentStrings) {
      return {
        "adjacentStrings_strings": adjacentStrings_strings,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.annotation) {
      return {
        "annotation_arguments": annotation_arguments,
        "annotation_constructorName": annotation_constructorName,
        "annotation_element": annotation_element,
        "annotation_name": annotation_name,
        "annotation_substitution": annotation_substitution,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.argumentList) {
      return {
        "argumentList_arguments": argumentList_arguments,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.asExpression) {
      return {
        "asExpression_expression": asExpression_expression,
        "asExpression_type": asExpression_type,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.assertInitializer) {
      return {
        "assertInitializer_condition": assertInitializer_condition,
        "assertInitializer_message": assertInitializer_message,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.assertStatement) {
      return {
        "assertStatement_condition": assertStatement_condition,
        "assertStatement_message": assertStatement_message,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.assignmentExpression) {
      return {
        "assignmentExpression_leftHandSide": assignmentExpression_leftHandSide,
        "assignmentExpression_rightHandSide":
            assignmentExpression_rightHandSide,
        "assignmentExpression_substitution": assignmentExpression_substitution,
        "assignmentExpression_element": assignmentExpression_element,
        "assignmentExpression_operator": assignmentExpression_operator,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.awaitExpression) {
      return {
        "awaitExpression_expression": awaitExpression_expression,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.binaryExpression) {
      return {
        "binaryExpression_invokeType": binaryExpression_invokeType,
        "binaryExpression_leftOperand": binaryExpression_leftOperand,
        "binaryExpression_rightOperand": binaryExpression_rightOperand,
        "binaryExpression_substitution": binaryExpression_substitution,
        "binaryExpression_element": binaryExpression_element,
        "binaryExpression_operator": binaryExpression_operator,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.block) {
      return {
        "block_statements": block_statements,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.blockFunctionBody) {
      return {
        "blockFunctionBody_block": blockFunctionBody_block,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.booleanLiteral) {
      return {
        "booleanLiteral_value": booleanLiteral_value,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.breakStatement) {
      return {
        "breakStatement_label": breakStatement_label,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.cascadeExpression) {
      return {
        "cascadeExpression_sections": cascadeExpression_sections,
        "cascadeExpression_target": cascadeExpression_target,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.catchClause) {
      return {
        "catchClause_body": catchClause_body,
        "catchClause_exceptionParameter": catchClause_exceptionParameter,
        "catchClause_exceptionType": catchClause_exceptionType,
        "catchClause_stackTraceParameter": catchClause_stackTraceParameter,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "classDeclaration_extendsClause": classDeclaration_extendsClause,
        "classDeclaration_withClause": classDeclaration_withClause,
        "classDeclaration_nativeClause": classDeclaration_nativeClause,
        "classDeclaration_isDartObject": classDeclaration_isDartObject,
        "classOrMixinDeclaration_implementsClause":
            classOrMixinDeclaration_implementsClause,
        "classOrMixinDeclaration_members": classOrMixinDeclaration_members,
        "classOrMixinDeclaration_typeParameters":
            classOrMixinDeclaration_typeParameters,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
        "name": name,
        "unused11": unused11,
      };
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "classTypeAlias_typeParameters": classTypeAlias_typeParameters,
        "classTypeAlias_superclass": classTypeAlias_superclass,
        "classTypeAlias_withClause": classTypeAlias_withClause,
        "classTypeAlias_implementsClause": classTypeAlias_implementsClause,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.comment) {
      return {
        "comment_references": comment_references,
        "comment_tokens": comment_tokens,
        "comment_type": comment_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.commentReference) {
      return {
        "commentReference_identifier": commentReference_identifier,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      return {
        "compilationUnit_declarations": compilationUnit_declarations,
        "compilationUnit_scriptTag": compilationUnit_scriptTag,
        "compilationUnit_directives": compilationUnit_directives,
        "compilationUnit_languageVersion": compilationUnit_languageVersion,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.conditionalExpression) {
      return {
        "conditionalExpression_condition": conditionalExpression_condition,
        "conditionalExpression_elseExpression":
            conditionalExpression_elseExpression,
        "conditionalExpression_thenExpression":
            conditionalExpression_thenExpression,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.configuration) {
      return {
        "configuration_name": configuration_name,
        "configuration_value": configuration_value,
        "configuration_uri": configuration_uri,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      return {
        "constructorDeclaration_initializers":
            constructorDeclaration_initializers,
        "annotatedNode_metadata": annotatedNode_metadata,
        "constructorDeclaration_body": constructorDeclaration_body,
        "constructorDeclaration_parameters": constructorDeclaration_parameters,
        "constructorDeclaration_redirectedConstructor":
            constructorDeclaration_redirectedConstructor,
        "constructorDeclaration_returnType": constructorDeclaration_returnType,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorFieldInitializer) {
      return {
        "constructorFieldInitializer_expression":
            constructorFieldInitializer_expression,
        "constructorFieldInitializer_fieldName":
            constructorFieldInitializer_fieldName,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorName) {
      return {
        "constructorName_name": constructorName_name,
        "constructorName_type": constructorName_type,
        "constructorName_substitution": constructorName_substitution,
        "constructorName_element": constructorName_element,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.continueStatement) {
      return {
        "continueStatement_label": continueStatement_label,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.declaredIdentifier) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "declaredIdentifier_identifier": declaredIdentifier_identifier,
        "declaredIdentifier_type": declaredIdentifier_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      return {
        "defaultFormalParameter_defaultValue":
            defaultFormalParameter_defaultValue,
        "defaultFormalParameter_parameter": defaultFormalParameter_parameter,
        "defaultFormalParameter_kind": defaultFormalParameter_kind,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.doStatement) {
      return {
        "doStatement_body": doStatement_body,
        "doStatement_condition": doStatement_condition,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.dottedName) {
      return {
        "dottedName_components": dottedName_components,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.doubleLiteral) {
      return {
        "doubleLiteral_value": doubleLiteral_value,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.emptyFunctionBody) {
      return {
        "emptyFunctionBody_fake": emptyFunctionBody_fake,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.emptyStatement) {
      return {
        "emptyStatement_fake": emptyStatement_fake,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      return {
        "enumDeclaration_constants": enumDeclaration_constants,
        "annotatedNode_metadata": annotatedNode_metadata,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      return {
        "namespaceDirective_combinators": namespaceDirective_combinators,
        "annotatedNode_metadata": annotatedNode_metadata,
        "namespaceDirective_configurations": namespaceDirective_configurations,
        "namespaceDirective_selectedUri": namespaceDirective_selectedUri,
        "flags": flags,
        "informativeId": informativeId,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "kind": kind,
        "name": name,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
      };
    }
    if (kind == idl.LinkedNodeKind.expressionFunctionBody) {
      return {
        "expressionFunctionBody_expression": expressionFunctionBody_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.expressionStatement) {
      return {
        "expressionStatement_expression": expressionStatement_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.extendsClause) {
      return {
        "extendsClause_superclass": extendsClause_superclass,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "extensionDeclaration_typeParameters":
            extensionDeclaration_typeParameters,
        "extensionDeclaration_extendedType": extensionDeclaration_extendedType,
        "extensionDeclaration_members": extensionDeclaration_members,
        "extensionDeclaration_refName": extensionDeclaration_refName,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.extensionOverride) {
      return {
        "extensionOverride_extendedType": extensionOverride_extendedType,
        "extensionOverride_arguments": extensionOverride_arguments,
        "extensionOverride_extensionName": extensionOverride_extensionName,
        "extensionOverride_typeArguments": extensionOverride_typeArguments,
        "extensionOverride_typeArgumentTypes":
            extensionOverride_typeArgumentTypes,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "fieldDeclaration_fields": fieldDeclaration_fields,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      return {
        "actualType": actualType,
        "normalFormalParameter_metadata": normalFormalParameter_metadata,
        "fieldFormalParameter_type": fieldFormalParameter_type,
        "fieldFormalParameter_typeParameters":
            fieldFormalParameter_typeParameters,
        "fieldFormalParameter_formalParameters":
            fieldFormalParameter_formalParameters,
        "inheritsCovariant": inheritsCovariant,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithDeclaration) {
      return {
        "forEachParts_iterable": forEachParts_iterable,
        "forEachPartsWithDeclaration_loopVariable":
            forEachPartsWithDeclaration_loopVariable,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forEachPartsWithIdentifier) {
      return {
        "forEachParts_iterable": forEachParts_iterable,
        "forEachPartsWithIdentifier_identifier":
            forEachPartsWithIdentifier_identifier,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forElement) {
      return {
        "forMixin_forLoopParts": forMixin_forLoopParts,
        "forElement_body": forElement_body,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forPartsWithDeclarations) {
      return {
        "forParts_condition": forParts_condition,
        "forPartsWithDeclarations_variables":
            forPartsWithDeclarations_variables,
        "forParts_updaters": forParts_updaters,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forPartsWithExpression) {
      return {
        "forParts_condition": forParts_condition,
        "forPartsWithExpression_initialization":
            forPartsWithExpression_initialization,
        "forParts_updaters": forParts_updaters,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.forStatement) {
      return {
        "forMixin_forLoopParts": forMixin_forLoopParts,
        "forStatement_body": forStatement_body,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.formalParameterList) {
      return {
        "formalParameterList_parameters": formalParameterList_parameters,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_metadata": annotatedNode_metadata,
        "functionDeclaration_functionExpression":
            functionDeclaration_functionExpression,
        "functionDeclaration_returnType": functionDeclaration_returnType,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.functionDeclarationStatement) {
      return {
        "functionDeclarationStatement_functionDeclaration":
            functionDeclarationStatement_functionDeclaration,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.functionExpression) {
      return {
        "actualReturnType": actualReturnType,
        "functionExpression_body": functionExpression_body,
        "functionExpression_formalParameters":
            functionExpression_formalParameters,
        "functionExpression_typeParameters": functionExpression_typeParameters,
        "flags": flags,
        "kind": kind,
        "name": name,
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
        "flags": flags,
        "invocationExpression_arguments": invocationExpression_arguments,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_metadata": annotatedNode_metadata,
        "functionTypeAlias_formalParameters":
            functionTypeAlias_formalParameters,
        "functionTypeAlias_returnType": functionTypeAlias_returnType,
        "functionTypeAlias_typeParameters": functionTypeAlias_typeParameters,
        "typeAlias_hasSelfReference": typeAlias_hasSelfReference,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
        "name": name,
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
        "inheritsCovariant": inheritsCovariant,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.genericFunctionType) {
      return {
        "actualReturnType": actualReturnType,
        "genericFunctionType_typeParameters":
            genericFunctionType_typeParameters,
        "genericFunctionType_returnType": genericFunctionType_returnType,
        "genericFunctionType_id": genericFunctionType_id,
        "genericFunctionType_formalParameters":
            genericFunctionType_formalParameters,
        "genericFunctionType_type": genericFunctionType_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "genericTypeAlias_typeParameters": genericTypeAlias_typeParameters,
        "genericTypeAlias_functionType": genericTypeAlias_functionType,
        "typeAlias_hasSelfReference": typeAlias_hasSelfReference,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      return {
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "names": names,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.ifElement) {
      return {
        "ifMixin_condition": ifMixin_condition,
        "ifElement_thenElement": ifElement_thenElement,
        "ifElement_elseElement": ifElement_elseElement,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.ifStatement) {
      return {
        "ifMixin_condition": ifMixin_condition,
        "ifStatement_elseStatement": ifStatement_elseStatement,
        "ifStatement_thenStatement": ifStatement_thenStatement,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.implementsClause) {
      return {
        "implementsClause_interfaces": implementsClause_interfaces,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      return {
        "namespaceDirective_combinators": namespaceDirective_combinators,
        "annotatedNode_metadata": annotatedNode_metadata,
        "namespaceDirective_configurations": namespaceDirective_configurations,
        "namespaceDirective_selectedUri": namespaceDirective_selectedUri,
        "flags": flags,
        "importDirective_prefix": importDirective_prefix,
        "informativeId": informativeId,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "kind": kind,
        "name": name,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
      };
    }
    if (kind == idl.LinkedNodeKind.indexExpression) {
      return {
        "indexExpression_index": indexExpression_index,
        "indexExpression_target": indexExpression_target,
        "indexExpression_substitution": indexExpression_substitution,
        "indexExpression_element": indexExpression_element,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.instanceCreationExpression) {
      return {
        "instanceCreationExpression_arguments":
            instanceCreationExpression_arguments,
        "instanceCreationExpression_constructorName":
            instanceCreationExpression_constructorName,
        "instanceCreationExpression_typeArguments":
            instanceCreationExpression_typeArguments,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.integerLiteral) {
      return {
        "expression_type": expression_type,
        "flags": flags,
        "integerLiteral_value": integerLiteral_value,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.interpolationExpression) {
      return {
        "interpolationExpression_expression":
            interpolationExpression_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.interpolationString) {
      return {
        "flags": flags,
        "interpolationString_value": interpolationString_value,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.isExpression) {
      return {
        "isExpression_expression": isExpression_expression,
        "isExpression_type": isExpression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.label) {
      return {
        "label_label": label_label,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.labeledStatement) {
      return {
        "labeledStatement_labels": labeledStatement_labels,
        "labeledStatement_statement": labeledStatement_statement,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "libraryDirective_name": libraryDirective_name,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.libraryIdentifier) {
      return {
        "libraryIdentifier_components": libraryIdentifier_components,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.listLiteral) {
      return {
        "typedLiteral_typeArguments": typedLiteral_typeArguments,
        "listLiteral_elements": listLiteral_elements,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.mapLiteralEntry) {
      return {
        "mapLiteralEntry_key": mapLiteralEntry_key,
        "mapLiteralEntry_value": mapLiteralEntry_value,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      return {
        "actualReturnType": actualReturnType,
        "annotatedNode_metadata": annotatedNode_metadata,
        "methodDeclaration_body": methodDeclaration_body,
        "methodDeclaration_formalParameters":
            methodDeclaration_formalParameters,
        "methodDeclaration_returnType": methodDeclaration_returnType,
        "methodDeclaration_typeParameters": methodDeclaration_typeParameters,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "methodDeclaration_hasOperatorEqualWithParameterTypeFromObject":
            methodDeclaration_hasOperatorEqualWithParameterTypeFromObject,
        "name": name,
        "topLevelTypeInferenceError": topLevelTypeInferenceError,
      };
    }
    if (kind == idl.LinkedNodeKind.methodInvocation) {
      return {
        "invocationExpression_invokeType": invocationExpression_invokeType,
        "methodInvocation_methodName": methodInvocation_methodName,
        "methodInvocation_target": methodInvocation_target,
        "invocationExpression_typeArguments":
            invocationExpression_typeArguments,
        "expression_type": expression_type,
        "flags": flags,
        "invocationExpression_arguments": invocationExpression_arguments,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "mixinDeclaration_onClause": mixinDeclaration_onClause,
        "classOrMixinDeclaration_implementsClause":
            classOrMixinDeclaration_implementsClause,
        "classOrMixinDeclaration_members": classOrMixinDeclaration_members,
        "classOrMixinDeclaration_typeParameters":
            classOrMixinDeclaration_typeParameters,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "simplyBoundable_isSimplyBounded": simplyBoundable_isSimplyBounded,
        "mixinDeclaration_superInvokedNames":
            mixinDeclaration_superInvokedNames,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.namedExpression) {
      return {
        "namedExpression_expression": namedExpression_expression,
        "namedExpression_name": namedExpression_name,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.nativeClause) {
      return {
        "nativeClause_name": nativeClause_name,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.nativeFunctionBody) {
      return {
        "nativeFunctionBody_stringLiteral": nativeFunctionBody_stringLiteral,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.nullLiteral) {
      return {
        "nullLiteral_fake": nullLiteral_fake,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.onClause) {
      return {
        "onClause_superclassConstraints": onClause_superclassConstraints,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.parenthesizedExpression) {
      return {
        "parenthesizedExpression_expression":
            parenthesizedExpression_expression,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "flags": flags,
        "informativeId": informativeId,
        "uriBasedDirective_uri": uriBasedDirective_uri,
        "kind": kind,
        "name": name,
        "uriBasedDirective_uriContent": uriBasedDirective_uriContent,
        "uriBasedDirective_uriElement": uriBasedDirective_uriElement,
      };
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "partOfDirective_libraryName": partOfDirective_libraryName,
        "partOfDirective_uri": partOfDirective_uri,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.postfixExpression) {
      return {
        "postfixExpression_operand": postfixExpression_operand,
        "postfixExpression_substitution": postfixExpression_substitution,
        "postfixExpression_element": postfixExpression_element,
        "postfixExpression_operator": postfixExpression_operator,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.prefixExpression) {
      return {
        "prefixExpression_operand": prefixExpression_operand,
        "prefixExpression_substitution": prefixExpression_substitution,
        "prefixExpression_element": prefixExpression_element,
        "prefixExpression_operator": prefixExpression_operator,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.prefixedIdentifier) {
      return {
        "prefixedIdentifier_identifier": prefixedIdentifier_identifier,
        "prefixedIdentifier_prefix": prefixedIdentifier_prefix,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.propertyAccess) {
      return {
        "propertyAccess_propertyName": propertyAccess_propertyName,
        "propertyAccess_target": propertyAccess_target,
        "propertyAccess_operator": propertyAccess_operator,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.redirectingConstructorInvocation) {
      return {
        "redirectingConstructorInvocation_arguments":
            redirectingConstructorInvocation_arguments,
        "redirectingConstructorInvocation_constructorName":
            redirectingConstructorInvocation_constructorName,
        "redirectingConstructorInvocation_substitution":
            redirectingConstructorInvocation_substitution,
        "redirectingConstructorInvocation_element":
            redirectingConstructorInvocation_element,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.rethrowExpression) {
      return {
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.returnStatement) {
      return {
        "returnStatement_expression": returnStatement_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.setOrMapLiteral) {
      return {
        "typedLiteral_typeArguments": typedLiteral_typeArguments,
        "setOrMapLiteral_elements": setOrMapLiteral_elements,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      return {
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "names": names,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      return {
        "actualType": actualType,
        "normalFormalParameter_metadata": normalFormalParameter_metadata,
        "simpleFormalParameter_type": simpleFormalParameter_type,
        "inheritsCovariant": inheritsCovariant,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
        "topLevelTypeInferenceError": topLevelTypeInferenceError,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleIdentifier) {
      return {
        "simpleIdentifier_substitution": simpleIdentifier_substitution,
        "simpleIdentifier_element": simpleIdentifier_element,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleStringLiteral) {
      return {
        "simpleStringLiteral_value": simpleStringLiteral_value,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.spreadElement) {
      return {
        "spreadElement_expression": spreadElement_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
        "spreadElement_spreadOperator": spreadElement_spreadOperator,
      };
    }
    if (kind == idl.LinkedNodeKind.stringInterpolation) {
      return {
        "stringInterpolation_elements": stringInterpolation_elements,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.superConstructorInvocation) {
      return {
        "superConstructorInvocation_arguments":
            superConstructorInvocation_arguments,
        "superConstructorInvocation_constructorName":
            superConstructorInvocation_constructorName,
        "superConstructorInvocation_substitution":
            superConstructorInvocation_substitution,
        "superConstructorInvocation_element":
            superConstructorInvocation_element,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.superExpression) {
      return {
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.switchCase) {
      return {
        "switchMember_statements": switchMember_statements,
        "switchCase_expression": switchCase_expression,
        "switchMember_labels": switchMember_labels,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.switchDefault) {
      return {
        "switchMember_statements": switchMember_statements,
        "switchMember_labels": switchMember_labels,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.switchStatement) {
      return {
        "switchStatement_members": switchStatement_members,
        "switchStatement_expression": switchStatement_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.symbolLiteral) {
      return {
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "names": names,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.thisExpression) {
      return {
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.throwExpression) {
      return {
        "throwExpression_expression": throwExpression_expression,
        "expression_type": expression_type,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "topLevelVariableDeclaration_variableList":
            topLevelVariableDeclaration_variableList,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.tryStatement) {
      return {
        "tryStatement_catchClauses": tryStatement_catchClauses,
        "tryStatement_body": tryStatement_body,
        "tryStatement_finallyBlock": tryStatement_finallyBlock,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.typeArgumentList) {
      return {
        "typeArgumentList_arguments": typeArgumentList_arguments,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.typeName) {
      return {
        "typeName_typeArguments": typeName_typeArguments,
        "typeName_name": typeName_name,
        "flags": flags,
        "kind": kind,
        "name": name,
        "typeName_type": typeName_type,
      };
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      return {
        "annotatedNode_metadata": annotatedNode_metadata,
        "typeParameter_bound": typeParameter_bound,
        "typeParameter_variance": typeParameter_variance,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
        "typeParameter_defaultType": typeParameter_defaultType,
      };
    }
    if (kind == idl.LinkedNodeKind.typeParameterList) {
      return {
        "typeParameterList_typeParameters": typeParameterList_typeParameters,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      return {
        "actualType": actualType,
        "annotatedNode_metadata": annotatedNode_metadata,
        "variableDeclaration_initializer": variableDeclaration_initializer,
        "inheritsCovariant": inheritsCovariant,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
        "topLevelTypeInferenceError": topLevelTypeInferenceError,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationList) {
      return {
        "variableDeclarationList_variables": variableDeclarationList_variables,
        "annotatedNode_metadata": annotatedNode_metadata,
        "variableDeclarationList_type": variableDeclarationList_type,
        "flags": flags,
        "informativeId": informativeId,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclarationStatement) {
      return {
        "variableDeclarationStatement_variables":
            variableDeclarationStatement_variables,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.whileStatement) {
      return {
        "whileStatement_body": whileStatement_body,
        "whileStatement_condition": whileStatement_condition,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.withClause) {
      return {
        "withClause_mixinTypes": withClause_mixinTypes,
        "flags": flags,
        "kind": kind,
        "name": name,
      };
    }
    if (kind == idl.LinkedNodeKind.yieldStatement) {
      return {
        "yieldStatement_expression": yieldStatement_expression,
        "flags": flags,
        "kind": kind,
        "name": name,
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
    fb.Builder fbBuilder = fb.Builder();
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
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _LinkedNodeBundleReader().read(rootRef, 0);
}

class _LinkedNodeBundleReader extends fb.TableReader<_LinkedNodeBundleImpl> {
  const _LinkedNodeBundleReader();

  @override
  _LinkedNodeBundleImpl createObject(fb.BufferContext bc, int offset) =>
      _LinkedNodeBundleImpl(bc, offset);
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
    _libraries ??=
        const fb.ListReader<idl.LinkedNodeLibrary>(_LinkedNodeLibraryReader())
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
    if (libraries.isNotEmpty) {
      _result["libraries"] =
          libraries.map((_value) => _value.toJson()).toList();
    }
    if (references != null) {
      _result["references"] = references.toJson();
    }
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
      _LinkedNodeLibraryImpl(bc, offset);
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
    _units ??= const fb.ListReader<idl.LinkedNodeUnit>(_LinkedNodeUnitReader())
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
    if (exports.isNotEmpty) {
      _result["exports"] = exports;
    }
    if (name != '') {
      _result["name"] = name;
    }
    if (nameLength != 0) {
      _result["nameLength"] = nameLength;
    }
    if (nameOffset != 0) {
      _result["nameOffset"] = nameOffset;
    }
    if (units.isNotEmpty) {
      _result["units"] = units.map((_value) => _value.toJson()).toList();
    }
    if (uriStr != '') {
      _result["uriStr"] = uriStr;
    }
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
      _LinkedNodeReferencesImpl(bc, offset);
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
    _name ??= const fb.ListReader<String>(fb.StringReader())
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
    if (name.isNotEmpty) {
      _result["name"] = name;
    }
    if (parent.isNotEmpty) {
      _result["parent"] = parent;
    }
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
  int _functionTypedef;
  List<LinkedNodeTypeBuilder> _functionTypedefTypeArguments;
  List<LinkedNodeTypeTypeParameterBuilder> _functionTypeParameters;
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
  int get functionTypedef => _functionTypedef ??= 0;

  /// The typedef this function type is created for.
  set functionTypedef(int value) {
    assert(value == null || value >= 0);
    this._functionTypedef = value;
  }

  @override
  List<LinkedNodeTypeBuilder> get functionTypedefTypeArguments =>
      _functionTypedefTypeArguments ??= <LinkedNodeTypeBuilder>[];

  set functionTypedefTypeArguments(List<LinkedNodeTypeBuilder> value) {
    this._functionTypedefTypeArguments = value;
  }

  @override
  List<LinkedNodeTypeTypeParameterBuilder> get functionTypeParameters =>
      _functionTypeParameters ??= <LinkedNodeTypeTypeParameterBuilder>[];

  set functionTypeParameters(List<LinkedNodeTypeTypeParameterBuilder> value) {
    this._functionTypeParameters = value;
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
      int functionTypedef,
      List<LinkedNodeTypeBuilder> functionTypedefTypeArguments,
      List<LinkedNodeTypeTypeParameterBuilder> functionTypeParameters,
      int interfaceClass,
      List<LinkedNodeTypeBuilder> interfaceTypeArguments,
      idl.LinkedNodeTypeKind kind,
      idl.EntityRefNullabilitySuffix nullabilitySuffix,
      int typeParameterElement,
      int typeParameterId})
      : _functionFormalParameters = functionFormalParameters,
        _functionReturnType = functionReturnType,
        _functionTypedef = functionTypedef,
        _functionTypedefTypeArguments = functionTypedefTypeArguments,
        _functionTypeParameters = functionTypeParameters,
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
    _functionTypedefTypeArguments?.forEach((b) => b.flushInformative());
    _functionTypeParameters?.forEach((b) => b.flushInformative());
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
    signature.addInt(
        this._nullabilitySuffix == null ? 0 : this._nullabilitySuffix.index);
    signature.addInt(this._functionTypedef ?? 0);
    if (this._functionTypedefTypeArguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._functionTypedefTypeArguments.length);
      for (var x in this._functionTypedefTypeArguments) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_functionFormalParameters;
    fb.Offset offset_functionReturnType;
    fb.Offset offset_functionTypedefTypeArguments;
    fb.Offset offset_functionTypeParameters;
    fb.Offset offset_interfaceTypeArguments;
    if (!(_functionFormalParameters == null ||
        _functionFormalParameters.isEmpty)) {
      offset_functionFormalParameters = fbBuilder.writeList(
          _functionFormalParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_functionReturnType != null) {
      offset_functionReturnType = _functionReturnType.finish(fbBuilder);
    }
    if (!(_functionTypedefTypeArguments == null ||
        _functionTypedefTypeArguments.isEmpty)) {
      offset_functionTypedefTypeArguments = fbBuilder.writeList(
          _functionTypedefTypeArguments
              .map((b) => b.finish(fbBuilder))
              .toList());
    }
    if (!(_functionTypeParameters == null || _functionTypeParameters.isEmpty)) {
      offset_functionTypeParameters = fbBuilder.writeList(
          _functionTypeParameters.map((b) => b.finish(fbBuilder)).toList());
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
    if (_functionTypedef != null && _functionTypedef != 0) {
      fbBuilder.addUint32(9, _functionTypedef);
    }
    if (offset_functionTypedefTypeArguments != null) {
      fbBuilder.addOffset(10, offset_functionTypedefTypeArguments);
    }
    if (offset_functionTypeParameters != null) {
      fbBuilder.addOffset(2, offset_functionTypeParameters);
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
      fbBuilder.addUint8(8, _nullabilitySuffix.index);
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
      _LinkedNodeTypeImpl(bc, offset);
}

class _LinkedNodeTypeImpl extends Object
    with _LinkedNodeTypeMixin
    implements idl.LinkedNodeType {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeTypeImpl(this._bc, this._bcOffset);

  List<idl.LinkedNodeTypeFormalParameter> _functionFormalParameters;
  idl.LinkedNodeType _functionReturnType;
  int _functionTypedef;
  List<idl.LinkedNodeType> _functionTypedefTypeArguments;
  List<idl.LinkedNodeTypeTypeParameter> _functionTypeParameters;
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
                _LinkedNodeTypeFormalParameterReader())
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
  int get functionTypedef {
    _functionTypedef ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _functionTypedef;
  }

  @override
  List<idl.LinkedNodeType> get functionTypedefTypeArguments {
    _functionTypedefTypeArguments ??=
        const fb.ListReader<idl.LinkedNodeType>(_LinkedNodeTypeReader())
            .vTableGet(_bc, _bcOffset, 10, const <idl.LinkedNodeType>[]);
    return _functionTypedefTypeArguments;
  }

  @override
  List<idl.LinkedNodeTypeTypeParameter> get functionTypeParameters {
    _functionTypeParameters ??=
        const fb.ListReader<idl.LinkedNodeTypeTypeParameter>(
                _LinkedNodeTypeTypeParameterReader())
            .vTableGet(
                _bc, _bcOffset, 2, const <idl.LinkedNodeTypeTypeParameter>[]);
    return _functionTypeParameters;
  }

  @override
  int get interfaceClass {
    _interfaceClass ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _interfaceClass;
  }

  @override
  List<idl.LinkedNodeType> get interfaceTypeArguments {
    _interfaceTypeArguments ??=
        const fb.ListReader<idl.LinkedNodeType>(_LinkedNodeTypeReader())
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
        _bc, _bcOffset, 8, idl.EntityRefNullabilitySuffix.starOrIrrelevant);
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
    if (functionFormalParameters.isNotEmpty) {
      _result["functionFormalParameters"] =
          functionFormalParameters.map((_value) => _value.toJson()).toList();
    }
    if (functionReturnType != null) {
      _result["functionReturnType"] = functionReturnType.toJson();
    }
    if (functionTypedef != 0) {
      _result["functionTypedef"] = functionTypedef;
    }
    if (functionTypedefTypeArguments.isNotEmpty) {
      _result["functionTypedefTypeArguments"] = functionTypedefTypeArguments
          .map((_value) => _value.toJson())
          .toList();
    }
    if (functionTypeParameters.isNotEmpty) {
      _result["functionTypeParameters"] =
          functionTypeParameters.map((_value) => _value.toJson()).toList();
    }
    if (interfaceClass != 0) {
      _result["interfaceClass"] = interfaceClass;
    }
    if (interfaceTypeArguments.isNotEmpty) {
      _result["interfaceTypeArguments"] =
          interfaceTypeArguments.map((_value) => _value.toJson()).toList();
    }
    if (kind != idl.LinkedNodeTypeKind.bottom) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    if (nullabilitySuffix != idl.EntityRefNullabilitySuffix.starOrIrrelevant) {
      _result["nullabilitySuffix"] = nullabilitySuffix.toString().split('.')[1];
    }
    if (typeParameterElement != 0) {
      _result["typeParameterElement"] = typeParameterElement;
    }
    if (typeParameterId != 0) {
      _result["typeParameterId"] = typeParameterId;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "functionFormalParameters": functionFormalParameters,
        "functionReturnType": functionReturnType,
        "functionTypedef": functionTypedef,
        "functionTypedefTypeArguments": functionTypedefTypeArguments,
        "functionTypeParameters": functionTypeParameters,
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
      _LinkedNodeTypeFormalParameterImpl(bc, offset);
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
    if (kind != idl.LinkedNodeFormalParameterKind.requiredPositional) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    if (name != '') {
      _result["name"] = name;
    }
    if (type != null) {
      _result["type"] = type.toJson();
    }
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

class LinkedNodeTypeSubstitutionBuilder extends Object
    with _LinkedNodeTypeSubstitutionMixin
    implements idl.LinkedNodeTypeSubstitution {
  bool _isLegacy;
  List<LinkedNodeTypeBuilder> _typeArguments;
  List<int> _typeParameters;

  @override
  bool get isLegacy => _isLegacy ??= false;

  set isLegacy(bool value) {
    this._isLegacy = value;
  }

  @override
  List<LinkedNodeTypeBuilder> get typeArguments =>
      _typeArguments ??= <LinkedNodeTypeBuilder>[];

  set typeArguments(List<LinkedNodeTypeBuilder> value) {
    this._typeArguments = value;
  }

  @override
  List<int> get typeParameters => _typeParameters ??= <int>[];

  set typeParameters(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._typeParameters = value;
  }

  LinkedNodeTypeSubstitutionBuilder(
      {bool isLegacy,
      List<LinkedNodeTypeBuilder> typeArguments,
      List<int> typeParameters})
      : _isLegacy = isLegacy,
        _typeArguments = typeArguments,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _typeArguments?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._typeParameters == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeParameters.length);
      for (var x in this._typeParameters) {
        signature.addInt(x);
      }
    }
    if (this._typeArguments == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._typeArguments.length);
      for (var x in this._typeArguments) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._isLegacy == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_typeArguments;
    fb.Offset offset_typeParameters;
    if (!(_typeArguments == null || _typeArguments.isEmpty)) {
      offset_typeArguments = fbBuilder
          .writeList(_typeArguments.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder.writeListUint32(_typeParameters);
    }
    fbBuilder.startTable();
    if (_isLegacy == true) {
      fbBuilder.addBool(2, true);
    }
    if (offset_typeArguments != null) {
      fbBuilder.addOffset(1, offset_typeArguments);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(0, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _LinkedNodeTypeSubstitutionReader
    extends fb.TableReader<_LinkedNodeTypeSubstitutionImpl> {
  const _LinkedNodeTypeSubstitutionReader();

  @override
  _LinkedNodeTypeSubstitutionImpl createObject(
          fb.BufferContext bc, int offset) =>
      _LinkedNodeTypeSubstitutionImpl(bc, offset);
}

class _LinkedNodeTypeSubstitutionImpl extends Object
    with _LinkedNodeTypeSubstitutionMixin
    implements idl.LinkedNodeTypeSubstitution {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeTypeSubstitutionImpl(this._bc, this._bcOffset);

  bool _isLegacy;
  List<idl.LinkedNodeType> _typeArguments;
  List<int> _typeParameters;

  @override
  bool get isLegacy {
    _isLegacy ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isLegacy;
  }

  @override
  List<idl.LinkedNodeType> get typeArguments {
    _typeArguments ??=
        const fb.ListReader<idl.LinkedNodeType>(_LinkedNodeTypeReader())
            .vTableGet(_bc, _bcOffset, 1, const <idl.LinkedNodeType>[]);
    return _typeArguments;
  }

  @override
  List<int> get typeParameters {
    _typeParameters ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _typeParameters;
  }
}

abstract class _LinkedNodeTypeSubstitutionMixin
    implements idl.LinkedNodeTypeSubstitution {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (isLegacy != false) {
      _result["isLegacy"] = isLegacy;
    }
    if (typeArguments.isNotEmpty) {
      _result["typeArguments"] =
          typeArguments.map((_value) => _value.toJson()).toList();
    }
    if (typeParameters.isNotEmpty) {
      _result["typeParameters"] = typeParameters;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "isLegacy": isLegacy,
        "typeArguments": typeArguments,
        "typeParameters": typeParameters,
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
      _LinkedNodeTypeTypeParameterImpl(bc, offset);
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
    if (bound != null) {
      _result["bound"] = bound.toJson();
    }
    if (name != '') {
      _result["name"] = name;
    }
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
  bool _isNNBD;
  bool _isSynthetic;
  LinkedNodeBuilder _node;
  String _partUriStr;
  String _uriStr;

  @override
  bool get isNNBD => _isNNBD ??= false;

  set isNNBD(bool value) {
    this._isNNBD = value;
  }

  @override
  bool get isSynthetic => _isSynthetic ??= false;

  set isSynthetic(bool value) {
    this._isSynthetic = value;
  }

  @override
  LinkedNodeBuilder get node => _node;

  set node(LinkedNodeBuilder value) {
    this._node = value;
  }

  @override
  String get partUriStr => _partUriStr ??= '';

  /// If the unit is a part, the URI specified in the `part` directive.
  /// Otherwise empty.
  set partUriStr(String value) {
    this._partUriStr = value;
  }

  @override
  String get uriStr => _uriStr ??= '';

  /// The absolute URI.
  set uriStr(String value) {
    this._uriStr = value;
  }

  LinkedNodeUnitBuilder(
      {bool isNNBD,
      bool isSynthetic,
      LinkedNodeBuilder node,
      String partUriStr,
      String uriStr})
      : _isNNBD = isNNBD,
        _isSynthetic = isSynthetic,
        _node = node,
        _partUriStr = partUriStr,
        _uriStr = uriStr;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _node?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._uriStr ?? '');
    signature.addBool(this._node != null);
    this._node?.collectApiSignature(signature);
    signature.addBool(this._isSynthetic == true);
    signature.addBool(this._isNNBD == true);
    signature.addString(this._partUriStr ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_node;
    fb.Offset offset_partUriStr;
    fb.Offset offset_uriStr;
    if (_node != null) {
      offset_node = _node.finish(fbBuilder);
    }
    if (_partUriStr != null) {
      offset_partUriStr = fbBuilder.writeString(_partUriStr);
    }
    if (_uriStr != null) {
      offset_uriStr = fbBuilder.writeString(_uriStr);
    }
    fbBuilder.startTable();
    if (_isNNBD == true) {
      fbBuilder.addBool(3, true);
    }
    if (_isSynthetic == true) {
      fbBuilder.addBool(2, true);
    }
    if (offset_node != null) {
      fbBuilder.addOffset(1, offset_node);
    }
    if (offset_partUriStr != null) {
      fbBuilder.addOffset(4, offset_partUriStr);
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
      _LinkedNodeUnitImpl(bc, offset);
}

class _LinkedNodeUnitImpl extends Object
    with _LinkedNodeUnitMixin
    implements idl.LinkedNodeUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedNodeUnitImpl(this._bc, this._bcOffset);

  bool _isNNBD;
  bool _isSynthetic;
  idl.LinkedNode _node;
  String _partUriStr;
  String _uriStr;

  @override
  bool get isNNBD {
    _isNNBD ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _isNNBD;
  }

  @override
  bool get isSynthetic {
    _isSynthetic ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isSynthetic;
  }

  @override
  idl.LinkedNode get node {
    _node ??= const _LinkedNodeReader().vTableGet(_bc, _bcOffset, 1, null);
    return _node;
  }

  @override
  String get partUriStr {
    _partUriStr ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
    return _partUriStr;
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
    if (isNNBD != false) {
      _result["isNNBD"] = isNNBD;
    }
    if (isSynthetic != false) {
      _result["isSynthetic"] = isSynthetic;
    }
    if (node != null) {
      _result["node"] = node.toJson();
    }
    if (partUriStr != '') {
      _result["partUriStr"] = partUriStr;
    }
    if (uriStr != '') {
      _result["uriStr"] = uriStr;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "isNNBD": isNNBD,
        "isSynthetic": isSynthetic,
        "node": node,
        "partUriStr": partUriStr,
        "uriStr": uriStr,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class PackageBundleBuilder extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  LinkedNodeBundleBuilder _bundle2;
  PackageBundleSdkBuilder _sdk;

  @override
  LinkedNodeBundleBuilder get bundle2 => _bundle2;

  /// The version 2 of the summary.
  set bundle2(LinkedNodeBundleBuilder value) {
    this._bundle2 = value;
  }

  @override
  PackageBundleSdkBuilder get sdk => _sdk;

  /// The SDK specific data, if this bundle is for SDK.
  set sdk(PackageBundleSdkBuilder value) {
    this._sdk = value;
  }

  PackageBundleBuilder(
      {LinkedNodeBundleBuilder bundle2, PackageBundleSdkBuilder sdk})
      : _bundle2 = bundle2,
        _sdk = sdk;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _bundle2?.flushInformative();
    _sdk?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._bundle2 != null);
    this._bundle2?.collectApiSignature(signature);
    signature.addBool(this._sdk != null);
    this._sdk?.collectApiSignature(signature);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "PBdl");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_bundle2;
    fb.Offset offset_sdk;
    if (_bundle2 != null) {
      offset_bundle2 = _bundle2.finish(fbBuilder);
    }
    if (_sdk != null) {
      offset_sdk = _sdk.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_bundle2 != null) {
      fbBuilder.addOffset(0, offset_bundle2);
    }
    if (offset_sdk != null) {
      fbBuilder.addOffset(1, offset_sdk);
    }
    return fbBuilder.endTable();
  }
}

idl.PackageBundle readPackageBundle(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _PackageBundleReader().read(rootRef, 0);
}

class _PackageBundleReader extends fb.TableReader<_PackageBundleImpl> {
  const _PackageBundleReader();

  @override
  _PackageBundleImpl createObject(fb.BufferContext bc, int offset) =>
      _PackageBundleImpl(bc, offset);
}

class _PackageBundleImpl extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageBundleImpl(this._bc, this._bcOffset);

  idl.LinkedNodeBundle _bundle2;
  idl.PackageBundleSdk _sdk;

  @override
  idl.LinkedNodeBundle get bundle2 {
    _bundle2 ??=
        const _LinkedNodeBundleReader().vTableGet(_bc, _bcOffset, 0, null);
    return _bundle2;
  }

  @override
  idl.PackageBundleSdk get sdk {
    _sdk ??= const _PackageBundleSdkReader().vTableGet(_bc, _bcOffset, 1, null);
    return _sdk;
  }
}

abstract class _PackageBundleMixin implements idl.PackageBundle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (bundle2 != null) {
      _result["bundle2"] = bundle2.toJson();
    }
    if (sdk != null) {
      _result["sdk"] = sdk.toJson();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "bundle2": bundle2,
        "sdk": sdk,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class PackageBundleSdkBuilder extends Object
    with _PackageBundleSdkMixin
    implements idl.PackageBundleSdk {
  String _allowedExperimentsJson;

  @override
  String get allowedExperimentsJson => _allowedExperimentsJson ??= '';

  /// The content of the `allowed_experiments.json` from SDK.
  set allowedExperimentsJson(String value) {
    this._allowedExperimentsJson = value;
  }

  PackageBundleSdkBuilder({String allowedExperimentsJson})
      : _allowedExperimentsJson = allowedExperimentsJson;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._allowedExperimentsJson ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_allowedExperimentsJson;
    if (_allowedExperimentsJson != null) {
      offset_allowedExperimentsJson =
          fbBuilder.writeString(_allowedExperimentsJson);
    }
    fbBuilder.startTable();
    if (offset_allowedExperimentsJson != null) {
      fbBuilder.addOffset(0, offset_allowedExperimentsJson);
    }
    return fbBuilder.endTable();
  }
}

class _PackageBundleSdkReader extends fb.TableReader<_PackageBundleSdkImpl> {
  const _PackageBundleSdkReader();

  @override
  _PackageBundleSdkImpl createObject(fb.BufferContext bc, int offset) =>
      _PackageBundleSdkImpl(bc, offset);
}

class _PackageBundleSdkImpl extends Object
    with _PackageBundleSdkMixin
    implements idl.PackageBundleSdk {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageBundleSdkImpl(this._bc, this._bcOffset);

  String _allowedExperimentsJson;

  @override
  String get allowedExperimentsJson {
    _allowedExperimentsJson ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _allowedExperimentsJson;
  }
}

abstract class _PackageBundleSdkMixin implements idl.PackageBundleSdk {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (allowedExperimentsJson != '') {
      _result["allowedExperimentsJson"] = allowedExperimentsJson;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "allowedExperimentsJson": allowedExperimentsJson,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class TopLevelInferenceErrorBuilder extends Object
    with _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  List<String> _arguments;
  idl.TopLevelInferenceErrorKind _kind;

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

  TopLevelInferenceErrorBuilder(
      {List<String> arguments, idl.TopLevelInferenceErrorKind kind})
      : _arguments = arguments,
        _kind = kind;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
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
      fbBuilder.addOffset(1, offset_arguments);
    }
    if (_kind != null && _kind != idl.TopLevelInferenceErrorKind.assignment) {
      fbBuilder.addUint8(0, _kind.index);
    }
    return fbBuilder.endTable();
  }
}

class _TopLevelInferenceErrorReader
    extends fb.TableReader<_TopLevelInferenceErrorImpl> {
  const _TopLevelInferenceErrorReader();

  @override
  _TopLevelInferenceErrorImpl createObject(fb.BufferContext bc, int offset) =>
      _TopLevelInferenceErrorImpl(bc, offset);
}

class _TopLevelInferenceErrorImpl extends Object
    with _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _TopLevelInferenceErrorImpl(this._bc, this._bcOffset);

  List<String> _arguments;
  idl.TopLevelInferenceErrorKind _kind;

  @override
  List<String> get arguments {
    _arguments ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _arguments;
  }

  @override
  idl.TopLevelInferenceErrorKind get kind {
    _kind ??= const _TopLevelInferenceErrorKindReader().vTableGet(
        _bc, _bcOffset, 0, idl.TopLevelInferenceErrorKind.assignment);
    return _kind;
  }
}

abstract class _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (arguments.isNotEmpty) {
      _result["arguments"] = arguments;
    }
    if (kind != idl.TopLevelInferenceErrorKind.assignment) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "arguments": arguments,
        "kind": kind,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedInformativeDataBuilder extends Object
    with _UnlinkedInformativeDataMixin
    implements idl.UnlinkedInformativeData {
  int _variantField_2;
  int _variantField_3;
  int _variantField_9;
  int _variantField_8;
  List<int> _variantField_7;
  int _variantField_6;
  int _variantField_5;
  String _variantField_10;
  int _variantField_1;
  List<String> _variantField_4;
  idl.LinkedNodeKind _kind;

  @override
  int get codeLength {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    return _variantField_2 ??= 0;
  }

  set codeLength(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    _variantField_2 = value;
  }

  @override
  int get codeOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    return _variantField_3 ??= 0;
  }

  set codeOffset(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    _variantField_3 = value;
  }

  @override
  int get combinatorEnd {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    return _variantField_9 ??= 0;
  }

  set combinatorEnd(int value) {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    assert(value == null || value >= 0);
    _variantField_9 = value;
  }

  @override
  int get combinatorKeywordOffset {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    return _variantField_8 ??= 0;
  }

  @override
  int get importDirective_prefixOffset {
    assert(kind == idl.LinkedNodeKind.importDirective);
    return _variantField_8 ??= 0;
  }

  set combinatorKeywordOffset(int value) {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    assert(value == null || value >= 0);
    _variantField_8 = value;
  }

  set importDirective_prefixOffset(int value) {
    assert(kind == idl.LinkedNodeKind.importDirective);
    assert(value == null || value >= 0);
    _variantField_8 = value;
  }

  @override
  List<int> get compilationUnit_lineStarts {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    return _variantField_7 ??= <int>[];
  }

  /// Offsets of the first character of each line in the source code.
  set compilationUnit_lineStarts(List<int> value) {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    assert(value == null || value.every((e) => e >= 0));
    _variantField_7 = value;
  }

  @override
  int get constructorDeclaration_periodOffset {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_6 ??= 0;
  }

  set constructorDeclaration_periodOffset(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_6 = value;
  }

  @override
  int get constructorDeclaration_returnTypeOffset {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    return _variantField_5 ??= 0;
  }

  set constructorDeclaration_returnTypeOffset(int value) {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    assert(value == null || value >= 0);
    _variantField_5 = value;
  }

  @override
  String get defaultFormalParameter_defaultValueCode {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    return _variantField_10 ??= '';
  }

  /// If the parameter has a default value, the source text of the constant
  /// expression in the default value.  Otherwise the empty string.
  set defaultFormalParameter_defaultValueCode(String value) {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_10 = value;
  }

  @override
  int get directiveKeywordOffset {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    return _variantField_1 ??= 0;
  }

  @override
  int get nameOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    return _variantField_1 ??= 0;
  }

  set directiveKeywordOffset(int value) {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    assert(value == null || value >= 0);
    _variantField_1 = value;
  }

  set nameOffset(int value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    assert(value == null || value >= 0);
    _variantField_1 = value;
  }

  @override
  List<String> get documentationComment_tokens {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    return _variantField_4 ??= <String>[];
  }

  set documentationComment_tokens(List<String> value) {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    _variantField_4 = value;
  }

  @override
  idl.LinkedNodeKind get kind => _kind ??= idl.LinkedNodeKind.adjacentStrings;

  /// The kind of the node.
  set kind(idl.LinkedNodeKind value) {
    this._kind = value;
  }

  UnlinkedInformativeDataBuilder.classDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.classDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.classTypeAlias({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.classTypeAlias,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.compilationUnit({
    int codeLength,
    int codeOffset,
    List<int> compilationUnit_lineStarts,
  })  : _kind = idl.LinkedNodeKind.compilationUnit,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_7 = compilationUnit_lineStarts;

  UnlinkedInformativeDataBuilder.constructorDeclaration({
    int codeLength,
    int codeOffset,
    int constructorDeclaration_periodOffset,
    int constructorDeclaration_returnTypeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.constructorDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_6 = constructorDeclaration_periodOffset,
        _variantField_5 = constructorDeclaration_returnTypeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.defaultFormalParameter({
    int codeLength,
    int codeOffset,
    String defaultFormalParameter_defaultValueCode,
  })  : _kind = idl.LinkedNodeKind.defaultFormalParameter,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_10 = defaultFormalParameter_defaultValueCode;

  UnlinkedInformativeDataBuilder.enumConstantDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.enumConstantDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.enumDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.enumDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.exportDirective({
    int directiveKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.exportDirective,
        _variantField_1 = directiveKeywordOffset;

  UnlinkedInformativeDataBuilder.extensionDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.extensionDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.fieldDeclaration({
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.fieldDeclaration,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.fieldFormalParameter({
    int codeLength,
    int codeOffset,
    int nameOffset,
  })  : _kind = idl.LinkedNodeKind.fieldFormalParameter,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset;

  UnlinkedInformativeDataBuilder.functionDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.functionDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.functionTypeAlias({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.functionTypeAlias,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.functionTypedFormalParameter({
    int codeLength,
    int codeOffset,
    int nameOffset,
  })  : _kind = idl.LinkedNodeKind.functionTypedFormalParameter,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset;

  UnlinkedInformativeDataBuilder.genericTypeAlias({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.genericTypeAlias,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.hideCombinator({
    int combinatorEnd,
    int combinatorKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.hideCombinator,
        _variantField_9 = combinatorEnd,
        _variantField_8 = combinatorKeywordOffset;

  UnlinkedInformativeDataBuilder.importDirective({
    int importDirective_prefixOffset,
    int directiveKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.importDirective,
        _variantField_8 = importDirective_prefixOffset,
        _variantField_1 = directiveKeywordOffset;

  UnlinkedInformativeDataBuilder.libraryDirective({
    int directiveKeywordOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.libraryDirective,
        _variantField_1 = directiveKeywordOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.methodDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.methodDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.mixinDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.mixinDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.partDirective({
    int directiveKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.partDirective,
        _variantField_1 = directiveKeywordOffset;

  UnlinkedInformativeDataBuilder.partOfDirective({
    int directiveKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.partOfDirective,
        _variantField_1 = directiveKeywordOffset;

  UnlinkedInformativeDataBuilder.showCombinator({
    int combinatorEnd,
    int combinatorKeywordOffset,
  })  : _kind = idl.LinkedNodeKind.showCombinator,
        _variantField_9 = combinatorEnd,
        _variantField_8 = combinatorKeywordOffset;

  UnlinkedInformativeDataBuilder.simpleFormalParameter({
    int codeLength,
    int codeOffset,
    int nameOffset,
  })  : _kind = idl.LinkedNodeKind.simpleFormalParameter,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset;

  UnlinkedInformativeDataBuilder.topLevelVariableDeclaration({
    List<String> documentationComment_tokens,
  })  : _kind = idl.LinkedNodeKind.topLevelVariableDeclaration,
        _variantField_4 = documentationComment_tokens;

  UnlinkedInformativeDataBuilder.typeParameter({
    int codeLength,
    int codeOffset,
    int nameOffset,
  })  : _kind = idl.LinkedNodeKind.typeParameter,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset;

  UnlinkedInformativeDataBuilder.variableDeclaration({
    int codeLength,
    int codeOffset,
    int nameOffset,
  })  : _kind = idl.LinkedNodeKind.variableDeclaration,
        _variantField_2 = codeLength,
        _variantField_3 = codeOffset,
        _variantField_1 = nameOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {
    if (kind == idl.LinkedNodeKind.classDeclaration) {
    } else if (kind == idl.LinkedNodeKind.classTypeAlias) {
    } else if (kind == idl.LinkedNodeKind.compilationUnit) {
    } else if (kind == idl.LinkedNodeKind.constructorDeclaration) {
    } else if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
    } else if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
    } else if (kind == idl.LinkedNodeKind.enumDeclaration) {
    } else if (kind == idl.LinkedNodeKind.exportDirective) {
    } else if (kind == idl.LinkedNodeKind.extensionDeclaration) {
    } else if (kind == idl.LinkedNodeKind.fieldDeclaration) {
    } else if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
    } else if (kind == idl.LinkedNodeKind.functionDeclaration) {
    } else if (kind == idl.LinkedNodeKind.functionTypeAlias) {
    } else if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
    } else if (kind == idl.LinkedNodeKind.genericTypeAlias) {
    } else if (kind == idl.LinkedNodeKind.hideCombinator) {
    } else if (kind == idl.LinkedNodeKind.importDirective) {
    } else if (kind == idl.LinkedNodeKind.libraryDirective) {
    } else if (kind == idl.LinkedNodeKind.methodDeclaration) {
    } else if (kind == idl.LinkedNodeKind.mixinDeclaration) {
    } else if (kind == idl.LinkedNodeKind.partDirective) {
    } else if (kind == idl.LinkedNodeKind.partOfDirective) {
    } else if (kind == idl.LinkedNodeKind.showCombinator) {
    } else if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
    } else if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
    } else if (kind == idl.LinkedNodeKind.typeParameter) {
    } else if (kind == idl.LinkedNodeKind.variableDeclaration) {}
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.classTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.compilationUnit) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.compilationUnit_lineStarts == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.compilationUnit_lineStarts.length);
        for (var x in this.compilationUnit_lineStarts) {
          signature.addInt(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
      signature.addInt(this.constructorDeclaration_returnTypeOffset ?? 0);
      signature.addInt(this.constructorDeclaration_periodOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      signature.addString(this.defaultFormalParameter_defaultValueCode ?? '');
    } else if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.enumDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.exportDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.directiveKeywordOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.functionDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.hideCombinator) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.combinatorKeywordOffset ?? 0);
      signature.addInt(this.combinatorEnd ?? 0);
    } else if (kind == idl.LinkedNodeKind.importDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.directiveKeywordOffset ?? 0);
      signature.addInt(this.importDirective_prefixOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.libraryDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.directiveKeywordOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.methodDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.partDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.directiveKeywordOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.partOfDirective) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.directiveKeywordOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.showCombinator) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.combinatorKeywordOffset ?? 0);
      signature.addInt(this.combinatorEnd ?? 0);
    } else if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      if (this.documentationComment_tokens == null) {
        signature.addInt(0);
      } else {
        signature.addInt(this.documentationComment_tokens.length);
        for (var x in this.documentationComment_tokens) {
          signature.addString(x);
        }
      }
    } else if (kind == idl.LinkedNodeKind.typeParameter) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
    } else if (kind == idl.LinkedNodeKind.variableDeclaration) {
      signature.addInt(this.kind == null ? 0 : this.kind.index);
      signature.addInt(this.nameOffset ?? 0);
      signature.addInt(this.codeLength ?? 0);
      signature.addInt(this.codeOffset ?? 0);
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_variantField_7;
    fb.Offset offset_variantField_10;
    fb.Offset offset_variantField_4;
    if (!(_variantField_7 == null || _variantField_7.isEmpty)) {
      offset_variantField_7 = fbBuilder.writeListUint32(_variantField_7);
    }
    if (_variantField_10 != null) {
      offset_variantField_10 = fbBuilder.writeString(_variantField_10);
    }
    if (!(_variantField_4 == null || _variantField_4.isEmpty)) {
      offset_variantField_4 = fbBuilder.writeList(
          _variantField_4.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (_variantField_2 != null && _variantField_2 != 0) {
      fbBuilder.addUint32(2, _variantField_2);
    }
    if (_variantField_3 != null && _variantField_3 != 0) {
      fbBuilder.addUint32(3, _variantField_3);
    }
    if (_variantField_9 != null && _variantField_9 != 0) {
      fbBuilder.addUint32(9, _variantField_9);
    }
    if (_variantField_8 != null && _variantField_8 != 0) {
      fbBuilder.addUint32(8, _variantField_8);
    }
    if (offset_variantField_7 != null) {
      fbBuilder.addOffset(7, offset_variantField_7);
    }
    if (_variantField_6 != null && _variantField_6 != 0) {
      fbBuilder.addUint32(6, _variantField_6);
    }
    if (_variantField_5 != null && _variantField_5 != 0) {
      fbBuilder.addUint32(5, _variantField_5);
    }
    if (offset_variantField_10 != null) {
      fbBuilder.addOffset(10, offset_variantField_10);
    }
    if (_variantField_1 != null && _variantField_1 != 0) {
      fbBuilder.addUint32(1, _variantField_1);
    }
    if (offset_variantField_4 != null) {
      fbBuilder.addOffset(4, offset_variantField_4);
    }
    if (_kind != null && _kind != idl.LinkedNodeKind.adjacentStrings) {
      fbBuilder.addUint8(0, _kind.index);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedInformativeDataReader
    extends fb.TableReader<_UnlinkedInformativeDataImpl> {
  const _UnlinkedInformativeDataReader();

  @override
  _UnlinkedInformativeDataImpl createObject(fb.BufferContext bc, int offset) =>
      _UnlinkedInformativeDataImpl(bc, offset);
}

class _UnlinkedInformativeDataImpl extends Object
    with _UnlinkedInformativeDataMixin
    implements idl.UnlinkedInformativeData {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedInformativeDataImpl(this._bc, this._bcOffset);

  int _variantField_2;
  int _variantField_3;
  int _variantField_9;
  int _variantField_8;
  List<int> _variantField_7;
  int _variantField_6;
  int _variantField_5;
  String _variantField_10;
  int _variantField_1;
  List<String> _variantField_4;
  idl.LinkedNodeKind _kind;

  @override
  int get codeLength {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    _variantField_2 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _variantField_2;
  }

  @override
  int get codeOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.compilationUnit ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.defaultFormalParameter ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
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
    _variantField_3 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _variantField_3;
  }

  @override
  int get combinatorEnd {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    _variantField_9 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _variantField_9;
  }

  @override
  int get combinatorKeywordOffset {
    assert(kind == idl.LinkedNodeKind.hideCombinator ||
        kind == idl.LinkedNodeKind.showCombinator);
    _variantField_8 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 8, 0);
    return _variantField_8;
  }

  @override
  int get importDirective_prefixOffset {
    assert(kind == idl.LinkedNodeKind.importDirective);
    _variantField_8 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 8, 0);
    return _variantField_8;
  }

  @override
  List<int> get compilationUnit_lineStarts {
    assert(kind == idl.LinkedNodeKind.compilationUnit);
    _variantField_7 ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
    return _variantField_7;
  }

  @override
  int get constructorDeclaration_periodOffset {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_6 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 6, 0);
    return _variantField_6;
  }

  @override
  int get constructorDeclaration_returnTypeOffset {
    assert(kind == idl.LinkedNodeKind.constructorDeclaration);
    _variantField_5 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 5, 0);
    return _variantField_5;
  }

  @override
  String get defaultFormalParameter_defaultValueCode {
    assert(kind == idl.LinkedNodeKind.defaultFormalParameter);
    _variantField_10 ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 10, '');
    return _variantField_10;
  }

  @override
  int get directiveKeywordOffset {
    assert(kind == idl.LinkedNodeKind.exportDirective ||
        kind == idl.LinkedNodeKind.importDirective ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.partDirective ||
        kind == idl.LinkedNodeKind.partOfDirective);
    _variantField_1 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _variantField_1;
  }

  @override
  int get nameOffset {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldFormalParameter ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypedFormalParameter ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.simpleFormalParameter ||
        kind == idl.LinkedNodeKind.typeParameter ||
        kind == idl.LinkedNodeKind.variableDeclaration);
    _variantField_1 ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _variantField_1;
  }

  @override
  List<String> get documentationComment_tokens {
    assert(kind == idl.LinkedNodeKind.classDeclaration ||
        kind == idl.LinkedNodeKind.classTypeAlias ||
        kind == idl.LinkedNodeKind.constructorDeclaration ||
        kind == idl.LinkedNodeKind.enumDeclaration ||
        kind == idl.LinkedNodeKind.enumConstantDeclaration ||
        kind == idl.LinkedNodeKind.extensionDeclaration ||
        kind == idl.LinkedNodeKind.fieldDeclaration ||
        kind == idl.LinkedNodeKind.functionDeclaration ||
        kind == idl.LinkedNodeKind.functionTypeAlias ||
        kind == idl.LinkedNodeKind.genericTypeAlias ||
        kind == idl.LinkedNodeKind.libraryDirective ||
        kind == idl.LinkedNodeKind.methodDeclaration ||
        kind == idl.LinkedNodeKind.mixinDeclaration ||
        kind == idl.LinkedNodeKind.topLevelVariableDeclaration);
    _variantField_4 ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _variantField_4;
  }

  @override
  idl.LinkedNodeKind get kind {
    _kind ??= const _LinkedNodeKindReader()
        .vTableGet(_bc, _bcOffset, 0, idl.LinkedNodeKind.adjacentStrings);
    return _kind;
  }
}

abstract class _UnlinkedInformativeDataMixin
    implements idl.UnlinkedInformativeData {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (kind != idl.LinkedNodeKind.adjacentStrings) {
      _result["kind"] = kind.toString().split('.')[1];
    }
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (compilationUnit_lineStarts.isNotEmpty) {
        _result["compilationUnit_lineStarts"] = compilationUnit_lineStarts;
      }
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (constructorDeclaration_periodOffset != 0) {
        _result["constructorDeclaration_periodOffset"] =
            constructorDeclaration_periodOffset;
      }
      if (constructorDeclaration_returnTypeOffset != 0) {
        _result["constructorDeclaration_returnTypeOffset"] =
            constructorDeclaration_returnTypeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (defaultFormalParameter_defaultValueCode != '') {
        _result["defaultFormalParameter_defaultValueCode"] =
            defaultFormalParameter_defaultValueCode;
      }
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      if (directiveKeywordOffset != 0) {
        _result["directiveKeywordOffset"] = directiveKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      if (combinatorEnd != 0) {
        _result["combinatorEnd"] = combinatorEnd;
      }
      if (combinatorKeywordOffset != 0) {
        _result["combinatorKeywordOffset"] = combinatorKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      if (importDirective_prefixOffset != 0) {
        _result["importDirective_prefixOffset"] = importDirective_prefixOffset;
      }
      if (directiveKeywordOffset != 0) {
        _result["directiveKeywordOffset"] = directiveKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      if (directiveKeywordOffset != 0) {
        _result["directiveKeywordOffset"] = directiveKeywordOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      if (directiveKeywordOffset != 0) {
        _result["directiveKeywordOffset"] = directiveKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      if (directiveKeywordOffset != 0) {
        _result["directiveKeywordOffset"] = directiveKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      if (combinatorEnd != 0) {
        _result["combinatorEnd"] = combinatorEnd;
      }
      if (combinatorKeywordOffset != 0) {
        _result["combinatorKeywordOffset"] = combinatorKeywordOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      if (documentationComment_tokens.isNotEmpty) {
        _result["documentationComment_tokens"] = documentationComment_tokens;
      }
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      if (codeLength != 0) {
        _result["codeLength"] = codeLength;
      }
      if (codeOffset != 0) {
        _result["codeOffset"] = codeOffset;
      }
      if (nameOffset != 0) {
        _result["nameOffset"] = nameOffset;
      }
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() {
    if (kind == idl.LinkedNodeKind.classDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.classTypeAlias) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.compilationUnit) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "compilationUnit_lineStarts": compilationUnit_lineStarts,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.constructorDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "constructorDeclaration_periodOffset":
            constructorDeclaration_periodOffset,
        "constructorDeclaration_returnTypeOffset":
            constructorDeclaration_returnTypeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.defaultFormalParameter) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "defaultFormalParameter_defaultValueCode":
            defaultFormalParameter_defaultValueCode,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.enumConstantDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.enumDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.exportDirective) {
      return {
        "directiveKeywordOffset": directiveKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.extensionDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldDeclaration) {
      return {
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.fieldFormalParameter) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionTypeAlias) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.functionTypedFormalParameter) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.genericTypeAlias) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.hideCombinator) {
      return {
        "combinatorEnd": combinatorEnd,
        "combinatorKeywordOffset": combinatorKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.importDirective) {
      return {
        "importDirective_prefixOffset": importDirective_prefixOffset,
        "directiveKeywordOffset": directiveKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.libraryDirective) {
      return {
        "directiveKeywordOffset": directiveKeywordOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.methodDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.mixinDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.partDirective) {
      return {
        "directiveKeywordOffset": directiveKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.partOfDirective) {
      return {
        "directiveKeywordOffset": directiveKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.showCombinator) {
      return {
        "combinatorEnd": combinatorEnd,
        "combinatorKeywordOffset": combinatorKeywordOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.simpleFormalParameter) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.topLevelVariableDeclaration) {
      return {
        "documentationComment_tokens": documentationComment_tokens,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.typeParameter) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "kind": kind,
      };
    }
    if (kind == idl.LinkedNodeKind.variableDeclaration) {
      return {
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "nameOffset": nameOffset,
        "kind": kind,
      };
    }
    throw StateError("Unexpected $kind");
  }

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedNamespaceDirectiveBuilder extends Object
    with _UnlinkedNamespaceDirectiveMixin
    implements idl.UnlinkedNamespaceDirective {
  List<UnlinkedNamespaceDirectiveConfigurationBuilder> _configurations;
  String _uri;

  @override
  List<UnlinkedNamespaceDirectiveConfigurationBuilder> get configurations =>
      _configurations ??= <UnlinkedNamespaceDirectiveConfigurationBuilder>[];

  /// The configurations that control which library will actually be used.
  set configurations(
      List<UnlinkedNamespaceDirectiveConfigurationBuilder> value) {
    this._configurations = value;
  }

  @override
  String get uri => _uri ??= '';

  /// The URI referenced by this directive, nad used by default when none
  /// of the [configurations] matches.
  set uri(String value) {
    this._uri = value;
  }

  UnlinkedNamespaceDirectiveBuilder(
      {List<UnlinkedNamespaceDirectiveConfigurationBuilder> configurations,
      String uri})
      : _configurations = configurations,
        _uri = uri;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _configurations?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._configurations == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._configurations.length);
      for (var x in this._configurations) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addString(this._uri ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_configurations;
    fb.Offset offset_uri;
    if (!(_configurations == null || _configurations.isEmpty)) {
      offset_configurations = fbBuilder
          .writeList(_configurations.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_configurations != null) {
      fbBuilder.addOffset(0, offset_configurations);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(1, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedNamespaceDirectiveReader
    extends fb.TableReader<_UnlinkedNamespaceDirectiveImpl> {
  const _UnlinkedNamespaceDirectiveReader();

  @override
  _UnlinkedNamespaceDirectiveImpl createObject(
          fb.BufferContext bc, int offset) =>
      _UnlinkedNamespaceDirectiveImpl(bc, offset);
}

class _UnlinkedNamespaceDirectiveImpl extends Object
    with _UnlinkedNamespaceDirectiveMixin
    implements idl.UnlinkedNamespaceDirective {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedNamespaceDirectiveImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedNamespaceDirectiveConfiguration> _configurations;
  String _uri;

  @override
  List<idl.UnlinkedNamespaceDirectiveConfiguration> get configurations {
    _configurations ??=
        const fb.ListReader<idl.UnlinkedNamespaceDirectiveConfiguration>(
                _UnlinkedNamespaceDirectiveConfigurationReader())
            .vTableGet(_bc, _bcOffset, 0,
                const <idl.UnlinkedNamespaceDirectiveConfiguration>[]);
    return _configurations;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _uri;
  }
}

abstract class _UnlinkedNamespaceDirectiveMixin
    implements idl.UnlinkedNamespaceDirective {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (configurations.isNotEmpty) {
      _result["configurations"] =
          configurations.map((_value) => _value.toJson()).toList();
    }
    if (uri != '') {
      _result["uri"] = uri;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "configurations": configurations,
        "uri": uri,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedNamespaceDirectiveConfigurationBuilder extends Object
    with _UnlinkedNamespaceDirectiveConfigurationMixin
    implements idl.UnlinkedNamespaceDirectiveConfiguration {
  String _name;
  String _uri;
  String _value;

  @override
  String get name => _name ??= '';

  /// The name of the declared variable used in the condition.
  set name(String value) {
    this._name = value;
  }

  @override
  String get uri => _uri ??= '';

  /// The URI to be used if the condition is true.
  set uri(String value) {
    this._uri = value;
  }

  @override
  String get value => _value ??= '';

  /// The value to which the value of the declared variable will be compared,
  /// or the empty string if the condition does not include an equality test.
  set value(String value) {
    this._value = value;
  }

  UnlinkedNamespaceDirectiveConfigurationBuilder(
      {String name, String uri, String value})
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

class _UnlinkedNamespaceDirectiveConfigurationReader
    extends fb.TableReader<_UnlinkedNamespaceDirectiveConfigurationImpl> {
  const _UnlinkedNamespaceDirectiveConfigurationReader();

  @override
  _UnlinkedNamespaceDirectiveConfigurationImpl createObject(
          fb.BufferContext bc, int offset) =>
      _UnlinkedNamespaceDirectiveConfigurationImpl(bc, offset);
}

class _UnlinkedNamespaceDirectiveConfigurationImpl extends Object
    with _UnlinkedNamespaceDirectiveConfigurationMixin
    implements idl.UnlinkedNamespaceDirectiveConfiguration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedNamespaceDirectiveConfigurationImpl(this._bc, this._bcOffset);

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

abstract class _UnlinkedNamespaceDirectiveConfigurationMixin
    implements idl.UnlinkedNamespaceDirectiveConfiguration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (name != '') {
      _result["name"] = name;
    }
    if (uri != '') {
      _result["uri"] = uri;
    }
    if (value != '') {
      _result["value"] = value;
    }
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

class UnlinkedUnit2Builder extends Object
    with _UnlinkedUnit2Mixin
    implements idl.UnlinkedUnit2 {
  List<int> _apiSignature;
  List<UnlinkedNamespaceDirectiveBuilder> _exports;
  bool _hasLibraryDirective;
  bool _hasPartOfDirective;
  List<UnlinkedNamespaceDirectiveBuilder> _imports;
  List<UnlinkedInformativeDataBuilder> _informativeData;
  List<int> _lineStarts;
  String _partOfUri;
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
  List<UnlinkedNamespaceDirectiveBuilder> get exports =>
      _exports ??= <UnlinkedNamespaceDirectiveBuilder>[];

  /// URIs of `export` directives.
  set exports(List<UnlinkedNamespaceDirectiveBuilder> value) {
    this._exports = value;
  }

  @override
  bool get hasLibraryDirective => _hasLibraryDirective ??= false;

  /// Is `true` if the unit contains a `library` directive.
  set hasLibraryDirective(bool value) {
    this._hasLibraryDirective = value;
  }

  @override
  bool get hasPartOfDirective => _hasPartOfDirective ??= false;

  /// Is `true` if the unit contains a `part of` directive.
  set hasPartOfDirective(bool value) {
    this._hasPartOfDirective = value;
  }

  @override
  List<UnlinkedNamespaceDirectiveBuilder> get imports =>
      _imports ??= <UnlinkedNamespaceDirectiveBuilder>[];

  /// URIs of `import` directives.
  set imports(List<UnlinkedNamespaceDirectiveBuilder> value) {
    this._imports = value;
  }

  @override
  List<UnlinkedInformativeDataBuilder> get informativeData =>
      _informativeData ??= <UnlinkedInformativeDataBuilder>[];

  set informativeData(List<UnlinkedInformativeDataBuilder> value) {
    this._informativeData = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /// Offsets of the first character of each line in the source code.
  set lineStarts(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  String get partOfUri => _partOfUri ??= '';

  /// URI of the `part of` directive.
  set partOfUri(String value) {
    this._partOfUri = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /// URIs of `part` directives.
  set parts(List<String> value) {
    this._parts = value;
  }

  UnlinkedUnit2Builder(
      {List<int> apiSignature,
      List<UnlinkedNamespaceDirectiveBuilder> exports,
      bool hasLibraryDirective,
      bool hasPartOfDirective,
      List<UnlinkedNamespaceDirectiveBuilder> imports,
      List<UnlinkedInformativeDataBuilder> informativeData,
      List<int> lineStarts,
      String partOfUri,
      List<String> parts})
      : _apiSignature = apiSignature,
        _exports = exports,
        _hasLibraryDirective = hasLibraryDirective,
        _hasPartOfDirective = hasPartOfDirective,
        _imports = imports,
        _informativeData = informativeData,
        _lineStarts = lineStarts,
        _partOfUri = partOfUri,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _exports?.forEach((b) => b.flushInformative());
    _imports?.forEach((b) => b.flushInformative());
    _informativeData?.forEach((b) => b.flushInformative());
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
    signature.addBool(this._hasPartOfDirective == true);
    if (this._parts == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._parts.length);
      for (var x in this._parts) {
        signature.addString(x);
      }
    }
    signature.addBool(this._hasLibraryDirective == true);
    if (this._informativeData == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._informativeData.length);
      for (var x in this._informativeData) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addString(this._partOfUri ?? '');
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UUN2");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_exports;
    fb.Offset offset_imports;
    fb.Offset offset_informativeData;
    fb.Offset offset_lineStarts;
    fb.Offset offset_partOfUri;
    fb.Offset offset_parts;
    if (!(_apiSignature == null || _apiSignature.isEmpty)) {
      offset_apiSignature = fbBuilder.writeListUint32(_apiSignature);
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_imports == null || _imports.isEmpty)) {
      offset_imports = fbBuilder
          .writeList(_imports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_informativeData == null || _informativeData.isEmpty)) {
      offset_informativeData = fbBuilder
          .writeList(_informativeData.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_lineStarts == null || _lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(_lineStarts);
    }
    if (_partOfUri != null) {
      offset_partOfUri = fbBuilder.writeString(_partOfUri);
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
    if (_hasLibraryDirective == true) {
      fbBuilder.addBool(6, true);
    }
    if (_hasPartOfDirective == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_imports != null) {
      fbBuilder.addOffset(2, offset_imports);
    }
    if (offset_informativeData != null) {
      fbBuilder.addOffset(7, offset_informativeData);
    }
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(5, offset_lineStarts);
    }
    if (offset_partOfUri != null) {
      fbBuilder.addOffset(8, offset_partOfUri);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(4, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedUnit2 readUnlinkedUnit2(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedUnit2Reader().read(rootRef, 0);
}

class _UnlinkedUnit2Reader extends fb.TableReader<_UnlinkedUnit2Impl> {
  const _UnlinkedUnit2Reader();

  @override
  _UnlinkedUnit2Impl createObject(fb.BufferContext bc, int offset) =>
      _UnlinkedUnit2Impl(bc, offset);
}

class _UnlinkedUnit2Impl extends Object
    with _UnlinkedUnit2Mixin
    implements idl.UnlinkedUnit2 {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedUnit2Impl(this._bc, this._bcOffset);

  List<int> _apiSignature;
  List<idl.UnlinkedNamespaceDirective> _exports;
  bool _hasLibraryDirective;
  bool _hasPartOfDirective;
  List<idl.UnlinkedNamespaceDirective> _imports;
  List<idl.UnlinkedInformativeData> _informativeData;
  List<int> _lineStarts;
  String _partOfUri;
  List<String> _parts;

  @override
  List<int> get apiSignature {
    _apiSignature ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _apiSignature;
  }

  @override
  List<idl.UnlinkedNamespaceDirective> get exports {
    _exports ??= const fb.ListReader<idl.UnlinkedNamespaceDirective>(
            _UnlinkedNamespaceDirectiveReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.UnlinkedNamespaceDirective>[]);
    return _exports;
  }

  @override
  bool get hasLibraryDirective {
    _hasLibraryDirective ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 6, false);
    return _hasLibraryDirective;
  }

  @override
  bool get hasPartOfDirective {
    _hasPartOfDirective ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _hasPartOfDirective;
  }

  @override
  List<idl.UnlinkedNamespaceDirective> get imports {
    _imports ??= const fb.ListReader<idl.UnlinkedNamespaceDirective>(
            _UnlinkedNamespaceDirectiveReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.UnlinkedNamespaceDirective>[]);
    return _imports;
  }

  @override
  List<idl.UnlinkedInformativeData> get informativeData {
    _informativeData ??= const fb.ListReader<idl.UnlinkedInformativeData>(
            _UnlinkedInformativeDataReader())
        .vTableGet(_bc, _bcOffset, 7, const <idl.UnlinkedInformativeData>[]);
    return _informativeData;
  }

  @override
  List<int> get lineStarts {
    _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _lineStarts;
  }

  @override
  String get partOfUri {
    _partOfUri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 8, '');
    return _partOfUri;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _parts;
  }
}

abstract class _UnlinkedUnit2Mixin implements idl.UnlinkedUnit2 {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (apiSignature.isNotEmpty) {
      _result["apiSignature"] = apiSignature;
    }
    if (exports.isNotEmpty) {
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    }
    if (hasLibraryDirective != false) {
      _result["hasLibraryDirective"] = hasLibraryDirective;
    }
    if (hasPartOfDirective != false) {
      _result["hasPartOfDirective"] = hasPartOfDirective;
    }
    if (imports.isNotEmpty) {
      _result["imports"] = imports.map((_value) => _value.toJson()).toList();
    }
    if (informativeData.isNotEmpty) {
      _result["informativeData"] =
          informativeData.map((_value) => _value.toJson()).toList();
    }
    if (lineStarts.isNotEmpty) {
      _result["lineStarts"] = lineStarts;
    }
    if (partOfUri != '') {
      _result["partOfUri"] = partOfUri;
    }
    if (parts.isNotEmpty) {
      _result["parts"] = parts;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "apiSignature": apiSignature,
        "exports": exports,
        "hasLibraryDirective": hasLibraryDirective,
        "hasPartOfDirective": hasPartOfDirective,
        "imports": imports,
        "informativeData": informativeData,
        "lineStarts": lineStarts,
        "partOfUri": partOfUri,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}
