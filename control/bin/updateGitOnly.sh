#!/bin/bash

export CONTENT_DIR="/u01/content/"
export GIT_REPOS="https://raw.githubusercontent.com/nagypeter/vmcontrol/master/control/bin/git.repos.txt"

. ~/.bashrc

curl $GIT_REPOS -o ~/git.repos.txt

# print proxy settings
GIT_SYSTEM_PROXY=`git config --get --system http.proxy`
GIT_GLOBAL_PROXY=`git config --get --global http.proxy`
echo "GIT _system_ Proxy set to: [${GIT_SYSTEM_PROXY}] (OK to be empty)"
echo "GIT _global_ Proxy set to: [${GIT_GLOBAL_PROXY}] (OK to be empty)"

#process file contains git repos
while IFS= read -r GIT_URL_AND_VERSION; do

  #Split the string based on the delimiter, ':'
  readarray -d : -t strarr <<< "$GIT_URL_AND_VERSION"

  BRANCH="master"
  # Print each value of the array by using loop
  for (( n=0; n < ${#strarr[*]}; n++))
  do
    if ((n == 0))
     then
       GIT_URL=${strarr[n]}
     elif ((n == 1))
     then
       BRANCH=${strarr[n]}
     fi
  done

  echo "Next Git repository to clone/update: $GIT_URL with version $BRANCH"

  cd $CONTENT_DIR

  # protect from network failure/wrong proxy settings
  timeout 10 git ls-remote --exit-code -h "$GIT_URL"
  if [ "$?" -ne 0 ]; then
      echo "[ERROR] Unable to read from ${GIT_URL}"
      echo "Check your proxy settings and/or restart Virtualbox VM."
      if [ "$1" == "wait" ]; then
         read -p "Press [Enter] to close the window"
         exit 1;
      fi
  fi

  # get the folder name
  LAST=${GIT_URL##*/}
  GITLOCALFOLDER=${LAST%%.git}

  if [ ! -e ${GITLOCALFOLDER} ]; then
    echo "Cloning remote repository from ${GIT_URL} to ${GITLOCALFOLDER}..."
    git clone ${GIT_URL}
    cd ${GITLOCALFOLDER}
    git checkout ${BRANCH}
  else
    echo "Update remote repository from ${GIT_URL} to ${GITLOCALFOLDER}..."
    cd ${GITLOCALFOLDER}
    git fetch

    git reset --hard origin/${BRANCH}

    echo "========================================"
    echo "The file(s) below is not tracked by git:"
    git clean -n
    echo "========================================"
  fi

done < ~/git.repos.txt

read -p "Git update complete. Press [Enter] to close the window"
