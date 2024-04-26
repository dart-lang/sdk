String g() {
  return bField.a("a");
}

class B {
  dynamic a;
  B({this.a});
}

var bField = B(a: (String s) => "$s");
/** DIFF **/
/*
@@ -1 +1,10 @@
-String g() => "";
+String g() {
+  return bField.a("a");
+}
+
+class B {
+  dynamic a;
+  B({this.a});
+}
+
+var bField = B(a: (String s) => "$s");
*/
