// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This imports all of the different message libraries and provides an
 * [initializeMessages] function that sets up the lookup for a particular
 * library.
 */
library messages_all;

import 'dart:async';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';
import 'messages_th_th.dart' as th_TH;
import 'messages_de.dart' as de;
import 'package:intl/intl.dart';

// TODO(alanknight): Use lazy loading of the requested library.
MessageLookupByLibrary _findExact(localeName) {
  switch (localeName) {
    case 'th_TH' : return th_TH.messages;
    case 'de' : return de.messages;
    default: return null;
  }
}

initializeMessages(localeName) {
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(localeName, _findGeneratedMessagesFor);
  return new Future.value();
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, (x) => _findExact(x) != null,
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
