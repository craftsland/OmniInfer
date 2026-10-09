#!/usr/bin/env bash
# Builds the pinned Entrpi/ds4 DeepSeek V4 Flash server for NVIDIA DGX Spark (GB10).
# ds4 publishes no release binaries, so this always builds the pinned source
# archive with `make cuda-spark` and installs it into OmniInfer's runtime tree.

set -euo pipefail

DS4_REPO="Entrpi/ds4"
DS4_VERSION="v0.6.5"
DS4_COMMIT="addc0c4bd6c664f8eed556df5c41f17990dcfcb6"
DS4_ARCHIVE_SHA256="17d1afb8e845333dfb91bd2397a23726fa385b47882817ee39aa27b6fbe0345a"
DS4_ARCHIVE_URL="https://codeload.github.com/${DS4_REPO}/tar.gz/${DS4_COMMIT}"
DS4_REQUIRED_SM="12.1"

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_ROOT}/../../../.." && pwd)"
RUNTIME_ROOT="${OMNIINFER_RUNTIME_ROOT:-${REPO_ROOT}/.local/runtime}/linux"
ACTIVE_ROOT="${RUNTIME_ROOT}/ds4-linux-cuda"
VERSIONS_ROOT="${RUNTIME_ROOT}/.ds4-linux-cuda-versions"
CACHE_ROOT="${REPO_ROOT}/.local/cache/ds4"
LOG_ROOT="${REPO_ROOT}/tmp/test_results/install/ds4-linux-cuda"
CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
JOBS="${OMNIINFER_DS4_BUILD_JOBS:-}"
DRY_RUN=0
CHECK_DEPS=0
FORCE_HOST=0

usage() {
  cat <<'EOF'
Usage: build.sh [options]

Builds the pinned Entrpi/ds4 v0.6.5 server (DeepSeek V4 Flash) for NVIDIA DGX
Spark and installs it into OmniInfer's local runtime tree.

Options:
  --from-source       accepted for the source installer; ds4 is source-only
  --jobs <n>          parallel make jobs (default: half of the CPU cores)
  --check-deps        report build dependencies without installing
  --dry-run           print the planned build without changing files
  --force-host        build even when no GB10 (compute capability 12.1) is visible
  -h, --help          show this help message

Requirements:
  Linux aarch64, NVIDIA GB10 with driver branch R580 or newer, CUDA 13 toolkit
  with nvcc and cuBLAS (CUDA_HOME, default /usr/local/cuda), gcc, make, curl,
  tar and sha256sum. No sudo is required.

Models:
  ds4 loads only the antirez DeepSeek V4 GGUF releases (for example the
  DeepSeek-V4-Flash IQ2XXS imatrix Q2 file); llama.cpp GGUFs are rejected.
EOF
}

while (($# > 0)); do
  case "$1" in
    --from-source) shift ;;
    --jobs)
      JOBS="${2:?missing value for --jobs}"
      shift 2
      ;;
    --check-deps)
      CHECK_DEPS=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force-host)
      FORCE_HOST=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -n "${JOBS}" && ! "${JOBS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "--jobs must be a positive integer, got '${JOBS}'." >&2
  exit 1
fi

gpu_compute_caps() {
  nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits 2>/dev/null | tr -d ' '
}

nvidia_driver_branch() {
  nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null \
    | sed -n '1{s/[[:space:]]//g;s/\..*//;p;}'
}

check_deps() {
  local rc=0
  _dep() {
    local cmd="$1" desc="$2" hint="$3" pkg="${4:-}"
    if command -v "${cmd}" >/dev/null 2>&1 || [[ -x "${cmd}" ]]; then
      printf 'ok|%s|%s|%s|%s\n' "${cmd}" "${desc}" "${hint}" "${pkg}"
    else
      printf 'missing|%s|%s|%s|%s\n' "${cmd}" "${desc}" "${hint}" "${pkg}"
      rc=1
    fi
  }
  _dep gcc "C compiler" "Install build-essential" build-essential
  _dep make "GNU make" "Install build-essential" build-essential
  _dep curl "source download" "Install curl" curl
  _dep tar "archive extraction" "Install tar" tar
  _dep sha256sum "checksum verification" "Install coreutils" coreutils
  _dep nvidia-smi "NVIDIA driver" "Install the NVIDIA R580+ driver for DGX OS" ""
  _dep "${CUDA_HOME}/bin/nvcc" "CUDA 13 compiler" "Install the CUDA 13 toolkit or set CUDA_HOME" ""
  _dep "${CUDA_HOME}/bin/cuobjdump" "CUDA binary inspector" "Install the CUDA 13 toolkit or set CUDA_HOME" ""
  if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "aarch64" ]]; then
    echo "ds4-linux-cuda requires Linux aarch64 (NVIDIA DGX Spark)." >&2
    rc=1
  fi
  if command -v nvidia-smi >/dev/null 2>&1; then
    local branch
    branch="$(nvidia_driver_branch)"
    if [[ ! "${branch}" =~ ^[0-9]+$ || "${branch}" -lt 580 ]]; then
      echo "ds4 CUDA 13 requires NVIDIA driver branch R580 or newer; found '${branch:-unknown}'." >&2
      rc=1
    fi
    if [[ ${FORCE_HOST} -eq 0 ]] && ! gpu_compute_caps | grep -qx "${DS4_REQUIRED_SM}"; then
      echo "ds4 cuda-spark builds sm_121a only; no GPU with compute capability ${DS4_REQUIRED_SM} (GB10) is visible." >&2
      rc=1
    fi
  fi
  return "${rc}"
}

if [[ ${CHECK_DEPS} -eq 1 ]]; then
  check_deps
  exit $?
fi

if [[ -z "${JOBS}" ]]; then
  cores="$(nproc 2>/dev/null || echo 4)"
  JOBS=$(( cores > 2 ? cores / 2 : 1 ))
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  cat <<EOF
ds4 Linux CUDA (DGX Spark) build plan
  source: ${DS4_REPO} ${DS4_VERSION} (${DS4_COMMIT})
  archive: ${DS4_ARCHIVE_URL}
  archive sha256: ${DS4_ARCHIVE_SHA256}
  target: make cuda-spark (sm_121a)
  jobs: ${JOBS}
  CUDA_HOME: ${CUDA_HOME}
  runtime: ${ACTIVE_ROOT}
EOF
  exit 0
fi

if ! deps_report="$(check_deps)"; then
  printf '%s\n' "${deps_report}" | grep '^missing|' >&2 || true
  echo "Build dependencies for ds4-linux-cuda are not satisfied; run with --check-deps for details." >&2
  exit 1
fi

mkdir -p "${CACHE_ROOT}" "${VERSIONS_ROOT}" "${LOG_ROOT}"

archive="${CACHE_ROOT}/ds4-${DS4_COMMIT}.tar.gz"
if [[ ! -f "${archive}" ]] || ! printf '%s  %s\n' "${DS4_ARCHIVE_SHA256}" "${archive}" | sha256sum -c - >/dev/null 2>&1; then
  rm -f "${archive}"
  curl -fL --retry 5 --retry-delay 3 --connect-timeout 20 -o "${archive}.part" "${DS4_ARCHIVE_URL}"
  if ! printf '%s  %s\n' "${DS4_ARCHIVE_SHA256}" "${archive}.part" | sha256sum -c - >/dev/null; then
    rm -f "${archive}.part"
    echo "Checksum verification failed for ${DS4_ARCHIVE_URL}." >&2
    exit 1
  fi
  mv "${archive}.part" "${archive}"
fi

install_id="${DS4_VERSION}-$(date -u +%Y%m%dT%H%M%SZ)-$$"
candidate="${VERSIONS_ROOT}/${install_id}"
build_dir="${candidate}.build"
trap 'rm -rf "${candidate:-}" "${build_dir:-}" "${ACTIVE_ROOT}.new.$$"' EXIT
mkdir -p "${build_dir}" "${candidate}/bin" "${candidate}/logs"
tar -xzf "${archive}" --strip-components=1 -C "${build_dir}"
# The tarball has no .git; ds4 stamps its version from the committed VERSION file.
expected_version="${DS4_VERSION#v}"
if [[ "$(cat "${build_dir}/VERSION" 2>/dev/null)" != "${expected_version}" ]]; then
  echo "ds4 source archive does not report VERSION ${expected_version}." >&2
  exit 1
fi

build_log="${LOG_ROOT}/build-${install_id}.log"
echo "Building ds4 ${DS4_VERSION} (make cuda-spark, ${JOBS} jobs); log: ${build_log}"
# ds4 stamps its version with `git describe`; the build tree sits inside the
# OmniInfer checkout, so stop git discovery at the build directory and let the
# Makefile fall back to the archive's VERSION file.
if ! GIT_CEILING_DIRECTORIES="$(dirname "${build_dir}")" PATH="${CUDA_HOME}/bin:${PATH}" \
    make -C "${build_dir}" cuda-spark -j"${JOBS}" CUDA_HOME="${CUDA_HOME}" >"${build_log}" 2>&1; then
  echo "make cuda-spark failed; last lines of ${build_log}:" >&2
  tail -30 "${build_log}" >&2
  exit 1
fi

server="${build_dir}/ds4-server"
if [[ ! -x "${server}" ]]; then
  echo "make cuda-spark did not produce ds4-server." >&2
  exit 1
fi
sass_archs="$("${CUDA_HOME}/bin/cuobjdump" "${server}" 2>/dev/null | sed -n 's/^arch = //p' | sort -u | tr '\n' ' ')"
if [[ "${sass_archs}" != "sm_121a " ]]; then
  echo "ds4-server must contain only sm_121a SASS; found: ${sass_archs:-none}." >&2
  exit 1
fi
linked_libraries="$(ldd "${server}")"
if grep -q 'not found' <<<"${linked_libraries}"; then
  echo "ds4-server has unresolved shared libraries:" >&2
  grep 'not found' <<<"${linked_libraries}" >&2
  exit 1
fi
reported_version="$("${server}" --version 2>/dev/null | head -1)"
if [[ "${reported_version}" != "ds4-server ${expected_version}" ]]; then
  echo "Unexpected ds4-server version: '${reported_version}'." >&2
  exit 1
fi

# ds4-server needs only its binary at runtime; CUDA kernels are compiled in.
install -m 0755 "${server}" "${candidate}/bin/ds4-server"
cp "${build_dir}/LICENSE" "${candidate}/LICENSE"
cat >"${candidate}/install-manifest.json" <<EOF
{
  "schema_version": 1,
  "backend": "ds4-linux-cuda",
  "source_repository": "https://github.com/${DS4_REPO}",
  "source_version": "${DS4_VERSION}",
  "source_commit": "${DS4_COMMIT}",
  "source_archive_sha256": "${DS4_ARCHIVE_SHA256}",
  "make_target": "cuda-spark",
  "sass_architectures": "$(printf '%s' "${sass_archs}" | sed 's/ *$//')",
  "ds4_server_sha256": "$(sha256sum "${candidate}/bin/ds4-server" | cut -d' ' -f1)",
  "nvcc": "$("${CUDA_HOME}/bin/nvcc" --version | tail -1)",
  "nvidia_driver_branch": "$(nvidia_driver_branch)",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
rm -rf "${build_dir}"

active_link="${ACTIVE_ROOT}.new.$$"
ln -s ".ds4-linux-cuda-versions/${install_id}" "${active_link}"
mv -Tf "${active_link}" "${ACTIVE_ROOT}"
trap - EXIT

echo "ds4 Linux CUDA runtime installed."
echo "  launcher: ${ACTIVE_ROOT}/bin/ds4-server"
echo "  manifest: ${ACTIVE_ROOT}/install-manifest.json"
