function logInfo() {
    echo "$(date '+%Y/%m/%dT%H:%M:%S') INFO  $1"
}

function logWarn() {
    echo "$(date '+%Y/%m/%dT%H:%M:%S') WARN  $1"
}

function logError() {
    echo "$(date '+%Y/%m/%dT%H:%M:%S') ERROR $1"
}

function gitClone() {
    local url="$1"

    dir="$HOME/src/$(echo $url | cut -d"/" -f3- | sed -e 's/.com//g' | sed -e 's/.git//1')"
    mkdir -p "$(dirname $dir)"
    cwd=$(pwd)
    cd $(dirname $dir)
    echo "cloning into $(dirname $dir)"
    git clone "$url"
    cd $dir
    git pull
    cd $cwd
}