#?bin/sh

bindir=$(dirname $0);
datadir="${bindir}/../log/$(date -Iminutes)"
rawdir="${datadir}/raw"
intdir="${datadir}/interpreted"

mkdir -pv "${rawdir}" "${intdir}"

if [ "$1" = "-j" ]; then
    shift
    p=$1
    shift;
else
    p=$(grep -E '^processor' /proc/cpuinfo | tail -1 | awk '{print $3+1}')
fi

if [ -n "$*" ]; then
    echo "$@"
else
    cat
fi | \
    "${bindir}/split-up-into-slash24.sh" | \
    xargs -P${p} -I'{}' sh -c \
          "echo Scanning '{}'; '${bindir}/scanhost.pl' '{}' | tee '${rawdir}'"/'$(echo "{}" | sed -e "s:/[0-9]*\$:.log:") | '"'${bindir}/interpret-versions.pl' | tee '${intdir}'"/'$(echo "{}" | sed -e "s:/[0-9]*\$:.log:")'
