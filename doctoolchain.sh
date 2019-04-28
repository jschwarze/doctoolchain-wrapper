#!/usr/bin/env bash
#set -x
## Wrapper Script for running DocToolchain inside of your own project, docker based.
## The script will help you to execute the DocToolchain commands inside your project.
## You can use the following environment variables to adapt to your local needs.
##
## The version of the docker image used for doctoolchain
DTC_VERSION="${DTC_VERSION:-v1.1.1}"
## The docker image that should be used
DTC_IMAGE="${DTC_IMAGE:-rdmueller/doctoolchain}"
## The documentation root
DTC_DOC_ROOT="${DTC_DOC_ROOT:-./}"
DTC_DOC_ROOT="$(cd $DTC_DOC_ROOT; pwd)"
## The output directory
DTC_OUTPUT_DIR="${DTC_OUTPUT_DIR:-${DTC_DOC_ROOT}/build}"


RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

################################################################# 
## Initialize a new documentation folder for doctoolchain.
##
init () {
  DTC_DOC_ROOT=${1:-${DTC_DOC_ROOT}}
  if [ ! -d "$1" ]; then
    mkdir -p $1
  fi
  DTC_DOC_ROOT="$(cd $DTC_DOC_ROOT; pwd)"
  if [ -f "$DTC_DOC_ROOT/Config.groovy" ]; then
    echo -e "${ORANGE}WARNING! Initialization stopped because folder ($DTC_DOC_ROOT) seems to be initialized already. The file Config.groovy already exists.${NC}"
    exit 1;
  fi
  echo "    Executing initialization..."
  docker run --rm -it --entrypoint /bin/bash -w /docToolchain -v $DTC_DOC_ROOT:/project $DTC_IMAGE:$DTC_VERSION \
  -c "./gradlew -b init.gradle $2 -PnewDocDir=/project && exit"
  echo "  Creating gradle.properties file for further configuration..."
  cat >$DTC_DOC_ROOT/gradle.properties <<EOF
// settings to link to open issues

jiraRoot = 'https://jira-instance'
jiraUser = 'username'
jiraPass = '' // leave empty to get a prompt
jiraProject = '' // the key of the project
jiraLabel = '' // the label to restrict search to

jiraJql  = project='%jiraProject%' AND resolution='Unresolved' AND labels='%jiraLabel%' ORDER BY priority DESC, duedate ASC

// Directory containing the documents to be processed by docToolchain.
// If the documents are together with docToolchain, this can be relative path.
// If the documents are outside of docToolchain, this must be absolute path, usually provided
// on the command line with -P option given to gradle.
docDir = /project
#inputPath = src/docs
## FIXME - This is used because of https://github.com/docToolchain/docToolchain/issues/259
inputPath=.
pdfThemeDir = ./src/docs/pdfTheme

// Path to the main configuration file, relative to docDir.
mainConfigFile = Config.groovy

// Path to the confluence configuration file, relative to docDir.
confluenceConfigFile = scripts/ConfluenceConfig.groovy

// Path to the configuration file of exportChangelog task, relative to docDir.
changelogConfigFile = scripts/ChangelogConfig.groovy"
}
EOF
  echo "  Creating .gitignore file..."
  cat >$DTC_DOC_ROOT/.gitignore <<EOF
.gradle
build
EOF
    ## FIXME: This Hack is needed because the container is running as root. 
    ## We could use '--user $(id -u):$(id -g)' as docker parameter, but that will not work because gradle would write into the /docToolchain folder... :-(
    echo "  Changing owner of documentation folder $DTC_DOC_ROOT to the current user..."
    sudo chown -R ${USER}:${USER} $DTC_DOC_ROOT

    echo "  Now we will copy that script into the documentation folder for further executions..."
    cp ${BASH_SOURCE[0]} $DTC_DOC_ROOT
    echo -e "${GREEN}DONE.${NC} Directory $DTC_DOC_ROOT successfully initialized."
    echo "We recommend to initialize the folder as a git repository with 'git init' and create and initial commit."
}

clean () {
    if [ ! -d "$DTC_OUTPUT_DIR" ]; then
        echo -e "${RED}ERROR. The given output folder $DTC_OUTPUT_DIR does not exist.${NC}"
        exit 2;
    fi
    echo "  Deleting content of output directory ${DTC_OUTPUT_DIR}..."
    rm -rf $DTC_OUTPUT_DIR/*
    echo -e "${GREEN}DONE.${NC}"
}

run () {
    docker run --rm -it --entrypoint /bin/bash -v $DTC_DOC_ROOT:/project -v $DTC_DOC_ROOT/gradle.properties:/docToolchain/gradle.properties $DTC_IMAGE:$DTC_VERSION \
    -c "doctoolchain . $1 $2 $3 $4 $5 $6 $7 $8 $9 && exit"
    # Check if the output folder exist
    if [ ! -d "$DTC_OUTPUT_DIR" ]; then
        echo -e "${RED}ERROR. Could not build documentation.${NC}"
        exit 3;
    fi
    ## FIXME. This is needed, because the container is running with root. 
    ## We could use '--user $(id -u):$(id -g)' as docker parameter, but gradle will write into /docToolchain folder. There we can't write.
    echo "  Changing owner of output folder $DTC_OUTPUT_DIR to the current user..."
    sudo chown -R ${USER}:${USER} ./build 
    sudo chown -R ${USER}:${USER} ./.gradle 
    echo -e "${GREEN}DONE. docToolchain execution was successfull.${NC}"   
}

help () {
    echo "Please run with one of the following commands: [clean|initExising|initArc42EN|initArc42DE|initArc42ES|<any doctool command>]"
    echo "  clean - delete everything inside the DTC_OUTPUT_DIR ($DTC_OUTPUT_DIR)"
    echo "  initExisting - initialize a documentation root directory with existing documents in folder given by env DTC_DOC_ROOT ($DTC_DOC_ROOT) or by second parameter"
    echo "  initArc42EN - initialize a new documentation root directory with english Arc42 template in folder given by env DTC_DOC_ROOT ($DTC_DOC_ROOT) or by second parameter"
    echo "  initArc42DE - initialize a new documentation root directory with german Arc42 template in folder given by env DTC_DOC_ROOT ($DTC_DOC_ROOT) or by second parameter"
    echo "  initArc42ES - initialize a new documentation root directory with spanish Arc42 template in folder given by env DTC_DOC_ROOT ($DTC_DOC_ROOT) or by second parameter"
    echo "  generateHTML - Generates HTML documentation from $DTC_DOC_ROOT into $DTC_OUTPUT_DIR"
    echo "  generatePDF - Generates PDF documentation from $DTC_DOC_ROOT into $DTC_OUTPUT_DIR"
}


#echo "DTC_VERSION=$DTC_VERSION"
#echo "DTC_IMAGE=$DTC_IMAGE"
#echo "DTC_DOC_ROOT=$DTC_DOC_ROOT"
#echo "DTC_OUTPUT_DIR=$DTC_OUTPUT_DIR"

case "$1" in
    "initExisting")
      init $2 "initExisting"
      ;;
    "initArc42EN")
      init $2 "initArc42EN"
      ;;
    "initArc42DE")
      init $2 "initArc42DE"
      ;;
    "initArc42ES")
      init $2 "initArc42ES"
      ;;      
    "clean")
      clean
      ;;
    "help")
      help
      ;;
    *)
      run $1 $2 $3 $4
      ;;
esac