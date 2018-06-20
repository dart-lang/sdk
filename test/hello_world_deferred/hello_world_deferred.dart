import 'dart:async';
import 'deferred_import.dart' deferred as deferred_import;

Future<void> main() async {
  await deferred_import.loadLibrary();
  print(deferred_import.helloWorld);
}
