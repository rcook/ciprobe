# ciprobe

[![AppVeyor status for project](https://ci.appveyor.com/api/projects/status/a6s9xs8d65678j52?svg=true)][status-project]
[![AppVeyor status for master branch](https://ci.appveyor.com/api/projects/status/a6s9xs8d65678j52/branch/master?svg=true)][status-master]

_Template Rust project built using Cargo and [rust-appveyor-build-pack][rust-appveyor-build-pack]_

* [Latest release][latest]

## Getting starting

### Generate your project from this template project

Go to this project's [home page][home] and click _Use this template_ or directly [generate the project][generate].

### Get an AppVeyor project ID

* Sign into [AppVeyor][appveyor]
* Add your GitHub project
* Go to _Settings_ > _Badges_
* In _Raster image URL_ box, copy and paste ID from end of the URL

### Replace the project name

Clone the newly created Git repo and perform some search and replace:

```bash
cd /path/to/sources
git clone git@github.com/USER/PROJECT.git
cd project
git ls-files | xargs sed -i -e s/ciprobe/PROJECT/g -e s/a6s9xs8d65678j52/APPVEYOR-PROJECT-ID/g
git add .
git commit --amend --author 'FULL-NAME <EMAIL>' -CHEAD
git push -f
````

Where you should replace the following values:

* `USER`
* `PROJECT`
* `APPVEYOR-PROJECT-ID`
* `FULL-NAME`
* `EMAIL`

## Licence

[MIT License][licence]

[appveyor]: https://appveyor.com/
[generate]: https://github.com/rcook/ciprobe/generate
[home]: https://github.com/rcook/ciprobe
[latest]: https://github.com/rcook/ciprobe/releases/latest
[licence]: LICENSE
[rust-appveyor-build-pack]: https://github.com/rcook/rust-appveyor-build-pack
[status-project]: https://ci.appveyor.com/project/rcook/ciprobe
[status-master]: https://ci.appveyor.com/project/rcook/ciprobe/branch/master
