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
### 配置云函数
7 个变量

- 

