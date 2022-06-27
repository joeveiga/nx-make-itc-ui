#!/bin/bash

set -o errexit

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
  if [[ -d $old_repos_path && $refresh_old_repos -eq 0 ]]
  then 
    rm -rf $old_repos_path
  fi
  mkdir -p $old_repos_path

  function clone_app {
    local repo_name=$1  # repo to clone
    local move_to=$2    # name for the app to be created in the new monorepo
    local repo_path=$old_repos_path/$move_to

    if [[ ! -d $repo_path ]]
    then 
      cd $old_repos_path
      git clone git@bitbucket.org:observeit/$repo_name.git $move_to
      cd $repo_path
      git_filter_repo --path src/ \
                      --path diagnostics/
      # TODO: move diagnostics to e2e apps (left in here for now)

      git_filter_repo --invert-paths \
                      --path-regex '^src/tsconfig.*json$' \
                      --path-regex '^src/tslint.json$' \
                      --path-regex '^src/karma.conf.js$'

      git_filter_repo --to-subdirectory-filter apps/$move_to
    fi

  }

  function clone_lib {
    local repo_name="itc-ui-library"
    local repo_path="$old_repos_path/$repo_name"

    if [[ ! -d $repo_path ]]
    then 
      cd $old_repos_path
      git clone git@bitbucket.org:observeit/$repo_name.git
      cd $repo_path
      git_filter_repo --path projects/common/src \
                      --path projects/components/src \
                      --path projects/state/src \
                      --path projects/diagnostics/src \
                      --path projects/diagnostics/config \
                      --path projects/diagnostics/types \
      
      # handle diagnostics special structure :/
      git_filter_repo --path-rename projects/diagnostics/config/:projects/diagnostics/src/config/
      git_filter_repo --path-rename projects/diagnostics/types/:projects/diagnostics/src/types/

      git_filter_repo --path-rename projects/:libs/

    fi
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
    npm install -g nx@13.x
  fi

  if [ ! -d $monorepo_path ]
  then
    cd $root_path
    npx create-nx-workspace@13 --preset=empty --name=$monorepo_name --nxCloud=false
    cd $monorepo_path
    npm install --save-dev @nrwl/angular@13.x @nrwl/js@13.x
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
  local e2e=$3
  local app_path=$monorepo_path/apps/$app_name 

  if [ ! -d $app_path ]
  then
    cd $monorepo_path
    nx g @nrwl/angular:application --name=$app_name \
                                   --port=$port \
                                   --style=scss \
                                   --skipTests \
                                   --e2eTestRunner=$e2e \
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
    local generator=$1
    local lib_name=$2
    local lib_path=$monorepo_path/libs/$lib_name

    if [ ! -d $lib_path ]
    then
      cd $monorepo_path
      nx g $generator --name=$lib_name \
                                 --importPath=@itc-ui-library/$lib_name \
                                 --unitTestRunner=none \
                                 --strict=false \
                                 --linter=none \
                                 --publishable
      rm -rf $lib_path/src/*
    fi
  }

  function create_ng_lib {
    create_lib @nrwl/angular:library $1
  }

  function create_ts_lib {
    create_lib @nrwl/js:library $1
  }

  create_ng_lib "common"
  create_ng_lib "components"
  create_ng_lib "state"

  create_ts_lib "diagnostics"

  copy_repo_history "itc-ui-library"
}

function make {
  clone_repos
  create_workspace

  _IFS=$IFS;IFS=','
  for a in "${apps[@]}"; do set -- $a
    create_app $2 $3 $4
  done
  IFS=$_IFS

  create_libs

  cd $monorepo_path

  # sort package.json to reduce patch conflicts
  npx sort-package-json
  
  # initial wip commit
  git add .
  git commit -m "Create nx workspace (wip)"
}

monorepo_name=itc-nx-ui  # name for the new repo to be created
refresh_old_repos=1
old_repos_path=$TMPDIR/__nx-make-itc-ui__tmp-repos

apps=(
  itc-login-application,login,4201,protractor
  itc-backoffice-application,backoffice,4202,cypress
  # itc-search-application,search,4203,none
  # itc-portal-application,portal,4205,none
  # pfpt-casb-application,casb,4206,none
  # pfpt-dlp-application,dlp,4207,none
)

while getopts ":n:p:rR:" option; do
   case $option in
      n)
        monorepo_name=$OPTARG;;
      r)
        refresh_old_repos=0;;
      R)
        old_repos_path=$OPTARG;;
   esac
done

root_path=$(pwd)
monorepo_path="$root_path/$monorepo_name"

make

