// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/null_value.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:kernel/ast.dart' as type;

class NullValues {
  static const NullValue<type.Expression> Expression =
      const NullValue<type.Expression>();
  static const NullValue<type.MapLiteralEntry> MapLiteralEntry =
      const NullValue<type.MapLiteralEntry>();
  static const NullValue<type.Pattern> Pattern =
      const NullValue<type.Pattern>();
  static const NullValue<type.Statement> Statement =
      const NullValue<type.Statement>();
}

class ValueKinds {
  static const SingleValueKind<type.DartType> DartType =
      const SingleValueKind<type.DartType>();
  static const SingleValueKind<type.Expression> Expression =
      const SingleValueKind<type.Expression>();
  static const SingleValueKind<type.Expression> ExpressionOrNull =
      const SingleValueKind<type.Expression>(NullValues.Expression);
  static const SingleValueKind<type.MapLiteralEntry> MapLiteralEntry =
      const SingleValueKind<type.MapLiteralEntry>();
  static const SingleValueKind<type.MapLiteralEntry> MapLiteralEntryOrNull =
      const SingleValueKind<type.MapLiteralEntry>(NullValues.MapLiteralEntry);
  static const SingleValueKind<type.MapPatternEntry> MapPatternEntry =
      const SingleValueKind<type.MapPatternEntry>();
  static const SingleValueKind<type.Pattern> Pattern =
      const SingleValueKind<type.Pattern>();
  static const SingleValueKind<type.Pattern> PatternOrNull =
      const SingleValueKind<type.Pattern>(NullValues.Pattern);
  static const SingleValueKind<type.Statement> Statement =
      const SingleValueKind<type.Statement>();
  static const SingleValueKind<type.Statement> StatementOrNull =
      const SingleValueKind<type.Statement>(NullValues.Statement);
  static const SingleValueKind<type.SwitchCase> SwitchCase =
      const SingleValueKind<type.SwitchCase>();
}
