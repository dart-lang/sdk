// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache_repair;

import 'dart:async';

import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../source/cached.dart';
import '../utils.dart';

/// Handles the `cache repair` pub command.
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
        break0() {
          join0() {
            join1() {
              globals.repairActivatedPackages().then((x0) {
                try {
                  var results = x0;
                  join2() {
                    join3() {
                      join4() {
                        join5() {
                          completer0.complete();
                        }
                        if (failures > 0) {
                          flushThenExit(exit_codes.UNAVAILABLE).then((x1) {
                            try {
                              x1;
                              join5();
                            } catch (e0, s0) {
                              completer0.completeError(e0, s0);
                            }
                          }, onError: completer0.completeError);
                        } else {
                          join5();
                        }
                      }
                      if (successes == 0 && failures == 0) {
                        log.message(
                            "No packages in cache, so nothing to repair.");
                        join4();
                      } else {
                        join4();
                      }
                    }
                    if (results.last > 0) {
                      var packages = pluralize("package", results.last);
                      log.message(
                          "Failed to reactivate ${log.red(results.last)} ${packages}.");
                      join3();
                    } else {
                      join3();
                    }
                  }
                  if (results.first > 0) {
                    var packages = pluralize("package", results.first);
                    log.message(
                        "Reactivated ${log.green(results.first)} ${packages}.");
                    join2();
                  } else {
                    join2();
                  }
                } catch (e1, s1) {
                  completer0.completeError(e1, s1);
                }
              }, onError: completer0.completeError);
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
        var trampoline0;
        continue0() {
          trampoline0 = null;
          if (it0.moveNext()) {
            var source = it0.current;
            join6() {
              source.repairCachedPackages().then((x2) {
                trampoline0 = () {
                  trampoline0 = null;
                  try {
                    var results = x2;
                    successes += results.first;
                    failures += results.last;
                    trampoline0 = continue0;
                  } catch (e2, s2) {
                    completer0.completeError(e2, s2);
                  }
                };
                do trampoline0(); while (trampoline0 != null);
              }, onError: completer0.completeError);
            }
            if (source is! CachedSource) {
              continue0();
            } else {
              join6();
            }
          } else {
            break0();
          }
        }
        trampoline0 = continue0;
        do trampoline0(); while (trampoline0 != null);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }
}
