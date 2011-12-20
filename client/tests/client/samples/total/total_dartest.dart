// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('total_dartest');

#import('dart:html');
#import('../../../../base/base.dart');
#import('../../../../samples/total/src/TotalLib.dart');
#import('../../../../testing/unittest/unittest_dartest.dart');
#import('../../../../testing/dartest/dartest.dart');
#import('../../../../view/view.dart');
#source('../../../../../samples/total/src/SYLKProducer.dart');
#source('total_test_lib.dart');

fakeTests() {
  group('Failing Tests::', () {
    test('Int Test', () {
      Expect.equals(1,2);
    });
    
    test('String Test', () {
      Expect.equals(""," ");
    });
    
    test('Divide by Zero', (){
      Expect.equals(0, 1/0);
    });
  });
  
  group('Errorneous Tests::' , () {
    test('IndexOutOfRange', (){
      List<int> intList = new List<int>();
      Expect.equals(0, intList[0]);
    });
    
    test('NullPointer', (){
      List<int> intList;
      Expect.equals(0, intList.length);
    });
  });
}

main() {

  // Run the Application
  new Total().run();

  // Load the tests
  totalTests();
  
  fakeTests();

  // Run DARTest
  new DARTest().run();

}
