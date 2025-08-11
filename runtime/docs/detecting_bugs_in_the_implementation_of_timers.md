# Detecting Bugs in the Implementation of Timers

When an app is connected to DevTools, a message will appear in the Logging view
of DevTools whenever a timer in the app fires at least 100 ms late.

<!-- // TODO(derekxu16): Insert a screenshot of DevTools displaying these messages. -->

As the messages in the screenshot state, the appearance of these messages does
not necessarily mean that there is a bug in the implementation of timers. Timers
can be blocked from firing for other reasons. A stretch of uninterruptible
synchronous operations can block asynchronous operations, or an app can be
frozen by the OS to conserve resources. When "late timer" messages appear, these
other causes must be ruled out before before suspecting that there is a bug in
the implementation of timers.

Be wary of the fact that it is possible for a bug in the implementation of
timers to manifest only by increasing the delay length of timers that would have
also been delayed under normal circumstances. For example,
[this bug in the implementation of timers on Android](https://github.com/dart-lang/sdk/issues/54868)
only manifested after a given Android app was put into and then taken out of the
Android cached apps freezer. One would have had to join the information logged
in DevTools with information logged by the Android platform to discover this
bug. The following is an explanation of how this could have been done.

Consider an app that was put into and taken out of the cached apps freezer. The
times at which the app was put into and taken out of the cached apps freezer
will be available in `logcat`.
[This link](https://source.android.com/docs/core/perf/cached-apps-freezer#testing-the-apps-freezer)
explains how to find those times. Let those times be `f_in` and `f_out`. There
will be messages in DevTools that say "A timer was supposed to fire `x_i` ms
ago, but just fired now...". The time at which each message was logged will also
be shown in DevTools; let these time be `m_i`. If a message exists such that
(`f_in` <= `m_i` - `x_i` <= `f_out`) AND (`x_i` >= `f_out` - `f_in`), and other
asynchronous operations blockers can be ruled out, then it means that there is a
bug in the implementation of timers.
