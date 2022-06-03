#!/bin/bash

monorepo_name=${NX_MAKE__MONOREPO_NAME:-itc-ui}  # name for the new repo to be created
old_repos_path=${NX_MAKE__TMP_REPOS_PATH:-$TMPDIR/__nx-make-itc-ui__tmp-repos}

cmd=$1
root_path=$(pwd)
monorepo_path="$root_path/$monorepo_name"
patch_file_path="$root_path/patch.diff"

apps=(
  itc-login-application,login,4201
  itc-backoffice-application,backoffice,4202
  itc-search-application,search,4203
  itc-portal-application,portal,4205
  pfpt-casb-application,casb,4206
  pfpt-dlp-application,dlp,4207
)

# wrapper of filter-repo to reuse some common args
function git_filter_repo {
  # we're excluding all branches other than master
  git filter-repo --refs master $@ 
}

# clone all the ui repos into $old_repos_path.
# this function will also take care of rewriting the git history
# to move the src/ files to their target destination in the new repo
function clone_repos {
  # install git-filter-repo plugin if it doesn't exist
  if ! command -v git-filter-repo &> /dev/null 
  then
    brew install git-filter-repo
  fi

  # clear from previous execution
  if [ -d $old_repos_path ]
  then 
    rm -rf $old_repos_path
  fi
  mkdir -p $old_repos_path

  function clone_app {
    local repo_name=$1  # repo to clone
    local move_to=$2    # name for the app to be created in the new monorepo
    local repo_path=$old_repos_path/$move_to

    cd $old_repos_path
    git clone git@bitbucket.org:observeit/$repo_name.git $move_to
    cd $repo_path
    git_filter_repo --path src/
    git_filter_repo --invert-paths \
                    --path-regex '^src/tsconfig.*json$' \
                    --path-regex '^src/tslint.json$' \
                    --path-regex '^src/karma.conf.js$'
    git_filter_repo --to-subdirectory-filter apps/$move_to
  }

  function clone_lib {
    local repo_name="itc-ui-library"
    local repo_path="$old_repos_path/$repo_name"

    cd $old_repos_path
    git clone git@bitbucket.org:observeit/$repo_name.git
    cd $repo_path
    git_filter_repo --path projects/common/src \
                    --path projects/components/src \
                    --path projects/state/src
    git_filter_repo --path-rename projects/:libs/
  }

  clone_lib &

  _IFS=$IFS;IFS=','
  for a in "${apps[@]}"; do set -- $a
    clone_app $1 $2 &
  done
  IFS=$_IFS

  wait
}

function create_workspace {
  # install nx if it doesn't exist
  if ! command -v nx &> /dev/null
  then
    npm install -g nx@13
  fi

  if [ ! -d $monorepo_path ]
  then
    cd $root_path
    npx create-nx-workspace@13 --preset=empty --name=$monorepo_name --nxCloud=false
    cd $monorepo_path
    npm install --save-dev @nrwl/angular@13
  fi
}

function copy_repo_history {
  local repo_name=$1

  cd $monorepo_path
  git remote add $repo_name $old_repos_path/$repo_name
  git fetch $repo_name
  git branch $repo_name remotes/$repo_name/master
  git merge $repo_name -m "Merge '$repo_name' history" --allow-unrelated-histories
  git remote remove $repo_name
  git branch -d $repo_name
}

function create_app {
  local app_name=$1
  local port=$2
  local app_path=$monorepo_path/apps/$app_name 

  if [ ! -d $app_path ]
  then
    cd $monorepo_path
    nx g @nrwl/angular:application --name=$app_name \
                                   --port=$port \
                                   --style=scss \
                                   --skipTests \
                                   --e2eTestRunner=none \
                                   --unitTestRunner=none \
                                   --strict=false \
                                   --linter=none \
                                   --routing=false
    rm -rf $app_path/src/*
  fi

  copy_repo_history $app_name
  # mv $app_path/src/styles.css $app_path/src/styles.scss
}

function create_libs {
  function create_lib {
    local lib_name=$1
    local lib_path=$monorepo_path/libs/$lib_name

    if [ ! -d $lib_path ]
    then
      cd $monorepo_path
      nx g @nrwl/angular:library --name=$lib_name \
                                 --importPath=@itc-ui-library/$lib_name \
                                 --unitTestRunner=none \
                                 --strict=false \
                                 --linter=none
      rm -rf $lib_path/src/*
    fi
  }

  create_lib "common"
  create_lib "components"
  create_lib "state"

  copy_repo_history "itc-ui-library"
}

function generate_patch {
  cd $monorepo_path
  git add .
  git diff --staged --no-color > $patch_file_path
  git reset
}

function make {
  clone_repos
  create_workspace

  _IFS=$IFS;IFS=','
  for a in "${apps[@]}"; do set -- $a
    create_app $2 $3
  done
  IFS=$_IFS

  create_libs

  # initial wip commit
  cd $monorepo_path
  git add .
  git commit -m "Create nx workspace (wip)"

  if [ -e $patch_file_path ]
  then
    # apply current fixes
    git apply $patch_file_path
  fi
}


case $cmd in
  generate-patch | gp)
    generate_patch
    ;;

  *)
    make
    ;;
esac

