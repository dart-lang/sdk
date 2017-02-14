// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('try catch', () {
    String code = '''
main() {
  try {
    print('hi');
  } catch (e, s) {
    print(e);
    print(s);
    print('bye');
  }
}''';
    return check(code);
  });

  test('try omit catch', () {
    String code = '''
main() {
  try {
    print('hi');
  } on ArgumentError {
    print('howdy');
  }
}''';
    return check(code);
  });

  test('try finally', () {
    String code = '''
main() {
  try {
    print('hi');
  } finally {
    print('bye');
  }
}''';
    return check(code);
  });

  test('try catch finally', () {
    String code = '''
main() {
  try {
    print('hi');
  } catch(e) {
    print('howdy');
  } finally {
    print('bye');
  }
}''';
    return check(code);
  });

  test('try multi catch', () {
    String code = '''
main() {
  try {
    print('hi');
  } on String catch(e) {
    print('hola');
  } on int catch(e) {
    print('halo');
  } catch (e) {
    print('howdy');
  }
}''';
    return check(code);
  });

  test('try multi-catch finally', () {
    String code = '''
main() {
  try {
    print('hi');
  } on String catch(e) {
    print('hola');
  } on int catch(e) {
    print('halo');
  } catch (e) {
    print('howdy');
  } finally {
    print('bye');
  }
}''';
    return check(code);
  });
}
