Leg is an experimental add-on to the Frog compiler that aims to
explore areas of long-term interest:

   * high-performance extensible scanner and parser
   * concrete type inferencing
   * fancy language tool support
   * programming environment integration
   * SSA-based intermediate representation
   * adaptive compilation on the client
   * ...

Some of the things listed above are very experimental of nature and
may prove themselves infeasible or unnecesary, so we want to work on
them in a way that guarantees we will not disrupt the work being done
to make Frog a fantastic compiler for Dart in its default setup.

To keep things simple and allow quick experimentation, Leg will only
support a subset of Dart and fall back on using the default Frog
compiler for the remaining parts of the language. We expect Leg to be
a complete and correct implementation of the supported subset
throughout the implementation and experimentation so you should always
be able to try Leg on any Dart project.

The plan is to share code between the default Frog compiler and Leg
where it makes sense and to learn from both code bases along the way.
