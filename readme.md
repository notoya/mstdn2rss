# mstdn2rss.rb

Mastodon の home timeline を RSS に変換します。

## インストール

mastodon-api と dotenv の gem を予め導入してください。

## 使い方

カレントディレクトリの.envファイルに環境変数を設定する必要があります。.env.sample を .env にリネームして使用してください。
その際、予めアクセストークンを取得して置く必要があります。高橋さんの [Access Token Generator for Mastodon API](https://takahashim.github.io/mastodon-access-token/) が便利です。

設定は以下の通り

|環境変数             |内容              |
|---------------------|------------------|
|MASTODON_URL         |インスタンスの url|
|MASTODON_ACCESS_TOKEN|アクセストークン|
|MASTODON_CHECK_MIN   |指定した時間分遡って取得する(分)|
|MASTODON_PUBLIC_ONLY |DM、非公開の記事を RSS出力しない (true/false)|

実行すると標準出力に RSS を出力しますのでリダイレクトして使用してください。

また、引数としてファイル名を指定すると設定ファイルとして使用しますので複数のインスタンスで使用する場合は使い分けができます。
