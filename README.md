# jma-receipt-docker

[日医標準レセプトソフト(ORCA)](https://www.orca.med.or.jp/receipt)をDockerコンテナ上で実行します。

[PUSH通知機能](https://www.orca.med.or.jp/receipt/tec/push-api)も利用可能です。

- PUSH通知機能(jma-receipt-pusher)
- 日レセPUSH通知駆動フレームワーク(push-exchanger)

## 使用方法

### 一時的な利用の場合

```console
docker pull harukats/jma-receipt
docker run -p 8000:8000 harukats/jma-receipt
```

[ORCAMOクライアント(monsiaj)](https://www.orca.med.or.jp/receipt/download/java-client2/)で
`http://localhost:8000/rpc` に接続してください。

ormasterユーザのデフォルトパスワードは`ormaster`です。

### データベースのデータを保持する場合

```console
git clone https://github.com/harukats/jma-receipt-docker jma-receipt
cd jma-receipt
docker-compose up
```

docker-compose.ymlを適宜カスタマイズして使用してください。
