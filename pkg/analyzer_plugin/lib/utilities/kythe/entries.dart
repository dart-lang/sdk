// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show KytheEntry;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/kythe/entries.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of entries when computing entries in a
 * `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartEntryRequest implements EntryRequest {
  /**
   * The analysis result for the file in which the entries are being requested.
   */
  ResolveResult get result;
}

/**
 * An object that [EntryContributor]s use to record entries.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EntryCollector {
  /**
   * Record a new [entry].
   */
  void addEntry(KytheEntry entry);
}

/**
 * An object used to produce entries.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class EntryContributor {
  /**
   * Contribute entries for the file specified by the given [request] into the
   * given [collector].
   */
  void computeEntries(EntryRequest request, EntryCollector collector);
}

/**
 * A generator that will generate a 'kythe.getEntries' response.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EntryGenerator {
  /**
   * The contributors to be used to generate the entries.
   */
  final List<EntryContributor> contributors;

  /**
   * Initialize a newly created entry generator to use the given [contributors].
   */
  EntryGenerator(this.contributors);

  /**
   * Create a 'kythe.getEntries' response for the file specified by the given
   * [request]. If any of the contributors throws an exception, also create a
   * non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateGetEntriesResponse(EntryRequest request) {
    List<Notification> notifications = <Notification>[];
    EntryCollectorImpl collector = new EntryCollectorImpl();
    for (EntryContributor contributor in contributors) {
      try {
        contributor.computeEntries(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    KytheGetKytheEntriesResult result =
        new KytheGetKytheEntriesResult(collector.entries, collector.files);
    return new GeneratorResult(result, notifications);
  }
}

/**
 * The information about a requested set of entries.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EntryRequest {
  /**
   * Return the path of the file in which entries are being requested.
   */
  String get path;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}
