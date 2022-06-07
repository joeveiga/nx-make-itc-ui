# nx-make-itc-ui

Initialize a nx monorepo for our UI projects.

## About

This script will:

- [x] Create a new nx monorepo workspace in cwd (named `itc-ui` by default)
- [x] Generate applications within the monorepo for the ui projects (`login`, `backoffice`, `search`, `portal`, `casb`, `dlp`)
- [x] Generate libraries for the ui libraries (`common`, `state`, `components`)
- [x] Copy the code (`src/` dir) and git history from the old repos into the new one. This operation will rewrite the commit history with the new file paths.
- [x] Running the script after the nx workspace has been created will not recreate it, but rather will update it with the latest upstream changes from
      the repos. _IMPORTANT:_ the nx workplace repo must be clean to avoid merge errors.

#### Motivation

The process of unifying all the repos involves multiple history rewrites and merges that are fairly easy to mess up. By automating these initial steps
in the migration process we greatly reduce the probability of running into issues.

#### Notes

The generated monorepo will still need to be manually modified to:

- Merge dependencies from all the projects into the global `package.json` for the monorepo
- Port any necessary config from the old `angular.json` files to the `project.json` files for each app. This should be straight forward since both files
  use more or less the same schema

I'm looking into ways to alleviate this, perhaps distributing a git patch file with these changes and applying it as part of the script execution (WIP).

## Make

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | bash
```

You can use env variables to modify some basic options, e.g., changing the path where the temporary repos will be cloned:

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | (NX_MAKE__TMP_REPOS_PATH=$(pwd)/__tmp-repos bash)
```

Defaults:

```bash
# name of the nx monorepo workspace to be created
NX_MAKE__MONOREPO_NAME=itc-ui

# path to the temp dir where the repos will be cloned
# NOTE: these WILL NOT BE REMOVED after script execution. we'll keep them around to be used as reference for the manual changes
# feel free to remove them manually after you're done
NX_MAKE__TMP_REPOS_PATH=$TMPDIR/__nx-make-itc-ui__tmp-repos
```
