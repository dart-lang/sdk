// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/null_value.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:kernel/ast.dart' as type;

import '../kernel/inferred_collections.dart' as type;

class NullValues {
  static const NullValue Expression = const NullValue("Expression");
  static const NullValue MapLiteralEntry = const NullValue("MapLiteralEntry");
  static const NullValue Pattern = const NullValue("Pattern");
  static const NullValue Statement = const NullValue("Statement");
}

class ValueKinds {
  static const SingleValueKind<type.DartType> DartType =
      const SingleValueKind<type.DartType>();
  static const SingleValueKind<type.Expression> Expression =
      const SingleValueKind<type.Expression>();
  static const SingleValueKind<type.Expression> ExpressionOrNull =
      const SingleValueKind<type.Expression>(NullValues.Expression);
  static const SingleValueKind<type.InferredElement> InferredElement =
      const SingleValueKind<type.InferredElement>();
  static const SingleValueKind<type.InferredElement> InferredElementOrNull =
      const SingleValueKind<type.InferredElement>(NullValues.Expression);
  static const SingleValueKind<type.InferredMapLiteralEntry> MapLiteralEntry =
      const SingleValueKind<type.InferredMapLiteralEntry>();
  static const SingleValueKind<type.InferredMapLiteralEntry>
  MapLiteralEntryOrNull = const SingleValueKind<type.InferredMapLiteralEntry>(
    NullValues.MapLiteralEntry,
  );
  static const SingleValueKind<type.MapPatternEntry> MapPatternEntry =
      const SingleValueKind<type.MapPatternEntry>();
  static const SingleValueKind<type.Pattern> Pattern =
      const SingleValueKind<type.Pattern>();
  static const SingleValueKind<type.Pattern> PatternOrNull =
      const SingleValueKind<type.Pattern>(NullValues.Pattern);
  static const SingleValueKind<type.PatternGuard> PatternGuard =
      const SingleValueKind<type.PatternGuard>();
  static const SingleValueKind<type.PatternSwitchCase> PatternSwitchCase =
      const SingleValueKind<type.PatternSwitchCase>();
  static const SingleValueKind<type.Statement> Statement =
      const SingleValueKind<type.Statement>();
  static const SingleValueKind<type.Statement> StatementOrNull =
      const SingleValueKind<type.Statement>(NullValues.Statement);
  static const SingleValueKind<type.SwitchCase> SwitchCase =
      const SingleValueKind<type.SwitchCase>();
  static const SingleValueKind<type.SwitchExpressionCase> SwitchExpressionCase =
      const SingleValueKind<type.SwitchExpressionCase>();
}
