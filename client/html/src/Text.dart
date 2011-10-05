// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Text extends CharacterData factory TextWrappingImplementation {
  
  Text(String content);

  String get wholeText();

  Text replaceWholeText([String content]);

  Text splitText([int offset]);
}
