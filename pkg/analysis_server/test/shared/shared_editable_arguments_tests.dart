// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../../tool/codebase/failing_tests.dart';
import '../lsp/request_helpers_mixin.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared editable arguments tests that are used by both LSP + Legacy server
/// tests.
mixin SharedEditableArgumentsTests
    on SharedTestInterface, LspRequestHelpersMixin {
  late TestCode code;

  /// Initializes the server with [content] and fetches editable arguments.
  Future<EditableArguments?> getEditableArgumentsFor(
    String content, {
    Future<void> Function(Uri, String)? open,
  }) async {
    // Default to the standart openFile function if we weren't overridden.
    open ??= openFile;

    code = TestCode.parse('''
import 'package:flutter/widgets.dart';

$content
''');
    createFile(testFilePath, code.code);
    await initializeServer();
    await open(testFileUri, code.code);
    await currentAnalysis;
    return await getEditableArguments(testFileUri, code.position.position);
  }

  Matcher hasArg(Matcher matcher) {
    return hasArgs(contains(matcher));
  }

  Matcher hasArgNamed(String argumentName, {String? doc}) {
    return hasArg(isArg(argumentName));
  }

  Matcher hasArgs(Matcher matcher) {
    return isA<EditableArguments>().having(
      (arguments) => arguments.arguments,
      'arguments',
      matcher,
    );
  }

  Matcher hasDocumentation(Matcher matcher) {
    return isA<EditableArguments>().having(
      (arguments) => arguments.documentation,
      'documentation',
      matcher,
    );
  }

  Matcher hasName(Matcher matcher) {
    return isA<EditableArguments>().having(
      (arguments) => arguments.name,
      'name',
      matcher,
    );
  }

  Matcher isArg(
    String name, {
    Object? documentation = anything,
    Object? type = anything,
    Object? value = anything,
    Object? displayValue = anything,
    Object? hasArgument = anything,
    Object? defaultValue = anything,
    Object? isRequired = anything,
    Object? isNullable = anything,
    Object? isDeprecated = anything,
    Object? isEditable = anything,
    Object? notEditableReason = anything,
    Object? options = anything,
  }) {
    return isA<EditableArgument>()
        .having((arg) => arg.name, 'name', name)
        .having((arg) => arg.documentation, 'documentation', documentation)
        .having((arg) => arg.type, 'type', type)
        .having((arg) => arg.value, 'value', value)
        .having((arg) => arg.displayValue, 'displayValue', displayValue)
        .having((arg) => arg.hasArgument, 'hasArgument', hasArgument)
        .having((arg) => arg.defaultValue, 'defaultValue', defaultValue)
        .having((arg) => arg.isRequired, 'isRequired', isRequired)
        .having((arg) => arg.isNullable, 'isNullable', isNullable)
        .having((arg) => arg.isDeprecated, 'isDeprecated', isDeprecated)
        .having((arg) => arg.isEditable, 'isEditable', isEditable)
        .having(
          (arg) => arg.notEditableReason,
          'notEditableReason',
          notEditableReason,
        )
        .having((arg) => arg.options, 'options', options)
        // Some extra checks that should be true for all.
        .having(
          (arg) =>
              arg.value == null ||
              arg.value?.toString() != arg.displayValue?.toString(),
          'different value and displayValues',
          isTrue,
        )
        .having(
          (arg) => (arg.notEditableReason == null) == arg.isEditable,
          'notEditableReason must be supplied if isEditable=false',
          isTrue,
        )
        .having(
          (arg) => arg.value == null || arg.isEditable,
          'isEditable must be true if there is a value',
          isTrue,
        )
        .having(
          (arg) => arg.type == 'enum'
              ? (arg.options?.isNotEmpty ?? false)
              : arg.options == null,
          'enum types must have options / non-enums must not have options',
          isTrue,
        );
  }

  Future<void> test_defaultValue_named_default() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({int? a = 1});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: 1)));
  }

  Future<void> test_defaultValue_named_default_constantVariable() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  static const constantOne = 1;

  const MyWidget({int? a = constantOne});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: 1)));
  }

  Future<void> test_defaultValue_named_default_null() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({int? a = null});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: null)));
  }

  Future<void> test_defaultValue_named_noDefault() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({int? a});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: null)));
  }

  Future<void> test_defaultValue_named_required_noDefault() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({required int? a});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: null)));
  }

  Future<void> test_defaultValue_positional() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(int a);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: null)));
  }

  Future<void> test_defaultValue_positional_optional_default() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget([int? a = 1]);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: 1)));
  }

  Future<void> test_defaultValue_positional_optional_noDefault() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget([int? a]);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasArg(isArg('a', defaultValue: null)));
  }

  Future<void> test_documentation_fieldParameter_literal() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  /// Documentation for x.
  final int x;

  /// Creates a MyWidget.
  const MyWidget(this.x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasArg(isArg('x', documentation: 'Documentation for x.')));
  }

  Future<void> test_documentation_fieldParameter_macro() async {
    var result = await getEditableArgumentsFor('''
/// {@template shared_docs}
/// Shared docs.
/// {@endtemplate}
class MyWidget extends StatelessWidget {
  /// {@macro shared_docs}
  final int x;

  /// Creates a MyWidget.
  const MyWidget(this.x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasArg(isArg('x', documentation: 'Shared docs.')));
  }

  Future<void> test_documentation_literal() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  /// Creates a MyWidget.
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasDocumentation(equals('Creates a MyWidget.')));
  }

  Future<void> test_documentation_macro() async {
    var result = await getEditableArgumentsFor('''
/// {@template my_widget_docs}
/// MyWidget shared docs.
/// {@endtemplate}
class MyWidget extends StatelessWidget {
  /// {@macro my_widget_docs}
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasDocumentation(equals('MyWidget shared docs.')));
  }

  Future<void> test_documentation_missing() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasDocumentation(isNull));
  }

  Future<void> test_documentation_widgetFactory() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  /// Creates a Padded.
  @widgetFactory
  Widget padded(int x) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) {
    return padd^ed(1);
  }
}
''');
    expect(result, hasDocumentation(equals('Creates a Padded.')));
  }

  Future<void> test_hasArgument() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(
    int? aPositionalSupplied,
    int? aPositionalNotSupplied, {
    int? aNamedSupplied,
    int? aNamedNotSupplied,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(1, aNamedSupplied: 1);
}
''');
    expect(
      result,
      hasArgs(
        unorderedEquals([
          isArg('aPositionalSupplied', hasArgument: true),
          isArg('aPositionalNotSupplied', hasArgument: false),
          isArg('aNamedSupplied', hasArgument: true),
          isArg('aNamedNotSupplied', hasArgument: false),
        ]),
      ),
    );
  }

  Future<void> test_isDeprecated() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  /// Creates a MyWidget.
  const MyWidget(
    @deprecated
    int aDeprecated,
    int aNotDeprecated,
  );

  @override
  Widget build(BuildContext context) => MyW^idget(1, 2);
}
''');
    expect(
      result,
      hasArgs(
        unorderedEquals([
          isArg('aDeprecated', isDeprecated: true),
          isArg('aNotDeprecated', isDeprecated: false),
        ]),
      ),
    );
  }

  Future<void> test_isEditable_false_positional_optional() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget([int? a, int? b, int? c]);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('a', isEditable: true),
          isArg('b', isEditable: true),
          isArg(
            'c',
            // c is not editable because it is not guaranteed that we can insert
            // a default value for b (it could be a private value or require
            // imports).
            isEditable: false,
            notEditableReason:
                "A value for the 3rd parameter can't be added until a value "
                'for all preceding positional parameters have been added.',
          ),
        ]),
      ),
    );
  }

  Future<void> test_isEditable_false_positional_required1() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(int a, int b);

  @override
  Widget build(BuildContext context) => MyW^idget();
}
''');
    expect(
      result,
      hasArg(
        // b is not editable because there are missing required previous
        // arguments (a).
        isArg(
          'b',
          isEditable: false,
          notEditableReason:
              "A value for the 2nd parameter can't be added until a value "
              'for all preceding positional parameters have been added.',
        ),
      ),
    );
  }

  Future<void> test_isEditable_false_positional_required2() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(int a, int b, int c);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(
      result,
      hasArg(
        // c is not editable because there are missing required previous
        // arguments (b).
        isArg(
          'c',
          isEditable: false,
          notEditableReason:
              "A value for the 3rd parameter can't be added until a value "
              'for all preceding positional parameters have been added.',
        ),
      ),
    );
  }

  Future<void> test_isEditable_false_string_adjacent() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String s);

  @override
  Widget build(BuildContext context) => MyW^idget('a' 'b');
}
''');
    expect(
      result,
      hasArg(
        isArg(
          's',
          type: 'string',
          value: isNull,
          displayValue: 'ab',
          hasArgument: true,
          isEditable: false,
          notEditableReason: "Adjacent strings can't be edited",
        ),
      ),
    );
  }

  Future<void> test_isEditable_false_string_interpolated() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String s);

  @override
  Widget build(BuildContext context) => MyW^idget('${context.runtimeType}');
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            's',
            type: 'string',
            value: isNull,
            displayValue: r"'${context.runtimeType}'",
            isEditable: false,
            notEditableReason: "Interpolated strings can't be edited",
          ),
        ]),
      ),
    );
  }

  Future<void> test_isEditable_false_string_withNewlines() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String sEscaped, String sLiteral);

  @override
  Widget build(BuildContext context) => MyW^idget(
    'a\nb',
    """
a
b
""",
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'sEscaped',
            type: 'string',
            value: isNull,
            displayValue: 'a\nb',
            isEditable: false,
            notEditableReason: "Strings containing newlines can't be edited",
          ),
          isArg(
            'sLiteral',
            type: 'string',
            value: isNull,
            displayValue: 'a\nb\n',
            isEditable: false,
            notEditableReason: "Strings containing newlines can't be edited",
          ),
        ]),
      ),
    );
  }

  Future<void> test_isEditable_true_named() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({int? a, int? b, int? c});

  @override
  Widget build(BuildContext context) => MyW^idget(a: 1);
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('a', isEditable: true),
          isArg('b', isEditable: true),
          isArg('c', isEditable: true),
        ]),
      ),
    );
  }

  Future<void> test_isEditable_true_positional_required() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(int a, int b);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(
      result,
      hasArg(
        isArg(
          'b',
          // b is editable because it's the next argument and we don't need
          // to add anything additional.
          isEditable: true,
        ),
      ),
    );
  }

  Future<void> test_isEditable_true_string_dollar_escaped() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String s);

  @override
  Widget build(BuildContext context) => MyW^idget('\${1}');
}
''');
    expect(
      result,
      hasArg(
        isArg(
          's',
          type: 'string',
          value: r'${1}',
          displayValue: isNull,
          isEditable: true,
        ),
      ),
    );
  }

  Future<void> test_isEditable_true_string_dollar_raw() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String s);

  @override
  Widget build(BuildContext context) => MyW^idget(r'${1}');
}
''');
    expect(
      result,
      hasArg(
        isArg(
          's',
          type: 'string',
          value: r'${1}',
          displayValue: isNull,
          isEditable: true,
        ),
      ),
    );
  }

  Future<void>
  test_isEditable_true_string_tripleQuoted_withoutNewlines() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget(String s);

  @override
  Widget build(BuildContext context) => MyW^idget("""string_value""");
}
''');
    expect(
      result,
      hasArg(
        isArg(
          's',
          type: 'string',
          value: 'string_value',
          displayValue: isNull,
          isEditable: true,
        ),
      ),
    );
  }

  Future<void> test_isNullable() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(
    int aPositional,
    int? aPositionalNullable, {
    int? aNamed,
    required int aRequiredNamed,
    required int? aRequiredNamedNullable
  });

  @override
  Widget build(BuildContext context) => MyW^idget();
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aPositional', isNullable: false),
          isArg('aPositionalNullable', isNullable: true),
          isArg('aNamed', isNullable: true),
          isArg('aRequiredNamed', isNullable: false),
          isArg('aRequiredNamedNullable', isNullable: true),
        ]),
      ),
    );
  }

  Future<void> test_isRequired() async {
    failTestOnErrorDiagnostic = false;
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(
    int aPositional,
    int? aPositionalNullable, {
    int? aNamed,
    required int aRequiredNamed,
    required int? aRequiredNamedNullable
  });

  @override
  Widget build(BuildContext context) => MyW^idget();
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aPositional', isRequired: true),
          isArg('aPositionalNullable', isRequired: true),
          isArg('aNamed', isRequired: false),
          isArg('aRequiredNamed', isRequired: true),
          isArg('aRequiredNamedNullable', isRequired: true),
        ]),
      ),
    );
  }

  Future<void> test_location_bad_extensionMethod_noWidgetFactory() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  Widget padded(String a1) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget();
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => this.pad^ded('value1');
}
''');
    expect(result, isNull);
  }

  Future<void> test_location_bad_functionInvocation() async {
    var result = await getEditableArgumentsFor('''
MyWidget create(String a1) => throw '';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => crea^te('value1');
}
''');
    expect(result, isNull);
  }

  Future<void> test_location_bad_methodInvocation() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  @widgetFactory
  MyWidget create(String a1) => throw '';

  @override
  Widget build(BuildContext context) => crea^te('value1');
}
''');
    expect(result, isNull);
  }

  Future<void> test_location_bad_nonDart() async {
    var textFilePath = pathContext.join(projectFolderPath, 'lib', 'test.txt');
    var textFileUri = Uri.file(textFilePath);

    var content = 'my text';
    createFile(textFilePath, content);
    await initializeServer();
    await openFile(textFileUri, content);
    await currentAnalysis;
    var result = await getEditableArguments(
      textFileUri,
      Position(line: 0, character: 0),
    );

    expect(result, isNull);
  }

  Future<void> test_location_bad_unnamedConstructor_notWidget() async {
    var result = await getEditableArgumentsFor('''
class MyWidget {
  const MyWidget(String a1);

  @override
  MyWidget build(BuildContext context) => MyW^idget('value1');
}
''');
    expect(result, isNull);
  }

  Future<void> test_location_good_argumentList_argumentName() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a^1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_argumentList_literalValue() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a1: 'val^ue1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_argumentList_nestedInvocation() async {
    var result = await getEditableArgumentsFor('''
String getString() => '';

class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyWidget(getS^tring());
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void>
  test_location_good_argumentList_nestedInvocation_arguments() async {
    var result = await getEditableArgumentsFor('''
String getString(String s) => s;

class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyWidget(getString('valu^e1'));
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_argumentList_parens_afterOpen() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(^a1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_argumentList_parens_beforeClose() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a1: 'value1'^);
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_argumentList_parens_beforeOpen() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget^(a1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_extensionMethod_constructorTarget() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  @widgetFactory
  Widget padded(String a1) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget();
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => MyWidget().pad^ded('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_extensionMethod_thisTarget() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  @widgetFactory
  Widget padded(String a1) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => this.pad^ded('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_extensionMethod_variableTarget() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  @widgetFactory
  Widget padded(String a1) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget();
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) {
    MyWidget? foo;
    return foo!.pad^ded('value1');
  }
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_namedConstructor_className() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget.foo('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_namedConstructor_constructorName() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => MyWidget.f^oo('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_location_good_unnamedConstructor() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  Future<void> test_name_widgetConstructor() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) => MyW^idget(1);
}
''');
    expect(result, hasName(equals('MyWidget')));
  }

  Future<void> test_name_widgetConstructor_named() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget.named(int x);

  @override
  Widget build(BuildContext context) => MyW^idget.named(1);
}
''');
    expect(result, hasName(equals('MyWidget')));
  }

  Future<void> test_name_widgetFactory() async {
    var result = await getEditableArgumentsFor('''
extension on MyWidget {
  @widgetFactory
  Widget padded(int x) => this;
}

class MyWidget extends StatelessWidget {
  const MyWidget(int x);

  @override
  Widget build(BuildContext context) {
    return padd^ed(1);
  }
}
''');
    expect(result, hasName(isNull));
  }

  /// Arguments should be returned in the order of the parameters in the source
  /// code. This keeps things consistent across different instances of the same
  /// Widget class and prevents the order from changing as a user adds/removes
  /// arguments.
  ///
  /// If an editor wants to sort provided arguments first (and keep these stable
  /// across add/removes) it could still do so client-side, whereas if server
  /// orders them that way, the opposite (using source-order) is not possible.
  Future<void> test_order() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    int c1 = 0,
    int c2 = 0,
    int a1 = 0,
    int a2 = 0,
    int b1 = 0,
    int b2 = 0,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(b1: 1, a1: 1, c1: 1);
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('c1'),
          isArg('c2'),
          isArg('a1'),
          isArg('a2'),
          isArg('b1'),
          isArg('b2'),
        ]),
      ),
    );
  }

  Future<void> test_range() async {
    var result = await getEditableArgumentsFor(r'''
class MyWidget extends StatelessWidget {
  const MyWidget({int? a = null});

  @override
  Widget build(BuildContext context) => [!MyW^idget(a: 1)!];
}
''');
    expect(result!.range, code.range.range);
  }

  Future<void> test_textDocument_unopenedFile() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''', open: (_, _) async {});

    // Verify null version for unopened file.
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', null),
    );
  }

  Future<void> test_textDocument_versioned() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''');

    // Verify initial content of 1.
    expect(
      result!.textDocument,
      isA<VersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', 1),
    );

    // Update the content to v5.
    await replaceFile(5, testFileUri, '${code.code}\n// extra comment');

    // Verify new results have version 5.
    result = await getEditableArguments(testFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<VersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', 5),
    );
  }

  Future<void> test_textDocument_versioned_closedFile() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''');

    // Verify initial content of 1.
    expect(
      result!.textDocument,
      isA<VersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', 1),
    );

    // Close the file.
    await closeFile(testFileUri);

    // Verify new results have null version.
    result = await getEditableArguments(testFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', isNull),
    );
  }

  Future<void> test_type_bool() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    bool supplied = true,
    bool suppliedAsDefault = true,
    bool notSupplied = true,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: false,
    suppliedAsDefault: true,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'bool',
            value: false,
            hasArgument: true,
            defaultValue: true,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'bool',
            value: true,
            hasArgument: true,
            defaultValue: true,
          ),
          isArg(
            'notSupplied',
            type: 'bool',
            value: isNull,
            hasArgument: false,
            defaultValue: true,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_bool_nonLiterals() async {
    var result = await getEditableArgumentsFor('''
var myVar = true;
const myConst = true;
class MyWidget extends StatelessWidget {
  const MyWidget({
    bool? aVar,
    bool? aConst,
    bool? aExpr,
    bool? aConstExpr,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    aVar: myVar,
    aConst: myConst,
    aExpr: DateTime.now().isBefore(DateTime.now()),
    aConstExpr: 1 == 2,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aVar', type: 'bool', value: isNull, displayValue: 'myVar'),
          isArg('aConst', type: 'bool', value: true, displayValue: 'myConst'),
          isArg(
            'aExpr',
            type: 'bool',
            value: isNull,
            displayValue: 'DateTime.now().isBefore(DateTime.now())',
          ),
          isArg(
            'aConstExpr',
            type: 'bool',
            value: false,
            displayValue: '1 == 2',
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_double() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    double supplied = 1.0,
    double suppliedAsDefault = 1.0,
    double notSupplied = 1.0,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: 2.0,
    suppliedAsDefault: 1.0,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'double',
            value: 2.0,
            hasArgument: true,
            defaultValue: 1.0,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'double',
            value: 1.0,
            hasArgument: true,
            defaultValue: 1.0,
          ),
          isArg(
            'notSupplied',
            type: 'double',
            value: isNull,
            hasArgument: false,
            defaultValue: 1.0,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_double_intLiterals() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    double supplied = 1,
    double suppliedAsDefault = 1,
    double notSupplied = 1,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: 2,
    suppliedAsDefault: 1,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'double',
            value: 2,
            hasArgument: true,
            defaultValue: 1,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'double',
            value: 1,
            hasArgument: true,
            defaultValue: 1,
          ),
          isArg(
            'notSupplied',
            type: 'double',
            value: isNull,
            hasArgument: false,
            defaultValue: 1,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_double_nonLiterals() async {
    var result = await getEditableArgumentsFor('''
var myVar = 1.0;
const myConst = 1.0;
class MyWidget extends StatelessWidget {
  const MyWidget({
    double? aVar,
    double? aConst,
    double? aExpr,
    double? aConstExpr,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    aVar: myVar,
    aConst: myConst,
    aExpr: DateTime.now().millisecondsSinceEpoch.toDouble(),
    aConstExpr: 1.0 + myConst,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aVar', type: 'double', value: isNull, displayValue: 'myVar'),
          isArg('aConst', type: 'double', value: 1.0, displayValue: 'myConst'),
          isArg(
            'aExpr',
            type: 'double',
            value: isNull,
            displayValue: 'DateTime.now().millisecondsSinceEpoch.toDouble()',
          ),
          isArg(
            'aConstExpr',
            type: 'double',
            value: 2.0,
            displayValue: '1.0 + myConst',
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_enum() async {
    var result = await getEditableArgumentsFor('''
enum E { one, two }
class MyWidget extends StatelessWidget {
  const MyWidget({
    E supplied = E.one,
    E suppliedAsDefault = E.one,
    E notSupplied = E.one,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: E.two,
    suppliedAsDefault: E.one,
  );
}
''');

    var optionsMatcher = equals(['E.one', 'E.two']);
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'enum',
            value: 'E.two',
            hasArgument: true,
            defaultValue: 'E.one',
            options: optionsMatcher,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'enum',
            value: 'E.one',
            hasArgument: true,
            defaultValue: 'E.one',
            options: optionsMatcher,
          ),
          isArg(
            'notSupplied',
            type: 'enum',
            value: isNull,
            hasArgument: false,
            defaultValue: 'E.one',
            options: optionsMatcher,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_enum_nonLiterals() async {
    var result = await getEditableArgumentsFor('''
enum E { one, two }
var myVar = E.one;
const myConst = E.one;
class MyWidget extends StatelessWidget {
  const MyWidget({
    E? aVar,
    E? aConst,
    E? aExpr,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    aVar: myVar,
    aConst: myConst,
    aExpr: E.values.first,
  );
}
''');

    var optionsMatcher = equals(['E.one', 'E.two']);
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'aVar',
            type: 'enum',
            value: isNull,
            displayValue: 'myVar',
            options: optionsMatcher,
          ),
          isArg(
            'aConst',
            type: 'enum',
            value: 'E.one',
            displayValue: 'myConst',
            options: optionsMatcher,
          ),
          isArg(
            'aExpr',
            type: 'enum',
            value: isNull,
            displayValue: 'E.values.first',
            options: optionsMatcher,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_int() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    int supplied = 1,
    int suppliedAsDefault = 1,
    int notSupplied = 1,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: 2,
    suppliedAsDefault: 1,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'int',
            value: 2,
            hasArgument: true,
            defaultValue: 1,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'int',
            value: 1,
            hasArgument: true,
            defaultValue: 1,
          ),
          isArg(
            'notSupplied',
            type: 'int',
            value: isNull,
            hasArgument: false,
            defaultValue: 1,
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_int_nonLiterals() async {
    var result = await getEditableArgumentsFor('''
var myVar = 1;
const myConst = 1;
class MyWidget extends StatelessWidget {
  const MyWidget({
    int? aVar,
    int? aConst,
    int? aExpr,
    int? aConstExpr,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    aVar: myVar,
    aConst: myConst,
    aExpr: DateTime.now().millisecondsSinceEpoch,
    aConstExpr: 1 + myConst,
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aVar', type: 'int', value: isNull, displayValue: 'myVar'),
          isArg('aConst', type: 'int', value: 1, displayValue: 'myConst'),
          isArg(
            'aExpr',
            type: 'int',
            value: isNull,
            displayValue: 'DateTime.now().millisecondsSinceEpoch',
          ),
          isArg(
            'aConstExpr',
            type: 'int',
            value: 2,
            displayValue: '1 + myConst',
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_string() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({
    String supplied = 'a',
    String suppliedAsDefault = 'a',
    String notSupplied = 'a',
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    supplied: 'b',
    suppliedAsDefault: 'a',
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg(
            'supplied',
            type: 'string',
            value: 'b',
            hasArgument: true,
            defaultValue: 'a',
          ),
          isArg(
            'suppliedAsDefault',
            type: 'string',
            value: 'a',
            hasArgument: true,
            defaultValue: 'a',
          ),
          isArg(
            'notSupplied',
            type: 'string',
            value: isNull,
            hasArgument: false,
            defaultValue: 'a',
          ),
        ]),
      ),
    );
  }

  Future<void> test_type_string_nonLiterals() async {
    var result = await getEditableArgumentsFor('''
var myVar = 'a';
const myConst = 'a';
class MyWidget extends StatelessWidget {
  const MyWidget({
    String? aVar,
    String? aConst,
    String? aExpr,
    String? aConstExpr,
  });

  @override
  Widget build(BuildContext context) => MyW^idget(
    aVar: myVar,
    aConst: myConst,
    aExpr: DateTime.now().toString(),
    aConstExpr: 'a' + 'b',
  );
}
''');
    expect(
      result,
      hasArgs(
        orderedEquals([
          isArg('aVar', type: 'string', value: isNull, displayValue: 'myVar'),
          isArg('aConst', type: 'string', value: 'a', displayValue: 'myConst'),
          isArg(
            'aExpr',
            type: 'string',
            value: isNull,
            displayValue: 'DateTime.now().toString()',
          ),
          isArg(
            'aConstExpr',
            type: 'string',
            value: 'ab',
            displayValue: "'a' + 'b'",
          ),
        ]),
      ),
    );
  }
}
