#!/bin/bash

# ==============================================================================
# 00-utils.sh - Utility Functions
# ==============================================================================

# Color Definitions
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# Logging Functions
log() {
    echo -e "${BLUE}[LOG]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Permission Check
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script with sudo or as root."
        exit 1
    fi
}