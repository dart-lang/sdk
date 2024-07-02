> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

## Branches and work flows

We have a rather simple branch setup for the dart project. Normally, everything is developed on the main branch. Features that are not yet ready for prime time are hidden under a flag, and enabled when sufficient stability has been proven. We occasionally create feature branches for landing big and disruptive changes. In addition to that, we have our dev, beta, and stable branches used for releasing the sdk.

In summary, we have in four main branches:

   * **[main](https://github.com/dart-lang/sdk/blob/main/tools/VERSION)**:
     Used for "everyday" development; land your CLs here. 

   * **[dev](https://github.com/dart-lang/sdk/blob/dev/tools/VERSION)**:
     Populated from the main branch via full pushes, usually twice a week. Only in emergencies are [cherry picks](Cherry-picks-to-a-release-channel.md) landed on the dev channel. Don't land CLs here. Released via [dev channel builds](https://dart.dev/tools/sdk/archive#dev-channel).

   * **[beta](https://github.com/dart-lang/sdk/blob/beta/tools/VERSION)**:
     Populated from the dev branch via full pushes, usually once a month, or via [cherry picks](Cherry-picks-to-a-release-channel.md). Don't land CLs here. Released via [beta channel builds](https://dart.dev/tools/sdk/archive#beta-channel).

   * **[stable](https://github.com/dart-lang/sdk/blob/stable/tools/VERSION)**:
     Our main release branch, populated from the beta branch via full pushes when a release is ready, or via [cherry picks](Cherry-picks-to-a-release-channel.md). Don't land CLs here. Released via [stable channel builds](https://dart.dev/tools/sdk/archive#stable-channel).


## Release cycle
Our normal release cycle is roughly 2 months long, but we don't make any guarantees, i.e., we may ship early if we feel that the stability is good or we may ship late if it is not. We don't normally follow a feature driven release cycle, but in some cases for larger changes to the language we may postpone a release to get all tools in sync.

During the entire cycle we do full merges of main to dev, basically releasing a green build from main on dev roughly twice a week. In case of bugs found quickly we do another full push.

We spend the last ~2 weeks of the cycle stabilizing the beta channel, starting with a full push of the latest dev release to beta. We only cherry picking critical fixes to the beta channel. People continue working on the main branch and dev releases will continue to be released. In this 2 week period we do multiple batches of cherry picks a week, and release those on the beta channel. We call this cherry-pick season.

Once we have something that looks good we merge it to stable and release it there. During the 2 months we do patch security, crash and critical bug releases on stable based on the latest stable version.

### Getting your changes to beta channel during cherry pick season

See the [cherry pick to beta](Cherry-picks-to-a-release-channel.md) page for all the details on how to get a change cherry picked.
