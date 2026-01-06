#!/bin/bash

# Color codes for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display banner
banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║  Wayback Machine URL Extractor         ║"
    echo "║  Target: Archive.org CDX API           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to validate URL input
validate_url() {
    local url=$1
    if [[ -z "$url" ]]; then
        echo -e "${RED}[✗] Error: URL cannot be empty${NC}"
        return 1
    fi
    
    # Remove http:// or https:// if present
    url=$(echo "$url" | sed 's|^https\?://||')
    
    if [[ ! "$url" =~ ^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}[✗] Error: Invalid URL format${NC}"
        return 1
    fi
    
    echo "$url"
    return 0
}

# Function to fetch URLs from Wayback Machine
fetch_wayback_urls() {
    local target=$1
    local output_file=$2
    local api_url="https://web.archive.org/cdx/search/cdx?url=*.${target}&fl=original&collapse=urlkey&output=json"
    
    echo -e "${YELLOW}[*] Fetching URLs for: ${target}${NC}"
    echo -e "${YELLOW}[*] API Request: ${api_url}${NC}\n"
    
    # Fetch data from API
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    # Check if curl was successful
    if [[ -z "$response" ]]; then
        echo -e "${RED}[✗] Error: Failed to connect to Wayback Machine API${NC}"
        return 1
    fi
    
    # Parse JSON and extract URLs (skip first line which is header)
    local urls=$(echo "$response" | jq -r '.[] | select(length > 0) | .[0]' 2>/dev/null | tail -n +2)
    
    # Check if any URLs were found
    if [[ -z "$urls" ]]; then
        echo -e "${RED}[✗] No URLs found for: ${target}${NC}"
        return 1
    fi
    
    # Clear output file if it exists
    > "$output_file"
    
    # Counter for results
    local count=0
    
    # Write URLs to file and display in terminal
    echo -e "${GREEN}[+] Found URLs:${NC}\n"
    
    while IFS= read -r url; do
        if [[ -n "$url" ]]; then
            echo "$url" >> "$output_file"
            echo -e "${GREEN}${url}${NC}"
            ((count++))
        fi
    done <<< "$urls"
    
    echo ""
    echo -e "${GREEN}[+] Total URLs found: ${count}${NC}"
    echo -e "${GREEN}[+] Results saved to: ${output_file}${NC}"
    
    return 0
}

# Main script execution
main() {
    banner
    
    # Get target URL input from user
    echo -e "${CYAN}Enter target domain (e.g., example.com):${NC}"
    read -p "> " target_input
    
    # Validate input
    target=$(validate_url "$target_input")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    # Define output file with timestamp
    output_file="wayback_urls_${target}_$(date +%s).txt"
    
    # Fetch and process URLs
    fetch_wayback_urls "$target" "$output_file"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${YELLOW}[*] Script completed successfully${NC}"
        
        # Show option to display file contents
        echo ""
        read -p "$(echo -e ${CYAN}View file contents? [y/n]: ${NC})" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}\n--- File Contents ---${NC}"
            cat "$output_file" | sed "s/^/${GREEN}/" | sed "s/$/${NC}/"
        fi
    else
        exit 1
    fi
}

# Run main function
main "$@"

