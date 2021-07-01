// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N valid_regexps`

var bad = RegExp('('); //LINT
var good = RegExp('[(]'); //OK
var interpolated = '';
var skipped = RegExp('( $interpolated'); //OK -- skipped
/// https://stackoverflow.com/questions/61151471/regexp-for-unicode-13-emojis
var emojis = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    unicode: true); //OK
