The `loader_test` folder contains a folder per test.

Each test is focusing on part of the features of how tests folders are
recognized and turned into a modular test specification by our libraries.  Note
that all `.dart` source files in these tests are empty because we ignore their
contents.

Each folder contains a file named `expectation.txt` which shows a plain text
summary of what we expect to extract or report from the test:

 * for invalid inputs it shows the error mesage produced by the modular\_test
   loader logic

 * for valid inputs it shows the test layout, highlighting what each module
   contents and dependencies are.

In the future, modular tests will be written in the style of the non-error test
cases.
