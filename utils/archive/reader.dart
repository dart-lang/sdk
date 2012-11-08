// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library reader;

import 'input_stream.dart';
import 'options.dart';
import 'read_request.dart';
import 'utils.dart';

/**
 * A class for extracting and decompressing an archive.
 *
 * Each instance of this class represents a specific set of options for
 * extracting an archive. These options can be used to create multiple input
 * streams using the [reader.ArchiveReader.openFilename] and
 * [reader.ArchiveReader.openMemory] methods.
 *
 * Before opening an archive, this needs to be configured. [filter] should be
 * used to enable specific decompression algorithms, and [format] should be used
 * to enable specific archive formats.
 */
class ArchiveReader {
  /**
   * The configuration for the filter(s) to use when decompressing the contents
   * of an archive. The precise compression used is auto-detected from among all
   * enabled options.
   */
  final Filter filter;

  /**
   * The configuration for the archive format(s) to look for when extracting the
   * contents of an archive. The format used is auto-detected from among all
   * enabled options.
   */
  final Format format;

  /**
   * Options for both [filter] and [format]. See [the libarchive
   * documentation][wiki] for a list of available options.
   *
   * [wiki]: https://github.com/libarchive/libarchive/wiki/ManPageArchiveReadSetOptions3
   */
  final ArchiveOptions options;

  /** Creates a new, unconfigured archive reader. */
  ArchiveReader() : filter = new Filter._(),
                    format = new Format._(),
                    options = new ArchiveOptions();

  /**
   * Begins extracting from [file].
   *
   * [block_size] only needs to be specified for reading from devices that
   * require strict I/O blocking.
   */
  Future<ArchiveInputStream> openFilename(String file, [int block_size=16384]) {
    var id;
    return _createArchive().chain((_id) {
      id = _id;
      return call(OPEN_FILENAME, id, [file, block_size]);
    }).transform((_) => new ArchiveInputStream(id));
  }

  /** Begins extracting from [data], which should be a list of bytes. */
  Future<ArchiveInputStream> openData(List<int> data) {
    var id;
    return _createArchive().chain((_id) {
      id = _id;
      return call(OPEN_MEMORY, id, [bytesForC(data)]);
    }).transform((_) => new ArchiveInputStream(id));
  }

  /**
   * Creates an archive struct, applies all the configuration options to it, and
   * returns its id.
   */
  Future<int> _createArchive() {
    return call(NEW).chain((id) {
      if (id == 0 || id == null) {
        throw new ArchiveException("Archive is invalid or closed.");
      }
      return _pushConfiguration(id).transform((_) => id);
    });
  }

  /**
   * Applies all configuration in this archive to the archive identified by
   * [id]. Returns a future that completes once all the configuration is
   * applied.
   */
  Future _pushConfiguration(int id) {
    var pending = <Future>[];
    if (filter.program != null) {
      if (filter.programSignature != null) {
        var signature = bytesForC(filter.programSignature);
        pending.add(call(SUPPORT_FILTER_PROGRAM_SIGNATURE, id,
                          [filter.program, signature]));
      } else {
        pending.add(call(SUPPORT_FILTER_PROGRAM, id, [filter.program]));
      }
    } else if (filter.all) {
      pending.add(call(SUPPORT_FILTER_ALL, id));
    } else {
      if (filter.bzip2) pending.add(call(SUPPORT_FILTER_BZIP2, id));
      if (filter.compress) {
        pending.add(call(SUPPORT_FILTER_COMPRESS, id));
      }
      if (filter.gzip) pending.add(call(SUPPORT_FILTER_GZIP, id));
      if (filter.lzma) pending.add(call(SUPPORT_FILTER_LZMA, id));
      if (filter.xz) pending.add(call(SUPPORT_FILTER_XZ, id));
    }

    if (format.all) {
      pending.add(call(SUPPORT_FORMAT_ALL, id));
    } else {
      if (format.ar) pending.add(call(SUPPORT_FORMAT_AR, id));
      if (format.cpio) pending.add(call(SUPPORT_FORMAT_CPIO, id));
      if (format.empty) pending.add(call(SUPPORT_FORMAT_EMPTY, id));
      if (format.iso9660) pending.add(call(SUPPORT_FORMAT_ISO9660, id));
      if (format.mtree) pending.add(call(SUPPORT_FORMAT_MTREE, id));
      if (format.raw) pending.add(call(SUPPORT_FORMAT_RAW, id));
      if (format.tar) pending.add(call(SUPPORT_FORMAT_TAR, id));
      if (format.zip) pending.add(call(SUPPORT_FORMAT_ZIP, id));
    }

    void addOption(request, option) {
      var value;
      if (option.value == false || option.value == null) {
        value = null;
      } else if (option.value == true) {
        value = '1';
      } else {
        value = option.value.toString();
      }

      pending.add(CALL(request, id, [module, option.name, value]));
    };

    for (var option in filter.options.all) {
      addOption(SET_FILTER_OPTION, option);
    }

    for (var option in format.options.all) {
      addOption(SET_FORMAT_OPTION, option);
    }

    for (var option in options.all) {
      addOption(SET_OPTION, option);
    }

    return Futures.wait(pending);
  }
}

/**
 * The configuration for the filter(s) to use when decompressing the contents
 * of an archive. The precise compression used is auto-detected from among all
 * enabled options.
 */
class Filter {
  /**
   * Auto-detect among all possible filters. If this is set, all other filter
   * flags are ignored. [program] takes precedence over this.
   */
  bool all = false;

  /**
   * Enable [bzip2][wp] compression.
   *
   * [wp]: http://en.wikipedia.org/wiki/Bzip2
   */
  bool bzip2 = false;

  /**
   * Enable the compression used by [the `compress` utility][wp].
   *
   * [wp]: http://en.wikipedia.org/wiki/Compress
   */
  bool compress = false;

  /**
   * Enable [gzip][wp] compression.
   *
   * [wp]: http://en.wikipedia.org/wiki/Gzip
   */
  bool gzip = false;

  /**
   * Enable [lzma][wp] compression.
   *
   * [wp]: http://en.wikipedia.org/wiki/Lzma
   */
  bool lzma = false;

  /**
   * Enable [xz][wp] compression.
   *
   * [wp]: http://en.wikipedia.org/wiki/Xz
   */
  bool xz = false;

  /**
   * Compress using the command-line program `program`. If this is specified and
   * [programSignature] is not, all other filter flags are ignored. This takes
   * precedence over [all].
   */
  String program;

  // TODO(nweiz): allow multiple programs with signatures to be specified.
  /**
   * If set, `program` will be applied only to files whose initial bytes match
   * [programSignature].
   */
  List<int> programSignature;

  /**
   * Options for individual filters. See [the libarchive documentation][wiki]
   * for a list of available options.
   *
   * [wiki]: https://github.com/libarchive/libarchive/wiki/ManPageArchiveReadSetOptions3
   */
  final ArchiveOptions options;

  Filter._() : options = new ArchiveOptions();
}

/**
 * The configuration for the archive format(s) to look for when extracting the
 * contents of an archive. The format used is auto-detected from among all
 * enabled options.
 */
class Format {
  /**
   * Auto-detect among all possible formats. If this is set, all other format
   * flags are ignored.
   */
  bool all = false;

  /**
   * Enable the [ar][wp] format.
   *
   * [wp]: http://en.wikipedia.org/wiki/Ar_(Unix)
   */
  bool ar = false;

  /**
   * Enable the [cpio][wp] format.
   *
   * [wp]: http://en.wikipedia.org/wiki/Cpio
   */
  bool cpio = false;

  /** Enable treating empty files as archives with no entries. */
  bool empty = false;

  /**
   * Enable the [ISO 9660][wp] format.
   *
   * [wp]: http://en.wikipedia.org/wiki/ISO_9660
   */
  bool iso9660 = false;

  /**
   * Enable the [mtree][wiki] format.
   *
   * [wiki]: https://github.com/libarchive/libarchive/wiki/ManPageMtree5
   */
  bool mtree = false;

  /** Enable treating unknown files as archives containing a single file. */
  bool raw = false;

  /**
   * Enable the [tar][wp] format.
   *
   * [wp]: http://en.wikipedia.org/wiki/Tar_(file_format)
   */
  bool tar = false;

  /**
   * Enable the [zip][wp] format.
   *
   * [wp]: http://en.wikipedia.org/wiki/ZIP_(file_format)
   */
  bool zip = false;


  /**
   * Options for individual formats. See [the libarchive documentation][wiki]
   * for a list of available options.
   *
   * [wiki]: https://github.com/libarchive/libarchive/wiki/ManPageArchiveReadSetOptions3
   */
  final ArchiveOptions options;

  Format._() : options = new ArchiveOptions();
}
