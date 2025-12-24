#!/bin/bash

CM_OR_UM="um"
INTERVALS=("5m")
YEARS=("2025")
# MONTHS=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12")
MONTHS=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11")

SYMBOLS_FILE="test.txt"
DEST_BASE="/mnt/e/Data/binance-futures/${CM_OR_UM}"

if [[ ! -f "${SYMBOLS_FILE}" ]]; then
  echo "Symbols file not found: ${SYMBOLS_FILE}"
  exit 1
fi

mapfile -t SYMBOLS < "${SYMBOLS_FILE}"
echo "Loaded ${#SYMBOLS[@]} symbols from ${SYMBOLS_FILE}"

if [ "$CM_OR_UM" == "um" ]; then
  BASE_URL="https://data.binance.vision/data/futures/um/monthly/klines"
else
  echo "CM_OR_UM can be only um or cm"
  exit 0
fi

download_url() {
  local url="$1"
  local out_file="$2"

  # 이미 있으면 스킵
  if [[ -f "${out_file}" ]]; then
    echo "skip (exists): ${out_file}"
    return
  fi

  # 디렉토리 생성
  mkdir -p "$(dirname "${out_file}")"

  # 다운로드
  local response
  response=$(wget --server-response -q -O "${out_file}" "${url}" 2>&1 | awk 'NR==1{print $2}')
  if [ "${response}" == "404" ]; then
    echo "File not exist: ${url}"
    rm -f "${out_file}"
  else
    echo "downloaded: ${out_file}"
  fi
}

for symbol in "${SYMBOLS[@]}"; do
  for interval in "${INTERVALS[@]}"; do
    for year in "${YEARS[@]}"; do
      for month in "${MONTHS[@]}"; do
        # 원격 파일 URL
        url="${BASE_URL}/${symbol}/${interval}/${symbol}-${interval}-${year}-${month}.zip"

        # 심볼 기준 + 연월 기준 로컬 경로
        local_dir="${DEST_BASE}/${symbol}/${year}-${month}"
        local_file="${local_dir}/${symbol}-${interval}-${year}-${month}.zip"

        download_url "${url}" "${local_file}" &
      done
      wait
    done
  done
done
