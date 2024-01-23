// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ---- String.substring

/*member: substring1:Specializer=[substring]*/
@pragma('dart2js:noInline')
substring1(String param) {
  return param.substring(1);
}

/*member: substring2:Specializer=[substring]*/
@pragma('dart2js:noInline')
substring2(String param) {
  return param.substring(1, 3);
}

/*member: substring3:Specializer=[substring]*/
@pragma('dart2js:noInline')
substring3(String param) {
  dynamic s = param;
  return s.substring(1, 2); // Not confused by static type.
}

/*member: substring4:*/
@pragma('dart2js:noInline')
substring4(String param) {
  dynamic s = param;
  return s.substring(1, 2, 3); // Arity mismatch.
}

/*member: substring5:*/
@pragma('dart2js:noInline')
substring5(String param) {
  dynamic s = [param];
  return s.substring(1); // Receiver mismatch.
}

// ---- String.trim

/*member: trim1:Specializer=[trim]*/
@pragma('dart2js:noInline')
trim1(String param) {
  return param.trim();
}

// ---- String.indexOf

/*member: indexOf1:Specializer=[indexOf]*/
@pragma('dart2js:noInline')
indexOf1(String param) {
  return param.indexOf('e');
}

/*member: indexOf2:Specializer=[indexOf]*/
@pragma('dart2js:noInline')
indexOf2(String param) {
  return param.indexOf('e', 3);
}

// Specializer does not match as the pattern is not a string.
/*member: indexOf3:*/
@pragma('dart2js:noInline')
indexOf3(String param) {
  return param.indexOf(RegExp('e'));
}

// ---- String.contains

/*member: contains1:Specializer=[contains]*/
@pragma('dart2js:noInline')
contains1(String param) {
  return param.contains('e');
}

/*member: contains2:Specializer=[contains]*/
@pragma('dart2js:noInline')
contains2(String param) {
  return param.contains('e', 3);
}

// Specializer does not match as the pattern is not a string.
/*member: contains3:*/
@pragma('dart2js:noInline')
contains3(String param) {
  return param.contains(RegExp('e'));
}

// ---- String.startsWith

/*member: startsWith1:Specializer=[startsWith]*/
@pragma('dart2js:noInline')
startsWith1(String param) {
  return param.startsWith('e');
}

/*member: startsWith2:Specializer=[startsWith]*/
@pragma('dart2js:noInline')
startsWith2(String param) {
  return param.startsWith('e', 3);
}

// Specializer does not match as the pattern is not a string.
/*member: startsWith3:*/
@pragma('dart2js:noInline')
startsWith3(String param) {
  return param.startsWith(RegExp('e'));
}

// ---- String.endsWith

/*member: endsWith1:Specializer=[endsWith]*/
@pragma('dart2js:noInline')
endsWith1(String param) {
  return param.endsWith('e');
}

main() {
  substring1('hello');
  substring1('bye');
  substring1('');
  substring2('hello');
  substring2('bye');
  substring2('');
  substring3('hello');
  substring3('bye');
  substring3('');
  substring4('hello');
  substring4('bye');
  substring4('');
  substring5('hello');
  substring5('bye');
  substring5('');

  trim1('hello');
  trim1(' bye ');
  trim1('    ');

  indexOf1('hello');
  indexOf1('bye');
  indexOf2('hello');
  indexOf2('bye');
  indexOf3('hello');
  indexOf3('bye');

  contains1('hello');
  contains1('bye');
  contains2('hello');
  contains2('bye');
  contains3('hello');
  contains3('bye');

  startsWith1('hello');
  startsWith1('bye');
  startsWith2('hello');
  startsWith2('bye');
  startsWith3('hello');
  startsWith3('bye');

  endsWith1('hello');
  endsWith1('bye');
}
