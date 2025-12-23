#!/bin/bash

# 당신의 설정 반영
CM_OR_UM="um"  # um 선물 추천
INTERVALS=("1h")
YEARS=("2025")
MONTHS=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12")
DEST="/mnt/ssd/binance-data/futures"

BASE_URL="https://data.binance.vision/data/futures/${CM_OR_UM}/monthly/klines"
mkdir -p "${DEST}"

# 전체 USDT 선물 심볼 자동 가져오기
echo "📥 선물 심볼 리스트 자동 생성..."
curl -s "https://fapi.binance.com/fapi/v1/exchangeInfo" | \
jq -r '.symbols[] | select(.status=="TRADING" and .contractType=="PERPETUAL") | .symbol' | \
grep USD > "${DEST}/futures_symbols.txt"

mapfile -t SYMBOLS < "${DEST}/futures_symbols.txt"
echo "✅ ${#SYMBOLS[@]}개 선물 심볼 발견!"

# 개선된 병렬 다운로드 함수
download_url() {
    local url=$1
    local localfile="${DEST}/$(basename ${url})"
    
    if [[ -f "${localfile}" ]]; then
        echo "⏭️  이미 존재: $(basename ${url})"
        return
    fi
    
    if wget -q --show-progress -O "${localfile}" "${url}"; then
        echo "✅ 완료: $(basename ${url})"
    else
        echo "❌ 실패: $(basename ${url})"
        rm -f "${localfile}"
    fi
}

# 병렬 다운로드 (최대 20개 동시 실행)
MAX_JOBS=20
counter=0
total=$(( ${#SYMBOLS[@]} * ${#INTERVALS[@]} * ${#YEARS[@]} * ${#MONTHS[@]} ))

for symbol in "${SYMBOLS[@]}"; do
    for interval in "${INTERVALS[@]}"; do
        for year in "${YEARS[@]}"; do
            for month in "${MONTHS[@]}"; do
                ((counter++))
                url="${BASE_URL}/${symbol}/${interval}/${symbol}-${interval}-${year}-${month}.zip"
                download_url "${url}" &
                
                # 동시 실행 제한
                while [ $(jobs -r | wc -l) -ge ${MAX_JOBS} ]; do
                    sleep 0.1
                done
                
                echo "🔄 진행: ${counter}/${total} (${symbol})"
            done
        done
    done
done

wait  # 모든 백그라운드 작업 완료 대기
echo "🎉 모든 선물 데이터 다운로드 완료!"
