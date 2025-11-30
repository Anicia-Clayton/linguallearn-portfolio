#!/bin/bash
# Download PocketSign ASL Videos
# Run in WSL: bash download_upload_asl_videos.sh

# ============================================================================
# CONFIGURATION
# ============================================================================

# DOWNLOAD LOCATION (Outside Git Repo)
# Use /mnt/c/ format for Windows drives
LOCAL_PROJECT_FILES="/mnt/c/<LOCAL-DOWNLOAD-LOCATION>"
LOCAL_OUTPUT_PATH="$LOCAL_PROJECT_FILES/asl-videos/pocketsign"

# S3 BUCKET INFORMATION
S3_BUCKET_NAME="<S3-BUCKET-NAME>"
S3_PREFIX="asl/pocketsign"

# CLOUDFRONT DOMAIN
# Search for & update <YOUR-CLOUDFRONT-DOMAIN> section of test url (near end of code)

# ============================================================================
# ANSI COLOR CODES
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# SCRIPT START
# ============================================================================

echo -e "\n${CYAN}==================================${NC}"
echo -e "${CYAN}PocketSign ASL Video Downloader${NC}"
echo -e "${CYAN}==================================${NC}"

echo -e "\n${YELLOW}Configuration:${NC}"
echo -e "  Local Path: ${LOCAL_OUTPUT_PATH}"
echo -e "  S3 Bucket:  s3://${S3_BUCKET_NAME}/${S3_PREFIX}"
echo ""

read -p "Is this correct? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please update the paths at the top of this script.${NC}"
    exit 1
fi

# ============================================================================
# CREATE DIRECTORY STRUCTURE
# ============================================================================

echo -e "\n${CYAN}Creating directory structure...${NC}"

CATEGORIES=("greetings" "common-words" "questions" "numbers" "family")

for category in "${CATEGORIES[@]}"; do
    mkdir -p "$LOCAL_OUTPUT_PATH/$category"
    echo -e "  ${GREEN}Created: $category/${NC}"
done

# ============================================================================
# DEFINE VIDEO LISTS
# ============================================================================

declare -A VIDEOS
VIDEOS[greetings]="hello goodbye thank_you please youre_welcome"
VIDEOS[common-words]="yes no help stop go"
VIDEOS[questions]="what where when who why how"
VIDEOS[numbers]="one two three four five six seven eight nine ten"
VIDEOS[family]="mom dad sister brother"

BASE_URL="https://pocketsign.s3-us-west-2.amazonaws.com"

# ============================================================================
# DOWNLOAD VIDEOS
# ============================================================================

SUCCESS_COUNT=0
FAIL_COUNT=0

for category in "${CATEGORIES[@]}"; do
    echo -e "\n${GREEN}Downloading $category videos...${NC}"

    for video in ${VIDEOS[$category]}; do
        # Handle spaces in video names (convert underscore to space for URL)
        url_video=$(echo "$video" | sed 's/_/ /g')
        url="$BASE_URL/${url_video}.mp4"
        filename="$LOCAL_OUTPUT_PATH/$category/${video}.mp4"

        echo -n -e "  ${YELLOW}${video}.mp4${NC} ... "

        if curl -f -s -o "$filename" "$url" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            ((SUCCESS_COUNT++))
        else
            echo -e "${RED}✗ Failed${NC}"
            ((FAIL_COUNT++))
        fi
    done
done

# ============================================================================
# DOWNLOAD SUMMARY
# ============================================================================

echo -e "\n${CYAN}==================================${NC}"
echo -e "${CYAN}Download Summary${NC}"
echo -e "${CYAN}==================================${NC}"
echo -e "  ${GREEN}Success: $SUCCESS_COUNT videos${NC}"
echo -e "  ${RED}Failed:  $FAIL_COUNT videos${NC}"
echo -e "  ${YELLOW}Location: $LOCAL_OUTPUT_PATH${NC}"

# ============================================================================
# UPLOAD TO S3
# ============================================================================

echo -e "\n${CYAN}==================================${NC}"
echo -e "${CYAN}Upload to S3${NC}"
echo -e "${CYAN}==================================${NC}"

read -p "Upload videos to S3 now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}Uploading to S3...${NC}"

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}ERROR: AWS CLI not found. Please install AWS CLI first.${NC}"
        echo -e "${YELLOW}Install: sudo apt-get install awscli${NC}"
        exit 1
    fi

    S3_PATH="s3://$S3_BUCKET_NAME/$S3_PREFIX/"

    echo -e "${YELLOW}Uploading from: $LOCAL_OUTPUT_PATH${NC}"
    echo -e "${YELLOW}Uploading to:   $S3_PATH${NC}"
    echo ""

    # Execute upload
    aws s3 cp "$LOCAL_OUTPUT_PATH" "$S3_PATH" --recursive

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ Upload complete!${NC}"

        # Verify upload
        echo -e "\n${CYAN}Verifying upload...${NC}"
        aws s3 ls "$S3_PATH" --recursive
    else
        echo -e "\n${RED}✗ Upload failed!${NC}"
        echo -e "${YELLOW}Check your AWS credentials and bucket name.${NC}"
    fi
else
    echo -e "\n${YELLOW}Skipping upload. You can upload later with:${NC}"
    echo -e "${CYAN}  aws s3 cp \"$LOCAL_OUTPUT_PATH\" s3://$S3_BUCKET_NAME/$S3_PREFIX/ --recursive${NC}"
fi

# ============================================================================
# NEXT STEPS
# ============================================================================

echo -e "\n${CYAN}==================================${NC}"
echo -e "${CYAN}Next Steps${NC}"
echo -e "${CYAN}==================================${NC}"

echo -e "\n${YELLOW}1. Review downloaded videos:${NC}"
echo -e "   Windows Explorer: $(echo "$LOCAL_OUTPUT_PATH" | sed 's|/mnt/c|C:|')"

echo -e "\n${YELLOW}2. Test CloudFront delivery:${NC}"
echo -e "   Get CloudFront domain: terraform output cloudfront_domain_name"
echo -e "   Test URL: https://<YOUR-CLOUDFRONT-DOMAIN>/asl/pocketsign/greetings/hello.mp4"

echo -e "\n${RED}3. IMPORTANT - Seek Permission:${NC}"
echo -e "   Contact PocketSign for usage permission!"
echo -e "   See: docs/asl-content-attribution.md"

echo -e "\n${YELLOW}4. Update database with video metadata:${NC}"
echo -e "   Add vocabulary cards linking to CloudFront URLs"

echo -e "\n${GREEN}==================================${NC}"
echo -e "${GREEN}Script Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
