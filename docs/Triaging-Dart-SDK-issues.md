## Workflow

* Look through issues that don't have an area assigned.
  * Use the [SDK triage query].
* Does the issue relate to code in the SDK?
  * Assign to the right area by adding an `area-*` label.
* Is the issue in `area-core-library`?
  * Assign the right `library-*` label, too.
* Is it obvious if the issue is a bug or enhancement?
  * Optional: Add `type-bug` or `type-enhancement` if you can.
* Does the issue relate to code in another `dart-lang` project/package?
  * Move the issue to the right repo by using the `Transfer issue` link.
* Get emails when issues are tagged with labels you care about
  * Use the [Dart SDK email tool].

## Issue Labels

### Priority

* Level of **team urgency**
  * Should be the opinion of team and/or product management
  * Can be affected by the quantity/priority of existing issues - *If everything is P0, nothing is P0*
  * May evolve as other issues are resolved and new issues are opened
* Levels
  * **[P0][]**: Drop everything and fix it.
    * For dev channel: blocks the release. Valid cherry-pick.
    * For release channel: worthy of a "dot" release
  * **[P1][]**: Planned for the in-progress release
    * Should be aligned with other work to ensure likely completion in current release
  * **[P2][]**: Important work for later release.
    * Should be done – eventually.
  * **[P3][]**: Maybe, someday
    * First candidates to close as "closed-not-planned"
* When we enter cherry pick season for release X...
    * P0 issues: are the only fixes that will be taken for release X
    * P1-3 issues:
      * Milestone flag should be changed to release X+1 or
      * P1 issues can be changed to p2/3 and milestone flag removed

## Using the `needs-info` label

If you need additional information from an issue reporter to triage or otherwise act
on an issue, say so, and consider adding the `needs-info` label to the issue. Issues
with a `needs-info` label are triaged by our [no response] bot; it will auto-close
the issue after 14 days if the issue reporter does not respond.

## Triage automation

We're experimenting with triage automation. You may see comments made by a
`@dart-github-bot` - that's related to our automation investigations. We may or
may not continue experimentation here; for now, you can safely ignore these
comments.

For the source for the triage tool, see
https://github.com/dart-lang/ecosystem/tree/main/pkgs/sdk_triage_bot.

## Follow up steps for Dart VM and Dart IO Library issues

Issues filed against the Dart VM (issues with label `area-vm` : [VM issues](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aarea-vm+)) and IO library (issues with labels `area-core-library` `library-io` : [io library issues](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aarea-core-library+label%3Alibrary-io)) are triaged at least weekly by a member of the Dart VM team.
Triaging a bug entails the following steps
* Figure out if it is a bug, enhancement request, performance issue, general question, documentation issue or one of the other types and mark the issue appropriately as `type-bug`,`type-question`,`type-enhancement`,`type-performance` or one of the other types.
* If additional information is needed for addressing the bug please add the label `needs-info` to the issue and a comment back to the person filing the issue asking for information
* Review contents of the issue and assign one of 4 priorities listed below

  * P0 - the issue critically impacts many users: somebody is actively working on it and daily updates will be posted on the issue, it is definitely a cherry pick candidate
  * P1 - the issue blocks several users: it is desirable to address it in the next beta release, there will be weekly updates on the issue (could be a cherry pick to the previous stable release)
  * P2 - the issue is represents an important issue for a small number of users or is of minor importance for many users: it is desirable to address it in the next stable release, there will be quarterly updates on the issue
  * P3 - the issue is not critical and is not being actively addressed

  If the priority is <= P2 then it is also assigned to a developer.

* Assign a milestone to the issue based on the priority selected so that the expected resolution timeline is clear. At this point add the `triaged` label so that it is clear the issue has been looked at.

Issues may have their priorities adjusted up or down based on user feedback and milestones may also be adjusted based on available bandwidth in the team to address issues.

[SDK triage query]: https://goto.google.com/dart-triage
[Dart SDK email tool]: https://dart-github-label-notifier.web.app
[P0]: https://github.com/dart-lang/sdk/labels/P0
[P1]: https://github.com/dart-lang/sdk/labels/P1
[P2]: https://github.com/dart-lang/sdk/labels/P2
[P3]: https://github.com/dart-lang/sdk/labels/P3
[no response]: https://github.com/dart-lang/sdk/blob/main/.github/workflows/no-response.yml
