// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'dart:convert' as convert;

import 'package:analyzer/src/summary/api_signature.dart' as api_sig;
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;

import 'idl.dart' as idl;

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
        : idl.UnlinkedParamKind.required;
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

  /**
   * The exception string.
   */
  void set exception(String value) {
    this._exception = value;
  }

  @override
  List<AnalysisDriverExceptionFileBuilder> get files =>
      _files ??= <AnalysisDriverExceptionFileBuilder>[];

  /**
   * The state of files when the exception happened.
   */
  void set files(List<AnalysisDriverExceptionFileBuilder> value) {
    this._files = value;
  }

  @override
  String get path => _path ??= '';

  /**
   * The path of the file being analyzed when the exception happened.
   */
  void set path(String value) {
    this._path = value;
  }

  @override
  String get stackTrace => _stackTrace ??= '';

  /**
   * The exception stack trace string.
   */
  void set stackTrace(String value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _files?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class AnalysisDriverExceptionFileBuilder extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  String _content;
  String _path;

  @override
  String get content => _content ??= '';

  /**
   * The content of the file.
   */
  void set content(String value) {
    this._content = value;
  }

  @override
  String get path => _path ??= '';

  /**
   * The path of the file.
   */
  void set path(String value) {
    this._path = value;
  }

  AnalysisDriverExceptionFileBuilder({String content, String path})
      : _content = content,
        _path = path;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class AnalysisDriverResolvedUnitBuilder extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  List<AnalysisDriverUnitErrorBuilder> _errors;
  AnalysisDriverUnitIndexBuilder _index;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  /**
   * The full list of analysis errors, both syntactic and semantic.
   */
  void set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  @override
  AnalysisDriverUnitIndexBuilder get index => _index;

  /**
   * The index of the unit.
   */
  void set index(AnalysisDriverUnitIndexBuilder value) {
    this._index = value;
  }

  AnalysisDriverResolvedUnitBuilder(
      {List<AnalysisDriverUnitErrorBuilder> errors,
      AnalysisDriverUnitIndexBuilder index})
      : _errors = errors,
        _index = index;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
    _index?.flushInformative();
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class AnalysisDriverSubtypeBuilder extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  List<String> _members;
  String _name;
  List<String> _supertypes;

  @override
  List<String> get members => _members ??= <String>[];

  /**
   * The names of defined instance members.
   * The list is sorted in ascending order.
   */
  void set members(List<String> value) {
    this._members = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * The name of the class.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  List<String> get supertypes => _supertypes ??= <String>[];

  /**
   * The identifiers of the direct supertypes.
   * The list is sorted in ascending order.
   */
  void set supertypes(List<String> value) {
    this._supertypes = value;
  }

  AnalysisDriverSubtypeBuilder(
      {List<String> members, String name, List<String> supertypes})
      : _members = members,
        _name = name,
        _supertypes = supertypes;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    if (this._supertypes == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._supertypes.length);
      for (var x in this._supertypes) {
        signature.addString(x);
      }
    }
    if (this._members == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._members.length);
      for (var x in this._members) {
        signature.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_members;
    fb.Offset offset_name;
    fb.Offset offset_supertypes;
    if (!(_members == null || _members.isEmpty)) {
      offset_members = fbBuilder
          .writeList(_members.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (!(_supertypes == null || _supertypes.isEmpty)) {
      offset_supertypes = fbBuilder
          .writeList(_supertypes.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_members != null) {
      fbBuilder.addOffset(2, offset_members);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (offset_supertypes != null) {
      fbBuilder.addOffset(1, offset_supertypes);
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

  List<String> _members;
  String _name;
  List<String> _supertypes;

  @override
  List<String> get members {
    _members ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _members;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  List<String> get supertypes {
    _supertypes ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _supertypes;
  }
}

abstract class _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (members.isNotEmpty) _result["members"] = members;
    if (name != '') _result["name"] = name;
    if (supertypes.isNotEmpty) _result["supertypes"] = supertypes;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "members": members,
        "name": name,
        "supertypes": supertypes,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * The optional correction hint for the error.
   */
  void set correction(String value) {
    this._correction = value;
  }

  @override
  int get length => _length ??= 0;

  /**
   * The length of the error in the file.
   */
  void set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  /**
   * The message of the error.
   */
  void set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * The offset from the beginning of the file.
   */
  void set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  String get uniqueName => _uniqueName ??= '';

  /**
   * The unique name of the error code.
   */
  void set uniqueName(String value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the kind of the synthetic element.
   */
  void set elementKinds(List<idl.IndexSyntheticElementKind> value) {
    this._elementKinds = value;
  }

  @override
  List<int> get elementNameClassMemberIds =>
      _elementNameClassMemberIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the class member element name, or `null` if the element
   * is a top-level element.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this index.
   */
  void set elementNameClassMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the named parameter name, or `null` if the element is not
   * a named parameter.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this index.
   */
  void set elementNameParameterIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameParameterIds = value;
  }

  @override
  List<int> get elementNameUnitMemberIds =>
      _elementNameUnitMemberIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the top-level element name, or `null` if the element is
   * the unit.  The list is sorted in ascending order, so that the client can
   * quickly check whether an element is referenced in this index.
   */
  void set elementNameUnitMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the index into [unitLibraryUris] and [unitUnitUris] for the library
   * specific unit where the element is declared.
   */
  void set elementUnits(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  int get nullStringId => _nullStringId ??= 0;

  /**
   * Identifier of the null string in [strings].
   */
  void set nullStringId(int value) {
    assert(value == null || value >= 0);
    this._nullStringId = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /**
   * List of unique element strings used in this index.  The list is sorted in
   * ascending order, so that the client can quickly check the presence of a
   * string in this index.
   */
  void set strings(List<String> value) {
    this._strings = value;
  }

  @override
  List<AnalysisDriverSubtypeBuilder> get subtypes =>
      _subtypes ??= <AnalysisDriverSubtypeBuilder>[];

  /**
   * The list of classes declared in the unit.
   */
  void set subtypes(List<AnalysisDriverSubtypeBuilder> value) {
    this._subtypes = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /**
   * Each item of this list corresponds to the library URI of a unique library
   * specific unit referenced in the index.  It is an index into [strings] list.
   */
  void set unitLibraryUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /**
   * Each item of this list corresponds to the unit URI of a unique library
   * specific unit referenced in the index.  It is an index into [strings] list.
   */
  void set unitUnitUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitUnitUris = value;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags =>
      _usedElementIsQualifiedFlags ??= <bool>[];

  /**
   * Each item of this list is the `true` if the corresponding element usage
   * is qualified with some prefix.
   */
  void set usedElementIsQualifiedFlags(List<bool> value) {
    this._usedElementIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds =>
      _usedElementKinds ??= <idl.IndexRelationKind>[];

  /**
   * Each item of this list is the kind of the element usage.
   */
  void set usedElementKinds(List<idl.IndexRelationKind> value) {
    this._usedElementKinds = value;
  }

  @override
  List<int> get usedElementLengths => _usedElementLengths ??= <int>[];

  /**
   * Each item of this list is the length of the element usage.
   */
  void set usedElementLengths(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /**
   * Each item of this list is the offset of the element usage relative to the
   * beginning of the file.
   */
  void set usedElementOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /**
   * Each item of this list is the index into [elementUnits],
   * [elementNameUnitMemberIds], [elementNameClassMemberIds] and
   * [elementNameParameterIds].  The list is sorted in ascending order, so
   * that the client can quickly find element references in this index.
   */
  void set usedElements(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElements = value;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags =>
      _usedNameIsQualifiedFlags ??= <bool>[];

  /**
   * Each item of this list is the `true` if the corresponding name usage
   * is qualified with some prefix.
   */
  void set usedNameIsQualifiedFlags(List<bool> value) {
    this._usedNameIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds =>
      _usedNameKinds ??= <idl.IndexRelationKind>[];

  /**
   * Each item of this list is the kind of the name usage.
   */
  void set usedNameKinds(List<idl.IndexRelationKind> value) {
    this._usedNameKinds = value;
  }

  @override
  List<int> get usedNameOffsets => _usedNameOffsets ??= <int>[];

  /**
   * Each item of this list is the offset of the name usage relative to the
   * beginning of the file.
   */
  void set usedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /**
   * Each item of this list is the index into [strings] for a used name.  The
   * list is sorted in ascending order, so that the client can quickly find
   * whether a name is used in this index.
   */
  void set usedNames(List<int> value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _subtypes?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
      fbBuilder.addOffset(18, offset_subtypes);
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
        .vTableGet(_bc, _bcOffset, 18, const <idl.AnalysisDriverSubtype>[]);
    return _subtypes;
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
  String toString() => convert.JSON.encode(toJson());
}

class AnalysisDriverUnlinkedUnitBuilder extends Object
    with _AnalysisDriverUnlinkedUnitMixin
    implements idl.AnalysisDriverUnlinkedUnit {
  List<String> _definedClassMemberNames;
  List<String> _definedTopLevelNames;
  List<String> _referencedNames;
  List<String> _subtypedNames;
  UnlinkedUnitBuilder _unit;

  @override
  List<String> get definedClassMemberNames =>
      _definedClassMemberNames ??= <String>[];

  /**
   * List of class member names defined by the unit.
   */
  void set definedClassMemberNames(List<String> value) {
    this._definedClassMemberNames = value;
  }

  @override
  List<String> get definedTopLevelNames => _definedTopLevelNames ??= <String>[];

  /**
   * List of top-level names defined by the unit.
   */
  void set definedTopLevelNames(List<String> value) {
    this._definedTopLevelNames = value;
  }

  @override
  List<String> get referencedNames => _referencedNames ??= <String>[];

  /**
   * List of external names referenced by the unit.
   */
  void set referencedNames(List<String> value) {
    this._referencedNames = value;
  }

  @override
  List<String> get subtypedNames => _subtypedNames ??= <String>[];

  /**
   * List of names which are used in `extends`, `with` or `implements` clauses
   * in the file. Import prefixes and type arguments are not included.
   */
  void set subtypedNames(List<String> value) {
    this._subtypedNames = value;
  }

  @override
  UnlinkedUnitBuilder get unit => _unit;

  /**
   * Unlinked information for the unit.
   */
  void set unit(UnlinkedUnitBuilder value) {
    this._unit = value;
  }

  AnalysisDriverUnlinkedUnitBuilder(
      {List<String> definedClassMemberNames,
      List<String> definedTopLevelNames,
      List<String> referencedNames,
      List<String> subtypedNames,
      UnlinkedUnitBuilder unit})
      : _definedClassMemberNames = definedClassMemberNames,
        _definedTopLevelNames = definedTopLevelNames,
        _referencedNames = referencedNames,
        _subtypedNames = subtypedNames,
        _unit = unit;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _unit?.flushInformative();
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "definedClassMemberNames": definedClassMemberNames,
        "definedTopLevelNames": definedTopLevelNames,
        "referencedNames": referencedNames,
        "subtypedNames": subtypedNames,
        "unit": unit,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
}

class CodeRangeBuilder extends Object
    with _CodeRangeMixin
    implements idl.CodeRange {
  int _length;
  int _offset;

  @override
  int get length => _length ??= 0;

  /**
   * Length of the element code.
   */
  void set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * Offset of the element code relative to the beginning of the file.
   */
  void set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  CodeRangeBuilder({int length, int offset})
      : _length = length,
        _offset = offset;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class EntityRefBuilder extends Object
    with _EntityRefMixin
    implements idl.EntityRef {
  idl.EntityRefKind _entityKind;
  List<int> _implicitFunctionTypeIndices;
  int _paramReference;
  int _reference;
  int _slot;
  List<UnlinkedParamBuilder> _syntheticParams;
  EntityRefBuilder _syntheticReturnType;
  List<EntityRefBuilder> _typeArguments;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  idl.EntityRefKind get entityKind => _entityKind ??= idl.EntityRefKind.named;

  /**
   * The kind of entity being represented.
   */
  void set entityKind(idl.EntityRefKind value) {
    this._entityKind = value;
  }

  @override
  List<int> get implicitFunctionTypeIndices =>
      _implicitFunctionTypeIndices ??= <int>[];

  /**
   * If this is a reference to a function type implicitly defined by a
   * function-typed parameter, a list of zero-based indices indicating the path
   * from the entity referred to by [reference] to the appropriate type
   * parameter.  Otherwise the empty list.
   *
   * If there are N indices in this list, then the entity being referred to is
   * the function type implicitly defined by a function-typed parameter of a
   * function-typed parameter, to N levels of nesting.  The first index in the
   * list refers to the outermost level of nesting; for example if [reference]
   * refers to the entity defined by:
   *
   *     void f(x, void g(y, z, int h(String w))) { ... }
   *
   * Then to refer to the function type implicitly defined by parameter `h`
   * (which is parameter 2 of parameter 1 of `f`), then
   * [implicitFunctionTypeIndices] should be [1, 2].
   *
   * Note that if the entity being referred to is a generic method inside a
   * generic class, then the type arguments in [typeArguments] are applied
   * first to the class and then to the method.
   */
  void set implicitFunctionTypeIndices(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._implicitFunctionTypeIndices = value;
  }

  @override
  int get paramReference => _paramReference ??= 0;

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  void set paramReference(int value) {
    assert(value == null || value >= 0);
    this._paramReference = value;
  }

  @override
  int get reference => _reference ??= 0;

  /**
   * Index into [UnlinkedUnit.references] for the entity being referred to, or
   * zero if this is a reference to a type parameter.
   */
  void set reference(int value) {
    assert(value == null || value >= 0);
    this._reference = value;
  }

  @override
  int get slot => _slot ??= 0;

  /**
   * If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [EntityRef] is associated.
   *
   * Otherwise zero.
   */
  void set slot(int value) {
    assert(value == null || value >= 0);
    this._slot = value;
  }

  @override
  List<UnlinkedParamBuilder> get syntheticParams =>
      _syntheticParams ??= <UnlinkedParamBuilder>[];

  /**
   * If this [EntityRef] is a reference to a function type whose
   * [FunctionElement] is not in any library (e.g. a function type that was
   * synthesized by a LUB computation), the function parameters.  Otherwise
   * empty.
   */
  void set syntheticParams(List<UnlinkedParamBuilder> value) {
    this._syntheticParams = value;
  }

  @override
  EntityRefBuilder get syntheticReturnType => _syntheticReturnType;

  /**
   * If this [EntityRef] is a reference to a function type whose
   * [FunctionElement] is not in any library (e.g. a function type that was
   * synthesized by a LUB computation), the return type of the function.
   * Otherwise `null`.
   */
  void set syntheticReturnType(EntityRefBuilder value) {
    this._syntheticReturnType = value;
  }

  @override
  List<EntityRefBuilder> get typeArguments =>
      _typeArguments ??= <EntityRefBuilder>[];

  /**
   * If this is an instantiation of a generic type or generic executable, the
   * type arguments used to instantiate it (if any).
   */
  void set typeArguments(List<EntityRefBuilder> value) {
    this._typeArguments = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * If this is a function type, the type parameters defined for the function
   * type (if any).
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  EntityRefBuilder(
      {idl.EntityRefKind entityKind,
      List<int> implicitFunctionTypeIndices,
      int paramReference,
      int reference,
      int slot,
      List<UnlinkedParamBuilder> syntheticParams,
      EntityRefBuilder syntheticReturnType,
      List<EntityRefBuilder> typeArguments,
      List<UnlinkedTypeParamBuilder> typeParameters})
      : _entityKind = entityKind,
        _implicitFunctionTypeIndices = implicitFunctionTypeIndices,
        _paramReference = paramReference,
        _reference = reference,
        _slot = slot,
        _syntheticParams = syntheticParams,
        _syntheticReturnType = syntheticReturnType,
        _typeArguments = typeArguments,
        _typeParameters = typeParameters;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _syntheticParams?.forEach((b) => b.flushInformative());
    _syntheticReturnType?.flushInformative();
    _typeArguments?.forEach((b) => b.flushInformative());
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
    if (_paramReference != null && _paramReference != 0) {
      fbBuilder.addUint32(3, _paramReference);
    }
    if (_reference != null && _reference != 0) {
      fbBuilder.addUint32(0, _reference);
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
  int _paramReference;
  int _reference;
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
    if (paramReference != 0) _result["paramReference"] = paramReference;
    if (reference != 0) _result["reference"] = reference;
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
        "paramReference": paramReference,
        "reference": reference,
        "slot": slot,
        "syntheticParams": syntheticParams,
        "syntheticReturnType": syntheticReturnType,
        "typeArguments": typeArguments,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
}

class LinkedDependencyBuilder extends Object
    with _LinkedDependencyMixin
    implements idl.LinkedDependency {
  List<String> _parts;
  String _uri;

  @override
  List<String> get parts => _parts ??= <String>[];

  /**
   * Absolute URI for the compilation units listed in the library's `part`
   * declarations, empty string for invalid URI.
   */
  void set parts(List<String> value) {
    this._parts = value;
  }

  @override
  String get uri => _uri ??= '';

  /**
   * The absolute URI of the dependent library, e.g. `package:foo/bar.dart`.
   */
  void set uri(String value) {
    this._uri = value;
  }

  LinkedDependencyBuilder({List<String> parts, String uri})
      : _parts = parts,
        _uri = uri;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  void set dependency(int value) {
    assert(value == null || value >= 0);
    this._dependency = value;
  }

  @override
  idl.ReferenceKind get kind => _kind ??= idl.ReferenceKind.classOrEnum;

  /**
   * The kind of the entity being referred to.
   */
  void set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the exported entity.  For an exported setter, this name includes
   * the trailing '='.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get unit => _unit ??= 0;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  void set unit(int value) {
    assert(value == null || value >= 0);
    this._unit = value;
  }

  LinkedExportNameBuilder(
      {int dependency, idl.ReferenceKind kind, String name, int unit})
      : _dependency = dependency,
        _kind = kind,
        _name = name,
        _unit = unit;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for `dynamic` and
   * `void`).  This is followed by elements representing "prelinked"
   * dependencies (direct imports and the transitive closure of exports).
   * After the prelinked dependencies are elements representing "linked"
   * dependencies.
   *
   * A library is only included as a "linked" dependency if it is a true
   * dependency (e.g. a propagated or inferred type or constant value
   * implicitly refers to an element declared in the library) or
   * anti-dependency (e.g. the result of type propagation or type inference
   * depends on the lack of a certain declaration in the library).
   */
  void set dependencies(List<LinkedDependencyBuilder> value) {
    this._dependencies = value;
  }

  @override
  List<int> get exportDependencies => _exportDependencies ??= <int>[];

  /**
   * For each export in [UnlinkedUnit.exports], an index into [dependencies]
   * of the library being exported.
   */
  void set exportDependencies(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._exportDependencies = value;
  }

  @override
  List<LinkedExportNameBuilder> get exportNames =>
      _exportNames ??= <LinkedExportNameBuilder>[];

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  void set exportNames(List<LinkedExportNameBuilder> value) {
    this._exportNames = value;
  }

  @override
  bool get fallbackMode =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<int> get importDependencies => _importDependencies ??= <int>[];

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  void set importDependencies(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._importDependencies = value;
  }

  @override
  int get numPrelinkedDependencies => _numPrelinkedDependencies ??= 0;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  void set numPrelinkedDependencies(int value) {
    assert(value == null || value >= 0);
    this._numPrelinkedDependencies = value;
  }

  @override
  List<LinkedUnitBuilder> get units => _units ??= <LinkedUnitBuilder>[];

  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  void set units(List<LinkedUnitBuilder> value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _dependencies?.forEach((b) => b.flushInformative());
    _exportNames?.forEach((b) => b.flushInformative());
    _units?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  bool get fallbackMode =>
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * and the entity being referred to is contained within another entity, index
   * of the containing entity.  This behaves similarly to
   * [UnlinkedReference.prefixReference], however it is only used for class
   * members, not for prefixed imports.
   *
   * Containing references must always point backward; that is, for all i, if
   * LinkedUnit.references[i].containingReference != 0, then
   * LinkedUnit.references[i].containingReference < i.
   */
  void set containingReference(int value) {
    assert(value == null || value >= 0);
    this._containingReference = value;
  }

  @override
  int get dependency => _dependency ??= 0;

  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member), or if [kind] is [ReferenceKind.prefix].
   */
  void set dependency(int value) {
    assert(value == null || value >= 0);
    this._dependency = value;
  }

  @override
  idl.ReferenceKind get kind => _kind ??= idl.ReferenceKind.classOrEnum;

  /**
   * The kind of the entity being referred to.  For the pseudo-types `dynamic`
   * and `void`, the kind is [ReferenceKind.classOrEnum].
   */
  void set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  int get localIndex =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name => _name ??= '';

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it declares (does not include type parameters of enclosing entities).
   * Otherwise zero.
   */
  void set numTypeParameters(int value) {
    assert(value == null || value >= 0);
    this._numTypeParameters = value;
  }

  @override
  int get unit => _unit ??= 0;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member).
   */
  void set unit(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  int get localIndex =>
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
  String toString() => convert.JSON.encode(toJson());
}

class LinkedUnitBuilder extends Object
    with _LinkedUnitMixin
    implements idl.LinkedUnit {
  List<int> _constCycles;
  List<int> _parametersInheritingCovariant;
  List<LinkedReferenceBuilder> _references;
  List<TopLevelInferenceErrorBuilder> _topLevelInferenceErrors;
  List<EntityRefBuilder> _types;

  @override
  List<int> get constCycles => _constCycles ??= <int>[];

  /**
   * List of slot ids (referring to [UnlinkedExecutable.constCycleSlot])
   * corresponding to const constructors that are part of cycles.
   */
  void set constCycles(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._constCycles = value;
  }

  @override
  List<int> get parametersInheritingCovariant =>
      _parametersInheritingCovariant ??= <int>[];

  /**
   * List of slot ids (referring to [UnlinkedParam.inheritsCovariantSlot] or
   * [UnlinkedVariable.inheritsCovariantSlot]) corresponding to parameters
   * that inherit `@covariant` behavior from a base class.
   */
  void set parametersInheritingCovariant(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._parametersInheritingCovariant = value;
  }

  @override
  List<LinkedReferenceBuilder> get references =>
      _references ??= <LinkedReferenceBuilder>[];

  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  void set references(List<LinkedReferenceBuilder> value) {
    this._references = value;
  }

  @override
  List<TopLevelInferenceErrorBuilder> get topLevelInferenceErrors =>
      _topLevelInferenceErrors ??= <TopLevelInferenceErrorBuilder>[];

  /**
   * The list of type inference errors.
   */
  void set topLevelInferenceErrors(List<TopLevelInferenceErrorBuilder> value) {
    this._topLevelInferenceErrors = value;
  }

  @override
  List<EntityRefBuilder> get types => _types ??= <EntityRefBuilder>[];

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  void set types(List<EntityRefBuilder> value) {
    this._types = value;
  }

  LinkedUnitBuilder(
      {List<int> constCycles,
      List<int> parametersInheritingCovariant,
      List<LinkedReferenceBuilder> references,
      List<TopLevelInferenceErrorBuilder> topLevelInferenceErrors,
      List<EntityRefBuilder> types})
      : _constCycles = constCycles,
        _parametersInheritingCovariant = parametersInheritingCovariant,
        _references = references,
        _topLevelInferenceErrors = topLevelInferenceErrors,
        _types = types;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _references?.forEach((b) => b.flushInformative());
    _topLevelInferenceErrors?.forEach((b) => b.flushInformative());
    _types?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_constCycles;
    fb.Offset offset_parametersInheritingCovariant;
    fb.Offset offset_references;
    fb.Offset offset_topLevelInferenceErrors;
    fb.Offset offset_types;
    if (!(_constCycles == null || _constCycles.isEmpty)) {
      offset_constCycles = fbBuilder.writeListUint32(_constCycles);
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
        "parametersInheritingCovariant": parametersInheritingCovariant,
        "references": references,
        "topLevelInferenceErrors": topLevelInferenceErrors,
        "types": types,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
}

class PackageBundleBuilder extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  String _apiSignature;
  List<PackageDependencyInfoBuilder> _dependencies;
  List<LinkedLibraryBuilder> _linkedLibraries;
  List<String> _linkedLibraryUris;
  int _majorVersion;
  int _minorVersion;
  List<String> _unlinkedUnitHashes;
  List<UnlinkedUnitBuilder> _unlinkedUnits;
  List<String> _unlinkedUnitUris;

  @override
  String get apiSignature => _apiSignature ??= '';

  /**
   * MD5 hash of the non-informative fields of the [PackageBundle] (not
   * including this one).  This can be used to identify when the API of a
   * package may have changed.
   */
  void set apiSignature(String value) {
    this._apiSignature = value;
  }

  @override
  List<PackageDependencyInfoBuilder> get dependencies =>
      _dependencies ??= <PackageDependencyInfoBuilder>[];

  /**
   * Information about the packages this package depends on, if known.
   */
  void set dependencies(List<PackageDependencyInfoBuilder> value) {
    this._dependencies = value;
  }

  @override
  List<LinkedLibraryBuilder> get linkedLibraries =>
      _linkedLibraries ??= <LinkedLibraryBuilder>[];

  /**
   * Linked libraries.
   */
  void set linkedLibraries(List<LinkedLibraryBuilder> value) {
    this._linkedLibraries = value;
  }

  @override
  List<String> get linkedLibraryUris => _linkedLibraryUris ??= <String>[];

  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core` or
   * `package:foo/bar.dart`.
   */
  void set linkedLibraryUris(List<String> value) {
    this._linkedLibraryUris = value;
  }

  @override
  int get majorVersion => _majorVersion ??= 0;

  /**
   * Major version of the summary format.  See
   * [PackageBundleAssembler.currentMajorVersion].
   */
  void set majorVersion(int value) {
    assert(value == null || value >= 0);
    this._majorVersion = value;
  }

  @override
  int get minorVersion => _minorVersion ??= 0;

  /**
   * Minor version of the summary format.  See
   * [PackageBundleAssembler.currentMinorVersion].
   */
  void set minorVersion(int value) {
    assert(value == null || value >= 0);
    this._minorVersion = value;
  }

  @override
  List<String> get unlinkedUnitHashes => _unlinkedUnitHashes ??= <String>[];

  /**
   * List of MD5 hashes of the files listed in [unlinkedUnitUris].  Each hash
   * is encoded as a hexadecimal string using lower case letters.
   */
  void set unlinkedUnitHashes(List<String> value) {
    this._unlinkedUnitHashes = value;
  }

  @override
  List<UnlinkedUnitBuilder> get unlinkedUnits =>
      _unlinkedUnits ??= <UnlinkedUnitBuilder>[];

  /**
   * Unlinked information for the compilation units constituting the package.
   */
  void set unlinkedUnits(List<UnlinkedUnitBuilder> value) {
    this._unlinkedUnits = value;
  }

  @override
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ??= <String>[];

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  void set unlinkedUnitUris(List<String> value) {
    this._unlinkedUnitUris = value;
  }

  PackageBundleBuilder(
      {String apiSignature,
      List<PackageDependencyInfoBuilder> dependencies,
      List<LinkedLibraryBuilder> linkedLibraries,
      List<String> linkedLibraryUris,
      int majorVersion,
      int minorVersion,
      List<String> unlinkedUnitHashes,
      List<UnlinkedUnitBuilder> unlinkedUnits,
      List<String> unlinkedUnitUris})
      : _apiSignature = apiSignature,
        _dependencies = dependencies,
        _linkedLibraries = linkedLibraries,
        _linkedLibraryUris = linkedLibraryUris,
        _majorVersion = majorVersion,
        _minorVersion = minorVersion,
        _unlinkedUnitHashes = unlinkedUnitHashes,
        _unlinkedUnits = unlinkedUnits,
        _unlinkedUnitUris = unlinkedUnitUris;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _dependencies = null;
    _linkedLibraries?.forEach((b) => b.flushInformative());
    _unlinkedUnitHashes = null;
    _unlinkedUnits?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
    signature.addString(this._apiSignature ?? '');
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "PBdl");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_dependencies;
    fb.Offset offset_linkedLibraries;
    fb.Offset offset_linkedLibraryUris;
    fb.Offset offset_unlinkedUnitHashes;
    fb.Offset offset_unlinkedUnits;
    fb.Offset offset_unlinkedUnitUris;
    if (_apiSignature != null) {
      offset_apiSignature = fbBuilder.writeString(_apiSignature);
    }
    if (!(_dependencies == null || _dependencies.isEmpty)) {
      offset_dependencies = fbBuilder
          .writeList(_dependencies.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_linkedLibraries == null || _linkedLibraries.isEmpty)) {
      offset_linkedLibraries = fbBuilder
          .writeList(_linkedLibraries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_linkedLibraryUris == null || _linkedLibraryUris.isEmpty)) {
      offset_linkedLibraryUris = fbBuilder.writeList(
          _linkedLibraryUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_unlinkedUnitHashes == null || _unlinkedUnitHashes.isEmpty)) {
      offset_unlinkedUnitHashes = fbBuilder.writeList(
          _unlinkedUnitHashes.map((b) => fbBuilder.writeString(b)).toList());
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
    if (offset_apiSignature != null) {
      fbBuilder.addOffset(7, offset_apiSignature);
    }
    if (offset_dependencies != null) {
      fbBuilder.addOffset(8, offset_dependencies);
    }
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
    if (offset_unlinkedUnitHashes != null) {
      fbBuilder.addOffset(4, offset_unlinkedUnitHashes);
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

  String _apiSignature;
  List<idl.PackageDependencyInfo> _dependencies;
  List<idl.LinkedLibrary> _linkedLibraries;
  List<String> _linkedLibraryUris;
  int _majorVersion;
  int _minorVersion;
  List<String> _unlinkedUnitHashes;
  List<idl.UnlinkedUnit> _unlinkedUnits;
  List<String> _unlinkedUnitUris;

  @override
  String get apiSignature {
    _apiSignature ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 7, '');
    return _apiSignature;
  }

  @override
  List<idl.PackageDependencyInfo> get dependencies {
    _dependencies ??= const fb.ListReader<idl.PackageDependencyInfo>(
            const _PackageDependencyInfoReader())
        .vTableGet(_bc, _bcOffset, 8, const <idl.PackageDependencyInfo>[]);
    return _dependencies;
  }

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
  List<String> get unlinkedUnitHashes {
    _unlinkedUnitHashes ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 4, const <String>[]);
    return _unlinkedUnitHashes;
  }

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
    if (apiSignature != '') _result["apiSignature"] = apiSignature;
    if (dependencies.isNotEmpty)
      _result["dependencies"] =
          dependencies.map((_value) => _value.toJson()).toList();
    if (linkedLibraries.isNotEmpty)
      _result["linkedLibraries"] =
          linkedLibraries.map((_value) => _value.toJson()).toList();
    if (linkedLibraryUris.isNotEmpty)
      _result["linkedLibraryUris"] = linkedLibraryUris;
    if (majorVersion != 0) _result["majorVersion"] = majorVersion;
    if (minorVersion != 0) _result["minorVersion"] = minorVersion;
    if (unlinkedUnitHashes.isNotEmpty)
      _result["unlinkedUnitHashes"] = unlinkedUnitHashes;
    if (unlinkedUnits.isNotEmpty)
      _result["unlinkedUnits"] =
          unlinkedUnits.map((_value) => _value.toJson()).toList();
    if (unlinkedUnitUris.isNotEmpty)
      _result["unlinkedUnitUris"] = unlinkedUnitUris;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "apiSignature": apiSignature,
        "dependencies": dependencies,
        "linkedLibraries": linkedLibraries,
        "linkedLibraryUris": linkedLibraryUris,
        "majorVersion": majorVersion,
        "minorVersion": minorVersion,
        "unlinkedUnitHashes": unlinkedUnitHashes,
        "unlinkedUnits": unlinkedUnits,
        "unlinkedUnitUris": unlinkedUnitUris,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
}

class PackageDependencyInfoBuilder extends Object
    with _PackageDependencyInfoMixin
    implements idl.PackageDependencyInfo {
  String _apiSignature;
  List<String> _includedPackageNames;
  bool _includesDartUris;
  bool _includesFileUris;
  String _summaryPath;

  @override
  String get apiSignature => _apiSignature ??= '';

  /**
   * API signature of this dependency.
   */
  void set apiSignature(String value) {
    this._apiSignature = value;
  }

  @override
  List<String> get includedPackageNames => _includedPackageNames ??= <String>[];

  /**
   * If this dependency summarizes any files whose URI takes the form
   * "package:<package_name>/...", a list of all such package names, sorted
   * lexicographically.  Otherwise empty.
   */
  void set includedPackageNames(List<String> value) {
    this._includedPackageNames = value;
  }

  @override
  bool get includesDartUris => _includesDartUris ??= false;

  /**
   * Indicates whether this dependency summarizes any files whose URI takes the
   * form "dart:...".
   */
  void set includesDartUris(bool value) {
    this._includesDartUris = value;
  }

  @override
  bool get includesFileUris => _includesFileUris ??= false;

  /**
   * Indicates whether this dependency summarizes any files whose URI takes the
   * form "file:...".
   */
  void set includesFileUris(bool value) {
    this._includesFileUris = value;
  }

  @override
  String get summaryPath => _summaryPath ??= '';

  /**
   * Relative path to the summary file for this dependency.  This is intended as
   * a hint to help the analysis server locate summaries of dependencies.  We
   * don't specify precisely what this path is relative to, but we expect it to
   * be relative to a directory the analysis server can find (e.g. for projects
   * built using Bazel, it would be relative to the "bazel-bin" directory).
   *
   * Absent if the path is not known.
   */
  void set summaryPath(String value) {
    this._summaryPath = value;
  }

  PackageDependencyInfoBuilder(
      {String apiSignature,
      List<String> includedPackageNames,
      bool includesDartUris,
      bool includesFileUris,
      String summaryPath})
      : _apiSignature = apiSignature,
        _includedPackageNames = includedPackageNames,
        _includesDartUris = includesDartUris,
        _includesFileUris = includesFileUris,
        _summaryPath = summaryPath;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._apiSignature ?? '');
    signature.addString(this._summaryPath ?? '');
    if (this._includedPackageNames == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._includedPackageNames.length);
      for (var x in this._includedPackageNames) {
        signature.addString(x);
      }
    }
    signature.addBool(this._includesFileUris == true);
    signature.addBool(this._includesDartUris == true);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_includedPackageNames;
    fb.Offset offset_summaryPath;
    if (_apiSignature != null) {
      offset_apiSignature = fbBuilder.writeString(_apiSignature);
    }
    if (!(_includedPackageNames == null || _includedPackageNames.isEmpty)) {
      offset_includedPackageNames = fbBuilder.writeList(
          _includedPackageNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (_summaryPath != null) {
      offset_summaryPath = fbBuilder.writeString(_summaryPath);
    }
    fbBuilder.startTable();
    if (offset_apiSignature != null) {
      fbBuilder.addOffset(0, offset_apiSignature);
    }
    if (offset_includedPackageNames != null) {
      fbBuilder.addOffset(2, offset_includedPackageNames);
    }
    if (_includesDartUris == true) {
      fbBuilder.addBool(4, true);
    }
    if (_includesFileUris == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_summaryPath != null) {
      fbBuilder.addOffset(1, offset_summaryPath);
    }
    return fbBuilder.endTable();
  }
}

class _PackageDependencyInfoReader
    extends fb.TableReader<_PackageDependencyInfoImpl> {
  const _PackageDependencyInfoReader();

  @override
  _PackageDependencyInfoImpl createObject(fb.BufferContext bc, int offset) =>
      new _PackageDependencyInfoImpl(bc, offset);
}

class _PackageDependencyInfoImpl extends Object
    with _PackageDependencyInfoMixin
    implements idl.PackageDependencyInfo {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageDependencyInfoImpl(this._bc, this._bcOffset);

  String _apiSignature;
  List<String> _includedPackageNames;
  bool _includesDartUris;
  bool _includesFileUris;
  String _summaryPath;

  @override
  String get apiSignature {
    _apiSignature ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _apiSignature;
  }

  @override
  List<String> get includedPackageNames {
    _includedPackageNames ??=
        const fb.ListReader<String>(const fb.StringReader())
            .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _includedPackageNames;
  }

  @override
  bool get includesDartUris {
    _includesDartUris ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 4, false);
    return _includesDartUris;
  }

  @override
  bool get includesFileUris {
    _includesFileUris ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _includesFileUris;
  }

  @override
  String get summaryPath {
    _summaryPath ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _summaryPath;
  }
}

abstract class _PackageDependencyInfoMixin
    implements idl.PackageDependencyInfo {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (apiSignature != '') _result["apiSignature"] = apiSignature;
    if (includedPackageNames.isNotEmpty)
      _result["includedPackageNames"] = includedPackageNames;
    if (includesDartUris != false)
      _result["includesDartUris"] = includesDartUris;
    if (includesFileUris != false)
      _result["includesFileUris"] = includesFileUris;
    if (summaryPath != '') _result["summaryPath"] = summaryPath;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "apiSignature": apiSignature,
        "includedPackageNames": includedPackageNames,
        "includesDartUris": includesDartUris,
        "includesFileUris": includesFileUris,
        "summaryPath": summaryPath,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the kind of the synthetic element.
   */
  void set elementKinds(List<idl.IndexSyntheticElementKind> value) {
    this._elementKinds = value;
  }

  @override
  List<int> get elementNameClassMemberIds =>
      _elementNameClassMemberIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the class member element name, or `null` if the element
   * is a top-level element.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this
   * [PackageIndex].
   */
  void set elementNameClassMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the named parameter name, or `null` if the element is not
   * a named parameter.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this
   * [PackageIndex].
   */
  void set elementNameParameterIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameParameterIds = value;
  }

  @override
  List<int> get elementNameUnitMemberIds =>
      _elementNameUnitMemberIds ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the top-level element name, or `null` if the element is
   * the unit.  The list is sorted in ascending order, so that the client can
   * quickly check whether an element is referenced in this [PackageIndex].
   */
  void set elementNameUnitMemberIds(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the index into [unitLibraryUris] and [unitUnitUris] for the library
   * specific unit where the element is declared.
   */
  void set elementUnits(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /**
   * List of unique element strings used in this [PackageIndex].  The list is
   * sorted in ascending order, so that the client can quickly check the
   * presence of a string in this [PackageIndex].
   */
  void set strings(List<String> value) {
    this._strings = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /**
   * Each item of this list corresponds to the library URI of a unique library
   * specific unit referenced in the [PackageIndex].  It is an index into
   * [strings] list.
   */
  void set unitLibraryUris(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<UnitIndexBuilder> get units => _units ??= <UnitIndexBuilder>[];

  /**
   * List of indexes of each unit in this [PackageIndex].
   */
  void set units(List<UnitIndexBuilder> value) {
    this._units = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /**
   * Each item of this list corresponds to the unit URI of a unique library
   * specific unit referenced in the [PackageIndex].  It is an index into
   * [strings] list.
   */
  void set unitUnitUris(List<int> value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _units?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class TopLevelInferenceErrorBuilder extends Object
    with _TopLevelInferenceErrorMixin
    implements idl.TopLevelInferenceError {
  List<String> _arguments;
  idl.TopLevelInferenceErrorKind _kind;
  int _slot;

  @override
  List<String> get arguments => _arguments ??= <String>[];

  /**
   * The [kind] specific arguments.
   */
  void set arguments(List<String> value) {
    this._arguments = value;
  }

  @override
  idl.TopLevelInferenceErrorKind get kind =>
      _kind ??= idl.TopLevelInferenceErrorKind.assignment;

  /**
   * The kind of the error.
   */
  void set kind(idl.TopLevelInferenceErrorKind value) {
    this._kind = value;
  }

  @override
  int get slot => _slot ??= 0;

  /**
   * The slot id (which is unique within the compilation unit) identifying the
   * target of type inference with which this [TopLevelInferenceError] is
   * associated.
   */
  void set slot(int value) {
    assert(value == null || value >= 0);
    this._slot = value;
  }

  TopLevelInferenceErrorBuilder(
      {List<String> arguments, idl.TopLevelInferenceErrorKind kind, int slot})
      : _arguments = arguments,
        _kind = kind,
        _slot = slot;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Each item of this list is the kind of an element defined in this unit.
   */
  void set definedNameKinds(List<idl.IndexNameKind> value) {
    this._definedNameKinds = value;
  }

  @override
  List<int> get definedNameOffsets => _definedNameOffsets ??= <int>[];

  /**
   * Each item of this list is the name offset of an element defined in this
   * unit relative to the beginning of the file.
   */
  void set definedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._definedNameOffsets = value;
  }

  @override
  List<int> get definedNames => _definedNames ??= <int>[];

  /**
   * Each item of this list corresponds to an element defined in this unit.  It
   * is an index into [PackageIndex.strings] list.  The list is sorted in
   * ascending order, so that the client can quickly find name definitions in
   * this [UnitIndex].
   */
  void set definedNames(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._definedNames = value;
  }

  @override
  int get unit => _unit ??= 0;

  /**
   * Index into [PackageIndex.unitLibraryUris] and [PackageIndex.unitUnitUris]
   * for the library specific unit that corresponds to this [UnitIndex].
   */
  void set unit(int value) {
    assert(value == null || value >= 0);
    this._unit = value;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags =>
      _usedElementIsQualifiedFlags ??= <bool>[];

  /**
   * Each item of this list is the `true` if the corresponding element usage
   * is qualified with some prefix.
   */
  void set usedElementIsQualifiedFlags(List<bool> value) {
    this._usedElementIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds =>
      _usedElementKinds ??= <idl.IndexRelationKind>[];

  /**
   * Each item of this list is the kind of the element usage.
   */
  void set usedElementKinds(List<idl.IndexRelationKind> value) {
    this._usedElementKinds = value;
  }

  @override
  List<int> get usedElementLengths => _usedElementLengths ??= <int>[];

  /**
   * Each item of this list is the length of the element usage.
   */
  void set usedElementLengths(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /**
   * Each item of this list is the offset of the element usage relative to the
   * beginning of the file.
   */
  void set usedElementOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /**
   * Each item of this list is the index into [PackageIndex.elementUnits] and
   * [PackageIndex.elementOffsets].  The list is sorted in ascending order, so
   * that the client can quickly find element references in this [UnitIndex].
   */
  void set usedElements(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedElements = value;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags =>
      _usedNameIsQualifiedFlags ??= <bool>[];

  /**
   * Each item of this list is the `true` if the corresponding name usage
   * is qualified with some prefix.
   */
  void set usedNameIsQualifiedFlags(List<bool> value) {
    this._usedNameIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds =>
      _usedNameKinds ??= <idl.IndexRelationKind>[];

  /**
   * Each item of this list is the kind of the name usage.
   */
  void set usedNameKinds(List<idl.IndexRelationKind> value) {
    this._usedNameKinds = value;
  }

  @override
  List<int> get usedNameOffsets => _usedNameOffsets ??= <int>[];

  /**
   * Each item of this list is the offset of the name usage relative to the
   * beginning of the file.
   */
  void set usedNameOffsets(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /**
   * Each item of this list is the index into [PackageIndex.strings] for a
   * used name.  The list is sorted in ascending order, so that the client can
   * quickly find name uses in this [UnitIndex].
   */
  void set usedNames(List<int> value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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
  EntityRefBuilder _supertype;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /**
   * Annotations for this class.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the class.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables =>
      _executables ??= <UnlinkedExecutableBuilder>[];

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  void set executables(List<UnlinkedExecutableBuilder> value) {
    this._executables = value;
  }

  @override
  List<UnlinkedVariableBuilder> get fields =>
      _fields ??= <UnlinkedVariableBuilder>[];

  /**
   * Field declarations contained in the class.
   */
  void set fields(List<UnlinkedVariableBuilder> value) {
    this._fields = value;
  }

  @override
  bool get hasNoSupertype => _hasNoSupertype ??= false;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  void set hasNoSupertype(bool value) {
    this._hasNoSupertype = value;
  }

  @override
  List<EntityRefBuilder> get interfaces => _interfaces ??= <EntityRefBuilder>[];

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  void set interfaces(List<EntityRefBuilder> value) {
    this._interfaces = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  void set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isMixinApplication => _isMixinApplication ??= false;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  void set isMixinApplication(bool value) {
    this._isMixinApplication = value;
  }

  @override
  List<EntityRefBuilder> get mixins => _mixins ??= <EntityRefBuilder>[];

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  void set mixins(List<EntityRefBuilder> value) {
    this._mixins = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the class.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  EntityRefBuilder get supertype => _supertype;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  void set supertype(EntityRefBuilder value) {
    this._supertype = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the class, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> value) {
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
        _supertype = supertype,
        _typeParameters = typeParameters;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _executables?.forEach((b) => b.flushInformative());
    _fields?.forEach((b) => b.flushInformative());
    _interfaces?.forEach((b) => b.flushInformative());
    _mixins?.forEach((b) => b.flushInformative());
    _nameOffset = null;
    _supertype?.flushInformative();
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
        "supertype": supertype,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * If this is a `show` combinator, offset of the end of the list of shown
   * names.  Otherwise zero.
   */
  void set end(int value) {
    assert(value == null || value >= 0);
    this._end = value;
  }

  @override
  List<String> get hides => _hides ??= <String>[];

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  void set hides(List<String> value) {
    this._hides = value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * If this is a `show` combinator, offset of the `show` keyword.  Otherwise
   * zero.
   */
  void set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  List<String> get shows => _shows ??= <String>[];

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  void set shows(List<String> value) {
    this._shows = value;
  }

  UnlinkedCombinatorBuilder(
      {int end, List<String> hides, int offset, List<String> shows})
      : _end = end,
        _hides = hides,
        _offset = offset,
        _shows = shows;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _end = null;
    _offset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class UnlinkedConfigurationBuilder extends Object
    with _UnlinkedConfigurationMixin
    implements idl.UnlinkedConfiguration {
  String _name;
  String _uri;
  String _value;

  @override
  String get name => _name ??= '';

  /**
   * The name of the declared variable whose value is being used in the
   * condition.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  String get uri => _uri ??= '';

  /**
   * The URI of the implementation library to be used if the condition is true.
   */
  void set uri(String value) {
    this._uri = value;
  }

  @override
  String get value => _value ??= '';

  /**
   * The value to which the value of the declared variable will be compared,
   * or `true` if the condition does not include an equality test.
   */
  void set value(String value) {
    this._value = value;
  }

  UnlinkedConfigurationBuilder({String name, String uri, String value})
      : _name = name,
        _uri = uri,
        _value = value;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * If there are `m` [arguments] and `n` [argumentNames], then each argument
   * from [arguments] with index `i` such that `n + i - m >= 0`, should be used
   * with the name at `n + i - m`.
   */
  void set argumentNames(List<String> value) {
    this._argumentNames = value;
  }

  @override
  List<UnlinkedExprBuilder> get arguments =>
      _arguments ??= <UnlinkedExprBuilder>[];

  /**
   * If [kind] is `thisInvocation` or `superInvocation`, the arguments of the
   * invocation.  Otherwise empty.
   */
  void set arguments(List<UnlinkedExprBuilder> value) {
    this._arguments = value;
  }

  @override
  UnlinkedExprBuilder get expression => _expression;

  /**
   * If [kind] is `field`, the expression of the field initializer.
   * Otherwise `null`.
   */
  void set expression(UnlinkedExprBuilder value) {
    this._expression = value;
  }

  @override
  idl.UnlinkedConstructorInitializerKind get kind =>
      _kind ??= idl.UnlinkedConstructorInitializerKind.field;

  /**
   * The kind of the constructor initializer (field, redirect, super).
   */
  void set kind(idl.UnlinkedConstructorInitializerKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * If [kind] is `field`, the name of the field declared in the class.  If
   * [kind] is `thisInvocation`, the name of the constructor, declared in this
   * class, to redirect to.  If [kind] is `superInvocation`, the name of the
   * constructor, declared in the superclass, to invoke.
   */
  void set name(String value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _arguments?.forEach((b) => b.flushInformative());
    _expression?.flushInformative();
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class UnlinkedDocumentationCommentBuilder extends Object
    with _UnlinkedDocumentationCommentMixin
    implements idl.UnlinkedDocumentationComment {
  String _text;

  @override
  int get length =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  int get offset =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get text => _text ??= '';

  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  void set text(String value) {
    this._text = value;
  }

  UnlinkedDocumentationCommentBuilder({String text}) : _text = text;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  int get length =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  int get offset =>
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this enum.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the enum.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the enum type.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedEnumValueBuilder> get values =>
      _values ??= <UnlinkedEnumValueBuilder>[];

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  void set values(List<UnlinkedEnumValueBuilder> value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _nameOffset = null;
    _values?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class UnlinkedEnumValueBuilder extends Object
    with _UnlinkedEnumValueMixin
    implements idl.UnlinkedEnumValue {
  UnlinkedDocumentationCommentBuilder _documentationComment;
  String _name;
  int _nameOffset;

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the enumerated value.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  UnlinkedEnumValueBuilder(
      {UnlinkedDocumentationCommentBuilder documentationComment,
      String name,
      int nameOffset})
      : _documentationComment = documentationComment,
        _name = name,
        _nameOffset = nameOffset;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _documentationComment = null;
    _nameOffset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_documentationComment;
    fb.Offset offset_name;
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
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

  idl.UnlinkedDocumentationComment _documentationComment;
  String _name;
  int _nameOffset;

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
    if (documentationComment != null)
      _result["documentationComment"] = documentationComment.toJson();
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "documentationComment": documentationComment,
        "name": name,
        "nameOffset": nameOffset,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this executable.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  UnlinkedExprBuilder get bodyExpr => _bodyExpr;

  /**
   * If this executable's function body is declared using `=>`, the expression
   * to the right of the `=>`.  May be omitted if neither type inference nor
   * constant evaluation depends on the function body.
   */
  void set bodyExpr(UnlinkedExprBuilder value) {
    this._bodyExpr = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the executable.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  List<UnlinkedConstructorInitializerBuilder> get constantInitializers =>
      _constantInitializers ??= <UnlinkedConstructorInitializerBuilder>[];

  /**
   * If a constant [UnlinkedExecutableKind.constructor], the constructor
   * initializers.  Otherwise empty.
   */
  void set constantInitializers(
      List<UnlinkedConstructorInitializerBuilder> value) {
    this._constantInitializers = value;
  }

  @override
  int get constCycleSlot => _constCycleSlot ??= 0;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [isConst] is `true`,
   * a nonzero slot id which is unique within this compilation unit.  If this id
   * is found in [LinkedUnit.constCycles], then this constructor is part of a
   * cycle.
   *
   * Otherwise, zero.
   */
  void set constCycleSlot(int value) {
    assert(value == null || value >= 0);
    this._constCycleSlot = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  int get inferredReturnTypeSlot => _inferredReturnTypeSlot ??= 0;

  /**
   * If this executable's return type is inferable, nonzero slot id
   * identifying which entry in [LinkedUnit.types] contains the inferred
   * return type.  If there is no matching entry in [LinkedUnit.types], then
   * no return type was inferred for this variable, so its static type is
   * `dynamic`.
   */
  void set inferredReturnTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredReturnTypeSlot = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  void set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isAsynchronous => _isAsynchronous ??= false;

  /**
   * Indicates whether the executable has body marked as being asynchronous.
   */
  void set isAsynchronous(bool value) {
    this._isAsynchronous = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  void set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isExternal => _isExternal ??= false;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  void set isExternal(bool value) {
    this._isExternal = value;
  }

  @override
  bool get isFactory => _isFactory ??= false;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  void set isFactory(bool value) {
    this._isFactory = value;
  }

  @override
  bool get isGenerator => _isGenerator ??= false;

  /**
   * Indicates whether the executable has body marked as being a generator.
   */
  void set isGenerator(bool value) {
    this._isGenerator = value;
  }

  @override
  bool get isRedirectedConstructor => _isRedirectedConstructor ??= false;

  /**
   * Indicates whether the executable is a redirected constructor.
   */
  void set isRedirectedConstructor(bool value) {
    this._isRedirectedConstructor = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool value) {
    this._isStatic = value;
  }

  @override
  idl.UnlinkedExecutableKind get kind =>
      _kind ??= idl.UnlinkedExecutableKind.functionOrMethod;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  void set kind(idl.UnlinkedExecutableKind value) {
    this._kind = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get localFunctions =>
      _localFunctions ??= <UnlinkedExecutableBuilder>[];

  /**
   * The list of local functions.
   */
  void set localFunctions(List<UnlinkedExecutableBuilder> value) {
    this._localFunctions = value;
  }

  @override
  List<String> get localLabels =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<UnlinkedVariableBuilder> get localVariables =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  String get name => _name ??= '';

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameEnd => _nameEnd ??= 0;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
   * the offset of the end of the constructor name.  Otherwise zero.
   */
  void set nameEnd(int value) {
    assert(value == null || value >= 0);
    this._nameEnd = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  void set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  int get periodOffset => _periodOffset ??= 0;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
   * the offset of the period before the constructor name.  Otherwise zero.
   */
  void set periodOffset(int value) {
    assert(value == null || value >= 0);
    this._periodOffset = value;
  }

  @override
  EntityRefBuilder get redirectedConstructor => _redirectedConstructor;

  /**
   * If [isRedirectedConstructor] and [isFactory] are both `true`, the
   * constructor to which this constructor redirects; otherwise empty.
   */
  void set redirectedConstructor(EntityRefBuilder value) {
    this._redirectedConstructor = value;
  }

  @override
  String get redirectedConstructorName => _redirectedConstructorName ??= '';

  /**
   * If [isRedirectedConstructor] is `true` and [isFactory] is `false`, the
   * name of the constructor that this constructor redirects to; otherwise
   * empty.
   */
  void set redirectedConstructorName(String value) {
    this._redirectedConstructorName = value;
  }

  @override
  EntityRefBuilder get returnType => _returnType;

  /**
   * Declared return type of the executable.  Absent if the executable is a
   * constructor or the return type is implicit.  Absent for executables
   * associated with variable initializers and closures, since these
   * executables may have return types that are not accessible via direct
   * imports.
   */
  void set returnType(EntityRefBuilder value) {
    this._returnType = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  @override
  int get visibleLength => _visibleLength ??= 0;

  /**
   * If a local function, the length of the visible range; zero otherwise.
   */
  void set visibleLength(int value) {
    assert(value == null || value >= 0);
    this._visibleLength = value;
  }

  @override
  int get visibleOffset => _visibleOffset ??= 0;

  /**
   * If a local function, the beginning of the visible range; zero otherwise.
   */
  void set visibleOffset(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
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

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  List<String> get localLabels =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<idl.UnlinkedVariable> get localVariables =>
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this export directive.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * Offset of the "export" keyword.
   */
  void set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _offset = null;
    _uriEnd = null;
    _uriOffset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Combinators contained in this export declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  List<UnlinkedConfigurationBuilder> get configurations =>
      _configurations ??= <UnlinkedConfigurationBuilder>[];

  /**
   * Configurations used to control which library will actually be loaded at
   * run-time.
   */
  void set configurations(List<UnlinkedConfigurationBuilder> value) {
    this._configurations = value;
  }

  @override
  String get uri => _uri ??= '';

  /**
   * URI used in the source code to reference the exported library.
   */
  void set uri(String value) {
    this._uri = value;
  }

  UnlinkedExportPublicBuilder(
      {List<UnlinkedCombinatorBuilder> combinators,
      List<UnlinkedConfigurationBuilder> configurations,
      String uri})
      : _combinators = combinators,
        _configurations = configurations,
        _uri = uri;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _combinators?.forEach((b) => b.flushInformative());
    _configurations?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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
  List<String> _strings;

  @override
  List<idl.UnlinkedExprAssignOperator> get assignmentOperators =>
      _assignmentOperators ??= <idl.UnlinkedExprAssignOperator>[];

  /**
   * Sequence of operators used by assignment operations.
   */
  void set assignmentOperators(List<idl.UnlinkedExprAssignOperator> value) {
    this._assignmentOperators = value;
  }

  @override
  List<double> get doubles => _doubles ??= <double>[];

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  void set doubles(List<double> value) {
    this._doubles = value;
  }

  @override
  List<int> get ints => _ints ??= <int>[];

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  void set ints(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._ints = value;
  }

  @override
  bool get isValidConst => _isValidConst ??= false;

  /**
   * Indicates whether the expression is a valid potentially constant
   * expression.
   */
  void set isValidConst(bool value) {
    this._isValidConst = value;
  }

  @override
  List<idl.UnlinkedExprOperation> get operations =>
      _operations ??= <idl.UnlinkedExprOperation>[];

  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  void set operations(List<idl.UnlinkedExprOperation> value) {
    this._operations = value;
  }

  @override
  List<EntityRefBuilder> get references => _references ??= <EntityRefBuilder>[];

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  void set references(List<EntityRefBuilder> value) {
    this._references = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  void set strings(List<String> value) {
    this._strings = value;
  }

  UnlinkedExprBuilder(
      {List<idl.UnlinkedExprAssignOperator> assignmentOperators,
      List<double> doubles,
      List<int> ints,
      bool isValidConst,
      List<idl.UnlinkedExprOperation> operations,
      List<EntityRefBuilder> references,
      List<String> strings})
      : _assignmentOperators = assignmentOperators,
        _doubles = doubles,
        _ints = ints,
        _isValidConst = isValidConst,
        _operations = operations,
        _references = references,
        _strings = strings;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _references?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_assignmentOperators;
    fb.Offset offset_doubles;
    fb.Offset offset_ints;
    fb.Offset offset_operations;
    fb.Offset offset_references;
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
        "strings": strings,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this import declaration.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  List<UnlinkedCombinatorBuilder> get combinators =>
      _combinators ??= <UnlinkedCombinatorBuilder>[];

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  List<UnlinkedConfigurationBuilder> get configurations =>
      _configurations ??= <UnlinkedConfigurationBuilder>[];

  /**
   * Configurations used to control which library will actually be loaded at
   * run-time.
   */
  void set configurations(List<UnlinkedConfigurationBuilder> value) {
    this._configurations = value;
  }

  @override
  bool get isDeferred => _isDeferred ??= false;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  void set isDeferred(bool value) {
    this._isDeferred = value;
  }

  @override
  bool get isImplicit => _isImplicit ??= false;

  /**
   * Indicates whether the import declaration is implicit.
   */
  void set isImplicit(bool value) {
    this._isImplicit = value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  void set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  int get prefixOffset => _prefixOffset ??= 0;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  void set prefixOffset(int value) {
    assert(value == null || value >= 0);
    this._prefixOffset = value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  void set prefixReference(int value) {
    assert(value == null || value >= 0);
    this._prefixReference = value;
  }

  @override
  String get uri => _uri ??= '';

  /**
   * URI used in the source code to reference the imported library.
   */
  void set uri(String value) {
    this._uri = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  void set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  void set uriOffset(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _combinators?.forEach((b) => b.flushInformative());
    _configurations?.forEach((b) => b.flushInformative());
    _offset = null;
    _prefixOffset = null;
    _uriEnd = null;
    _uriOffset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this parameter.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the parameter.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  String get defaultValueCode => _defaultValueCode ??= '';

  /**
   * If the parameter has a default value, the source text of the constant
   * expression in the default value.  Otherwise the empty string.
   */
  void set defaultValueCode(String value) {
    this._defaultValueCode = value;
  }

  @override
  int get inferredTypeSlot => _inferredTypeSlot ??= 0;

  /**
   * If this parameter's type is inferable, nonzero slot id identifying which
   * entry in [LinkedLibrary.types] contains the inferred type.  If there is no
   * matching entry in [LinkedLibrary.types], then no type was inferred for
   * this variable, so its static type is `dynamic`.
   *
   * Note that although strong mode considers initializing formals to be
   * inferable, they are not marked as such in the summary; if their type is
   * not specified, they always inherit the static type of the corresponding
   * field.
   */
  void set inferredTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredTypeSlot = value;
  }

  @override
  int get inheritsCovariantSlot => _inheritsCovariantSlot ??= 0;

  /**
   * If this is a parameter of an instance method, a nonzero slot id which is
   * unique within this compilation unit.  If this id is found in
   * [LinkedUnit.parametersInheritingCovariant], then this parameter inherits
   * `@covariant` behavior from a base class.
   *
   * Otherwise, zero.
   */
  void set inheritsCovariantSlot(int value) {
    assert(value == null || value >= 0);
    this._inheritsCovariantSlot = value;
  }

  @override
  UnlinkedExecutableBuilder get initializer => _initializer;

  /**
   * The synthetic initializer function of the parameter.  Absent if the
   * variable does not have an initializer.
   */
  void set initializer(UnlinkedExecutableBuilder value) {
    this._initializer = value;
  }

  @override
  bool get isExplicitlyCovariant => _isExplicitlyCovariant ??= false;

  /**
   * Indicates whether this parameter is explicitly marked as being covariant.
   */
  void set isExplicitlyCovariant(bool value) {
    this._isExplicitlyCovariant = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  /**
   * Indicates whether the parameter is declared using the `final` keyword.
   */
  void set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isFunctionTyped => _isFunctionTyped ??= false;

  /**
   * Indicates whether this is a function-typed parameter. A parameter is
   * function-typed if the declaration of the parameter has explicit formal
   * parameters
   * ```
   * int functionTyped(int p)
   * ```
   * but is not function-typed if it does not, even if the type of the parameter
   * is a function type.
   */
  void set isFunctionTyped(bool value) {
    this._isFunctionTyped = value;
  }

  @override
  bool get isInitializingFormal => _isInitializingFormal ??= false;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  void set isInitializingFormal(bool value) {
    this._isInitializingFormal = value;
  }

  @override
  idl.UnlinkedParamKind get kind => _kind ??= idl.UnlinkedParamKind.required;

  /**
   * Kind of the parameter.
   */
  void set kind(idl.UnlinkedParamKind value) {
    this._kind = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the parameter.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  void set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  EntityRefBuilder get type => _type;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if the type is
   * implicit.
   */
  void set type(EntityRefBuilder value) {
    this._type = value;
  }

  @override
  int get visibleLength => _visibleLength ??= 0;

  /**
   * The length of the visible range.
   */
  void set visibleLength(int value) {
    assert(value == null || value >= 0);
    this._visibleLength = value;
  }

  @override
  int get visibleOffset => _visibleOffset ??= 0;

  /**
   * The beginning of the visible range.
   */
  void set visibleOffset(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
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

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
    if (_kind != null && _kind != idl.UnlinkedParamKind.required) {
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
        .vTableGet(_bc, _bcOffset, 4, idl.UnlinkedParamKind.required);
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
    if (kind != idl.UnlinkedParamKind.required)
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this part declaration.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int value) {
    assert(value == null || value >= 0);
    this._uriEnd = value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int value) {
    assert(value == null || value >= 0);
    this._uriOffset = value;
  }

  UnlinkedPartBuilder(
      {List<UnlinkedExprBuilder> annotations, int uriEnd, int uriOffset})
      : _annotations = annotations,
        _uriEnd = uriEnd,
        _uriOffset = uriOffset;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _uriEnd = null;
    _uriOffset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * The kind of object referred to by the name.
   */
  void set kind(idl.ReferenceKind value) {
    this._kind = value;
  }

  @override
  List<UnlinkedPublicNameBuilder> get members =>
      _members ??= <UnlinkedPublicNameBuilder>[];

  /**
   * If this [UnlinkedPublicName] is a class, the list of members which can be
   * referenced statically - static fields, static methods, and constructors.
   * Otherwise empty.
   *
   * Unnamed constructors are not included since they do not constitute a
   * separate name added to any namespace.
   */
  void set members(List<UnlinkedPublicNameBuilder> value) {
    this._members = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * The name itself.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _members?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportPublicBuilder> value) {
    this._exports = value;
  }

  @override
  List<UnlinkedPublicNameBuilder> get names =>
      _names ??= <UnlinkedPublicNameBuilder>[];

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  void set names(List<UnlinkedPublicNameBuilder> value) {
    this._names = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  void set parts(List<String> value) {
    this._parts = value;
  }

  UnlinkedPublicNamespaceBuilder(
      {List<UnlinkedExportPublicBuilder> exports,
      List<UnlinkedPublicNameBuilder> names,
      List<String> parts})
      : _exports = exports,
        _names = names,
        _parts = parts;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _exports?.forEach((b) => b.flushInformative());
    _names?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class UnlinkedReferenceBuilder extends Object
    with _UnlinkedReferenceMixin
    implements idl.UnlinkedReference {
  String _name;
  int _prefixReference;

  @override
  String get name => _name ??= '';

  /**
   * Name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   * For the pseudo-type `bottom`, the string is "*bottom*".
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  void set prefixReference(int value) {
    assert(value == null || value >= 0);
    this._prefixReference = value;
  }

  UnlinkedReferenceBuilder({String name, int prefixReference})
      : _name = name,
        _prefixReference = prefixReference;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {}

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
}

class UnlinkedTypedefBuilder extends Object
    with _UnlinkedTypedefMixin
    implements idl.UnlinkedTypedef {
  List<UnlinkedExprBuilder> _annotations;
  CodeRangeBuilder _codeRange;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  String _name;
  int _nameOffset;
  List<UnlinkedParamBuilder> _parameters;
  EntityRefBuilder _returnType;
  idl.TypedefStyle _style;
  List<UnlinkedTypeParamBuilder> _typeParameters;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /**
   * Annotations for this typedef.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the typedef.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the typedef.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters =>
      _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * Parameters of the executable, if any.
   */
  void set parameters(List<UnlinkedParamBuilder> value) {
    this._parameters = value;
  }

  @override
  EntityRefBuilder get returnType => _returnType;

  /**
   * If [style] is [TypedefStyle.functionType], the return type of the typedef.
   * If [style] is [TypedefStyle.genericFunctionType], the function type being
   * defined.
   */
  void set returnType(EntityRefBuilder value) {
    this._returnType = value;
  }

  @override
  idl.TypedefStyle get style => _style ??= idl.TypedefStyle.functionType;

  /**
   * The style of the typedef.
   */
  void set style(idl.TypedefStyle value) {
    this._style = value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters =>
      _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the typedef, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> value) {
    this._typeParameters = value;
  }

  UnlinkedTypedefBuilder(
      {List<UnlinkedExprBuilder> annotations,
      CodeRangeBuilder codeRange,
      UnlinkedDocumentationCommentBuilder documentationComment,
      String name,
      int nameOffset,
      List<UnlinkedParamBuilder> parameters,
      EntityRefBuilder returnType,
      idl.TypedefStyle style,
      List<UnlinkedTypeParamBuilder> typeParameters})
      : _annotations = annotations,
        _codeRange = codeRange,
        _documentationComment = documentationComment,
        _name = name,
        _nameOffset = nameOffset,
        _parameters = parameters,
        _returnType = returnType,
        _style = style,
        _typeParameters = typeParameters;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _nameOffset = null;
    _parameters?.forEach((b) => b.flushInformative());
    _returnType?.flushInformative();
    _typeParameters?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
        "parameters": parameters,
        "returnType": returnType,
        "style": style,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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

  /**
   * Annotations for this type parameter.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  EntityRefBuilder get bound => _bound;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  void set bound(EntityRefBuilder value) {
    this._bound = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the type parameter.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the type parameter.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
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

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _bound?.flushInformative();
    _codeRange = null;
    _nameOffset = null;
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String toString() => convert.JSON.encode(toJson());
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
  List<UnlinkedPartBuilder> _parts;
  UnlinkedPublicNamespaceBuilder _publicNamespace;
  List<UnlinkedReferenceBuilder> _references;
  List<UnlinkedTypedefBuilder> _typedefs;
  List<UnlinkedVariableBuilder> _variables;

  @override
  List<int> get apiSignature => _apiSignature ??= <int>[];

  /**
   * MD5 hash of the non-informative fields of the [UnlinkedUnit] (not
   * including this one) as 16 unsigned 8-bit integer values.  This can be used
   * to identify when the API of a unit may have changed.
   */
  void set apiSignature(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._apiSignature = value;
  }

  @override
  List<UnlinkedClassBuilder> get classes =>
      _classes ??= <UnlinkedClassBuilder>[];

  /**
   * Classes declared in the compilation unit.
   */
  void set classes(List<UnlinkedClassBuilder> value) {
    this._classes = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the unit.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  List<UnlinkedEnumBuilder> get enums => _enums ??= <UnlinkedEnumBuilder>[];

  /**
   * Enums declared in the compilation unit.
   */
  void set enums(List<UnlinkedEnumBuilder> value) {
    this._enums = value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables =>
      _executables ??= <UnlinkedExecutableBuilder>[];

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  void set executables(List<UnlinkedExecutableBuilder> value) {
    this._executables = value;
  }

  @override
  List<UnlinkedExportNonPublicBuilder> get exports =>
      _exports ??= <UnlinkedExportNonPublicBuilder>[];

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportNonPublicBuilder> value) {
    this._exports = value;
  }

  @override
  String get fallbackModePath =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  List<UnlinkedImportBuilder> get imports =>
      _imports ??= <UnlinkedImportBuilder>[];

  /**
   * Import declarations in the compilation unit.
   */
  void set imports(List<UnlinkedImportBuilder> value) {
    this._imports = value;
  }

  @override
  bool get isPartOf => _isPartOf ??= false;

  /**
   * Indicates whether the unit contains a "part of" declaration.
   */
  void set isPartOf(bool value) {
    this._isPartOf = value;
  }

  @override
  List<UnlinkedExprBuilder> get libraryAnnotations =>
      _libraryAnnotations ??= <UnlinkedExprBuilder>[];

  /**
   * Annotations for the library declaration, or the empty list if there is no
   * library declaration.
   */
  void set libraryAnnotations(List<UnlinkedExprBuilder> value) {
    this._libraryAnnotations = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get libraryDocumentationComment =>
      _libraryDocumentationComment;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  void set libraryDocumentationComment(
      UnlinkedDocumentationCommentBuilder value) {
    this._libraryDocumentationComment = value;
  }

  @override
  String get libraryName => _libraryName ??= '';

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  void set libraryName(String value) {
    this._libraryName = value;
  }

  @override
  int get libraryNameLength => _libraryNameLength ??= 0;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  void set libraryNameLength(int value) {
    assert(value == null || value >= 0);
    this._libraryNameLength = value;
  }

  @override
  int get libraryNameOffset => _libraryNameOffset ??= 0;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  void set libraryNameOffset(int value) {
    assert(value == null || value >= 0);
    this._libraryNameOffset = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /**
   * Offsets of the first character of each line in the source code.
   */
  void set lineStarts(List<int> value) {
    assert(value == null || value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  List<UnlinkedPartBuilder> get parts => _parts ??= <UnlinkedPartBuilder>[];

  /**
   * Part declarations in the compilation unit.
   */
  void set parts(List<UnlinkedPartBuilder> value) {
    this._parts = value;
  }

  @override
  UnlinkedPublicNamespaceBuilder get publicNamespace => _publicNamespace;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  void set publicNamespace(UnlinkedPublicNamespaceBuilder value) {
    this._publicNamespace = value;
  }

  @override
  List<UnlinkedReferenceBuilder> get references =>
      _references ??= <UnlinkedReferenceBuilder>[];

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and is used to represent
   * the absence of a reference in places where a reference is optional (for
   * example [UnlinkedReference.prefixReference or
   * UnlinkedImport.prefixReference]).
   */
  void set references(List<UnlinkedReferenceBuilder> value) {
    this._references = value;
  }

  @override
  List<UnlinkedTypedefBuilder> get typedefs =>
      _typedefs ??= <UnlinkedTypedefBuilder>[];

  /**
   * Typedefs declared in the compilation unit.
   */
  void set typedefs(List<UnlinkedTypedefBuilder> value) {
    this._typedefs = value;
  }

  @override
  List<UnlinkedVariableBuilder> get variables =>
      _variables ??= <UnlinkedVariableBuilder>[];

  /**
   * Top level variables declared in the compilation unit.
   */
  void set variables(List<UnlinkedVariableBuilder> value) {
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
        _parts = parts,
        _publicNamespace = publicNamespace,
        _references = references,
        _typedefs = typedefs,
        _variables = variables;

  /**
   * Flush [informative] data recursively.
   */
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
    _parts?.forEach((b) => b.flushInformative());
    _publicNamespace?.flushInformative();
    _references?.forEach((b) => b.flushInformative());
    _typedefs?.forEach((b) => b.flushInformative());
    _variables?.forEach((b) => b.flushInformative());
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  String get fallbackModePath =>
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
        "parts": parts,
        "publicNamespace": publicNamespace,
        "references": references,
        "typedefs": typedefs,
        "variables": variables,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
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
  bool _isStatic;
  String _name;
  int _nameOffset;
  int _propagatedTypeSlot;
  EntityRefBuilder _type;

  @override
  List<UnlinkedExprBuilder> get annotations =>
      _annotations ??= <UnlinkedExprBuilder>[];

  /**
   * Annotations for this variable.
   */
  void set annotations(List<UnlinkedExprBuilder> value) {
    this._annotations = value;
  }

  @override
  CodeRangeBuilder get codeRange => _codeRange;

  /**
   * Code range of the variable.
   */
  void set codeRange(CodeRangeBuilder value) {
    this._codeRange = value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment =>
      _documentationComment;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder value) {
    this._documentationComment = value;
  }

  @override
  int get inferredTypeSlot => _inferredTypeSlot ??= 0;

  /**
   * If this variable is inferable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the inferred type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then no type was
   * inferred for this variable, so its static type is `dynamic`.
   */
  void set inferredTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._inferredTypeSlot = value;
  }

  @override
  int get inheritsCovariantSlot => _inheritsCovariantSlot ??= 0;

  /**
   * If this is an instance non-final field, a nonzero slot id which is unique
   * within this compilation unit.  If this id is found in
   * [LinkedUnit.parametersInheritingCovariant], then the parameter of the
   * synthetic setter inherits `@covariant` behavior from a base class.
   *
   * Otherwise, zero.
   */
  void set inheritsCovariantSlot(int value) {
    assert(value == null || value >= 0);
    this._inheritsCovariantSlot = value;
  }

  @override
  UnlinkedExecutableBuilder get initializer => _initializer;

  /**
   * The synthetic initializer function of the variable.  Absent if the variable
   * does not have an initializer.
   */
  void set initializer(UnlinkedExecutableBuilder value) {
    this._initializer = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  void set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isCovariant => _isCovariant ??= false;

  /**
   * Indicates whether this variable is declared using the `covariant` keyword.
   * This should be false for everything except instance fields.
   */
  void set isCovariant(bool value) {
    this._isCovariant = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  void set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool value) {
    this._isStatic = value;
  }

  @override
  String get name => _name ??= '';

  /**
   * Name of the variable.
   */
  void set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  void set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  int get propagatedTypeSlot => _propagatedTypeSlot ??= 0;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  void set propagatedTypeSlot(int value) {
    assert(value == null || value >= 0);
    this._propagatedTypeSlot = value;
  }

  @override
  EntityRefBuilder get type => _type;

  /**
   * Declared type of the variable.  Absent if the type is implicit.
   */
  void set type(EntityRefBuilder value) {
    this._type = value;
  }

  @override
  int get visibleLength =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  int get visibleOffset =>
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
        _isStatic = isStatic,
        _name = name,
        _nameOffset = nameOffset,
        _propagatedTypeSlot = propagatedTypeSlot,
        _type = type;

  /**
   * Flush [informative] data recursively.
   */
  void flushInformative() {
    _annotations?.forEach((b) => b.flushInformative());
    _codeRange = null;
    _documentationComment = null;
    _initializer?.flushInformative();
    _nameOffset = null;
    _type?.flushInformative();
  }

  /**
   * Accumulate non-[informative] data into [signature].
   */
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
  int get visibleLength =>
      throw new UnimplementedError('attempt to access deprecated field');

  @override
  int get visibleOffset =>
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
        "isStatic": isStatic,
        "name": name,
        "nameOffset": nameOffset,
        "propagatedTypeSlot": propagatedTypeSlot,
        "type": type,
      };

  @override
  String toString() => convert.JSON.encode(toJson());
}
