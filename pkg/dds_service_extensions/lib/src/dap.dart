// ignore: implementation_imports
import 'package:vm_service/src/vm_service.dart';

extension DapExtension on VmService {
  static bool _factoriesRegistered = false;
  Future<DapResponse> handleDap(String message) async {
    return _callHelper<DapResponse>(
      'handleDap',
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
    addTypeFactory('DapResponse', DapResponse.parse);
    _factoriesRegistered = true;
  }
}

class DapResponse extends Response {
  static DapResponse? parse(Map<String, dynamic>? json) =>
      json == null ? null : DapResponse._fromJson(json);

  DapResponse({
    required this.message,
  });

  DapResponse._fromJson(Map<String, dynamic> json) : message = json['message'];

  @override
  String get type => 'DapResponse';

  @override
  String toString() => '[DapResponse]';

  final Map<String, Object?> message;
}
