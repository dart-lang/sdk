library single_library_test;

import 'dart:io'; 

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/docgen.dart';

main() {
  group('Generate docs for', () {
    test('one simple file.', () {
      var temporaryDir = Directory.systemTemp.createTempSync('single_library_');
      var fileName = path.join(temporaryDir.path, 'temp.dart');
      var file = new File(fileName);
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
      
      getMirrorSystem([fileName])
        .then(expectAsync1((mirrorSystem) {
          var testLibraryUri = new Uri(scheme: 'file', 
              path: path.absolute(fileName));
          var library = generateLibrary(mirrorSystem.libraries[testLibraryUri]);
          expect(library is Library, isTrue);
          
          var classTypes = library.classes;
          expect(classTypes is ClassGroup, isTrue);
          
          var classes = [];
          classes.addAll(classTypes.classes.values);
          classes.addAll(classTypes.errors.values);
          expect(classes.every((e) => e is Class), isTrue);
          
          expect(classTypes.typedefs.values.every((e) => e is Typedef), isTrue);
          
          var classMethodTypes = [];
          classes.forEach((e) {
            classMethodTypes.add(e.methods);
            classMethodTypes.add(e.inheritedMethods);
          });
          expect(classMethodTypes.every((e) => e is MethodGroup), isTrue);

          var classMethods = [];
          classMethodTypes.forEach((e) {
            classMethods.addAll(e.setters.values);
            classMethods.addAll(e.getters.values);
            classMethods.addAll(e.constructors.values);
            classMethods.addAll(e.operators.values);
            classMethods.addAll(e.regularMethods.values);
          });
          expect(classMethods.every((e) => e is Method), isTrue);
          
          var methodParameters = [];
          classMethods.forEach((e) { 
            methodParameters.addAll(e.parameters.values);
          });
          expect(methodParameters.every((e) => e is Parameter), isTrue);
          
          var functionTypes = library.functions;
          expect(functionTypes is MethodGroup, isTrue);
          
          var functions = [];
          functions.addAll(functionTypes.setters.values);
          functions.addAll(functionTypes.getters.values);
          functions.addAll(functionTypes.constructors.values);
          functions.addAll(functionTypes.operators.values);
          functions.addAll(functionTypes.regularMethods.values);
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
        })).whenComplete(() => temporaryDir.deleteSync(recursive: true));
    });
  });
}
