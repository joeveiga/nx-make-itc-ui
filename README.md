# nx-make-itc-ui

Initialize a nx monorepo for our UI projects.

## About

This script will:

- Create a new nx monorepo workspace in cwd (named `itc-ui` by default)
- Generate applications within the monorepo for the ui projects (`login`, `backoffice`, `search`, `portal`, `casb`, `dlp`)
- Generate libraries for the ui libraries (`common`, `state`, `components`)
- Copy the git history from the old repos into the new one. This operation will rewrite the commit history with the new file paths.

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

```bash
curl -o - https://raw.githubusercontent.com/joeveiga/nx-make-itc-ui/main/make.sh | (NX_MAKE__MONOREPO_NAME=itc-ui bash)
```

