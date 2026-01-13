# macOS (Apple Silicon) RViz 2 ビルドガイド

このドキュメントは、macOS Sonoma (Apple Silicon) 上で ROS 2 Humble の RViz 2 をビルドするための手順をまとめたものです。

## 1. 事前準備 (Prerequisites)

以下のソフトウェアがインストールされていることを確認してください。

- **Homebrew**
- **Qt5**: `brew install qt@5` (ビルドには Qt5 が必須です)
- **Eigen3**: `brew install eigen`
- **Assimp**: `brew install assimp`
- **Python 3.10**: (pyenv などで管理されていることを想定)

```bash
brew link qt@5 --force
```

## 2. 環境変数の設定

ビルドを実行するターミナルで以下の環境変数を設定します。

```bash
# Qt5 のパス設定
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export Qt5_DIR="/opt/homebrew/opt/qt@5/lib/cmake/Qt5"

# Python のパス
export PYTHON_EXECUTABLE=$(which python3)

# コンパイラの指定 (Command Line Tools を使用)
export CC=/Library/Developer/CommandLineTools/usr/bin/clang
export CXX=/Library/Developer/CommandLineTools/usr/bin/clang++

# 依存ライブラリのパス
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
export Eigen3_DIR="/opt/homebrew/share/eigen3/cmake"
```

## 3. ビルド用ユーティリティスクリプトの作成

macOS でのビルド中に発生するランダムな割り込み（`Interrupt: 2`）に対処するため、成功するまでループするスクリプトを作成します。

**ファイル名: `build_rviz_optimized.sh`**

```bash
#!/bin/bash
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
. ~/ros2_humble/install/setup.bash

# 追加の検索パス
export CMAKE_PREFIX_PATH="/opt/homebrew:$CMAKE_PREFIX_PATH"

PACKAGES=$@
for pkg in $PACKAGES; do
  echo "--- Building $pkg ---"
  until colcon build --event-handlers console_direct+ \
    --packages-select $pkg \
    --parallel-workers 1 \
    --cmake-args \
      -DPYTHON_EXECUTABLE=$(which python3) \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_OSX_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
      -DCMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3" \
      -DTHIRDPARTY=ON \
      -DBUILD_TESTING=OFF; do
    echo "$pkg failed, retrying in 2 seconds..."
    sleep 2
  done
  # 成功したら環境を反映
  . ~/ros2_humble/install/setup.bash
done
```

実行権限を付与します：
```bash
chmod +x build_rviz_optimized.sh
```

## 4. ビルドの実行手順

以下の順序でパッケージをビルドします。依存関係の都合上、この順序が推奨されます。

### Step 1: ベンダーパッケージ
```bash
./build_rviz_optimized.sh rviz_ogre_vendor rviz_assimp_vendor
```

### Step 2: 依存メッセージ・ツール
```bash
./build_rviz_optimized.sh interactive_markers laser_geometry
```

### Step 3: RViz コアライブラリ
```bash
./build_rviz_optimized.sh rviz_rendering rviz_common
```

### Step 4: プラグインおよび本体
```bash
./build_rviz_optimized.sh rviz_default_plugins rviz2
```

## 5. 起動確認

ビルド完了後、新しいターミナルで以下を実行します。

```bash
source ~/ros2_humble/install/setup.bash
rviz2
```

---
**トラブルシューティング:**
- **`nullptr_t` エラー**: `CMAKE_CXX_STANDARD=17` が設定されているか確認してください。
- **`Eigen` が見つからない**: `CMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3"` が `colcon` 引数に含まれているか確認してください。
