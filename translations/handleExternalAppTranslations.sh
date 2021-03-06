#!/bin/sh

# verbose and exit on error
set -xe

# import GPG keys
gpg --import /gpg/nextcloud-bot.public.asc
gpg --allow-secret-key-import --import /gpg/nextcloud-bot.asc
gpg --list-keys

# fetch git repo
git clone git@github.com:$1/$2 /app

# build PO file
cd l10n
wget https://raw.githubusercontent.com/nextcloud/docker-ci/master/translations/l10n.pl
wget https://raw.githubusercontent.com/nextcloud/server/master/build/l10nParseAppInfo.php
perl ./l10n.pl $2 read

# push sources
tx push -s

# pull translations - force pull because a fresh clone has newer time stamps
tx pull -f -a --minimum-perc=75

# build JS/JSON based on translations
perl ./l10n.pl $2 write

rm l10n.pl
rm l10nParseAppInfo.php
cd ..

if [ -d tests ]; then
  # remove tests/
  rm -rf tests
  git checkout -- tests/
fi

# create git commit and push it
git add l10n/*.js l10n/*.json
git commit -am "[tx-robot] updated from transifex" || true
git push origin master
echo "done"
