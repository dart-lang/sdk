///
//  Generated code. Do not modify.
///
library blaze.worker_worker_protocol;

import 'package:protobuf/protobuf.dart';

class Input extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Input')
    ..a(1, 'path', PbFieldType.OS)
    ..a(2, 'digest', PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Input() : super();
  Input.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Input.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Input clone() => new Input()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Input create() => new Input();
  static PbList<Input> createRepeated() => new PbList<Input>();
  static Input getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyInput();
    return _defaultInstance;
  }
  static Input _defaultInstance;
  static void $checkItem(Input v) {
    if (v is !Input) checkItemFailed(v, 'Input');
  }

  String get path => $_get(0, 1, '');
  void set path(String v) { $_setString(0, 1, v); }
  bool hasPath() => $_has(0, 1);
  void clearPath() => clearField(1);

  List<int> get digest => $_get(1, 2, null);
  void set digest(List<int> v) { $_setBytes(1, 2, v); }
  bool hasDigest() => $_has(1, 2);
  void clearDigest() => clearField(2);
}

class _ReadonlyInput extends Input with ReadonlyMessageMixin {}

class WorkRequest extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('WorkRequest')
    ..p(1, 'arguments', PbFieldType.PS)
    ..pp(2, 'inputs', PbFieldType.PM, Input.$checkItem, Input.create)
    ..hasRequiredFields = false
  ;

  WorkRequest() : super();
  WorkRequest.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  WorkRequest.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  WorkRequest clone() => new WorkRequest()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static WorkRequest create() => new WorkRequest();
  static PbList<WorkRequest> createRepeated() => new PbList<WorkRequest>();
  static WorkRequest getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyWorkRequest();
    return _defaultInstance;
  }
  static WorkRequest _defaultInstance;
  static void $checkItem(WorkRequest v) {
    if (v is !WorkRequest) checkItemFailed(v, 'WorkRequest');
  }

  List<String> get arguments => $_get(0, 1, null);

  List<Input> get inputs => $_get(1, 2, null);
}

class _ReadonlyWorkRequest extends WorkRequest with ReadonlyMessageMixin {}

class WorkResponse extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('WorkResponse')
    ..a(1, 'exitCode', PbFieldType.O3)
    ..a(2, 'output', PbFieldType.OS)
    ..hasRequiredFields = false
  ;

  WorkResponse() : super();
  WorkResponse.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  WorkResponse.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  WorkResponse clone() => new WorkResponse()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static WorkResponse create() => new WorkResponse();
  static PbList<WorkResponse> createRepeated() => new PbList<WorkResponse>();
  static WorkResponse getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyWorkResponse();
    return _defaultInstance;
  }
  static WorkResponse _defaultInstance;
  static void $checkItem(WorkResponse v) {
    if (v is !WorkResponse) checkItemFailed(v, 'WorkResponse');
  }

  int get exitCode => $_get(0, 1, 0);
  void set exitCode(int v) { $_setUnsignedInt32(0, 1, v); }
  bool hasExitCode() => $_has(0, 1);
  void clearExitCode() => clearField(1);

  String get output => $_get(1, 2, '');
  void set output(String v) { $_setString(1, 2, v); }
  bool hasOutput() => $_has(1, 2);
  void clearOutput() => clearField(2);
}

class _ReadonlyWorkResponse extends WorkResponse with ReadonlyMessageMixin {}

const Input$json = const {
  '1': 'Input',
  '2': const [
    const {'1': 'path', '3': 1, '4': 1, '5': 9},
    const {'1': 'digest', '3': 2, '4': 1, '5': 12},
  ],
};

const WorkRequest$json = const {
  '1': 'WorkRequest',
  '2': const [
    const {'1': 'arguments', '3': 1, '4': 3, '5': 9},
    const {'1': 'inputs', '3': 2, '4': 3, '5': 11, '6': '.blaze.worker.Input'},
  ],
};

const WorkResponse$json = const {
  '1': 'WorkResponse',
  '2': const [
    const {'1': 'exit_code', '3': 1, '4': 1, '5': 5},
    const {'1': 'output', '3': 2, '4': 1, '5': 9},
  ],
};

