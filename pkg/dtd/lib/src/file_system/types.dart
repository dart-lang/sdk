// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../dtd.dart';

/// A list or [uris] on the system where the Dart Tooling Daemon is running.
class UriList {
  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the uris parameter.
  static const String _kUris = 'uris';

  factory UriList.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
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
      : uris = List<String>.from(response.result[_kUris] as List)
            .map(Uri.parse)
            .toList();

  static String get type => 'UriList';

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        _kUris: uris?.map((f) => f.toString()).toList(),
      };

  @override
  String toString() => '[UriList uris: $uris]';
}

/// The [content] of a file from the system where the Dart Tooling Daemon is
/// running.
class FileContent {
  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the content parameter.
  static const String _kContent = 'content';

  factory FileContent.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return FileContent._fromDTDResponse(response);
  }

  /// The content of the file as a String.
  String? content;

  FileContent({this.content});

  FileContent._fromDTDResponse(DTDResponse response) {
    content = response.result[_kContent] as String?;
  }

  static String get type => 'FileContent';

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        FileContent._kContent: content,
      };

  @override
  String toString() => '[FileContent content: $content]';
}

/// The list of roots in the IDE workspace.
class IDEWorkspaceRoots {
  /// The key for the type parameter.
  static const String _kType = 'type';
  static String get type => 'IDEWorkspaceRoots';

  /// The key for the content parameter.
  static const String kIDEWorkspaceRoots = 'ideWorkspaceRoots';

  factory IDEWorkspaceRoots.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return IDEWorkspaceRoots._fromDTDResponse(response);
  }

  /// The lists of IDE workspace roots.
  final List<Uri> ideWorkspaceRoots;

  IDEWorkspaceRoots({required this.ideWorkspaceRoots});

  IDEWorkspaceRoots._fromDTDResponse(DTDResponse response)
      : ideWorkspaceRoots =
            List<String>.from(response.result[kIDEWorkspaceRoots] as List)
                .map(Uri.parse)
                .toList();

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        kIDEWorkspaceRoots: ideWorkspaceRoots.map((e) => e.toString()).toList(),
      };

  @override
  String toString() =>
      '[IDEWorkspaceRoots ideWorkspaceRoots: $ideWorkspaceRoots]';
}
