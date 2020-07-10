// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';

class EditBulkFixes {
  final AnalysisServer server;
  final Request request;

  EditBulkFixes(this.server, this.request);

  Future<Response> compute() async {
    // todo (pq): implemennt
    return EditBulkFixesResult([]).toResponse(request.id);
  }
}
