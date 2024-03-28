// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../dtd.dart';

/// A list or [uris] on the system where the Dart Tooling Daemon is running.
class UriList {
  const UriList({this.uris});

  factory UriList.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return UriList._fromDTDResponse(response);
  }

  UriList._fromDTDResponse(DTDResponse response)
      : uris = List<String>.from(response.result[_kUris] as List)
            .map(Uri.parse)
            .toList();

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the uris parameter.
  static const String _kUris = 'uris';

  /// A list of URIs.
  final List<Uri>? uris;

  static String get type => 'UriList';

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        _kUris: uris?.map((f) => f.toString()).toList(),
      };

  @override
  String toString() => '[$type uris: $uris]';
}

/// The [content] of a file from the system where the Dart Tooling Daemon is
/// running.
class FileContent {
  const FileContent({this.content});

  factory FileContent.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return FileContent._fromDTDResponse(response);
  }

  FileContent._fromDTDResponse(DTDResponse response)
      : content = response.result[_kContent] as String?;

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the content parameter.
  static const String _kContent = 'content';

  static String get type => 'FileContent';

  /// The content of the file as a String.
  final String? content;

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        FileContent._kContent: content,
      };

  @override
  String toString() => '[$type content: $content]';
}

/// The list of roots in the IDE workspace.
class IDEWorkspaceRoots {
  const IDEWorkspaceRoots({required this.ideWorkspaceRoots});

  factory IDEWorkspaceRoots.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return IDEWorkspaceRoots._fromDTDResponse(response);
  }

  IDEWorkspaceRoots._fromDTDResponse(DTDResponse response)
      : ideWorkspaceRoots =
            List<String>.from(response.result[kIDEWorkspaceRoots] as List)
                .map(Uri.parse)
                .toList();

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the content parameter.
  static const String kIDEWorkspaceRoots = 'ideWorkspaceRoots';

  static String get type => 'IDEWorkspaceRoots';

  /// The list of IDE workspace roots.
  final List<Uri> ideWorkspaceRoots;

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        kIDEWorkspaceRoots: ideWorkspaceRoots.map((e) => e.toString()).toList(),
      };

  @override
  String toString() => '[$type ideWorkspaceRoots: $ideWorkspaceRoots]';
}
