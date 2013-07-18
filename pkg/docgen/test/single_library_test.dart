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
   * Doc comment for class [A].
   * 
   * Multiline Test
   */
  /*
   * Normal comment for class A.
   */
  class A {
    
    int _someNumber;
    
    A() {
      _someNumber = 12;
    }
    
    /**
     * Test for linking to parameter [A]
     */
    void doThis(int A) {
      print(A);
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
          
          var classMethodTypes = [];
          classes.forEach((e) => classMethodTypes.addAll(e.methods.values));
          expect(classMethodTypes.every((e) => e is Map), isTrue);

          var classMethods = [];
          classMethodTypes.forEach((e) => classMethods.addAll(e.values));
          expect(classMethods.every((e) => e is Method), isTrue);
          
          var methodParameters = [];
          classMethods.forEach((e) { 
            methodParameters.addAll(e.parameters.values);
          });
          expect(methodParameters.every((e) => e is Parameter), isTrue);
          
          var functionTypes = library.functions.values;
          expect(functionTypes.every((e) => e is Map), isTrue);
          
          var functions = [];
          functionTypes.forEach((e) => functions.addAll(e.values));
          expect(functions.every((e) => e is Method), isTrue);
          
          var functionParameters = [];
          functions.forEach((e) {
            functionParameters.addAll(e.parameters.values); 
          });
          expect(functionParameters.every((e) => e is Parameter), isTrue);
    
          var variables = library.variables.values;
          expect(variables.every((e) => e is Variable), isTrue);
          
          /// Testing fixReference 
          // Testing Doc comment for class [A].
          var libraryMirror = mirrorSystem.libraries[testLibraryUri];
          var classMirror = libraryMirror.classes.values.first;
          var classDocComment = fixReference('A', libraryMirror, 
              classMirror, null).children.first.text;
          expect(classDocComment == 'test.A', isTrue);
          
          // Test for linking to parameter [A]
          var methodMirror = classMirror.methods['doThis'];
          var methodParameterDocComment = fixReference('A', libraryMirror,
              classMirror, methodMirror).children.first.text;
          expect(methodParameterDocComment == 'test.A.doThis#A', isTrue);
          
          // Testing trying to refer to doThis function
          var methodDocComment = fixReference('doThis', libraryMirror, 
              classMirror, methodMirror).children.first.text;
          expect(methodDocComment == 'test.A.doThis', isTrue);
          
          // Testing something with no reference
          var libraryDocComment = fixReference('foobar', libraryMirror,
              classMirror, methodMirror).children.first.text;
          expect(libraryDocComment == 'foobar', isTrue);
          
          file.deleteSync();
        }));
    });
  });
}
