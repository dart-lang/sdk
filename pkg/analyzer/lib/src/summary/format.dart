// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the SDK script
// "pkg/analyzer/tool/summary/generate.dart $IDL_FILE_PATH",
// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.

// The generator sometimes generates unnecessary 'this' references.
// ignore_for_file: unnecessary_this

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

class PackageBundleBuilder extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  int _fake;

  @override
  int get fake => _fake ??= 0;

  /// The version 2 of the summary.
  set fake(int value) {
    assert(value == null || value >= 0);
    this._fake = value;
  }

  PackageBundleBuilder({int fake}) : _fake = fake;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._fake ?? 0);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "PBdl");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fbBuilder.startTable();
    if (_fake != null && _fake != 0) {
      fbBuilder.addUint32(0, _fake);
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

  int _fake;

  @override
  int get fake {
    _fake ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _fake;
  }
}

abstract class _PackageBundleMixin implements idl.PackageBundle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (fake != 0) {
      _result["fake"] = fake;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "fake": fake,
      };

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
      List<int> lineStarts,
      String partOfUri,
      List<String> parts})
      : _apiSignature = apiSignature,
        _exports = exports,
        _hasLibraryDirective = hasLibraryDirective,
        _hasPartOfDirective = hasPartOfDirective,
        _imports = imports,
        _lineStarts = lineStarts,
        _partOfUri = partOfUri,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _exports?.forEach((b) => b.flushInformative());
    _imports?.forEach((b) => b.flushInformative());
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
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(5, offset_lineStarts);
    }
    if (offset_partOfUri != null) {
      fbBuilder.addOffset(7, offset_partOfUri);
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
  List<int> get lineStarts {
    _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
    return _lineStarts;
  }

  @override
  String get partOfUri {
    _partOfUri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 7, '');
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
        "lineStarts": lineStarts,
        "partOfUri": partOfUri,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}
