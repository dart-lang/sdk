# Dart SDK breaking change process

The present document describes the Dart SDK philosophy for compatibility, and
process for breaking changes.

## Dart compatibility and philosophy

Generally the Dart team strives to not make breaking changes, and to preserve
compatibility of all Dart programs across stable Dart SDK releases. However, on
occasion, we believe that breaking changes are needed, or justified:

* Security: To resolve a security issue in the specification or implementation.

* Unspecified behavior: Programs that depend on unspecified behavior may break
  as such behavior is specified and implemented.

* Implementation bugs: If the implementation deviates unintentionally from the
  specification, programs may break as we rectify the implementation.

* Evolution: If we deem that there is a very large benefit to changing current
  behavior, we may choose to do so after careful consideration of the associated
  impact of the change.

## Scope of compatibility

It is not practical to offer compatability to programs that do not follow
best practices. Thus, the breaking change process assumes that programs
abide by the following basic conditions:

* Must contain no static analysis **errors**.

* Must not rely on a certain runtime **error** being thrown (in other words, 
  a new SDK might throw fewer errors than an old SDK).

* Must access libraries via the public API (for example, must not reach into
  the internals of a package located in the `/src/` directory).

* Must not rely on an [experiment flag](flags.md).

* Must not circumvent clear restrictions documented in the public API
  documentation (for example, must not mixin a class clearly documented as
  not intended to be used as a mixin).

Compatibility is only considered between stable releases (i.e. releases from the
[Dart stable
channel](https://dart.dev/tools/sdk/archive#stable-channel)).

## Breaking change notification

Anyone wishing to make a breaking change to Dart is expected to perform the
following steps.  It is expected that all of these steps are followed prior
to a change being released in a dev channel release.

### Step 1: Announcement

* Create an issue in the Dart SDK issue tracker labelled
  `breaking-change-request` containing the following:

  * The intended change in behavior.

  * The justification/rationale for making the change.

  * The expected impact of this change.

  * Clear steps for mitigating the change.

[TODO: Link to an issue template for this]

* Email Dart Announce (`announce@dartlang.org`):

  * Subject: 'Breaking change [bug ID]: [short summary]'

  * Very short summary of the intended change

  * Link to the above mentioned issue

  * A request that developers may leave comments in the linked issue, if this
    breaking change poses a severe problem.

* Once you have sent the announce email, please let 'frankyow@google.com` know
as he will help drive the request through approval review process.

### Step 2: Approval

If there is a general agreement that the benefit of the change outweighs the
cost of the change, a set of Dart SDK approvers will approve the change.
Adequate time must be allowed after step 1, at a minimum 24 hours during the
work week for smaller impact changes, and proportionally longer for higher
impact changes.
### Step 3: Execution

If approved, the change may be made.

After the breaking change had been made, the person who made the change must:

* Resolve the breaking change issue and make a note that the change has landed

* Make a note in the [Dart SDK changelog](`changelog.md`) detailing the change.
  This must be prefixed `** Breaking change:`.

* Reply to the original announcement email, and make a note that the change is
  being implemented.

If not approved, or if the requestor decides to not pursue the change, the
requestor must:

* Reply to the original announcement email, and make a note that the change is
  has been rejected, with a quick summary of the rationale for that.
## Unexpected breaking changes & roll-back requests

If a developer notices a breaking change has been made in the dev or stable
channels, and this change impacts a program that abides to the above defined
scope of compatibility, and for which either:

  * No breaking change was announced, or

  * The impact of the change was significantly larger than described in the
    breaking change announcement

, then they may file a 'request for roll-back' using the following steps:

* Create an issue in the Dart SDK issue tracker labelled
  `roll-back-request` containing the following:

  * If applicable, a link to the associated breaking change request issue

  * A clear description of the actual impact, and if applicable a description of
    how this differs from the expected impact.

  * A link to the program that was affected, or another program that illustrated
    the same effect.

[TODO: Link to an issue template for this]

Upon receiving such an issue the Dart SDK team will either:

  * Roll-back the change, or

  * Make a quick corrective action to correct the change, or

  * Detail how the change in their opinion does not warrant a roll-back.

If a breaking change is rolled-back, in addition:

  * The breaking change request issue should be reopened

### Roll-backs following unexpected changes

If a roll-back occurs after what should have been a breaking change, the
originator of the change is expected to follow the breaking change process to
move forward.

If a roll-back occurs after a breaking change, but where the impact was larger
than anticipated, then the impacted party is expected to make a best effort to
quickly rectify their program to either not be affected by the breaking change,
or in some other way offer the originator a clear timeline for when the breaking
change can be landed.

