#!/bin/bash

#
#  Script to cut a release and publish to gh-pages (or whatever release branch is)
#

SEMVER=./node_modules/semver/bin/semver
OLD_VERSION=$(node -pe 'require("./package.json").version')
CHANGELOG=./CHANGELOG.md
PROG=$(basename $0)
RELEASE_BRANCH=gh-pages # NOTE: this script will force push over this branch. Def. don't use master!
CHANGES=$(git log $OLD_VERSION...master --no-merges --pretty=format:"  * (%an) %s" | head -n -1)
OLD_CHANGES=$(cat $CHANGELOG)

NEW_VERSION='' # will be populated later by script

# for printing friendly status messages
function report () {
  local msg="$1"
  # make it cyan
  echo "$(tput setaf 6)$PROG: $msg$(tput sgr0)"
}

function error () {
  local msg="$1"
  # red this time
  echo "$(tput setaf 1)$PROG: Fatal: $msg$(tput sgr0)"
  exit 1
}

# ensure there are any uncommited files in the current directory
function ensure_clean_directory () {
  report "ensuring directory is clean..."
  git diff --exit-code > /dev/null || {
    error 'git working directory must be clean before running this script, bailing like a lion.'
  }
}

function ensure_on_master_branch () {
  report "ensuring we're on master branch..."
	[[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]] || {
		error 'must be on master branch to cut a release, bailing like a sea turtle.'
	}
}

# The $RELEASE_BRANCH branch will end up existing on github, but not ever locally.
# This way we won't be tempted to tamper with it. Also it makes sense.
function ensure_no_gh_pages_branch () {
  report "ensuring there isn't already a $RELEASE_BRANCH branch..."
	[[ $(git branch | grep $RELEASE_BRANCH) ]] && {
    error "looks like a $RELEASE_BRANCH branch already exists, this is wrong. Bailing like a zebra."
	}
}

function ensure_changes_since_last_release () {
  report "ensuring there have been changes since the last release..."
  [[ $CHANGES ]] || {
    error "looks like there aren't any changes since the last release, bailing like a cowardly swordfish."
  }
}

# ensure the version we're gonna try to write doesn't already exist
function ensure_unique_version () {
  local tag=$1
  report "ensuring the new version isn't already taken..."
  [[ $(git tag | grep $tag) ]] && {
    error "looks like that tag is already taken :/ Best remove it from git tag list, or use a higher one. Make sure it doesn't exist on GH as well."
  }
}

# Prompt for new version (if not provided)
function get_new_version () {
  report "grabbing new version..."

  local proposed_version=$($SEMVER -i patch $OLD_VERSION)

  echo "Enter next version after $OLD_VERSION ($proposed_version):"
  read NEW_VERSION

  [ -z $NEW_VERSION ] && NEW_VERSION=$proposed_version
}

function print_to_changelog () {
  report "writing changes to changelog..."
  local new_version=$1
  printf "### [$new_version](https://github.com/aaronik/tones/releases/tag/$new_version)\n\n$CHANGES\n\n$OLD_CHANGES" > $CHANGELOG
}

function build () {
  npm run build

  if [[ $? != 0 ]]; then
    report "Wuh oh, something went wrong with the build, bailing hard. To undo what's been done, just remove the $RELEASE_BRANCH branch."
  fi
}

# now nuke the build from disk and git
# This method keeps the master branch clean of builds.
function clean_build () {
  report "removing build before merging back into master..."

  git rm -r dist/
  rm -rf dist/
  git commit --amend --no-edit
}


### Main

ensure_changes_since_last_release
ensure_clean_directory
ensure_on_master_branch
ensure_no_gh_pages_branch

# get the new version number
get_new_version

# make sure we haven't used that version
ensure_unique_version $NEW_VERSION

# nothing should be failing from here on out
set -e

# copy branch onto $RELEASE_BRANCH.
# Scheme is as follows: Do release commit, tag, etc. on $RELEASE_BRANCH branch.
# If something borks in this script, cleaning up is as easy as removing the branch.
# Once all's done and pushed to GH, we'll merge this branch back into master.
report "creating branch $RELEASE_BRANCH..."
git checkout -b $RELEASE_BRANCH

# modify package to have new version number. Deps on .npmrc existing
report "writing new npm version $NEW_VERSION..."
npm version $NEW_VERSION

# Add to changelog
print_to_changelog $NEW_VERSION

# cut a tag with new version number
report "cutting new git tag..."
git tag $NEW_VERSION

# run build
build

# commit the changes (package.json and CHANGELOG.md)
report "writing new git release..."
git add -A
git commit -am "release: $NEW_VERSION"

# push to the hub
report "pushing the latest..."
# force push b/c master is the source of truth
git push origin $RELEASE_BRANCH -f --tags

# now we need to clean out the build before we go back to master
clean_build

# checkout back to master
report "back to master..."
git checkout master

# now merge $RELEASE_BRANCH release commit into master branch
report "merging $RELEASE_BRANCH release commit into master for fully updated-ness..."
git merge $RELEASE_BRANCH

# we're all done, clean up
report "all done! cleaning up after ourselves..."
git branch -d $RELEASE_BRANCH
