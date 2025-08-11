// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'response_types.dart';

/// A DTD response that contains information about a set of VM service
/// connections.
class VmServicesResponse {
  const VmServicesResponse({required this.vmServicesInfos});

  factory VmServicesResponse.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return VmServicesResponse._fromDTDResponse(response);
  }

  VmServicesResponse._fromDTDResponse(DTDResponse response)
      : vmServicesInfos = List<Map<String, Object?>>.from(
          (response.result[_kVmServices] as List).cast<Map<String, Object?>>(),
        ).map(VmServiceInfo.fromJson).toList();

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the VM services parameter.
  static const String _kVmServices = 'vmServices';

  /// A list of VM services and their associated metadata.
  final List<VmServiceInfo> vmServicesInfos;

  static String get type => 'VmServicesResponse';

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        _kVmServices: vmServicesInfos.map((info) => info.toJson()).toList(),
      };

  @override
  String toString() => '[$type $_kVmServices: $vmServicesInfos]';
}

/// Information about a VM service connection that is exposed via the DTD.
class VmServiceInfo {
  const VmServiceInfo({
    required this.uri,
    this.exposedUri,
    this.name,
  });

  /// Deserializes a [json] object to create a [VmServiceInfo] object.
  static VmServiceInfo fromJson(Map<String, Object?> json) => VmServiceInfo(
        uri: json[_kUri] as String,
        exposedUri: json[_kExposedUri] as String?,
        name: json[_kName] as String?,
      );

  static const String _kUri = 'uri';
  static const String _kExposedUri = 'exposedUri';
  static const String _kName = 'name';

  /// The URI for the VM service connection.
  final String uri;

  /// The URI for the VM service connection that has been exposed to the
  /// user/client machine if the backend VM service is running in a different
  /// location (for example, an editor running in the user's browser with the
  /// backend on a remote server).
  ///
  /// Code that runs on the user/client machine (such as DevTools and DevTools
  /// extensions) should prefer this URI (if provided) whereas code that also
  /// runs on the backend (such as the debug adapter) should always use [uri].
  ///
  /// This value will be null or identical to [uri] in environments where
  /// there is no exposing to do (for example, an editor running locally on the
  /// same machine that the VM service is running).
  final String? exposedUri;

  /// The human-readable name for this VM service connection as defined by tool
  /// or service that started it (e.g. 'Flutter - Pixel 5').
  ///
  /// This is optional and may be null if the DTD client that registered the VM
  /// service did not provide a name.
  final String? name;

  /// Serializes this [VmServiceInfo] object to JSON.
  Map<String, Object?> toJson() => <String, Object?>{
        _kUri: uri,
        if (exposedUri != null) _kExposedUri: exposedUri,
        if (name != null) _kName: name,
      };

  @override
  String toString() {
    final sb = StringBuffer()..write(uri);
    if (exposedUri != null && exposedUri != uri) {
      sb.write(' (exposed: $exposedUri)');
    }
    if (name != null) {
      sb.write(' - $name');
    }
    return sb.toString();
  }
}
