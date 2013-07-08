library single_library_test;

import 'dart:io'; 

import 'package:unittest/unittest.dart';

import '../lib/docgen.dart';
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';

main() {
  group('Generate docs for', () {
    test('one simple file.', () {
      // TODO(janicejl): Instead of creating a new file, should use an in-memory
      // file for creating the mirrorSystem. Example of the util function in 
      // sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart. 
      // Example of the test is in file mirrors_lookup_test.dart
      var file = new File('test.dart');
      file.writeAsStringSync('''
  library test;
  /**
   * Doc comment for class A.
   * 
   * Multiline Test
   */
  /*
   * Normal comment for class A.
   */
  class A {
    
    /**
     * Markdown _test_ for **class** [A] 
     */
    int _someNumber;
    
    A() {
      _someNumber = 12;
    }
    
    void doThis(int a) {
      print(a);
    }
  }
  
  main() {
    A a = new A();
    a.doThis(5);
  }
      ''');
      
      getMirrorSystem(['test.dart'],'', parseSdk: false)
        .then(expectAsync1((mirrorSystem) {
          var testLibraryUri = currentDirectory.resolve('test.dart');
          var library = generateLibrary(mirrorSystem.libraries[testLibraryUri], 
              includePrivate: true);
          expect(library is Library, isTrue);
          
          var classes = library.classes.values;
          expect(classes.every((e) => e is Class), isTrue);
          
          var classMethods = [];
          classes.forEach((e) => classMethods.addAll(e.methods.values));
          expect(classMethods.every((e) => e is Method), isTrue);
          
          var methodParameters = [];
          classMethods.forEach((e) { 
            methodParameters.addAll(e.parameters.values);
          });
          expect(methodParameters.every((e) => e is Parameter), isTrue);
          
          var functions = library.functions.values;
          expect(functions.every((e) => e is Method), isTrue);
          
          var functionParameters = [];
          functions.forEach((e) {
            functionParameters.addAll(e.parameters.values); 
          });
          expect(functionParameters.every((e) => e is Parameter), isTrue);
    
          var variables = library.variables.values;
          expect(variables.every((e) => e is Variable), isTrue);
          
          file.deleteSync();
        }));
    });
  });
}
