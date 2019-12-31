tick="✓"

step_log() {
  message=$1
  printf "\n\033[90;1m==> \033[0m\033[37;1m%s\033[0m\n" "$message"
}

add_log() {
  mark=$1
  subject=$2
  message=$3
  if [ "$mark" = "$tick" ]; then
    printf "\033[32;1m%s \033[0m\033[34;1m%s \033[0m\033[90;1m%s\033[0m\n" "$mark" "$subject" "$message"
  else
    printf "\033[31;1m%s \033[0m\033[34;1m%s \033[0m\033[90;1m%s\033[0m\n" "$mark" "$subject" "$message"
  fi
}

step_log "Housekeeping"
unset HOMEBREW_DISABLE_LOAD_FORMULA
brew update-reset "$(brew --repository)" >/dev/null 2>&1
brew tap shivammathur/homebrew-php
if [ "$PSR_VERSION" = "psr@7.0" ]; then
  brew uninstall --ignore-dependencies openssl@1.1
  rm -rf /usr/local/opt/openssl@1.1/*
  brew tap shivammathur/homebrew-openssl-deprecated
  brew install openssl@1.0 >/dev/null 2>&1
  brew link --force openssl@1.0
fi
add_log "$tick" "Housekeeping" "Done"

step_log "Adding tap $GITHUB_REPOSITORY"
mkdir -p "$(brew --prefix)/Homebrew/Library/Taps/$HOMEBREW_BINTRAY_USER"
ln -s "$PWD" "$(brew --prefix)/Homebrew/Library/Taps/$GITHUB_REPOSITORY"
add_log "$tick" "$GITHUB_REPOSITORY" "Tap added to brewery"

step_log "Checking label"
package="${PSR_VERSION//@/:}"
new_version=$(brew info Formula/"$PSR_VERSION".rb | head -n 1 | cut -d',' -f 1 | cut -d' ' -f 3)
existing_version=$(curl --user "$HOMEBREW_BINTRAY_USER":"$HOMEBREW_BINTRAY_KEY" -s https://api.bintray.com/packages/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO"/"$package" | sed -e 's/^.*"latest_version":"\([^"]*\)".*$/\1/')
echo "existing label: $existing_version"
echo "new label: $new_version"
#if [ "$new_version" != "$existing_version" ]; then
if true; then
  step_log "Filling the Bottle"
  brew test-bot "$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO"/"$PSR_VERSION" --root-url=https://dl.bintray.com/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO" --skip-setup --skip-homebrew --skip-recursive-dependents
  LC_ALL=C find . -type f -name '*.json' -exec sed -i '' s~homebrew/bottles-phalcon~"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO"~ {} +
  LC_ALL=C find . -type f -name '*.json' -exec sed -i '' s~bottles-phalcon~phalcon~ {} +
  LC_ALL=C find . -type f -name '*.json' -exec sed -i '' s~bottles~phalcon~ {} +
  cat -- *.json
  add_log "$tick" "PSR" "Bottle filled"

  step_log "Adding label"
  curl \
  --user "$HOMEBREW_BINTRAY_USER":"$HOMEBREW_BINTRAY_KEY" \
  --header "Content-Type: application/json" \
  --data " \
  {\"name\": \"$package\", \
  \"vcs_url\": \"$GITHUB_REPOSITORY\", \
  \"licenses\": [\"MIT\"], \
  \"public_download_numbers\": true, \
  \"public_stats\": true \
  }" \
  https://api.bintray.com/packages/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO" >/dev/null 2>&1 || true
  add_log "$tick" "$package" "Bottle labeled"

  step_log "Stocking the new Bottle"
  git stash
  sleep $((RANDOM % 100 + 1))s
  git pull -f https://"$HOMEBREW_BINTRAY_USER":"$GITHUB_TOKEN"@github.com/"$GITHUB_REPOSITORY".git HEAD:master
  git stash apply
  curl --user "$HOMEBREW_BINTRAY_USER":"$HOMEBREW_BINTRAY_KEY" -X DELETE https://api.bintray.com/packages/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO"/"$package"/versions/"$new_version"
  brew test-bot --ci-upload --tap="$GITHUB_REPOSITORY" --root-url=https://dl.bintray.com/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO" --bintray-org="$HOMEBREW_BINTRAY_USER"
  curl --user "$HOMEBREW_BINTRAY_USER":"$HOMEBREW_BINTRAY_KEY" -X POST https://api.bintray.com/content/"$HOMEBREW_BINTRAY_USER"/"$HOMEBREW_BINTRAY_REPO"/"$package"/"$new_version"/publish
  add_log "$tick" "PSR $PSR_VERSION" "Bottle added to stock"

  step_log "Updating inventory"
  git push https://"$HOMEBREW_BINTRAY_USER":"$GITHUB_TOKEN"@github.com/"$GITHUB_REPOSITORY".git HEAD:master --follow-tags
  add_log "$tick" "Inventory" "updated"
else
  add_log "$tick" "PSR $new_version" "Bottle exists"
fi