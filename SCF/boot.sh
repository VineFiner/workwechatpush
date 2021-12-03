#!/bin/sh

############## 构建可执行二进制文件 ##########

# 构建
docker run --rm \
-v "$PWD:/workspace" \
-w /workspace \
swift:5.5.2-centos8  \
/bin/bash -cl " \
     swift build -c release --static-swift-stdlib"

# 复制构建产物, 复制资源文件
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  centos  \
  /bin/bash -cl ' \
     rm -rf .build/install && mkdir -p .build/install && \
     cp -P .build/release/Run .build/install/'
     
############## 函数部署 ###################
# 创建启动文件
touch .build/install/scf_bootstrap && chmod +x .build/install/scf_bootstrap

# 写入启动内容
cat > .build/install/scf_bootstrap<<EOF
#!/usr/bin/env bash
# export LD_LIBRARY_PATH=/opt/swift/usr/lib:${LD_LIBRARY_PATH}
./Run serve --env production --hostname 0.0.0.0 --port 9000
EOF

# 压缩文件夹
cd .build/install && zip --symlinks -r app-0.0.1.zip *

######## serveless.yml 部署
