#!/usr/bin/env bash

set -a #export declared variables

. ${SHFLAGHS:-/usr/local/include/shflags}

DEFINE_string configfile '.upsync.yml' "remote upsync configuration file" c

FLAGS "$@" || (echo "Failed parsing options." >&2; exit $?)
eval set -- "${FLAGS_ARGV}"

if ! test -f "${FLAGS_configfile}"; then
    echo "config file ${FLAGS_configfile} not found"
    exit 127
fi
REALCONFIG="/tmp/${FLAGS_configfile}.yaml"
envsubst < "${FLAGS_configfile}" > "${REALCONFIG}"

SYNCS=$(cat ${REALCONFIG}  |yq -j e '.sync' -|jq -c '')
DEFAULT_EXCLUDES=${DEFAULT_EXCLUDES:-"--exclude .upsync.yml"}
#DEFAULT_EXCLUDES=${DEFAULT_EXCLUDES:-}

for row in $(echo "${SYNCS}" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${row} | base64 --decode | jq -r "${1}"
    }

   ORIGIN=$(_jq '.origin // empty')
   USERNAME=$(_jq '.username // empty')
   TOKEN=$(_jq '.token // empty')
   BRANCH=$(_jq '.branch // empty')
   MESSAGE=$(_jq '.message // empty')
   PATHS=$(_jq '.paths')

   ([ -z "$ORIGIN" ] || [ -z "$USERNAME" ] || [ -z "$TOKEN" ] || [ -z "$BRANCH" ] || [ -z "$MESSAGE" ]) && { (echo "required values: origin,username,token,branch,message"); exit 0; }

   git submodule foreach --recursive git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader'
   export XDG_CONFIG_HOME=$(mktemp -d -t ci-XXXXXXXXXX)
   mkdir -p ${XDG_CONFIG_HOME}/git
   echo "https://${USERNAME}:${TOKEN}@github.com" > ${XDG_CONFIG_HOME}/git/credentials
   git config --global --add user.name ${USERNAME}
   git config --global --add user.email dokify-bot@dokify.net
   git config --global credential.helper store
   REMOTE=remote-$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8)
   git remote add ${REMOTE} ${ORIGIN}
   git fetch ${REMOTE}

   ITERATE_PATHS=$(echo ${PATHS}|jq -c '')
   for path in $(echo "${ITERATE_PATHS}" | jq -r '.[] | @base64'); do
     _jq() {
        echo ${path} | base64 --decode | jq -r "${1}"
     }

     SRC="$(_jq '.src')"

     EXCLUDES="$(_jq '.exclude')"
     ITERATE_EXCLUDES=$(echo ${EXCLUDES}|jq -c '')
     EXC=("${DEFAULT_EXCLUDES[@]}")

     for exclude in $(echo "${ITERATE_EXCLUDES}" | jq -r '.[] | @base64'); do
        EXC+=("--exclude $(realpath --relative-to="${SRC}" ${SRC}/$(echo ${exclude} | base64 --decode))")
     done
     EXC_REGEX="$(IFS=' ' ; echo "${EXC[*]}")"

     #echo git diff ..${REMOTE}/${BRANCH} -- $SRC \| git apply ${EXC_REGEX} $(git ls-tree -r ${REMOTE}/${BRANCH} --name-only|xargs  -i sh -c "echo --include {}" |xargs) --summary
     git diff ..${REMOTE}/${BRANCH} -- $SRC | git apply ${EXC_REGEX} $(git ls-tree -r ${REMOTE}/${BRANCH} --name-only|xargs  -i sh -c "echo --include {}" |xargs) --summary
     git diff ..${REMOTE}/${BRANCH} -- $SRC | git apply ${EXC_REGEX} $(git ls-tree -r ${REMOTE}/${BRANCH} --name-only|xargs  -i sh -c "echo --include {}" |xargs)
     git add $SRC
   done

   git commit -m "${MESSAGE}"
   git push
done