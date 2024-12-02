// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditableArgumentsTest);
  });
}

@reflectiveTest
class EditableArgumentsTest extends AbstractLspAnalysisServerTest {
  late TestCode code;

  /// Initializes the server with [content] and fetches editable arguments.
  Future<EditableArguments?> getEditableArgumentsFor(
    String content, {
    bool open = true,
  }) async {
    code = TestCode.parse('''
import 'package:flutter/widgets.dart';

$content
''');
    newFile(mainFilePath, code.code);
    await initialize();
    if (open) {
      await openFile(mainFileUri, code.code);
    }
    await initialAnalysis;
    return await getEditableArguments(mainFileUri, code.position.position);
  }

  Matcher hasArg(Matcher matcher) {
    return hasArgs(contains(matcher));
  }

  Matcher hasArgNamed(String argumentName) {
    return hasArg(isArg(argumentName));
  }

  Matcher hasArgs(Matcher matcher) {
    return isA<EditableArguments>().having(
      (arguments) => arguments.arguments,
      'arguments',
      matcher,
    );
  }

  Matcher isArg(
    String name, {
    Object? type = anything,
    Object? value = anything,
    Object? displayValue = anything,
    Object? hasArgument = anything,
    Object? isDefault = anything,
    Object? isRequired = anything,
    Object? isNullable = anything,
    Object? isEditable = anything,
    Object? notEditableReason = anything,
    Object? options = anything,
  }) {
    return isA<EditableArgument>()
        .having((arg) => arg.name, 'name', name)
        .having((arg) => arg.type, 'type', type)
        .having((arg) => arg.value, 'value', value)
        .having((arg) => arg.displayValue, 'displayValue', displayValue)
        .having((arg) => arg.hasArgument, 'hasArgument', hasArgument)
        .having((arg) => arg.isDefault, 'isDefault', isDefault)
        .having((arg) => arg.isRequired, 'isRequired', isRequired)
        .having((arg) => arg.isNullable, 'isNullable', isNullable)
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
          (arg) =>
              arg.type == 'enum'
                  ? (arg.options?.isNotEmpty ?? false)
                  : arg.options == null,
          'enum types must have options / non-enums must not have options',
          isTrue,
        );
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(flutter: true);
  }

  test_hasArgument() async {
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
        orderedEquals([
          isArg('aPositionalSupplied', hasArgument: true),
          isArg('aNamedSupplied', hasArgument: true),
          isArg('aPositionalNotSupplied', hasArgument: false),
          isArg('aNamedNotSupplied', hasArgument: false),
        ]),
      ),
    );
  }

  test_isEditable_false_positional_optional() async {
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

  test_isEditable_false_positional_required1() async {
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

  test_isEditable_false_positional_required2() async {
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

  test_isEditable_false_string_adjacent() async {
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
          isDefault: false,
          isEditable: false,
          notEditableReason: "Adjacent strings can't be edited",
        ),
      ),
    );
  }

  test_isEditable_false_string_interpolated() async {
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

  test_isEditable_false_string_withNewlines() async {
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

  test_isEditable_true_named() async {
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

  test_isEditable_true_positional_required() async {
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

  test_isEditable_true_string_dollar_escaped() async {
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

  test_isEditable_true_string_dollar_raw() async {
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

  test_isNullable() async {
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

  test_isRequired() async {
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

  test_location_bad_extensionMethod_noWidgetFactory() async {
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

  test_location_bad_functionInvocation() async {
    var result = await getEditableArgumentsFor('''
MyWidget create(String a1) => throw '';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => crea^te('value1');
}
''');
    expect(result, isNull);
  }

  test_location_bad_methodInvocation() async {
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

  test_location_bad_unnamedConstructor_notWidget() async {
    var result = await getEditableArgumentsFor('''
class MyWidget {
  const MyWidget(String a1);

  @override
  MyWidget build(BuildContext context) => MyW^idget('value1');
}
''');
    expect(result, isNull);
  }

  test_location_good_argumentList_argumentName() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a^1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_argumentList_literalValue() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a1: 'val^ue1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_argumentList_nestedInvocation() async {
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

  test_location_good_argumentList_parens_afterOpen() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(^a1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_argumentList_parens_beforeClose() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget(a1: 'value1'^);
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_argumentList_parens_beforeOpen() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget({required String a1 });

  @override
  Widget build(BuildContext context) => MyWidget^(a1: 'value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_extensionMethod_constructorTarget() async {
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

  test_location_good_extensionMethod_thisTarget() async {
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

  test_location_good_extensionMethod_variableTarget() async {
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

  test_location_good_namedConstructor_className() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget.foo('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_namedConstructor_constructorName() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget.foo(String a1);

  @override
  Widget build(BuildContext context) => MyWidget.f^oo('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  test_location_good_unnamedConstructor() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''');
    expect(result, hasArgNamed('a1'));
  }

  /// Arguments should be returned in the order at the call site followed by
  /// by the unspecified parameters.
  test_order() async {
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
          isArg('b1'),
          isArg('a1'),
          isArg('c1'),
          isArg('c2'),
          isArg('a2'),
          isArg('b2'),
        ]),
      ),
    );
  }

  test_textDocument_closedFile() async {
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
          .having((td) => td.uri, 'uri', mainFileUri)
          .having((td) => td.version, 'version', 1),
    );

    // Close the file.
    await closeFile(mainFileUri);

    // Verify new results have null version.
    result = await getEditableArguments(mainFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', mainFileUri)
          .having((td) => td.version, 'version', isNull),
    );
  }

  test_textDocument_unopenedFile() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''', open: false);

    // Verify null version for unopened file.
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', mainFileUri)
          .having((td) => td.version, 'version', null),
    );
  }

  test_textDocument_versions() async {
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
          .having((td) => td.uri, 'uri', mainFileUri)
          .having((td) => td.version, 'version', 1),
    );

    // Update the content to v5.
    await replaceFile(5, mainFileUri, '${code.code}\n// extra comment');

    // Verify new results have version 5.
    result = await getEditableArguments(mainFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<VersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', mainFileUri)
          .having((td) => td.version, 'version', 5),
    );
  }

  test_type_bool() async {
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
          isArg('supplied', type: 'bool', value: false, isDefault: false),
          isArg(
            'suppliedAsDefault',
            type: 'bool',
            value: true,
            isDefault: true,
          ),
          isArg('notSupplied', type: 'bool', value: true, isDefault: true),
        ]),
      ),
    );
  }

  test_type_bool_nonLiterals() async {
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

  test_type_double() async {
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
          isArg('supplied', type: 'double', value: 2.0, isDefault: false),
          isArg(
            'suppliedAsDefault',
            type: 'double',
            value: 1.0,
            isDefault: true,
          ),
          isArg('notSupplied', type: 'double', value: 1.0, isDefault: true),
        ]),
      ),
    );
  }

  test_type_double_intLiterals() async {
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
          isArg('supplied', type: 'double', value: 2, isDefault: false),
          isArg('suppliedAsDefault', type: 'double', value: 1, isDefault: true),
          isArg('notSupplied', type: 'double', value: 1, isDefault: true),
        ]),
      ),
    );
  }

  test_type_double_nonLiterals() async {
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

  test_type_enum() async {
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
            isDefault: false,
            options: optionsMatcher,
          ),
          isArg(
            'suppliedAsDefault',
            type: 'enum',
            value: 'E.one',
            isDefault: true,
            options: optionsMatcher,
          ),
          isArg(
            'notSupplied',
            type: 'enum',
            value: 'E.one',
            isDefault: true,
            options: optionsMatcher,
          ),
        ]),
      ),
    );
  }

  test_type_enum_nonLiterals() async {
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

  test_type_int() async {
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
          isArg('supplied', type: 'int', value: 2, isDefault: false),
          isArg('suppliedAsDefault', type: 'int', value: 1, isDefault: true),
          isArg('notSupplied', type: 'int', value: 1, isDefault: true),
        ]),
      ),
    );
  }

  test_type_int_nonLiterals() async {
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

  test_type_string() async {
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
          isArg('supplied', type: 'string', value: 'b', isDefault: false),
          isArg(
            'suppliedAsDefault',
            type: 'string',
            value: 'a',
            isDefault: true,
          ),
          isArg('notSupplied', type: 'string', value: 'a', isDefault: true),
        ]),
      ),
    );
  }

  test_type_string_nonLiterals() async {
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
