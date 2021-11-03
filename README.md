## 简单推送

[文本消息](https://work.weixin.qq.com/api/doc/90000/90135/90236#%E6%96%87%E6%9C%AC%E6%B6%88%E6%81%AF)
```
curl --location --request POST 'http://127.0.0.1:8080/info' \
--header 'Content-Type: application/json' \
--data-raw '{
    "touser": "@all",
    "msgtype": "text",
    "agentid": 1000002,
    "text": {
        "content": "测试"
    },
    "safe": 0
}'

```

## 接收消息与事件

### 本地测试

- 配置环境变量

```
touch .env
echo "CORP_ID=AAAAAAAAAAAAAAA" >> .env
echo "CORP_SECRET=AAAAAAAAAA" >> .env
echo "ENCODING_AESKEY=AAAAAAA" >> .env
echo "ENCODING_TOKEN=AAAAAAAA" >> .env
echo "BACKEND_CALLBACKURL=http://127.0.0.1:8080/hello" >> .env
```

