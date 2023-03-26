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
  AssistKind get kind => DartAssistKind.CONVERT_TO_SWITCH_EXPRESSION;

  Future<void> test_argument_switchExpression() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}
    
void f(Color color) {
  switch (color) {
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
    await assertHasAssistAt('(color)', '''
enum Color {
  red, blue, green, yellow
}
    
void f(Color color) {
  print(switch (color) {
    Color.red => 'red', // Red.
    Color.blue => 'blue',
    // Not green.
    Color.green => throw 'Green is bad',
    Color.yellow => 
      // Yellow is OK.
      'yellow'
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
  switch (color) {
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
    await assertHasAssistAt('(color)', '''
enum Color {
  red, blue, green, yellow
}
    
void f(Color color) {
  print(switch (color) {
    Color.red => 'red', // Red.
    Color.blue => 'blue',
    // Not green.
    Color.green => throw 'Green is bad',
    Color.yellow => 
      // Yellow is OK.
      'yellow'
  });
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
  switch (color) {
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
    await assertHasAssistAt('(color)', '''
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

  Future<void> test_assignment_switchExpression_noBreaks() async {
    await resolveTestCode('''
enum Color {
  red, blue, green, yellow
}
    
String f(Color color) {
  var name = '';
  switch (color) {
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
    await assertHasAssistAt('(color)', '''
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

  Future<void> test_return_notExhaustive_noAssist() async {
    await resolveTestCode('''
String f(int i) {
  switch(i) {
    case 1:
      return 'one';
    case 2:
      return 'two';
  }
  return '';
}
''');

    await assertNoAssistAt('switch');
  }

  Future<void> test_return_switchExpression() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}
    
String name(Color color) {
  switch (color) {
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
    await assertHasAssistAt('(color)', '''
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

  Future<void> test_return_switchKeyword() async {
    await resolveTestCode('''
enum Color {
  red, orange, yellow, green
}
    
String name(Color color) {
  switch (color) {
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
    await assertHasAssistAt('switch', '''
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
