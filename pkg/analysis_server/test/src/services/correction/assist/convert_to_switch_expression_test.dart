// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSwitchExpressionTest);
  });
}

@reflectiveTest
class ConvertToSwitchExpressionTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSwitchExpression;

  Future<void> test_argument_differentFunctions() async {
    await resolveTestCode('''
void f(String s) {
  swit^ch (s) {
    case 'foo':
      print('foo');
    case _:
      g('bar');
  }
}

void g(String s) {}
''');
    await assertNoAssist();
  }

  Future<void> test_argument_sharedBody() async {
    await resolveTestCode('''
enum Color {
  red, blue, white
}

void f(Color color) {
  switch ^(color) {
    case Color.red:
    case Color.blue:
      print(0);
    case Color.white:
      print(1);
  }
}
''');

    await assertHasAssist('''
enum Color {
  red, blue, white
}

void f(Color color) {
  print(switch (color) {
    Color.red || Color.blue => 0,
    Color.white => 1
  });
}
''');
  }

  Future<void> test_argument_switchExpression() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}

void f(Color color) {
  switch ^(color) {
    case Color.red:
      print('red'); // Red.
      break;
    case Color.blue:
      print('blue');
      break;
    // Not green.
    case Color.green:
      throw 'Green is bad';
    case Color.yellow:
      // Yellow is OK.
      print('yellow');
      break;
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, green, yellow
}

void f(Color color) {
  print(switch (color) {
    Color.red => 'red', // Red.
    Color.blue => 'blue',
    // Not green.
    Color.green =>  throw 'Green is bad',
    Color.yellow => /**/
      // Yellow is OK.
      'yellow'
  });
}
''');
  }

  Future<void> test_argument_switchExpression_defaultCase() async {
    await resolveTestCode('''
void f(String s) {
  ^switch (s) {
    case 'foo':
      print('foo');
    case 'bar':
      print('bar');
    default:
      throw 'unrecognized';
  }
}
''');
    await assertHasAssist('''
void f(String s) {
  print(switch (s) {
    'foo' => 'foo',
    'bar' => 'bar',
    _ => throw 'unrecognized'
  });
}
''');
  }

  Future<void> test_argument_switchExpression_noBreaks() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}

void f(Color color) {
  switch ^(color) {
    case Color.red:
      print('red'); // Red.
    case Color.blue:
      print('blue');
    // Not green.
    case Color.green:
      throw 'Green is bad';
    case Color.yellow:
      // Yellow is OK.
      print('yellow');
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, green, yellow
}

void f(Color color) {
  print(switch (color) {
    Color.red => 'red', // Red.
    Color.blue => 'blue',
    // Not green.
    Color.green =>  throw 'Green is bad',
    Color.yellow => /**/
      // Yellow is OK.
      'yellow'
  });
}
''');
  }

  Future<void> test_argument_switchExpression_wildcard() async {
    await resolveTestCode('''
void f(String s) {
  switch ^(s) {
    case 'foo':
      print('foo');
    case 'bar':
      print('bar');
    case _:
      throw 'unrecognized';
  }
}
''');
    await assertHasAssist('''
void f(String s) {
  print(switch (s) {
    'foo' => 'foo',
    'bar' => 'bar',
    _ =>  throw 'unrecognized'
  });
}
''');
  }

  Future<void> test_assignment_compound_different() async {
    await resolveTestCode('''
int f(int x) {
  var value = 0;
  ^switch (x) {
    case 1:
      value = 3;
    case 2:
      value += 5;
    default:
      throw 'unrecognized';
  }
  return value;
}
''');
    await assertNoAssist();
  }

  Future<void> test_assignment_compound_same_addition() async {
    await resolveTestCode('''
int f(int x) {
  var value = 0;
  s^witch (x) {
    case 1:
      value += 3;
    case 2:
      value += 5;
    default:
      throw 'unrecognized';
  }
  return value;
}
''');
    await assertHasAssist('''
int f(int x) {
  var value = 0;
  value += switch (x) {
    1 => 3,
    2 => 5,
    _ => throw 'unrecognized'
  };
  return value;
}
''');
  }

  Future<void> test_assignment_compound_same_nullAware() async {
    await resolveTestCode('''
int f(int x) {
  int? value = null;
  sw^itch (x) {
    case 1:
      value ??= 3;
    case 2:
      value ??= 5;
    default:
      throw 'unrecognized';
  }
  return value;
}
''');
    await assertHasAssist('''
int f(int x) {
  int? value = null;
  value ??= switch (x) {
    1 => 3,
    2 => 5,
    _ => throw 'unrecognized'
  };
  return value;
}
''');
  }

  Future<void> test_assignment_differentVariables() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}

String f(Color color) {
  var name = '';
  var favorite = '';
  swi^tch (color) {
    case Color.red:
      name = 'red';
    case Color.blue:
      favorite = 'blue';
    case Color.green:
      name = 'green';
    case Color.yellow:
      name = 'yellow';
  }
  return name;
}
''');
    await assertNoAssist();
  }

  Future<void> test_assignment_sharedBody() async {
    await resolveTestCode('''
enum Color {
  red, blue, white
}

void f(Color color) {
  int value;
  switch ^(color) {
    case Color.red:
    case Color.blue:
      value = 0;
    case Color.white:
      value = 1;
  }
}
''');

    await assertHasAssist('''
enum Color {
  red, blue, white
}

void f(Color color) {
  int value;
  value = switch (color) {
    Color.red || Color.blue => 0,
    Color.white => 1
  };
}
''');
  }

  Future<void> test_assignment_switchExpression() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}

String f(Color color) {
  var name = '';
  switch ^(color) {
    case Color.red:
      name = 'red';
      break;
    case Color.blue:
      name = 'blue'; // Blue!
      break;
    // Not green.
    case Color.green:
      throw 'Green is bad';
    case Color.yellow:
      // Yellow is OK.
      name = 'yellow';
      break;
  }
  return name;
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, green, yellow
}

String f(Color color) {
  var name = '';
  name = switch (color) {
    Color.red => 'red',
    Color.blue => 'blue', // Blue!
    // Not green.
    Color.green => throw 'Green is bad',
    Color.yellow =>
      // Yellow is OK.
      'yellow'
  };
  return name;
}
''');
  }

  Future<void> test_assignment_switchExpression_defaultCase() async {
    await resolveTestCode('''
String f(String s) {
  var name = '';
  switch ^(s) {
    case 'foo':
      name = 'foo';
    case 'bar':
      name = 'bar';
    default:
      throw 'unrecognized';
  }
  return name;
}
''');
    await assertHasAssist('''
String f(String s) {
  var name = '';
  name = switch (s) {
    'foo' => 'foo',
    'bar' => 'bar',
    _ => throw 'unrecognized'
  };
  return name;
}
''');
  }

  Future<void> test_assignment_switchExpression_noBreaks() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}

String f(Color color) {
  var name = '';
  switch ^(color) {
    case Color.red:
      name = 'red';
    case Color.blue:
      name = 'blue'; // Blue!
    // Not green.
    case Color.green:
      throw 'Green is bad';
    case Color.yellow:
      // Yellow is OK.
      name = 'yellow';
  }
  return name;
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, green, yellow
}

String f(Color color) {
  var name = '';
  name = switch (color) {
    Color.red => 'red',
    Color.blue => 'blue', // Blue!
    // Not green.
    Color.green => throw 'Green is bad',
    Color.yellow =>
      // Yellow is OK.
      'yellow'
  };
  return name;
}
''');
  }

  Future<void> test_assignment_switchExpression_wildCardCase() async {
    await resolveTestCode('''
String f(String s) {
  var name = '';
  switch ^(s) {
    case 'foo':
      name = 'foo';
    case 'bar':
      name = 'bar';
    case _:
      throw 'unrecognized';
  }
  return name;
}
''');
    await assertHasAssist('''
String f(String s) {
  var name = '';
  name = switch (s) {
    'foo' => 'foo',
    'bar' => 'bar',
    _ => throw 'unrecognized'
  };
  return name;
}
''');
  }

  Future<void> test_empty() async {
    await resolveTestCode('''
void f(int x) {
  switch ^(x) {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_return_justDefault_throw() async {
    await resolveTestCode('''
String f(int x) {
  s^witch (x) {
    default:
      throw 'foo';
  }
}
''');
    await assertHasAssist('''
String f(int x) {
  return switch (x) {
    _ => throw 'foo'
  };
}
''');
  }

  Future<void> test_return_justDefault_value() async {
    await resolveTestCode('''
String f(int x) {
  ^switch (x) {
    default:
      return 'foo';
  }
}
''');
    await assertHasAssist('''
String f(int x) {
  return switch (x) {
    _ => 'foo'
  };
}
''');
  }

  Future<void> test_return_multipleStatements() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  ^switch (color) {
    case Color.red:
      print('red');
      return 'red';
    case Color.orange:
      return 'orange';
    case Color.green:
      return 'green';
    case Color.yellow:
      return 'yellow';
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_return_notExhaustive() async {
    await resolveTestCode('''
String f(int i) {
  swi^tch(i) {
    case 1:
      return 'one';
    case 2:
      return 'two';
  }
  return '';
}
''');
    await assertNoAssist();
  }

  Future<void> test_return_sharedBody() async {
    await resolveTestCode('''
enum Color {
  red, blue, white
}

int f(Color color) {
  switch ^(color) {
    case Color.red:
    case Color.blue:
      return 0;
    case Color.white:
      return 1;
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, white
}

int f(Color color) {
  return switch (color) {
    Color.red || Color.blue => 0,
    Color.white => 1
  };
}
''');
  }

  Future<void> test_return_sharedBody_hasWhen() async {
    await resolveTestCode('''
enum Color {
  red, blue, white
}

int f(Color color) {
  switc^h (color) {
    case Color.red when true:
    case Color.blue:
      return 0;
    case Color.white:
      return 1;
    default:
      return 2;
  }
}
''');

    await assertNoAssist();
  }

  Future<void> test_return_switchExpression() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  switch ^(color) {
    case Color.red:
      throw 'red!';
    case Color.orange:
      return 'orange';
    case Color.green:
      throw 'green';
    case Color.yellow:
      return 'yellow';
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  return switch (color) {
    Color.red => throw 'red!',
    Color.orange => 'orange',
    Color.green => throw 'green',
    Color.yellow => 'yellow'
  };
}
''');
  }

  Future<void> test_return_switchExpression_defaultCase() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  switch ^(color) {
    case Color.red:
      throw 'red!';
    case Color.orange:
      return 'orange';
    case Color.green:
      throw 'green';
    default:
      return 'yellow';
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  return switch (color) {
    Color.red => throw 'red!',
    Color.orange => 'orange',
    Color.green => throw 'green',
    _ => 'yellow'
  };
}
''');
  }

  Future<void> test_return_switchExpression_elseThrow() async {
    await resolveTestCode('''
enum Color {
  red, blue, white
}

Color fromName(String name) {
  s^witch (name) {
    case 'red':
      return Color.red;
    case 'blue':
      return Color.blue;
    case 'white':
      return Color.white;
  }
  throw name;
}
''');
    await assertHasAssist('''
enum Color {
  red, blue, white
}

Color fromName(String name) {
  return switch (name) {
    'red' => Color.red,
    'blue' => Color.blue,
    'white' => Color.white,
    _ => throw name,
  };
}
''');
  }

  Future<void> test_return_switchExpression_elseThrow_multiline() async {
    await resolveTestCode('''
enum Color {
  red
}

Color fromName(String name) {
  switc^h (name) {
    case 'red':
      return Color.red;
  }
  throw 'Only'
    ' supports'
    ' red';
}
''');
    await assertHasAssist('''
enum Color {
  red
}

Color fromName(String name) {
  return switch (name) {
    'red' => Color.red,
    _ => throw 'Only'
      ' supports'
      ' red',
  };
}
''');
  }

  Future<void> test_return_switchExpression_wildcard() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  switch ^(color) {
    case Color.red:
      throw 'red!';
    case Color.orange:
      return 'orange';
    case Color.green:
      throw 'green';
    case _:
      return 'yellow';
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  return switch (color) {
    Color.red => throw 'red!',
    Color.orange => 'orange',
    Color.green => throw 'green',
    _ => 'yellow'
  };
}
''');
  }

  Future<void> test_return_switchKeyword() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  sw^itch (color) {
    // Uh-oh.
    case Color.red:
      throw 'red!';
    case Color.orange:
      // Tangerine?
      return 'orange';
    case Color.green:
      // Whoops.
      throw 'green';
    case Color.yellow:
      return 'yellow';
  }
}
''');
    await assertHasAssist('''
enum Color {
  red, orange, yellow, green
}

String name(Color color) {
  return switch (color) {
    // Uh-oh.
    Color.red => throw 'red!',
    Color.orange =>
      // Tangerine?
      'orange',
    Color.green =>
      // Whoops.
      throw 'green',
    Color.yellow => 'yellow'
  };
}
''');
  }
}
