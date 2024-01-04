// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../dtd.dart';

// TODO(https://github.com/flutter/devtools/issues/6996): find an elegant way
// to extend DTDResponse.

/// A list or [uris] on the system where the Dart Tooling Daemon is running.
class UriList {
  /// The key for the type parameter.
  static const String kType = 'type';

  /// The key for the uris parameter.
  static const String kUris = 'uris';

  factory UriList.fromDTDResponse(DTDResponse response) {
    if (response.result[kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $kType param to be $type, got: ${response.result[kType]}',
      );
    }
    return UriList._fromDTDResponse(response);
  }

  /// A list of URIs.
  List<Uri>? uris;

  UriList({
    this.uris,
  });

  UriList._fromDTDResponse(DTDResponse response)
      : uris = List<String>.from(response.result[kUris] as List)
            .map(Uri.parse)
            .toList();

  static String get type => 'UriList';

  Map<String, Object?> toJson() {
    final json = <String, dynamic>{};
    json[kType] = type;
    json[kUris] = uris?.map((f) => f.toString()).toList();
    return json;
  }

  @override
  String toString() => '[UriList uris: $uris]';
}

/// The [content] of a file from the system where the Dart Tooling Daemon is
/// running.
class FileContent {
  /// The key for the type parameter.
  static const String kType = 'type';

  /// The key for the content parameter.
  static const String kContent = 'content';

  factory FileContent.fromDTDResponse(DTDResponse response) {
    if (response.result[kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $kType param to be $type, got: ${response.result[kType]}',
      );
    }
    return FileContent._fromDTDResponse(response);
  }

  /// The content of the file as a String.
  String? content;

  FileContent({this.content});

  FileContent._fromDTDResponse(DTDResponse response) {
    content = response.result[kContent] as String?;
  }

  static String get type => 'FileContent';

  Map<String, Object?> toJson() {
    final json = <String, dynamic>{};
    json[kType] = type;
    json.addAll({FileContent.kContent: content});
    return json;
  }

  @override
  String toString() => '[FileContent content: $content]';
}
