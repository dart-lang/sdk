// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the SDK script
// "pkg/analyzer/tool/summary/generate.dart $IDL_FILE_PATH",
// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.

// The generator sometimes generates unnecessary 'this' references.
// ignore_for_file: unnecessary_this

import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;

import 'package:analyzer/src/summary/api_signature.dart' as api_sig;
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;
import 'package:analyzer/src/summary/idl.dart' as idl;

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
  String? _exception;
  List<AnalysisDriverExceptionFileBuilder>? _files;
  String? _path;
  String? _stackTrace;

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

  AnalysisDriverExceptionContextBuilder({
    String? exception,
    List<AnalysisDriverExceptionFileBuilder>? files,
    String? path,
    String? stackTrace,
  }) : _exception = exception,
       _files = files,
       _path = path,
       _stackTrace = stackTrace;

  /// Flush informative data recursively.
  void flushInformative() {
    _files?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._path ?? '');
    signatureSink.addString(this._exception ?? '');
    signatureSink.addString(this._stackTrace ?? '');
    var files = this._files;
    if (files == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(files.length);
      for (var x in files) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADEC");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_exception;
    fb.Offset? offset_files;
    fb.Offset? offset_path;
    fb.Offset? offset_stackTrace;
    var exception = _exception;
    if (exception != null) {
      offset_exception = fbBuilder.writeString(exception);
    }
    var files = _files;
    if (!(files == null || files.isEmpty)) {
      offset_files = fbBuilder.writeList(
        files.map((b) => b.finish(fbBuilder)).toList(),
      );
    }
    var path = _path;
    if (path != null) {
      offset_path = fbBuilder.writeString(path);
    }
    var stackTrace = _stackTrace;
    if (stackTrace != null) {
      offset_stackTrace = fbBuilder.writeString(stackTrace);
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
  List<int> buffer,
) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverExceptionContextReader().read(rootRef, 0);
}

class _AnalysisDriverExceptionContextReader
    extends fb.TableReader<_AnalysisDriverExceptionContextImpl> {
  const _AnalysisDriverExceptionContextReader();

  @override
  _AnalysisDriverExceptionContextImpl createObject(
    fb.BufferContext bc,
    int offset,
  ) => _AnalysisDriverExceptionContextImpl(bc, offset);
}

class _AnalysisDriverExceptionContextImpl extends Object
    with _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionContextImpl(this._bc, this._bcOffset);

  String? _exception;
  List<idl.AnalysisDriverExceptionFile>? _files;
  String? _path;
  String? _stackTrace;

  @override
  String get exception {
    return _exception ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      1,
      '',
    );
  }

  @override
  List<idl.AnalysisDriverExceptionFile> get files {
    return _files ??= const fb.ListReader<idl.AnalysisDriverExceptionFile>(
      _AnalysisDriverExceptionFileReader(),
    ).vTableGet(_bc, _bcOffset, 3, const <idl.AnalysisDriverExceptionFile>[]);
  }

  @override
  String get path {
    return _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }

  @override
  String get stackTrace {
    return _stackTrace ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      2,
      '',
    );
  }
}

mixin _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_exception = exception;
    if (local_exception != '') {
      result["exception"] = local_exception;
    }
    var local_files = files;
    if (local_files.isNotEmpty) {
      result["files"] = local_files.map((value) => value.toJson()).toList();
    }
    var local_path = path;
    if (local_path != '') {
      result["path"] = local_path;
    }
    var local_stackTrace = stackTrace;
    if (local_stackTrace != '') {
      result["stackTrace"] = local_stackTrace;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
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
  String? _content;
  String? _path;

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

  AnalysisDriverExceptionFileBuilder({String? content, String? path})
    : _content = content,
      _path = path;

  /// Flush informative data recursively.
  void flushInformative() {}

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._path ?? '');
    signatureSink.addString(this._content ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_content;
    fb.Offset? offset_path;
    var content = _content;
    if (content != null) {
      offset_content = fbBuilder.writeString(content);
    }
    var path = _path;
    if (path != null) {
      offset_path = fbBuilder.writeString(path);
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
    fb.BufferContext bc,
    int offset,
  ) => _AnalysisDriverExceptionFileImpl(bc, offset);
}

class _AnalysisDriverExceptionFileImpl extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionFileImpl(this._bc, this._bcOffset);

  String? _content;
  String? _path;

  @override
  String get content {
    return _content ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      1,
      '',
    );
  }

  @override
  String get path {
    return _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }
}

mixin _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_content = content;
    if (local_content != '') {
      result["content"] = local_content;
    }
    var local_path = path;
    if (local_path != '') {
      result["path"] = local_path;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {"content": content, "path": path};

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverResolvedUnitBuilder extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  List<AnalysisDriverUnitErrorBuilder>? _errors;
  AnalysisDriverUnitIndexBuilder? _index;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  /// The full list of analysis errors, both syntactic and semantic.
  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  @override
  AnalysisDriverUnitIndexBuilder? get index => _index;

  /// The index of the unit.
  set index(AnalysisDriverUnitIndexBuilder? value) {
    this._index = value;
  }

  AnalysisDriverResolvedUnitBuilder({
    List<AnalysisDriverUnitErrorBuilder>? errors,
    AnalysisDriverUnitIndexBuilder? index,
  }) : _errors = errors,
       _index = index;

  /// Flush informative data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
    _index?.flushInformative();
  }

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var errors = this._errors;
    if (errors == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(errors.length);
      for (var x in errors) {
        x.collectApiSignature(signatureSink);
      }
    }
    signatureSink.addBool(this._index != null);
    this._index?.collectApiSignature(signatureSink);
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADRU");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_errors;
    fb.Offset? offset_index;
    var errors = _errors;
    if (!(errors == null || errors.isEmpty)) {
      offset_errors = fbBuilder.writeList(
        errors.map((b) => b.finish(fbBuilder)).toList(),
      );
    }
    var index = _index;
    if (index != null) {
      offset_index = index.finish(fbBuilder);
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
  List<int> buffer,
) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverResolvedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverResolvedUnitReader
    extends fb.TableReader<_AnalysisDriverResolvedUnitImpl> {
  const _AnalysisDriverResolvedUnitReader();

  @override
  _AnalysisDriverResolvedUnitImpl createObject(
    fb.BufferContext bc,
    int offset,
  ) => _AnalysisDriverResolvedUnitImpl(bc, offset);
}

class _AnalysisDriverResolvedUnitImpl extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverResolvedUnitImpl(this._bc, this._bcOffset);

  List<idl.AnalysisDriverUnitError>? _errors;
  idl.AnalysisDriverUnitIndex? _index;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    return _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
      _AnalysisDriverUnitErrorReader(),
    ).vTableGet(_bc, _bcOffset, 0, const <idl.AnalysisDriverUnitError>[]);
  }

  @override
  idl.AnalysisDriverUnitIndex? get index {
    return _index ??= const _AnalysisDriverUnitIndexReader().vTableGetOrNull(
      _bc,
      _bcOffset,
      1,
    );
  }
}

mixin _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_errors = errors;
    if (local_errors.isNotEmpty) {
      result["errors"] = local_errors.map((value) => value.toJson()).toList();
    }
    var local_index = index;
    if (local_index != null) {
      result["index"] = local_index.toJson();
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {"errors": errors, "index": index};

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverSubtypeBuilder extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  List<int>? _members;
  int? _name;

  @override
  List<int> get members => _members ??= <int>[];

  /// The names of defined instance members.
  /// They are indexes into [AnalysisDriverUnitIndex.strings] list.
  /// The list is sorted in ascending order.
  set members(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._members = value;
  }

  @override
  int get name => _name ??= 0;

  /// The name of the class.
  /// It is an index into [AnalysisDriverUnitIndex.strings] list.
  set name(int value) {
    assert(value >= 0);
    this._name = value;
  }

  AnalysisDriverSubtypeBuilder({List<int>? members, int? name})
    : _members = members,
      _name = name;

  /// Flush informative data recursively.
  void flushInformative() {}

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addInt(this._name ?? 0);
    var members = this._members;
    if (members == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(members.length);
      for (var x in members) {
        signatureSink.addInt(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_members;
    var members = _members;
    if (!(members == null || members.isEmpty)) {
      offset_members = fbBuilder.writeListUint32(members);
    }
    fbBuilder.startTable();
    if (offset_members != null) {
      fbBuilder.addOffset(1, offset_members);
    }
    fbBuilder.addUint32(0, _name, 0);
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

  List<int>? _members;
  int? _name;

  @override
  List<int> get members {
    return _members ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      1,
      const <int>[],
    );
  }

  @override
  int get name {
    return _name ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
  }
}

mixin _AnalysisDriverSubtypeMixin implements idl.AnalysisDriverSubtype {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_members = members;
    if (local_members.isNotEmpty) {
      result["members"] = local_members;
    }
    var local_name = name;
    if (local_name != 0) {
      result["name"] = local_name;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {"members": members, "name": name};

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnitErrorBuilder extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  List<DiagnosticMessageBuilder>? _contextMessages;
  String? _correction;
  int? _length;
  String? _message;
  int? _offset;
  String? _uniqueName;

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
    assert(value >= 0);
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
    assert(value >= 0);
    this._offset = value;
  }

  @override
  String get uniqueName => _uniqueName ??= '';

  /// The unique name of the error code.
  set uniqueName(String value) {
    this._uniqueName = value;
  }

  AnalysisDriverUnitErrorBuilder({
    List<DiagnosticMessageBuilder>? contextMessages,
    String? correction,
    int? length,
    String? message,
    int? offset,
    String? uniqueName,
  }) : _contextMessages = contextMessages,
       _correction = correction,
       _length = length,
       _message = message,
       _offset = offset,
       _uniqueName = uniqueName;

  /// Flush informative data recursively.
  void flushInformative() {
    _contextMessages?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addInt(this._offset ?? 0);
    signatureSink.addInt(this._length ?? 0);
    signatureSink.addString(this._uniqueName ?? '');
    signatureSink.addString(this._message ?? '');
    signatureSink.addString(this._correction ?? '');
    var contextMessages = this._contextMessages;
    if (contextMessages == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(contextMessages.length);
      for (var x in contextMessages) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_contextMessages;
    fb.Offset? offset_correction;
    fb.Offset? offset_message;
    fb.Offset? offset_uniqueName;
    var contextMessages = _contextMessages;
    if (!(contextMessages == null || contextMessages.isEmpty)) {
      offset_contextMessages = fbBuilder.writeList(
        contextMessages.map((b) => b.finish(fbBuilder)).toList(),
      );
    }
    var correction = _correction;
    if (correction != null) {
      offset_correction = fbBuilder.writeString(correction);
    }
    var message = _message;
    if (message != null) {
      offset_message = fbBuilder.writeString(message);
    }
    var uniqueName = _uniqueName;
    if (uniqueName != null) {
      offset_uniqueName = fbBuilder.writeString(uniqueName);
    }
    fbBuilder.startTable();
    if (offset_contextMessages != null) {
      fbBuilder.addOffset(5, offset_contextMessages);
    }
    if (offset_correction != null) {
      fbBuilder.addOffset(4, offset_correction);
    }
    fbBuilder.addUint32(1, _length, 0);
    if (offset_message != null) {
      fbBuilder.addOffset(3, offset_message);
    }
    fbBuilder.addUint32(0, _offset, 0);
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

  List<idl.DiagnosticMessage>? _contextMessages;
  String? _correction;
  int? _length;
  String? _message;
  int? _offset;
  String? _uniqueName;

  @override
  List<idl.DiagnosticMessage> get contextMessages {
    return _contextMessages ??= const fb.ListReader<idl.DiagnosticMessage>(
      _DiagnosticMessageReader(),
    ).vTableGet(_bc, _bcOffset, 5, const <idl.DiagnosticMessage>[]);
  }

  @override
  String get correction {
    return _correction ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      4,
      '',
    );
  }

  @override
  int get length {
    return _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  String get message {
    return _message ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      3,
      '',
    );
  }

  @override
  int get offset {
    return _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
  }

  @override
  String get uniqueName {
    return _uniqueName ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      2,
      '',
    );
  }
}

mixin _AnalysisDriverUnitErrorMixin implements idl.AnalysisDriverUnitError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_contextMessages = contextMessages;
    if (local_contextMessages.isNotEmpty) {
      result["contextMessages"] = local_contextMessages
          .map((value) => value.toJson())
          .toList();
    }
    var local_correction = correction;
    if (local_correction != '') {
      result["correction"] = local_correction;
    }
    var local_length = length;
    if (local_length != 0) {
      result["length"] = local_length;
    }
    var local_message = message;
    if (local_message != '') {
      result["message"] = local_message;
    }
    var local_offset = offset;
    if (local_offset != 0) {
      result["offset"] = local_offset;
    }
    var local_uniqueName = uniqueName;
    if (local_uniqueName != '') {
      result["uniqueName"] = local_uniqueName;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
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
  List<String>? _elementImportPrefixes;
  List<idl.IndexSyntheticElementKind>? _elementKinds;
  List<int>? _elementNameClassMemberIds;
  List<int>? _elementNameParameterIds;
  List<int>? _elementNameUnitMemberIds;
  List<int>? _elementUnits;
  List<int>? _libFragmentRefTargets;
  List<int>? _libFragmentRefUriLengths;
  List<int>? _libFragmentRefUriOffsets;
  int? _nullStringId;
  List<String>? _strings;
  List<AnalysisDriverSubtypeBuilder>? _subtypes;
  List<int>? _supertypes;
  List<int>? _unitLibraryUris;
  List<int>? _unitUnitUris;
  List<bool>? _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedElementKinds;
  List<int>? _usedElementLengths;
  List<int>? _usedElementOffsets;
  List<int>? _usedElements;
  List<bool>? _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedNameKinds;
  List<int>? _usedNameOffsets;
  List<int>? _usedNames;

  @override
  List<String> get elementImportPrefixes =>
      _elementImportPrefixes ??= <String>[];

  /// Each item of this list corresponds to a unique referenced element. It is
  /// a list of the prefixes associated with references to the element.
  set elementImportPrefixes(List<String> value) {
    this._elementImportPrefixes = value;
  }

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
    assert(value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this index.
  set elementNameParameterIds(List<int> value) {
    assert(value.every((e) => e >= 0));
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
    assert(value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  set elementUnits(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  List<int> get libFragmentRefTargets => _libFragmentRefTargets ??= <int>[];

  /// Support for indexing `part` and `part of` directives.
  ///
  /// This is the index into [unitLibraryUris] and [unitUnitUris].
  /// This is the library fragment referenced by the directive.
  set libFragmentRefTargets(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._libFragmentRefTargets = value;
  }

  @override
  List<int> get libFragmentRefUriLengths =>
      _libFragmentRefUriLengths ??= <int>[];

  /// Support for indexing `part` and `part of` directives.
  ///
  /// The offset of the URI in the directive.
  set libFragmentRefUriLengths(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._libFragmentRefUriLengths = value;
  }

  @override
  List<int> get libFragmentRefUriOffsets =>
      _libFragmentRefUriOffsets ??= <int>[];

  /// Support for indexing `part` and `part of` directives.
  ///
  /// The offset of the URI in the directive.
  set libFragmentRefUriOffsets(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._libFragmentRefUriOffsets = value;
  }

  @override
  int get nullStringId => _nullStringId ??= 0;

  /// Identifier of the null string in [strings].
  set nullStringId(int value) {
    assert(value >= 0);
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
    assert(value.every((e) => e >= 0));
    this._supertypes = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitLibraryUris(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitUnitUris(List<int> value) {
    assert(value.every((e) => e >= 0));
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
    assert(value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  set usedElementOffsets(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /// Each item of this list is the index into [elementUnits],
  /// [elementNameUnitMemberIds], [elementNameClassMemberIds] and
  /// [elementNameParameterIds].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this index.
  set usedElements(List<int> value) {
    assert(value.every((e) => e >= 0));
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
    assert(value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /// Each item of this list is the index into [strings] for a used name.  The
  /// list is sorted in ascending order, so that the client can quickly find
  /// whether a name is used in this index.
  set usedNames(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedNames = value;
  }

  AnalysisDriverUnitIndexBuilder({
    List<String>? elementImportPrefixes,
    List<idl.IndexSyntheticElementKind>? elementKinds,
    List<int>? elementNameClassMemberIds,
    List<int>? elementNameParameterIds,
    List<int>? elementNameUnitMemberIds,
    List<int>? elementUnits,
    List<int>? libFragmentRefTargets,
    List<int>? libFragmentRefUriLengths,
    List<int>? libFragmentRefUriOffsets,
    int? nullStringId,
    List<String>? strings,
    List<AnalysisDriverSubtypeBuilder>? subtypes,
    List<int>? supertypes,
    List<int>? unitLibraryUris,
    List<int>? unitUnitUris,
    List<bool>? usedElementIsQualifiedFlags,
    List<idl.IndexRelationKind>? usedElementKinds,
    List<int>? usedElementLengths,
    List<int>? usedElementOffsets,
    List<int>? usedElements,
    List<bool>? usedNameIsQualifiedFlags,
    List<idl.IndexRelationKind>? usedNameKinds,
    List<int>? usedNameOffsets,
    List<int>? usedNames,
  }) : _elementImportPrefixes = elementImportPrefixes,
       _elementKinds = elementKinds,
       _elementNameClassMemberIds = elementNameClassMemberIds,
       _elementNameParameterIds = elementNameParameterIds,
       _elementNameUnitMemberIds = elementNameUnitMemberIds,
       _elementUnits = elementUnits,
       _libFragmentRefTargets = libFragmentRefTargets,
       _libFragmentRefUriLengths = libFragmentRefUriLengths,
       _libFragmentRefUriOffsets = libFragmentRefUriOffsets,
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

  /// Flush informative data recursively.
  void flushInformative() {
    _subtypes?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var strings = this._strings;
    if (strings == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(strings.length);
      for (var x in strings) {
        signatureSink.addString(x);
      }
    }
    signatureSink.addInt(this._nullStringId ?? 0);
    var unitLibraryUris = this._unitLibraryUris;
    if (unitLibraryUris == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(unitLibraryUris.length);
      for (var x in unitLibraryUris) {
        signatureSink.addInt(x);
      }
    }
    var unitUnitUris = this._unitUnitUris;
    if (unitUnitUris == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(unitUnitUris.length);
      for (var x in unitUnitUris) {
        signatureSink.addInt(x);
      }
    }
    var elementKinds = this._elementKinds;
    if (elementKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementKinds.length);
      for (var x in elementKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var elementUnits = this._elementUnits;
    if (elementUnits == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementUnits.length);
      for (var x in elementUnits) {
        signatureSink.addInt(x);
      }
    }
    var elementNameUnitMemberIds = this._elementNameUnitMemberIds;
    if (elementNameUnitMemberIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameUnitMemberIds.length);
      for (var x in elementNameUnitMemberIds) {
        signatureSink.addInt(x);
      }
    }
    var elementNameClassMemberIds = this._elementNameClassMemberIds;
    if (elementNameClassMemberIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameClassMemberIds.length);
      for (var x in elementNameClassMemberIds) {
        signatureSink.addInt(x);
      }
    }
    var elementNameParameterIds = this._elementNameParameterIds;
    if (elementNameParameterIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameParameterIds.length);
      for (var x in elementNameParameterIds) {
        signatureSink.addInt(x);
      }
    }
    var usedElements = this._usedElements;
    if (usedElements == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElements.length);
      for (var x in usedElements) {
        signatureSink.addInt(x);
      }
    }
    var usedElementKinds = this._usedElementKinds;
    if (usedElementKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementKinds.length);
      for (var x in usedElementKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var usedElementOffsets = this._usedElementOffsets;
    if (usedElementOffsets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementOffsets.length);
      for (var x in usedElementOffsets) {
        signatureSink.addInt(x);
      }
    }
    var usedElementLengths = this._usedElementLengths;
    if (usedElementLengths == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementLengths.length);
      for (var x in usedElementLengths) {
        signatureSink.addInt(x);
      }
    }
    var usedElementIsQualifiedFlags = this._usedElementIsQualifiedFlags;
    if (usedElementIsQualifiedFlags == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementIsQualifiedFlags.length);
      for (var x in usedElementIsQualifiedFlags) {
        signatureSink.addBool(x);
      }
    }
    var usedNames = this._usedNames;
    if (usedNames == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNames.length);
      for (var x in usedNames) {
        signatureSink.addInt(x);
      }
    }
    var usedNameKinds = this._usedNameKinds;
    if (usedNameKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameKinds.length);
      for (var x in usedNameKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var usedNameOffsets = this._usedNameOffsets;
    if (usedNameOffsets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameOffsets.length);
      for (var x in usedNameOffsets) {
        signatureSink.addInt(x);
      }
    }
    var usedNameIsQualifiedFlags = this._usedNameIsQualifiedFlags;
    if (usedNameIsQualifiedFlags == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameIsQualifiedFlags.length);
      for (var x in usedNameIsQualifiedFlags) {
        signatureSink.addBool(x);
      }
    }
    var supertypes = this._supertypes;
    if (supertypes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(supertypes.length);
      for (var x in supertypes) {
        signatureSink.addInt(x);
      }
    }
    var subtypes = this._subtypes;
    if (subtypes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(subtypes.length);
      for (var x in subtypes) {
        x.collectApiSignature(signatureSink);
      }
    }
    var elementImportPrefixes = this._elementImportPrefixes;
    if (elementImportPrefixes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementImportPrefixes.length);
      for (var x in elementImportPrefixes) {
        signatureSink.addString(x);
      }
    }
    var libFragmentRefTargets = this._libFragmentRefTargets;
    if (libFragmentRefTargets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(libFragmentRefTargets.length);
      for (var x in libFragmentRefTargets) {
        signatureSink.addInt(x);
      }
    }
    var libFragmentRefUriOffsets = this._libFragmentRefUriOffsets;
    if (libFragmentRefUriOffsets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(libFragmentRefUriOffsets.length);
      for (var x in libFragmentRefUriOffsets) {
        signatureSink.addInt(x);
      }
    }
    var libFragmentRefUriLengths = this._libFragmentRefUriLengths;
    if (libFragmentRefUriLengths == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(libFragmentRefUriLengths.length);
      for (var x in libFragmentRefUriLengths) {
        signatureSink.addInt(x);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADUI");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_elementImportPrefixes;
    fb.Offset? offset_elementKinds;
    fb.Offset? offset_elementNameClassMemberIds;
    fb.Offset? offset_elementNameParameterIds;
    fb.Offset? offset_elementNameUnitMemberIds;
    fb.Offset? offset_elementUnits;
    fb.Offset? offset_libFragmentRefTargets;
    fb.Offset? offset_libFragmentRefUriLengths;
    fb.Offset? offset_libFragmentRefUriOffsets;
    fb.Offset? offset_strings;
    fb.Offset? offset_subtypes;
    fb.Offset? offset_supertypes;
    fb.Offset? offset_unitLibraryUris;
    fb.Offset? offset_unitUnitUris;
    fb.Offset? offset_usedElementIsQualifiedFlags;
    fb.Offset? offset_usedElementKinds;
    fb.Offset? offset_usedElementLengths;
    fb.Offset? offset_usedElementOffsets;
    fb.Offset? offset_usedElements;
    fb.Offset? offset_usedNameIsQualifiedFlags;
    fb.Offset? offset_usedNameKinds;
    fb.Offset? offset_usedNameOffsets;
    fb.Offset? offset_usedNames;
    var elementImportPrefixes = _elementImportPrefixes;
    if (!(elementImportPrefixes == null || elementImportPrefixes.isEmpty)) {
      offset_elementImportPrefixes = fbBuilder.writeList(
        elementImportPrefixes.map((b) => fbBuilder.writeString(b)).toList(),
      );
    }
    var elementKinds = _elementKinds;
    if (!(elementKinds == null || elementKinds.isEmpty)) {
      offset_elementKinds = fbBuilder.writeListUint8(
        elementKinds.map((b) => b.index).toList(),
      );
    }
    var elementNameClassMemberIds = _elementNameClassMemberIds;
    if (!(elementNameClassMemberIds == null ||
        elementNameClassMemberIds.isEmpty)) {
      offset_elementNameClassMemberIds = fbBuilder.writeListUint32(
        elementNameClassMemberIds,
      );
    }
    var elementNameParameterIds = _elementNameParameterIds;
    if (!(elementNameParameterIds == null || elementNameParameterIds.isEmpty)) {
      offset_elementNameParameterIds = fbBuilder.writeListUint32(
        elementNameParameterIds,
      );
    }
    var elementNameUnitMemberIds = _elementNameUnitMemberIds;
    if (!(elementNameUnitMemberIds == null ||
        elementNameUnitMemberIds.isEmpty)) {
      offset_elementNameUnitMemberIds = fbBuilder.writeListUint32(
        elementNameUnitMemberIds,
      );
    }
    var elementUnits = _elementUnits;
    if (!(elementUnits == null || elementUnits.isEmpty)) {
      offset_elementUnits = fbBuilder.writeListUint32(elementUnits);
    }
    var libFragmentRefTargets = _libFragmentRefTargets;
    if (!(libFragmentRefTargets == null || libFragmentRefTargets.isEmpty)) {
      offset_libFragmentRefTargets = fbBuilder.writeListUint32(
        libFragmentRefTargets,
      );
    }
    var libFragmentRefUriLengths = _libFragmentRefUriLengths;
    if (!(libFragmentRefUriLengths == null ||
        libFragmentRefUriLengths.isEmpty)) {
      offset_libFragmentRefUriLengths = fbBuilder.writeListUint32(
        libFragmentRefUriLengths,
      );
    }
    var libFragmentRefUriOffsets = _libFragmentRefUriOffsets;
    if (!(libFragmentRefUriOffsets == null ||
        libFragmentRefUriOffsets.isEmpty)) {
      offset_libFragmentRefUriOffsets = fbBuilder.writeListUint32(
        libFragmentRefUriOffsets,
      );
    }
    var strings = _strings;
    if (!(strings == null || strings.isEmpty)) {
      offset_strings = fbBuilder.writeList(
        strings.map((b) => fbBuilder.writeString(b)).toList(),
      );
    }
    var subtypes = _subtypes;
    if (!(subtypes == null || subtypes.isEmpty)) {
      offset_subtypes = fbBuilder.writeList(
        subtypes.map((b) => b.finish(fbBuilder)).toList(),
      );
    }
    var supertypes = _supertypes;
    if (!(supertypes == null || supertypes.isEmpty)) {
      offset_supertypes = fbBuilder.writeListUint32(supertypes);
    }
    var unitLibraryUris = _unitLibraryUris;
    if (!(unitLibraryUris == null || unitLibraryUris.isEmpty)) {
      offset_unitLibraryUris = fbBuilder.writeListUint32(unitLibraryUris);
    }
    var unitUnitUris = _unitUnitUris;
    if (!(unitUnitUris == null || unitUnitUris.isEmpty)) {
      offset_unitUnitUris = fbBuilder.writeListUint32(unitUnitUris);
    }
    var usedElementIsQualifiedFlags = _usedElementIsQualifiedFlags;
    if (!(usedElementIsQualifiedFlags == null ||
        usedElementIsQualifiedFlags.isEmpty)) {
      offset_usedElementIsQualifiedFlags = fbBuilder.writeListBool(
        usedElementIsQualifiedFlags,
      );
    }
    var usedElementKinds = _usedElementKinds;
    if (!(usedElementKinds == null || usedElementKinds.isEmpty)) {
      offset_usedElementKinds = fbBuilder.writeListUint8(
        usedElementKinds.map((b) => b.index).toList(),
      );
    }
    var usedElementLengths = _usedElementLengths;
    if (!(usedElementLengths == null || usedElementLengths.isEmpty)) {
      offset_usedElementLengths = fbBuilder.writeListUint32(usedElementLengths);
    }
    var usedElementOffsets = _usedElementOffsets;
    if (!(usedElementOffsets == null || usedElementOffsets.isEmpty)) {
      offset_usedElementOffsets = fbBuilder.writeListUint32(usedElementOffsets);
    }
    var usedElements = _usedElements;
    if (!(usedElements == null || usedElements.isEmpty)) {
      offset_usedElements = fbBuilder.writeListUint32(usedElements);
    }
    var usedNameIsQualifiedFlags = _usedNameIsQualifiedFlags;
    if (!(usedNameIsQualifiedFlags == null ||
        usedNameIsQualifiedFlags.isEmpty)) {
      offset_usedNameIsQualifiedFlags = fbBuilder.writeListBool(
        usedNameIsQualifiedFlags,
      );
    }
    var usedNameKinds = _usedNameKinds;
    if (!(usedNameKinds == null || usedNameKinds.isEmpty)) {
      offset_usedNameKinds = fbBuilder.writeListUint8(
        usedNameKinds.map((b) => b.index).toList(),
      );
    }
    var usedNameOffsets = _usedNameOffsets;
    if (!(usedNameOffsets == null || usedNameOffsets.isEmpty)) {
      offset_usedNameOffsets = fbBuilder.writeListUint32(usedNameOffsets);
    }
    var usedNames = _usedNames;
    if (!(usedNames == null || usedNames.isEmpty)) {
      offset_usedNames = fbBuilder.writeListUint32(usedNames);
    }
    fbBuilder.startTable();
    if (offset_elementImportPrefixes != null) {
      fbBuilder.addOffset(20, offset_elementImportPrefixes);
    }
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
    if (offset_libFragmentRefTargets != null) {
      fbBuilder.addOffset(21, offset_libFragmentRefTargets);
    }
    if (offset_libFragmentRefUriLengths != null) {
      fbBuilder.addOffset(23, offset_libFragmentRefUriLengths);
    }
    if (offset_libFragmentRefUriOffsets != null) {
      fbBuilder.addOffset(22, offset_libFragmentRefUriOffsets);
    }
    fbBuilder.addUint32(1, _nullStringId, 0);
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

  List<String>? _elementImportPrefixes;
  List<idl.IndexSyntheticElementKind>? _elementKinds;
  List<int>? _elementNameClassMemberIds;
  List<int>? _elementNameParameterIds;
  List<int>? _elementNameUnitMemberIds;
  List<int>? _elementUnits;
  List<int>? _libFragmentRefTargets;
  List<int>? _libFragmentRefUriLengths;
  List<int>? _libFragmentRefUriOffsets;
  int? _nullStringId;
  List<String>? _strings;
  List<idl.AnalysisDriverSubtype>? _subtypes;
  List<int>? _supertypes;
  List<int>? _unitLibraryUris;
  List<int>? _unitUnitUris;
  List<bool>? _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedElementKinds;
  List<int>? _usedElementLengths;
  List<int>? _usedElementOffsets;
  List<int>? _usedElements;
  List<bool>? _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedNameKinds;
  List<int>? _usedNameOffsets;
  List<int>? _usedNames;

  @override
  List<String> get elementImportPrefixes {
    return _elementImportPrefixes ??= const fb.ListReader<String>(
      fb.StringReader(),
    ).vTableGet(_bc, _bcOffset, 20, const <String>[]);
  }

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds {
    return _elementKinds ??= const fb.ListReader<idl.IndexSyntheticElementKind>(
      _IndexSyntheticElementKindReader(),
    ).vTableGet(_bc, _bcOffset, 4, const <idl.IndexSyntheticElementKind>[]);
  }

  @override
  List<int> get elementNameClassMemberIds {
    return _elementNameClassMemberIds ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      7,
      const <int>[],
    );
  }

  @override
  List<int> get elementNameParameterIds {
    return _elementNameParameterIds ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      8,
      const <int>[],
    );
  }

  @override
  List<int> get elementNameUnitMemberIds {
    return _elementNameUnitMemberIds ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      6,
      const <int>[],
    );
  }

  @override
  List<int> get elementUnits {
    return _elementUnits ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      5,
      const <int>[],
    );
  }

  @override
  List<int> get libFragmentRefTargets {
    return _libFragmentRefTargets ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      21,
      const <int>[],
    );
  }

  @override
  List<int> get libFragmentRefUriLengths {
    return _libFragmentRefUriLengths ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      23,
      const <int>[],
    );
  }

  @override
  List<int> get libFragmentRefUriOffsets {
    return _libFragmentRefUriOffsets ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      22,
      const <int>[],
    );
  }

  @override
  int get nullStringId {
    return _nullStringId ??= const fb.Uint32Reader().vTableGet(
      _bc,
      _bcOffset,
      1,
      0,
    );
  }

  @override
  List<String> get strings {
    return _strings ??= const fb.ListReader<String>(
      fb.StringReader(),
    ).vTableGet(_bc, _bcOffset, 0, const <String>[]);
  }

  @override
  List<idl.AnalysisDriverSubtype> get subtypes {
    return _subtypes ??= const fb.ListReader<idl.AnalysisDriverSubtype>(
      _AnalysisDriverSubtypeReader(),
    ).vTableGet(_bc, _bcOffset, 19, const <idl.AnalysisDriverSubtype>[]);
  }

  @override
  List<int> get supertypes {
    return _supertypes ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      18,
      const <int>[],
    );
  }

  @override
  List<int> get unitLibraryUris {
    return _unitLibraryUris ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      2,
      const <int>[],
    );
  }

  @override
  List<int> get unitUnitUris {
    return _unitUnitUris ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      3,
      const <int>[],
    );
  }

  @override
  List<bool> get usedElementIsQualifiedFlags {
    return _usedElementIsQualifiedFlags ??= const fb.BoolListReader().vTableGet(
      _bc,
      _bcOffset,
      13,
      const <bool>[],
    );
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds {
    return _usedElementKinds ??= const fb.ListReader<idl.IndexRelationKind>(
      _IndexRelationKindReader(),
    ).vTableGet(_bc, _bcOffset, 10, const <idl.IndexRelationKind>[]);
  }

  @override
  List<int> get usedElementLengths {
    return _usedElementLengths ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      12,
      const <int>[],
    );
  }

  @override
  List<int> get usedElementOffsets {
    return _usedElementOffsets ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      11,
      const <int>[],
    );
  }

  @override
  List<int> get usedElements {
    return _usedElements ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      9,
      const <int>[],
    );
  }

  @override
  List<bool> get usedNameIsQualifiedFlags {
    return _usedNameIsQualifiedFlags ??= const fb.BoolListReader().vTableGet(
      _bc,
      _bcOffset,
      17,
      const <bool>[],
    );
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds {
    return _usedNameKinds ??= const fb.ListReader<idl.IndexRelationKind>(
      _IndexRelationKindReader(),
    ).vTableGet(_bc, _bcOffset, 15, const <idl.IndexRelationKind>[]);
  }

  @override
  List<int> get usedNameOffsets {
    return _usedNameOffsets ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      16,
      const <int>[],
    );
  }

  @override
  List<int> get usedNames {
    return _usedNames ??= const fb.Uint32ListReader().vTableGet(
      _bc,
      _bcOffset,
      14,
      const <int>[],
    );
  }
}

mixin _AnalysisDriverUnitIndexMixin implements idl.AnalysisDriverUnitIndex {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_elementImportPrefixes = elementImportPrefixes;
    if (local_elementImportPrefixes.isNotEmpty) {
      result["elementImportPrefixes"] = local_elementImportPrefixes;
    }
    var local_elementKinds = elementKinds;
    if (local_elementKinds.isNotEmpty) {
      result["elementKinds"] = local_elementKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_elementNameClassMemberIds = elementNameClassMemberIds;
    if (local_elementNameClassMemberIds.isNotEmpty) {
      result["elementNameClassMemberIds"] = local_elementNameClassMemberIds;
    }
    var local_elementNameParameterIds = elementNameParameterIds;
    if (local_elementNameParameterIds.isNotEmpty) {
      result["elementNameParameterIds"] = local_elementNameParameterIds;
    }
    var local_elementNameUnitMemberIds = elementNameUnitMemberIds;
    if (local_elementNameUnitMemberIds.isNotEmpty) {
      result["elementNameUnitMemberIds"] = local_elementNameUnitMemberIds;
    }
    var local_elementUnits = elementUnits;
    if (local_elementUnits.isNotEmpty) {
      result["elementUnits"] = local_elementUnits;
    }
    var local_libFragmentRefTargets = libFragmentRefTargets;
    if (local_libFragmentRefTargets.isNotEmpty) {
      result["libFragmentRefTargets"] = local_libFragmentRefTargets;
    }
    var local_libFragmentRefUriLengths = libFragmentRefUriLengths;
    if (local_libFragmentRefUriLengths.isNotEmpty) {
      result["libFragmentRefUriLengths"] = local_libFragmentRefUriLengths;
    }
    var local_libFragmentRefUriOffsets = libFragmentRefUriOffsets;
    if (local_libFragmentRefUriOffsets.isNotEmpty) {
      result["libFragmentRefUriOffsets"] = local_libFragmentRefUriOffsets;
    }
    var local_nullStringId = nullStringId;
    if (local_nullStringId != 0) {
      result["nullStringId"] = local_nullStringId;
    }
    var local_strings = strings;
    if (local_strings.isNotEmpty) {
      result["strings"] = local_strings;
    }
    var local_subtypes = subtypes;
    if (local_subtypes.isNotEmpty) {
      result["subtypes"] = local_subtypes
          .map((value) => value.toJson())
          .toList();
    }
    var local_supertypes = supertypes;
    if (local_supertypes.isNotEmpty) {
      result["supertypes"] = local_supertypes;
    }
    var local_unitLibraryUris = unitLibraryUris;
    if (local_unitLibraryUris.isNotEmpty) {
      result["unitLibraryUris"] = local_unitLibraryUris;
    }
    var local_unitUnitUris = unitUnitUris;
    if (local_unitUnitUris.isNotEmpty) {
      result["unitUnitUris"] = local_unitUnitUris;
    }
    var local_usedElementIsQualifiedFlags = usedElementIsQualifiedFlags;
    if (local_usedElementIsQualifiedFlags.isNotEmpty) {
      result["usedElementIsQualifiedFlags"] = local_usedElementIsQualifiedFlags;
    }
    var local_usedElementKinds = usedElementKinds;
    if (local_usedElementKinds.isNotEmpty) {
      result["usedElementKinds"] = local_usedElementKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_usedElementLengths = usedElementLengths;
    if (local_usedElementLengths.isNotEmpty) {
      result["usedElementLengths"] = local_usedElementLengths;
    }
    var local_usedElementOffsets = usedElementOffsets;
    if (local_usedElementOffsets.isNotEmpty) {
      result["usedElementOffsets"] = local_usedElementOffsets;
    }
    var local_usedElements = usedElements;
    if (local_usedElements.isNotEmpty) {
      result["usedElements"] = local_usedElements;
    }
    var local_usedNameIsQualifiedFlags = usedNameIsQualifiedFlags;
    if (local_usedNameIsQualifiedFlags.isNotEmpty) {
      result["usedNameIsQualifiedFlags"] = local_usedNameIsQualifiedFlags;
    }
    var local_usedNameKinds = usedNameKinds;
    if (local_usedNameKinds.isNotEmpty) {
      result["usedNameKinds"] = local_usedNameKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_usedNameOffsets = usedNameOffsets;
    if (local_usedNameOffsets.isNotEmpty) {
      result["usedNameOffsets"] = local_usedNameOffsets;
    }
    var local_usedNames = usedNames;
    if (local_usedNames.isNotEmpty) {
      result["usedNames"] = local_usedNames;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
    "elementImportPrefixes": elementImportPrefixes,
    "elementKinds": elementKinds,
    "elementNameClassMemberIds": elementNameClassMemberIds,
    "elementNameParameterIds": elementNameParameterIds,
    "elementNameUnitMemberIds": elementNameUnitMemberIds,
    "elementUnits": elementUnits,
    "libFragmentRefTargets": libFragmentRefTargets,
    "libFragmentRefUriLengths": libFragmentRefUriLengths,
    "libFragmentRefUriOffsets": libFragmentRefUriOffsets,
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

class CiderUnitErrorsBuilder extends Object
    with _CiderUnitErrorsMixin
    implements idl.CiderUnitErrors {
  List<AnalysisDriverUnitErrorBuilder>? _errors;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  CiderUnitErrorsBuilder({List<AnalysisDriverUnitErrorBuilder>? errors})
    : _errors = errors;

  /// Flush informative data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var errors = this._errors;
    if (errors == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(errors.length);
      for (var x in errors) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "CUEr");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_errors;
    var errors = _errors;
    if (!(errors == null || errors.isEmpty)) {
      offset_errors = fbBuilder.writeList(
        errors.map((b) => b.finish(fbBuilder)).toList(),
      );
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
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

  List<idl.AnalysisDriverUnitError>? _errors;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    return _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
      _AnalysisDriverUnitErrorReader(),
    ).vTableGet(_bc, _bcOffset, 0, const <idl.AnalysisDriverUnitError>[]);
  }
}

mixin _CiderUnitErrorsMixin implements idl.CiderUnitErrors {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_errors = errors;
    if (local_errors.isNotEmpty) {
      result["errors"] = local_errors.map((value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {"errors": errors};

  @override
  String toString() => convert.json.encode(toJson());
}

class DiagnosticMessageBuilder extends Object
    with _DiagnosticMessageMixin
    implements idl.DiagnosticMessage {
  String? _filePath;
  int? _length;
  String? _message;
  int? _offset;
  String? _url;

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
    assert(value >= 0);
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
    assert(value >= 0);
    this._offset = value;
  }

  @override
  String get url => _url ??= '';

  /// The URL of the message, if any.
  set url(String value) {
    this._url = value;
  }

  DiagnosticMessageBuilder({
    String? filePath,
    int? length,
    String? message,
    int? offset,
    String? url,
  }) : _filePath = filePath,
       _length = length,
       _message = message,
       _offset = offset,
       _url = url;

  /// Flush informative data recursively.
  void flushInformative() {}

  /// Accumulate non-informative data into [signatureSink].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._filePath ?? '');
    signatureSink.addInt(this._length ?? 0);
    signatureSink.addString(this._message ?? '');
    signatureSink.addInt(this._offset ?? 0);
    signatureSink.addString(this._url ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_filePath;
    fb.Offset? offset_message;
    fb.Offset? offset_url;
    var filePath = _filePath;
    if (filePath != null) {
      offset_filePath = fbBuilder.writeString(filePath);
    }
    var message = _message;
    if (message != null) {
      offset_message = fbBuilder.writeString(message);
    }
    var url = _url;
    if (url != null) {
      offset_url = fbBuilder.writeString(url);
    }
    fbBuilder.startTable();
    if (offset_filePath != null) {
      fbBuilder.addOffset(0, offset_filePath);
    }
    fbBuilder.addUint32(1, _length, 0);
    if (offset_message != null) {
      fbBuilder.addOffset(2, offset_message);
    }
    fbBuilder.addUint32(3, _offset, 0);
    if (offset_url != null) {
      fbBuilder.addOffset(4, offset_url);
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

  String? _filePath;
  int? _length;
  String? _message;
  int? _offset;
  String? _url;

  @override
  String get filePath {
    return _filePath ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      0,
      '',
    );
  }

  @override
  int get length {
    return _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  String get message {
    return _message ??= const fb.StringReader().vTableGet(
      _bc,
      _bcOffset,
      2,
      '',
    );
  }

  @override
  int get offset {
    return _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
  }

  @override
  String get url {
    return _url ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
  }
}

mixin _DiagnosticMessageMixin implements idl.DiagnosticMessage {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_filePath = filePath;
    if (local_filePath != '') {
      result["filePath"] = local_filePath;
    }
    var local_length = length;
    if (local_length != 0) {
      result["length"] = local_length;
    }
    var local_message = message;
    if (local_message != '') {
      result["message"] = local_message;
    }
    var local_offset = offset;
    if (local_offset != 0) {
      result["offset"] = local_offset;
    }
    var local_url = url;
    if (local_url != '') {
      result["url"] = local_url;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
    "filePath": filePath,
    "length": length,
    "message": message,
    "offset": offset,
    "url": url,
  };

  @override
  String toString() => convert.json.encode(toJson());
}
