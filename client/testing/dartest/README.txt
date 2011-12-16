DARTest is a test infrastructure for Dart applications.

To use the in-app test runner, follow these steps:
1. Import dartest as a library.
#import('dart/testing/unittest/unittest_dartest.dart');
#import('dart/testing/dartest/dartest.dart');


2. Write tests for the application in a function, call the test functions and
then run dart:

test('Test Description',(){
  Expect.equals(3, myAddFunc(1,2));
});
new DARTest().run();


3. Thats all! Now when you compile and run your application, you should 
see the DARTest in-app overlay window.

For an example, see tests in $DART/client/tests/client/samples/total/total_dartest.dart

