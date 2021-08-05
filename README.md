## 简单推送

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
