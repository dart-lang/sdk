// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generates 'runtime/tests/vm/dart/many_functions_test.dart'.
// This auto-generated test verifies that compiler and VM are capable of
// handling many functions.

void main(List<String> args) {
  final count = 10000;
  final buffer = StringBuffer();
  buffer.write('''
// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.

''');
  for (var i = 0; i < count; i++) {
    buffer.write(generateFunction(i));
  }

  buffer.write('''
void main() {
   final array = [];
''');
  for (var i = 0; i < count; i++) {
    buffer.write('array.add(f$i());\n');
  }
  buffer.write('''
   print('ran \${array.length} functions');
}
''');

  print(buffer.toString());
}

String generateFunction(int index) {
  return '''
@pragma('vm:never-inline')
String f$index() { return 'function$index'; }
''';
}
