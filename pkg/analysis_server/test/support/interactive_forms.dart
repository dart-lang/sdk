// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_custom_generated.dart';

extension FormFieldExtension on FormField {
  /// Returns a [FormAnswer] for this field with the answer [value].
  FormAnswer answer(Object? value) {
    return FormAnswer(id: id, value: value);
  }
}
