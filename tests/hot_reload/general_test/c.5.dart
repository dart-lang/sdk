String g() {
  return bField.a("a") + (bField.b ?? "c");
}

class B {
  dynamic a;
  dynamic b;
  B({this.a});
}

var bField = B(a: (String s) => "$s");
/** DIFF **/
/*
@@ -1,9 +1,10 @@
 String g() {
-  return bField.a("a");
+  return bField.a("a") + (bField.b ?? "c");
 }
 
 class B {
   dynamic a;
+  dynamic b;
   B({this.a});
 }
 
*/
