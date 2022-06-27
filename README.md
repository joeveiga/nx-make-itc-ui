# nx-make-itc-ui

Initialize a nx monorepo for our UI projects.

## About

This script will:

- [x] Create a new nx monorepo workspace in cwd (named `itc-nx-ui` by default)
- [x] Generate applications within the monorepo for the ui projects (`login`, `backoffice`, `search`, `portal`, `casb`, `dlp`)
- [x] Generate libraries for the ui libraries (`common`, `state`, `components`)
- [x] Copy the code (`src/` dir) and git history from the old repos into the new one. This operation will rewrite the commit history with the new file paths.
- [x] Running the script after the nx workspace has been created will not recreate it, but rather will update it with the latest upstream changes from
      the repos. _IMPORTANT:_ the nx workplace repo must be clean to avoid merge errors.

#### Motivation

The process of unifying all the repos involves multiple history rewrites and merges that are fairly easy to mess up. By automating these initial steps
in the migration process we greatly reduce the probability of running into issues.

#### Notes

The generated monorepo will still need to be manually modified to.
I'm looking into ways to alleviate this, perhaps distributing a git patch file with these changes and applying it
as part of the script execution (WIP).

## Make

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | bash
```

You can modify some basic options, e.g., changing the path where the temporary repos will be cloned:

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | bash -s -- -R $(pwd)/__tmp-repos
```

If you want the current fixes to be applied automatically, you can try:

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | bash -s -- -p  https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/fixes_patch.diff 
```

This might not work!

### Defaults:

```bash
# name of the nx monorepo workspace to be created (default 'itc-nx-ui')
-n <monorepo_name>

# path to the temp dir where the repos will be cloned
# NOTE: these WILL NOT BE REMOVED after script execution. we'll keep them around to be used as reference for the manual changes
# feel free to remove them manually after you're done (default '$TMPDIR/__nx-make-itc-ui__tmp-repos')
-R <absolute_path_to_directory>

# re-clone repos into temp repos directory even if they already exist (default not set)
-r

# path to patch file with fixes
-p
```
