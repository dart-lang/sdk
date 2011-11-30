URL: http://code.google.com/p/double-conversion/
Version: d7a1ee5a309c ('Merge in "Reduce static" branch.').
License: BSD
License File: LICENSE

Description:
This is the double->string and string->double library that has been developed
for v8.

Local Modifications:
Removed the test directory, the Makefile and the scons-files.
Wrapped ASSERT, UNIMPLEMENTED and UNREACHABLE macros into #ifndef.
Changed memcpy to memmove.
