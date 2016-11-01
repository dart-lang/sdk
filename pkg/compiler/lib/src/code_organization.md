[comment]: WIP - code is being refactored...

##General code organization of this pacakge

  lib/src/
    |- ...
    |- universe/  - how we represent the closed-world semantics of a program.

[comment]: TODO fill in the rest


##Details

### Universe
[comment]: TODO rename universe => world
[comment]: TODO consider merging feature.dart and use.dart

How we represent the closed-world semantics of a program.

universe/
 |- feature.dart - Features that may be used in the program. Using a feature
 |                 pulls in special code that the compiler needs to support it.
 |- use.dart     - Describes a use of an element (a method, a class) and how it
 |                 is used by the program.


