import 'package:dap/dap.dart' as dap;
// ignore: implementation_imports
import 'package:vm_service/src/vm_service.dart' as vm;

extension DapExtension on vm.VmService {
  static bool _factoriesRegistered = false;
  Future<DapResponse> sendDapRequest(String message) async {
    return _callHelper<DapResponse>(
      'sendDapRequest',
      args: {'message': message},
    );
  }

  Future<T> _callHelper<T>(String method,
      {String? isolateId, Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return callMethod(
      method,
      args: {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    ).then((e) => e as T);
  }

  static void _registerFactories() {
    vm.addTypeFactory('DapResponse', DapResponse.parse);
    _factoriesRegistered = true;
  }
}

class DapResponse extends vm.Response {
  static DapResponse? parse(Map<String, dynamic>? json) =>
      json == null ? null : DapResponse._fromJson(json);

  DapResponse({
    required this.dapResponse,
  });

  DapResponse._fromJson(Map<String, dynamic> json)
      : dapResponse = dap.Response.fromJson(json['dapResponse']);

  @override
  String get type => 'DapResponse';

  @override
  String toString() => '[DapResponse]';

  final dap.Response dapResponse;
}
