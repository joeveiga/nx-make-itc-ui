#!/bin/bash

set -o errexit

git add --all -- ':!package-lock.json'
git diff --staged --no-color
git reset

