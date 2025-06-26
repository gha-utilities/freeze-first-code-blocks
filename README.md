# Freeze First Code Blocks
[heading__top]:
  #freeze-first-code-blocks
  "&#x2B06; GitHub Action to parse and convert first found code block in files to image via Freeze"


GitHub Action to parse and convert first found code block in files to image via
Freeze

## [![Byte size of Freeze First Code Blocks][badge__main__freeze_first_code_blocks__source_code]][freeze_first_code_blocks__main__source_code] [![Open Issues][badge__issues__freeze_first_code_blocks]][issues__freeze_first_code_blocks] [![Open Pull Requests][badge__pull_requests__freeze_first_code_blocks]][pull_requests__freeze_first_code_blocks] [![Latest commits][badge__commits__freeze_first_code_blocks__main]][commits__freeze_first_code_blocks__main] [![License][badge__license]][branch__current__license]


---


- [&#x2B06; Top of Document][heading__top]
- [&#x1F3D7; Requirements][heading__requirements]
- [&#9889; Quick Start][heading__quick_start]
- [&#x1F9F0; Usage][heading__usage]
- [&#x1F5D2; Notes][heading__notes]
- [&#x1F4C8; Contributing][heading__contributing]
  - [&#x1F531; Forking][heading__forking]
  - [&#x1F4B1; Sponsor][heading__sponsor]
- [&#x1F4C7; Attribution][heading__attribution]
- [&#x2696; Licensing][heading__license]


---



## Requirements
[heading__requirements]:
  #requirements
  "&#x1F3D7; Prerequisites and/or dependencies that this project needs to function properly"


Awk, GAwk, or MAwk must be installed in addition to `bash`, `find`, and `jq`,
to make use of scripts within this repository;

- Alpine
   ```Bash
   sudo apk add --no-cache bash findutils gawk jq
   ```
- Arch BTW™
   ```Bash
   sudo pacman -S bash findutils gawk jq
   ```
- Debian derived distributions
   ```Bash
   sudo apt-get install bash findutils gawk jq
   ```

...  And for the latest/greatest version of `freeze` it is recommended to
install Golang, which varies from distribution to distribution;

```bash
go install github.com/charmbracelet/freeze@v0.2.2
```

...  Finally, for now, access to GitHub Actions if using on GitHub, or manually
assigning environment variables prior to running `./entrypoint.sh` _should_ be
all that be necessary to satisfy requirements for this repository.


______


## Quick Start
[heading__quick_start]:
  #quick-start
  "&#9889; Perhaps as easy as one, 2.0,..."




## Usage
[heading__usage]:
  #usage
  "&#x1F9F0; How to utilize this repository"


Reference the code of this repository within your own `workflow` file under
`jobs.steps` section;

```yaml
      - name: Find and freeze first code blocks in posts
        uses: gha-utilities/freeze-first-code-blocks@v0.0.1
        with:
          source_directory: _posts
          find_regex: '.*.md'
```

... For completeness the following be a fully functional example for customized
Jekyll built site deployed to GitHub Pages;


```yaml
on:
  push:
    branches: [ gh-pages ]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Cache assets/images
        uses: actions/cache@v4
        id: cache-images
        with:
          key: cache-images
          path: assets/images

      - name: Checkout source
        uses: actions/checkout@v4
        with:
          fetch-depth: 1
          fetch-tags: true
          ref: ${{ github.head_ref }}
          submodules: 'recursive'

      - name: Find and freeze first code blocks in all collections
        uses: gha-utilities/freeze-first-code-blocks@v0.0.1
        with:
          source_directory: './collections'
          find_regex: '.*.md'
          find_regextype: 'emacs'
          sed_args: '-E'
          sed_expression: 's@collections/_@assets/images/@'
          freeze_config: './ci-cd/.config/freeze/user.json'

      - name: Convert with ImageMagick -- first-code-block
        uses: gha-utilities/ImageMagick@v0.0.6
        with:
          source_directory: assets/images
          find_regex: '.*first-code-block.png'
          destination_extensions: avif,jpg

      - name: Convert PNG images to WebP -- first-code-block
        uses: gha-utilities/bulk-cwebp@v0.0.3
        with:
          source_directory: assets/images
          find_regex: '.*first-code-block.png'
          cwebp_opts: '- q 60'

      # ↓ Do some site building here ↓
      - name: Setup pages
        uses: actions/configure-pages@v5.0.0
      - name: Build pages
        uses: actions/jekyll-build-pages@v1
      # ↑ Do some site building here ↑

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3.0.1

  deploy:
    runs-on: ubuntu-latest
    needs: build

    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4.0.5
```


______


## Notes
[heading__notes]:
  #notes
  "&#x1F5D2; Additional things to keep in mind when developing"


This repository may not be feature complete and/or fully functional, Pull
Requests that add features or fix bugs are certainly welcomed.

Check the [`./action.yaml`](./action.yaml) file for all input/output-s
available as well as up-to-date examples where applicable.

______


## Contributing
[heading__contributing]:
  #contributing
  "&#x1F4C8; Options for contributing to freeze-first-code-blocks and gha-utilities"


Options for contributing to freeze-first-code-blocks and gha-utilities

---

### Forking
[heading__forking]:
  #forking
  "&#x1F531; Tips for forking freeze-first-code-blocks"


Start making a [Fork][freeze_first_code_blocks__fork_it] of this repository to
an account that you have write permissions for.

- Add remote for fork URL. The URL syntax is
  _`git@github.com:<NAME>/<REPO>.git`_...

```Bash
cd ~/git/hub/gha-utilities/freeze-first-code-blocks

git remote add fork git@github.com:<NAME>/freeze-first-code-blocks.git
```


- Commit your changes and push to your fork, eg. to fix an issue...


```Bash
cd ~/git/hub/gha-utilities/freeze-first-code-blocks


git commit -F- <<'EOF'
:bug: Fixes #42 Issue


**Edits**


- `<SCRIPT-NAME>` script, fixes some bug reported in issue
EOF


git push fork main
```

> Note, the `-u` option may be used to set `fork` as the default remote, eg.
> _`git push -u fork main`_ however, this will also default the `fork` remote
> for pulling from too! Meaning that pulling updates from `origin` must be done
> explicitly, eg. _`git pull origin main`_

- Then on GitHub submit a Pull Request through the Web-UI, the URL syntax is _`https://github.com/<NAME>/<REPO>/pull/new/<BRANCH>`_

> Note; to decrease the chances of your Pull Request needing modifications
> before being accepted, please check the
> [dot-github](https://github.com/gha-utilities/.github) repository for detailed
> contributing guidelines.

---

### Sponsor
  [heading__sponsor]:
  #sponsor
  "&#x1F4B1; Methods for financially supporting gha-utilities that maintains freeze-first-code-blocks"


Thanks for even considering it!

Via Liberapay you may
<sub>[![sponsor__shields_io__liberapay]][sponsor__link__liberapay]</sub> on a
repeating basis.

Regardless of if you're able to financially support projects such as
freeze-first-code-blocks that gha-utilities maintains, please consider sharing
projects that are useful with others, because one of the goals of maintaining
Open Source repositories is to provide value to the community.


______


## Attribution
[heading__attribution]:
  #attribution
  "&#x1F4C7; Resources that where helpful in building this project so far."


- [CSS Tricks -- The Essential Meta Tags for Social Media](https://css-tricks.com/essential-meta-tags-social-media/)
- [GitHub -- `bash-utilities/failure`](https://github.com/bash-utilities/failure)
- [GitHub -- `community/discussions` -- `106666` -- For multi-line outputs](https://github.com/orgs/community/discussions/106666)
- [GitHub -- `github-utilities/make-readme`](https://github.com/github-utilities/make-readme)
- [GitHub -- `jekyll/jekyll-seo-tag`](https://github.com/jekyll/jekyll-seo-tag)


______


## License
[heading__license]:
  #license
  "&#x2696; Legal side of Open Source"


```
GitHub Action to parse and convert first found code block in files to image via Freeze
Copyright (C) 2025 gha-utilities

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```


For further details review full length version of
[AGPL-3.0][branch__current__license] License.



[branch__current__license]:
  /LICENSE
  "&#x2696; Full length version of AGPL-3.0 License"

[badge__license]:
  https://img.shields.io/github/license/gha-utilities/freeze-first-code-blocks

[badge__commits__freeze_first_code_blocks__main]:
  https://img.shields.io/github/last-commit/gha-utilities/freeze-first-code-blocks/main.svg

[commits__freeze_first_code_blocks__main]:
  https://github.com/gha-utilities/freeze-first-code-blocks/commits/main
  "&#x1F4DD; History of changes on this branch"

[freeze_first_code_blocks__community]:
  https://github.com/gha-utilities/freeze-first-code-blocks/community
  "&#x1F331; Dedicated to functioning code"

[issues__freeze_first_code_blocks]:
  https://github.com/gha-utilities/freeze-first-code-blocks/issues
  "&#x2622; Search for and _bump_ existing issues or open new issues for project maintainer to address."

[freeze_first_code_blocks__fork_it]:
  https://github.com/gha-utilities/freeze-first-code-blocks/fork
  "&#x1F531; Fork it!"

[pull_requests__freeze_first_code_blocks]:
  https://github.com/gha-utilities/freeze-first-code-blocks/pulls
  "&#x1F3D7; Pull Request friendly, though please check the Community guidelines"

[freeze_first_code_blocks__main__source_code]:
  https://github.com/gha-utilities/freeze-first-code-blocks/
  "&#x2328; Project source!"

[badge__issues__freeze_first_code_blocks]:
  https://img.shields.io/github/issues/gha-utilities/freeze-first-code-blocks.svg

[badge__pull_requests__freeze_first_code_blocks]:
  https://img.shields.io/github/issues-pr/gha-utilities/freeze-first-code-blocks.svg

[badge__main__freeze_first_code_blocks__source_code]:
  https://img.shields.io/github/repo-size/gha-utilities/freeze-first-code-blocks

[sponsor__shields_io__liberapay]:
  https://img.shields.io/static/v1?logo=liberapay&label=Sponsor&message=gha-utilities

[sponsor__link__liberapay]:
  https://liberapay.com/gha-utilities
  "&#x1F4B1; Sponsor developments and projects that gha-utilities maintains via Liberapay"

