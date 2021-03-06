#!/bin/bash
set -ueo pipefail

readonly GIT_HASH="$(git rev-parse --short HEAD)"
readonly LDFLAGS="-X main.gitHash=${GIT_HASH} -w -s"
readonly VERSION="1.1.0-${GIT_HASH}"
readonly PROJECT='terraform-provider-keycloak'

function build-for() {
    local os="${1}"
    local arch="${2}"
    local target="release/${os}/${arch}"

    echo "Building ${PROJECT} for ${os}-${arch} in ${target}"

    mkdir -p "${target}"

    env GOOS="${os}" GOARCH="${arch}" go build \
        -ldflags "${LDFLAGS}" \
        -o "${target}/${PROJECT}" \
        -tags netgo
}

function sign-for() {
    local os="${1}"
    local arch="${2}"
    local target="release/${os}/${arch}"
    local bin="${target}/${PROJECT}"
    local hash="$(sha256sum ${bin})"
    local tar="release/${PROJECT}-${VERSION}-${os}-${arch}.tar.gz"

    echo "Signing ${PROJECT} binary for ${os}-${arch} with SHA256 ${hash}"
    gpg --sign "${bin}"

    echo "Packing release into ${tar}"
    tar czvf "${tar}" -C "${target}" ${PROJECT} ${PROJECT}.gpg
}

case "${1}" in
    "build")
        # Build releases for various operating systems:
        build-for "linux" "amd64"
        build-for "darwin" "amd64"
        build-for "windows" "amd64"
        build-for "freebsd" "amd64"
        exit 0
        ;;
    "sign")
        # Sign releases:
        sign-for "linux" "amd64"
        sign-for "darwin" "amd64"
        sign-for "windows" "amd64"
        sign-for "freebsd" "amd64"
        exit 0
        ;;
esac
