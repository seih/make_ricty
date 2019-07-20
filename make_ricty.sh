#!/bin/bash

# 動作定義
set -Ceu

# 変数定義
readonly RG=ricty_generator.sh
readonly IR=Inconsolata-Regular.ttf
readonly IB=Inconsolata-Bold.ttf
readonly M1=migu-1m-20150712

# 関数定義
help() {
  local help
  help="$(cat <<- EOT
	$(basename "${0}") - Rictyフォントを生成する

	Usage:
	  $(basename "${0}") [command]

	Description:
	  Rictyフォントの生成に必要なファイルを取得し、通常の行間の「Ricty」と、
	  行間の広い「Ricty M」と、さらに行間の広い「Ricty L」フォントを生成する。
	  同時に字間 (xAvgCharWidth) とスタイル (fsSelection・macStyle) の情報を
	  正す。
	  commandを指定せず実行すると、すべての処理を適切な順番で実行する。
	  commandを指定して実行すると、指定した処理だけを実行する。

	Commands:
	  clean: 取得したファイルや中間生成ファイルを削除する。
	  correct_spacing_and_style: TTFの字間とスタイル情報を正す。
	  generate_ricty: 3種類の行間のRictyフォントを生成する。
	  get_inconsolata: Inconsolataフォントを取得する。
	  get_migu-1m: Migu 1Mフォントを取得する。
	  get_ricty_generator: ricty_generator.shを取得する。
	  help: このヘルプを表示する。
	EOT
  )"

  echo "${help}"
  exit 0
}

log() {
  echo "$(date --iso-8601=seconds) ${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}:${FUNCNAME[1]} ${*}"
}

err() {
  echo "$(date --iso-8601=seconds) ${*}" >&2
}

command_exists() {
  if command -v "${1}" > /dev/null 2>&1; then
    return 0
  else
    err "「${1}」コマンドが存在しないため、インストールが必要。"
    exit 1
  fi
}

clean() {
  log "BEGIN"

  rm -f "${RG}"
  rm -f "${IR}"
  rm -f "${IB}"
  rm -f "${M1}.zip" migu-1m-bold.ttf migu-1m-regular.ttf
  rm -f ./*.ttx ./*.new ./*.new2

  log "END" 
}

prepare() {
  log "BEGIN"

  command_exists unzip
  command_exists wget
  command_exists ttx

  log "END"
}

get_ricty_generator() {
  log "BEGIN"

  [[ ! -e "${RG}" ]] && wget https://www.rs.tus.ac.jp/yyusa/ricty/"${RG}"
  [[ ! -x "${RG}" ]] && chmod +x "${RG}"
  	
  log "END"
}

get_inconsolata() {
  log "BEGIN"

  [[ ! -e "${IR}" ]] && wget https://github.com/google/fonts/raw/master/ofl/inconsolata/"${IR}"
  [[ ! -e "${IB}" ]] && wget https://github.com/google/fonts/raw/master/ofl/inconsolata/"${IB}"

  log "END"
}

get_migu-1m() {
  log "BEGIN"

  if [[ ! -e "${M1}.zip" ]]; then
    wget --trust-server-names "https://ja.osdn.net/frs/redir.php?m=iij&f=mix-mplus-ipa/63545/${M1}.zip"
    unzip -j -n ${M1}.zip ${M1}/migu-1m-regular.ttf ${M1}/migu-1m-bold.ttf
  fi

  log "END"
}

generate_ricty() {
  log "BEGIN"

  [[ ! -e "Ricty-Regular.ttf" ]]  && ./ricty_generator.sh auto
  [[ ! -e "RictyM-Regular.ttf" ]] && ./ricty_generator.sh -w -n 'M' auto
  [[ ! -e "RictyL-Regular.ttf" ]] && ./ricty_generator.sh -W -n 'L' auto

  log "END"
}

correct_spacing_and_style() {
  log "BEGIN"

  local ttf_filename
  local ttx_os2_filename
  local ttx_head_filename

  # 意図せず広くなっている字間を正し、スタイル (標準・斜体・太字・太字斜体) も正す
  for ttf_filename in Ricty*.ttf; do
    ## TTXファイルの生成
  
    ### 参考: OS/2 - OS/2 and Windows metrics table specification - Typography | Microsoft Docs
    ### https://docs.microsoft.com/en-us/typography/opentype/spec/os2#fsselection
    ttx_os2_filename="${ttf_filename%.ttf}.os2.ttx"
    [[ ! -e "${ttx_os2_filename}" ]] && ttx -t OS/2 -o "${ttx_os2_filename}" "${ttf_filename}"
  
    ### 参考: head - Font header table specification - Typography | Microsoft Docs
    ### https://docs.microsoft.com/en-us/typography/opentype/spec/head
    ttx_head_filename=${ttf_filename%.ttf}.head.ttx
    [[ ! -e "${ttx_head_filename}" ]] && ttx -t head -o "${ttx_head_filename}" "${ttf_filename}"
  
    ## 字間を狭めた設定ファイルを生成
    if grep -F '<xAvgCharWidth value="500"/>' "${ttx_os2_filename}" > /dev/null 2>&1; then
      continue
    else
      sed -i -e 's|<xAvgCharWidth value="940"/>|<xAvgCharWidth value="500"/>|' "${ttx_os2_filename}"
    fi
  
    ## スタイルを正した設定ファイルを生成
    ## OS/2メトリクステーブルのfsSelectionだけでなく、headテーブルのmacStyleも変更する
    case "${ttf_filename}" in
      *-Regular.ttf )
        sed -i -e 's|<fsSelection value="[^"]*"/>|<fsSelection value="00000000 01000000"/>|' "${ttx_os2_filename}"
        sed -i -e 's|<macStyle value="[^"]*"/>|<macStyle value="00000000 00000000"/>|'       "${ttx_head_filename}"
        ;;
      *-Oblique.ttf )
        sed -i -e 's|<fsSelection value="[^"]*"/>|<fsSelection value="00000000 00000001"/>|' "${ttx_os2_filename}"
        sed -i -e 's|<macStyle value="[^"]*"/>|<macStyle value="00000000 00000010"/>|'       "${ttx_head_filename}"
        ;;
      *-Bold.ttf )
        sed -i -e 's|<fsSelection value="[^"]*"/>|<fsSelection value="00000000 00100000"/>|' "${ttx_os2_filename}"
        sed -i -e 's|<macStyle value="[^"]*"/>|<macStyle value="00000000 00000001"/>|'       "${ttx_head_filename}"
        ;;
      *-BoldOblique.ttf )
        sed -i -e 's|<fsSelection value="[^"]*"/>|<fsSelection value="00000000 00100001"/>|' "${ttx_os2_filename}"
        sed -i -e 's|<macStyle value="[^"]*"/>|<macStyle value="00000000 00000011"/>|'       "${ttx_head_filename}"
        ;;
    esac
  
    ## TTFファイルに反映
    [[ ! -e "${ttf_filename}.new"  ]] && ttx -m "${ttf_filename}"     -o "${ttf_filename}.new"  "${ttx_os2_filename}"
    [[ ! -e "${ttf_filename}.new2" ]] && ttx -m "${ttf_filename}.new" -o "${ttf_filename}.new2" "${ttx_head_filename}"
    cp --force "${ttf_filename}.new2" "${ttf_filename}"  
  done

  log "END"
}

main() {
  log "BEGIN"

  prepare
  get_ricty_generator
  get_inconsolata
  get_migu-1m

  generate_ricty
  correct_spacing_and_style

  log "END"
}

# 主処理
if (( ${#} == 0 )); then
  main
elif declare -f "${1}" > /dev/null; then
  "${1}"
else
  err "該当するコマンド「${1}」が存在しません。"
fi
