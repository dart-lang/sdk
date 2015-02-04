// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exit code constants.
///
/// From [the BSD sysexits manpage][manpage]. Not every constant here is used,
/// even though some of the unused ones may be appropriate for errors
/// encountered by pub.
///
/// [manpage]: http://www.freebsd.org/cgi/man.cgi?query=sysexits
library pub.exit_codes;

/// The command completely successfully.
const SUCCESS = 0;

/// The command was used incorrectly.
const USAGE = 64;

/// The input data was incorrect.
const DATA = 65;

/// An input file did not exist or was unreadable.
const NO_INPUT = 66;

/// The user specified did not exist.
const NO_USER = 67;

/// The host specified did not exist.
const NO_HOST = 68;

/// A service is unavailable.
const UNAVAILABLE = 69;

/// An internal software error has been detected.
const SOFTWARE = 70;

/// An operating system error has been detected.
const OS = 71;

/// Some system file did not exist or was unreadable.
const OS_FILE = 72;

/// A user-specified output file cannot be created.
const CANT_CREATE = 73;

/// An error occurred while doing I/O on some file.
const IO = 74;

/// Temporary failure, indicating something that is not really an error.
const TEMP_FAIL = 75;

/// The remote system returned something invalid during a protocol exchange.
const PROTOCOL = 76;

/// The user did not have sufficient permissions.
const NO_PERM = 77;

/// Something was unconfigured or mis-configured.
const CONFIG = 78;
