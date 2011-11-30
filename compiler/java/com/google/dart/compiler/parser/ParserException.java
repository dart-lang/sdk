// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.parser;

/**
 * {@link RuntimeException} which is thrown to indicate, that some inner part of parser can not
 * recovery from error, so parsing should be restarted from next known top level element.
 */
final class ParserException extends RuntimeException {
}
