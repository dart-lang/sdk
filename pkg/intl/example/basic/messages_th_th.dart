// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a library that provides messages for a German locale. All the
 * messages from the main program should be duplicated here with the same
 * function name.
 */
library messages_th_TH;
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

class MessageLookup extends MessageLookupByLibrary {

  get localeName => 'th_TH';

  final messages = {
    "runAt": (time, day) => Intl.message('วิ่ง $time on $day.')
  };
}
