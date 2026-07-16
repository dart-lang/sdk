// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'internal_ast.dart';

/// Base class for all control-flow elements.
sealed class ControlFlowElement({required super.fileOffset})
    extends InternalExpression {
  /// Returns this control flow element as a [MapLiteralEntry], or `null` if
  /// this control flow element cannot be converted into a [MapLiteralEntry].
  ///
  /// [onConvertElement] is called when a [ForElement], [ForInElement], or
  /// [IfElement] is converted to a [ForMapEntry], [ForInMapEntry], or
  /// [IfMapEntry], respectively.
  // TODO(johnniwinther): Merge this with [convertToMapEntry].
  InternalMapLiteralEntry? toMapLiteralEntry(
    void onConvertElement(ControlFlowElement from, ControlFlowMapEntry to),
  );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    throw new UnsupportedError('$runtimeType.acceptInference');
  }
}

/// A spread element in a list or set literal.
class SpreadElement extends ControlFlowElement {
  final InternalExpression expression;
  final bool isNullAware;

  new(this.expression, {required this.isNullAware, required super.fileOffset});

  @override
  SpreadMapEntry toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    return new SpreadMapEntry(
      expression,
      isNullAware: isNullAware,
      fileOffset: fileOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (isNullAware) {
      printer.write('?');
    }
    expression.toTextInternal(printer);
  }
}

class NullAwareElement extends ControlFlowElement {
  final InternalExpression expression;

  new(this.expression, {required super.fileOffset});

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    throw new UnsupportedError('$runtimeType.toMapLiteralEntry');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
    expression.toTextInternal(printer);
  }
}

/// An 'if' element in a list or set literal.
class IfElement extends ControlFlowElement {
  final InternalExpression condition;
  final InternalExpression then;
  final InternalExpression? otherwise;

  new(this.condition, this.then, this.otherwise, {required super.fileOffset});

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    InternalMapLiteralEntry? thenEntry;
    InternalExpression then = this.then;
    if (then is ControlFlowElement) {
      ControlFlowElement thenElement = then;
      thenEntry = thenElement.toMapLiteralEntry(onConvertElement);
    }
    if (thenEntry == null) return null;
    InternalMapLiteralEntry? otherwiseEntry;
    InternalExpression? otherwise = this.otherwise;
    if (otherwise != null) {
      // Coverage-ignore-block(suite): Not run.
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapLiteralEntry(onConvertElement);
      }
      if (otherwiseEntry == null) return null;
    }
    IfMapEntry result = new IfMapEntry(
      condition,
      thenEntry,
      otherwiseEntry,
      fileOffset: fileOffset,
    );
    onConvertElement(this, result);
    return result;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    condition.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

/// A 'for' element in a list or set literal.
class ForElement extends ControlFlowElement implements ForElementBase {
  // May be empty, but not null.
  @override
  final List<InternalVariableDeclaration> variables;

  @override
  final InternalExpression? condition; // May be null.

  @override
  final List<InternalExpression> updates; // May be empty, but not null.

  @override
  final InternalExpression body;

  new(
    this.variables,
    this.condition,
    this.updates,
    this.body, {
    required super.fileOffset,
  });

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    InternalMapLiteralEntry? bodyEntry;
    InternalExpression body = this.body;
    if (body is ControlFlowElement) {
      ControlFlowElement bodyElement = body;
      bodyEntry = bodyElement.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForMapEntry result = new ForMapEntry(
      variables,
      condition,
      updates,
      bodyEntry,
      fileOffset: fileOffset,
    );
    onConvertElement(this, result);
    return result;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

/// A 'for-in' element in a list or set literal.
class ForInElement extends ControlFlowElement {
  final InternalForInElement element;
  final InternalExpression iterable;
  final InternalExpression body;
  final bool isAsync; // True if this is an 'await for' loop.

  /// File offset for the `for` keyword.
  final int forOffset;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required super.fileOffset,
    required this.forOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    InternalMapLiteralEntry? bodyEntry;
    InternalExpression body = this.body;
    if (body is ControlFlowElement) {
      bodyEntry = body.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForInMapEntry result = new ForInMapEntry(
      element,
      iterable,
      bodyEntry,
      isAsync: isAsync,
      fileOffset: fileOffset,
      forOffset: forOffset,
    );
    onConvertElement(this, result);
    return result;
  }
}

class IfCaseElement extends ControlFlowElement {
  final InternalExpression expression;
  final InternalPatternGuard patternGuard;
  final InternalExpression then;
  final InternalExpression? otherwise;

  new({
    required this.expression,
    required this.patternGuard,
    required this.then,
    this.otherwise,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    InternalMapLiteralEntry? thenEntry;
    InternalExpression then = this.then;
    if (then is ControlFlowElement) {
      ControlFlowElement thenElement = then;
      thenEntry = thenElement.toMapLiteralEntry(onConvertElement);
    }
    if (thenEntry == null) return null;
    InternalMapLiteralEntry? otherwiseEntry;
    InternalExpression? otherwise = this.otherwise;
    if (otherwise != null) {
      // Coverage-ignore-block(suite): Not run.
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapLiteralEntry(onConvertElement);
      }
      if (otherwiseEntry == null) return null;
    }
    IfCaseMapEntry result = new IfCaseMapEntry(
      expression: expression,
      patternGuard: this.patternGuard,
      then: thenEntry,
      otherwise: otherwiseEntry,
      fileOffset: fileOffset,
    );
    onConvertElement(this, result);
    return result;
  }
}

abstract interface class ForElementBase implements InternalExpression {
  List<InternalVariableDeclaration> get variables;

  InternalExpression? get condition;

  List<InternalExpression> get updates;

  InternalExpression get body;
}

class PatternForElement extends ControlFlowElement implements ForElementBase {
  final InternalPatternVariableDeclaration patternVariableDeclaration;
  final List<InternalVariableDeclaration> intermediateVariables;

  // May be empty, but not null.
  @override
  final List<InternalVariableDeclaration> variables;

  @override
  final InternalExpression? condition; // May be null.

  @override
  final List<InternalExpression> updates; // May be empty, but not null.

  @override
  final InternalExpression body;

  new({
    required this.patternVariableDeclaration,
    required this.intermediateVariables,
    required this.variables,
    required this.condition,
    required this.updates,
    required this.body,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }

  @override
  InternalMapLiteralEntry? toMapLiteralEntry(
    void Function(ControlFlowElement, ControlFlowMapEntry) onConvertElement,
  ) {
    throw new UnimplementedError("toMapLiteralEntry");
  }
}

/// Base class for all control-flow map entries.
sealed class ControlFlowMapEntry({required super.fileOffset})
    extends InternalNode
    implements InternalMapLiteralEntry {}

/// A null-aware entry in a map literal.
class NullAwareMapEntry extends ControlFlowMapEntry {
  /// `true` if the key expression is null-aware, that is, marked with `?`.
  final bool isKeyNullAware;

  final InternalExpression key;

  /// `true` if the value expression is null-aware, that is, marked with `?`.
  final bool isValueNullAware;

  final InternalExpression value;

  new({
    required this.isKeyNullAware,
    required this.key,
    required this.isValueNullAware,
    required this.value,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isKeyNullAware) {
      printer.write('?');
    }
    key.toTextInternal(printer);
    printer.write(': ');
    if (isValueNullAware) {
      printer.write('?');
    }
    value.toTextInternal(printer);
  }
}

/// A spread element in a map literal.
class SpreadMapEntry extends ControlFlowMapEntry {
  final InternalExpression expression;
  final bool isNullAware;

  new(this.expression, {required this.isNullAware, required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    expression.toTextInternal(printer);
  }
}

/// An 'if' element in a map literal.
class IfMapEntry extends ControlFlowMapEntry {
  final InternalExpression condition;
  final InternalMapLiteralEntry then;
  final InternalMapLiteralEntry? otherwise;

  new(this.condition, this.then, this.otherwise, {required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    condition.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

sealed class ForMapEntryBase implements InternalMapLiteralEntry {
  List<InternalVariableDeclaration> get variables;

  InternalExpression? get condition;

  List<InternalExpression> get updates;

  InternalMapLiteralEntry get body;
}

/// A 'for' element in a map literal.
class ForMapEntry extends ControlFlowMapEntry implements ForMapEntryBase {
  @override
  final List<InternalVariableDeclaration> variables;

  @override
  final InternalExpression? condition;

  @override
  final List<InternalExpression> updates;

  @override
  final InternalMapLiteralEntry body;

  new(
    this.variables,
    this.condition,
    this.updates,
    this.body, {
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

class PatternForMapEntry extends ControlFlowMapEntry
    implements ForMapEntryBase {
  final InternalPatternVariableDeclaration patternVariableDeclaration;
  final List<InternalVariableDeclaration> intermediateVariables;

  @override
  final List<InternalVariableDeclaration> variables;

  @override
  final InternalExpression? condition;

  @override
  final List<InternalExpression> updates;

  @override
  final InternalMapLiteralEntry body;

  new({
    required this.patternVariableDeclaration,
    required this.intermediateVariables,
    required this.variables,
    required this.condition,
    required this.updates,
    required this.body,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

/// A 'for-in' element in a map literal.
class ForInMapEntry extends ControlFlowMapEntry {
  final InternalForInElement element;
  final InternalExpression iterable;
  final InternalMapLiteralEntry body;
  final bool isAsync; // True if this is an 'await for' loop.

  /// File offset for the `for` keyword.
  final int forOffset;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required super.fileOffset,
    required this.forOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

class IfCaseMapEntry extends ControlFlowMapEntry {
  final InternalExpression expression;
  final InternalPatternGuard patternGuard;
  final InternalMapLiteralEntry then;
  final InternalMapLiteralEntry? otherwise;

  new({
    required this.expression,
    required this.patternGuard,
    required this.then,
    this.otherwise,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

bool isConvertibleToMapEntry(InternalExpression element) {
  if (element is ControlFlowElement) {
    switch (element) {
      case SpreadElement():
        return true;
      case NullAwareElement():
        return false;
      case IfElement():
        return isConvertibleToMapEntry(element.then) &&
            (element.otherwise == null ||
                isConvertibleToMapEntry(element.otherwise!));
      case IfCaseElement():
        return isConvertibleToMapEntry(element.then) &&
            (element.otherwise == null ||
                isConvertibleToMapEntry(element.otherwise!));
      case ForElement():
        return isConvertibleToMapEntry(element.body);
      case PatternForElement():
        return isConvertibleToMapEntry(element.body);
      case ForInElement():
        return isConvertibleToMapEntry(element.body);
    }
  } else {
    return false;
  }
}

/// Convert [element] to a [MapLiteralEntry], if possible. If [element] cannot
/// be converted an error reported through [helper] and a map entry holding an
/// invalid expression is returned.
///
/// [onConvertElement] is called when a [ForElement], [ForInElement], or
/// [IfElement] is converted to a [ForMapEntry], [ForInMapEntry], or
/// [IfMapEntry], respectively.
InternalMapLiteralEntry convertToMapEntry(
  InternalExpression element,
  ProblemReporting problemReporting,
  CompilerContext compilerContext,
  Uri fileUri,
  void Function(ControlFlowElement from, ControlFlowMapEntry to)
  onConvertElement,
) {
  if (element is ControlFlowElement) {
    switch (element) {
      case SpreadElement():
        return new SpreadMapEntry(
          element.expression,
          isNullAware: element.isNullAware,
          fileOffset: element.expression.fileOffset,
        );

      case NullAwareElement():
        // Coverage-ignore(suite): Not run.
        return _convertToErroneousMapEntry(
          element,
          problemReporting,
          compilerContext,
          fileUri,
        );

      case IfElement():
        IfMapEntry result = new IfMapEntry(
          element.condition,
          convertToMapEntry(
            element.then,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          element.otherwise == null
              ? null
              : convertToMapEntry(
                  element.otherwise!,
                  problemReporting,
                  compilerContext,
                  fileUri,
                  onConvertElement,
                ),
          fileOffset: element.fileOffset,
        );
        onConvertElement(element, result);
        return result;

      case IfCaseElement():
        IfCaseMapEntry result = new IfCaseMapEntry(
          expression: element.expression,
          patternGuard: element.patternGuard,
          then: convertToMapEntry(
            element.then,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          otherwise: element.otherwise == null
              ? null
              : convertToMapEntry(
                  element.otherwise!,
                  problemReporting,
                  compilerContext,
                  fileUri,
                  onConvertElement,
                ),
          fileOffset: element.fileOffset,
        );
        onConvertElement(element, result);
        return result;

      case PatternForElement():
        PatternForMapEntry result = new PatternForMapEntry(
          patternVariableDeclaration: element.patternVariableDeclaration,
          intermediateVariables: element.intermediateVariables,
          variables: element.variables,
          condition: element.condition,
          updates: element.updates,
          body: convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          fileOffset: element.fileOffset,
        );
        onConvertElement(element, result);
        return result;

      case ForElement():
        ForMapEntry result = new ForMapEntry(
          element.variables,
          element.condition,
          element.updates,
          convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          fileOffset: element.fileOffset,
        );
        onConvertElement(element, result);
        return result;

      case ForInElement():
        ForInMapEntry result = new ForInMapEntry(
          element.element,
          element.iterable,
          convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          fileOffset: element.fileOffset,
          forOffset: element.forOffset,
          isAsync: element.isAsync,
        );
        onConvertElement(element, result);
        return result;
    }
  } else {
    return _convertToErroneousMapEntry(
      element,
      problemReporting,
      compilerContext,
      fileUri,
    );
  }
}

InternalMapLiteralEntry _convertToErroneousMapEntry(
  InternalExpression element,
  ProblemReporting problemReporting,
  CompilerContext compilerContext,
  Uri fileUri,
) {
  return intern.createMapLiteralEntry(
    intern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.expectedAfterButGot.withArguments(expected: ':'),
        fileUri: fileUri,
        fileOffset: element.fileOffset,
        // TODO(danrubel): what is the length of the expression?
        length: noLength,
      ),
    ),
    intern.createNullLiteral(element.fileOffset),
    fileOffset: element.fileOffset,
  );
}
