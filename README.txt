make_ricty - Rictyフォントを生成する

Usage:
  make_ricty [command]

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
  move_ttf: TTFファイルをttfディレクトリに移動する。
