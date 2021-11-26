import 'foo.dart' as foo;
// This import isn't used --- foo.bar below explicitly wants bar from foo.
import 'bar.dart';

var x = foo.bar();

foo.Baz? baz;
