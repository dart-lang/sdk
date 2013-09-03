/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that looks up messages for specific locales by
 * delegating to the appropriate library.
 */

library messages_all;

import 'dart:async';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';
import 'package:intl/intl.dart';

import 'foo_messages_fr.dart' as fr;
import 'foo_messages_de_DE.dart' as de_DE;


MessageLookupByLibrary _findExact(localeName) {
  switch (localeName) {
    case 'fr' : return fr.messages;
    case 'de_DE' : return de_DE.messages;
    default: return null;
  }
}

/** User programs should call this before using [localeName] for messages.*/
Future initializeMessages(String localeName) {
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(localeName, _findGeneratedMessagesFor);
  // TODO(alanknight): Restore once Issue 12824 is fixed.
  // var lib = deferredLibraries[localeName];
  // return lib == null ? new Future.value(false) : lib.load();
  return new Future.value(true);
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, (x) => _findExact(x) != null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
