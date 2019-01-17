// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: deprecated_member_use
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unused_import

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart'
    show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = const JsonEncoder.withIndent('    ');

class DartDiagnosticServer implements ToJsonable {
  DartDiagnosticServer(this.port) {
    if (port == null) {
      throw 'port is required but was not provided';
    }
  }
  static DartDiagnosticServer fromJson(Map<String, dynamic> json) {
    final port = json['port'];
    return new DartDiagnosticServer(port);
  }

  final num port;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['port'] = port ?? (throw 'port is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('port') &&
        obj['port'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is DartDiagnosticServer) {
      return port == other.port && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}
