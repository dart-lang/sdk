library pub.command.cache_repair;
import 'dart:async';
import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../source/cached.dart';
import '../utils.dart';
class CacheRepairCommand extends PubCommand {
  String get description => "Reinstall cached packages.";
  String get usage => "pub cache repair";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";
  Future onRun() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var successes = 0;
        var failures = 0;
        var it0 = cache.sources.iterator;
        break0(x3) {
          join0() {
            join1() {
              join2() {
                join3() {
                  completer0.complete(null);
                }
                if (failures > 0) {
                  flushThenExit(exit_codes.UNAVAILABLE).then((x0) {
                    try {
                      x0;
                      join3();
                    } catch (e0) {
                      completer0.completeError(e0);
                    }
                  }, onError: (e1) {
                    completer0.completeError(e1);
                  });
                } else {
                  join3();
                }
              }
              if (successes == 0 && failures == 0) {
                log.message("No packages in cache, so nothing to repair.");
                join2();
              } else {
                join2();
              }
            }
            if (failures > 0) {
              var packages = pluralize("package", failures);
              log.message(
                  "Failed to reinstall ${log.red(failures)} ${packages}.");
              join1();
            } else {
              join1();
            }
          }
          if (successes > 0) {
            var packages = pluralize("package", successes);
            log.message("Reinstalled ${log.green(successes)} ${packages}.");
            join0();
          } else {
            join0();
          }
        }
        continue0(x4) {
          if (it0.moveNext()) {
            Future.wait([]).then((x2) {
              var source = it0.current;
              join4() {
                source.repairCachedPackages().then((x1) {
                  try {
                    var results = x1;
                    successes += results.first;
                    failures += results.last;
                    continue0(null);
                  } catch (e2) {
                    completer0.completeError(e2);
                  }
                }, onError: (e3) {
                  completer0.completeError(e3);
                });
              }
              if (source is! CachedSource) {
                continue0(null);
              } else {
                join4();
              }
            });
          } else {
            break0(null);
          }
        }
        continue0(null);
      } catch (e4) {
        completer0.completeError(e4);
      }
    });
    return completer0.future;
  }
}
