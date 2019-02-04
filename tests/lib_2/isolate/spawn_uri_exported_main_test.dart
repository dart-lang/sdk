import "dart:async";
import "dart:isolate";
import "package:expect/expect.dart";

main() {
  print("Spawning isolate.");
  var t = new Timer(new Duration(seconds: 30), () {
    // it might take some time for new isolate to get spawned from source since
    // it needs to be compiled first.
    Expect.fail("Isolate was not spawned successfully.");
  });
  var rp = new RawReceivePort();
  rp.handler = (msg) {
    print("Spawned main called.");
    Expect.equals(msg, 50);
    rp.close();
  };
  Isolate
      .spawnUri(Uri.parse("spawn_uri_exported_main.dart"), null, rp.sendPort)
      .then((_) {
    print("Loaded");
    t.cancel();
  });
}
