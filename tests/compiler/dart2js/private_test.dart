// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'mock_compiler.dart';

import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart';

const String PRIVATE_SOURCE_URI = 'src:private';
const String PRIVATE_SOURCE = '''

var _privateVariable;
void _privateFunction() {}

class _PrivateClass {
  _PrivateClass();
  _PrivateClass.publicConstructor();
  _PrivateClass._privateConstructor();

  var _privateField;
  get _privateGetter => null;
  void set _privateSetter(var value) {}
  void _privateMethod() {}

  var publicField;
  get publicGetter => null;
  void set publicSetter(var value) {}
  void publicMethod() {}
}

class PublicClass extends _PrivateClass {
  PublicClass() : super();
  PublicClass.publicConstructor() : super.publicConstructor();
  PublicClass._privateConstructor() : super._privateConstructor();

  _PrivateClass get private => this;
}
''';


void analyze(String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is !List) expectedWarnings = [expectedWarnings];

  MockCompiler compiler = new MockCompiler.internal(analyzeOnly: true);
  compiler.registerSource(Uri.parse(PRIVATE_SOURCE_URI), PRIVATE_SOURCE);
  compiler.diagnosticHandler = (uri, int begin, int end, String message, kind) {
    SourceFile sourceFile = compiler.sourceFiles[uri.toString()];
    if (sourceFile != null) {
      print(sourceFile.getLocationMessage(message, begin, end, true, (x) => x));
    } else {
      print(message);
    }
  };

  String source = '''
                  library public;

                  import '$PRIVATE_SOURCE_URI';

                  void main() {
                    PublicClass publicClass;
                    $text
                  }
                  ''';
  Uri uri = Uri.parse('src:public');
  compiler.registerSource(uri, source);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    compareWarningKinds(text, expectedWarnings, compiler.warnings);
  }));
}

void main() {
  // Read from private variable.
  analyze('var value = _privateVariable;', MessageKind.CANNOT_RESOLVE);
  // Write to private variable.
  analyze('_privateVariable = 0;', MessageKind.CANNOT_RESOLVE);
  // Access private function.
  analyze('var value = _privateFunction;', MessageKind.CANNOT_RESOLVE);
  // Call private function.
  analyze('_privateFunction();', MessageKind.CANNOT_RESOLVE);

  // Call unnamed (public) constructor on private class.
  analyze('new _PrivateClass();', MessageKind.CANNOT_RESOLVE);
  // Call public constructor on private class.
  analyze('new _PrivateClass.publicConstructor();',
          MessageKind.CANNOT_RESOLVE);
  // Call private constructor on private class.
  analyze('new _PrivateClass._privateConstructor();',
      MessageKind.CANNOT_RESOLVE);
  // Call public getter of private type.
  analyze('var value = publicClass.private;');
  // Read from private field on private class.
  analyze('var value = publicClass.private._privateField;',
      MessageKind.PRIVATE_ACCESS);
  // Write to private field on private class.
  analyze('publicClass.private._privateField = 0;',
      MessageKind.PRIVATE_ACCESS);
  // Call private getter on private class.
  analyze('var value = publicClass.private._privateGetter;',
      MessageKind.PRIVATE_ACCESS);
  // Call private setter on private class.
  analyze('publicClass.private._privateSetter = 0;',
      MessageKind.PRIVATE_ACCESS);
  // Access private method on private class.
  analyze('var value = publicClass.private._privateMethod;',
      MessageKind.PRIVATE_ACCESS);
  // Call private method on private class.
  analyze('publicClass.private._privateMethod();',
      MessageKind.PRIVATE_ACCESS);

  // Read from public field on private class.
  analyze('var value = publicClass.private.publicField;');
  // Write to public field on private class.
  analyze('publicClass.private.publicField = 0;');
  // Call public getter on private class.
  analyze('var value = publicClass.private.publicGetter;');
  // Call public setter on private class.
  analyze('publicClass.private.publicSetter = 0;');
  // Access public method on private class.
  analyze('var value = publicClass.private.publicMethod;');
  // Call public method on private class.
  analyze('publicClass.private.publicMethod();');

  // Call unnamed (public) constructor on public class.
  analyze('publicClass = new PublicClass();');
  // Call public constructor on public class.
  analyze('publicClass = new PublicClass.publicConstructor();');
  // Call private constructor on public class.
  analyze('publicClass = new PublicClass._privateConstructor();',
      MessageKind.CANNOT_FIND_CONSTRUCTOR);
  // Read from private field on public class.
  analyze('var value = publicClass._privateField;',
      MessageKind.PRIVATE_ACCESS);
  // Write to private field on public class.
  analyze('publicClass._privateField = 0;',
      MessageKind.PRIVATE_ACCESS);
  // Call private getter on public class.
  analyze('var value = publicClass._privateGetter;',
      MessageKind.PRIVATE_ACCESS);
  // Call private setter on public class.
  analyze('publicClass._privateSetter = 0;',
      MessageKind.PRIVATE_ACCESS);
  // Access private method on public class.
  analyze('var value = publicClass._privateMethod;',
      MessageKind.PRIVATE_ACCESS);
  // Call private method on public class.
  analyze('publicClass._privateMethod();',
      MessageKind.PRIVATE_ACCESS);

  // Read from public field on public class.
  analyze('var value = publicClass.publicField;');
  // Write to public field on public class.
  analyze('publicClass.publicField = 0;');
  // Call public getter on public class.
  analyze('var value = publicClass.publicGetter;');
  // Call public setter on public class.
  analyze('publicClass.publicSetter = 0;');
  // Access public method on public class.
  analyze('var value = publicClass.publicMethod;');
  // Call public method on public class.
  analyze('publicClass.publicMethod();');
}

