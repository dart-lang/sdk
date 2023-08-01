// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The context in which a snippet request was made.
///
/// This is used to filter the available snippets (for example preventing
/// snippets that create classes showing up when inside an existing class or
/// function body).
enum SnippetContext {
  atTopLevel,
  inAnnotation,
  inBlock,
  inClass,
  inComment,
  inConstructorInvocation,
  inExpression,
  inIdentifierDeclaration,
  inPattern,
  inQualifiedMemberAccess,
  inStatement,
  inString,
  inName,
}
