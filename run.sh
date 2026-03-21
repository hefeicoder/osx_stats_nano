#!/bin/bash
swift build -c release 2>&1 && .build/release/OSXStatsNano &
