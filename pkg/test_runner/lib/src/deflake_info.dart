// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// During deflaking, each test can be run with a custom timeout and repetition
/// count.
class DeflakeInfo {
  String name;
  int repeat;
  int timeout;

  DeflakeInfo(
      {required this.name, required this.repeat, required this.timeout});

  Map<dynamic, dynamic> toJson() => {
        'name': name,
        'repeat': repeat,
        'timeout': timeout,
      };

  static DeflakeInfo fromJson(Map<dynamic, dynamic> json) => DeflakeInfo(
      name: json['name'] as String,
      repeat: json['repeat'] as int? ?? 5,
      timeout: json['timeout'] as int? ?? -1);
}
