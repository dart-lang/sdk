// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

enum Status {
  accepted,
  rejected,
  restarted;
}

/// Reports the result of a hot reload or restart at runtime for test validation
/// purposes only.
class HotReloadReceipt {
  final int generation;
  final Status status;

  /// Optional message describing the reason this reload was rejected.
  ///
  /// Expected to be `null` when this reload was accepted.
  final String? rejectionMessage;

  static final _generationKey = 'generation';
  static final _statusKey = 'status';
  static final _rejectionMessageKey = 'rejectionMessage';

  HotReloadReceipt({
    required this.generation,
    required this.status,
    this.rejectionMessage,
  });

  @override
  String toString() => jsonEncode(toJson());

  HotReloadReceipt.fromJson(Map<String, dynamic> json)
      : generation = json[_generationKey] as int,
        status = Status.values.byName(json[_statusKey] as String),
        rejectionMessage = json[_rejectionMessageKey] as String?;

  Map<String, dynamic> toJson() {
    return {
      _generationKey: generation,
      _statusKey: status.name,
      if (rejectionMessage != null) _rejectionMessageKey: rejectionMessage,
    };
  }

  static final hotReloadReceiptTag = '_!# HOT RELOAD RECEIPT #!_: ';

  static final compileTimeErrorMessage =
      'Correct error verified at compile time.';
}
