// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Efficient JavaScript code builder.
///
/// Used to create wrapper expressions and functions for expression evaluation.
class JsBuilder {
  var _indent = 0;
  final _buffer = StringBuffer();

  String? _built;
  String build() => _built ??= _buffer.toString();

  JsBuilder();

  void write(String item) {
    _buffer.write(item);
  }

  void writeLine(String item) {
    _buffer.writeln(item);
  }

  void writeAll(Iterable<String> items, [String separator = '']) {
    _buffer.writeAll(items, separator);
  }

  void _writeIndent() {
    writeAll([for (var i = 0; i < _indent * 2; i++) ' '], '');
  }

  void writeWithIndent(String item) {
    _writeIndent();
    write(item);
  }

  void writeLineWithIndent(String line) {
    _writeIndent();
    writeLine(line);
  }

  void writeMultiLineExpression(Iterable<String> lines) {
    var i = 0;
    for (final line in lines) {
      if (i == 0) {
        writeLine(line);
      } else if (i < lines.length - 1) {
        writeLineWithIndent(line);
      } else {
        writeWithIndent(line);
      }
      i++;
    }
  }

  void increaseIndent() {
    _indent++;
  }

  void decreaseIndent() {
    if (_indent != 0) _indent--;
  }

  /// Call the expression built by [build] with [args].
  ///
  /// $function($args);
  void writeCallExpression(Iterable<String> args, void Function() build) {
    build();
    write('(');
    writeAll(args, ', ');
    write(')');
  }

  /// Wrap the expression built by [build] in try/catch block.
  ///
  /// try {
  ///   $expression;
  /// } catch (error) {
  ///   error.name + ": " + error.message;
  /// };
  void writeTryCatchExpression(void Function() build) {
    writeLineWithIndent('try {');

    increaseIndent();
    writeWithIndent('');
    build();
    writeLine('');
    decreaseIndent();

    writeLineWithIndent('} catch (error) {');
    writeLineWithIndent('  error.name + ": " + error.message;');
    writeWithIndent('}');
  }

  ///  Wrap the statement built by [build] in try/catch block.
  ///
  /// try {
  ///   $statement
  /// } catch (error) {
  ///   return error.name + ": " + error.message;
  /// };
  void writeTryCatchStatement(void Function() build) {
    writeLineWithIndent('try {');

    increaseIndent();
    build();
    writeLine('');
    decreaseIndent();

    writeLineWithIndent('} catch (error) {');
    writeLineWithIndent('  return error.name + ": " + error.message;');
    writeWithIndent('}');
  }

  /// Return the expression built by [build].
  ///
  /// return $expression;
  void writeReturnStatement(void Function() build) {
    writeWithIndent('return ');
    build();
    write(';');
  }

  /// Define a function with [params] and body built by [build].
  ///
  /// function($args) {
  ///   $body
  /// };
  void writeFunctionDefinition(Iterable<String> params, void Function() build) {
    write('function (');
    writeAll(params, ', ');
    writeLine(') {');

    increaseIndent();
    build();
    writeLine('');
    decreaseIndent();

    writeWithIndent('}');
  }

  /// Bind the function built by [build] to [to].
  ///
  /// $function.bind($to)
  void writeBindExpression(String to, void Function() build) {
    build();
    write('.bind(');
    write(to);
    write(')');
  }

  /// Create a wrapper expression to evaluate the [body].
  ///
  /// Can be used in `Debugger.evaluateOnCallFrame` Chrome API.
  ///
  /// try {
  ///   $expression;
  /// } catch (error) {
  ///   error.name + ": " + error.message;
  /// }
  static String createEvalExpression(Iterable<String> body) =>
      (JsBuilder().._writeEvalExpression(body)).build();

  void _writeEvalExpression(Iterable<String> body) {
    writeTryCatchExpression(() {
      writeMultiLineExpression(body);
      write(';');
    });
  }

  /// Create a wrapper function with [params] that calls a static [function].
  ///
  /// Can be used in `Runtime.callFunctionOn` Chrome API.
  ///
  /// function ($params) {
  ///   try {
  ///     return $function($params);
  ///   } catch (error) {
  ///     return error.name + ": " + error.message;
  ///   }
  /// }
  static String createEvalStaticFunction(
    Iterable<String> function,
    Iterable<String> params,
  ) => (JsBuilder().._writeEvalStaticFunction(function, params)).build();

  void _writeEvalStaticFunction(
    Iterable<String> function,
    Iterable<String> params,
  ) {
    writeFunctionDefinition(
      params,
      () => writeTryCatchStatement(
        () => writeReturnStatement(
          () => writeCallExpression(params, () {
            writeMultiLineExpression(function);
          }),
        ),
      ),
    );
  }

  /// Create a wrapper function with [params] that calls a bound [function].
  ///
  /// Can be used in `Runtime.callFunctionOn` Chrome API.
  /// function ($params, __t$this) {
  ///   try {
  ///     return function ($params) {
  ///       return $function($params);
  ///     }.bind(__t$this)($params);
  ///   } catch (error) {
  ///     return error.name + ": " + error.message;
  ///   }
  /// }
  static String createEvalBoundFunction(
    Iterable<String> function,
    Iterable<String> params,
  ) => (JsBuilder().._writeEvalBoundFunction(function, params)).build();

  void _writeEvalBoundFunction(
    Iterable<String> function,
    Iterable<String> params,
  ) {
    final original = 'this';
    final substitute = '__t\$this';

    final args = params.where((e) => e != original);
    final substitutedParams = [
      ...params.where((e) => e != original),
      substitute,
    ];

    writeFunctionDefinition(
      substitutedParams,
      () => writeTryCatchStatement(
        () => writeReturnStatement(
          () => writeCallExpression(
            args,
            () => writeBindExpression(
              substitute,
              () => writeFunctionDefinition(
                args,
                () => writeReturnStatement(
                  () => writeCallExpression(args, () {
                    writeMultiLineExpression(function);
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
