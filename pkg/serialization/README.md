A general-purpose serialization facility for Dart Objects.

This provides the ability to save and restore objects to pluggable
Formats using pluggable Rules.
These rules can use mirrors or be hard-coded. The main principle
is using only public APIs on the serialized objects, so changes to the
internal representation do not break previous serializations. It also handles
cycles, different representations, filling in known objects on the 
receiving side, and other issues. It is not as much intended for
APIs using JSON to pass acyclic structures without class information,
and is fairly heavweight and expensive for doing that compared to simpler
approaches.
