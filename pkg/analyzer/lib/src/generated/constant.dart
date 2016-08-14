// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.constant;

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart' show RecordingErrorListener;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/type_system.dart'
    show TypeSystem, TypeSystemImpl;

export 'package:analyzer/context/declared_variables.dart';
export 'package:analyzer/dart/constant/value.dart';
export 'package:analyzer/src/dart/constant/evaluation.dart';
export 'package:analyzer/src/dart/constant/utilities.dart';
export 'package:analyzer/src/dart/constant/value.dart';

/// Instances of the class [ConstantEvaluator] evaluate constant expressions to
/// produce their compile-time value.
///
/// According to the Dart Language Specification:
///
/// > A constant expression is one of the following:
/// >
/// > * A literal number.
/// > * A literal boolean.
/// > * A literal string where any interpolated expression is a compile-time
/// >   constant that evaluates to a numeric, string or boolean value or to
/// >   **null**.
/// > * A literal symbol.
/// > * **null**.
/// > * A qualified reference to a static constant variable.
/// > * An identifier expression that denotes a constant variable, class or type
/// >   alias.
/// > * A constant constructor invocation.
/// > * A constant list literal.
/// > * A constant map literal.
/// > * A simple or qualified identifier denoting a top-level function or a
/// >   static method.
/// > * A parenthesized expression _(e)_ where _e_ is a constant expression.
/// > * <span>
/// >   An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i>
/// >   where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions and <i>identical()</i> is statically bound to the predefined
/// >   dart function <i>identical()</i> discussed above.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i>
/// >   or <i>e<sub>1</sub> != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a
/// >   numeric, string or boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> || e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to a boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &amp; e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;&gt;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to an integer value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> +
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> -e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> * e<sub>2</sub></i>, <i>e<sub>1</sub> /
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> ~/ e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &gt; e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;= e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or <i>e<sub>1</sub> %
/// >   e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a numeric
/// >   value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> :
/// >   e<sub>3</sub></i> where <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and
/// >   <i>e<sub>3</sub></i> are constant expressions, and <i>e<sub>1</sub></i>
/// >   evaluates to a boolean value.
/// >   </span>
///
/// The values returned by instances of this class are therefore `null` and
/// instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
/// `DartObject`.
///
/// In addition, this class defines several values that can be returned to
/// indicate various conditions encountered during evaluation. These are
/// documented with the static fields that define those values.
@deprecated
class ConstantEvaluator {
  /**
   * The source containing the expression(s) that will be evaluated.
   */
  final Source _source;

  /**
   * The type provider used to access the known types.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system primitives.
   */
  final TypeSystem _typeSystem;

  /**
   * Initialize a newly created evaluator to evaluate expressions in the given
   * [source]. The [typeProvider] is the type provider used to access known
   * types.
   */
  ConstantEvaluator(this._source, this._typeProvider, {TypeSystem typeSystem})
      : _typeSystem = typeSystem ?? new TypeSystemImpl();

  EvaluationResult evaluate(Expression expression) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(_typeProvider, new DeclaredVariables(),
            typeSystem: _typeSystem),
        errorReporter));
    if (result != null) {
      return EvaluationResult.forValue(result);
    }
    return EvaluationResult.forErrors(errorListener.errors);
  }
}
