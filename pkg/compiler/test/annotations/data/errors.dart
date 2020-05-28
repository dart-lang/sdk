// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  unknown();
  noInlineField;
  tryInlineField;
  noThrowsWithoutNoInline();
  noSideEffectsWithoutNoInline();
  asConflict1();
  asConflict2();
  parameterConflict1();
  parameterConflict2();
  downcastConflict1();
  downcastConflict2();
  typesConflict1();
  typesConflict2();
}

@pragma('dart2js:unknown')
/*error: [Unknown dart2js pragma @pragma('dart2js:unknown')]*/
unknown() {}

@pragma('dart2js:noInline')
var
/*error: [@pragma('dart2js:noInline') annotation is only supported for methods and constructors.]*/
    noInlineField;

@pragma('dart2js:tryInline')
var
/*error: [@pragma('dart2js:tryInline') annotation is only supported for methods and constructors.]*/
    tryInlineField;

@pragma('dart2js:noThrows')
/*error: [@pragma('dart2js:noThrows') should always be combined with @pragma('dart2js:noInline').]*/
noThrowsWithoutNoInline() {}

@pragma('dart2js:noSideEffects')
/*error: [@pragma('dart2js:noSideEffects') should always be combined with @pragma('dart2js:noInline').]*/
noSideEffectsWithoutNoInline() {}

@pragma('dart2js:as:trust')
@pragma('dart2js:as:check')
/*error: [@pragma('dart2js:as:check') must not be used with @pragma('dart2js:as:trust').]*/
asConflict1() {}

@pragma('dart2js:as:trust')
@pragma('dart2js:as:check')
/*error: [@pragma('dart2js:as:check') must not be used with @pragma('dart2js:as:trust').]*/
asConflict2() {}

@pragma('dart2js:parameter:trust')
@pragma('dart2js:parameter:check')
/*error: [@pragma('dart2js:parameter:check') must not be used with @pragma('dart2js:parameter:trust').]*/
parameterConflict1() {}

@pragma('dart2js:parameter:trust')
@pragma('dart2js:parameter:check')
/*error: [@pragma('dart2js:parameter:check') must not be used with @pragma('dart2js:parameter:trust').]*/
parameterConflict2() {}

@pragma('dart2js:downcast:trust')
@pragma('dart2js:downcast:check')
/*error: [@pragma('dart2js:downcast:check') must not be used with @pragma('dart2js:downcast:trust').]*/
downcastConflict1() {}

@pragma('dart2js:downcast:trust')
@pragma('dart2js:downcast:check')
/*error: [@pragma('dart2js:downcast:check') must not be used with @pragma('dart2js:downcast:trust').]*/
downcastConflict2() {}

@pragma('dart2js:types:trust')
@pragma('dart2js:types:check')
/*error: [@pragma('dart2js:types:check') must not be used with @pragma('dart2js:types:trust').]*/
typesConflict1() {}

@pragma('dart2js:types:trust')
@pragma('dart2js:types:check')
/*error: [@pragma('dart2js:types:check') must not be used with @pragma('dart2js:types:trust').]*/
typesConflict2() {}
