# 腾讯云函数部署

## 1、构建并拷贝所需运行时

```
docker run --rm \
-v "$PWD:/workspace" \
-w /workspace \
swift:5.5.2-centos7  \
/bin/bash -cl " \
     yum remove git -y && \
     yum install https://repo.ius.io/ius-release-el7.rpm -y && \
     yum install git224 -y && \
     yum install -y sqlite-devel && \
     swift build -c release && \
     rm -rf .build/install && mkdir -p .build/install && \
     cp -P .build/release/Run .build/install/ && \
     ldd .build/install/Run | grep swift | awk '{print $3}' | xargs cp -Lv -t .build/install/"
```

## 2、创建云函数启动文件

- 创建启动文件

```
cd .build/install && touch scf_bootstrap && chmod +x scf_bootstrap
```

- 写入启动内容

```
#!/usr/bin/env bash

# export LD_LIBRARY_PATH=/opt/swift/usr/lib:${LD_LIBRARY_PATH}

./Run serve --env production --hostname 0.0.0.0 --port 9000
```

## 3、压缩代码包

```
tar cvzf app-0.0.1.tar.gz -C .build/install .
```

- 或者

```
cd .build/install && zip --symlinks app-0.0.1.zip *
```

## 4、部署

- 复制 yml 文件

```
cp SCF/Serverless.yml serverless.yml
```

- 部署

```
sls deploy --debug
```
