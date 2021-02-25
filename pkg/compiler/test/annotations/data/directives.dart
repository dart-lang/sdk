// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  typesTrust();
  typesCheck();
  asTrust();
  asCheck();
  downcastTrust();
  downcastCheck();
  parameterTrust();
  parameterCheck();
  indexBoundsTrust();
  indexBoundsCheck();
}

/*member: typesTrust:types:trust*/
@pragma('dart2js:types:trust')
typesTrust() {}

/*member: typesCheck:types:check*/
@pragma('dart2js:types:check')
typesCheck() {}

/*member: asTrust:as:trust*/
@pragma('dart2js:as:trust')
asTrust() {}

/*member: asCheck:as:check*/
@pragma('dart2js:as:check')
asCheck() {}

/*member: downcastTrust:downcast:trust*/
@pragma('dart2js:downcast:trust')
downcastTrust() {}

/*member: downcastCheck:downcast:check*/
@pragma('dart2js:downcast:check')
downcastCheck() {}

/*member: parameterTrust:parameter:trust*/
@pragma('dart2js:parameter:trust')
parameterTrust() {}

/*member: parameterCheck:parameter:check*/
@pragma('dart2js:parameter:check')
parameterCheck() {}

/*member: indexBoundsTrust:index-bounds:trust*/
@pragma('dart2js:index-bounds:trust')
indexBoundsTrust() {}

/*member: indexBoundsCheck:index-bounds:check*/
@pragma('dart2js:index-bounds:check')
indexBoundsCheck() {}
