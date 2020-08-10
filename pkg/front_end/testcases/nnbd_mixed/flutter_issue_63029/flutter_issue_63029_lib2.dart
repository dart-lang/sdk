// @dart = 2.8

import 'flutter_issue_63029_lib1.dart';

class C {}

mixin D<T extends A> on B<T> implements C {}
