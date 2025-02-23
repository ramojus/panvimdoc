# panvimdoc

Decrease friction when writing documentation for your plugins.
Write documentation in [pandoc markdown](https://pandoc.org/MANUAL.html).
Generate documentation in vimdoc.

::: center
This software is released under a MIT License.
:::

# TLDR

1. Choose `${VIMDOC_PROJECT_NAME}`. See [.github/workflows/panvimdoc.yml](./.github/workflows/panvimdoc.yml) as an example.
2. Add the following to `./.github/workflows/panvimdoc.yml`:

   ```yaml
   name: panvimdoc

   on: [push]

   jobs:
     docs:
       runs-on: ubuntu-latest
       name: pandoc to vimdoc
       steps:
         - uses: actions/checkout@v2
         - name: panvimdoc
           uses: kdheepak/panvimdoc@main
           with:
             vimdoc: ${VIMDOC_PROJECT_NAME}
         - uses: stefanzweifel/git-auto-commit-action@v4
           with:
             commit_message: "Auto generate docs"
             branch: ${{ github.head_ref }}
   ```

3. `README.md` gets converted to `./doc/${VIMDOC_PROJECT_NAME}.txt` and committed to the repo.

# Usage

### Using Github Actions

Create an empty doc file:

```
touch doc/${VIMDOC_PROJECT_NAME}.txt
git commit -am "Add empty doc"
git push
```

You don't actually need the file, just the `doc` folder but it is probably easiest to create a file.

Then add the following to `./.github/workflows/panvimdoc.yml`:

```yaml
name: panvimdoc

on: [push]

jobs:
  docs:
    runs-on: ubuntu-latest
    name: pandoc to vimdoc
    steps:
      - uses: actions/checkout@v2
      - name: panvimdoc
        uses: kdheepak/panvimdoc@v3
        with:
          vimdoc: ${VIMDOC_PROJECT_NAME} # Output vimdoc project name (required)
          # The following are all optional
          pandoc: "README.md" # Input pandoc file
          version: "NVIM v0.8.0" # Vim version number
          toc: true # Table of contents
          description: "" # Project Description
          demojify: false # Strip emojis from the vimdoc
          dedupsubheadings: true # Add heading to subheading anchor links to ensure that subheadings are unique
          treesitter: true # Use treesitter for highlighting codeblocks
          ignorerawblocks: true # Ignore raw html blocks in markdown when converting to vimdoc
          shiftheadinglevelby: 0 # Shift heading levels by specified number
          incrementheadinglevelby: 0 # Increment heading levels by specified number
```

Choose `VIMDOC_PROJECT_NAME` appropriately.
This is usually the name of the plugin or the documentation file without the `.txt` extension. For example, the following:

```
- name: panvimdoc
  uses: kdheepak/panvimdoc@main
  with:
    vimdoc: panvimdoc
```

Will output a file `doc/panvimdoc.txt` and the vim help tag for it will be `panvimdoc` using the `main` branch of the repository. It is recommended to pin to an exact version so you can be confident that no surprises occur for you or your users.

For an example of how this is used, see one of the following workflows:

- [kdheepak/panvimdoc](./.github/workflows/panvimdoc.yml): [doc/panvimdoc.txt](./doc/panvimdoc.txt)
- [kdheepak/tabline.nvim](https://github.com/kdheepak/tabline.nvim/blob/main/.github/workflows/ci.yml): [doc/tabline.txt](https://github.com/kdheepak/tabline.nvim/blob/main/doc/tabline.txt)
- [mcchrish/zenbones.nvim](https://github.com/mcchrish/zenbones.nvim/blob/main/.github/workflows/doc.yml): [doc/zenbones.txt](https://github.com/mcchrish/zenbones.nvim/blob/main/doc/zenbones.txt)
- [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim/blob/master/.github/workflows/autogen.yml): [doc/lualine.txt](https://github.com/nvim-lualine/lualine.nvim/blob/master/doc/lualine.txt)

_Feel free to submit a PR to add your documentation as an example here._

### Using it manually

The `./entrypoint.sh` script runs `pandoc` along with all the filters and custom output writer.

```bash
$ ./entrypoint.sh
Usage: ./entrypoint.sh --project-name PROJECT_NAME --input-file INPUT_FILE --vim-version VIM_VERSION --toc TOC --description DESCRIPTION --dedup-subheadings DEDUP_SUBHEADINGS --treesitter TREESITTER

Arguments:
  --project-name: the name of the project
  --input-file: the input markdown file
  --vim-version: the version of Vim that the project is compatible with
  --toc: 'true' if the output should include a table of contents, 'false' otherwise
  --description: a description of the project
  --dedup-subheadings: 'true' if duplicate subheadings should be removed, 'false' otherwise
  --demojify: 'false' if emojis should not be removed, 'true' otherwise
  --treesitter: 'true' if the project uses Tree-sitter syntax highlighting, 'false' otherwise
  --ignore-rawblocks: 'true' if the project should ignore HTML raw blocks, 'false' otherwise
  --doc-mapping: 'true' if the project should use h4 headers as mapping docs, 'false' otherwise
  --shift-heading-level-by: 0 if you don't want to shift heading levels , n otherwise
  --increment-heading-level-by: 0 if don't want to increment the starting heading number, n otherwise
```

You will need `pandoc v3.0.0` or greater for this script to work.

# Motivation

Writing documentation is work.
Writing documentation in vimdoc for vim plugins is an additional hassle.
Making writing vim plugin documentation frictionless is important.

Writing documentation in markdown and converting it to vimdoc can help toward that goal.
This way, plugin authors will have to write documentation just once (for example, as part of the README of the project), and the vim documentation can be autogenerated.

Writing vim documentation requires conforming to a few simple rules.
Although `vimdoc` is not a well defined spec, vim does have some nice syntax highlighting and features like tags and links when the text file is in `vimdoc` compatible format and when `filetype=help` in vim.
Also, typically, while vim documentation are just plain text files, they are usually formatted well using whitespace.
See <https://vimhelp.org/helphelp.txt.html#help-writing> or [`@nanotree`'s project](https://github.com/nanotee/vimdoc-notes) for more information.
I think preserving these features and characteristics of vimdoc for documentation of vim plugins is important.

Writing documentation in Markdown and converting it to vimdoc is not a novel idea.
For example, one can implement a neovim treesitter based markdown to vimdoc converter that works fairly well.
See [ibhagwan/ts-vimdoc.nvim](https://github.com/ibhagwan/ts-vimdoc.nvim) for more information.
This approach is close to ideal. There are no dependencies, except for the Markdown treesitter parser. It is neovim only but you can use this on github actions even for a vim plugin documentation.

I found two other projects that do something similar, [wincent/docvim](https://github.com/wincent/docvim) and [FooSoft/md2vim](https://github.com/FooSoft/md2vim).
As far as I can tell, these projects are actively maintained and may suit your need.

However, none of these projects use Pandoc.
Pandoc Markdown supports a wide number of features: See <https://pandoc.org/MANUAL.html> for more information.
Most importantly, it supports a range of Markdown formats and flavors.
And, Pandoc has filters and a custom output writer that can be configured in lua.
Pandoc filters can extend the capability of Pandoc with minimal lua scripting, and these are very easy to write and maintain too.

This project aims to write a specification of syntax in Pandoc Markdown, and to take advantage of Pandoc filters and the custom output writer capability, to convert a Markdown file to a vim documentation help file.
This project provides a reference implementation of the specification as well.

# Goals

- Markdown file must be readable when the file is presented as the README on GitHub / GitLab / SourceHut etc.
- Markdown file converted to HTML using Pandoc must be web friendly and render appropriately (if the user chooses to do so).
- Vim documentation generated must support links and tags.
- Vim documentation generated should be aesthetically pleasing to view, in vim and as a plain text file.
  - This means using columns and spacing appropriately.
- Format of built in Vim documentation is used as guidelines but not as rules.

# Features

- Autogenerate title for vim documentation
- Autogenerate table of contents
- Generate links and tags
- Support markdown syntax for tables
- Support raw vimdoc syntax where ever needed for manual control.
- Support including multiple Markdown files

# Specification

The specification is described in [panvimdoc.md](./doc/panvimdoc.md) along with examples.
The generated output is in [panvimdoc.txt](./doc/panvimdoc.txt).
The reference implementation of the Pandoc lua filter is in [panvimdoc.lua](./scripts/panvimdoc.lua).
See [entrypoint.sh](./entrypoint.sh) for how to use this script, or check the [Usage](#usage) section.

If you would like to contribute to the specification, have feature requests or opinions, please feel free to comment here: <https://github.com/kdheepak/panvimdoc/discussions/11>.

# References

- <https://learnvimscriptthehardway.stevelosh.com/chapters/54.html>
- <https://github.com/nanotee/vimdoc-notes>
- <https://github.com/mjlbach/babelfish.nvim>
- <https://foosoft.net/projects/md2vim/>
- <https://github.com/wincent/docvim>
- <https://github.com/Orange-OpenSource/pandoc-terminal-writer/>
