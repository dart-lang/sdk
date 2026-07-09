// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// No annotation here.
library late_field_checks.lib_none;

import 'late_field_checks_common.dart';

void main() {
  libraryName = 'LibraryNone';

  test(() => ClassNoneFieldNone());
  test(() => ClassNoneFinalFieldNone());
  test(() => ClassNoneFieldTrust());
  test(() => ClassNoneFinalFieldTrust());
  test(() => ClassNoneFieldCheck());
  test(() => ClassNoneFinalFieldCheck());

  test(() => ClassTrustFieldNone());
  test(() => ClassTrustFinalFieldNone());
  test(() => ClassTrustFieldTrust());
  test(() => ClassTrustFinalFieldTrust());
  test(() => ClassTrustFieldCheck());
  test(() => ClassTrustFinalFieldCheck());

  test(() => ClassCheckFieldNone());
  test(() => ClassCheckFinalFieldNone());
  test(() => ClassCheckFieldTrust());
  test(() => ClassCheckFinalFieldTrust());
  test(() => ClassCheckFieldCheck());
  test(() => ClassCheckFinalFieldCheck());
}

class ClassNoneFieldNone implements Field, Checked {
  late int field;
}

class ClassNoneFinalFieldNone implements Field, Final, Checked {
  late final int field;
}

class ClassNoneFieldTrust implements Field, Trusted {
  @pragma('dart2js:late:trust')
  late int field;
}

class ClassNoneFinalFieldTrust implements Field, Final, Trusted {
  @pragma('dart2js:late:trust')
  late final int field;
}

class ClassNoneFieldCheck implements Field, Checked {
  @pragma('dart2js:late:check')
  late int field;
}

class ClassNoneFinalFieldCheck implements Field, Final, Checked {
  @pragma('dart2js:late:check')
  late final int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFieldNone implements Field, Trusted {
  late int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFinalFieldNone implements Field, Final, Trusted {
  late final int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFieldTrust implements Field, Trusted {
  @pragma('dart2js:late:trust')
  late int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFinalFieldTrust implements Field, Final, Trusted {
  @pragma('dart2js:late:trust')
  late final int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFieldCheck implements Field, Checked {
  @pragma('dart2js:late:check')
  late int field;
}

@pragma('dart2js:late:trust')
class ClassTrustFinalFieldCheck implements Field, Final, Checked {
  @pragma('dart2js:late:check')
  late final int field;
}

@pragma('dart2js:late:check')
class ClassCheckFieldNone implements Field, Checked {
  late int field;
}

@pragma('dart2js:late:check')
class ClassCheckFinalFieldNone implements Field, Final, Checked {
  late final int field;
}

@pragma('dart2js:late:check')
class ClassCheckFieldTrust implements Field, Trusted {
  @pragma('dart2js:late:trust')
  late int field;
}

@pragma('dart2js:late:check')
class ClassCheckFinalFieldTrust implements Field, Final, Trusted {
  @pragma('dart2js:late:trust')
  late final int field;
}

@pragma('dart2js:late:check')
class ClassCheckFieldCheck implements Field, Checked {
  @pragma('dart2js:late:check')
  late int field;
}

@pragma('dart2js:late:check')
class ClassCheckFinalFieldCheck implements Field, Final, Checked {
  @pragma('dart2js:late:check')
  late final int field;
}
