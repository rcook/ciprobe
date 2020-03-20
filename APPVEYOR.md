# AppVeyor environment

## Branch build (`master` and other)

Triggered when pushing a _branch_ to GitHub

* `$thisDir`, `$currentDir` and `APPVEYOR_BUILD_FOLDER` all set to Git repo root directory
* `APPVEYOR_BUILD_ID` is build ID (same for all jobs)
* `APPVEYOR_BUILD_NUMBER` is build number (same for all jobs)
* `APPVEYOR_BUILD_VERSION` is build version (same for all jobs)
* `APPVEYOR_JOB_ID` is unique for each job
* `APPVEYOR_REPO_BRANCH` is branch
* `APPVEYOR_REPO_COMMIT` is commit hash
* `APPVEYOR_REPO_TAG` is `false`
* No tags show up
* Repo is in detached `HEAD` state checked out at `APPVEYOR_REPO_COMMIT`

### Windows

* `$IsWindows` is `True`
* `APPVEYOR` is `True`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `Visual Studio 2015`
* `CI` is `True`

### Linux

* `$IsLinux` is `True`
* `APPVEYOR` is `True`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `Ubuntu`
* `CI` is `true`

### macOS

* `$IsMacOS` is `True`
* `APPVEYOR` is `true`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `macOS`
* `CI` is `true`
