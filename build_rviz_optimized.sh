#!/bin/bash
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
. ~/ros2_humble/install/setup.bash
cd ~/ros2_humble

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
